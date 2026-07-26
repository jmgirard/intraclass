# Design-aware hint for the CI-stage boundary aborts (M93) --------------------
#
# When the Monte-Carlo default aborts near the sigma^2 -> 0 boundary
# (`intraclass_singular_fit`), the generic remedies -- refit, aggregate, inspect the
# model -- do not tell the user the one thing that would actually help: that an
# opt-in `ci_method` exists which returns an interval on data where the default
# cannot. Which method that is depends entirely on the design in hand, so a blanket
# "try mpl" would be wrong off the two-way random agreement cell.
#
# This is a PURE function of the predicates `icc()` has already computed at its
# `ci_method` fences (`R/icc.R`) -- it re-derives nothing and fits nothing. The rows
# below mirror those fences exactly; `tests/testthat/test-boundary-abort-hint.R`
# holds the GP7 guard that every method named here is genuinely ACCEPTED by `icc()`
# on that design, so a later fence change reds a test instead of leaving the hint
# quietly pointing at another abort.
#
# The hint is ADDITIVE: the abort class, its leading message, and its existing
# generic remedies are untouched (AC2/AC5). Nothing here implements a
# fallback-on-abort default -- that is the distinct `#3`/ADR-003 contract change
# D-012 fenced out ("A classical fallback-on-abort default behaviour is a distinct,
# later `#3` question, not decided here").
#
# Evidential note on the wording, and on what is NOT named. Every method named here
# is a DETERMINISTIC closed form whose 0-abort record is measured: D-012 measured
# SEARLE and Burch returning a finite interval on 100% of 32,000 balanced one-way
# datasets where the MC default aborted on 4-44%, and each method's parenthetical is
# D-012's own one-line characterization. `ci_method = "npbootstrap"` is named on NO
# design, which also empties the unbalanced one-way row (it is the only method
# shipping that cell, D-013). Its second abort is a RESAMPLE-stage guard
# (`R/ci-npbootstrap.R:178-191`) that is stochastic and not a property of the observed
# data at all, so no design predicate can fence it -- two M93 review passes tried, with
# a raw subject count and then a subject-count floor, and the ordinary double-code
# design (most subjects rated once, a few doubled) defeated both at every size. M97
# takes it up behind a predicate derived from the data rather than the design.

# Exact data degeneracy, PER ROW: TRUE when the data are degenerate enough that the
# methods THAT ROW names abort on them. The design predicates alone cannot see this --
# a balanced one-way design whose scores are constant within subject is a perfectly
# ordinary design carrying data on which searle and burch both abort (M93 review F2).
#
# The check is per row and never shared, because the rows fail on different data. A
# shared check that ORed every row's condition together suppressed the classical row on
# data where `searle` and `burch` both return intervals (M93 pass-3 F2): the disjuncts
# it borrowed belonged to `npbootstrap`, which no row names any more. A row falls
# silent only where its OWN methods abort.
#
# One-way (searle/burch): ASK the shipped guard rather than restate it, by running
# `classical_guard_observed()` on the same `classical_oneway_ss()` summary both
# reducers build and catching its abort. A restatement is a copy that drifts -- the
# copy is how pass-2's F2 shipped -- and this is the `mpl_kappa_available()` pattern
# from the same review: one source of truth, the shipped code itself. Forced only on
# the balanced branch, which is the only one that names a method, so
# `classical_oneway_ss()`'s balanced assumption always holds where it runs.
#
# Two-way (mpl): only all-constant data break it (its optim dies at the initial
# parameters). Zero error MS with a healthy subject or rater MS is fine -- mpl returns
# an interval there -- and the exactly-additive cell never reaches this code at all,
# because the glmmTMB POINT fit dies on it first (all probed at the M93 implement gate).
boundary_data_degenerate <- function(df, oneway) {
  if (isTRUE(oneway)) {
    # EVERYTHING is inside the tryCatch, extraction included. `npb_groups()` raises
    # `intraclass_unidentified` on an NA score, and this runs while the boundary abort's
    # message vector is being built -- so a probe that throws does not report a
    # degeneracy, it REPLACES the user's `intraclass_singular_fit` with an unrelated
    # error about a bootstrap they never asked for (M93 pass-4 F2, scored 95). Any
    # failure here means "this row's methods cannot work on this data", which is exactly
    # the answer the check exists to give, so it is caught and reported as TRUE.
    return(tryCatch(
      {
        ss <- classical_oneway_ss(npb_groups(df))
        classical_guard_observed(ss, "SEARLE exact-F", rlang::current_env())
        # MSA = 0 (every subject mean exactly equal) passes both shipped guards and
        # still breaks both methods: `burch_kappa_hat()` divides by sqrt(msa) -> NaN,
        # and searle's averaged endpoint is -Inf (pass-4 F3, scored 87). searle's
        # ICC(1) alone survives as [-1/(n-1), -1/(n-1)], a zero-width interval pinned
        # at the support floor; the implement gate chose to stay silent rather than
        # offer that, so the whole row goes quiet here.
        isTRUE(ss$msa == 0)
      },
      error = function(e) TRUE
    ))
  }
  isTRUE(stats::var(df$score) == 0)
}

# Does the Spearman-Brown projection to each requested divisor stay well-posed for this
# method's own ICC(1) interval? `npb_sb(rho, m) = m*rho/(1 + (m-1)*rho)` has a pole at
# `rho = -1/(m-1)`; a lower endpoint below the pole is mapped ABOVE +1 and the interval
# comes back reversed -- `searle` gives ICC(6) = [4.594, 0.602] on ordinary boundary
# data (pass-4 F4, scored 88). `icc()` fences a numeric `unit` off the unbalanced
# npbootstrap path for this same reason (`R/icc.R:1417-1431`); the balanced classical
# path never had such a fence.
#
# The test is exact and per method, not a blanket numeric-`unit` refusal: measured at
# the implement gate against the real intervals at m = 2, 3, 4, 5, 6, 10, 20, it agrees
# with observed reversal in every cell for BOTH methods -- and the two methods differ
# (searle reverses from m = 5, burch only from m = 10 on the same data), so a shared
# rule would have to over-suppress one of them.
boundary_sb_safe <- function(rho_lower, divisors) {
  if (!is.finite(rho_lower)) {
    return(FALSE)
  }
  all(vapply(
    divisors,
    function(m) !is.finite(m) || m <= 1 || rho_lower > -1 / (m - 1),
    logical(1)
  ))
}

# Per-method verdict for the balanced one-way row: is this method's ICC(1) interval
# projectable to every divisor the caller asked for? Returns a named logical, one entry
# per method, in the order the message names them. Each method's OWN ICC(1) lower
# endpoint is used -- they differ (searle's exact-F limit is more negative than burch's
# REML one on the same data), which is why the pair can split. Wrapped whole: like
# `boundary_data_degenerate()`, this runs while an abort message is being built, so a
# failure must read as "cannot offer this method", never escape (pass-4 F2).
boundary_classical_sb_ok <- function(df, conf_level, divisors) {
  out <- c(searle = FALSE, burch = FALSE)
  tryCatch(
    {
      ss <- classical_oneway_ss(npb_groups(df))
      s_lo <- searle_endpoints(
        ss$msa,
        ss$mse,
        ss$df1,
        ss$df2,
        ss$n,
        conf_level
      )[["lower"]]
      kappa_bc <- burch_kappa_bc(
        burch_kappa_hat(npb_groups(df), ss$msa, ss$mse),
        ss$k,
        ss$n
      )
      b_lo <- burch_reml_endpoints(
        ss$msa,
        ss$mse,
        ss$k,
        ss$n,
        burch_g(kappa_bc),
        conf_level
      )[["lower"]]
      out[["searle"]] <- boundary_sb_safe(s_lo, divisors)
      out[["burch"]] <- boundary_sb_safe(b_lo, divisors)
    },
    error = function(e) NULL
  )
  out
}

# Build the design-aware `i =` bullets for a boundary abort. Returns a named
# character vector (every name "i", ready to splice into a cli message vector), or
# character(0) when no opt-in method applies to this design -- in which case the
# abort keeps its generic remedies alone (AC4).
#
# Four inputs are NOT design fences, each added after a review pass found the hint
# naming a method that then failed: `n_s`/`n_r` (the kappa_m calibration grid, pass-1
# F1), `degenerate` (data on which the row's own methods abort, pass-1 F2 and pass-4
# F3), `complete` (pass-4 F1) and `sb_ok` (pass-4 F4). `degenerate` and `sb_ok` are
# PROMISES, forced inside whichever branch names a method and nowhere else.
#
# `complete` is FALSE when any score is `NA`. It gates every row, before the design
# split, because no method survives such data: `balanced` is computed from
# `table(subject, rater)` CELL COUNTS (`R/design.R:53`), which count an NA-scored row
# as an observed cell, so a design carrying NAs looks complete to every fence here
# while `mpl` aborts on the reshaped cell and the classical pair's summary goes NA
# (pass-4 F1, scored 94). One gate for one input beat two mechanisms guarding the same
# hole (implement gate, 2026-07-26).
boundary_method_hint <- function(
  oneway,
  multilevel,
  replicates,
  raters,
  balanced,
  type,
  type_supplied,
  conf_level,
  n_s,
  n_r,
  complete,
  degenerate,
  sb_ok
) {
  # A cluster facet or within-cell replicates put the design outside EVERY opt-in
  # method's fence, whatever else is true, so neither branch below can apply.
  if (isTRUE(multilevel) || isTRUE(replicates)) {
    return(character(0))
  }
  if (!isTRUE(complete)) {
    return(character(0))
  }

  if (isTRUE(oneway)) {
    # UNBALANCED: nothing to name. `searle`/`burch` are balanced-only (D-013), and
    # `npbootstrap` -- the only method shipping this cell -- is out (see the header).
    if (!isTRUE(balanced)) {
      return(character(0))
    }
    # ...and BALANCED only where the classical pair's own guard stays quiet. Forcing
    # `degenerate` here rather than above the design split is what keeps the check
    # per-row: this branch forces the one-way condition, the `mpl` branch below forces
    # the two-way one, and no other design forces either.
    if (isTRUE(degenerate)) {
      return(character(0))
    }
    # Each method is named only where its own Spearman-Brown projection stays well
    # posed for every requested divisor, so the pair can split: at a numeric `unit`
    # searle drops out before burch does.
    named <- names(sb_ok)[vapply(sb_ok, isTRUE, logical(1))]
    if (!length(named)) {
      return(character(0))
    }
    blurb <- c(
      searle = "{.code ci_method = \"searle\"} (best calibrated when the data are \\
                close to normal, and narrowest)",
      burch = "{.code ci_method = \"burch\"} (never under-covers, at the cost of a \\
               wider interval)"
    )
    lead <- if (length(named) > 1L) {
      "Two interval methods return a result for this design where the default \\
       cannot: "
    } else {
      "An interval method returns a result for this design where the default \\
       cannot: "
    }
    return(c(
      i = paste0(lead, paste(blurb[named], collapse = " and "), ".")
    ))
  }

  # `mpl` is the balanced-complete two-way RANDOM absolute-agreement cell only, at a
  # conf_level AND an (n_r, n_s) geometry its kappa_m table is calibrated for
  # (D-014/D-015). An EXPLICIT consistency request is a genuine conflict icc() aborts
  # on; an unset `type` still resolves, because icc() narrows the default to agreement
  # when mpl is selected. The user reaching this abort is on the DEFAULT ci_method, so
  # `type` has not been narrowed yet and `type_supplied` is what distinguishes the two
  # cases.
  if (!identical(raters, "random") || !isTRUE(balanced)) {
    return(character(0))
  }
  if (isTRUE(type_supplied) && "consistency" %in% type) {
    return(character(0))
  }
  if (isTRUE(degenerate)) {
    return(character(0))
  }
  # The level set AND the rater/subject grid are read from the shipped table via the
  # lookup itself (M91/D-017 for the levels; M93 review F1 for the grid), never
  # hardcoded here -- icc()'s mpl fence checks the level but not the geometry, so this
  # is the only thing standing between the hint and an `intraclass_unsupported` abort
  # at, say, 8 subjects.
  if (!mpl_kappa_available(n_r, n_s, conf_level)) {
    return(character(0))
  }
  c(
    i = "{.code ci_method = \"mpl\"} returns a result for this design where the \\
         default cannot: the modified profile-likelihood interval is defined on \\
         every dataset at this boundary, at the cost of being conservative."
  )
}
