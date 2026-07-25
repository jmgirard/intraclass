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
# Evidential note on the wording. For BALANCED one-way, D-012 measured all three
# named methods returning a finite interval on 100% of 32,000 datasets (0 aborts)
# where the MC default aborted on 4-44% -- so "returns a result where the default
# cannot" is earned, and each method's parenthetical is D-012's own one-line
# characterization. For UNBALANCED one-way that sweep does not apply (it was
# balanced-only), so the hint says npbootstrap is AVAILABLE and deliberately does
# not claim it survives the boundary (implement gate, 2026-07-25).

# Exact ANOVA degeneracy: TRUE when the DATA (not the design) are degenerate enough
# that every method a row below could name aborts on them. The design predicates alone
# cannot see this -- a balanced one-way design whose scores are constant within subject
# is a perfectly ordinary design carrying data on which searle, burch and npbootstrap
# all abort, and the M93 hint named all three (review F2).
#
# One-way: evaluate the shipped guards themselves rather than restate them. MSE = 0 is
# `classical_guard_observed()`'s condition (searle/burch) and a non-finite log F is
# `npbootstrap_ci()`'s (SSA = 0 or SSE = 0), so this is degenerate exactly when one of
# those fires. SSA = 0 alone kills only npbootstrap -- searle/burch still return an
# interval -- but the hint stays silent there too: the shipped balanced-one-way bullet
# names all three in one sentence, and a hint pointing at an abort is worse than none
# (AC3). Exact zero, matching the guards' own convention -- a small-but-positive F is
# the near-zero ICC these methods exist to serve, not a degeneracy.
#
# Two-way: only all-constant data break `mpl` (its optim dies at the initial
# parameters). Zero error MS with a healthy subject or rater MS is fine -- mpl returns
# an interval there -- and the exactly-additive cell never reaches this code at all,
# because the glmmTMB POINT fit dies on it first (all probed at the M93 implement gate).
boundary_data_degenerate <- function(df, oneway) {
  if (isTRUE(oneway)) {
    a <- npb_anova(split(df$score, df$subject))
    # isTRUE(): with one rating per subject MSE is NaN, but icc() has already aborted
    # on that design (unidentified), so this is belt-and-braces, never the live path.
    return(isTRUE(a$mse == 0) || !is.finite(a$logf))
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
# kappa_m calibration grid; F2: every one-way method on degenerate data).
boundary_method_hint <- function(
  oneway,
  multilevel,
  replicates,
  raters,
  balanced,
  type,
  type_supplied,
  conf_level,
  unit,
  n_s,
  n_r,
  degenerate
) {
  # A cluster facet or within-cell replicates put the design outside EVERY opt-in
  # method's fence, whatever else is true, so neither branch below can apply.
  if (isTRUE(multilevel) || isTRUE(replicates)) {
    return(character(0))
  }
  # Degenerate data disqualify every row below, so this precedes the design split.
  if (isTRUE(degenerate)) {
    return(character(0))
  }

  if (isTRUE(oneway)) {
    # `npbootstrap`/`searle`/`burch` are one-way methods; only npbootstrap ships the
    # unbalanced case (M84/M85), and it takes "single"/"average" units only there --
    # a numeric `unit` aborts, so naming it then would point at another abort.
    if (isTRUE(balanced)) {
      return(c(
        i = "Three interval methods return a result for this design where the \\
             default cannot: {.code ci_method = \"searle\"} (best calibrated when \\
             the data are close to normal, and narrowest), {.code \"burch\"} (never \\
             under-covers, at the cost of a wider interval), and \\
             {.code \"npbootstrap\"} (assumes no particular distribution)."
      ))
    }
    if (any(vapply(unit, is.numeric, logical(1)))) {
      return(character(0))
    }
    return(c(
      i = "{.code ci_method = \"npbootstrap\"} is available for unbalanced one-way \\
           data, with {.code unit = \"single\"} or {.code \"average\"}."
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
