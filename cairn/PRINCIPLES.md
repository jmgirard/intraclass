# Invariant principles (the constitution)

> These are load-bearing and reproduced **verbatim** from the founding brief
> (`CLAUDE_CODE_KICKOFF.md`, §2). **Change-controlled:** altering any principle
> requires the maintainer's explicit approval and a dated entry in
> [`DECISIONS.md`](DECISIONS.md).

## Statistical correctness

1. **Oracle-first verification.** No estimator is considered correct because a
   formula "looks right" or a model reasoned about it. Correctness is
   *established* by numerical agreement with independent oracles: (a) closed-form
   / textbook values (e.g., Brennan 2001, Shrout & Fleiss 1979 worked examples),
   (b) at least one established package on the balanced case it supports
   (`psych::ICC`, `gtheory`), and (c) simulation with known population variance
   components. Every exported estimator must pass ≥2 independent oracle types.
2. **Name the estimand.** Every ICC function documents precisely what population
   quantity it estimates (which variance components in numerator/denominator,
   single vs. average, agreement vs. consistency, fixed vs. random raters)
   *before* any code is written.
3. **Interval estimation is engine-agnostic and boundary-aware.** Default to
   Monte-Carlo CIs simulated from the parameter covariance matrix (the ICC is a
   non-normal ratio; the delta method is unreliable near the zero-rater-variance
   boundary, which is the common case). Report the method used. Never present a
   point estimate without an interval unless explicitly asked.
4. **No fabricated reference values, ever.** Oracle values in tests must come from
   a cited source or a reproducible script committed to the repo (with seed). If a
   value cannot be sourced or reproduced, the test is not written and the
   estimator is not shipped.
5. **Fail loudly on ill-posed designs.** If a requested ICC is not identified by
   the supplied design (e.g., a variance component that cannot be separated),
   error with a classed, explanatory condition — do not silently return a
   plausible-looking number.

## Software design

6. **Stable, small public API.** Exported surface is deliberate and documented.
   Internal helpers are not exported. Breaking changes require a `DECISIONS.md`
   entry.
7. **Tidy S3 generics.** Provide `print`, `summary`, and `format` methods;
   `tidy`/`glance`/`augment` (via the `generics` package) and an `autoplot` where
   sensible. Fitted-object classes are explicit and documented.
8. **All user-facing messaging via `cli`.** Progress, warnings, and informative
   notes use `cli`. All errors use `rlang::abort()` with a classed condition and
   an actionable message. No bare `stop()`/`warning()`/`cat()`/`print()` for user
   communication.
9. **Pure functions, explicit state.** No reliance on global options for
   correctness; no writing to the user's filesystem or `.GlobalEnv` as a side
   effect.

## Testing

10. **testthat 3e, everything exported is tested.** Oracle tests (principle 1),
    edge/boundary tests, error-path tests, and snapshot tests for printed output
    and error messages. No `skip()` without a documented, time-bound reason.
11. **Coverage is a floor, not a goal.** Target ≥90% but treat oracle coverage of
    statistical paths as the real bar. CI fails on coverage regression.

## Reproducibility & provenance

12. **Seeded and sourced.** Any stochastic code (simulation, MC CIs) is seeded in
    tests. Every statistical method in the code and docs cites its source (paper +
    equation where possible) in a comment and in `REFERENCES.md`.

## Documentation-as-teaching

13. **Explain the "why."** Every exported statistical function's docs include a
    short "Which ICC is this, and when should you use it?" note and the key
    tradeoff. Vignettes actively guide decisions rather than just demonstrating
    syntax.

## Process

14. **Plan before code; respect milestone gates.** No implementation without an
    approved plan for the current milestone. No starting milestone N+1 before N
    meets its Definition of Done (§8).
15. **Thin vertical slices.** Prefer one estimator working end-to-end (fit →
    estimate → CI → print/tidy → tested → documented → CI green) over broad
    half-built scaffolding.
16. **Tracking files are always current.** After each completed unit of work,
    update the tracking files atomically in the same commit. The tracking system
    is the single source of truth for project state.
17. **No scope creep.** New ideas go to `ROADMAP.md` as proposals, not into the
    current milestone.

## Agent conduct

18. **Escalate uncertainty, don't paper over it.** On any statistical doubt,
    invoke the verification procedure (§5) and the routing policy (§6). State
    assumptions explicitly. It is always acceptable to stop and ask the
    maintainer.
19. **Fable is never invoked automatically.** No subagent, skill, hook, or
    auto-delegation may route work to Fable (or any Mythos-tier model). Fable is
    used only after the maintainer explicitly approves it for a specific, named
    task, because it incurs additional token cost. Agents may *recommend* a Fable
    review and must then wait; they may not perform it. Default all automated
    verification to Opus.
