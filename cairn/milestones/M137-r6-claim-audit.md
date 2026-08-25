<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M137: R6 claim audit over the M134-M136 prose diffs

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP1, GP8   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m137-r6-claim-audit`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Read every chunk of user-facing prose that M134, M135 and M136 rewrote against
the text it replaced, and repair each claim whose scope moved. **Surface tier:
user-facing** — the deliverable is corrected text in the shipped vignettes,
roxygen blocks and README, which is what a v0.1.0 reader gets.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** the 111 hunks the three prose-pass merges changed on user-facing paths;
the repairs those comparisons call for; a rewrite of `prose-style.md` step 5's
selection rule from its ten-word list to the class the list was standing in for.

**Out:** a mechanical checker over prose diffs — refused at this gate, stays the
ROADMAP candidate row it already is. The `cli` abort and hint surface (135
message sites across 14 files, not the two the candidate row names) — stays a
candidate row. Prose the three passes did not touch — not this milestone's
domain. Any claim found false on its own merits rather than by the comparison —
repaired in place if cheap, else a candidate row.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: Each hunk in the enumerated domain has its added text compared
      against the text it replaced, and every discrepancy that comparison
      records — a claim whose domain widened or narrowed — is repaired in the
      shipped prose. The domain is what these three commands report (111 hunks,
      measured 2026-08-24): `git diff -U3 --no-renames --diff-algorithm=myers
      bb42f8e^ bb42f8e -- vignettes/` (32); the same form for `8aafb0e^
      8aafb0e -- vignettes/` (52); and for `5c274fc^ 5c274fc -- 'R/*.R'
      README.Rmd` (27). This criterion promises the comparison ran over that
      domain and that its findings are repaired. It does **not** promise that
      no widened claim remains: M136 recorded three closures each defeated by
      a fresh shape, so that promise is unavailable to a reading pass.
- [ ] AC2: No repair changes what the package computes or reports.
      `git diff --merge-base main -- 'R/*.R' | grep '^[+-]' | grep -v
      '^[+-][+-]' | grep -v "^[+-] *#'"` is empty. Every other changed path is
      one of `vignettes/*.Rmd`, `README.Rmd`, `README.md`, `man/*.Rd`,
      `NEWS.md`, `cairn/`, or — where a repair lands inside a verbatim-pinned
      span — a re-pointed anchor in `tests/testthat/*.R` or `data-raw/*.R`,
      with no change to any test expectation other than such an anchor.
- [ ] AC3: For every file this branch touches, `python3
      data-raw/prose-profile.py` reports zero on R1 and R2 (the two rules that
      script defines), and reports an over-35 sentence only where that sentence
      carries the 58-word clause `residual_template()` pins with `fixed =
      TRUE` — the carrier set derived by matching that clause, never stated as
      a count (four at 2026-08-24: two in `R/icc.R`, one in
      `vignettes/glossary.Rmd`, one in `vignettes/interval-methods.Rmd`).
- [ ] AC4: The installed-package suite at `NOT_CRAN=true CI=true` is green
      (failed + error sum 0), and every checker the `check-references` job runs
      (`.github/workflows/lint.yaml`) passes with `--self-test`.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T3, T4, T5
- AC2 → T5, T6
- AC3 → T6
- AC4 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Run the three pinned `git diff` commands; record the per-merge hunk
      count and confirm the total against AC1's 111. Open the triage table in
      this file's Work log / Review sections — one row per hunk, keyed by
      commit + file + hunk header. No `data-raw/` ledger: a standing table over
      the repo's own prose is apparatus, and the triage is milestone evidence.
- [x] T2: Rewrite `cairn/doctrine/prose-style.md` step 5's selection rule from
      the ten scope words to the class they stood in for — any construction
      carrying a claim's scope that a sentence split can drop. Compress
      elsewhere in the module to stay inside its stated 120-line / 8,000-byte
      budget (119 / 6,900 at 2026-08-24) and report the post-edit figures.
- [ ] T3: Triage the 84 vignette hunks from M134 and M135. Per hunk: a verdict,
      and where the verdict is a discrepancy, both texts quoted.
- [ ] T4: Triage the 27 roxygen and README hunks from M136, same form.
- [ ] T5: Repair every discrepancy T3/T4 recorded. Where a repair falls inside
      a span pinned verbatim (`test-doc-skew-caveat.R`,
      `data-raw/m117-width-pin-mutations.R`), re-point the anchor in the same
      commit — M130's lesson: a doc-surface edit re-keys the claim ledgers.
- [ ] T6: Run AC2's diff command, the ruler (AC3), the installed-package suite
      and the `check-references` checkers with `--self-test` (AC4). Add a
      `NEWS.md` entry for any repair a user would notice.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-24: created by /milestone-plan. Gate: audit-and-fix with no new checker; the `cli` message surface left out; domain limited to the rewritten hunks; the criteria-audit reader run.
- 2026-08-24: criteria audit ran in FULL mode (user-facing tier), one fresh-context [O] reader, 15 findings. Structural fixes taken: AC3 (doctrine binding) dropped to T2 as an instrument-bound promise on a user-facing milestone; AC1 rewritten to quantify over the enumerated 111 rather than over its own verdict column; the over-35 exemption corrected from two carriers to four and derived by clause match; "four doc-claim checkers" replaced by the CI job that runs them; diff options pinned; `tests/` and `data-raw/*.R` pin anchors added to AC2; the committed ledger dropped for a milestone-file triage.
- 2026-08-24: approach chosen — a reading pass that repairs what it finds, over a mechanical scope-narrowing predicate. The predicate lost because D-021 bars a new guard over this repo's own doc claims absent a defect in what the package computes, and D-029's M116 precedent is directly on point; the ten-word grep it would generalize is also the net M136's three escapes already defeated. Falsifier: a user reaching a widened claim in shipped v0.1.0 prose, which is the candidate row's own promotion condition and would supersede D-021 for this scope.
- 2026-08-24: doctrine step 5 rewritten over the class rather than extended by three members — the alternative (adding em dash, parenthesis and frame adverbial to the word list) lost to the standing rule that a counterexample is not answered by a wider enumeration. Falsifier: a fourth escape whose construction the class statement also fails to name.

- 2026-08-24: T1 — domain measured with the three pinned commands: `bb42f8e` 32 hunks, `8aafb0e` 52, `5c274fc` 27; total 111, equal to AC1's figure. The `5c274fc` `R/*.R` side is roxygen-only (the AC2 grep over that commit returns 0 lines), so no code line entered the audited domain. Gate: triage table lives in this work log as one block (option 1 of 3); a repair re-words to the replaced text's scope rather than reverting to its wording, so R1/R2 stay at zero (option 1 of 3).

- 2026-08-24: T2 — `prose-style.md` step 5 rewritten to select every hunk and to name the scope-carrying class (quantifier/absolute, restrictive clause, dash- or parenthesis-set appositive, frame adverbial, conditional, hedge) rather than ten words; R1's proper-noun rationale, the gating paragraph and the R6 paragraph compressed to pay for it. Post-edit: 118 lines / 6,921 bytes against the module's < 120 / < 8,000 budget.

### Triage table (T1 opens; T3/T4 fill) — 111 hunks

Verdicts: `same` — the added text's claim domain equals the text it replaced; `wider` / `narrower` — it moved, and both texts are quoted in the row.

| # | commit | file | hunk | verdict | note |
|---|---|---|---|---|---|

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
