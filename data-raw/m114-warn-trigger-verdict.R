# M114 T5 — apply the frozen selection rule mechanically; emit the verdict.
#
# Reads ONLY (a) the frozen rules (cairn/references/mc-skew-warn-trigger.md,
# committed before any derivation artifact — the constants below transcribe
# its § Candidate trigger set / § Cell classification / § Binding rules), and
# (b) the derived tables: data-raw/m114-warn-trigger-stats.tsv (per-rep
# statistics, both halves) + data-raw/m113-skew-response-coverage.tsv (the
# M111 cells' non-abort coverage / abort rate — the committed M113
# classification source the frozen page names). No free choices: the
# candidate set, floors, and selection ordering are closed on the page, so
# this script is a function of (frozen page, derived tables) alone — AC5.
#
# Outputs (committed):
#   data-raw/m114-warn-trigger-candidates.tsv — all 48 candidates, pass/fail
#     per binding rule + the selection metrics
#   data-raw/m114-warn-trigger-verdict.tsv — the winner's per-cell fire-rate
#     table (or, on degrade, the empty-winner marker row)
#
# Run (foreground, seconds):  Rscript data-raw/m114-warn-trigger-verdict.R

stats_path <- "data-raw/m114-warn-trigger-stats.tsv"
m113_path <- "data-raw/m113-skew-response-coverage.tsv"

stats <- read.delim(stats_path, stringsAsFactors = FALSE)
stopifnot(nrow(stats) == 128000L + 10000L)

# ---- cell classification (frozen page § Cell classification) ----------------
# M111 cells (1–64): cov/ab from the committed M113 table's mc rows.
# Held-out cells (65–74): cov/ab from their own per-rep rows.
m113 <- read.delim(m113_path, stringsAsFactors = FALSE)
mc113 <- m113[m113$method == "mc", ]
cells_m111 <- data.frame(
  cell = mc113$cell,
  cov = mc113$coverage_nonabort,
  ab = mc113$n_abort / mc113$n_rep
)
ho <- stats[stats$source == "heldout", ]
cells_ho <- do.call(rbind, lapply(split(ho, ho$cell), function(g) {
  na <- !g$mc_aborted
  data.frame(
    cell = g$cell[1],
    cov = mean(g$mc_covered[na]),
    ab = mean(g$mc_aborted)
  )
}))
cellinfo <- rbind(cells_m111, cells_ho)
meta <- unique(stats[, c("cell", "dist")])
cellinfo <- merge(cellinfo, meta, by = "cell")
cellinfo$class <- with(cellinfo, ifelse(
  ab <= 0.1 & cov < 0.93,
  ifelse(cov < 0.80, "targeted_a", "targeted_b"),
  ifelse(dist == "gaussian" & ab <= 0.1 & cov >= 0.93, "protected",
    "descriptive"
  )
))

# ---- candidate set (frozen page § Candidate trigger set: 48, closed) --------
ck_grid <- c(0.5, 1.0, 1.5, 2.0, 3.0, 4.0)
cg_grid <- c(0.25, 0.5, 0.75, 1.0, 1.5, 2.0)
candidates <- rbind(
  data.frame(form = "K", c_k = ck_grid, c_g = NA_real_),
  data.frame(form = "S", c_k = NA_real_, c_g = cg_grid),
  expand.grid(form = "KS", c_k = ck_grid, c_g = cg_grid,
    stringsAsFactors = FALSE
  )
)

# fire indicator per rep; undefined statistics count as NOT fired (frozen page)
fires <- function(cand, s) {
  fk <- !is.na(s$kappa_bc) & s$kappa_bc > cand$c_k
  fg <- !is.na(s$gamma) & abs(s$gamma) > cand$c_g
  switch(cand$form, K = fk, S = fg, KS = fk | fg)
}

# ---- evaluate all 48 over non-aborted reps ----------------------------------
nonab <- stats[!stats$mc_aborted, ]
rows <- vector("list", nrow(candidates))
percell_rows <- vector("list", nrow(candidates))
for (i in seq_len(nrow(candidates))) {
  cand <- candidates[i, ]
  f <- fires(cand, nonab)
  fr <- vapply(
    split(f, nonab$cell),
    mean,
    numeric(1)
  )
  fr_df <- data.frame(cell = as.integer(names(fr)), fire_rate = unname(fr))
  fr_df <- merge(fr_df, cellinfo, by = "cell")
  w1 <- all(fr_df$fire_rate[fr_df$class == "targeted_a"] >= 0.90)
  w2 <- all(fr_df$fire_rate[fr_df$class == "targeted_b"] >= 0.50)
  w3 <- all(fr_df$fire_rate[fr_df$class == "protected"] <= 0.10)
  targeted <- fr_df$class %in% c("targeted_a", "targeted_b")
  rows[[i]] <- data.frame(
    form = cand$form, c_k = cand$c_k, c_g = cand$c_g,
    w1 = w1, w2 = w2, w3 = w3, passes = w1 && w2 && w3,
    max_protected_fire = max(fr_df$fire_rate[fr_df$class == "protected"]),
    min_targeted_fire = min(fr_df$fire_rate[targeted])
  )
  percell_rows[[i]] <- fr_df
}
ledger <- do.call(rbind, rows)

# ---- frozen selection ordering (page § Selection rule) ----------------------
passers <- which(ledger$passes)
if (length(passers) == 0L) {
  verdict <- "degrade"
  message(
    "DEGRADE: no candidate in the frozen family met the frozen ",
    "floors/ceilings on the derived tables."
  )
  winner_tbl <- data.frame(
    cell = NA_integer_, fire_rate = NA_real_, cov = NA_real_,
    ab = NA_real_, dist = "none", class = "no-winner"
  )
} else {
  form_rank <- c(K = 1L, S = 2L, KS = 3L)
  ord <- passers[order(
    ledger$max_protected_fire[passers], # (1) min max protected fire
    -ledger$min_targeted_fire[passers], # (2) max min targeted fire
    form_rank[ledger$form[passers]], # (3) K over S over KS
    -ifelse(is.na(ledger$c_k[passers]), -Inf, ledger$c_k[passers]), # (4a)
    -ifelse(is.na(ledger$c_g[passers]), -Inf, ledger$c_g[passers]) # (4b)
  )]
  win <- ord[1L]
  verdict <- "trigger"
  message(sprintf(
    "WINNER: form %s, c_k = %s, c_g = %s (max protected fire %.4f, min targeted fire %.4f); %d/48 passers",
    ledger$form[win], format(ledger$c_k[win]), format(ledger$c_g[win]),
    ledger$max_protected_fire[win], ledger$min_targeted_fire[win],
    length(passers)
  ))
  winner_tbl <- percell_rows[[win]]
}

fmt4 <- function(x) ifelse(is.na(x), "NA", sprintf("%.4f", x))
led_out <- ledger
led_out$max_protected_fire <- fmt4(led_out$max_protected_fire)
led_out$min_targeted_fire <- fmt4(led_out$min_targeted_fire)
write.table(led_out, "data-raw/m114-warn-trigger-candidates.tsv",
  sep = "\t", quote = FALSE, row.names = FALSE
)
win_out <- winner_tbl
for (cn in c("fire_rate", "cov", "ab")) win_out[[cn]] <- fmt4(win_out[[cn]])
write.table(win_out, "data-raw/m114-warn-trigger-verdict.tsv",
  sep = "\t", quote = FALSE, row.names = FALSE
)
message("verdict: ", verdict, "; ledgers written")
print(table(cellinfo$class))
