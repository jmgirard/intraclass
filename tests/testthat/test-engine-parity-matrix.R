# Standing cross-engine parity matrix (M49) ------------------------------------
#
# One committed asset that enumerates the (estimand x engine) grid and pins
# cross-engine POINT-ESTIMATE agreement, so a new estimator, a new engine, or an
# upstream engine update surfaces a silent parity gap as a test failure instead
# of drifting unnoticed (DESIGN.md GP4; the "silent-drift" known-issues wart).
#
# HOW TO EXTEND (the load-bearing rule):
#   * Add an engine to icc()  -> add it to every cell's `agree`/`na` below and
#     to the roster guard at the bottom (which fails until you do).
#   * Add an estimand/design   -> add a `cell(...)` row with its engine
#     dispositions. A design no cell covers is a silent gap by construction.
#
# WHAT THIS GUARDS vs WHAT IT DEFERS:
#   * Guards: point-estimate agreement across the frequentist engines
#     (glmmTMB is the reference; lme4 and lavaan are independent
#     implementations, PRINCIPLES.md #1 / ADR-002 / ADR-012), and that every
#     documented engine refusal (abort_unsupported) actually fires.
#   * Cross-referenced, not re-run here: interval parity (test-icc-lme4-engine.R,
#     test-icc-lavaan.R) and the Bayesian brms engine, whose live-Stan agreement
#     stays in test-icc-brms.R (skip_on_ci; brms/Stan verification is
#     structurally weaker -- separate known-issues wart). brms reachability is
#     enumerated in the roster guard so adding/removing it breaks this file.
#
# TOLERANCES (calibrated, not vibes -- see the fixture sizes below):
#   * lme4 <-> glmmTMB: both REML, agree to ~1e-4 (single level) / ~1e-3
#     (multilevel) on balanced and incomplete data.
#   * lavaan <-> glmmTMB: CONSISTENCY is exact on balanced data and near-exact
#     under FIML; ABSOLUTE AGREEMENT uses the SEM indicator-mean estimator, which
#     is only asymptotically equivalent and differs by a small-sample term
#     (icc() @param engine; Jorgensen 2021, Vispoel et al. 2022) -- hence the
#     looser agreement tolerance.

# --- Deterministic fixtures (self-contained; sizes chosen so every engine
#     converges cleanly and the calibrated tolerances hold) --------------------

pm_twoway <- function(ns, k, s2s, s2r, s2e, seed, drop = 0) {
  set.seed(seed)
  subj <- stats::rnorm(ns, 0, sqrt(s2s))
  rat <- stats::rnorm(k, 0, sqrt(s2r))
  d <- expand.grid(
    subject = factor(seq_len(ns)),
    rater = factor(seq_len(k))
  )
  d$score <- 3 +
    subj[d$subject] +
    rat[d$rater] +
    stats::rnorm(nrow(d), 0, sqrt(s2e))
  if (drop > 0) {
    d <- d[-sample.int(nrow(d), floor(drop * nrow(d))), ]
  }
  d
}

pm_crossed <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  rt <- stats::rnorm(k, 0, sqrt(vr))
  crv <- stats::rnorm(nc * k, 0, sqrt(vcr))
  d <- expand.grid(
    subj = seq_len(ns),
    cluster = seq_len(nc),
    rater = seq_len(k)
  )
  d$score <- 10 +
    cl[d$cluster] +
    scv[(d$cluster - 1) * ns + d$subj] +
    rt[d$rater] +
    crv[(d$cluster - 1) * k + d$rater] +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d
}

pm_nested <- function(nc, ns, k, vc, vsc, vrc, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  rcv <- stats::rnorm(nc * k, 0, sqrt(vrc))
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  d$score <- 10 +
    cl[d$cluster] +
    scv[(d$cluster - 1) * ns + d$subj] +
    rcv[(d$cluster - 1) * k + d$rater] +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  # cluster-unique rater labels => an unambiguous nested (Design 2) pattern
  d$rater <- factor(paste(d$cluster, d$rater, sep = "_"))
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d
}

pm_tw <- pm_twoway(40, 5, 1.0, 0.6, 0.8, seed = 11)
pm_twi <- pm_twoway(40, 5, 1.0, 0.6, 0.8, seed = 11, drop = 0.15)
pm_ml <- pm_crossed(15, 8, 5, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 11)
pm_ne <- pm_nested(20, 6, 5, 1.0, 1.2, 0.7, 0.5, seed = 11)

# --- Helpers ------------------------------------------------------------------

# Named vector of point estimates keyed by index (+ level when present).
pm_estimates <- function(fit) {
  td <- tidy(fit)
  keys <- if ("level" %in% names(td) && any(!is.na(td$level))) {
    paste(td$index, td$level, sep = "/")
  } else {
    td$index
  }
  stats::setNames(td$estimate, keys)
}

# tol is either a scalar or c(A = ., C = .) applied by index class.
pm_tol_for <- function(key, tol) {
  if (length(tol) == 1L && is.null(names(tol))) {
    return(unname(tol))
  }
  if (grepl("\\(A", key)) tol[["A"]] else tol[["C"]]
}

# --- The matrix: one cell per estimand principal variant ----------------------
# Each cell carries a `fit(engine)` closure (columns hardcoded per design),
# `agree` (engine -> tolerance the point estimates must meet vs glmmTMB), and
# `na` (engine -> classed abort that must fire; the per-line comment is its
# one-line reachability reason). glmmTMB is the reference and is present in every
# cell. Every engine (glmmTMB, lme4, lavaan) appears in every cell as either an
# `agree` or an `na` entry, so no (design, engine) pair is silently absent; brms
# is covered by the roster guard (its live parity lives in test-icc-brms.R).
#
# Spec-surface coverage (granularity = one principal variant per estimand spec,
# per the M49 plan gate): M1 two-way random, M2 two-way fixed, M3 incomplete
# random, M36 incomplete fixed, M6 one-way, M5 crossed multilevel (both levels),
# M27 crossed fixed multilevel, M8 nested (Design 2). Diagnostic/rarely-selected
# corners (M17 conflated + within-cell replicates, Design 3, cluster-level fixed)
# stay in their own estimator tests -- add a row here when one becomes a routine
# selectable design.

pm_cells <- list(
  list(
    name = "two-way random, complete (M1)",
    fit = function(e) icc(pm_tw, score, subject, rater, engine = e, seed = 1),
    agree = list(lme4 = 1e-4, lavaan = c(A = 1e-2, C = 1e-4)),
    na = list()
  ),
  list(
    name = "two-way fixed, complete (M2 / Case-3A)",
    fit = function(e) {
      icc(pm_tw, score, subject, rater, raters = "fixed", engine = e, seed = 1)
    },
    agree = list(lme4 = 1e-4, lavaan = c(A = 1e-2, C = 1e-4)),
    na = list()
  ),
  list(
    name = "two-way random, incomplete (M3 / FIML)",
    fit = function(e) icc(pm_twi, score, subject, rater, engine = e, seed = 1),
    agree = list(lme4 = 1e-3, lavaan = c(A = 2e-2, C = 3e-3)),
    na = list()
  ),
  list(
    name = "two-way fixed, incomplete (M36 / FIML)",
    fit = function(e) {
      icc(pm_twi, score, subject, rater, raters = "fixed", engine = e, seed = 1)
    },
    agree = list(lme4 = 1e-3, lavaan = c(A = 2e-2, C = 3e-3)),
    na = list()
  ),
  list(
    name = "one-way random, complete (M6)",
    fit = function(e) {
      icc(pm_tw, score, subject, rater, model = "oneway", engine = e, seed = 1)
    },
    agree = list(lme4 = 1e-4),
    # lavaan: SEM engine fits the two-way design only -- one-way is out of scope.
    na = list(lavaan = "intraclass_unsupported")
  ),
  list(
    name = "multilevel crossed random, both levels (M5)",
    fit = function(e) {
      icc(pm_ml, score, subject, rater, cluster = cluster, engine = e, seed = 1)
    },
    # lavaan (M54, D-005): two-level SEM, ML-only -- at pm_ml's N_c = 15 the
    # cluster-level agreement carries the ML-vs-REML + tau^2 small-sample
    # terms (observed max |delta| .020 A / .0017 C; both shrink with N_c).
    agree = list(lme4 = 1e-3, lavaan = c(A = 4e-2, C = 5e-3)),
    na = list()
  ),
  list(
    name = "multilevel crossed fixed, both levels (M27 / M37)",
    fit = function(e) {
      icc(
        pm_ml,
        score,
        subject,
        rater,
        cluster = cluster,
        raters = "fixed",
        engine = e,
        seed = 1
      )
    },
    # lavaan (M57): fixed-rater two-level SEM at both levels via the Case-3A
    # between-intercept correction, ML-only -- same small-sample A/C budget as
    # the M5 random cell on pm_ml (observed max |delta| .016 A / .0017 C).
    agree = list(lme4 = 1e-3, lavaan = c(A = 4e-2, C = 5e-3)),
    na = list()
  ),
  list(
    name = "multilevel nested (Design 2) random, subject level (M8)",
    fit = function(e) {
      icc(
        pm_ne,
        score,
        subject,
        rater,
        cluster = cluster,
        design = "nested_in_clusters",
        engine = e,
        seed = 1
      )
    },
    agree = list(lme4 = 1e-3),
    # lavaan: the two-level SEM mapping is crossed (Design 1) only -- no
    # nested-rater parameterization (M54).
    na = list(lavaan = "intraclass_unsupported")
  )
)

test_that("cross-engine point estimates agree on every reachable matrix cell", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("lavaan")

  for (cell in pm_cells) {
    ref <- pm_estimates(suppressWarnings(cell$fit("glmmTMB")))
    for (eng in names(cell$agree)) {
      cand <- pm_estimates(suppressWarnings(cell$fit(eng)))
      keys <- intersect(names(ref), names(cand))
      expect_true(
        length(keys) > 0L,
        label = sprintf("[%s] %s shares no index with glmmTMB", cell$name, eng)
      )
      tol <- cell$agree[[eng]]
      for (key in keys) {
        expect_lt(
          abs(ref[[key]] - cand[[key]]),
          pm_tol_for(key, tol) + .Machine$double.eps
        )
      }
    }
  }
})

test_that("every documented engine refusal fires as a classed abort", {
  skip_if_not_installed("glmmTMB")

  fired <- 0L
  for (cell in pm_cells) {
    for (eng in names(cell$na)) {
      skip_if_not_installed(eng)
      expect_error(
        suppressWarnings(cell$fit(eng)),
        class = cell$na[[eng]]
      )
      fired <- fired + 1L
    }
  }
  # Guard against the cells silently losing their N/A assertions.
  expect_gt(fired, 0L)
})

test_that("the matrix roster covers exactly icc()'s engine set (GP4)", {
  # A new engine added to icc() -- or one removed -- breaks this until the cells
  # above are updated, so the parity grid can never silently fall out of date.
  # Read the roster from icc()'s own source of truth (the validate_choice call),
  # not a hand-copied list: the default `engine =` formal is only "glmmTMB".
  icc_body <- paste(deparse(body(icc)), collapse = " ")
  roster_call <- regmatches(
    icc_body,
    regexpr("validate_choice\\(\\s*engine,\\s*c\\([^)]*\\)", icc_body)
  )
  expect_length(roster_call, 1L)
  supported <- eval(parse(text = sub(".*(c\\([^)]*\\)).*", "\\1", roster_call)))

  covered <- unique(unlist(lapply(pm_cells, function(cell) {
    c("glmmTMB", names(cell$agree), names(cell$na))
  })))
  # brms is enumerated for completeness; its live parity lives in
  # test-icc-brms.R (skip_on_ci), not re-run here.
  covered <- union(covered, "brms")

  expect_setequal(covered, supported)
})
