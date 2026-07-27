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
  #
  # The seed sweep FAILS rather than skips when nothing aborts, and the returned value
  # is inspected outside the condition branch. Both matter for the same reason: the
  # violation this criterion forbids is `icc()` RETURNING an interval where it should
  # abort, and a `skip_if_not(found, ...)` ending is green on exactly that -- no seed
  # aborts, `found` stays FALSE, and the test skips over the fallback default it exists
  # to forbid. An `expect_false(inherits(got, "icc"))` reached only when `got` is
  # already a condition is a tautology for the same reason.
  got <- NULL
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
      break
    }
  }
  # An error, not a value: whatever the sweep ended on must NOT be an interval.
  expect_false(inherits(got, "icc"))
  expect_s3_class(got, "intraclass_singular_fit")
  expect_s3_class(got, "rlang_error")
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

# One sweep cell. Fires the REAL abort, parses the method names out of the message
# `icc()` actually raised, and asserts the named set is EXACTLY the usable set among
# the methods this design ADMITS. That is both AC3 halves in one assertion:
#   named but not usable -> the failure all five review passes kept finding
#   usable but not named -> over-suppression (pass-3 F2, in the other direction)
#
# It follows that a SILENT cell is not vacuous: it asserts that nothing admissible
# would have worked on that data. This is what makes the previously-empty `unit`
# cells real rather than cells to delete -- pass-5 F2 measured `unit = 10` and
# `unit = 20` checking nothing, and under "named == usable" they check the converse.
#
# Returns its counts rather than one number, because a cell whose default never
# aborted asserted NOTHING and the caller has to be able to see that.
bh_sweep_cell <- function(
  lab,
  build,
  args,
  candidates,
  seeds = 1:6,
  forbid = character(0)
) {
  aborts <- 0L
  named_total <- 0L
  for (sd in seeds) {
    d <- build(sd)
    m <- do.call(
      bh_msg_any,
      c(list(d, ci_method = "montecarlo", seed = 1), args)
    )
    if (is.na(m)) {
      next
    }
    aborts <- aborts + 1L
    named <- bh_msg_methods(m)
    tag <- paste(lab, "seed", sd)
    # Nothing outside this design's admissible set may EVER be named, whatever the
    # data says -- `icc()` would refuse the string (AC4).
    expect_identical(
      paste(
        tag,
        "outside admissible:",
        paste(setdiff(named, candidates), collapse = "+")
      ),
      paste(tag, "outside admissible:", "")
    )
    for (bad in forbid) {
      expect_identical(
        paste(tag, bad, "named:", bad %in% named),
        paste(tag, bad, "named:", FALSE)
      )
    }
    # `bh_usable()`, never a bare error check: the method must come back with an
    # interval that is finite, correctly ordered AND in support on every estimand.
    usable <- Filter(function(x) bh_usable(d, x, args), candidates)
    expect_identical(
      paste(tag, "named:", paste(sort(named), collapse = "+")),
      paste(tag, "named:", paste(sort(usable), collapse = "+"))
    )
    named_total <- named_total + length(named)
  }
  list(aborts = aborts, named = named_total)
}

test_that("the names the REAL abort gives are exactly the usable set, one-way (AC3)", {
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

  named_total <- 0L
  for (cell in cells) {
    lab <- paste0(
      if (cell$bal) "balanced " else "unbalanced ",
      cell$n_s,
      "x",
      cell$n_k
    )
    r <- bh_sweep_cell(
      lab = lab,
      build = function(sd) {
        bh_smallint(cell$n_s, cell$n_k, sd, balanced = cell$bal)
      },
      args = list(model = "oneway"),
      # Unbalanced admits NOTHING: searle/burch are balanced-only (D-013) and the
      # bootstrap that ships that cell is named on no design until M97.
      candidates = if (cell$bal) c("searle", "burch") else character(0),
      forbid = c("mpl", "npbootstrap")
    )
    # Every DECLARED cell must have fired the abort at least once. Without this a
    # cell that never aborts contributes nothing while reading as covered.
    expect_identical(
      paste(lab, "aborted:", r$aborts > 0L),
      paste(lab, "aborted:", TRUE)
    )
    named_total <- named_total + r$named
  }
  # ...and somewhere in the sweep a method must actually have been NAMED, or
  # "named == usable" would hold everywhere by universal silence.
  expect_gt(named_total, 0L)
})

test_that("the names the REAL abort gives are exactly the usable set, two-way (AC3)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  s_nodes <- sort(unique(kappa_m_table$n_s))
  named_total <- 0L

  run <- function(lab, build, args, candidates, seeds = 1:6) {
    r <- bh_sweep_cell(
      lab = lab,
      build = build,
      args = args,
      candidates = candidates,
      seeds = seeds,
      forbid = setdiff(c("searle", "burch", "mpl", "npbootstrap"), candidates)
    )
    expect_identical(
      paste(lab, "aborted:", r$aborts > 0L),
      paste(lab, "aborted:", TRUE)
    )
    r$named
  }

  # Two-way random: on the kappa_m grid at two geometries, off it below the grid's
  # smallest subject count, with `type` unset and supplied.
  named_total <- named_total +
    run(
      "two-way 20x3 on-grid",
      function(sd) bh_twoway(n_s = 20L, seed = sd),
      list(),
      "mpl"
    )
  named_total <- named_total +
    run(
      "two-way 10x3 on-grid",
      function(sd) bh_twoway(n_s = 10L, seed = sd),
      list(),
      "mpl"
    )
  named_total <- named_total +
    run(
      "two-way 20x3 type supplied",
      function(sd) bh_twoway(n_s = 20L, seed = sd),
      list(type = "agreement"),
      "mpl"
    )
  # OFF the grid mpl is still ADMISSIBLE (icc() accepts the string on this design);
  # it is the lookup's own abort that makes it unusable, so the converse half is what
  # carries this cell. That is the pass-1 F1 mechanism, now checked rather than fenced.
  named_total <- named_total +
    run(
      "two-way off-grid",
      function(sd) bh_twoway(n_s = min(s_nodes) - 2L, seed = sd),
      list(),
      "mpl"
    )
  # An uncalibrated conf_level, likewise settled by the lookup rather than by a rule.
  named_total <- named_total +
    run(
      "two-way uncalibrated conf_level",
      function(sd) bh_twoway(n_s = 20L, seed = sd),
      list(conf_level = 0.975),
      "mpl"
    )

  # Designs that admit nothing at all: the abort must name nothing, and `candidates`
  # being empty makes "named == usable" say exactly that.
  named_total <- named_total +
    run(
      "fixed raters",
      function(sd) bh_twoway(seed = sd),
      list(raters = "fixed"),
      character(0)
    )
  named_total <- named_total +
    run(
      "explicit consistency",
      function(sd) bh_twoway(seed = sd),
      list(type = "consistency"),
      character(0)
    )

  # Degenerate data, all three shapes. Each is silent for its OWN reason (MSE = 0
  # trips the shipped guard, SSA = 0 leaves burch at NaN and searle's ICC(k) at -Inf,
  # constant two-way data kills mpl's optim) -- and the converse half is what states
  # that, rather than a `forbid` list asserting silence by fiat.
  named_total <- named_total +
    run(
      "one-way SSA = 0",
      function(sd) bh_degen_between(),
      list(model = "oneway"),
      c("searle", "burch"),
      seeds = 1L
    )
  named_total <- named_total +
    run(
      "one-way MSE = 0",
      function(sd) bh_degen_within(),
      list(model = "oneway"),
      c("searle", "burch"),
      seeds = 1L
    )
  named_total <- named_total +
    run(
      "two-way constant",
      function(sd) bh_degen_flat(),
      list(),
      "mpl",
      seeds = 1L
    )

  # The two-way half must be shown FIRING, not merely consistent.
  expect_gt(named_total, 0L)
})

# ---- AC3: the shapes the review passes came through --------------------------
# None of these existed in any earlier sweep. Two pass-4 findings were reachable only
# through a missing score and one only through a numeric `unit`; the grid varied
# designs but never the data's completeness or the requested divisor.

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
  r_ow <- bh_sweep_cell(
    lab = "one-way + NA score",
    build = na_ow,
    args = list(model = "oneway"),
    candidates = c("searle", "burch"),
    forbid = c("mpl", "npbootstrap")
  )
  r_tw <- bh_sweep_cell(
    lab = "two-way + NA score",
    build = na_tw,
    args = list(),
    candidates = "mpl",
    forbid = c("searle", "burch", "npbootstrap")
  )
  expect_gt(r_ow$aborts, 0L)
  expect_gt(r_tw$aborts, 0L)
  # Silence here is an assertion, not an absence: the converse half above has already
  # confirmed no admissible method was usable on that data.
  expect_identical(r_ow$named, 0L)
  expect_identical(r_tw$named, 0L)

  # AC2's never-raise clause, the sharper half: building the hint must not turn the
  # boundary abort into a DIFFERENT error. Pass 4 replaced it with
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

test_that("a numeric unit splits the pair at its own projection pole (AC3)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # The projection `npb_sb(rho, m)` has a pole at `rho = -1/(m-1)`; past it the
  # interval comes back reversed or entirely above +1. The two methods cross at
  # different m on the same data, so naming is per method -- and no rule in the code
  # says so any more, it falls out of running each one.
  #
  # Pass-5 F2 measured two of these cells checking nothing under the old
  # "named => usable" predicate. Under "named == usable" a silent cell asserts the
  # converse, so every cell carries an assertion and the tautological
  # `expect_gte(checked, 0L)` that used to sit here is gone.
  for (m in c(2, 3, 6, 10, 20)) {
    lab <- paste("one-way unit =", m)
    r <- bh_sweep_cell(
      lab = lab,
      build = function(sd) bh_smallint(20L, 3L, sd),
      args = list(model = "oneway", unit = m),
      candidates = c("searle", "burch"),
      forbid = c("mpl", "npbootstrap")
    )
    expect_identical(
      paste(lab, "aborted:", r$aborts > 0L),
      paste(lab, "aborted:", TRUE)
    )
  }

  # ...and the split is real rather than all-or-nothing: on one dataset there is an m
  # where burch is still offered and searle is not.
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

# A balanced one-way design on which `searle`, projected to `unit = 10`, crosses
# `npb_sb()`'s pole and reports an interval lying entirely ABOVE +1 -- measured
# [1.276702, 1.824471] at `conf_level = 0.80`. Healthy data, a legal call, no abort:
# the shipped defect M93 routes the hint around rather than fixes (ROADMAP
# candidate). Used here to give the AC4 grid a cell where out-of-support
# post-processing would actually show.
#
# 8x2 rather than the smallest cell that exhibits this (2x2): the M84 lesson is that
# a tiny glmmTMB fit can die with a RAW unclassed error on Linux/Windows while
# completing on macOS, which is precisely how M93 review pass 1 went red on CI with
# a green local gate. 8 subjects keeps the property and keeps the fit ordinary.
bh_pole_oneway <- function(n_s = 8L, n_k = 2L, seed = 6L) {
  set.seed(seed)
  a <- stats::rnorm(n_s, sd = sqrt(0.001))
  data.frame(
    subject = factor(rep(seq_len(n_s), each = n_k)),
    rater = factor(rep(seq_len(n_k), times = n_s)),
    score = rep(a, each = n_k) + stats::rnorm(n_s * n_k, sd = sqrt(0.999))
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
    # never sees. Here `searle` at 8 subjects, `unit = 10`, `conf_level = 0.80`
    # genuinely reports [1.276702, 1.824471]: above +1, and the shipped defect this
    # milestone routes around (ROADMAP candidate).
    list(
      lab = "one-way 8x2 past the projection pole",
      d = bh_pole_oneway(),
      args = list(model = "oneway", conf_level = 0.80),
      methods = "searle",
      oneway = TRUE,
      conf_level = 0.80,
      units = list(10)
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

# ---- T6/T7/T8: the three guards review pass 6 found missing ------------------
# Each of these pins a property the code already had and nothing asserted. Pass 6
# reproduced all three by mutation: the suite stayed green while the property was
# broken, which is the same shape as the tautologies passes 3-5 found here.

test_that("verification never runs on a successful call, only on the aborting one (AC2)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # AC2's laziness clause: `hint` is a promise forced only inside an abort message,
  # so a successful call must not pay for running the candidate methods. This matters
  # beyond tidiness -- M97 registers `npbootstrap` behind this same helper at ~135 ms,
  # and an accidental eager force would charge every successful icc() call for a
  # bootstrap the caller never asked for.
  calls <- 0L
  real <- boundary_method_usable
  local_mocked_bindings(
    boundary_method_usable = function(...) {
      calls <<- calls + 1L
      real(...)
    }
  )

  # A healthy fit: the MC interval succeeds, so the hint is never forced.
  invisible(suppressWarnings(suppressMessages(
    icc(
      bh_ok_oneway(),
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = "montecarlo",
      seed = 1
    )
  )))
  expect_identical(calls, 0L)

  # ...and the same instrumentation must show it DOES run when the abort fires, or
  # the zero above would be satisfied by the helper simply never being reachable.
  fired <- FALSE
  for (sd in 1:12) {
    got <- tryCatch(
      {
        suppressWarnings(suppressMessages(
          icc(
            bh_oneway(seed = sd),
            score,
            subject,
            rater,
            model = "oneway",
            ci_method = "montecarlo",
            seed = 1
          )
        ))
        NULL
      },
      intraclass_singular_fit = function(e) e
    )
    if (!is.null(got)) {
      fired <- TRUE
      break
    }
  }
  skip_if_not(fired, "no one-way MC abort in the seed sweep (boundary luck)")
  expect_gt(calls, 0L)
})

test_that("icc() passes the effective group size as the support floor's n0 (AC4)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # The ICC(1) support floor is -1/(n0-1) (D-010), and `n0` comes from icc() as
  # `design_info$k_eff`. Only a pure-function test exercised the floor, hard-coding
  # n0 -- so a mis-wiring was invisible, and invisible in the OVER-NAMING direction:
  # too small an n0 lowers the floor and admits intervals sitting on it.
  seen <- NULL
  real <- boundary_method_hint
  local_mocked_bindings(
    boundary_method_hint = function(..., n0) {
      seen <<- n0
      real(..., n0 = n0)
    }
  )
  fired <- FALSE
  for (sd in 1:12) {
    got <- tryCatch(
      {
        suppressWarnings(suppressMessages(
          icc(
            bh_oneway(n_s = 30, n_k = 5, seed = sd),
            score,
            subject,
            rater,
            model = "oneway",
            ci_method = "montecarlo",
            seed = 1
          )
        ))
        NULL
      },
      intraclass_singular_fit = function(e) e
    )
    if (!is.null(got)) {
      fired <- TRUE
      break
    }
  }
  skip_if_not(fired, "no one-way MC abort in the seed sweep (boundary luck)")
  # Balanced 30x5: k_eff is the rater count, which is searle's group size n.
  expect_identical(seen, 5)
})

test_that("the support floor is load-bearing at the value icc() supplies (AC4)", {
  # The assertion above pins WHICH value is passed; this pins that the value MATTERS,
  # so the pair cannot both pass on a floor that never bites. SSA = 0 at k = 3 with
  # `unit = "single"` alone is the cell where searle returns [-0.5, -0.5] -- finite
  # and ordered, and sitting exactly on the open support floor -1/(k-1).
  d <- bh_degen_between()
  e <- list(icc_estimand(unit = "single", k_eff = 3, oneway = TRUE))
  ends <- searle_ci(d, e, conf_level = 0.95)[[1]]
  expect_identical(ends$conf.low, -0.5)
  expect_identical(ends$conf.high, -0.5)

  args <- list(
    oneway = TRUE,
    multilevel = FALSE,
    replicates = FALSE,
    raters = "random",
    balanced = TRUE,
    type = c("agreement", "consistency"),
    type_supplied = FALSE,
    conf_level = 0.95,
    df = d,
    estimands = e
  )
  # At the correct n0 the interval is OUT of support and the row stays silent...
  expect_length(do.call(boundary_method_hint, c(args, list(n0 = 3))), 0L)
  # ...and at a wrong, smaller n0 the floor drops below it and `searle` gets named --
  # the AC3-forbidden shape. This is what makes the silence above an assertion about
  # n0 rather than an accident of the data.
  wrong <- do.call(boundary_method_hint, c(args, list(n0 = 2)))
  expect_length(wrong, 1L)
  expect_match(wrong[["i"]], "searle", fixed = TRUE)
})


# ---- T11/AC5: the leak guard, as an invariant over the producer ---------------
# Three predecessors of this guard each enumerated a hand-picked set, and each set was
# short by one:
#   pass 7 -- a detector matching ~4 significant digits, blind to a leak rendered
#             `round(v, 3)`, which is this package's own house style for a number in a
#             cli message and is used by the very abort the hint attaches to;
#   pass 8 -- an enumeration reading only the one-way abort, blind to the `mpl` bullet;
#   pass 9 -- a `branches` list naming two of the THREE bullet forms
#             `boundary_method_hint()` renders, blind to the one-way SINGULAR lead that
#             fires when a numeric `unit` splits the pair (74 of 1,680 real aborts).
#             `checked == 2L` could not see it: it counted the author's list, not the
#             surface the hint has.
#
# A list cannot be repaired by adding to it. The author of a detector is exactly who
# cannot enumerate the renderings it misses, so this guard lists nothing: it varies the
# hint's INPUTS and checks whatever bullets come back, whatever they say.
#
# What that does and does not buy, stated exactly. Every rendering the grid's inputs
# REACH is checked, including one written after this guard was. A rendering reachable
# only through an input axis the grid does not vary would still go unread -- the
# residual cost of any input grid, answered by widening the grid rather than by listing
# literals. A rendering nothing reaches is not a leak surface at all, because no user
# can be shown it either: a searle-only lead is unreachable, measured across 11 `unit`
# values x 2 data shapes x 6 seeds, where only the burch-only and searle+burch forms
# ever occur.

test_that("no interval computed during verification reaches the message (AC5)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # AC5's second clause, and the line D-018 draws against the fallback-on-abort default
  # D-012 fenced out: verification computes real intervals and DISCARDS them. They
  # decide whether to NAME a method, and must reach neither the message text nor any
  # returned object.

  # THE invariant, asserted on every bullet the producer returns: a hint bullet carries
  # no digit. Deliberately stronger than "no leaked endpoint" -- every shipped bullet is
  # digit-free already (`ci_method`, `searle`, `burch`, `mpl` and the prose around them
  # all are), so there is no precision to match and no rendering to evade. A future
  # bullet that wants a number -- M97's `npbootstrap` one included -- is a deliberate
  # decision to make here, not something that slips through.
  num_tokens <- function(text) {
    regmatches(
      text,
      gregexpr("[0-9]+(?:[.][0-9]+)?(?:[eE][-+]?[0-9]+)?", text, perl = TRUE)
    )[[1]]
  }
  flat <- function(x) {
    gsub("[[:space:]]+", " ", cli::ansi_strip(paste(x, collapse = " ")))
  }
  # Render a bullet the way the user really sees it. `cli::format_message()` reproduces
  # the inline + wrap + `\\`-continuation stripping cli applies on the abort path;
  # `cli_abort()` itself runs only `format_inline()` and rlang wraps afterwards, so
  # this is NOT the identical call and faithfulness is not by construction. What
  # establishes it is the end-to-end substring comparison below, which fails if the two
  # disagree -- and that comparison is also what keeps this helper honest: a stub
  # renderer fails it. `format_inline()` alone would not do: it leaves the `\\`
  # continuations in the string, so the comparison could never match.
  render <- function(b) flat(cli::format_message(b))

  # Both recorders read the PRODUCER, never a list of designs. `boundary_method_hint()`
  # hands back every bullet it renders, whatever branch built it, and
  # `boundary_interval_usable()` sees every interval verification inspects -- which is
  # exactly the set of values AC5 says must not reach the user, so the positive controls
  # below are driven off those rather than off reducers named per design. Naming
  # reducers per design would be the same hand-listing in another place.
  bullets <- character(0)
  ends <- numeric(0)
  real_hint <- boundary_method_hint
  real_usable <- boundary_interval_usable
  local_mocked_bindings(
    boundary_method_hint = function(...) {
      out <- real_hint(...)
      bullets <<- c(bullets, unname(out))
      out
    },
    boundary_interval_usable = function(ci, ...) {
      ends <<- c(ends, ci$conf.low, ci$conf.high)
      real_usable(ci, ...)
    }
  )

  # A grid over the hint's INPUTS -- design, balance, `unit`, `type` -- chosen to reach
  # different branches without naming what any of them renders. Which literals this
  # exercises is measured below, never declared here.
  grid <- list(
    list(
      lab = "one-way, default unit",
      build = function(sd) bh_oneway(seed = sd),
      args = list(model = "oneway")
    ),
    list(
      lab = "one-way, unit = 6",
      build = function(sd) bh_smallint(20L, 3L, sd),
      args = list(model = "oneway", unit = 6)
    ),
    list(
      lab = "one-way, unit = 20",
      build = function(sd) bh_smallint(20L, 3L, sd),
      args = list(model = "oneway", unit = 20)
    ),
    list(
      lab = "one-way, unbalanced",
      build = function(sd) bh_smallint(20L, 3L, sd, balanced = FALSE),
      args = list(model = "oneway")
    ),
    list(
      lab = "two-way, type unset",
      build = function(sd) bh_twoway(seed = sd),
      args = list()
    ),
    list(
      lab = "two-way, agreement supplied",
      build = function(sd) bh_twoway(seed = sd),
      args = list(type = "agreement")
    )
  )

  fire <- function(build, args) {
    for (sd in 1:10) {
      got <- tryCatch(
        {
          suppressWarnings(suppressMessages(do.call(
            icc,
            c(
              list(build(sd), quote(score), quote(subject), quote(rater)),
              args,
              list(ci_method = "montecarlo", seed = 1)
            )
          )))
          NULL
        },
        intraclass_singular_fit = function(e) e
      )
      if (!is.null(got)) {
        return(flat(conditionMessage(got)))
      }
    }
    NULL
  }

  # Per cell: the abort must fire (a fixture drifting off the boundary FAILS rather
  # than skipping), and whatever the user is shown carries only its legitimate numbers.
  for (cell in grid) {
    before <- length(bullets)
    msg <- fire(cell$build, cell$args)
    expect_identical(
      paste(cell$lab, "aborted:", !is.null(msg)),
      paste(cell$lab, "aborted:", TRUE)
    )
    if (is.null(msg)) {
      next
    }

    # The whole-message enumeration, kept from T9/T10. The legitimate set per abort
    # site: site B reports the share of non-finite draws and nothing else; site A
    # carries no number at all. The hint bullets and both generic remedies are
    # digit-free, so the legitimate set really is that small.
    #
    # Every cell of this grid lands on site B in practice (site A is the rare
    # non-finite-covariance abort, ~1 in 40 at these geometries), so the site-A arm
    # below is reachable but not currently exercised, and its anchor could rot without
    # reddening. Kept rather than dropped because a fixture shifting onto site A must
    # meet an assertion rather than an unhandled branch.
    tokens <- num_tokens(msg)
    site_b <- grepl("% of draws were non-finite", msg, fixed = TRUE)
    expect_true(
      site_b || grepl("parameter covariance is not finite", msg, fixed = TRUE)
    )
    if (site_b) {
      expect_identical(length(tokens), 1L)
      expect_true(grepl(paste0(tokens[[1]], "% of draws"), msg, fixed = TRUE))
    } else {
      expect_identical(length(tokens), 0L)
    }
    expect_match(msg, "could not be computed", fixed = TRUE)

    # ...and the bullets this cell produced are the text the user was actually shown.
    # This is the end-to-end half: without it the invariant would hold over strings
    # that never reach a message.
    for (b in unique(bullets[seq_len(length(bullets) - before) + before])) {
      rendered <- NULL
      expect_no_error(rendered <- render(b))
      expect_true(!is.null(rendered) && nzchar(rendered))
      if (!is.null(rendered)) {
        expect_true(grepl(rendered, msg, fixed = TRUE))
      }
    }
  }

  # The sweep read something. Without this every assertion below is over an empty set.
  expect_gt(length(bullets), 0L)
  expect_gt(length(ends), 0L)
  distinct <- unique(bullets)

  # THE invariant, over every rendering the grid produced -- raw and cli-rendered. The
  # rendered form closes a leak interpolated at render time rather than pasted in: a
  # `{...}` expression can be digit-free as a template and numeric on screen. No
  # mutation below demonstrates that shape, because a bullet is spliced as a finished
  # string into a message glued in another frame, where such an expression would not
  # resolve; the clause is cheap insurance against a future design where the hint
  # returns templates evaluated in scope, and is stated as that rather than as a
  # defended hole.
  for (b in distinct) {
    expect_identical(num_tokens(b), character(0))
    expect_identical(num_tokens(render(b)), character(0))
  }

  # Non-vacuity, and the pass-9 hole stated as a property of the OUTPUT rather than as
  # a list of branches: among the bullets naming CLASSICAL methods -- the row that has
  # two leads -- the grid saw one naming a single method and one naming both, so the
  # singular and plural one-way leads were both read. A guard that only ever reaches
  # the plural lead is what shipped pass-9 F1.
  #
  # Restricting to the classical row is load-bearing, not tidiness. Over ALL bullets a
  # count of 1 is also produced by the `mpl` bullet, which names one method too, so the
  # unrestricted form is satisfied with the singular one-way lead never rendered --
  # the very shape it claims to close. Which bullets are classical is read off the
  # method names in the output, never from a list of branches.
  method_names <- lapply(distinct, bh_msg_methods)
  classical <- vapply(
    method_names,
    function(m) length(m) > 0L && all(m %in% c("searle", "burch")),
    logical(1)
  )
  expect_true(any(classical))
  oneway_counts <- lengths(method_names[classical])
  expect_true(1L %in% oneway_counts)
  expect_true(2L %in% oneway_counts)

  # A pin on the number of DISTINCT renderings observed -- the producer's, not a list
  # of the author's. It reds in both directions that matter: a grid drifting off a
  # branch drops the count, and a REACHABLE rendering added to the hint raises it, so a
  # new literal cannot arrive unread the way pass-9's did.
  expect_identical(length(distinct), 3L)

  # Positive controls, driven off the intervals verification really computed. The
  # invariant above asserts an ABSENCE, so its DETECTOR must be shown capable of seeing
  # the thing it denies -- at every numeric rendering a leak could plausibly take. Both
  # predecessors of this guard passed precisely by being blind to one.
  #
  # Scope, exactly: these control `num_tokens()`, appending each value to an
  # already-rendered bullet. They say nothing about `render()`, which is controlled
  # instead by the end-to-end substring comparison above.
  finite_ends <- unique(ends[is.finite(ends)])
  expect_gt(length(finite_ends), 0L)
  for (b in distinct) {
    base <- render(b)
    for (v in finite_ends) {
      for (rendered in c(
        format(v),
        format(round(v, 3)),
        format(signif(v, 3))
      )) {
        expect_gt(length(num_tokens(paste0(base, " (", rendered, ")"))), 0L)
      }
    }
  }
})
