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
    ss <- classical_oneway_ss(npb_groups(df))
    probe <- tryCatch(
      classical_guard_observed(ss, "SEARLE exact-F", rlang::current_env()),
      error = function(e) e
    )
    return(inherits(probe, "condition"))
  }
  isTRUE(stats::var(df$score) == 0)
}

# Build the design-aware `i =` bullets for a boundary abort. Returns a named
# character vector (every name "i", ready to splice into a cli message vector), or
# character(0) when no opt-in method applies to this design -- in which case the
# abort keeps its generic remedies alone (AC4).
#
# `n_s`/`n_r` are the observed subject and rater counts and `degenerate` is
# `boundary_data_degenerate()` above: the two inputs that are NOT design fences, added
# after review pass 1 found the hint naming methods that then abort (F1: `mpl` off its
# kappa_m calibration grid; F2: the one-way methods on degenerate data). `degenerate`
# is a PROMISE carrying the row-appropriate condition, forced inside whichever branch
# names a method and nowhere else.
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
  degenerate
) {
  # A cluster facet or within-cell replicates put the design outside EVERY opt-in
  # method's fence, whatever else is true, so neither branch below can apply.
  if (isTRUE(multilevel) || isTRUE(replicates)) {
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
    return(c(
      i = "Two interval methods return a result for this design where the \\
           default cannot: {.code ci_method = \"searle\"} (best calibrated when \\
           the data are close to normal, and narrowest) and {.code \"burch\"} \\
           (never under-covers, at the cost of a wider interval)."
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
