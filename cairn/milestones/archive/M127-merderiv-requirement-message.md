# M127: Correct the lme4 merDeriv requirement message

**Status:** done (2026-08-18, PR #136 https://github.com/jmgirard/intraclass/pull/136)

**Goal:** the merDeriv `check_installed()` reason said "to compute lme4 Monte-Carlo confidence
intervals", but the check fires at every `fit_lme4*()` entry before any interval-method
branching, so a `ci_method = "bootstrap"` caller was told it belonged to a method they never requested.

**Outcome:** `merderiv_reason()` in `R/engine-lme4.R` is the single source for all 12
dispatched `fit_lme4*()` sites, no literals left: "to supply the lme4 parameter
covariance; every lme4 fit checks for it on entry, whatever interval method you ask
for." `test-icc-lme4-engine.R` renders it through the real `rlang::check_installed()`
path against an absent probe package name, asserting by substring at several
`cli.width` settings. The withdrawn wording is pinned as `merderiv_method_specific` in
`test-doc-skew-caveat.R` (quote delimiters and full stop included), and `|merderiv` joined
the `spellings` alternation in `data-raw/m123-capability-claim-mutations.R` so the harness
plants it: 11 RED cells, control green. Two engine comments still framing the requirement as
Monte-Carlo-specific were corrected; `:50` now defines "entry point" mechanically.

**Decisions:** none cross-cutting. Milestone-local: the `spellings` widening is one
token, not a general identifier regex — that would red the two-way check.

**Review:** two three-lens fan-outs, 16 findings — one amendment return (AC3's
`.R`-sources-only clause, disproven by its own evidence), 11 fixed on the branch, 1
informational, 3 drifted citations left recorded at the maintainer's selection.
