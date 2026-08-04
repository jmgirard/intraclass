# The `bootstrap` half of M103 AC2's verdict table.
#
# `tests/testthat/test-reducer-abort-hint.R` asserts, cell by cell, that
# `boundary_method_usable()` returns what the committed sweep measured -- but only
# for `searle`, `burch` and `npbootstrap`. `bootstrap` is left to this script: at
# the 999 refits the fixture was measured under it costs ~17 s per dataset, ~8 min
# over the table, on a suite that already runs 13-24 min per platform. That is not
# a per-push cost, so the split was taken deliberately at the M103 implement gate
# (2026-08-04) with the consequence stated: a regression in the `bootstrap` row of
# `boundary_method_usable()` is caught here, at a milestone gate, not by CI.
#
# The `montecarlo` row is checked here too. It is cheap, but it needs an engine
# fit exactly as `bootstrap` does, and fitting one per cell is the part the suite
# is avoiding.
#
# Run from the repo root (~10 min):
#   Rscript data-raw/check-abort-remedy-verdicts.R
# Exits non-zero on any disagreement, and prints every cell it checked.

suppressMessages(devtools::load_all(quiet = TRUE))

fixture <- "tests/testthat/fixtures/abort-remedy-sweep.tsv"
sweep <- utils::read.delim(
  fixture,
  comment.char = "#",
  stringsAsFactors = FALSE
)

# The sweep's own generators. A copy that drifted from
# `data-raw/sweep-abort-remedies.R` would build different data and disagree with
# the recorded verdicts, which is what this script fails on.
gen_mse0 <- function(n_s, n_r, jitter_sd = 0, seed = 1) {
  set.seed(seed)
  mu <- stats::rnorm(n_s, 0, 3)
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = rep(mu, each = n_r) + stats::rnorm(n_s * n_r, 0, jitter_sd)
  )
}

gen_ssa0 <- function(n_s, n_r, jitter_sd = 0, seed = 1) {
  set.seed(seed)
  profile <- stats::rnorm(n_r, 0, 3)
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = rep(profile, times = n_s) + stats::rnorm(n_s * n_r, 0, jitter_sd)
  )
}

gen_resample_degenerate <- function(n_s, n_r, n_varying = 2L, seed = 1) {
  set.seed(seed)
  mu <- stats::rnorm(n_s, 0, 3)
  score <- rep(mu, each = n_r)
  for (i in seq_len(min(n_varying, n_s))) {
    idx <- ((i - 1) * n_r + 1):(i * n_r)
    score[idx] <- score[idx] + stats::rnorm(n_r, 0, 1)
  }
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = score
  )
}

gen_se_zero <- function(n_s, n_r, seed = 1) {
  data.frame(
    subject = rep(1:3, each = 2),
    rater = rep(1:2, times = 3),
    score = c(-1.5, -0.5, 0, 0, 0.5, 1.5)
  )
}

sweep_data <- function(row) {
  jit <- if (grepl("near", row$trigger)) 1e-8 else 0
  switch(
    row$generator,
    gen_mse0 = gen_mse0(row$n_s, row$n_r, jitter_sd = jit, seed = row$seed),
    gen_ssa0 = gen_ssa0(row$n_s, row$n_r, jitter_sd = jit, seed = row$seed),
    gen_resample_degenerate = gen_resample_degenerate(
      row$n_s,
      row$n_r,
      n_varying = 2L,
      seed = row$seed
    ),
    gen_se_zero = gen_se_zero(row$n_s, row$n_r, seed = row$seed),
    stop("unknown generator in the sweep fixture: ", row$generator)
  )
}

ests_oneway <- function(k_eff) {
  list(
    icc_estimand(unit = "single", k_eff = k_eff, oneway = TRUE),
    icc_estimand(unit = "average", k_eff = k_eff, oneway = TRUE)
  )
}

reached <- sweep[
  sweep$reached %in% TRUE & sweep$remedy %in% c("bootstrap", "montecarlo"),
]
if (!nrow(reached)) {
  stop("no engine-fit cells found in ", fixture)
}

bad <- 0L
for (i in seq_len(nrow(reached))) {
  row <- reached[i, ]
  df <- sweep_data(row)
  # The engine fit the dispatch would hand the hint. A cell whose point fit dies
  # is not one a user can reach this message on, and the sweep already recorded
  # that in `point_fit_ok`; every row here has it TRUE.
  fit <- withCallingHandlers(
    tryCatch(fit_glmmtmb_oneway(df), error = function(e) e),
    warning = function(w) invokeRestart("muffleWarning")
  )
  got <- if (inherits(fit, "condition")) {
    FALSE
  } else {
    boundary_method_usable(
      row$remedy,
      df,
      ests_oneway(row$n_r),
      conf_level = row$conf_level,
      n0 = row$n_r,
      seed = 1L,
      boot_samples = row$boot_samples,
      engine = fit
    )
  }
  want <- isTRUE(row$remedy_usable)
  ok <- identical(got, want)
  if (!ok) {
    bad <- bad + 1L
  }
  cat(sprintf(
    "%-34s %-24s %2dx%-2d seed %d %-11s recorded=%-5s rerun=%-5s %s\n",
    row$label,
    row$generator,
    row$n_s,
    row$n_r,
    row$seed,
    row$remedy,
    want,
    got,
    if (ok) "ok" else "MISMATCH"
  ))
}

cat(sprintf("\n%d cells checked, %d disagreements\n", nrow(reached), bad))
cat(sprintf(
  "R %s, glmmTMB %s, platform %s\n",
  getRversion(),
  utils::packageVersion("glmmTMB"),
  R.version$platform
))
if (bad > 0L) {
  stop(bad, " cell(s) disagree with ", fixture)
}
