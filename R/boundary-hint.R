# Design-aware hint for the CI-stage boundary aborts (M93) --------------------
#
# When the Monte-Carlo default aborts near the sigma^2 -> 0 boundary
# (`intraclass_singular_fit`), the generic remedies -- refit, aggregate, inspect the
# model -- do not tell the user the one thing that would actually help: that an
# opt-in `ci_method` exists which returns an interval on data where the default
# cannot. Which method that is depends entirely on the design in hand, so a blanket
# "try mpl" would be wrong off the two-way random agreement cell.
#
# The hint answers that in TWO stages, and the split is the whole design.
#
#   ADMISSIBILITY -- would `icc()` accept this `ci_method` string on this DESIGN?
#     A pure function of the fence predicates `icc()` has already computed
#     (`R/icc.R`), mirroring those fences. This stage cannot be replaced by running
#     anything, because a reducer will happily compute on a design `icc()` refuses:
#     naming a method the dispatch then rejects with `intraclass_unsupported` would
#     be its own bug (AC4 pins the rows against the shipped fences).
#
#   USABILITY -- does that method return an interval a user can use on this DATA?
#     Settled by RUNNING it (`boundary_method_usable()` above), never predicted.
#
# The second stage used to be a growing pile of design predicates, and that is what
# five review passes killed one at a time: the kappa_m calibration grid, a raw
# subject count, an effective subject count, a missing score / numeric `unit` /
# MSA = 0, and a verdict reading one of two endpoints. Each patch closed the stated
# mechanism and shipped a new one, because a predicate can only encode failures
# somebody already thought of. Running the method has no such horizon, and it
# subsumes every one of those predicates: the kappa_m gate (the lookup aborts off
# grid), the degeneracy checks (the shipped guards abort), score completeness (the
# extractors abort on an NA), and the Spearman-Brown pole test (the interval comes
# back reversed or above +1, and is rejected on its values).
#
# The hint is ADDITIVE: the abort class, its leading message, and its existing
# generic remedies are untouched (AC2/AC5). Nothing here implements a
# fallback-on-abort default -- that is the distinct `#3`/ADR-003 contract change
# D-012 fenced out ("A classical fallback-on-abort default behaviour is a distinct,
# later `#3` question, not decided here"), and D-018 draws the line this code sits
# on: the interval computed to decide the naming is discarded, and the user still
# gets the abort and no interval.
#
# The wording. The deterministic methods' parentheticals are D-012's own one-line
# characterizations (SEARLE and Burch returned a finite interval on 100% of 32,000
# balanced one-way datasets where the MC default aborted on 4-44%). The
# `npbootstrap` bullet (M97) claims only what its run showed -- "run on your data
# ... returns an interval" -- because its second abort is a RESAMPLE-stage guard
# (the `n_bad` block in `R/ci-npbootstrap.R`) that is stochastic: a run is evidence
# about that SEED, not about the design (the same unbalanced 8x3 dataset verifies
# under five of eight probed seeds and trips the guard under the other three). So
# verification runs under the seed AND `boot_samples` the user's own
# retry would use -- their `seed` when set, else the fixed `npb_hint_seed`, which
# the bullet then names so the promised call is exactly the verified one. The run
# consumes randomness inside an abort path, so it is RNG-neutral by construction:
# `npbootstrap_ci()` always receives a concrete seed here and restores the ambient
# stream via `with_rng_seed()` (#9).

# --- Verification: run the candidate method, then look at the interval --------
#
# Five review passes each closed one mechanism by which a design PREDICATE named a
# method that then failed on the user's data, and each patch shipped a new one: the
# kappa_m calibration grid, a raw subject count, an effective subject count, a
# missing score / numeric `unit` / MSA = 0, and a verdict reading one of the two
# endpoints. Prediction was abandoned at the M93 third re-cut (2026-07-26) for
# something that cannot have a sixth mechanism -- run the candidate's OWN shipped
# reducer on the data in hand, and name it only if the interval it returns is usable.
# `icc()` reports these endpoints verbatim (no clamping anywhere in the reporting
# path, verified at the implement gate), so the check cannot disagree with what the
# user's own `ci_method =` call would produce (AC4).
#
# D-018 draws the line against the fallback-on-abort default D-012 fenced out: the
# interval computed here decides whether to NAME a method and is then discarded. It
# reaches neither the message text nor any returned object -- the call still aborts
# `intraclass_singular_fit` and still returns no interval.

# Is one reported interval usable? Finite, correctly ordered, and inside the
# estimand's support under D-010 -- `(-1/(n0-1), 1)` for ICC(1), `(-Inf, 1)` for the
# averaged/projected form -- both OPEN.
#
# Out-of-support is not hypothetical. `searle` at a numeric `unit` past `npb_sb()`'s
# pole (`rho = -1/(m-1)`) returns intervals lying entirely ABOVE +1: measured at the
# implement gate on 28 of 12,600 healthy cells, values 1.16 to 13.1, one of them an
# 80% interval of [1.154, 1.164] around a point of 5.9e-09 (the shipped defect itself
# is a ROADMAP candidate; M93 only stops the hint pointing at it). Pole-crossed values
# have infimum `m/(m-1) > 1`, so the `< 1` cut separates them from legitimate ones
# with no tolerance band to tune -- legitimate endpoints approach 1 only from below.
#
# The ICC(1) floor is the classical estimator's ATTAINED minimum (MSA = 0 gives
# exactly `-1/(n0-1)`), not an asymptote, so this does reject a limit sitting on it:
# a zero-width interval pinned at the support boundary. Deliberate -- the support is
# open there, it never bound on healthy data (0 of 12,600 cells), and the default
# two-estimand call is silenced on that data anyway by ICC(k) coming back `-Inf`.
boundary_interval_usable <- function(ci, divisor, n0) {
  lo <- ci$conf.low
  hi <- ci$conf.high
  if (length(lo) != 1L || length(hi) != 1L) {
    return(FALSE)
  }
  if (!is.finite(lo) || !is.finite(hi) || lo > hi || hi >= 1) {
    return(FALSE)
  }
  floor_rho <- if (isTRUE(divisor == 1) && is.finite(n0) && n0 > 1) {
    -1 / (n0 - 1)
  } else {
    -Inf
  }
  lo > floor_rho
}

# The seed the `npbootstrap` verification runs under when the caller set none
# (M97 T3/AC3). A bootstrap run is evidence about ONE seed's resamples, not all of
# them, so the bullet NAMES this seed: the call it promises is exactly the verified
# run, never a fresh draw that can fail on a small design.
npb_hint_seed <- 1L

# Run one candidate `ci_method` and report whether EVERY estimand it returns is
# usable. This NEVER raises and never leaks a condition. The reducers abort by design
# (`intraclass_unidentified` on a missing score, `intraclass_unsupported` off mpl's
# kappa_m grid or at an uncalibrated level, the classical guards on degenerate data,
# `npbootstrap`'s resample-stage guard on a degenerate resample) and can warn; it
# runs while the boundary abort's own message vector is being built,
# where an escaping error would REPLACE the user's `intraclass_singular_fit` with an
# unrelated one (pass-4 F2, scored 95) and an escaping warning would attach itself to
# their abort. Any failure means "this method cannot serve this data", which is
# exactly the answer the check exists to give.
#
# Keyed by the `ci_method` string: M97 registered `npbootstrap` by adding a row here
# rather than by writing a second checker (M97 AC1). Its row runs the shipped reducer
# at the CALLER's own `boot_samples` -- the count their retry would use, never a
# reduced one, which would lower the chance of tripping a guard that fires on any
# degenerate resample (M93 pass-3 F3; the M97 review measured a run that succeeded
# at 999 aborting at a caller's 2000, so a hardcoded default here would hint a
# retry that fails) -- and under the caller's own `seed` when set, else under
# `npb_hint_seed` (the seed the bullet then names, so the verified run is the
# promised one).
boundary_method_usable <- function(
  method,
  df,
  estimands,
  conf_level,
  n0,
  seed = NULL,
  boot_samples = 999L
) {
  run <- switch(
    method,
    searle = function() searle_ci(df, estimands, conf_level = conf_level),
    burch = function() burch_ci(df, estimands, conf_level = conf_level),
    mpl = function() mpl_ci(df, estimands, conf_level = conf_level),
    npbootstrap = function() {
      npbootstrap_ci(
        df,
        estimands,
        conf_level = conf_level,
        boot_samples = boot_samples,
        seed = if (is.null(seed)) npb_hint_seed else seed
      )
    },
    NULL
  )
  if (is.null(run)) {
    return(FALSE)
  }
  isTRUE(tryCatch(
    withCallingHandlers(
      {
        ci <- run()
        length(ci) >= 1L &&
          all(vapply(
            seq_along(ci),
            function(i) {
              boundary_interval_usable(ci[[i]], estimands[[i]]$divisor, n0)
            },
            logical(1)
          ))
      },
      warning = function(w) invokeRestart("muffleWarning"),
      message = function(m) invokeRestart("muffleMessage")
    ),
    error = function(e) FALSE
  ))
}

# Build the design-aware `i =` bullets for a boundary abort. Returns a named
# character vector (every name "i", ready to splice into a cli message vector), or
# character(0) when no opt-in method serves this design AND data -- in which case the
# abort keeps its generic remedies alone (AC4).
#
# `df`, `estimands` and `conf_level` are what the USABILITY stage runs on: exactly
# the arguments `icc()` would hand the reducer it dispatches to, so the interval
# inspected here is the one the user's own `ci_method =` call would return. Running
# them is free on the success path -- the whole `hint` argument is a promise, forced
# only inside an abort message -- and each candidate is verified inside the branch
# that would name it, never above the design split.
#
# `n0` is the effective group size the ICC(1) support floor `-1/(n0-1)` is defined
# against (D-010). It is a SUPPORT CONSTANT, not a failure predictor: it says where
# the parameter space ends, not whether a method will work, which is why it survived
# the deletion of every predictive input.
boundary_method_hint <- function(
  oneway,
  multilevel,
  replicates,
  raters,
  balanced,
  type,
  type_supplied,
  unit,
  conf_level,
  df,
  estimands,
  n0,
  seed = NULL,
  boot_samples = 999L
) {
  usable <- function(method) {
    boundary_method_usable(
      method,
      df,
      estimands,
      conf_level,
      n0,
      seed = seed,
      boot_samples = boot_samples
    )
  }

  # A cluster facet or within-cell replicates put the design outside EVERY opt-in
  # method's fence, whatever else is true, so neither branch below can apply.
  if (isTRUE(multilevel) || isTRUE(replicates)) {
    return(character(0))
  }

  if (isTRUE(oneway)) {
    # UNBALANCED: `npbootstrap` is the only method shipping this cell (D-013),
    # named -- like every other row -- only after RUNNING it on the data in hand
    # (M97). ADMISSIBILITY first, mirroring `icc()`'s own fence: a numeric `unit`
    # (D-study projection) is refused at dispatch on the unbalanced path (its
    # Spearman-Brown pole is not pole-safe there, R/icc.R), so no verification
    # could license naming the string. The mirror is the fence's own expression.
    if (!isTRUE(balanced)) {
      if (any(vapply(unit, is.numeric, logical(1)))) {
        return(character(0))
      }
      if (!usable("npbootstrap")) {
        return(character(0))
      }
      # A bootstrap run is evidence about ONE seed's resamples, not all of them
      # (M97 AC3: the same unbalanced 8x3 dataset, under the production estimands,
      # verifies under five of eight probed seeds and trips the resample guard
      # under the other three). Under the caller's own `seed` the promise is exact -- their retry
      # re-runs the verified draws, so the bullet stays seed-free. With no caller
      # seed the run used the fixed `npb_hint_seed`, and the bullet NAMES it: the
      # promised call is exactly the verified one, never a fresh ambient draw that
      # can fail on a small design. That literal is the one deliberate digit in
      # any bullet; the AC5 leak guard enumerates it (a producer-chosen INPUT,
      # never a value the run returned -- those are discarded, D-018).
      if (is.null(seed)) {
        return(c(
          i = paste0(
            "{.code ci_method = \"npbootstrap\"}, run on your data with \\
             {.code seed = ",
            npb_hint_seed,
            "}, returns an interval where the default cannot: the transformed \\
             bootstrap-t resamples subjects rather than simulating from the \\
             fitted model. Pass {.code seed = ",
            npb_hint_seed,
            "} to reproduce that verified run; an unseeded call resamples \\
             differently and can fail on a small design."
          )
        ))
      }
      return(c(
        i = "{.code ci_method = \"npbootstrap\"}, run on your data under your \\
             {.code seed}, returns an interval where the default cannot: the \\
             transformed bootstrap-t resamples subjects rather than simulating \\
             from the fitted model."
      ))
    }
    # ...and each admissible method is named only if it actually delivers on this
    # data. The pair splits naturally, because each is asked separately: at a numeric
    # `unit` past its own Spearman-Brown pole `searle` drops out while `burch` stays.
    named <- Filter(usable, c("searle", "burch"))
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
      "Two interval methods, run on your data, return an interval where the \\
       default cannot: "
    } else {
      "An interval method, run on your data, returns an interval where the \\
       default cannot: "
    }
    return(c(
      i = paste0(lead, paste(blurb[named], collapse = " and "), ".")
    ))
  }

  # `mpl` is the two-way RANDOM absolute-agreement cell only (D-014/D-015). An
  # EXPLICIT consistency request is a genuine conflict icc() aborts on; an unset
  # `type` still resolves, because icc() narrows the default to agreement when mpl is
  # selected. The user reaching this abort is on the DEFAULT ci_method, so `type` has
  # not been narrowed yet and `type_supplied` is what distinguishes the two cases.
  # The kappa_m grid and the calibrated `conf_level` set are NOT checked here any
  # more: `mpl_kappa_lookup()` aborts on both, so running the method settles them
  # from one source of truth (pass-1 F1 was a copy of that grid drifting).
  if (!identical(raters, "random") || !isTRUE(balanced)) {
    return(character(0))
  }
  if (isTRUE(type_supplied) && "consistency" %in% type) {
    return(character(0))
  }
  if (!usable("mpl")) {
    return(character(0))
  }
  c(
    i = "{.code ci_method = \"mpl\"}, run on your data, returns an interval where \\
         the default cannot: the modified profile-likelihood interval was just \\
         verified on this dataset at this boundary, at the cost of being \\
         conservative."
  )
}
