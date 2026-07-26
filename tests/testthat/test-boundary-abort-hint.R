# M93: the design-aware hint appended to the CI-stage boundary aborts.
#
# AC1 lives here: the reproduction that establishes WHICH abort sites a
# near-sigma^2 -> 0 dataset actually reaches. The hint is added only to sites shown
# reachable (M84: an engine point-fit can crash first and leave a downstream guard
# unreachable), so this file is the evidence the AC2 scope rests on.
#
# The three candidate CI-stage `intraclass_singular_fit` sites, by message signature
# (the message text is the only discriminator -- one class covers all three):
#   A  R/ci-montecarlo.R:43   "fitted parameter covariance is not finite"  (rmvn)
#   B  R/ci-montecarlo.R:124  "draws were non-finite"                      (mc_interval)
#   C  R/ci-bootstrap.R:48    "refits converged"                           (bootstrap_ci)

# ---- Shared boundary fixtures -----------------------------------------------
# sigma^2_subject driven to ~0 with a healthy error variance: the cell where the
# MC default aborts (D-006 one-way 28-39%; D-014 two-way 25.9/31.2%).

bh_oneway <- function(n_s = 30, n_k = 5, s2s = 1e-6, s2e = 1.0, seed = 1) {
  set.seed(seed)
  s <- stats::rnorm(n_s, sd = sqrt(s2s))
  y <- rep(s, each = n_k) + stats::rnorm(n_s * n_k, sd = sqrt(s2e))
  data.frame(
    subject = factor(rep(seq_len(n_s), each = n_k)),
    rater = factor(rep(seq_len(n_k), times = n_s)),
    score = as.numeric(y)
  )
}

bh_twoway <- function(
  n_s = 20,
  n_r = 3,
  s2s = 1e-4,
  s2r = 0.3,
  s2e = 0.6,
  seed = 1
) {
  set.seed(seed)
  s <- stats::rnorm(n_s, sd = sqrt(s2s))
  r <- stats::rnorm(n_r, sd = sqrt(s2r))
  y <- outer(s, rep(1, n_r)) +
    outer(rep(1, n_s), r) +
    matrix(stats::rnorm(n_s * n_r, sd = sqrt(s2e)), n_s, n_r)
  data.frame(
    subject = factor(rep(seq_len(n_s), times = n_r)),
    rater = factor(rep(seq_len(n_r), each = n_s)),
    score = as.numeric(y)
  )
}

# Classify an abort by its message. cli hard-wraps the rendered message, so match
# on whitespace-collapsed text -- a fixed-string grep for "draws were non-finite"
# misses a wrap that lands between the words.
bh_site <- function(msg) {
  m <- gsub("[[:space:]]+", " ", msg)
  if (grepl("covariance is not finite", m, fixed = TRUE)) {
    return("A")
  }
  if (grepl("draws were non-finite", m, fixed = TRUE)) {
    return("B")
  }
  if (grepl("refits converged", m, fixed = TRUE)) {
    return("C")
  }
  "other"
}

# Run icc() and report the abort site reached, or "ok".
bh_probe <- function(d, ...) {
  tryCatch(
    {
      suppressWarnings(suppressMessages(icc(d, score, subject, rater, ...)))
      "ok"
    },
    intraclass_singular_fit = function(e) bh_site(conditionMessage(e))
  )
}

# As bh_probe(), but also classifies a RAW unclassed error as "point-fit". On
# DEGENERATE data the glmmTMB point fit can die inside `TMB::sdreport` with an
# unclassed "LU factorization ... failed" before any CI-stage guard runs -- the M84
# lesson, and platform-dependent: macOS completes the same fit that Linux and Windows
# abort on, so a probe that lets the raw error escape is green locally and red on CI.
# Handler order matters: `intraclass_singular_fit` is registered first, so a classed
# abort still classifies by site rather than falling into the catch-all.
bh_probe_any <- function(d, ...) {
  tryCatch(
    {
      suppressWarnings(suppressMessages(icc(d, score, subject, rater, ...)))
      "ok"
    },
    intraclass_singular_fit = function(e) bh_site(conditionMessage(e)),
    error = function(e) "point-fit"
  )
}

# ---- AC1: the reproduction, and which sites it reaches -----------------------

test_that("a near-zero-variance dataset aborts through the DEFAULT MC path (AC1)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # Sweep seeds rather than pin one: the abort is a property of the boundary cell,
  # not of a particular draw, and glmmTMB's convergence is platform-sensitive.
  ow <- vapply(
    1:12,
    function(sd) {
      bh_probe(
        bh_oneway(seed = sd),
        ci_method = "montecarlo",
        model = "oneway",
        seed = 1
      )
    },
    character(1)
  )
  tw <- vapply(
    1:12,
    function(sd) {
      bh_probe(bh_twoway(seed = sd), ci_method = "montecarlo", seed = 1)
    },
    character(1)
  )

  # The default MC path aborts on a material fraction of both designs.
  expect_gt(sum(ow != "ok"), 0L)
  expect_gt(sum(tw != "ok"), 0L)

  # Every abort reached is a Monte-Carlo site (A or B), never the bootstrap site.
  expect_setequal(
    setdiff(unique(c(ow, tw)), "ok"),
    intersect(c("A", "B"), c(ow, tw))
  )
  expect_false("C" %in% c(ow, tw))
  expect_false("other" %in% c(ow, tw))

  # Site B (non-finite draws) is the dominant one -- the site the hint most needs.
  expect_gt(sum(c(ow, tw) == "B"), 0L)
})

test_that("the bootstrap abort site is NOT reachable at the sigma^2 -> 0 boundary (AC2)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # AC2 excludes R/ci-bootstrap.R:48 from the hint on this evidence. Pinning it here
  # (GP7) means the exclusion cannot rot silently: if a future engine change makes
  # boundary refits fail, this reds and the exclusion is revisited rather than
  # quietly becoming wrong.
  res <- vapply(
    1:4,
    function(sd) {
      bh_probe(
        bh_oneway(n_s = 8, n_k = 3, s2s = 0, seed = sd),
        ci_method = "bootstrap",
        model = "oneway",
        boot_samples = 40L,
        seed = 1
      )
    },
    character(1)
  )
  expect_true(all(res == "ok"))
})

test_that("the reachable bootstrap abort takes DEGENERATE data, where no method helps (AC2)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # What DOES reach site C: zero within-subject variance. On such data every method
  # the mapping table would name aborts too, so a hint there would point at another
  # abort -- exactly what AC3 makes a test failure. This is why AC2 excludes it.
  d <- data.frame(
    subject = factor(rep(1:3, each = 2)),
    rater = factor(rep(1:2, times = 3)),
    score = rep(c(1, 5, 9), each = 2)
  )
  # Two outcomes both support the exclusion, and which one occurs is a platform
  # fact, not a contract: "C" is the bootstrap guard firing (macOS), "point-fit" is
  # the engine dying on the same table before any CI-stage guard is reached
  # (Linux/Windows). The second is the STRONGER form of the finding -- there the
  # bootstrap site is not even reached -- so accept either and pin that it is never
  # a Monte-Carlo site, which is what the AC2 exclusion actually rests on.
  site <- bh_probe_any(
    d,
    ci_method = "bootstrap",
    model = "oneway",
    boot_samples = 30L,
    seed = 1
  )
  # `info` (not expect_in(), which needs a newer testthat than DESCRIPTION pins)
  # so a failure names the site actually reached.
  expect_true(
    site %in% c("C", "point-fit"),
    info = paste("site reached:", site)
  )

  # Every method the mapping table would name aborts on this data too. The abort
  # CLASS is deliberately not asserted: our own guards raise
  # `intraclass_singular_fit`, but on the platforms above glmmTMB's raw point-fit
  # error arrives first, and the claim AC2 needs is "no method helps here".
  for (m in c("npbootstrap", "searle", "burch")) {
    expect_error(
      suppressWarnings(suppressMessages(
        icc(d, score, subject, rater, ci_method = m, model = "oneway")
      ))
    )
  }
})

# ---- AC2/AC4: the hint builder, every row of the mapping table ----------------
# boundary_method_hint() is a PURE function of the fence predicates, so it is
# exercised directly here; the AC3 grid below then proves the methods it names are
# genuinely accepted by icc() end to end.

bh_hint <- function(...) {
  defaults <- list(
    oneway = FALSE,
    multilevel = FALSE,
    replicates = FALSE,
    raters = "random",
    balanced = TRUE,
    type = c("agreement", "consistency"),
    type_supplied = FALSE,
    conf_level = 0.95,
    # A geometry ON the kappa_m grid, so a row that should hint does; the F1 tests
    # below move it off the grid deliberately.
    n_s = 20L,
    n_r = 3L,
    degenerate = FALSE
  )
  do.call(boundary_method_hint, utils::modifyList(defaults, list(...)))
}

test_that("balanced one-way is hinted at the two DETERMINISTIC methods (AC2)", {
  h <- bh_hint(oneway = TRUE, balanced = TRUE)
  expect_length(h, 1L)
  expect_named(h, "i")
  for (m in c("searle", "burch")) {
    expect_match(h[["i"]], m, fixed = TRUE)
  }
  expect_no_match(h[["i"]], "mpl", fixed = TRUE)
  # npbootstrap is deliberately NOT named here, at any subject count. D-012's 0-abort
  # evidence is a searle/burch result, and npbootstrap's resample guard fires routinely
  # below 15 subjects -- the AC3-forbidden shape (M93 pass-2 F1).
  expect_no_match(h[["i"]], "npbootstrap", fixed = TRUE)
  for (n in c(5L, 10L, 15L, 30L, 100L)) {
    expect_no_match(
      bh_hint(oneway = TRUE, balanced = TRUE, n_s = n)[["i"]],
      "npbootstrap",
      fixed = TRUE
    )
  }
})

test_that("unbalanced one-way gets NO hint, at any subject count (AC2/AC4)", {
  # `searle`/`burch` are balanced-only (D-013) and `npbootstrap` -- the only method
  # shipping this cell -- is named on no design at all: its second abort is a
  # RESAMPLE-stage guard, stochastic and invisible to any design predicate, which is
  # why two review passes fenced it wrongly. M97 revisits it behind a data-derived
  # stability predicate; until then the row is silent everywhere.
  for (n in c(2L, 5L, 10L, 15L, 20L, 60L)) {
    expect_length(bh_hint(oneway = TRUE, balanced = FALSE, n_s = n), 0L)
  }
})

test_that("the balanced two-way random agreement cell is hinted at mpl (AC2)", {
  h <- bh_hint()
  expect_length(h, 1L)
  expect_match(h[["i"]], "mpl", fixed = TRUE)
  # An unset `type` still resolves: icc() narrows the default to agreement for mpl.
  expect_length(
    bh_hint(type = c("agreement", "consistency"), type_supplied = FALSE),
    1L
  )
  expect_length(bh_hint(type = "agreement", type_supplied = TRUE), 1L)
})

test_that("designs with no boundary-robust opt-in get NO method hint (AC4)", {
  # Each of these is a genuine fence: naming any method here would be an abort.
  expect_length(bh_hint(raters = "fixed"), 0L)
  expect_length(bh_hint(multilevel = TRUE), 0L)
  expect_length(bh_hint(replicates = TRUE), 0L)
  expect_length(bh_hint(type = "consistency", type_supplied = TRUE), 0L)
  expect_length(
    bh_hint(type = c("agreement", "consistency"), type_supplied = TRUE),
    0L
  )
  expect_length(bh_hint(balanced = FALSE), 0L)
  expect_length(bh_hint(oneway = TRUE, balanced = FALSE), 0L)
  # An mpl-shaped design at an UNCALIBRATED conf_level: the kappa_m correction is
  # calibrated per level and never interpolated across levels (M91/D-017).
  expect_length(bh_hint(conf_level = 0.80), 0L)
  expect_length(bh_hint(conf_level = 0.975), 0L)
  # A cluster or replicate facet dominates every other predicate, one-way included.
  expect_length(bh_hint(oneway = TRUE, multilevel = TRUE), 0L)
  expect_length(bh_hint(oneway = TRUE, replicates = TRUE), 0L)
})

test_that("the hinted conf_level set is READ from the shipped table, not hardcoded (AC4)", {
  # Every calibrated level hints; the guard is that this tracks the table, so adding
  # or removing a level cannot leave the hint claiming a level that no longer exists.
  for (cl in sort(unique(kappa_m_table$conf_level))) {
    expect_length(bh_hint(conf_level = cl), 1L)
  }
  # A level strictly between two calibrated ones is still refused.
  expect_length(bh_hint(conf_level = 0.92), 0L)
})

# ---- AC2/AC5: threaded end to end, additively --------------------------------

# Render an abort's message to plain text, or NA if icc() did not abort.
bh_msg <- function(d, ...) {
  tryCatch(
    {
      suppressWarnings(suppressMessages(icc(d, score, subject, rater, ...)))
      NA_character_
    },
    intraclass_singular_fit = function(e) {
      gsub("[[:space:]]+", " ", cli::ansi_strip(conditionMessage(e)))
    }
  )
}

# The first seed in 1:12 whose default-MC fit aborts, for a given data builder.
bh_first_abort <- function(build, ...) {
  for (sd in 1:12) {
    m <- bh_msg(build(seed = sd), ci_method = "montecarlo", seed = 1, ...)
    if (!is.na(m)) {
      return(m)
    }
  }
  NULL
}

test_that("the hint reaches the real abort for the design in hand (AC2)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  m_ow <- bh_first_abort(bh_oneway, model = "oneway")
  skip_if(
    is.null(m_ow),
    "no one-way MC abort in the seed sweep (boundary luck)"
  )
  # `bh_oneway()` is a BALANCED 30x5 design, so the hint names the two deterministic
  # closed forms and deliberately not the bootstrap (M93 pass-2 F1).
  for (s in c("searle", "burch")) {
    expect_match(m_ow, s, fixed = TRUE)
  }
  expect_no_match(m_ow, "npbootstrap", fixed = TRUE)

  m_tw <- bh_first_abort(bh_twoway)
  skip_if(
    is.null(m_tw),
    "no two-way MC abort in the seed sweep (boundary luck)"
  )
  expect_match(m_tw, "ci_method = \"mpl\"", fixed = TRUE)
  # The two-way random hint must NOT offer the one-way methods, and vice versa.
  for (s in c("searle", "burch")) {
    expect_no_match(m_tw, s, fixed = TRUE)
  }
  expect_no_match(m_ow, "\"mpl\"", fixed = TRUE)
})

test_that("the hint is ADDITIVE: class, lead and generic remedies unchanged (AC2)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  m <- bh_first_abort(bh_twoway)
  skip_if(is.null(m), "no two-way MC abort in the seed sweep (boundary luck)")
  # Leading message and BOTH pre-existing generic remedies survive verbatim.
  expect_match(
    m,
    "The Monte-Carlo interval could not be computed",
    fixed = TRUE
  )
  expect_match(m, "which indicates an unstable fit", fixed = TRUE)
  expect_match(m, "or inspect the model", fixed = TRUE)

  # A design with no opt-in method keeps EXACTLY those remedies and gains nothing --
  # this is what makes the additivity claim testable rather than asserted.
  m_fixed <- bh_first_abort(bh_twoway, raters = "fixed")
  skip_if(is.null(m_fixed), "no fixed-rater MC abort in the seed sweep")
  expect_match(m_fixed, "or inspect the model", fixed = TRUE)
  for (s in c("searle", "burch", "npbootstrap", "\"mpl\"")) {
    expect_no_match(m_fixed, s, fixed = TRUE)
  }
})

test_that("the contract is unchanged: still aborts, still returns no interval (AC5)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # Nothing here implements the D-012-fenced fallback-on-abort default: the hint
  # tells the user what to switch to, it does not switch for them.
  found <- FALSE
  for (sd in 1:12) {
    d <- bh_twoway(seed = sd)
    got <- tryCatch(
      {
        suppressWarnings(suppressMessages(
          icc(d, score, subject, rater, ci_method = "montecarlo", seed = 1)
        ))
      },
      intraclass_singular_fit = function(e) e
    )
    if (inherits(got, "condition")) {
      found <- TRUE
      expect_s3_class(got, "intraclass_singular_fit")
      expect_s3_class(got, "rlang_error")
      # An error, not a value: no interval is produced on this path.
      expect_false(inherits(got, "icc"))
      break
    }
  }
  skip_if_not(found, "no two-way MC abort in the seed sweep (boundary luck)")
})

test_that("d_study() and the lavaan engine are untouched by the threading (AC2)", {
  # mc_components()/mc_interval()/rmvn() gained a defaulted `hint`; every other
  # caller passes none, so their behaviour is byte-identical. rmvn() is called
  # POSITIONALLY by the lavaan engine, so the new argument must sit after `call`.
  expect_identical(formals(rmvn)$hint, quote(character(0)))
  expect_identical(
    names(formals(rmvn))[1:4],
    c("n", "mu", "covariance", "call")
  )
  expect_identical(formals(mc_components)$hint, quote(character(0)))
  expect_identical(formals(mc_interval)$hint, quote(character(0)))
  expect_identical(formals(mc_ci)$hint, quote(character(0)))
})

# ---- AC3: the GP7 guard -- every method the hint names is ACCEPTED ------------
# The mapping table in the milestone mirrors icc()'s ci_method fences. Mirroring
# rots silently: a later fence change would leave the hint pointing at a method
# that now aborts, which is worse than no hint at all. So for every design in the
# grid, this asserts icc() genuinely accepts each method the hint names for it --
# on HEALTHY data, so an abort here means the fence moved, not that the fit is at
# the boundary.

# Healthy (non-boundary) builders: sigma^2_subject well away from 0.
bh_ok_oneway <- function(sizes = rep(5L, 20L), seed = 11) {
  set.seed(seed)
  n_s <- length(sizes)
  s <- stats::rnorm(n_s, sd = 1)
  data.frame(
    subject = factor(rep(seq_len(n_s), times = sizes)),
    rater = factor(sequence(sizes)),
    score = rep(s, times = sizes) + stats::rnorm(sum(sizes), sd = 0.7)
  )
}

bh_ok_twoway <- function(n_s = 20L, n_r = 3L, seed = 11) {
  set.seed(seed)
  s <- stats::rnorm(n_s, sd = 1)
  r <- stats::rnorm(n_r, sd = 0.4)
  y <- outer(s, rep(1, n_r)) +
    outer(rep(1, n_s), r) +
    matrix(stats::rnorm(n_s * n_r, sd = 0.7), n_s, n_r)
  data.frame(
    subject = factor(rep(seq_len(n_s), times = n_r)),
    rater = factor(rep(seq_len(n_r), each = n_s)),
    score = as.numeric(y)
  )
}

# Pull the method strings out of a rendered hint.
bh_named_methods <- function(h) {
  if (!length(h)) {
    return(character(0))
  }
  all <- c("npbootstrap", "searle", "burch", "mpl")
  all[vapply(
    all,
    function(m) {
      grepl(paste0("\"", m, "\""), h[["i"]], fixed = TRUE)
    },
    logical(1)
  )]
}

test_that("every ci_method the hint names is ACCEPTED on that design (AC3, GP7)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # Each row carries the predicates icc() computes for that design, by construction.
  grid <- list(
    list(
      lab = "one-way balanced",
      data = bh_ok_oneway(),
      args = list(model = "oneway"),
      pred = list(oneway = TRUE, balanced = TRUE)
    ),
    list(
      lab = "two-way random agreement",
      data = bh_ok_twoway(),
      args = list(type = "agreement"),
      pred = list(type = "agreement", type_supplied = TRUE)
    ),
    list(
      lab = "two-way random, unset type",
      data = bh_ok_twoway(),
      args = list(),
      pred = list()
    )
  )

  for (row in grid) {
    h <- do.call(bh_hint, row$pred)
    methods <- bh_named_methods(h)
    expect_gt(length(methods), 0L) # every row above SHOULD get a hint
    for (m in methods) {
      args <- c(
        list(
          row$data,
          quote(score),
          quote(subject),
          quote(rater),
          ci_method = m
        ),
        row$args
      )
      # Fold the row label into the compared value: expect_no_error() takes no
      # `info` in 3e, and a bare failure would not say WHICH design/method broke.
      status <- tryCatch(
        {
          suppressWarnings(suppressMessages(do.call(icc, args)))
          "accepted"
        },
        error = function(e) paste0("ABORTED ", class(e)[[1]])
      )
      expect_identical(
        paste(row$lab, "->", m, ":", status),
        paste(row$lab, "->", m, ": accepted")
      )
    }
  }
})

test_that("designs the hint stays silent on are the ones that would abort (AC3/AC4)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # The converse half of the guard: where the hint says nothing, every opt-in method
  # really does abort -- so silence is correct, not merely cautious.
  d <- bh_ok_twoway()
  expect_length(bh_hint(raters = "fixed"), 0L)
  for (m in c("mpl", "npbootstrap", "searle", "burch")) {
    expect_error(
      suppressWarnings(suppressMessages(
        icc(d, score, subject, rater, raters = "fixed", ci_method = m)
      )),
      class = "intraclass_unsupported"
    )
  }

  # Explicit consistency: mpl has no ICC(C,.) interval.
  expect_length(bh_hint(type = "consistency", type_supplied = TRUE), 0L)
  expect_error(
    suppressWarnings(suppressMessages(
      icc(d, score, subject, rater, type = "consistency", ci_method = "mpl")
    )),
    class = "intraclass_unsupported"
  )

  # An uncalibrated conf_level.
  expect_length(bh_hint(conf_level = 0.80), 0L)
  expect_error(
    suppressWarnings(suppressMessages(
      icc(d, score, subject, rater, ci_method = "mpl", conf_level = 0.80)
    )),
    class = "intraclass_unsupported"
  )

  # Unbalanced one-way: silent, and the two deterministic methods really are refused
  # there (D-013 fences them to balanced), so silence is a fence and not caution.
  # `npbootstrap` is the exception the silence is NOT justified by -- icc() accepts it
  # here -- which is exactly why M97 owns that row rather than this milestone: what
  # disqualifies it is a resample-stage guard, not the fence this loop can see.
  du <- bh_ok_oneway(sizes = c(rep(5L, 15L), rep(3L, 5L)))
  expect_length(bh_hint(oneway = TRUE, balanced = FALSE), 0L)
  for (m in c("searle", "burch")) {
    expect_error(
      suppressWarnings(suppressMessages(
        icc(du, score, subject, rater, model = "oneway", ci_method = m)
      )),
      class = "intraclass_unsupported"
    )
  }
})

# ---- AC2/AC3/AC4: the two inputs that are not design fences ------------------
# Review pass 1 caught the hint naming methods that then abort. Neither cause is
# visible in the design predicates: F1 is the kappa_m calibration GEOMETRY (icc()'s
# own mpl fence checks the design and the conf_level, never the (n_r, n_s) grid), and
# F2 is the DATA (a perfectly ordinary balanced one-way design can carry scores on
# which searle, burch and npbootstrap all abort).

test_that("the mpl hint is gated on the kappa_m grid, read from the table (AC3, F1)", {
  # Read the nodes from the shipped table, so this tracks a recalibration instead of
  # pinning today's 2-10 raters / 10-100 subjects as literals.
  s_nodes <- sort(unique(kappa_m_table$n_s))
  r_nodes <- sort(unique(kappa_m_table$n_r))

  # Off the grid -> silence. `n_s` is interpolated WITHIN its range but never
  # extrapolated, and `n_r` must be an exact node -- the same three conditions
  # mpl_kappa_lookup() aborts on.
  expect_length(bh_hint(n_s = min(s_nodes) - 1L), 0L)
  expect_length(bh_hint(n_s = max(s_nodes) + 1L), 0L)
  expect_length(bh_hint(n_r = max(r_nodes) + 1L), 0L)

  # On the grid -> the hint stands, at the edges and between subject nodes.
  expect_length(bh_hint(n_s = min(s_nodes)), 1L)
  expect_length(bh_hint(n_s = max(s_nodes)), 1L)
  expect_length(bh_hint(n_s = min(s_nodes) + 1L), 1L)
  for (r in r_nodes) {
    expect_length(bh_hint(n_r = r), 1L)
  }

  # The gate IS the lookup, not a restatement of it: wherever the hint fires the
  # lookup returns a kappa_m, and wherever it is silent the lookup aborts.
  for (n_s in c(min(s_nodes) - 1L, min(s_nodes), 37L, max(s_nodes) + 1L)) {
    hinted <- length(bh_hint(n_s = n_s)) > 0L
    resolves <- tryCatch(
      is.finite(mpl_kappa_lookup(3L, n_s, conf_level = 0.95)),
      intraclass_unsupported = function(e) FALSE
    )
    expect_identical(paste("n_s", n_s, hinted), paste("n_s", n_s, resolves))
  }
})

test_that("an off-grid mpl design is not hinted end to end (AC3, F1)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # 8 subjects x 3 raters: exactly the design review pass 1 reproduced, where the
  # default abort recommended `ci_method = "mpl"` and mpl then aborted on the same
  # data. Small designs are the ones that sit at this boundary, so this is the
  # common case, not a corner.
  small <- function(seed) bh_twoway(n_s = 8, seed = seed)
  m <- bh_first_abort(small)
  skip_if(
    is.null(m),
    "no MC abort at 8 subjects in the seed sweep (boundary luck)"
  )
  expect_no_match(m, "mpl", fixed = TRUE)
  # ...and the reason it must not be named: mpl aborts on that very design.
  expect_error(
    suppressWarnings(suppressMessages(
      icc(small(1), score, subject, rater, ci_method = "mpl")
    )),
    class = "intraclass_unsupported"
  )
})

# Degenerate builders, and the distinction that pass-3 F2 turned on. bh_degen_within:
# scores constant within subject (MSE = 0), where `classical_guard_observed()` fires and
# both searle and burch abort -- genuinely degenerate FOR THIS ROW. bh_degen_between:
# every subject mean identical (SSA = 0, MSE > 0), where searle and burch both return
# intervals -- NOT degenerate for this row, though it does kill `npbootstrap`, and a
# gate that ORed npbootstrap's conditions in silenced the hint on ordinary boundary
# data. bh_degen_flat: no variance at all, the two-way case where mpl's optim dies at
# its initial parameters.
bh_degen_within <- function(n_s = 10, n_k = 3) {
  set.seed(7)
  data.frame(
    subject = factor(rep(seq_len(n_s), each = n_k)),
    rater = factor(rep(seq_len(n_k), times = n_s)),
    score = rep(stats::rnorm(n_s), each = n_k)
  )
}
bh_degen_between <- function(n_s = 10, n_k = 3) {
  data.frame(
    subject = factor(rep(seq_len(n_s), each = n_k)),
    rater = factor(rep(seq_len(n_k), times = n_s)),
    score = rep(seq_len(n_k) - mean(seq_len(n_k)), times = n_s)
  )
}
bh_degen_flat <- function(n_s = 20, n_r = 3) {
  data.frame(
    subject = factor(rep(seq_len(n_s), times = n_r)),
    rater = factor(rep(seq_len(n_r), each = n_s)),
    score = rep(4, n_s * n_r)
  )
}

# As bh_msg(), but renders a RAW error's message too (degenerate data can kill the
# point fit outright, platform-depending). Either way the assertion is the same:
# whatever the user is told, it names no method.
bh_msg_any <- function(d, ...) {
  tryCatch(
    {
      suppressWarnings(suppressMessages(icc(d, score, subject, rater, ...)))
      NA_character_
    },
    error = function(e) {
      gsub("[[:space:]]+", " ", cli::ansi_strip(conditionMessage(e)))
    }
  )
}

test_that("the degeneracy flag fires exactly where the row's OWN guard fires (AC2, F2)", {
  # One-way: the flag IS `classical_guard_observed()`, asked rather than restated, so
  # it must agree with that guard case by case -- including where it must NOT fire.
  expect_true(boundary_data_degenerate(bh_degen_within(), oneway = TRUE))
  expect_false(boundary_data_degenerate(bh_degen_between(), oneway = TRUE))
  expect_true(boundary_data_degenerate(bh_degen_flat(), oneway = FALSE))
  # Healthy data are not degenerate, on either branch -- including data sitting at
  # the sigma^2 -> 0 boundary, which is the case the hint exists FOR.
  expect_false(boundary_data_degenerate(bh_ok_oneway(), oneway = TRUE))
  expect_false(boundary_data_degenerate(bh_oneway(), oneway = TRUE))
  expect_false(boundary_data_degenerate(bh_ok_twoway(), oneway = FALSE))
  expect_false(boundary_data_degenerate(bh_twoway(), oneway = FALSE))
  # The flag agrees with the shipped guard's own verdict, not with a copy of its
  # condition: run searle on each case and require the two to match. This is what
  # makes "asked, not restated" testable -- a drifting restatement reds here.
  for (case in list(
    list(lab = "within", d = bh_degen_within()),
    list(lab = "between", d = bh_degen_between()),
    list(lab = "healthy", d = bh_ok_oneway())
  )) {
    # Catch ANY error, not just the classed one: on MSE = 0 data the glmmTMB point
    # fit can die with a raw unclassed error before the classical guard is reached,
    # platform-depending (M84). Either way the user gets no interval, which is the
    # thing the flag has to agree with.
    aborts <- inherits(
      tryCatch(
        suppressWarnings(suppressMessages(
          icc(
            case$d,
            score,
            subject,
            rater,
            model = "oneway",
            ci_method = "searle"
          )
        )),
        error = function(e) e
      ),
      "condition"
    )
    expect_identical(
      paste(case$lab, boundary_data_degenerate(case$d, oneway = TRUE)),
      paste(case$lab, aborts)
    )
  }
  # A degenerate flag beats its own design row, one-way and two-way alike.
  expect_length(bh_hint(oneway = TRUE, balanced = TRUE, degenerate = TRUE), 0L)
  expect_length(bh_hint(degenerate = TRUE), 0L)
})

test_that("data degenerate FOR THE ROW get no hint; data that are not still do (AC3/AC4, F2)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # Where the row's own methods abort, the abort names nothing.
  for (case in list(
    list(lab = "within", d = bh_degen_within(), args = list(model = "oneway")),
    list(lab = "flat", d = bh_degen_flat(), args = list())
  )) {
    m <- do.call(
      bh_msg_any,
      c(list(case$d, ci_method = "montecarlo", seed = 1), case$args)
    )
    skip_if(is.na(m), paste("no abort on the", case$lab, "degenerate case"))
    for (s in c("searle", "burch", "npbootstrap", "mpl")) {
      expect_identical(
        paste(case$lab, s, grepl(s, m, fixed = TRUE)),
        paste(case$lab, s, FALSE)
      )
    }
  }
  # ...and they abort, so the silence is a fence rather than caution.
  for (mm in c("searle", "burch")) {
    expect_error(suppressWarnings(suppressMessages(
      icc(
        bh_degen_within(),
        score,
        subject,
        rater,
        ci_method = mm,
        model = "oneway"
      )
    )))
  }
  expect_error(suppressWarnings(suppressMessages(
    icc(bh_degen_flat(), score, subject, rater, ci_method = "mpl")
  )))

  # The other direction, and the pass-3 F2 regression this pins: SSA = 0 balanced
  # one-way (every subject mean exactly equal, MSE > 0) is NOT degenerate for the
  # classical row. The default aborts there, searle and burch both return intervals,
  # and a shared gate ORing npbootstrap's own conditions in used to silence the hint
  # on exactly this data -- the case the milestone exists to serve.
  db <- bh_degen_between()
  m <- bh_msg_any(db, ci_method = "montecarlo", model = "oneway", seed = 1)
  skip_if(is.na(m), "no abort on the SSA = 0 case")
  for (s in c("searle", "burch")) {
    expect_identical(
      paste("between", s, grepl(s, m, fixed = TRUE)),
      paste("between", s, TRUE)
    )
    status <- tryCatch(
      {
        suppressWarnings(suppressMessages(
          icc(db, score, subject, rater, model = "oneway", ci_method = s)
        ))
        "accepted"
      },
      error = function(e) paste0("ABORTED ", class(e)[[1]])
    )
    expect_identical(
      paste("between", s, status),
      paste("between", s, "accepted")
    )
  }
  # The bootstrap does abort on it, and is correctly not named.
  expect_false(grepl("npbootstrap", m, fixed = TRUE))
  expect_error(suppressWarnings(suppressMessages(
    icc(
      db,
      score,
      subject,
      rater,
      ci_method = "npbootstrap",
      model = "oneway",
      boot_samples = 50L,
      seed = 1
    )
  )))
})

# ---- AC3: the designs the criterion enumerates, end to end -------------------
# The grid above covers one-way and two-way random at ONE geometry, exercised through
# icc(); AC3 enumerates more than that, and the gap is how F1 shipped green -- a grid
# that never varies n_s/n_r cannot see a geometry fence, and a design checked only as
# a pure-function call never proves icc() agrees with the predicates it is handed.

# Subjects nested in clusters, raters crossed with both (ten Hove Design 1 shape).
bh_ok_multilevel <- function(n_c = 5L, n_s = 4L, n_r = 3L, seed = 11) {
  set.seed(seed)
  g <- expand.grid(
    subj = seq_len(n_s),
    cluster = seq_len(n_c),
    rater = seq_len(n_r)
  )
  cl <- stats::rnorm(n_c, sd = 1)
  rt <- stats::rnorm(n_r, sd = 0.4)
  sc <- stats::rnorm(n_c * n_s, sd = 0.9)
  data.frame(
    subject = factor(paste(g$cluster, g$subj, sep = "_")),
    rater = factor(g$rater),
    cluster = factor(g$cluster),
    score = cl[g$cluster] +
      sc[(g$cluster - 1L) * n_s + g$subj] +
      rt[g$rater] +
      stats::rnorm(nrow(g), sd = 0.6)
  )
}

# Two ratings per subject x rater cell: within-cell replicates, auto-detected.
bh_ok_replicates <- function(n_s = 12L, n_r = 3L, n_o = 2L, seed = 11) {
  set.seed(seed)
  g <- expand.grid(
    subject = seq_len(n_s),
    rater = seq_len(n_r),
    occ = seq_len(n_o)
  )
  s <- stats::rnorm(n_s, sd = 1)
  r <- stats::rnorm(n_r, sd = 0.4)
  sr <- stats::rnorm(n_s * n_r, sd = 0.3)
  data.frame(
    subject = factor(g$subject),
    rater = factor(g$rater),
    score = s[g$subject] +
      r[g$rater] +
      sr[(g$rater - 1L) * n_s + g$subject] +
      stats::rnorm(nrow(g), sd = 0.6)
  )
}

test_that("a hint fires on every kappa_m geometry it claims, end to end (AC3)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # Vary the geometry, which the single-geometry grid above never did: the smallest
  # calibrated design, and a wider one. Both must hint AND be accepted by icc().
  geoms <- list(c(n_s = 10L, n_r = 2L), c(n_s = 15L, n_r = 5L))
  for (g in geoms) {
    lab <- paste0(g[["n_s"]], "x", g[["n_r"]])
    h <- bh_hint(n_s = g[["n_s"]], n_r = g[["n_r"]])
    expect_identical(paste(lab, bh_named_methods(h)), paste(lab, "mpl"))
    d <- bh_ok_twoway(n_s = g[["n_s"]], n_r = g[["n_r"]])
    status <- tryCatch(
      {
        suppressWarnings(suppressMessages(
          icc(d, score, subject, rater, ci_method = "mpl")
        ))
        "accepted"
      },
      error = function(e) paste0("ABORTED ", class(e)[[1]])
    )
    expect_identical(paste(lab, status), paste(lab, "accepted"))
  }
})

test_that("multilevel, replicate and off-grid designs stay silent, and abort (AC3/AC4)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # The remaining AC3 rows, each run THROUGH icc() rather than as a predicate call:
  # the hint is silent, and every opt-in method really does abort there.
  cases <- list(
    list(
      lab = "multilevel",
      data = bh_ok_multilevel(),
      args = list(cluster = quote(cluster)),
      pred = list(multilevel = TRUE)
    ),
    list(
      lab = "within-cell replicates",
      data = bh_ok_replicates(),
      args = list(),
      pred = list(replicates = TRUE)
    ),
    list(
      lab = "two-way off the kappa_m grid",
      data = bh_ok_twoway(n_s = 8L),
      args = list(),
      pred = list(n_s = 8L)
    )
  )

  for (case in cases) {
    expect_length(do.call(bh_hint, case$pred), 0L)
    for (m in c("mpl", "npbootstrap", "searle", "burch")) {
      args <- c(
        list(
          case$data,
          quote(score),
          quote(subject),
          quote(rater),
          ci_method = m
        ),
        case$args
      )
      status <- tryCatch(
        {
          suppressWarnings(suppressMessages(do.call(icc, args)))
          "accepted"
        },
        error = function(e) paste0("aborted ", class(e)[[1]])
      )
      expect_identical(
        paste(case$lab, "->", m, ":", status),
        paste(case$lab, "->", m, ": aborted intraclass_unsupported")
      )
    }
  }
})

# ---- AC3: the sweep, driven by the REAL message -------------------------------
# This is the criterion's central evidence, and the only test here that derives nothing
# by hand. Everything above computes the hint from a predicate list; three review passes
# showed that is how a wrong hint ships green, because the grid asserts what the author
# believed icc() would compute rather than what it does. So: build a design, fire the
# real default abort, PARSE the method names out of the message it actually raised, and
# run each one on that same data. A method named and then aborting is a failure, which
# is the property AC3 states.

# Small-integer 1-3 ratings treated as continuous: ordinary interrater data sitting at
# the sigma^2 -> 0 boundary, which is where the default MC aborts and where small-n
# bootstrap resamples go degenerate. Named for what it is -- small integers analysed as
# continuous scores -- and deliberately NOT for the discrete-outcome axis the package
# neither handles nor studies: a committed references page carries a CI-checked
# observation that that axis's name is absent from R/ and tests/, and borrowing the word
# for a fixture would falsify a true claim (`data-raw/check-reference-observations.py`).
bh_smallint <- function(n_s, n_k, seed, balanced = TRUE) {
  set.seed(seed)
  sizes <- if (balanced) {
    rep(n_k, n_s)
  } else {
    rep(c(n_k, n_k - 1L), length.out = n_s)
  }
  data.frame(
    subject = factor(rep(seq_len(n_s), times = sizes)),
    rater = factor(sequence(sizes)),
    score = sample(1:3, sum(sizes), replace = TRUE)
  )
}

# Parse the `ci_method = "x"` names out of a rendered abort message.
bh_msg_methods <- function(m) {
  all <- c("npbootstrap", "searle", "burch", "mpl")
  all[vapply(
    all,
    function(x) grepl(paste0("\"", x, "\""), m, fixed = TRUE),
    logical(1)
  )]
}

# One sweep cell: `build(seed)` -> a data frame, `args` -> the icc() arguments that
# design needs. Returns the cells checked, so a vacuous pass is visible.
bh_sweep_cell <- function(
  lab,
  build,
  args,
  seeds = 1:6,
  forbid = character(0)
) {
  checked <- 0L
  for (sd in seeds) {
    d <- build(sd)
    m <- do.call(
      bh_msg_any,
      c(list(d, ci_method = "montecarlo", seed = 1), args)
    )
    if (is.na(m)) {
      next
    }
    named <- bh_msg_methods(m)
    tag <- paste(lab, "seed", sd)
    # Methods this design must never be offered (e.g. a two-way method on a one-way
    # fit), asserted on the parsed names rather than on the predicate list.
    for (bad in forbid) {
      expect_identical(
        paste(tag, bad, "named:", bad %in% named),
        paste(tag, bad, "named:", FALSE)
      )
    }
    for (meth in named) {
      checked <- checked + 1L
      status <- tryCatch(
        {
          suppressWarnings(suppressMessages(do.call(
            icc,
            c(
              list(d, quote(score), quote(subject), quote(rater)),
              args,
              list(ci_method = meth, seed = 1)
            )
          )))
          "accepted"
        },
        error = function(e) paste0("ABORTED ", class(e)[[1]])
      )
      expect_identical(
        paste(tag, "->", meth, ":", status),
        paste(tag, "->", meth, ": accepted")
      )
    }
  }
  checked
}

test_that("every method the REAL abort names is accepted, across one-way sizes (AC3)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  cells <- list(
    list(n_s = 5L, n_k = 2L, bal = TRUE),
    list(n_s = 8L, n_k = 3L, bal = TRUE),
    list(n_s = 10L, n_k = 2L, bal = TRUE),
    list(n_s = 12L, n_k = 2L, bal = TRUE),
    list(n_s = 20L, n_k = 3L, bal = TRUE),
    list(n_s = 5L, n_k = 3L, bal = FALSE),
    list(n_s = 10L, n_k = 3L, bal = FALSE),
    list(n_s = 20L, n_k = 3L, bal = FALSE)
  )

  checked <- 0L
  for (cell in cells) {
    checked <- checked +
      bh_sweep_cell(
        lab = paste0(
          if (cell$bal) "balanced " else "unbalanced ",
          cell$n_s,
          "x",
          cell$n_k
        ),
        build = function(sd) {
          bh_smallint(cell$n_s, cell$n_k, sd, balanced = cell$bal)
        },
        args = list(model = "oneway"),
        # A two-way method must never be named on a one-way fit; and the bootstrap
        # is named on no design at all until M97 lands its stability predicate.
        forbid = c("mpl", "npbootstrap")
      )
  }
  # The sweep must actually have exercised something; a silent zero passes vacuously.
  expect_gt(checked, 0L)
})

test_that("every method the REAL abort names is accepted, two-way and degenerate (AC3)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  s_nodes <- sort(unique(kappa_m_table$n_s))
  checked <- 0L

  # Two-way random: on the kappa_m grid at two geometries, off it below the grid's
  # smallest subject count, with `type` both unset and supplied.
  for (cell in list(
    list(lab = "two-way 20x3 on-grid", n_s = 20L, args = list()),
    list(lab = "two-way 10x3 on-grid", n_s = 10L, args = list()),
    list(
      lab = "two-way 20x3 type supplied",
      n_s = 20L,
      args = list(type = "agreement")
    ),
    list(
      lab = "two-way off-grid",
      n_s = min(s_nodes) - 2L,
      args = list()
    )
  )) {
    checked <- checked +
      bh_sweep_cell(
        lab = cell$lab,
        build = function(sd) bh_twoway(n_s = cell$n_s, seed = sd),
        args = cell$args,
        forbid = c("searle", "burch", "npbootstrap")
      )
  }

  # Designs with no opt-in at all: the abort must name nothing, so `forbid` covers
  # every method and the accepted loop has nothing to run.
  checked <- checked +
    bh_sweep_cell(
      lab = "fixed raters",
      build = function(sd) bh_twoway(seed = sd),
      args = list(raters = "fixed"),
      forbid = c("mpl", "searle", "burch", "npbootstrap")
    )

  # Degenerate data, both branches: whatever is named must still be accepted. SSA = 0
  # is the case where searle/burch ARE named (pass-3 F2), so it is asserted NON-vacuous
  # -- this sweep tests "named => accepted", under which a silenced hint passes for
  # free, and over-suppression is exactly how that cell would go quiet.
  ssa0 <- bh_sweep_cell(
    lab = "one-way SSA = 0",
    build = function(sd) bh_degen_between(),
    args = list(model = "oneway"),
    seeds = 1L,
    forbid = c("mpl", "npbootstrap")
  )
  expect_gt(ssa0, 0L)
  checked <- checked + ssa0
  checked <- checked +
    bh_sweep_cell(
      lab = "one-way MSE = 0",
      build = function(sd) bh_degen_within(),
      args = list(model = "oneway"),
      seeds = 1L,
      forbid = c("mpl", "searle", "burch", "npbootstrap")
    )
  checked <- checked +
    bh_sweep_cell(
      lab = "two-way constant",
      build = function(sd) bh_degen_flat(),
      args = list(),
      seeds = 1L,
      forbid = c("mpl", "searle", "burch", "npbootstrap")
    )

  expect_gt(checked, 0L)
})
