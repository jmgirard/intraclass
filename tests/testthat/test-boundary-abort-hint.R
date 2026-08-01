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

# Small-integer 1-3 ratings treated as continuous: ordinary interrater data sitting at
# the sigma^2 -> 0 boundary, which is where the default MC aborts and where small-n
# bootstrap resamples go degenerate. Named for what it is -- small integers analysed as
# continuous scores -- and deliberately NOT for the discrete-outcome axis the package
# neither handles nor studies: a committed references page carries a CI-checked
# observation that that axis's name is absent from R/ and tests/, and borrowing the word
# for a fixture would falsify a true claim (`data-raw/check-reference-observations.py`).
# (Moved up from the sweep section at M97: the direct hint-builder tests now RUN
# npbootstrap on genuinely unbalanced data, so they need the builder too.)
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

# The double-code shape that defeated M93 pass 3: most subjects rated once, a few
# twice. The subjects carrying within-subject variance are only the doubled handful,
# so npbootstrap's resample-stage guard fires at EVERY subject count -- the shape no
# design predicate could fence, and the reason the hint RUNS the method instead (M97).
bh_doublecode <- function(n_s, n_doubled = 3L, seed = 1) {
  set.seed(seed)
  sizes <- rep(1L, n_s)
  sizes[seq_len(n_doubled)] <- 2L
  data.frame(
    subject = factor(rep(seq_len(n_s), times = sizes)),
    rater = factor(sequence(sizes)),
    score = sample(1:3, sum(sizes), replace = TRUE)
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
  # The D-010 floor at the n0 production uses: the harmonic-mean effective group
  # size (== the rater count on balanced data). The raw rater count gave a
  # STRICTER floor than production's on unbalanced cells, so the named == usable
  # identity was judged against a mis-specified predicate (M97 review F6).
  n0 <- 1 / mean(1 / as.numeric(table(d$subject)))
  floor_rho <- ifelse(tb$index == "ICC(1)" & n0 > 1, -1 / (n0 - 1), -Inf)
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
# boundary_method_hint()'s ADMISSIBILITY stage is a pure function of the fence
# predicates; its USABILITY stage runs the candidate reducers (a 999-resample
# bootstrap included, since M97), so these direct tests drive it with real data
# and real estimands; the AC3 grid below then proves the methods it names are
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
  # The averaging divisor icc() itself passes: the HARMONIC mean of the
  # per-subject sizes (summarize_design()'s k_eff, its own expression so the
  # value is bit-identical), which equals the rater count on balanced data. The
  # raw rater count here made every unbalanced cell verify a DIFFERENT estimand
  # than production -- a different Spearman-Brown pole and D-010 floor -- which
  # is what the M97 review's F1 caught: the pinned seed-split was a
  # pole-crossing artifact, not resample instability.
  k <- 1 / mean(1 / as.numeric(table(df$subject)))
  defaults <- list(
    oneway = FALSE,
    multilevel = FALSE,
    replicates = FALSE,
    raters = "random",
    balanced = TRUE,
    type = c("agreement", "consistency"),
    type_supplied = FALSE,
    # The validated `unit` list icc() passes: the estimands and the admissibility
    # mirror read the same value, exactly as at the real call site (M97).
    unit = units,
    conf_level = 0.95,
    df = df,
    estimands = lapply(units, function(u) {
      icc_estimand(unit = u, k_eff = k, oneway = oneway)
    }),
    n0 = if (is.null(n0)) k else n0,
    seed = NULL,
    boot_samples = 999L
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
  # npbootstrap is deliberately NOT named here, at any subject count: the BALANCED
  # row stays deterministic-only (D-012's 0-abort evidence is a searle/burch
  # result), and M97 restored npbootstrap on the UNBALANCED row alone -- the cell
  # it is the only method to ship (D-013).
  expect_no_match(h[["i"]], "npbootstrap", fixed = TRUE)
  for (n in c(5L, 10L, 15L, 30L, 100L)) {
    expect_no_match(
      bh_hint(oneway = TRUE, balanced = TRUE, n_s = n)[["i"]],
      "npbootstrap",
      fixed = TRUE
    )
  }
})

test_that("unbalanced one-way hints npbootstrap only when the RUN verifies (AC2/AC4)", {
  # `searle`/`burch` are balanced-only (D-013); `npbootstrap` -- the only method
  # shipping this cell -- is named the way every other row is (M97): run the shipped
  # reducer on the data in hand and look at the interval. Its resample-stage abort
  # is stochastic, which is exactly why two review passes fenced it wrongly with
  # design predicates and why the run is the only evidence accepted.
  d_ok <- bh_smallint(20L, 3L, 1L, balanced = FALSE)

  # No caller seed: verification ran under the fixed `npb_hint_seed`, and the
  # bullet NAMES that seed -- the promised call is exactly the verified run.
  h <- bh_hint(oneway = TRUE, balanced = FALSE, df = d_ok)
  expect_length(h, 1L)
  expect_named(h, "i")
  expect_match(h[["i"]], "npbootstrap", fixed = TRUE)
  expect_match(h[["i"]], paste0("seed = ", npb_hint_seed), fixed = TRUE)
  # Quoted method strings, as bh_msg_methods() parses them: bare "mpl" would also
  # match inside the word "resamples".
  for (m in c("searle", "burch", "mpl")) {
    expect_no_match(h[["i"]], paste0("\"", m, "\""), fixed = TRUE)
  }

  # A caller seed: their own retry re-runs the verified draws, so the bullet is
  # seed-free -- no digit at all (the AC5 leak-guard invariant's clean case).
  h_seeded <- bh_hint(oneway = TRUE, balanced = FALSE, df = d_ok, seed = 5L)
  expect_length(h_seeded, 1L)
  expect_match(h_seeded[["i"]], "npbootstrap", fixed = TRUE)
  expect_no_match(h_seeded[["i"]], "seed = ", fixed = TRUE)
  expect_no_match(h_seeded[["i"]], "[0-9]")

  # Seed-specificity (AC3): under the production estimands the same 8x3 dataset
  # verifies under seed 1 and trips the resample guard under seed 2 (measured at
  # the review pass: usable under seeds 1,3,4,7,8; the guard fires under 2,5,6) --
  # so it is hinted under the one and silent under the other, and the NO-seed
  # verdict equals the fixed-seed-1 one, because that is the seed the run used.
  d_split <- bh_smallint(8L, 3L, 1L, balanced = FALSE)
  expect_length(
    bh_hint(oneway = TRUE, balanced = FALSE, df = d_split, seed = 1L),
    1L
  )
  expect_length(
    bh_hint(oneway = TRUE, balanced = FALSE, df = d_split, seed = 2L),
    0L
  )
  expect_length(bh_hint(oneway = TRUE, balanced = FALSE, df = d_split), 1L)

  # The caller's `boot_samples` is threaded through the verification exactly like
  # the seed (M97 review F5): a run that succeeds at the default 999 can abort at
  # a caller's larger count -- more resamples, more chances for a degenerate one
  # -- and a hint verified at a count the retry will not use is the
  # hinted-then-unusable failure AC4 forbids. Same data, same seed: hinted at the
  # default, silent at the caller's 2000.
  expect_length(
    bh_hint(
      oneway = TRUE,
      balanced = FALSE,
      df = d_split,
      seed = 1L,
      boot_samples = 2000L
    ),
    0L
  )

  # The double-code shape that defeated M93 pass 3: silent at EVERY probed size,
  # because the run itself trips the resample guard -- at 999 resamples, never a
  # reduced count (AC4).
  for (n in c(15L, 30L, 60L)) {
    expect_length(
      bh_hint(oneway = TRUE, balanced = FALSE, df = bh_doublecode(n)),
      0L
    )
  }

  # ADMISSIBILITY: a numeric `unit` is refused at dispatch on the unbalanced
  # npbootstrap path (its D-study pole is not pole-safe there), so the string is
  # never named however well the run went -- the fence mirror, not a verdict.
  expect_length(
    bh_hint(
      oneway = TRUE,
      balanced = FALSE,
      df = d_ok,
      units = list("single", 6)
    ),
    0L
  )
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
  # (The unbalanced ONE-WAY row is no longer fenced -- M97 names npbootstrap there
  # when its run verifies; see the dedicated test above.)
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
    ),
    # M97: the unbalanced one-way row. The hint and the acceptance call share
    # `seed = 1`, so the run the hint verified is the run icc() is asked to
    # accept -- the promise as made.
    list(
      lab = "one-way unbalanced",
      data = bh_smallint(20L, 3L, 1L, balanced = FALSE),
      args = list(model = "oneway", seed = 1),
      pred = list(
        oneway = TRUE,
        balanced = FALSE,
        df = bh_smallint(20L, 3L, 1L, balanced = FALSE),
        seed = 1
      )
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

  # Unbalanced one-way: the two deterministic methods really are refused there
  # (D-013 fences them to balanced), so their absence is a fence and not caution.
  du <- bh_ok_oneway(sizes = c(rep(5L, 15L), rep(3L, 5L)))
  for (m in c("searle", "burch")) {
    expect_error(
      suppressWarnings(suppressMessages(
        icc(du, score, subject, rater, model = "oneway", ci_method = m)
      )),
      class = "intraclass_unsupported"
    )
  }
  # ...and since M97 the row's remaining silence is a VERDICT, not a fence: on the
  # double-code shape the hint says nothing because the run failed, and the user's
  # own call under the same fixed seed really does abort -- silence agrees with
  # what they would have gotten.
  d_dc <- bh_doublecode(30L)
  expect_length(bh_hint(oneway = TRUE, balanced = FALSE, df = d_dc), 0L)
  expect_error(
    suppressWarnings(suppressMessages(
      icc(
        d_dc,
        score,
        subject,
        rater,
        model = "oneway",
        ci_method = "npbootstrap",
        seed = npb_hint_seed
      )
    )),
    class = "intraclass_singular_fit"
  )
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
    # Asked under the SAME `seed = 1` the abort above was fired with: for
    # `npbootstrap` the verdict is seed-specific (M97 AC3), so usability under a
    # different seed would not be the property the hint promised.
    usable <- Filter(
      function(x) bh_usable(d, x, c(args, list(seed = 1))),
      candidates
    )
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
  named_unbal <- 0L
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
      # Balanced admits the two classical methods; unbalanced admits exactly
      # `npbootstrap` -- the only method shipping that cell (D-013), named since
      # M97 when its own run verifies. "named == usable" carries both halves:
      # a hinted-then-unusable run AND over-suppression each red.
      candidates = if (cell$bal) c("searle", "burch") else "npbootstrap",
      forbid = if (cell$bal) {
        c("mpl", "npbootstrap")
      } else {
        c("mpl", "searle", "burch")
      }
    )
    # Every DECLARED cell must have fired the abort at least once. Without this a
    # cell that never aborts contributes nothing while reading as covered.
    expect_identical(
      paste(lab, "aborted:", r$aborts > 0L),
      paste(lab, "aborted:", TRUE)
    )
    named_total <- named_total + r$named
    if (!cell$bal) {
      named_unbal <- named_unbal + r$named
    }
  }
  # The restored row must be shown FIRING, not merely consistent: at least one
  # unbalanced abort must have named npbootstrap (the only candidate there), or the
  # M97 row would pass this sweep by universal silence.
  expect_gt(named_unbal, 0L)

  # Imbalance SHAPE, not only subject count (M97 AC4; the M93 pass-3 blind spot was
  # exactly this axis): the double-code design -- most subjects rated once, a few
  # twice -- at three sizes. The identity runs at the shipped boot_samples = 999,
  # never a reduced count, which would lower the chance of tripping a guard that
  # fires on any degenerate resample (M93 pass-3 F3).
  for (n in c(15L, 30L, 60L)) {
    lab <- paste0("double-code ", n, "s")
    r <- bh_sweep_cell(
      lab = lab,
      build = function(sd) bh_doublecode(n, seed = sd),
      args = list(model = "oneway"),
      candidates = "npbootstrap",
      forbid = c("mpl", "searle", "burch")
    )
    expect_identical(
      paste(lab, "aborted:", r$aborts > 0L),
      paste(lab, "aborted:", TRUE)
    )
    named_total <- named_total + r$named
  }

  # ...and somewhere in the sweep a method must actually have been NAMED, or
  # "named == usable" would hold everywhere by universal silence -- including by
  # npbootstrap never verifying on any unbalanced cell.
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

  # npbootstrap (M97): the verdict is about the RUN, so it carries the seed the
  # run used. Estimands and n0 use the HARMONIC k_eff production passes (2.4 for
  # alternating sizes 3,2) -- the raw rater count verified a different estimand
  # (the M97 review's F1). On a healthy unbalanced 20x3 every probed seed
  # verifies; on the same generator shrunk to 8x3 the SAME data verifies under
  # seeds 1,3,4,7,8 and fails under 2,5,6 (the resample guard trips), which is
  # exactly why the check runs under the seed the user's own call would use
  # rather than treating one run as evidence about every seed (AC3).
  keff_u <- function(d) 1 / mean(1 / as.numeric(table(d$subject)))
  d_unbal <- bh_smallint(20L, 3L, 1L, balanced = FALSE)
  e_u <- ests(list("single", "average"), keff_u(d_unbal))
  for (s in c(1L, 5L, 8L)) {
    expect_true(boundary_method_usable(
      "npbootstrap",
      d_unbal,
      e_u,
      0.95,
      n0 = keff_u(d_unbal),
      seed = s
    ))
  }
  d_split <- bh_smallint(8L, 3L, 1L, balanced = FALSE)
  e_s <- ests(list("single", "average"), keff_u(d_split))
  for (s in c(1L, 4L, 8L)) {
    expect_true(boundary_method_usable(
      "npbootstrap",
      d_split,
      e_s,
      0.95,
      n0 = keff_u(d_split),
      seed = s
    ))
  }
  for (s in c(2L, 5L, 6L)) {
    expect_false(boundary_method_usable(
      "npbootstrap",
      d_split,
      e_s,
      0.95,
      n0 = keff_u(d_split),
      seed = s
    ))
  }
  # No seed argument -> the run uses the fixed `npb_hint_seed` the bullet names,
  # so the no-seed verdict EQUALS the seed-1 verdict on both datasets.
  expect_identical(npb_hint_seed, 1L)
  expect_true(boundary_method_usable(
    "npbootstrap",
    d_split,
    e_s,
    0.95,
    keff_u(d_split)
  ))
  expect_true(boundary_method_usable(
    "npbootstrap",
    d_unbal,
    e_u,
    0.95,
    keff_u(d_unbal)
  ))
  # ...and the caller's boot_samples is part of the run's identity too (review
  # F5): the same data + seed that verify at the default 999 fail at 2000.
  expect_false(boundary_method_usable(
    "npbootstrap",
    d_split,
    e_s,
    0.95,
    keff_u(d_split),
    seed = 1L,
    boot_samples = 2000L
  ))

  # The double-code shape that defeated M93 pass 3 (most subjects rated once, a few
  # twice): the resample guard fires under every probed seed, so verification says
  # FALSE by running -- the shape no design predicate could fence.
  set.seed(1)
  dc_sizes <- rep(1L, 30L)
  dc_sizes[1:3] <- 2L
  d_dc <- data.frame(
    subject = factor(rep(seq_len(30L), times = dc_sizes)),
    rater = factor(sequence(dc_sizes)),
    score = sample(1:3, sum(dc_sizes), replace = TRUE)
  )
  for (s in 1:4) {
    expect_false(boundary_method_usable(
      "npbootstrap",
      d_dc,
      ests(list("single", "average"), keff_u(d_dc)),
      0.95,
      n0 = keff_u(d_dc),
      seed = s
    ))
  }

  # An unregistered method is never usable.
  expect_false(boundary_method_usable("montecarlo", d1, e_default, 0.95, 5))
})

test_that("ONE verification helper serves both method families (AC1)", {
  # M97 registered `npbootstrap` as a ROW in `boundary_method_usable()`, never as a
  # second checker -- a divergent copy is the drift pattern that produced M93's
  # pass-2 finding. Two halves: the namespace carries exactly the two boundary
  # verification functions (a sibling `*_usable` checker appearing reds this), and
  # both families' verdicts come out of the same function through the same
  # acceptance predicate.
  expect_identical(
    sort(grep("usable", ls(asNamespace("intraclass")), value = TRUE)),
    c("boundary_interval_usable", "boundary_method_usable")
  )
  ests <- lapply(list("single", "average"), function(u) {
    icc_estimand(unit = u, k_eff = 3, oneway = TRUE)
  })
  # Deterministic family and resampling family, one call surface each.
  d_bal <- bh_oneway(n_s = 20, n_k = 3)
  d_unbal <- bh_smallint(20L, 3L, 1L, balanced = FALSE)
  expect_true(boundary_method_usable("searle", d_bal, ests, 0.95, n0 = 3))
  expect_true(boundary_method_usable(
    "npbootstrap",
    d_unbal,
    ests,
    0.95,
    n0 = 3,
    seed = 1L
  ))
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
    list("mpl", d_empty),
    # npbootstrap's own abort surfaces: the observed-data degeneracy guard
    # (SSA = 0 / MSE = 0), the extraction guard (NA scores, empty), and the
    # RESAMPLE-stage guard (the double-code shape trips it under seed 1) -- every
    # one must be swallowed into a bare FALSE, or the check would replace the
    # user's boundary abort with a bootstrap error (the M93 pass-4 F2 failure
    # mode, in a new place -- M97 AC1).
    list("npbootstrap", bh_degen_within()),
    list("npbootstrap", bh_degen_between()),
    list("npbootstrap", d_na_all),
    list("npbootstrap", d_empty),
    list("npbootstrap", bh_smallint(8L, 3L, 1L, balanced = FALSE))
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

# ---- M97 T2/AC2: the verification run is RNG-neutral (#9) --------------------
# The npbootstrap verification CONSUMES randomness inside an abort path. #9 says a
# user who never asked for a bootstrap cannot have their draws perturbed by one, so
# the run always receives a concrete seed (the caller's, else `npb_hint_seed`) and
# goes through `with_rng_seed()`, which restores the ambient stream. Pinned here
# rather than assumed -- an unseeded `npbootstrap_ci()` call would draw from the
# ambient stream, so a refactor dropping the seed fallback reds these.

test_that("a hint that runs the bootstrap leaves the RNG stream untouched (AC2)", {
  d_ok <- bh_smallint(20L, 3L, 1L, balanced = FALSE)

  # No caller seed: the fixed-seed run must restore the ambient state exactly.
  set.seed(20260731)
  before <- .Random.seed
  h <- bh_hint(oneway = TRUE, balanced = FALSE, df = d_ok)
  expect_length(h, 1L) # the run really happened -- a silent cell asserts nothing
  expect_identical(.Random.seed, before)

  # ...and under a caller seed.
  set.seed(20260731)
  before <- .Random.seed
  h <- bh_hint(oneway = TRUE, balanced = FALSE, df = d_ok, seed = 5L)
  expect_length(h, 1L)
  expect_identical(.Random.seed, before)

  # A FAILING run restores the stream too: the abort inside `npbootstrap_ci()`
  # unwinds through with_rng_seed()'s on.exit handler. (The fixture is built
  # BEFORE the capture -- the builder's own set.seed() is not the property here.)
  d_dc <- bh_doublecode(30L)
  set.seed(20260731)
  before <- .Random.seed
  expect_length(bh_hint(oneway = TRUE, balanced = FALSE, df = d_dc), 0L)
  expect_identical(.Random.seed, before)
})

test_that("an icc() abort that ran the bootstrap verification is RNG-neutral (AC2)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # Seeded end to end: the whole call -- engine fit, MC draws, verification -- is
  # a no-op on the ambient stream, on the very call whose abort message proves the
  # bootstrap ran (it names npbootstrap).
  fired <- FALSE
  set.seed(42)
  invisible(stats::runif(1)) # make sure .Random.seed exists
  for (sd in 1:10) {
    d <- bh_smallint(20L, 3L, sd, balanced = FALSE)
    before <- .Random.seed
    got <- tryCatch(
      {
        suppressWarnings(suppressMessages(
          icc(d, score, subject, rater, model = "oneway", seed = 1)
        ))
        NULL
      },
      intraclass_singular_fit = function(e) e
    )
    expect_identical(.Random.seed, before)
    if (
      !is.null(got) && grepl("npbootstrap", conditionMessage(got), fixed = TRUE)
    ) {
      fired <- TRUE
      break
    }
  }
  expect_identical(fired, TRUE)

  # Unseeded end to end: the MC default legitimately draws from the ambient stream,
  # so "unchanged" is not the property -- "unperturbed BY THE VERIFICATION" is. The
  # stream must land in the same state as the identical call with the hint disabled,
  # or the verification leaked draws into the user's stream.
  abort_state <- function(sd) {
    set.seed(99)
    d <- bh_smallint(20L, 3L, sd, balanced = FALSE)
    msg <- tryCatch(
      {
        suppressWarnings(suppressMessages(
          icc(d, score, subject, rater, model = "oneway")
        ))
        NA_character_
      },
      intraclass_singular_fit = function(e) conditionMessage(e)
    )
    list(state = .Random.seed, msg = msg)
  }
  compared <- FALSE
  for (sd in 1:10) {
    with_hint <- abort_state(sd)
    if (is.na(with_hint$msg)) {
      next
    }
    without_hint <- with_mocked_bindings(
      abort_state(sd),
      boundary_method_hint = function(...) character(0)
    )
    expect_identical(with_hint$state, without_hint$state)
    if (grepl("npbootstrap", with_hint$msg, fixed = TRUE)) {
      compared <- TRUE
      break
    }
  }
  # The comparison must have covered a call whose verification RAN the bootstrap.
  expect_identical(compared, TRUE)
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
    # Originally the cell that made this test able to FAIL: `searle` at 8 subjects,
    # `unit = 10`, `conf_level = 0.80` genuinely reported [1.276702, 1.824471] --
    # above +1, the shipped defect M93 routed around. That defect is now FIXED: the
    # projection past `npb_sb()`'s pole aborts in the reducer (`npb_guard_sb_pole`),
    # so this cell exercises refusal parity -- reducer and `icc()` must decline it
    # together -- rather than endpoint equality.
    #
    # WHAT THIS GRID DETECTS, and what supplies each class (M98, all measured by
    # mutating `conf.low` at the reporting-path assembly, R/icc.R:2209):
    #   - a clamp binding at 0 (`pmax(0, .)`): eight boundary cells, min -0.5855.
    #   - a clamp binding at -1 (`pmax(-1, .)`): at HEAD this had exactly ONE
    #     supplier, the M97 npbootstrap `unit = "average"` cell at -2.5338 -- and
    #     that cell is SEEDED (`seed = 4`), so the whole class rode on one seed.
    #     The M98 SSA = 0 `unit = 2` cell (-2) adds a seed-free second supplier.
    #   - a clamp binding only on NON-FINITE endpoints: the M98 SSA = 0
    #     `unit = "average"` cell (-Inf) is the sole supplier. Before it, that
    #     mutation passed against the whole grid.
    #   - a HIGH-side clamp (`pmin(1, .)`): NOT detected, and not detectable here.
    #     The pole cell above was the only supplier, and since the 2026-08-01
    #     hotfix fenced `npb_sb()`'s pole no shipped `ci_method` can report an
    #     endpoint above +1 at all. A probe would need a synthetic reducer or an
    #     injected endpoint, neither of which exercises the reporting path this
    #     test exists to pin -- so it is a ROADMAP candidate, not a gap to paper
    #     over with a weaker probe.
    #
    # The two class assertions after the loop exist because losing a class
    # SILENTLY is the failure mode actually observed here: the high side had no
    # assertion, so the hotfix removed its only supplier and every test still
    # passed. Note the wording -- these endpoints are BELOW the conventional
    # [-1, 1] range, NOT "out of support": under D-010 the averaged/projected
    # form's support is (-Inf, 1), which is why `npb_guard_sb_pole()` permits
    # -Inf (the pole reached exactly) while refusing values past the pole.
    list(
      lab = "one-way 8x2 past the projection pole",
      d = bh_pole_oneway(),
      args = list(model = "oneway", conf_level = 0.80),
      methods = "searle",
      oneway = TRUE,
      conf_level = 0.80,
      units = list(10)
    ),
    # M97: the resampling family, both sides under the SAME seed -- the reducer
    # here and the icc() call below draw identical resamples, so the endpoint
    # comparison is exact, not statistical. Units are the two the unbalanced
    # path admits (a numeric `unit` is fenced at dispatch there).
    list(
      lab = "one-way unbalanced 20x3 npbootstrap",
      d = bh_smallint(20L, 3L, 1L, balanced = FALSE),
      args = list(model = "oneway", seed = 4),
      methods = "npbootstrap",
      oneway = TRUE,
      units = list("single", "average")
    ),
    # M98: the NON-FINITE class, which no other cell supplies. SSA = 0 (every
    # subject mean exactly equal, MSE > 0) puts searle's ICC(1) limits exactly on
    # the open support floor -1/(n0-1); `npb_sb()`'s pole sits at that same value
    # when the divisor is n0, so the projection returns -Inf -- the correct limit,
    # and IN support for the averaged/projected form under D-010 ((-Inf, 1)), which
    # is why `npb_guard_sb_pole()` (strictly `< 0`) deliberately permits it.
    # Seed-free by construction: `bh_degen_between()` makes no RNG call, so this
    # class does not rest on a seed the way the npbootstrap cell above does.
    # `unit = 5` is excluded on purpose -- there the pole is CROSSED rather than
    # reached, both sides abort, and it would be a second refusal cell the
    # `compared` count below does not admit.
    list(
      lab = "one-way SSA = 0 searle (non-finite)",
      d = bh_degen_between(),
      args = list(model = "oneway"),
      methods = "searle",
      oneway = TRUE,
      units = list("single", "average", 2)
    )
  )
  units <- list("single", "average", 2, 6)

  checked <- 0L
  compared <- 0L
  # One census flag per CLAMP CLASS, read off the reducer side so the census still
  # describes what the grid covers even while a mutation is perturbing the icc()
  # side. Each is asserted separately after the loop (M98).
  seen_finite_below_neg1 <- FALSE
  seen_nonfinite <- FALSE
  for (case in cases) {
    # The averaging divisor icc() itself uses: the HARMONIC mean of the per-subject
    # sizes (k_eff), computed with summarize_design()'s own expression so the
    # floating-point value is bit-identical, not merely algebraically equal --
    # tolerance = 0 below means a different summation ORDER already reds. On
    # balanced data this equals the rater count; on the unbalanced npbootstrap
    # case (M97) the raw count would compare the reducer against a different
    # estimand than the one icc() reports.
    k <- 1 / mean(1 / as.numeric(table(case$d$subject)))
    cl <- if (is.null(case$conf_level)) 0.95 else case$conf_level
    case_units <- if (is.null(case$units)) units else case$units
    for (m in case$methods) {
      reducer <- switch(
        m,
        searle = searle_ci,
        burch = burch_ci,
        mpl = mpl_ci,
        npbootstrap = function(df, e, conf_level) {
          npbootstrap_ci(df, e, conf_level = conf_level, seed = 4)
        }
      )
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
          expect_lte(red[[1]]$conf.high, 1)
          lo <- red[[1]]$conf.low
          if (is.finite(lo) && lo < -1) {
            seen_finite_below_neg1 <- TRUE
          }
          if (!is.finite(lo)) {
            seen_nonfinite <- TRUE
          }
          compared <- compared + 1L
        }
        checked <- checked + 1L
      }
    }
  }
  # The exact cell count, not `>= 0`: a cell silently dropped from the loop must red
  # rather than pass on a smaller grid (pass-5 F2 was exactly that assertion). An
  # INTEGER LITERAL, deliberately, not an expression over `cases`/`units` -- a
  # derived count self-adjusts to whatever the grid happens to be and so asserts
  # nothing (M98). 5 method-cases x 4 units = 20, + 1 pole cell, + 2 npbootstrap
  # cells (M97), + 3 SSA = 0 cells (M98).
  expect_identical(checked, 26L)
  # ...and every cell but the pole cell must reach the NUMERIC comparison. Without
  # this the test would still pass if every cell degenerated to "both refused", which
  # asserts nothing about endpoint equality -- the vacuity that keeps recurring in
  # this file. The pole cell is the ONE deliberate refusal, and it is pinned as such
  # by `expect_identical(checked, ...)` above plus the computed/refused parity
  # assertion inside the loop; a second silent refusal would red this count.
  expect_identical(compared, 25L)
  # ...and each CLAMP CLASS must still have a live supplier, asserted SEPARATELY.
  # One combined "something lies outside [-1, 1]" assertion would keep passing on a
  # grid that had lost the non-finite class -- and losing a class silently is not
  # hypothetical: it is exactly what happened on the HIGH side, where the only cell
  # that could detect a `pmin(1, .)` clamp was the out-of-support `searle` pole cell
  # and the 2026-08-01 hotfix fenced it away with nothing pinning it (M98).
  expect_true(seen_finite_below_neg1)
  expect_true(seen_nonfinite)
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

  # M97: the unbalanced one-way row offers `npbootstrap`, and icc() accepts the
  # string there...
  d_unbal <- bh_smallint(20L, 3L, 1L, balanced = FALSE)
  expect_false(bh_unsupported(d_unbal, "npbootstrap", list(model = "oneway")))
  # ...while its numeric-`unit` exclusion mirrors a REAL fence: the D-study
  # projection is refused at dispatch on the unbalanced path (not pole-safe), so
  # the row's silence there is the fence, never over-suppression.
  expect_true(bh_unsupported(
    d_unbal,
    "npbootstrap",
    list(model = "oneway", unit = 6)
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

  # THE invariant, asserted on every bullet the producer returns: a hint bullet
  # carries no numeric token EXCEPT the one deliberate literal M97 decided at its
  # gate -- the fixed verification seed the no-seed `npbootstrap` bullet names, and
  # exactly that. Every other bullet is token-free (`ci_method`, `searle`, `burch`,
  # `mpl` and the prose around them all are), so there is no precision to match and
  # no rendering to evade; any further number is a decision to make here, not
  # something that slips through.
  #
  # The detector matches digits AND the non-finite word-tokens `Inf`/`NaN`/`NA`
  # (M97, closing the M93 pass-10 carry-in): a bullet that quoted a REJECTED
  # candidate's endpoint would leak `Inf` without a digit in sight, and the
  # digit-only predecessor was blind to exactly that. Word boundaries keep prose
  # like "NAmed" or "infinite" out of the match.
  num_tokens <- function(text) {
    regmatches(
      text,
      gregexpr(
        "[0-9]+(?:[.][0-9]+)?(?:[eE][-+]?[0-9]+)?|(?<![[:alnum:]_])-?(?:Inf|NaN|NA)(?![[:alnum:]_])",
        text,
        perl = TRUE
      )
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
    # The same cell WITHOUT a user seed (M97): the npbootstrap bullet then names
    # the fixed verification seed -- the one deliberate numeric token any bullet
    # may carry -- so this cell is what makes the seed-exception arm of the
    # invariant below reachable rather than dead.
    list(
      lab = "one-way, unbalanced, no user seed",
      build = function(sd) bh_smallint(20L, 3L, sd, balanced = FALSE),
      args = list(model = "oneway"),
      user_seed = NULL
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

  fire <- function(build, args, user_seed = 1) {
    for (sd in 1:10) {
      got <- tryCatch(
        {
          suppressWarnings(suppressMessages(do.call(
            icc,
            c(
              list(build(sd), quote(score), quote(subject), quote(rater)),
              args,
              list(ci_method = "montecarlo"),
              # A NULL user_seed really omits the argument: the no-seed cell must
              # reach the hint's is.null(seed) branch, not a seeded one.
              if (!is.null(user_seed)) list(seed = user_seed)
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
    msg <- fire(
      cell$build,
      cell$args,
      user_seed = if ("user_seed" %in% names(cell)) cell$user_seed else 1
    )
    expect_identical(
      paste(cell$lab, "aborted:", !is.null(msg)),
      paste(cell$lab, "aborted:", TRUE)
    )
    if (is.null(msg)) {
      next
    }

    # The whole-message enumeration, kept from T9/T10. The legitimate set per abort
    # site: site B reports the share of non-finite draws; site A carries no number
    # of its own; and since M97 a no-seed npbootstrap bullet contributes exactly
    # the seed tokens the invariant below licenses it. So the expected multiset is
    # the site's own token plus whatever this cell's bullets legitimately carry --
    # anything further (a leaked endpoint, a leaked `Inf`) is a red.
    #
    # Every cell of this grid lands on site B, so the site-A arm below is reachable
    # but not currently exercised, and its anchor could rot without reddening. (Site A
    # is the rare non-finite-covariance abort; no rate for THIS grid is measured here,
    # and T1's committed site enumeration is over its own six boundary geometries, not
    # these fixtures.) The arm is kept rather than dropped because a fixture shifting
    # onto site A must meet an assertion rather than an unhandled branch.
    tokens <- num_tokens(msg)
    cell_bullets <- bullets[seq_len(length(bullets) - before) + before]
    bullet_tokens <- unlist(lapply(cell_bullets, function(b) {
      num_tokens(render(b))
    }))
    # Anchor the bullet side of the enumeration to the LICENSED constant, not to
    # whatever the bullets carry -- computed from the bullets alone, a leaked
    # token would appear on both sides of the multiset comparison below and pass
    # (M97 review F8). Every token a bullet contributes must BE the seed literal.
    expect_true(all(bullet_tokens == as.character(npb_hint_seed)))
    site_b <- grepl("% of draws were non-finite", msg, fixed = TRUE)
    expect_true(
      site_b || grepl("parameter covariance is not finite", msg, fixed = TRUE)
    )
    if (site_b) {
      pct <- sub("^.*?([0-9]+(?:[.][0-9]+)?)% of draws.*$", "\\1", msg)
      expect_true(grepl(paste0(pct, "% of draws"), msg, fixed = TRUE))
      expect_identical(sort(tokens), sort(c(pct, bullet_tokens)))
    } else {
      expect_identical(sort(tokens), sort(bullet_tokens))
    }
    expect_match(msg, "could not be computed", fixed = TRUE)

    # ...and the bullets this cell produced are the text the user was actually shown.
    # This is the end-to-end half: without it the invariant would hold over strings
    # that never reach a message.
    for (b in unique(cell_bullets)) {
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
    if (
      grepl("npbootstrap", b, fixed = TRUE) && grepl("seed = ", b, fixed = TRUE)
    ) {
      # The seed-exception arm (M97 T3): the no-seed npbootstrap bullet names the
      # fixed verification seed so the promised call is the verified run. Exactly
      # that literal, exactly TWICE (the bullet's two `seed =` mentions), raw and
      # rendered -- `unique()` here would let a leaked value that happens to
      # equal the literal hide behind it (M97 review F9). A producer-chosen
      # INPUT; every value the run RETURNED stays discarded (D-018).
      expect_identical(
        num_tokens(b),
        rep(as.character(npb_hint_seed), 2L)
      )
      expect_identical(
        num_tokens(render(b)),
        rep(as.character(npb_hint_seed), 2L)
      )
    } else {
      expect_identical(num_tokens(b), character(0))
      expect_identical(num_tokens(render(b)), character(0))
    }
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

  # Both npbootstrap renderings were read (M97): the seeded, token-free form and
  # the no-seed form carrying the named verification seed. Without this the
  # seed-exception arm above could go dead -- satisfied vacuously by a grid that
  # never renders the bullet it licenses.
  npb <- vapply(
    method_names,
    function(m) identical(m, "npbootstrap"),
    logical(1)
  )
  npb_with_seed <- npb &
    vapply(distinct, grepl, logical(1), pattern = "seed = ", fixed = TRUE)
  expect_true(any(npb_with_seed))
  expect_true(any(npb & !npb_with_seed))

  # A pin on the number of DISTINCT renderings observed -- the producer's, not a list
  # of the author's. It reds in both directions that matter: a grid drifting off a
  # branch drops the count, and a REACHABLE rendering added to the hint raises it, so a
  # new literal cannot arrive unread the way pass-9's did.
  # 3 from M93 (mpl, classical singular, classical plural) + the 2 npbootstrap
  # forms M97 added.
  expect_identical(length(distinct), 5L)

  # Positive controls, driven off the intervals verification really computed. The
  # invariant above asserts an ABSENCE, so its DETECTOR must be shown capable of seeing
  # the thing it denies -- at every numeric rendering a leak could plausibly take.
  # Pass 7 passed precisely by being blind to one of those renderings; passes 8 and 9
  # passed by being blind to a whole bullet form, which is what the grid above answers.
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
    # ...and at every NON-finite rendering (M97, the M93 pass-10 carry-in): a
    # rejected candidate's endpoint arrives as `Inf`/`NaN`/`NA` with no digit in
    # sight, which the digit-only detector could not see. `format()` of a
    # non-finite double renders exactly these words.
    for (v in c("Inf", "-Inf", "NaN", "NA")) {
      leaked <- num_tokens(paste0(base, " (", v, ")"))
      expect_true(v %in% leaked)
    }
    # The seed-exception arm licenses one literal, never a licence to carry more:
    # a SECOND number appended to the licensed bullet is still seen.
    expect_gt(
      length(num_tokens(paste0(base, " (0.123)"))),
      length(num_tokens(base))
    )
  }
})
