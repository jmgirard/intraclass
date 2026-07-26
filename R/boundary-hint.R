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

# The subject count below which the unbalanced one-way hint stays silent about
# `npbootstrap`. Its resample guard (`R/ci-npbootstrap.R:178-191`) says of itself only
# that degenerate resamples are "negligibly rare at k >= 10"; measured at the M93
# pass-3 gate, k = 10 is not enough (12 of 17 hinted balanced 2-rater designs then
# aborted), and every cell at 15+ was clean. An empirical floor, not a theoretical one.
npb_hint_min_subjects <- 15L

# Exact ANOVA degeneracy: TRUE when the DATA (not the design) are degenerate enough
# that every method a row below could name aborts on them. The design predicates alone
# cannot see this -- a balanced one-way design whose scores are constant within subject
# is a perfectly ordinary design carrying data on which searle, burch and npbootstrap
# all abort, and the M93 hint named all three (review F2).
#
# One-way: this restates the shipped guards' OBSERVED-data conditions, evaluated off the
# same `npb_anova()` summary they use -- MSE = 0 (`classical_guard_observed()`, for
# searle/burch), and a non-finite log F or a zero jackknife SE (`npbootstrap_ci()`'s two
# disjuncts, `R/ci-npbootstrap.R:144`). The `se_ij_logf == 0` disjunct is independent of
# the other two and was missed at first (M93 pass-2 review, F2): any k = 2 one-way design
# with equal within-subject sums of squares hits it exactly while log F stays finite.
# It restates rather than calls, so it is a copy that can drift -- it deliberately does
# NOT cover npbootstrap's second, RESAMPLE-stage guard, which is stochastic and not a
# property of the observed data at all; that one is handled by the subject-count floor
# above. Exact zero, matching the guards' own convention -- a small-but-positive F is the
# near-zero ICC these methods exist to serve, not a degeneracy.
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
    return(
      isTRUE(a$mse == 0) ||
        !is.finite(a$logf) ||
        isTRUE(a$se_ij_logf == 0)
    )
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
    # BALANCED: name the two DETERMINISTIC closed forms only. D-012's 0-abort evidence
    # -- a finite interval on 100% of 32,000 datasets where the MC default aborted on
    # 4-44% -- is stated for SEARLE and Burch, and for them alone; it is not an
    # npbootstrap result, and the M93 hint originally borrowed it for all three.
    # npbootstrap is a BOOTSTRAP: `npbootstrap_ci()`'s own resample guard aborts when a
    # resample comes out degenerate, which below ~15 subjects is not rare but routine
    # (measured at the M93 pass-3 gate: 16/16 hinted-then-aborting at 5 subjects x 2
    # raters, 12/17 at 10, 5/18 at 12, 0/14 at 15+). searle/burch aborted 0 times in
    # every one of those cells, and Burch already carries the non-normal case D-012
    # would otherwise want npbootstrap for, so dropping it here costs nothing.
    if (isTRUE(balanced)) {
      return(c(
        i = "Two interval methods return a result for this design where the \\
             default cannot: {.code ci_method = \"searle\"} (best calibrated when \\
             the data are close to normal, and narrowest) and {.code \"burch\"} \\
             (never under-covers, at the cost of a wider interval)."
      ))
    }
    # UNBALANCED: only npbootstrap ships this cell (M84/M85), so it is name-it-or-stay-
    # silent. It takes "single"/"average" units only here -- a numeric `unit` aborts.
    if (any(vapply(unit, is.numeric, logical(1)))) {
      return(character(0))
    }
    # ...and it is named only above the subject count where its resample guard goes
    # quiet (0 aborts at 12+ unbalanced, 0 at 15+ balanced; 13/13 at 5, 7/13 at 8,
    # 1/11 at 10). The floor is empirical and the guard is stochastic, so this makes
    # naming npbootstrap rare-to-fail rather than certain -- which is why the wording
    # below claims AVAILABILITY and never D-012's "where the default cannot".
    if (!isTRUE(n_s >= npb_hint_min_subjects)) {
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
