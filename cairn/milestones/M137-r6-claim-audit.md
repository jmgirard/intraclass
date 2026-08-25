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

- [x] T1: Run the three pinned `git diff` commands; record the per-merge hunk
      count and confirm the total against AC1's 111. Open the triage table in
      this file's Work log / Review sections — one row per hunk, keyed by
      commit + file + hunk header. No `data-raw/` ledger: a standing table over
      the repo's own prose is apparatus, and the triage is milestone evidence.
- [x] T2: Rewrite `cairn/doctrine/prose-style.md` step 5's selection rule from
      the ten scope words to the class they stood in for — any construction
      carrying a claim's scope that a sentence split can drop. Compress
      elsewhere in the module to stay inside its stated 120-line / 8,000-byte
      budget (119 / 6,900 at 2026-08-24) and report the post-edit figures.
- [x] T3: Triage the 84 vignette hunks from M134 and M135. Per hunk: a verdict,
      and where the verdict is a discrepancy, both texts quoted.
- [x] T4: Triage the 27 roxygen and README hunks from M136, same form.
- [x] T5: Repair every discrepancy T3/T4 recorded. Where a repair falls inside
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
| 1 | `bb42f8e` | `vignettes/choosing-an-icc.Rmd` | `@@ -18,21 +18,20 @@` | `same` |  |
| 2 | `bb42f8e` | `vignettes/choosing-an-icc.Rmd` | `@@ -42,7 +41,7 @@` | `same` |  |
| 3 | `bb42f8e` | `vignettes/choosing-an-icc.Rmd` | `@@ -54,9 +53,10 @@` | `same` | conditional split; `Those raters` binds the antecedent, so the one-way frame survives. |
| 4 | `bb42f8e` | `vignettes/choosing-an-icc.Rmd` | `@@ -69,14 +69,14 @@` | `same` |  |
| 5 | `bb42f8e` | `vignettes/choosing-an-icc.Rmd` | `@@ -93,7 +93,7 @@` | `same` |  |
| 6 | `bb42f8e` | `vignettes/choosing-an-icc.Rmd` | `@@ -113,14 +113,14 @@` | `same` |  |
| 7 | `bb42f8e` | `vignettes/choosing-an-icc.Rmd` | `@@ -132,24 +132,25 @@` | `same` |  |
| 8 | `bb42f8e` | `vignettes/choosing-an-icc.Rmd` | `@@ -162,7 +163,7 @@` | `same` |  |
| 9 | `bb42f8e` | `vignettes/choosing-an-icc.Rmd` | `@@ -209,19 +210,20 @@` | `same` |  |
| 10 | `bb42f8e` | `vignettes/choosing-an-icc.Rmd` | `@@ -252,23 +254,23 @@` | `same` |  |
| 11 | `bb42f8e` | `vignettes/getting-started.Rmd` | `@@ -17,8 +17,8 @@` | `same` |  |
| 12 | `bb42f8e` | `vignettes/getting-started.Rmd` | `@@ -27,25 +27,25 @@` | `same` |  |
| 13 | `bb42f8e` | `vignettes/getting-started.Rmd` | `@@ -54,12 +54,12 @@` | `same` |  |
| 14 | `bb42f8e` | `vignettes/getting-started.Rmd` | `@@ -80,7 +80,7 @@` | `same` |  |
| 15 | `bb42f8e` | `vignettes/getting-started.Rmd` | `@@ -89,10 +89,10 @@` | `same` |  |
| 16 | `bb42f8e` | `vignettes/getting-started.Rmd` | `@@ -101,7 +101,7 @@` | `same` |  |
| 17 | `bb42f8e` | `vignettes/getting-started.Rmd` | `@@ -112,9 +112,9 @@` | `same` |  |
| 18 | `bb42f8e` | `vignettes/getting-started.Rmd` | `@@ -130,14 +130,14 @@` | `same` |  |
| 19 | `bb42f8e` | `vignettes/getting-started.Rmd` | `@@ -146,20 +146,19 @@` | `same` | `icc()` simulates -> `the default interval does not rely on`; the topic sentence already scoped to the reported default, so no move. |
| 20 | `bb42f8e` | `vignettes/getting-started.Rmd` | `@@ -171,18 +170,18 @@` | `same` | `these choices` -> `Several choices`; the same five follow as questions, and neither wording claims exclusivity. |
| 21 | `bb42f8e` | `vignettes/glossary.Rmd` | `@@ -12,43 +12,46 @@` | `same` |  |
| 22 | `bb42f8e` | `vignettes/glossary.Rmd` | `@@ -56,7 +59,7 @@` | `same` |  |
| 23 | `bb42f8e` | `vignettes/glossary.Rmd` | `@@ -66,19 +69,20 @@` | `same` |  |
| 24 | `bb42f8e` | `vignettes/glossary.Rmd` | `@@ -86,13 +90,13 @@` | `same` |  |
| 25 | `bb42f8e` | `vignettes/glossary.Rmd` | `@@ -111,10 +115,10 @@` | `same` |  |
| 26 | `bb42f8e` | `vignettes/glossary.Rmd` | `@@ -128,13 +132,13 @@` | `same` |  |
| 27 | `bb42f8e` | `vignettes/glossary.Rmd` | `@@ -144,25 +148,26 @@` | `same` |  |
| 28 | `bb42f8e` | `vignettes/glossary.Rmd` | `@@ -183,17 +188,18 @@` | `same` |  |
| 29 | `bb42f8e` | `vignettes/glossary.Rmd` | `@@ -206,7 +212,7 @@` | `same` |  |
| 30 | `bb42f8e` | `vignettes/glossary.Rmd` | `@@ -230,7 +236,7 @@` | `same` |  |
| 31 | `bb42f8e` | `vignettes/glossary.Rmd` | `@@ -238,20 +244,20 @@` | `same` |  |
| 32 | `bb42f8e` | `vignettes/glossary.Rmd` | `@@ -259,37 +265,38 @@` | `same` |  |
| 33 | `8aafb0e` | `vignettes/comparison-with-other-packages.Rmd` | `@@ -24,7 +24,7 @@` | `same` |  |
| 34 | `8aafb0e` | `vignettes/comparison-with-other-packages.Rmd` | `@@ -43,10 +43,10 @@` | `same` |  |
| 35 | `8aafb0e` | `vignettes/comparison-with-other-packages.Rmd` | `@@ -90,15 +90,15 @@` | `same` |  |
| 36 | `8aafb0e` | `vignettes/comparison-with-other-packages.Rmd` | `@@ -126,8 +126,8 @@` | `same` |  |
| 37 | `8aafb0e` | `vignettes/comparison-with-other-packages.Rmd` | `@@ -163,58 +163,58 @@` | `same` | capability-matrix cells `—` -> `no`; same negative in a yes/partial/no column. Boundary-aware sentence reordered, `none of the classical tools provide` intact. |
| 38 | `8aafb0e` | `vignettes/d-studies-and-replicates.Rmd` | `@@ -15,12 +15,13 @@` | `same` |  |
| 39 | `8aafb0e` | `vignettes/d-studies-and-replicates.Rmd` | `@@ -34,7 +35,7 @@` | `same` |  |
| 40 | `8aafb0e` | `vignettes/d-studies-and-replicates.Rmd` | `@@ -42,16 +43,16 @@` | `same` |  |
| 41 | `8aafb0e` | `vignettes/d-studies-and-replicates.Rmd` | `@@ -63,7 +64,7 @@` | `same` |  |
| 42 | `8aafb0e` | `vignettes/d-studies-and-replicates.Rmd` | `@@ -71,11 +72,11 @@` | `same` |  |
| 43 | `8aafb0e` | `vignettes/d-studies-and-replicates.Rmd` | `@@ -83,7 +84,7 @@` | `same` |  |
| 44 | `8aafb0e` | `vignettes/d-studies-and-replicates.Rmd` | `@@ -95,9 +96,9 @@` | `same` |  |
| 45 | `8aafb0e` | `vignettes/d-studies-and-replicates.Rmd` | `@@ -107,18 +108,17 @@` | `same` |  |
| 46 | `8aafb0e` | `vignettes/d-studies-and-replicates.Rmd` | `@@ -127,17 +127,17 @@` | `same` |  |
| 47 | `8aafb0e` | `vignettes/d-studies-and-replicates.Rmd` | `@@ -147,11 +147,12 @@` | `same` |  |
| 48 | `8aafb0e` | `vignettes/d-studies-and-replicates.Rmd` | `@@ -173,25 +174,26 @@` | `same` |  |
| 49 | `8aafb0e` | `vignettes/d-studies-and-replicates.Rmd` | `@@ -199,18 +201,19 @@` | `same` |  |
| 50 | `8aafb0e` | `vignettes/d-studies-and-replicates.Rmd` | `@@ -219,7 +222,7 @@` | `same` |  |
| 51 | `8aafb0e` | `vignettes/d-studies-and-replicates.Rmd` | `@@ -228,14 +231,14 @@` | `same` |  |
| 52 | `8aafb0e` | `vignettes/engines.Rmd` | `@@ -15,32 +15,33 @@` | `same` |  |
| 53 | `8aafb0e` | `vignettes/engines.Rmd` | `@@ -53,20 +54,20 @@` | `same` |  |
| 54 | `8aafb0e` | `vignettes/engines.Rmd` | `@@ -92,51 +93,52 @@` | `same` | multilevel-SEM restriction moved out of the parenthesis into the next sentence (`That route takes random raters on complete, balanced data with equal cluster sizes`); bound preserved, not dropped. |
| 55 | `8aafb0e` | `vignettes/engines.Rmd` | `@@ -160,20 +162,20 @@` | `same` |  |
| 56 | `8aafb0e` | `vignettes/engines.Rmd` | `@@ -192,8 +194,8 @@` | `same` |  |
| 57 | `8aafb0e` | `vignettes/interval-methods.Rmd` | `@@ -15,16 +15,16 @@` | `same` |  |
| 58 | `8aafb0e` | `vignettes/interval-methods.Rmd` | `@@ -37,9 +37,9 @@` | `same` |  |
| 59 | `8aafb0e` | `vignettes/interval-methods.Rmd` | `@@ -57,17 +57,17 @@` | `same` |  |
| 60 | `8aafb0e` | `vignettes/interval-methods.Rmd` | `@@ -77,21 +77,21 @@` | `same` |  |
| 61 | `8aafb0e` | `vignettes/interval-methods.Rmd` | `@@ -101,25 +101,25 @@` | `same` |  |
| 62 | `8aafb0e` | `vignettes/interval-methods.Rmd` | `@@ -127,26 +127,26 @@` | `same` |  |
| 63 | `8aafb0e` | `vignettes/interval-methods.Rmd` | `@@ -157,10 +157,10 @@` | `same` |  |
| 64 | `8aafb0e` | `vignettes/interval-methods.Rmd` | `@@ -177,41 +177,43 @@` | `same` | densest hunk; the added `On the larger grid,` makes an implicit frame explicit. Every figure and fence carried. |
| 65 | `8aafb0e` | `vignettes/interval-methods.Rmd` | `@@ -220,13 +222,13 @@` | `same` |  |
| 66 | `8aafb0e` | `vignettes/interval-methods.Rmd` | `@@ -258,12 +260,12 @@` | `same` |  |
| 67 | `8aafb0e` | `vignettes/interval-methods.Rmd` | `@@ -271,22 +273,22 @@` | `wider` | **wider.** Replaced: "Like `"npbootstrap"`, it returns an interval at the near-zero-ICC boundary where the two-way Monte-Carlo default aborts". Added: "Unlike the two-way Monte-Carlo default, it does not abort at the near-zero-ICC boundary: like `"npbootstrap"`, it returns an interval there." The replaced text bound the promise to the cells where the default aborts; the added text promises the method does not abort at that boundary at all. D-019 records two abort paths there (a degenerate fit, a crossing-indicated root-finding failure), and `R/icc.R`'s own `"mpl"` block still carries the bounded wording. Repaired in T5. |
| 68 | `8aafb0e` | `vignettes/interval-methods.Rmd` | `@@ -314,23 +316,23 @@` | `same` |  |
| 69 | `8aafb0e` | `vignettes/interval-methods.Rmd` | `@@ -349,18 +351,18 @@` | `same` |  |
| 70 | `8aafb0e` | `vignettes/interval-methods.Rmd` | `@@ -382,7 +384,7 @@` | `same` |  |
| 71 | `8aafb0e` | `vignettes/multilevel-designs.Rmd` | `@@ -17,9 +17,9 @@` | `same` |  |
| 72 | `8aafb0e` | `vignettes/multilevel-designs.Rmd` | `@@ -72,8 +72,8 @@` | `same` |  |
| 73 | `8aafb0e` | `vignettes/multilevel-designs.Rmd` | `@@ -81,9 +81,9 @@` | `same` |  |
| 74 | `8aafb0e` | `vignettes/multilevel-designs.Rmd` | `@@ -97,29 +97,30 @@` | `same` |  |
| 75 | `8aafb0e` | `vignettes/multilevel-designs.Rmd` | `@@ -144,7 +145,7 @@` | `same` |  |
| 76 | `8aafb0e` | `vignettes/multilevel-designs.Rmd` | `@@ -156,8 +157,8 @@` | `same` |  |
| 77 | `8aafb0e` | `vignettes/multilevel-designs.Rmd` | `@@ -168,8 +169,8 @@` | `same` |  |
| 78 | `8aafb0e` | `vignettes/multilevel-designs.Rmd` | `@@ -182,19 +183,19 @@` | `same` |  |
| 79 | `8aafb0e` | `vignettes/multilevel-designs.Rmd` | `@@ -213,8 +214,8 @@` | `same` |  |
| 80 | `8aafb0e` | `vignettes/multilevel-designs.Rmd` | `@@ -229,9 +230,9 @@` | `same` |  |
| 81 | `8aafb0e` | `vignettes/multilevel-designs.Rmd` | `@@ -243,21 +244,22 @@` | `same` |  |
| 82 | `8aafb0e` | `vignettes/multilevel-designs.Rmd` | `@@ -271,29 +273,29 @@` | `same` |  |
| 83 | `8aafb0e` | `vignettes/multilevel-designs.Rmd` | `@@ -312,17 +314,17 @@` | `same` |  |
| 84 | `8aafb0e` | `vignettes/multilevel-designs.Rmd` | `@@ -332,8 +334,8 @@` | `same` |  |
| 85 | `5c274fc` | `R/abort.R` | `@@ -13,7 +13,7 @@` | `same` |  |
| 86 | `5c274fc` | `R/abort.R` | `@@ -63,12 +63,12 @@` | `same` |  |
| 87 | `5c274fc` | `R/abort.R` | `@@ -89,7 +89,7 @@` | `same` |  |
| 88 | `5c274fc` | `R/abort.R` | `@@ -117,10 +117,10 @@` | `same` |  |
| 89 | `5c274fc` | `R/abort.R` | `@@ -146,7 +146,7 @@` | `same` |  |
| 90 | `5c274fc` | `R/choose-icc.R` | `@@ -22,28 +22,28 @@` | `same` |  |
| 91 | `5c274fc` | `R/d-study.R` | `@@ -19,45 +19,49 @@` | `same` | `On that same data` added at the split, keeping the incomplete-data frame on the cluster-level clause. |
| 92 | `5c274fc` | `R/d-study.R` | `@@ -71,67 +75,69 @@` | `same` |  |
| 93 | `5c274fc` | `R/data.R` | `@@ -32,24 +32,24 @@` | `same` |  |
| 94 | `5c274fc` | `R/icc.R` | `@@ -3,9 +3,9 @@` | `same` |  |
| 95 | `5c274fc` | `R/icc.R` | `@@ -15,28 +15,29 @@` | `same` |  |
| 96 | `5c274fc` | `R/icc.R` | `@@ -55,95 +56,107 @@` | `same` |  |
| 97 | `5c274fc` | `R/icc.R` | `@@ -153,29 +166,29 @@` | `same` |  |
| 98 | `5c274fc` | `R/icc.R` | `@@ -183,40 +196,44 @@` | `same` | `@param design` gains a second override occasion (ambiguous labels). Not a scope move on an existing claim: the added occasion is separately true and is what the Multilevel section and the multilevel article already state. |
| 99 | `5c274fc` | `R/icc.R` | `@@ -227,172 +244,191 @@` | `same` |  |
| 100 | `5c274fc` | `R/icc.R` | `@@ -403,85 +439,88 @@` | `same` |  |
| 101 | `5c274fc` | `R/icc.R` | `@@ -492,87 +531,88 @@` | `same` |  |
| 102 | `5c274fc` | `R/icc.R` | `@@ -580,20 +620,22 @@` | `same` |  |
| 103 | `5c274fc` | `R/icc.R` | `@@ -602,9 +644,10 @@` | `same` |  |
| 104 | `5c274fc` | `R/icc.R` | `@@ -616,12 +659,12 @@` | `same` |  |
| 105 | `5c274fc` | `R/icc.R` | `@@ -629,8 +672,8 @@` | `same` |  |
| 106 | `5c274fc` | `README.Rmd` | `@@ -26,20 +26,22 @@` | `same` | `each with boundary-aware Monte-Carlo intervals` -> `Everything just listed comes with`; ranges over the same three sentences. |
| 107 | `5c274fc` | `README.Rmd` | `@@ -58,20 +60,20 @@` | `same` |  |
| 108 | `5c274fc` | `README.Rmd` | `@@ -88,20 +90,21 @@` | `same` |  |
| 109 | `5c274fc` | `README.Rmd` | `@@ -122,7 +125,7 @@` | `same` |  |
| 110 | `5c274fc` | `README.Rmd` | `@@ -131,14 +134,14 @@` | `same` |  |
| 111 | `5c274fc` | `README.Rmd` | `@@ -146,6 +149,6 @@` | `same` | table cell `—` -> `(this package)`; the `fills that gap` sentence that carried the no-comparable-package reading is unchanged. |

- 2026-08-24: T3/T4 — all 111 hunks compared against the text they replaced; table above. 110 `same`, 1 `wider`. Ten borderline comparisons carry a note naming why the verdict is `same`, the recurring shape being a restriction moved out of a dash pair or parenthesis into an adjacent sentence with an explicit frame (`On that same data`, `That route takes`, `In that design`).
- 2026-08-24: T5 — one repair. `vignettes/interval-methods.Rmd` row 67: the `"mpl"` boundary promise re-bound to the cells where the two-way Monte-Carlo default aborts. `data-raw/mpl-doc-claims.tsv` row `0e83d1125bf2` removed in the same commit (its quote was the widened clause). Also repaired on its own merits, per the Scope's cheap-in-place clause: `R/icc.R` `@param level` described the conflated diagnostic as "agreement-only, complete crossed designs", which `R/estimand.R:87-102` (both `type` forms) and `R/icc.R:1178-1183` ("`type` flows through unfiltered") plus the incomplete-conflated path at `R/icc.R:1486` falsify; now "crossed random-rater designs, balanced or incomplete", matching the Details section. No other claim was found false on its own merits.

- 2026-08-24: T6 (partial) — AC2's R-diff command returns 0 lines. AC4 green: `NOT_CRAN=true CI=true devtools::test()` reports FAIL 0, WARN 2, SKIP 26, PASS 8561; all four `check-references` checkers pass at base and `--self-test`. AC3 on the two repaired files: zero dashes; over-35 sentences 2 in `R/icc.R` and 1 in `vignettes/interval-methods.Rmd`, and a clause match for the pinned 58-word residual clause returns exactly those three plus the one in `vignettes/glossary.Rmd`, so the carrier set is AC3's four. Two criteria enumerations came up short against what the work needed, and the amendment gate is open on both: AC2 admits a re-pointed pin anchor in `data-raw/*.R` but the pin that needed re-pointing is `data-raw/mpl-doc-claims.tsv`; and AC3 binds the ruler to every touched file, which the drafted `NEWS.md` entry cannot meet, that file never having been in the prose standard's surface (90 over-35 sentences, 95 dashes at baseline). NEWS entry drafted in the tree pending that gate.

## Decisions
<!-- owner: implement / review · append-only -->

- 2026-08-24 (T5): the `"mpl"` boundary sentence in `vignettes/interval-methods.Rmd`
  is repaired by restoring the replaced text's scope in new wording, not by
  reverting: the pre-M135 sentence carried a semicolon splice the pass removed.
  The repair also drops the `data-raw/mpl-doc-claims.tsv` row keyed on the
  widened clause. That row existed only because M135's wording created a
  trigger-carrying sentence; the restored wording enumerates as no candidate
  (`check-mpl-doc-claims.py` reports 60 candidates, 0 failures), so the row is
  removed rather than re-keyed.

## Review
<!-- owner: review · exclusive -->
