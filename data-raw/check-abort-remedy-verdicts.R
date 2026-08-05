# The engine-fit half of M103 AC2's verdict table -- `bootstrap` and `montecarlo`.
#
# `tests/testthat/test-reducer-abort-hint.R` asserts, cell by cell, that
# `boundary_method_usable()` returns what the committed sweep measured -- but only
# for `searle`, `burch` and `npbootstrap`. The two engine-fit methods are left to
# this script, for two reasons that are now different from each other.
#
# COST. Both need an engine fit per cell, and `bootstrap` refits that model once
# per resample. That is not a per-push cost, so the split was taken deliberately at
# the M103 implement gate (2026-08-04) with the consequence stated: a regression in
# the engine-fit rows of `boundary_method_usable()` is caught here, at a milestone
# gate, not by CI.
#
# WHAT IS COMPARED, AND WHY NOT THE FIXTURE COLUMN. The sweep's `remedy_usable`
# records a full `icc()` retry at the caller's own `boot_samples` (999 in the
# committed run). `boundary_method_usable()` no longer runs `bootstrap` that way:
# it screens at `hint_screen_samples` and caps the full run at
# `hint_verify_boot_cap`, and the bullet names that capped count. Holding the two
# side by side would compare two experiments, and their agreeing would be luck
# (M103 review pass 2, G5). So this script checks AC2's rule read forward, which is
# the property a user actually gets: wherever `boundary_method_usable()` accepts a
# method, the call its bullet promises -- that method, that seed, that
# `boot_samples` -- is run as an `icc()` call and every interval it returns must be
# one `boundary_interval_usable()` accepts. A refusal asserts nothing: staying
# silent about a method that would have worked is the conservative direction the
# screen deliberately fails in. The fixture column is still printed beside each
# verdict, as context and to surface how often the cap and the screen change the
# answer, but no exit code depends on it.
#
# Run from the repo root (~15 min):
#   Rscript data-raw/check-abort-remedy-verdicts.R
# Exits non-zero on any broken promise, and prints every cell it checked.

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

# The call the bullet promises for an accepted method, run as the user would run
# it: `icc()`, at the seed the verification used and -- for `bootstrap` -- at the
# capped count the bullet names. Returns TRUE when every interval it returns is
# usable, FALSE on any abort, error or unusable endpoint, which is exactly the
# failure this script exists to catch.
promise_kept <- function(df, method, row) {
  fit <- tryCatch(
    withCallingHandlers(
      icc(
        df,
        score,
        subject,
        rater,
        model = "oneway",
        ci_method = method,
        conf_level = row$conf_level,
        seed = 1L,
        boot_samples = hint_verify_boot_samples(row$boot_samples)
      ),
      warning = function(w) invokeRestart("muffleWarning"),
      message = function(m) invokeRestart("muffleMessage")
    ),
    error = function(e) e
  )
  if (inherits(fit, "condition")) {
    return(FALSE)
  }
  est <- fit$estimates
  # Each estimand's own support floor, never a hardcoded one: `divisor` is 1 for
  # ICC(1) and the effective rater count for ICC(k) (`resolve_divisor()`).
  ests <- ests_oneway(row$n_r)
  all(vapply(
    seq_len(nrow(est)),
    function(i) {
      boundary_interval_usable(
        list(conf.low = est$conf.low[i], conf.high = est$conf.high[i]),
        divisor = ests[[i]]$divisor,
        n0 = row$n_r
      )
    },
    logical(1)
  ))
}

broken <- 0L
named <- 0L
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
  accepted <- if (inherits(fit, "condition")) {
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
  # Only an acceptance carries a promise. A refusal is checked against nothing --
  # see the header.
  kept <- if (accepted) promise_kept(df, row$remedy, row) else NA
  if (accepted) {
    named <- named + 1L
    if (!isTRUE(kept)) {
      broken <- broken + 1L
    }
  }
  cat(sprintf(
    "%-34s %-24s %2dx%-2d seed %d %-11s accepted=%-5s promise=%-5s (sweep@%d=%s)\n",
    row$label,
    row$generator,
    row$n_s,
    row$n_r,
    row$seed,
    row$remedy,
    accepted,
    if (is.na(kept)) "-" else if (isTRUE(kept)) "kept" else "BROKEN",
    row$boot_samples,
    isTRUE(row$remedy_usable)
  ))
}

cat(sprintf(
  "\n%d cells checked, %d accepted, %d broken promises\n",
  nrow(reached),
  named,
  broken
))
cat(sprintf(
  "R %s, glmmTMB %s, platform %s\n",
  getRversion(),
  utils::packageVersion("glmmTMB"),
  R.version$platform
))
# A check that accepts nothing asserts nothing. The sweep's own cells include
# ones where `bootstrap` is the only method that works at all, so zero
# acceptances means the verification stopped running, not that the data changed.
if (named == 0L) {
  stop("no engine-fit cell was accepted -- the forward check is vacuous")
}
if (broken > 0L) {
  stop(
    broken,
    " accepted cell(s) whose promised call did not return a usable interval"
  )
}
