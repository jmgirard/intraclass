<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M127: Correct the lme4 merDeriv requirement message

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP8
- **Branch/PR:** `m127-merderiv-requirement-message`

## Goal

`rlang::check_installed("merDeriv", reason = "to compute lme4 Monte-Carlo
confidence intervals.")` fires at the entry of every `fit_lme4*()` before any
interval-method branching, so a user who asked for `ci_method = "bootstrap"` is
told the requirement belongs to a method they did not request; this milestone
replaces that framing with what merDeriv supplies and when the check runs.

## Scope

**Surface tier: user-facing** — the deliverable is a message `rlang` renders to
the user at the console.

**In:** the `reason` passed to `check_installed("merDeriv", …)` at every lme4
entry point in `R/engine-lme4.R`, sourced from one internal expression;
rendering that condition in a test and pinning the text the user reads; adding
the superseded phrase to the existing withdrawn-claim pin in
`tests/testthat/test-doc-skew-caveat.R`; and the one repair that pin needs to be
planted at all — the four-prefix `spellings` extraction regex in
`data-raw/m123-capability-claim-mutations.R:73`, which today silently skips any
pin named outside `bayes|engines_omit|install_|design_never`.

**Out:**
- The `"lme4"` reasons at the sibling checks (`R/engine-lme4.R:50` and the
  replicate/multilevel variants) — true as written; no home needed.
- Any new doc-claim checker, ledger or truthfulness audit → barred by D-021;
  D-029 requires extending the existing instrument, which is what T3 does.
- The abort-remedy-truthfulness ledger → stays a ROADMAP candidate row, still
  barred by D-021.
- A bare-code-line plant regime for the mutation harness → back to the
  per-class-reachability candidate row; measured at the T3 gate to produce
  swept text byte-identical to the existing `README.Rmd` prefix-`""` cell.
- The remaining pieces of the per-class-reachability candidate row (installed-leg
  planting per spelling, `Rd:*` mutation verification, plant-target/walk
  cross-check, and the `installed_targets()` `vig[1]` truncation) → stay on that
  row; only the `spellings` regex and the plant-form gap are retired here.

## Acceptance criteria

- [ ] AC1. Every `rlang::check_installed()` call in `R/` whose package argument
      is `"merDeriv"` passes the corrected reason from one internal expression,
      and none passes a literal. Domain enumerated by
      `git grep -n -A2 'check_installed(' -- 'R/*.R'` filtered to the sites whose
      package literal is `"merDeriv"`; the filtered listing is quoted in the work
      log.
- [ ] AC2. The message the user reads names what merDeriv supplies and
      attributes the requirement to the engine's entry check, not to an
      interval method. Evidence: a test in
      `tests/testthat/test-icc-lme4-engine.R` puts `merderiv_reason()` through
      the real `rlang::check_installed()` rendering path and asserts the
      resulting `conditionMessage()`, with whitespace collapsed, contains
      verbatim (`fixed = TRUE`):
      `to supply the lme4 parameter covariance; every lme4 fit checks for it on entry, whatever interval method you ask for.`
      The assertion is a substring, not full-string equality, because the
      surrounding frame (`The package "X" is required …`) is rlang's prose and
      not this package's (M93 lesson); whitespace is collapsed, and the
      assertion repeated at two `cli.width` settings, because cli wraps the
      rendered message to the display width (measured to break at different
      points at widths 2000, 80 and 40).
- [ ] AC3. A maintainer restoring the withdrawn wording to a swept source file
      reds: the string literal it shipped in —
      `"to compute lme4 Monte-Carlo confidence intervals."`, double quotes and
      terminal full stop included, recovered by
      `git show 26ef090:R/engine-lme4.R` — joins `claim_patterns` in
      `tests/testthat/test-doc-skew-caveat.R`, and the pin's source walk runs
      green on a full source tree. The bare fragment without quotes is rejected
      on precision, not recall: it runs green on today's tree but would red a
      future true sentence ("the covariance used to compute lme4 Monte-Carlo
      confidence intervals"), this milestone's own NEWS bullet included — the
      `install_*` anchoring precedent. Because the pinned bytes are R code the
      entry reaches `.R` sources and not prose surfaces; that limit and the
      recall cost are recorded beside the entry. Evidence: the M123 mutation
      harness plants the new spelling through its existing 2 x 4
      (surface x wrap-form) matrix, every cell RED, its two-way name check green
      on the unmutated control, per-cell verdicts in the work log. Stated over a
      full source tree: the source leg returns `list()` when `R/` is absent
      (`tests/testthat/test-doc-skew-caveat.R:456-458`), so a green
      `R CMD check` does not evidence it; the evidence run is `devtools::test()`
      on the tree.
- [ ] AC4. The corrected message's claim is true of the code: `ci_method` is not
      a parameter of any function in `R/engine-lme4.R`, and every entry point the
      procedure `git grep -n '^fit_lme4' -- R/engine-lme4.R` returns reaches its
      merDeriv check before its fitting call. Evidence: that listing plus
      `git grep -n 'ci_method' -- R/engine-lme4.R`, both quoted in the work log.
- [ ] AC5. `devtools::check()` clean (0 errors / 0 warnings / 0 notes) and
      `air format --check .` clean.

## Coverage

- AC1 → T1
- AC2 → T1, T2
- AC3 → T3
- AC4 → T1, T4
- AC5 → T5

## Tasks

- [x] T1. Add one internal expression in `R/engine-lme4.R` returning
      `"to supply the lme4 parameter covariance; every lme4 fit checks for it on entry, whatever interval method you ask for."`
      and repoint every merDeriv `check_installed()` site the AC1 enumeration
      returns (today: `:53, :198, :325, :567, :591, :623, :648, :673, :706, :748,
      :883, :1014`) to it, removing the literals.
- [x] T2. Extend `tests/testthat/test-icc-lme4-engine.R` with the AC2 rendering
      assertion: put `merderiv_reason()` through `rlang::check_installed()` under
      an absent probe package name, at two `cli.width` settings, and compare the
      rendered message by substring — not the internal expression, and not
      rlang's own frame.
- [ ] T3. Add the quote-delimited literal to `claim_patterns` in
      `tests/testthat/test-doc-skew-caveat.R` as a `merderiv_*` entry, with the
      anchoring rationale, the `.R`-sources-only limit and the recall cost in the
      comment beside it; add the one token `|merderiv` to the `spellings`
      extraction alternation at `data-raw/m123-capability-claim-mutations.R:73`
      (a general identifier widening reds the two-way check on the unmutated
      control — it matches ~30 non-capability entries the harness does not
      plant); run the harness and record per-cell verdicts.
- [ ] T4. Record the AC4 listings in the work log; add the NEWS bullet, worded so
      it does not itself carry the withdrawn phrase — `NEWS.md` is swept by both
      pin legs, so quoting it would red AC3.
- [ ] T5. Gate hygiene: `air format .`, `devtools::check()`, the four data-raw
      checkers; delete the promoted candidate row from `cairn/ROADMAP.md` and
      narrow the per-class-reachability row to the pieces this milestone leaves.

## Work log

- 2026-08-18: created by /milestone-plan.
- 2026-08-18: plan gate chose a milestone over a hotfix because the honest job carries a wording decision, a boundary caveat and two confirmed pin blind spots, where M101's precedent covered a purely substitutive message fix; falsified by the implementation turning out to be the string substitution alone, with no design choice and no harness repair.
- 2026-08-18: plan gate chose naming what merDeriv supplies over reusing the sibling `"to fit the ICC model with lme4."` because that text is byte-identical to the lme4 check at `R/engine-lme4.R:50` and is contradicted by the nine replicate/multilevel siblings; falsified by a user reading the new message as not saying why merDeriv is demanded of them.
- 2026-08-18: plan gate chose claiming the entry CHECK over claiming the covariance is formed, because a singular fit aborts at `R/engine-lme4.R:79-94` before any covariance exists, and the check framing is the one M126 already landed at `README.Rmd:63`; falsified by an lme4 path that does not check for merDeriv on entry.
- 2026-08-18: plan gate chose extending the existing pin plus repairing its two blind spots over a standalone rendered-message assertion, because D-029 requires extending the existing instrument and D-021's Untouched clause permits checker repairs; falsified by the harness repair proving larger than the message correction it serves.
- 2026-08-18: criteria audit ran in FULL mode (user-facing tier), fresh-context [O] reader, twelve findings returned. Fixed before writing: AC1 bound a hoist rather than the property and its grep could not show which sites were the domain (widened to all of `R/`, filtered by package literal); AC2 pinned an internal constant rather than the rendered message and its literal spanned three lines (now a one-line rendered text); AC4 named an "engine contract" `icc()` does not return and a `vcov` untied to merDeriv (replaced with the entry-order claim the message actually makes); AC3 overstated what a green run covers (layout now stated); the NEWS bullet was uncovered and would itself red the pin (now T4). Promoted to gate questions: the wording collision with the sibling reason, the boundary-abort falsifier, and the pin/harness extent. The plant matrix stayed evidence under AC3 rather than becoming its own criterion, so no criterion binds an instrument property.

- 2026-08-18: AC2 amended (Substantive). The planned criterion pinned `The "merDeriv" package is required …` as a full string on one line; live measurement (rlang 1.3.0, cli 3.6.6) shows the template is `The package "X" is required …` and that cli wraps it to the display width, breaking at different points at widths 2000, 80 and 40. A fresh-context [O] reader then falsified the first repair too: `check_installed()` never calls `is_installed()` (it short-circuits on `.getNamespace()`, then calls `rlang:::detect_installed()`), and any mock is defeated when merDeriv's namespace is already loaded by earlier tests in the session. Mini gate chose the absent-probe package name over mocking `rlang:::detect_installed` (plus `unloadNamespace`) because the probe needs no unexported dependency internal, no cross-package mock — the repo's first — and no session-order assumption; falsified by the rendered reason diverging from what a real site renders. AC2 now pins by substring per the M93 lesson, so rlang's own frame is not hostage to this criterion. No criterion was widened: AC2's domain is unchanged and its promise narrowed to the clause this package owns.

- 2026-08-18: T1 — `merderiv_reason()` added to `R/engine-lme4.R`; all 12 merDeriv `check_installed()` sites repointed to it, no literals left (`git grep -n 'Monte-Carlo confidence intervals' -- R/` returns nothing).
- 2026-08-18: T2 — AC2 rendering test added to `tests/testthat/test-icc-lme4-engine.R`; mutation-checked by substituting the withdrawn wording into `merderiv_reason()`, which reds 3 assertions (both widths and the anti-withdrawn check) and greens on restore. Full suite `NOT_CRAN=true CI=true devtools::test()`: 0 failures, 8202 passing.

- 2026-08-18: AC3 and Scope amended (Substantive), narrowing. A fresh-context [O] reader measured that (i) after T1 the withdrawn wording lives only in `merderiv_reason()`'s body, which carries no `reason = ` prefix, so an anchor on that prefix would guard twelve sites that no longer exist and miss the one that does — the pin is the quote-delimited string literal instead; (ii) the bare fragment has zero hits on today's tree but would red a future true sentence, T4's own NEWS bullet included, so it is rejected on precision per the `install_*` precedent; (iii) a bare-code-line plant regime produces swept text byte-identical to the existing `README.Rmd` prefix-`""` cell, because `squash()` collapses indentation and the walk knows nothing of file type — the cell cannot fail independently, so it leaves Scope for the candidate row; (iv) a general identifier widening of the `spellings` alternation matches ~30 non-capability `claim_patterns` entries the harness deliberately does not plant and would red the two-way check on the unmutated control, so the widening is the single token `|merderiv`. Mini gate chose narrowing over building the regime, because the milestone's own plan-gate falsifier — "the harness repair proving larger than the message correction it serves" — was being met; falsified by the withdrawn wording returning to a swept `.R` source with the pin green. AC3's instrument clauses moved under an `Evidence:` label, so no criterion binds an instrument property.

- 2026-08-18: T3 partial checkpoint — pin entry `merderiv_method_specific` added to `claim_patterns` with its anchoring rationale, `.R`-sources-only limit and recall cost in the adjacent comment; `|merderiv` added to the `spellings` extraction alternation and the matching plant sentence added to the harness. T3 is NOT complete: the mutation harness run that AC3 requires (every cell RED, two-way name check green on the unmutated control, per-cell verdicts) was still in flight at this checkpoint, so no verdicts are recorded yet and AC3 stays unchecked. `README.Rmd` was mid-plant and is deliberately excluded from this commit.

## Decisions

## Review
