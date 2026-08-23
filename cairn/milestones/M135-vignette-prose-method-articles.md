# M135: Vignette prose pass — the method articles

- **Status:** planned
- **Priority:** normal
- **Depends on:** M134
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** —

## Goal

Apply M134's style rules to the five method articles, the ones whose prose is
watched by five separate guards, without moving any pinned claim.

## Scope

Surface tier: **user-facing** — published articles; D-029 carve-out, as M134.

**In:** `vignettes/engines.Rmd`, `vignettes/comparison-with-other-packages.Rmd`,
`vignettes/d-studies-and-replicates.Rmd`, `vignettes/multilevel-designs.Rmd`,
`vignettes/interval-methods.Rmd`, rewritten against rules R1–R6 of
`cairn/doctrine/prose-style.md` (M134).

Baseline at `72f9cc2`: these five hold 281 sentences, 88 over 35 words, 188 dash
occurrences. `interval-methods.Rmd` is the worst file in the package (86
sentences, 28 over 35 words, 54 dashes) and the only one fenced by four guards:
`tests/testthat/test-vignette-claims.R`, `test-vignette-transcripts.R` (M129
engine transcripts), `test-doc-skew-caveat.R`, `data-raw/check-mpl-doc-claims.py`
(`VIGNETTE = "vignettes/interval-methods.Rmd"`, `check-mpl-doc-claims.py:46`) and
`data-raw/m117-width-pin-mutations.R:330`.

**Out:** the style standard itself → M134 owns it, this milestone only applies
it. Roxygen and `README.Rmd` → M136. Numeric targets for R4/R5 → not gated
(M134 Scope). Any change to what a pinned claim asserts → refused here; a claim
found wrong goes to `/hotfix` or its own milestone, never into a style edit.

## Acceptance criteria

- [ ] AC1 `python3 data-raw/prose-profile.py` run against each of the five files
      named in Scope reports 0 dash-as-punctuation occurrences and 0 sentences
      over 35 words.
- [ ] AC2 For every hunk of `git diff <base> -- vignettes/` in this milestone
      whose added **or** removed lines match
      `\b(any|each|every|all|only|both|exactly|never|always|full)\b`, the added
      text's claim domain is equal to or narrower than the text it replaced.
- [ ] AC3 `python3 data-raw/check-mpl-doc-claims.py` exits 0 in live mode
      against the edited `interval-methods.Rmd`, and every
      `data-raw/mpl-doc-claims.tsv` row whose key changes carries the edited
      quote verbatim with its `assertion` and `disposition` columns unchanged,
      in the same commit as the prose edit.
- [ ] AC4 `Rscript data-raw/m117-width-pin-mutations.R` exits 0 against the
      edited `interval-methods.Rmd`.
- [ ] AC5 `devtools::test()` clean (including `test-vignette-claims.R`,
      `test-vignette-transcripts.R`, `test-doc-skew-caveat.R`);
      `devtools::check()` raw `Status:` line 0 errors / 0 warnings (NOTEs
      justified); `devtools::document()` no diff;
      `python3 data-raw/check-record-claims.py` exits 0 in live mode.

## Coverage

- AC1 → T1, T2, T3, T4, T5
- AC2 → T6
- AC3 → T5, T7
- AC4 → T5, T7
- AC5 → T8

## Tasks

- [ ] T1 Rewrite `vignettes/engines.Rmd` against R1–R6.
- [ ] T2 Rewrite `vignettes/comparison-with-other-packages.Rmd` against R1–R6.
- [ ] T3 Rewrite `vignettes/d-studies-and-replicates.Rmd` against R1–R6.
- [ ] T4 Rewrite `vignettes/multilevel-designs.Rmd` against R1–R6.
- [ ] T5 Rewrite `vignettes/interval-methods.Rmd` against R1–R6, holding every
      sentence the four guards quote byte-stable unless T7 re-keys it.
- [ ] T6 Run the AC2 grep over added and removed diff lines; repair any widening.
- [ ] T7 Re-key `data-raw/mpl-doc-claims.tsv` for every quote T5 edited, keeping
      `assertion` and `disposition` unchanged; run both `interval-methods`
      guards live before the commit that carries the prose edit.
- [ ] T8 Run the AC5 verify block.

## Work log

- 2026-08-23: created by /milestone-plan.
- 2026-08-23: plan-gate criteria audit ran in FULL mode; the record and its 13 findings are in M134's work log — this file's AC2/AC3 carry the F5 and F12 repairs, and its AC5 the F4 live-mode repair.
- 2026-08-23: plan gate chose to fold `interval-methods.Rmd` into this milestone over giving it its own because its four guards are re-run once for the whole file family rather than twice; falsified by T5 plus T7 overrunning a working session, which is the split's trigger.

## Decisions

## Review
