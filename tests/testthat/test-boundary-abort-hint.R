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

# THE acceptance predicate, defined once. A method is accepted only if `icc()` returns
# AND every interval it reports is finite and correctly ordered. "Did not raise" is NOT
# acceptance: M93 pass 4 shipped `burch` returning NaN and `searle` returning
# [4.594, 0.602] through a green suite that only checked for an error (F3, F4).
bh_usable <- function(d, method, args = list()) {
  fit <- tryCatch(
    suppressWarnings(suppressMessages(do.call(
      icc,
      c(
        list(d, quote(score), quote(subject), quote(rater)),
        args,
        list(ci_method = method)
      )
    ))),
    error = function(e) NULL
  )
  if (is.null(fit)) {
    return(FALSE)
  }
  tb <- generics::tidy(fit)
  if (!nrow(tb)) {
    return(FALSE)
  }
  # AC3's predicate, written from the criterion and from `tidy()`'s own output --
  # never by calling the package function it exists to check, which is the pass-3 F4 /
  # pass-5 F2 tautology trap. Every reported endpoint finite, correctly ordered, and
  # inside the estimand's support under D-010: (-Inf, 1) in general, tightened to
  # (-1/(n0-1), 1) for ICC(1). Both ends OPEN.
  #
  # `conf.high < 1` is the clause pass 5's predicate lacked. Without it `searle` at a
  # numeric `unit` past its Spearman-Brown pole passes as "usable" while returning an
  # interval lying entirely ABOVE +1 -- finite and ordered, and wrong.
  n0 <- length(unique(d$rater))
  floor_rho <- ifelse(tb$index == "ICC(1)" & n0 > 1L, -1 / (n0 - 1), -Inf)
  all(
    is.finite(tb$conf.low) &
      is.finite(tb$conf.high) &
      tb$conf.low <= tb$conf.high &
      tb$conf.high < 1 &
      tb$conf.low > floor_rho
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

bh_hint <- function(
  ...,
  df = NULL,
  n_s = NULL,
  n_r = NULL,
  units = list("single", "average"),
  n0 = NULL
) {
  # Drive the hint exactly as icc() does -- with real data and real estimands. The
  # hint RUNS each candidate now, so a hand-written predicate list can no longer
  # stand in for the data: a geometry is expressed by BUILDING that geometry, not by
  # passing a count alongside data that contradicts it. That substitution is what
  # pass-2 F4 caught (the grid computed the hint from hand-written preds rather than
  # from what icc() derives), and it is structurally impossible here now.
  args <- list(...)
  oneway <- isTRUE(args$oneway)
  if (is.null(df)) {
    # Default geometry sits ON the kappa_m grid, so a row that should hint does; the
    # grid tests below move it off deliberately.
    df <- if (oneway) {
      bh_oneway(
        n_s = if (is.null(n_s)) 20L else n_s,
        n_k = if (is.null(n_r)) 3L else n_r
      )
    } else {
      bh_twoway(
        n_s = if (is.null(n_s)) 20L else n_s,
        n_r = if (is.null(n_r)) 3L else n_r
      )
    }
  }
  k <- length(unique(df$rater))
  defaults <- list(
    oneway = FALSE,
    multilevel = FALSE,
    replicates = FALSE,
    raters = "random",
    balanced = TRUE,
    type = c("agreement", "consistency"),
    type_supplied = FALSE,
    conf_level = 0.95,
    df = df,
    estimands = lapply(units, function(u) {
      icc_estimand(unit = u, k_eff = k, oneway = oneway)
    }),
    n0 = if (is.null(n0)) k else n0
  )
  do.call(boundary_method_hint, utils::modifyList(defaults, args))
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

test_that("silence on degenerate data agrees with the interval, case by case (AC2/AC3)", {
  # The degeneracy FLAG is gone. A row now falls silent because running its methods
  # returned nothing usable, not because a predicate said so -- which means the
  # property the old flag-vs-guard test protected is now checkable in its sharpest
  # form: the set of methods NAMED must equal the set that is USABLE, on every kind
  # of data, with no rule in between to drift.
  for (case in list(
    list(lab = "MSE = 0 (constant within subject)", d = bh_degen_within()),
    list(lab = "SSA = 0 (subject means identical)", d = bh_degen_between()),
    list(lab = "healthy one-way", d = bh_ok_oneway()),
    list(lab = "sigma^2 -> 0 boundary", d = bh_oneway())
  )) {
    usable <- Filter(
      function(m) bh_usable(case$d, m, list(model = "oneway")),
      c("searle", "burch")
    )
    h <- bh_hint(df = case$d, oneway = TRUE, balanced = TRUE)
    named <- if (length(h)) bh_msg_methods(h[["i"]]) else character(0)
    expect_identical(
      paste(case$lab, "named:", paste(named, collapse = "+")),
      paste(case$lab, "named:", paste(usable, collapse = "+"))
    )
  }
  # SSA = 0 is the cell pass-3 F2 and pass-4 F3 disagreed about, and it is now
  # settled by looking rather than by ruling: searle returns ICC(1) [-0.5, -0.5],
  # exactly on the open support floor, and ICC(k) [-Inf, -Inf]; burch is NaN
  # throughout. So the row is silent -- and silent for a reason the test can state.
  expect_length(
    bh_hint(df = bh_degen_between(), oneway = TRUE, balanced = TRUE),
    0L
  )
  # Two-way: all-constant data kill mpl's optim at its initial parameters.
  expect_length(bh_hint(df = bh_degen_flat()), 0L)
  # A missing score silences every row, because every reducer aborts on it -- the
  # hole pass-4 needed two separate mechanisms (`complete` and the probe tryCatch) to
  # cover, and that no longer needs any mechanism of its own.
  na_oneway <- bh_ok_oneway()
  na_oneway$score[3] <- NA
  expect_length(bh_hint(df = na_oneway, oneway = TRUE, balanced = TRUE), 0L)
  na_twoway <- bh_twoway()
  na_twoway$score[5] <- NA
  expect_length(bh_hint(df = na_twoway), 0L)
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

  # SSA = 0 (every subject mean exactly equal, MSE > 0) is silenced too, and the
  # REASON matters because the first re-cut un-suppressed this very cell. It did so
  # on the finding that "searle and burch both return intervals" -- true only in the
  # sense that neither RAISES. burch returns NaN throughout and searle's averaged
  # endpoint is -Inf, so the shipped sentence "return a result" was false here
  # (pass-4 F3, scored 87). Silence is now on this row's own evidence, not on
  # npbootstrap's borrowed conditions, and the assertion is the usability predicate
  # rather than an abort check -- an abort check is what missed it twice.
  db <- bh_degen_between()
  m <- bh_msg_any(db, ci_method = "montecarlo", model = "oneway", seed = 1)
  skip_if(is.na(m), "no abort on the SSA = 0 case")
  for (meth in c("searle", "burch", "npbootstrap", "mpl")) {
    expect_identical(
      paste("between", meth, grepl(meth, m, fixed = TRUE)),
      paste("between", meth, FALSE)
    )
  }
  expect_false(bh_usable(db, "burch", list(model = "oneway")))
  expect_false(bh_usable(db, "searle", list(model = "oneway")))
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
      # `bh_usable()`, never a bare error check: the method must come back with a
      # finite, correctly ordered interval on every estimand it reports.
      status <- if (bh_usable(d, meth, args)) "usable" else "NOT usable"
      expect_identical(
        paste(tag, "->", meth, ":", status),
        paste(tag, "->", meth, ": usable")
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
  # Non-vacuity, pinned on a cell that must NAME something: this sweep asserts
  # "named => usable", under which total silence passes for free, so at least one
  # cell has to be shown firing (the pass-3 lesson, kept after the SSA = 0 cell that
  # used to carry it went correctly silent).
  live <- bh_sweep_cell(
    lab = "two-way 20x3 on-grid (non-vacuity)",
    build = function(sd) bh_twoway(n_s = 20L, seed = sd),
    args = list(),
    forbid = c("searle", "burch", "npbootstrap")
  )
  expect_gt(live, 0L)
  checked <- checked + live

  for (cell in list(
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

  # Degenerate data, all three shapes: every one is silent now, each for its own
  # reason (MSE = 0 breaks the shipped guard, MSA = 0 leaves burch at NaN, constant
  # two-way data kills mpl's optim), so `forbid` covers every method.
  checked <- checked +
    bh_sweep_cell(
      lab = "one-way SSA = 0",
      build = function(sd) bh_degen_between(),
      args = list(model = "oneway"),
      seeds = 1L,
      forbid = c("mpl", "searle", "burch", "npbootstrap")
    )
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

# ---- AC3: the four shapes review pass 4 came through -------------------------
# None of these existed in any earlier sweep. Two of the four pass-4 findings were
# reachable only through a missing score, and one only through a numeric `unit`; the
# grid varied designs but never the data's completeness or the requested divisor.

test_that("a missing score silences every row, and never breaks the abort (AC2/AC3)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # `balanced` counts an NA-scored row as an observed cell, so these designs look
  # complete to every design fence while no method survives them.
  na_ow <- function(sd) {
    d <- bh_smallint(20L, 3L, sd)
    d$score[5] <- NA
    d
  }
  na_tw <- function(sd) {
    d <- bh_twoway(n_s = 15L, seed = sd)
    d$score[4] <- NA
    d
  }
  bh_sweep_cell(
    lab = "one-way + NA score",
    build = na_ow,
    args = list(model = "oneway"),
    forbid = c("searle", "burch", "mpl", "npbootstrap")
  )
  bh_sweep_cell(
    lab = "two-way + NA score",
    build = na_tw,
    args = list(),
    forbid = c("searle", "burch", "mpl", "npbootstrap")
  )

  # AC2's never-raise clause, which is the sharper half: building the hint must not
  # turn the boundary abort into a DIFFERENT error. Pass 4 replaced it with
  # `intraclass_unidentified` from a bootstrap the caller never asked for.
  seen <- character(0)
  for (sd in 1:8) {
    for (build in list(na_ow, na_tw)) {
      d <- build(sd)
      args <- if (identical(build, na_ow)) list(model = "oneway") else list()
      got <- tryCatch(
        {
          suppressWarnings(suppressMessages(do.call(
            icc,
            c(
              list(d, quote(score), quote(subject), quote(rater)),
              args,
              list(ci_method = "montecarlo", seed = 1)
            )
          )))
          NULL
        },
        error = function(e) e
      )
      if (!is.null(got)) {
        seen <- c(seen, class(got)[[1]])
      }
    }
  }
  skip_if(!length(seen), "no abort on the NA-score designs (boundary luck)")
  expect_setequal(unique(seen), "intraclass_singular_fit")
})

test_that("a numeric unit splits the pair at its own Spearman-Brown pole (AC3)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # The projection `npb_sb(rho, m)` has a pole at `rho = -1/(m-1)`; a lower endpoint
  # below it comes back above +1 and the interval reverses. The two methods cross at
  # different m on the same data, so this is asserted per method, not per design.
  for (m in c(2, 3, 6, 10, 20)) {
    checked <- bh_sweep_cell(
      lab = paste("one-way unit =", m),
      build = function(sd) bh_smallint(20L, 3L, sd),
      args = list(model = "oneway", unit = m),
      forbid = c("mpl", "npbootstrap")
    )
    expect_gte(checked, 0L)
  }

  # ...and the split is real rather than an all-or-nothing fence: on one dataset there
  # is an m where burch is still offered and searle is not.
  d <- bh_smallint(20L, 3L, 1L)
  split_seen <- FALSE
  for (m in c(5, 6, 8)) {
    msg <- bh_msg_any(
      d,
      ci_method = "montecarlo",
      model = "oneway",
      unit = m,
      seed = 1
    )
    if (is.na(msg)) {
      next
    }
    named <- bh_msg_methods(msg)
    if (identical(named, "burch")) {
      split_seen <- TRUE
    }
    # Whatever is named must be usable at that unit.
    for (meth in named) {
      expect_identical(
        paste(
          "unit",
          m,
          meth,
          bh_usable(d, meth, list(model = "oneway", unit = m))
        ),
        paste("unit", m, meth, TRUE)
      )
    }
  }
  expect_true(split_seen)
})

# ---- T1: the verification helper (AC2) --------------------------------------
# The re-cut's core: a method is named only after its own shipped reducer has been
# run on the data in hand and the interval inspected. These pin the two pure
# functions directly; the end-to-end property is AC3's sweep.

test_that("boundary_interval_usable() accepts exactly the in-support intervals (AC2)", {
  ok <- function(lo, hi) list(conf.low = lo, conf.high = hi)
  # Finite, ordered, inside (-Inf, 1) for an averaged/projected estimand.
  expect_true(boundary_interval_usable(ok(-0.4, 0.6), divisor = 3, n0 = 3))
  expect_true(boundary_interval_usable(ok(-2.6e5, 0.99), divisor = 3, n0 = 3))
  # ...and inside (-1/(n0-1), 1) for ICC(1).
  expect_true(boundary_interval_usable(ok(-0.49, 0.2), divisor = 1, n0 = 3))

  # Non-finite in either endpoint. `searle` returns [-Inf, -Inf] for ICC(k) on
  # SSA = 0 data and `burch` returns NaN throughout (pass-4 F3).
  expect_false(boundary_interval_usable(ok(-Inf, -Inf), divisor = 3, n0 = 3))
  expect_false(boundary_interval_usable(ok(NaN, NaN), divisor = 1, n0 = 3))
  expect_false(boundary_interval_usable(ok(0.1, NA_real_), divisor = 1, n0 = 3))
  # Reversed: `searle` at a numeric unit past the pole (pass-4 F4).
  expect_false(boundary_interval_usable(ok(4.594, 0.602), divisor = 6, n0 = 3))
  # Out of support ABOVE +1, the pass-5 F3 shape this re-cut had to add: finite AND
  # ordered, so a finite-and-ordered-only predicate would have accepted it.
  expect_false(boundary_interval_usable(ok(1.154, 1.164), divisor = 15, n0 = 2))
  expect_false(boundary_interval_usable(ok(1.25, 1.25), divisor = 15, n0 = 3))
  # The support is OPEN at 1, so an endpoint sitting exactly on it is out.
  expect_false(boundary_interval_usable(ok(0.5, 1), divisor = 1, n0 = 3))
  # ...and open at the ICC(1) floor, which the classical estimator ATTAINS at
  # MSA = 0: searle's [-0.5, -0.5] at k = 3 is a zero-width interval pinned there.
  expect_false(boundary_interval_usable(ok(-0.5, -0.5), divisor = 1, n0 = 3))
  # The same floor does NOT gate an averaged estimand, whose support is (-Inf, 1).
  expect_true(boundary_interval_usable(ok(-0.5, -0.5), divisor = 3, n0 = 3))
  # A malformed entry is unusable rather than an error.
  expect_false(boundary_interval_usable(
    list(conf.low = numeric(0), conf.high = 0.5),
    divisor = 1,
    n0 = 3
  ))
})

test_that("boundary_method_usable() verdicts match the intervals the reducers return (AC2)", {
  ests <- function(units, k, oneway = TRUE) {
    lapply(units, function(u) {
      icc_estimand(unit = u, k_eff = k, oneway = oneway)
    })
  }
  d1 <- bh_oneway()
  e_default <- ests(list("single", "average"), 5)

  # Healthy boundary one-way: both classical methods return usable intervals, so
  # both verify. (Measured at the implement gate: searle single [-0.060, 0.206],
  # average [-0.397, 0.564]; burch single [-0.066, 0.186], average [-0.445, 0.532].)
  expect_true(boundary_method_usable("searle", d1, e_default, 0.95, n0 = 5))
  expect_true(boundary_method_usable("burch", d1, e_default, 0.95, n0 = 5))

  # MSE = 0: both shipped guards abort, so both fail verification.
  d_mse0 <- bh_degen_within()
  expect_false(boundary_method_usable(
    "searle",
    d_mse0,
    ests(list("single"), 3),
    0.95,
    3
  ))
  expect_false(boundary_method_usable(
    "burch",
    d_mse0,
    ests(list("single"), 3),
    0.95,
    3
  ))

  # SSA = 0: neither method raises, and the VALUES are what decide. searle gives
  # ICC(1) [-0.5, -0.5] (on the open support floor) and ICC(k) [-Inf, -Inf]; burch
  # gives NaN. So both fail, on the default call and on ICC(1) alone -- the cell
  # pass-3 F2 and pass-4 F3 disagreed about, settled by looking rather than ruling.
  d_ssa0 <- bh_degen_between()
  expect_false(boundary_method_usable(
    "searle",
    d_ssa0,
    ests(list("single", "average"), 3),
    0.95,
    3
  ))
  expect_false(boundary_method_usable(
    "searle",
    d_ssa0,
    ests(list("single"), 3),
    0.95,
    3
  ))
  expect_false(boundary_method_usable(
    "burch",
    d_ssa0,
    ests(list("single"), 3),
    0.95,
    3
  ))

  # A missing score aborts every reducer, which is why no separate completeness
  # input is needed any more (pass-4 F1/F2 were two mechanisms for this one hole).
  d_na <- d1
  d_na$score[3] <- NA_real_
  expect_false(boundary_method_usable("searle", d_na, e_default, 0.95, 5))
  expect_false(boundary_method_usable("burch", d_na, e_default, 0.95, 5))

  # mpl ON its kappa_m grid verifies; OFF the grid the lookup aborts, which is why
  # no separate grid gate is needed any more (pass-1 F1).
  d2 <- bh_twoway()
  e2 <- ests(list("single", "average"), 3, oneway = FALSE)
  expect_true(boundary_method_usable("mpl", d2, e2, 0.95, n0 = 3))
  expect_false(boundary_method_usable(
    "mpl",
    bh_twoway(n_s = 8),
    e2,
    0.95,
    n0 = 3
  ))
  # ...and at an uncalibrated conf_level, likewise (M91/D-017).
  expect_false(boundary_method_usable("mpl", d2, e2, 0.975, n0 = 3))

  # An unregistered method is never usable -- `npbootstrap` is M97's to add.
  expect_false(boundary_method_usable("npbootstrap", d1, e_default, 0.95, 5))
  expect_false(boundary_method_usable("montecarlo", d1, e_default, 0.95, 5))
})

test_that("verification never raises and never leaks a condition (AC2)", {
  # The obligation pass-4 F2 broke: this runs while the boundary abort's message
  # vector is being built, so a condition escaping here replaces the user's error.
  # Drive it over inputs that make the reducers abort, warn, or return garbage.
  ests <- function(units, k, oneway = TRUE) {
    lapply(units, function(u) {
      icc_estimand(unit = u, k_eff = k, oneway = oneway)
    })
  }
  e1 <- ests(list("single", "average"), 3)
  e2 <- ests(list("single", "average"), 3, oneway = FALSE)

  d_na_all <- bh_oneway(n_s = 10, n_k = 3)
  d_na_all$score <- NA_real_
  d_one_row <- bh_oneway(n_s = 10, n_k = 3)[1, , drop = FALSE]
  d_empty <- bh_oneway(n_s = 10, n_k = 3)[0, , drop = FALSE]

  hostile <- list(
    list("searle", bh_degen_within()),
    list("burch", bh_degen_within()),
    list("searle", bh_degen_between()),
    list("burch", bh_degen_flat()),
    list("searle", d_na_all),
    list("burch", d_na_all),
    list("searle", d_one_row),
    list("burch", d_empty),
    list("mpl", bh_degen_flat()),
    list("mpl", d_na_all),
    list("mpl", d_empty)
  )
  for (h in hostile) {
    meth <- h[[1]]
    dat <- h[[2]]
    e <- if (identical(meth, "mpl")) e2 else e1
    # No error, no warning, no message -- and a bare logical either way.
    expect_no_error(v <- boundary_method_usable(meth, dat, e, 0.95, n0 = 3))
    expect_no_warning(boundary_method_usable(meth, dat, e, 0.95, n0 = 3))
    expect_true(is.logical(v) && length(v) == 1L && !is.na(v))
  }
})

# ---- T3/AC4: the check cannot drift from the real call ----------------------
# Verification runs the REDUCER, while the user runs `icc()`. Those are the same
# endpoints today -- nothing in the reporting path clamps or rounds them -- but that
# is a property to pin, not to assume: if it ever stopped holding, the hint would be
# deciding on numbers the user never sees, and every AC3 sweep would still pass.

# A balanced one-way design on which `searle` projected to `unit = 15` crosses
# `npb_sb()`'s pole and reports an interval lying entirely ABOVE +1 -- measured
# [1.153869, 1.164311] at `conf_level = 0.80`, around a point of 5.9e-09. Healthy
# data, a legal call, no abort: the shipped defect M93 routes the hint around rather
# than fixes (ROADMAP candidate). Used here to give the AC4 grid a cell where
# out-of-support post-processing would actually show.
bh_pole_oneway <- function(n_s = 2L, n_k = 2L, seed = 2L) {
  set.seed(seed)
  a <- stats::rnorm(n_s, sd = sqrt(0.05))
  data.frame(
    subject = factor(rep(seq_len(n_s), each = n_k)),
    rater = factor(rep(seq_len(n_k), times = n_s)),
    score = rep(a, each = n_k) + stats::rnorm(n_s * n_k, sd = sqrt(0.95))
  )
}

# Does icc() REFUSE this ci_method on this design? (Admissibility, as the shipped
# fence answers it -- distinct from whether the method works on the data.)
bh_unsupported <- function(d, method, args = list()) {
  tryCatch(
    {
      suppressWarnings(suppressMessages(do.call(
        icc,
        c(
          list(d, quote(score), quote(subject), quote(rater)),
          args,
          list(ci_method = method)
        )
      )))
      FALSE
    },
    intraclass_unsupported = function(e) TRUE,
    error = function(e) FALSE
  )
}

test_that("verification inspects exactly the endpoints icc() reports (AC4)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  cases <- list(
    list(
      lab = "one-way balanced 20x5",
      d = bh_ok_oneway(),
      args = list(model = "oneway"),
      methods = c("searle", "burch"),
      oneway = TRUE
    ),
    list(
      lab = "one-way boundary 30x5",
      d = bh_oneway(),
      args = list(model = "oneway"),
      methods = c("searle", "burch"),
      oneway = TRUE
    ),
    list(
      lab = "two-way on-grid 20x3",
      d = bh_twoway(),
      args = list(),
      methods = "mpl",
      oneway = FALSE
    ),
    # The cell that makes this test able to FAIL. Every case above returns
    # comfortably in-support endpoints, so any post-processing that only bites out of
    # support -- a `pmin(1, .)` clamp in the reporting path, say -- would be invisible
    # to them, and the test would pass while the hint decided on numbers the user
    # never sees. Here `searle` at 2 subjects, `unit = 15`, `conf_level = 0.80`
    # genuinely reports [1.153869, 1.164311]: above +1, and the shipped defect this
    # milestone routes around (ROADMAP candidate).
    list(
      lab = "one-way 2x2 past the projection pole",
      d = bh_pole_oneway(),
      args = list(model = "oneway", conf_level = 0.80),
      methods = "searle",
      oneway = TRUE,
      conf_level = 0.80,
      units = list(15)
    )
  )
  units <- list("single", "average", 2, 6)

  checked <- 0L
  compared <- 0L
  out_of_support_seen <- FALSE
  for (case in cases) {
    k <- length(unique(case$d$rater))
    cl <- if (is.null(case$conf_level)) 0.95 else case$conf_level
    case_units <- if (is.null(case$units)) units else case$units
    for (m in case$methods) {
      reducer <- switch(m, searle = searle_ci, burch = burch_ci, mpl = mpl_ci)
      for (u in case_units) {
        e <- list(icc_estimand(unit = u, k_eff = k, oneway = case$oneway))
        red <- tryCatch(
          suppressWarnings(suppressMessages(
            reducer(case$d, e, conf_level = cl)
          )),
          error = function(err) NULL
        )
        tb <- tryCatch(
          generics::tidy(suppressWarnings(suppressMessages(do.call(
            icc,
            c(
              list(case$d, quote(score), quote(subject), quote(rater)),
              case$args,
              list(unit = u, ci_method = m)
            )
          )))),
          error = function(err) NULL
        )
        lab <- paste(case$lab, m, "unit", as.character(u))
        # Refusing on one side and computing on the other is itself a divergence.
        expect_identical(
          paste(lab, "computed:", is.null(red)),
          paste(lab, "computed:", is.null(tb))
        )
        if (!is.null(red) && !is.null(tb)) {
          expect_identical(nrow(tb), 1L)
          expect_equal(red[[1]]$conf.low, tb$conf.low[[1]], tolerance = 0)
          expect_equal(red[[1]]$conf.high, tb$conf.high[[1]], tolerance = 0)
          if (red[[1]]$conf.high > 1) {
            out_of_support_seen <- TRUE
          }
          compared <- compared + 1L
        }
        checked <- checked + 1L
      }
    }
  }
  # The exact cell count, not `>= 0`: a cell silently dropped from the loop must red
  # rather than pass on a smaller grid (pass-5 F2 was exactly that assertion).
  expect_identical(checked, length(units) * 5L + 1L)
  # ...and every cell must reach the NUMERIC comparison. Without this the test would
  # still pass if every cell degenerated to "both refused", which asserts nothing
  # about endpoint equality -- the vacuity that keeps recurring in this file.
  expect_identical(compared, length(units) * 5L + 1L)
  # ...and at least one compared cell must sit OUT of support, or the grid cannot
  # detect post-processing that only bites there. Verified by mutation: clamping the
  # reported endpoint with `pmin(1, .)` reds this test only because of that cell.
  expect_true(out_of_support_seen)
})

test_that("the admissibility rows mirror icc()'s own ci_method fences (AC4)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # What the rows OFFER, icc() must accept -- otherwise the hint names a string the
  # dispatch then refuses with `intraclass_unsupported` (the shape of pass-1 F1).
  for (m in c("searle", "burch")) {
    expect_false(bh_unsupported(bh_ok_oneway(), m, list(model = "oneway")))
  }
  expect_false(bh_unsupported(bh_ok_twoway(), "mpl", list()))
  expect_false(bh_unsupported(
    bh_ok_twoway(),
    "mpl",
    list(type = "agreement")
  ))

  # ...and what the rows EXCLUDE, icc() must really refuse -- otherwise the exclusion
  # is over-suppression rather than a mirror of the fence, which is the failure
  # pass-3 F2 caught in the other direction.
  ragged <- bh_ok_oneway(sizes = c(rep(5L, 15L), rep(3L, 5L)))
  for (m in c("searle", "burch")) {
    expect_true(bh_unsupported(ragged, m, list(model = "oneway")))
  }
  expect_true(bh_unsupported(bh_ok_twoway(), "mpl", list(raters = "fixed")))
  expect_true(bh_unsupported(
    bh_ok_twoway(),
    "mpl",
    list(type = "consistency")
  ))
})
