# M113 T2 — per-cell unconditional coverage for the searle / burch / mc legs,
# re-derived from the committed M111 fixture (data-raw/m111-fallback-results.rds).
# No sweep, no fits, no MC/glmmTMB dependency: everything is aggregation over
# the fixture's per-rep raw rows. Rules page:
# cairn/references/mc-skew-response-comparison.md (S1/S2, frozen 2026-08-08).
# Output: data-raw/m113-skew-response-coverage.tsv (committed text fixture).
#
# Coverage columns:
#   coverage_uncond   — mean(covered) with an aborted rep counting as a miss
#                       (the M111 F2 convention; classical legs never abort).
#   coverage_nonabort — mean(covered) among non-aborted reps; the S2 rule reads
#                       this column (abort disposition is D-026's, not re-opened).
#   lo_miss / hi_miss — tail-miss rates among NON-ABORTED reps, so they sum to 1
#                       with coverage_nonabort, not with coverage_uncond (for the
#                       MC leg the difference is the abort mass).
# Width: med_width per leg; width_ratio_vs_mc = med_width / MC med_width over
# the MC leg's non-aborted reps at that cell (S1 descriptive evidence).

fixture <- readRDS("data-raw/m111-fallback-results.rds")
raw <- fixture$raw

expected_cols <- c(
  "cell",
  "rho",
  "k",
  "n",
  "dist",
  "rep",
  "method",
  "lower",
  "upper",
  "aborted",
  "covered",
  "width",
  "lo_miss",
  "hi_miss"
)
stopifnot(
  identical(sort(names(raw)), sort(expected_cols)),
  nrow(raw) == 64L * 2000L * 3L,
  identical(sort(unique(raw$method)), c("burch", "mc", "searle")),
  length(unique(raw$cell)) == 64L
)
# Classical legs never abort on this grid (M111 F1; D-012 C1).
stopifnot(!any(raw$aborted[raw$method != "mc"]))

one_group <- function(g) {
  data.frame(
    cell = g$cell[[1L]],
    rho = g$rho[[1L]],
    k = g$k[[1L]],
    n = g$n[[1L]],
    dist = g$dist[[1L]],
    method = g$method[[1L]],
    n_rep = nrow(g),
    n_abort = sum(g$aborted),
    coverage_uncond = mean(g$covered),
    coverage_nonabort = mean(g$covered[!g$aborted]),
    lo_miss = mean(g$lo_miss[!g$aborted]),
    hi_miss = mean(g$hi_miss[!g$aborted]),
    med_width = stats::median(g$width[!g$aborted])
  )
}

groups <- split(raw, list(raw$cell, raw$method), drop = TRUE)
tab <- do.call(rbind, lapply(groups, one_group))
rownames(tab) <- NULL
stopifnot(nrow(tab) == 64L * 3L, all(tab$n_rep == 2000L))

mc_width <- tab$med_width[tab$method == "mc"]
names(mc_width) <- tab$cell[tab$method == "mc"]
tab$width_ratio_vs_mc <- tab$med_width / mc_width[as.character(tab$cell)]

# Pin the two ROADMAP-quoted known-prior cells (AC2): MC leg, rho = 0.60,
# n = 5, chisq1, k = 30 -> 0.676 and k = 50 -> 0.673, at quoted precision.
# "Quoted precision" is a +/- 0.0005 band, not round(): the k = 50 cell is
# exactly 0.6725, which the M111 page rendered half-up as 0.673 while R's
# half-even round() gives 0.672.
# Both are 0-abort cells, so the unconditional and non-abort columns agree.
quoted <- tab[
  tab$method == "mc" &
    tab$rho == 0.60 &
    tab$n == 5 &
    tab$dist == "chisq1" &
    tab$k %in% c(30, 50),
]
quoted <- quoted[order(quoted$k), ]
stopifnot(
  nrow(quoted) == 2L,
  all(quoted$n_abort == 0L),
  all(abs(quoted$coverage_uncond - c(0.676, 0.673)) <= 5e-4 + 1e-9)
)

tab <- tab[order(tab$cell, tab$method), ]
num <- vapply(tab, is.numeric, logical(1L))
out <- tab
out[num] <- lapply(
  out[num],
  function(x) trimws(formatC(x, digits = 10, format = "g"))
)
write.table(
  out,
  "data-raw/m113-skew-response-coverage.tsv",
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)
message("wrote data-raw/m113-skew-response-coverage.tsv (192 rows)")
