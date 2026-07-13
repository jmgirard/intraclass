# Invariant principles (the constitution)

> Reproduced from the founding brief (`CLAUDE_CODE_KICKOFF.md`, §2) and
> formalized into cairn's strength taxonomy on 2026-07-12 (`/design-interview`;
> D-001): each principle carries **[IP]** (inviolable — never violated in
> implementation; changing one requires an explicit user decision recorded in
> `DECISIONS.md`) or **[GP]** (guiding — a default stance tradeable with stated
> justification). Text is verbatim from the brief except where a dated D-entry
> records an amendment (#11, D-002) or retirement (#14–#17, D-003).
> **Change-controlled:** altering any principle requires the maintainer's
> explicit approval and a dated entry in [`DECISIONS.md`](DECISIONS.md).
> Interview-derived principles (IP1…, GP1…) live in
> [`DESIGN.md`](DESIGN.md) § Design Principles; this file remains the
> authoritative home for `#1`–`#19`, cited as `PRINCIPLES.md #N` in code.

## Statistical correctness

1. **[IP] Oracle-first verification.** No estimator is considered correct because a
   formula "looks right" or a model reasoned about it. Correctness is
   *established* by numerical agreement with independent oracles: (a) closed-form
   / textbook values (e.g., Brennan 2001, Shrout & Fleiss 1979 worked examples),
   (b) at least one established package on the balanced case it supports
   (`psych::ICC`, `gtheory`), and (c) simulation with known population variance
   components. Every exported estimator must pass ≥2 independent oracle types.
2. **[IP] Name the estimand.** Every ICC function documents precisely what population
   quantity it estimates (which variance components in numerator/denominator,
   single vs. average, agreement vs. consistency, fixed vs. random raters)
   *before* any code is written.
3. **[IP] Interval estimation is engine-agnostic and boundary-aware.** Default to
   Monte-Carlo CIs simulated from the parameter covariance matrix (the ICC is a
   non-normal ratio; the delta method is unreliable near the zero-rater-variance
   boundary, which is the common case). Report the method used. Never present a
   point estimate without an interval unless explicitly asked.
   *Fence (D-001):* the inviolable core is "always an interval, boundary-aware,
   method reported." The *default* interval method (Monte-Carlo from the
   parameter covariance) is a tradeable implementation choice — superseding it
   takes a D-entry, not a constitutional amendment.
4. **[IP] No fabricated reference values, ever.** Oracle values in tests must come from
   a cited source or a reproducible script committed to the repo (with seed). If a
   value cannot be sourced or reproduced, the test is not written and the
   estimator is not shipped.
5. **[IP] Fail loudly on ill-posed designs.** If a requested ICC is not identified by
   the supplied design (e.g., a variance component that cannot be separated),
   error with a classed, explanatory condition — do not silently return a
   plausible-looking number.

## Software design

6. **[GP] Stable, small public API.** Exported surface is deliberate and documented.
   Internal helpers are not exported. Breaking changes require a `DECISIONS.md`
   entry.
7. **[GP] Tidy S3 generics.** Provide `print`, `summary`, and `format` methods;
   `tidy`/`glance`/`augment` (via the `generics` package) and an `autoplot` where
   sensible. Fitted-object classes are explicit and documented.
8. **[GP] All user-facing messaging via `cli`.** Progress, warnings, and informative
   notes use `cli`. All errors use `rlang::abort()` with a classed condition and
   an actionable message. No bare `stop()`/`warning()`/`cat()`/`print()` for user
   communication.
   *Essence note (D-001):* the principle is *classed, actionable conditions*;
   `cli`/`rlang` is the current idiom, not the commitment.
9. **[GP] Pure functions, explicit state.** No reliance on global options for
   correctness; no writing to the user's filesystem or `.GlobalEnv` as a side
   effect.

## Testing

10. **[GP] testthat 3e, everything exported is tested.** Oracle tests (principle 1),
    edge/boundary tests, error-path tests, and snapshot tests for printed output
    and error messages. No `skip()` without a documented, time-bound reason.
11. **[GP] Coverage is a diagnostic, never a gate.** *(Amended 2026-07-12, D-002;
    the original targeted ≥90% with CI failing on coverage regression.)*
    Oracle coverage of statistical paths is the real bar. `covr` is a
    diagnostic: no numeric coverage target, and CI enforces no threshold.
    Untested defensive abort branches are an accepted cost.

## Reproducibility & provenance

12. **[IP] Seeded and sourced.** Any stochastic code (simulation, MC CIs) is seeded in
    tests. Every statistical method in the code and docs cites its source (paper +
    equation where possible) in a comment and in `REFERENCES.md`.

## Documentation-as-teaching

13. **[GP] Explain the "why."** Every exported statistical function's docs include a
    short "Which ICC is this, and when should you use it?" note and the key
    tradeoff. Vignettes actively guide decisions rather than just demonstrating
    syntax.

## Process

14.–17. **Retired (2026-07-12, D-003).** Plan-before-code (#14), thin vertical
slices (#15), tracking currency (#16), and scope discipline (#17) are absorbed
into the cairn tracking rulebook (the plugin's `tracking-rules.md` plus the
`cairn/` files), which now owns and enforces process. The numbers stay retired
and are never reused. (Original text: `CLAUDE_CODE_KICKOFF.md` §2.)

## Agent conduct

18. **[GP] Escalate uncertainty, don't paper over it.** On any statistical doubt,
    invoke the verification procedure (§5) and the routing policy (§6). State
    assumptions explicitly. It is always acceptable to stop and ask the
    maintainer.
19. **[IP] Fable is never invoked automatically.** No subagent, skill, hook, or
    auto-delegation may route work to Fable (or any Mythos-tier model). Fable is
    used only after the maintainer explicitly approves it for a specific, named
    task, because it incurs additional token cost. Agents may *recommend* a Fable
    review and must then wait; they may not perform it. Default all automated
    verification to Opus.
