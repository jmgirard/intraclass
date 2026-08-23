# M134: Vignette prose pass — the reader path, and the house style standard

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m134-vignette-prose-reader-path`

## Goal

Rewrite the three reader-path articles so no sentence runs past 35 words and no
dash stands in for punctuation, and write down the style rules the pass applies.

## Scope

Surface tier: **user-facing** — the deliverable is prose readers of the pkgdown
site and `browseVignettes()` see. Correcting what the package tells its users is
D-029's carve-out from D-021, so no trigger in what the package computes is
needed; `data-raw/prose-profile.py` stays a one-shot ruler, never wired to CI.

**In:** `vignettes/getting-started.Rmd`, `vignettes/choosing-an-icc.Rmd`,
`vignettes/glossary.Rmd`. The style standard `cairn/doctrine/prose-style.md`,
stating rules R1–R6:

- **R1 dash-as-punctuation** — no em dash, `---`, or standalone `--` used as a
  sentence-level break. Not counted: YAML front-matter delimiters, markdown
  table rules, dashes flanked by digits (page and numeric ranges), dashes
  joining capitalized proper nouns (`Spearman--Brown`).
- **R2 sentence length** — no prose sentence over 35 words.
- **R3 one idea per sentence** — at most one subordinate clause before the main verb.
- **R4 parentheticals** — at most one per sentence, none over 15 words (judgment, not gated).
- **R5 semicolons** — no semicolon joining clauses that could be two sentences (judgment, not gated).
- **R6 meaning is fixed** — a rewrite never widens or narrows a claim's scope (M72/M128).

Baseline over `vignettes/*.Rmd` at `72f9cc2`, measured 2026-08-23 by the
committed ruler `python3 data-raw/prose-profile.py 'vignettes/*.Rmd'`: 744
sentence-level fragments, 81 over 35 words, 226 dash-as-punctuation
occurrences, 11 parentheticals over 15 words, 55 semicolons. The three
in-scope files hold 358 of those fragments, 20 over 35 words, 66 dashes. The
figures this milestone was planned with (594 / 121 / 287 / 195 / 56) came from
a throwaway ruler that was never committed and cannot be re-run; the committed
ruler's reading of the same commit supersedes them.

**Out:** the five method articles → M135. Roxygen and `README.Rmd` → M136.
`cli` abort and hint strings in `R/abort.R`/`R/boundary-hint.R` → stay a
candidate row (same D-029 class, own guard in
`data-raw/check-abort-remedy-verdicts.R`). Numeric targets for R4 and R5 → not
gated anywhere; the read-through applies them. Any CI-wired prose checker →
refused, D-021 stands.

## Acceptance criteria

- [ ] AC1 `data-raw/prose-profile.py` is committed, implements R1's counted
      class and R2's sentence rule as `cairn/doctrine/prose-style.md` defines
      them, counts `#'` lines outside `@examples` in `.R` mode, and is
      byte-identical between its baseline run at `72f9cc2` and its final run.
- [ ] AC2 `python3 data-raw/prose-profile.py 'vignettes/getting-started.Rmd'`
      and the same command for `choosing-an-icc.Rmd` and `glossary.Rmd` each
      report 0 dash-as-punctuation occurrences and 0 sentences over 35 words.
- [ ] AC3 `cairn/doctrine/prose-style.md` exists and states rules R1–R6 as
      listed in Scope.
- [ ] AC4 For every hunk of `git diff 72f9cc2 -- vignettes/getting-started.Rmd
      vignettes/choosing-an-icc.Rmd vignettes/glossary.Rmd` whose added **or**
      removed lines match `\b(any|each|every|all|only|both|exactly|never|always|full)\b`,
      the added text's claim domain is equal to or narrower than the text it
      replaced.
- [ ] AC5 `devtools::test()` clean; `devtools::check()` raw `Status:` line 0
      errors / 0 warnings (NOTEs justified); `devtools::document()` no diff;
      `python3 data-raw/check-record-claims.py` exits 0 in live mode.

## Coverage

- AC1 → T1
- AC2 → T1, T3, T4, T5
- AC3 → T2
- AC4 → T6
- AC5 → T7

## Tasks

- [x] T1 Write `data-raw/prose-profile.py` (drops fenced chunks in `.Rmd`, reads
      only `#'` lines outside `@examples` in `.R`, implements R1's exclusions),
      run it at `72f9cc2`, and record the baseline table in Scope.
- [x] T2 Write `cairn/doctrine/prose-style.md` with R1–R6.
- [x] T3 Rewrite `vignettes/getting-started.Rmd` against R1–R6.
- [ ] T4 Rewrite `vignettes/choosing-an-icc.Rmd` against R1–R6.
- [ ] T5 Rewrite `vignettes/glossary.Rmd` against R1–R6 (167 fragments, the
      longest file; its one-sentence definitions are the R2 stress case).
- [ ] T6 Run the AC4 grep over added and removed diff lines; for each hunk it
      returns, compare the added claim's domain against the removed one and
      repair any widening in place.
- [ ] T7 Run the AC5 verify block; re-knit nothing (no roxygen touched).

## Work log

- 2026-08-23: created by /milestone-plan.
- 2026-08-23: plan-gate criteria audit ran in FULL mode ([O] fresh-context reader, all three milestones user-facing tier) and returned 13 findings, no criterion passing all six questions. Ten fixed here before writing: F1 (dash class unreachable at literal 0 — R1 exclusions defined), F2 (hand-listed R files → glob, M136), F3 (missing live MPL-checker AC, M136), F4 (`--self-test` is an instrument property → live mode), F5 (grep missed qualifier-deletion widening → added+removed lines, promise restated over hunks), F7 (AC3 unfalsifiable → R1–R6 enumerated in Scope; before/after examples moved to the PR body), F9 (AC1 was ruler-self-consistency → byte-identity of the ruler), F10 (`.R` mode scope undefined → `#'` outside `@examples`), F12 (M135 "re-triaged" undefined), F13 (M136 "in sync" → `git diff --exit-code`). Three posed at the gate: F8 (no target for parentheticals/semicolons), F11 (M136 AC2 requires a meaning change), audit note 2 (`cli` strings uncovered).
- 2026-08-23: plan gate chose three milestones split by article family over one all-vignettes milestone because M135's files carry five separate prose guards that one review would have to fence at once; falsified by a review that finds the three-way split forced the same edit to be re-argued across milestones.
- 2026-08-23: plan gate chose measured targets for R1/R2 only over numeric targets on all four trope classes because a zero target on parentheticals and semicolons has no non-arbitrary threshold and would fight readability; falsified by a post-pass read finding stacked parentheticals substantially unreduced.
- 2026-08-23: T1 — `data-raw/prose-profile.py` committed and run at `72f9cc2`; the ruler is frozen from this commit (AC1's byte-identity clock starts here).
- 2026-08-23: implement gate chose the committed ruler's baseline over the plan's recorded figures because the planned figures came from an uncommitted throwaway ruler that cannot be re-run; Scope amended to 744 fragments / 81 over 35 / 226 dashes / 11 long parentheticals / 55 semicolons over `vignettes/*.Rmd`, the three in-scope files holding 358 / 20 / 66. Falsified by the committed ruler needing a correction that changes these figures mid-pass.
- 2026-08-23: implement gate chose counting headings and table cells as prose over body paragraphs only, so AC2's zero covers every surface a reader sees; T5's stale sentence figure corrected to the new ruler's 167 fragments.
- 2026-08-23: T2 — `cairn/doctrine/prose-style.md` written: R1–R6 verbatim from Scope, the ruler's prose boundary, the five-step pass procedure, and a stated budget of 120 lines / 8,000 bytes (at 97 / 5,162).
- 2026-08-23: T3 — `getting-started.Rmd` rewritten; ruler now reports 0 dashes, 0 sentences over 35 (longest 32), against 18 dashes and 6 long sentences (longest 53) at baseline. Semicolons 1 → 0, long parentheticals 3 → 2.

## Decisions

## Review
