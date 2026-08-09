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
# grid), the degeneracy checks (the shipped guards abort), and the Spearman-Brown
# pole test (the interval comes back reversed or above +1, and is rejected on its
# values). Score completeness was on this list until M105, which removed it as a
# mechanism rather than subsuming it: `icc()` now drops `NA`-scored rows during
# canonicalization, so no reducer is handed one (D-022). The historical list above
# is unchanged -- it records which predicates were killed, not which are reachable.
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
# retry would use -- their `seed` when set, else the fixed `hint_verify_seed`, which
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

# The seed every STOCHASTIC verification runs under when the caller set none
# (M97 T3/AC3; extended from `npbootstrap` to the two engine-fit methods at M103).
# A resampling run is evidence about ONE seed's draws, not all of them, so the
# bullet NAMES this seed: the call it promises is exactly the verified run, never a
# fresh draw that can fail on a small design. It also makes the run RNG-neutral
# (#9) -- every stochastic reducer here restores the ambient stream when handed a
# concrete seed, and would consume it when handed `NULL`.
hint_verify_seed <- 1L

# The resample count the CHEAP NEGATIVE SCREEN runs at (M103 review, F11).
#
# Verification costs what the method costs, and `bootstrap` costs a refit per
# resample: 27 s at the shipped 999 on a 6x3 cell. That is spent inside an abort
# message, and it is spent whether or not the method turns out to help -- which
# made a previously instant `searle` abort take 25.6 s to print a message with no
# bullet in it at all. The classical guard is the worst cell by construction:
# `searle_ci()` and `burch_ci()` share the MSE = 0 / non-finite-F guard on the same
# `ss`, so on that trigger whenever one aborts the other does, and the cheap tier
# there is empty by construction rather than by data. Since M105 the two no longer
# abort together on EVERY trigger: Burch has its own MSA = 0 guard where SEARLE
# returns its attained minimum (D-022), so on that trigger the cheap tier is empty
# by data rather than by construction.
#
# So the expensive candidate is screened first at this count, and abandoned if the
# screen fails. Measured on 6x3 cells: a hopeless dataset (`gen_mse0`) is rejected
# in 0.69 s instead of 27.20 s, and a dataset where `bootstrap` works (`gen_ssa0`)
# passes the screen in 0.45 s and then pays the full 18.02 s.
#
# The screen can only ever cause SILENCE, never a name: nothing it accepts is
# named until the full run at the caller's own count has also succeeded. So it
# cannot make a bullet less true -- the promise M97 settled, that the verified run
# is the promised one, is untouched. What it can do is stay quiet where a full run
# would have succeeded and the screen's smaller one did not, which is the
# conservative direction and the one an abort path should fail in.
hint_screen_samples <- 25L

# The resample count the FULL verification of `bootstrap` is capped at.
#
# The screen above bounds the case where nothing works. This bounds the case
# where something does: a candidate that passes the screen still has to be run in
# full before it may be named, and at the shipped 999 that is ~18 s inside an
# abort message -- on the DEFAULT path, the most common call in the package.
#
# So the full run is capped here, and the bullet NAMES the count it verified at.
# That keeps M97's rule rather than bending it: the rule is that the promised
# call is the verified one, and a bullet reading
# `ci_method = "bootstrap", seed = 1, boot_samples = 199` promises exactly the
# run that was made. What changes is which call is recommended, not whether the
# recommendation was earned -- and 199 resamples is a serviceable percentile
# bootstrap in its own right, which is why the cap sits here rather than at the
# screen's 25.
hint_verify_boot_cap <- 199L

# The count `bootstrap` is actually verified at for a caller who passed
# `boot_samples`: their own value, or the cap, whichever is smaller. A caller
# already below the cap is verified at their own count and the bullet names it.
hint_verify_boot_samples <- function(boot_samples) {
  min(as.integer(boot_samples), hint_verify_boot_cap)
}

# Run one candidate `ci_method` and report whether EVERY estimand it returns is
# usable. This NEVER raises and never leaks a condition. The reducers abort by design
# (`intraclass_unsupported` off mpl's kappa_m grid or at an uncalibrated level,
# the classical guards on degenerate data,
# `npbootstrap`'s resample-stage guard on a degenerate resample) and can warn; it
# runs while the boundary abort's own message vector is being built,
# where an escaping error would REPLACE the user's `intraclass_singular_fit` with an
# unrelated one (pass-4 F2, scored 95) and an escaping warning would attach itself to
# their abort. Any failure means "this method cannot serve this data", which is
# exactly the answer the check exists to give.
#
# Keyed by the `ci_method` string: M97 registered `npbootstrap` by adding a row here
# rather than by writing a second checker (M97 AC1), and M103 registered the two
# ENGINE-FIT methods the same way. Those two differ from every other row in what
# they run on: `bootstrap` and `montecarlo` reduce a fitted model, not raw data, so
# their rows take `engine` and are unavailable (FALSE, never named) when the caller
# had no fit to hand down. Both are stochastic, so both take a concrete seed for
# the same reasons the `npbootstrap` row does.
#
# Every stochastic row runs under the caller's own `seed` when set, else under
# `hint_verify_seed` (the seed the bullet then names, so the verified run is the
# promised one).
#
# The RESAMPLE COUNT differs between them, and the difference is deliberate. The
# `npbootstrap` row runs at the CALLER's own `boot_samples` -- the count their
# retry would use, never a reduced one, which would lower the chance of tripping a
# guard that fires on any degenerate resample (M93 pass-3 F3; the M97 review
# measured a run that succeeded at 999 aborting at a caller's 2000, so a hardcoded
# default here would hint a retry that fails). The `bootstrap` row cannot afford
# that: a refit per resample is what made an abort take 25.6 s, so it screens and
# then caps at `hint_verify_boot_cap`. The promise is kept the other way round
# there -- the bullet names the capped count, so the call it promises is still the
# call that ran (M103 review pass 2, G6).
boundary_method_usable <- function(
  method,
  df,
  estimands,
  conf_level,
  n0,
  seed = NULL,
  boot_samples = 999L,
  engine = NULL,
  mc_samples = 10000L
) {
  # Every reducer is called WITHOUT a `hint`. A candidate verified with a hint of
  # its own would build that hint's candidates while building this one's, and the
  # classical pair share a guard, so `searle` verifying `burch` verifying `searle`
  # is a real cycle rather than a hypothetical one (M103 AC4). No hint here, no
  # cycle: a candidate's own abort is caught below and reported as unusable.
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
        seed = if (is.null(seed)) hint_verify_seed else seed
      )
    },
    bootstrap = if (is.null(engine)) {
      NULL
    } else {
      function() {
        bootstrap_ci(
          engine,
          estimands,
          conf_level = conf_level,
          # Capped, and the bullet names what this resolves to -- see
          # `hint_verify_boot_cap`.
          boot_samples = hint_verify_boot_samples(boot_samples),
          seed = if (is.null(seed)) hint_verify_seed else seed
        )
      }
    },
    montecarlo = if (is.null(engine)) {
      NULL
    } else {
      function() {
        mc_ci(
          engine,
          estimands,
          conf_level = conf_level,
          mc_samples = mc_samples,
          seed = if (is.null(seed)) hint_verify_seed else seed
        )
      }
    },
    NULL
  )
  if (is.null(run)) {
    return(FALSE)
  }
  # Screen the expensive candidate before paying for it (see
  # `hint_screen_samples`). The recursion terminates immediately: the inner call
  # runs at `hint_screen_samples`, which fails this same condition.
  if (
    identical(method, "bootstrap") && isTRUE(boot_samples > hint_screen_samples)
  ) {
    screened <- boundary_method_usable(
      method,
      df,
      estimands,
      conf_level,
      n0,
      seed = seed,
      boot_samples = hint_screen_samples,
      engine = engine,
      mc_samples = mc_samples
    )
    if (!screened) {
      return(FALSE)
    }
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
#
# TWO TIERS (M103), tried in order, the first that names anything winning:
#
#   1. The DESIGN-FENCED opt-in methods -- `searle`, `burch`, `npbootstrap`, `mpl`.
#      Each is admissible only on the design its own fence allows, which is what
#      the branching below mirrors.
#   2. The ENGINE-FIT methods -- `bootstrap`, `montecarlo`. No design fence: they
#      reduce whatever model was fitted, so the only precondition is having that
#      fit (`engine`). They are tried SECOND because they are the expensive ones --
#      a 999-refit parametric bootstrap inside an abort message costs ~17 s where
#      the deterministic classical pair costs ~5 ms -- and because on the data
#      where a fenced method works they add nothing. Where none of tier 1 works
#      they are the whole point: on zero-between-variance data (`gen_ssa0`)
#      `bootstrap` is the only shipped method that returns a usable interval at
#      all, 4 of 4 datasets in `tests/testthat/fixtures/abort-remedy-sweep.tsv`.
#
# `invoked` is the `ci_method` the CALLER asked for, and it does two things. It is
# excluded from both tiers -- a guard that just aborted may not recommend itself,
# and for the classical pair, which share the MSE = 0 / non-finite-F guard,
# running it again would re-enter that guard (caught, not recursive). Since M105
# Burch also has an MSA = 0 guard of its own that SEARLE does not share (D-022) --
# do not fold the two together, which is what that entry decided against. And it selects the contrast clause: M93's
# bullets were written for the Monte-Carlo default and say the named method works
# "where the default cannot", which is a claim about `montecarlo` that is verified
# only when `montecarlo` is what aborted. Off the default path the clause names no
# method and claims only what the abort itself proves -- the requested method
# failed here.
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
  boot_samples = 999L,
  invoked = "montecarlo",
  engine = NULL,
  mc_samples = 10000L
) {
  # Self-exclusion is tested BEFORE the run, so a guard never pays to verify the
  # method that just aborted in it (M103 AC3).
  usable <- function(method) {
    !identical(method, invoked) &&
      boundary_method_usable(
        method,
        df,
        estimands,
        conf_level,
        n0,
        seed = seed,
        boot_samples = boot_samples,
        engine = engine,
        mc_samples = mc_samples
      )
  }
  contrast <- if (identical(invoked, "montecarlo")) {
    "the default"
  } else {
    "the method you requested"
  }

  tier1 <- boundary_fenced_hint(
    usable = usable,
    contrast = contrast,
    oneway = oneway,
    multilevel = multilevel,
    replicates = replicates,
    raters = raters,
    balanced = balanced,
    type = type,
    type_supplied = type_supplied,
    unit = unit,
    seed = seed
  )
  if (length(tier1)) {
    return(tier1)
  }
  boundary_engine_hint(
    usable = usable,
    contrast = contrast,
    seed = seed,
    boot_samples = boot_samples
  )
}

# TIER 1 -- the design-fenced opt-in methods. `usable()` carries the run, the
# self-exclusion and the engine handle; `contrast` carries the clause naming what
# the recommended method beats. Returns `character(0)` when the design admits none
# of them, or when none that it admits works on this data.
boundary_fenced_hint <- function(
  usable,
  contrast,
  oneway,
  multilevel,
  replicates,
  raters,
  balanced,
  type,
  type_supplied,
  unit,
  seed = NULL
) {
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
      # seed the run used the fixed `hint_verify_seed`, and the bullet NAMES it: the
      # promised call is exactly the verified one, never a fresh ambient draw that
      # can fail on a small design. That literal is the one deliberate digit in
      # any bullet; the AC5 leak guard enumerates it (a producer-chosen INPUT,
      # never a value the run returned -- those are discarded, D-018).
      if (is.null(seed)) {
        return(c(
          i = paste0(
            "{.code ci_method = \"npbootstrap\"}, run on your data with \\
             {.code seed = ",
            hint_verify_seed,
            "}, returns an interval where ",
            contrast,
            " cannot: the transformed \\
             bootstrap-t resamples subjects rather than simulating from the \\
             fitted model. Pass {.code seed = ",
            hint_verify_seed,
            "} to reproduce that verified run; an unseeded call resamples \\
             differently and can fail on a small design."
          )
        ))
      }
      return(c(
        i = paste0(
          "{.code ci_method = \"npbootstrap\"}, run on your data under your \\
           {.code seed}, returns an interval where ",
          contrast,
          " cannot: the transformed bootstrap-t resamples subjects rather than \\
           simulating from the fitted model."
        )
      ))
    }
    # ...and each admissible method is named only if it actually delivers on this
    # data. The pair splits naturally, because each is asked separately: at a numeric
    # `unit` past its own Spearman-Brown pole `searle` drops out while `burch` stays.
    named <- Filter(usable, c("searle", "burch"))
    if (!length(named)) {
      return(character(0))
    }
    # Neither blurb claims to be the tighter interval: the shipped "narrowest"
    # / "wider" pair was false on both measured grids and is withdrawn (M116).
    # Nor could a blurb state the relationship honestly in a clause -- it is
    # conditional on the true ICC and on the subject count, and near a true ICC
    # of 0.6 the two are within a fraction of a percent of each other (M117).
    # This is where a user picks a method, so a width ranking here is the one
    # that would actually mislead; the conditional statement lives in `?icc`.
    blurb <- c(
      searle = "{.code ci_method = \"searle\"} (best calibrated when the data \\
                are close to normal)",
      burch = "{.code ci_method = \"burch\"} (dips below the nominal level in \\
               fewer cells -- but measured to under-cover on heavy-tailed or \\
               skewed subject effects, as the default does)"
    )
    lead <- if (length(named) > 1L) {
      paste0(
        "Two interval methods, run on your data, return an interval where ",
        contrast,
        " cannot: "
      )
    } else {
      paste0(
        "An interval method, run on your data, returns an interval where ",
        contrast,
        " cannot: "
      )
    }
    return(c(
      i = paste0(lead, paste(blurb[named], collapse = " and "), ".")
    ))
  }

  # `mpl` is the two-way RANDOM absolute-agreement cell only (D-014/D-015). An
  # EXPLICIT consistency request is a genuine conflict icc() aborts on; an unset
  # `type` still resolves, because icc() narrows the default to agreement when mpl is
  # selected. The user reaching this abort asked for some OTHER ci_method (the
  # default, or -- since M103 -- `bootstrap`, whose guard fires on two-way designs
  # too), so `type` has not been narrowed by an mpl selection either way, and
  # `type_supplied` is what distinguishes the two cases.
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
    i = paste0(
      "{.code ci_method = \"mpl\"}, run on your data, returns an interval where ",
      contrast,
      " cannot: the modified profile-likelihood interval was just verified on \\
       this dataset at this boundary, at the cost of being conservative."
    )
  )
}

# TIER 2 -- the engine-fit methods, reached only when no design-fenced method
# serves this design and data. No design branching: `bootstrap` and `montecarlo`
# reduce the fitted model rather than the raw data, so the fence is having a fit,
# which `usable()` enforces (its rows return FALSE with no `engine`).
#
# Both are stochastic, so both carry the seed discipline the `npbootstrap` bullet
# established: under the caller's own `seed` their retry re-runs the verified
# draws and the bullet stays seed-free; with no caller seed the verification ran
# under `hint_verify_seed`, and the bullet names it so the promised call is the
# verified one.
boundary_engine_hint <- function(
  usable,
  contrast,
  seed = NULL,
  boot_samples = 999L
) {
  named <- Filter(usable, c("bootstrap", "montecarlo"))
  if (!length(named)) {
    return(character(0))
  }
  blurb <- c(
    bootstrap = "{.code ci_method = \"bootstrap\"} (refits the fitted model to \\
                 simulated responses, so it never leans on the parameter \\
                 covariance)",
    montecarlo = "{.code ci_method = \"montecarlo\"} (draws from the fitted \\
                  parameter covariance on the engine's log scale)"
  )
  lead <- if (length(named) > 1L) {
    paste0(
      "Two model-based interval methods, run on your data, return an interval \\
       where ",
      contrast,
      " cannot: "
    )
  } else {
    paste0(
      "A model-based interval method, run on your data, returns an interval \\
       where ",
      contrast,
      " cannot: "
    )
  }
  # `boot_samples` means DIFFERENT things to different methods -- subject
  # resamples to `npbootstrap`, model refits to `bootstrap` -- so a cross-method
  # recommendation may not leave it implicit (M103 review, F8). It is also the
  # count the verification was capped at, which is rarely the caller's own. Both
  # reasons point the same way: the `bootstrap` bullet always names the count it
  # was verified at, so the call it promises is the call that was run.
  #
  # With BOTH methods named there were two runs, not one, and the count belongs to
  # only one of them -- `montecarlo` takes no `boot_samples` at all. So the plural
  # form says so rather than leaving a reader to guess which run the number
  # describes (M103 review pass 2, G12).
  many <- length(named) > 1L
  spec <- if ("bootstrap" %in% named) {
    paste0(
      if (many) ", the bootstrap at " else " and ",
      "{.code boot_samples = ",
      hint_verify_boot_samples(boot_samples),
      "}"
    )
  } else {
    character(0)
  }
  tail <- if (is.null(seed)) {
    paste0(
      if (many) {
        ". Both runs used {.code seed = "
      } else {
        ". That run used {.code seed = "
      },
      hint_verify_seed,
      "}",
      spec,
      "; pass the same to reproduce ",
      if (many) "them" else "it",
      ", as an unseeded call draws differently and can fail on a small design."
    )
  } else {
    paste0(
      if (many) {
        ", both run under your {.code seed}"
      } else {
        ", run under your {.code seed}"
      },
      spec,
      "."
    )
  }
  c(i = paste0(lead, paste(blurb[named], collapse = " and "), tail))
}
