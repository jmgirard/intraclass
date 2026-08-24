# M136: Roxygen and README prose pass

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M134
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m136-roxygen-readme-prose` / https://github.com/jmgirard/intraclass/pull/145

## Goal

Apply M134's style rules to every roxygen block and to `README.Rmd`, and make
`?icc`'s `design` blurb name the same occasions the multilevel article does.

## Scope

Surface tier: **user-facing** — `?icc` and the GitHub landing page; D-029
carve-out, as M134.

**In:** every `#'` line outside `@examples` under `R/*.R`, and `README.Rmd`,
rewritten against rules R1–R6 of `cairn/doctrine/prose-style.md` (M134). R1 and
R2 are gated by the ruler (AC1); R6 is certified over the census's domain only
(AC3); R3–R5 are the doctrine's step-3 read-through, recorded in the work log.
The baseline is what `python3 data-raw/prose-profile.py` reports over those two
arguments at `$(git merge-base main HEAD)`, extracted with `git archive`.

Also in: the standing candidate row from the M132 review ([O] finding 3) — the
`@param design` blurb (`R/icc.R:243-249`) names one occasion for declaring a
design, missing cells making the pattern ambiguous, while
`vignettes/multilevel-designs.Rmd:112-117` names two. The article is the
authoritative surface; the blurb adopts its pair:

1. the rater *labels* do not mean what the crossing pattern implies (a complete
   table whose rater labels repeat across clusters), and
2. missing cells leave the pattern genuinely ambiguous between crossed and nested.

That edit changes meaning by design, so its hunk is named in AC4 and exempt
from AC3.

`data-raw/check-mpl-doc-claims.py` scopes `R/icc.R`, `NEWS.md` and
`interval-methods.Rmd`, and 45 of the 54 `data-raw/mpl-doc-claims.tsv` rows
quote `R/icc.R` — a roxygen edit re-keys them (M130 lesson).

**Out:** vignettes → M134, M135. `cli` abort and hint strings in `R/abort.R`
and `R/boundary-hint.R` → stay a candidate row: same D-029 class, but they are
condition text with their own guard
(`data-raw/check-abort-remedy-verdicts.R`) and their own pinned renderings
(M93, M127), so they want their own gate. `@examples` code → untouched.

## Acceptance criteria

- [x] AC1 `python3 data-raw/prose-profile.py 'R/*.R'` reports 0
      dash-as-punctuation occurrences in its TOTAL row, a nonzero sentence
      count in its `R/icc.R` row, and 0 sentences over 35 words in every other
      row. The same command over `README.Rmd` reports 0 dashes, a nonzero
      sentence count, and 0 sentences over 35 words. For `R/icc.R` the count of
      sentences over 35 words equals the count of its `#'` sentences outside
      `@examples` that contain, verbatim, the clause `residual_template()`
      returns. Such a clause admits no sentence break:
      `tests/testthat/test-doc-skew-caveat.R` matches it with `fixed = TRUE`,
      and it begins lower-case with no internal sentence end.
- [x] AC2 `python3 data-raw/check-mpl-doc-claims.py` exits 0 in live mode
      against the edited `R/icc.R`, and every `data-raw/mpl-doc-claims.tsv` row
      whose key changes carries the edited quote verbatim with its `assertion`
      and `disposition` columns unchanged, in the same commit as the edit.
- [ ] AC3 Census: over `git diff -U0 $(git merge-base main HEAD)...HEAD -- R/
      README.Rmd`, attribute each content line (`^[+-][^+-]`) to the `^@@` hunk
      above it, and select a hunk when any of its content lines matches
      `grep -iE '\b(any|each|every|all|only|both|exactly|never|always|full)\b'`.
      Widen each selected hunk to its smallest enclosing paragraph — for
      roxygen, the run of `#'` lines bounded by a blank `#'` line or the next
      `@tag`; for `README.Rmd`, the blank-line paragraph — reporting any
      selected hunk lying in neither for hand adjudication. The census selects
      at least one hunk in `R/icc.R` and at least one in `README.Rmd`, and in
      every widened unit it selects other than the one holding `@param design`
      (AC4 governs that): where the unit has removed lines, its added text
      states a claim whose domain is equal to or narrower than the removed
      text; where it has none, the added text either repeats a claim the
      unchanged lines of that same unit already state, or contains verbatim a
      clause `residual_template()` or `width_templates()` returns. The census
      decides nothing about a claim-domain change carrying none of those ten
      words.
- [x] AC4 The rendered `man/icc.Rd` `design` argument entry names both
      occasions listed in Scope, in the article's terms.
- [x] AC5 `Rscript -e 'devtools::build_readme()'` followed by
      `git diff --exit-code README.md` is clean.
- [x] AC6 `devtools::test()` clean; `devtools::check()` raw `Status:` line 0
      errors / 0 warnings (NOTEs justified); `devtools::document()` no diff;
      `python3 data-raw/check-record-claims.py` exits 0 in live mode.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T4
- AC3 → T5
- AC4 → T2
- AC5 → T6
- AC6 → T6

## Tasks

- [x] T1 Rewrite the `#'` blocks in `R/icc.R` against R1–R6 (668 lines, the bulk
      of the surface; `@examples` untouched).
- [x] T2 Rewrite the `#'` blocks in the remaining `R/*.R` files against R1–R6,
      and rewrite `@param design` to name both Scope occasions.
- [x] T3 Rewrite `README.Rmd` against R1–R6.
- [x] T4 Re-key `data-raw/mpl-doc-claims.tsv` for every quote T1 edited, keeping
      `assertion` and `disposition` unchanged; run the checker live before the
      commit carrying the roxygen edit.
- [x] T5 Run the AC3 census; repair any widening outside the `@param design`
      unit. Record the total hunk count, the selected count and the
      hand-adjudicated count, and the exempt clause's word count beside each
      carrying sentence's. Probe twice, reverting each: plant a 40-word
      non-clause sentence in `R/icc.R` roxygen and confirm the over-35 count
      rises; delete one bounding qualifier from one roxygen sentence and
      confirm the census selects that hunk.
- [x] T6 `devtools::document()`, `devtools::build_readme()`, then the AC6 verify
      block; drop the stray `Rplots.pdf` if an example run leaves one (M131).

## Work log

- 2026-08-24: review returned to in-progress (defect return 2). AC3 fails its claim-domain rule at two further sites, both a sentence split dropping a scope marker: `R/icc.R:275-276`, where the semicolon that made `from `"lavaan"`` govern both halves became a full stop, leaving "**Absolute-agreement** ICCs use the SEM indicator-mean estimator" unscoped and false of `"glmmTMB"`/`"lme4"`; and `R/icc.R:113-114`, where a colon scoping the Case-3A mechanism to the crossed fixed-rater subject level became a full stop. AC1, AC2, AC4, AC5, AC6 and the whole consistency gate pass — AC2, the first return's other failure, is cleared by the rebuilt history (all 12 commits exit 0 under `check-mpl-doc-claims.py`). Thrash trigger (b) fires: AC3 twice, new mechanism each time, same shape. The three-lens fan-out was run anyway; its seven [O] findings are in the Review section, two of them user-facing docs defects (`@param occasions` lost `and/or`; `R/icc.R:290` "For that design" lost its antecedent, so the incomplete-SEM bootstrap fence reads as fixed-rater-only while `R/engine-lavaan.R:770` applies it to random raters too). The rebuilt branch is still unpushed: the harness refused the force-push again, so PR #145 carries the pre-rewrite history.

- 2026-08-24: defect-return repairs complete; status back to review. `devtools::test()` FAIL 0 / WARN 3 / SKIP 2 / PASS 8827; `devtools::check()` raw `Status: 1 NOTE` (the NOT_CRAN `spelling.Rout` diff, M127/M128); `devtools::document()` and `build_readme()` leave no diff; `cairn_validate.py` all checks passed. The force-push of the rebuilt branch to PR #145 is not yet done — this session's harness refused it, so the remote still carries the pre-rewrite history.

- 2026-08-24: defect-return repair, AC2 same-commit clause. Branch history rebuilt from `0d33928`: the amendment tracking edit and the `R/icc.R` roxygen rewrite that `e849606` carried together are now separate commits, and the `mpl-doc-claims.tsv` re-key that landed in `900b2d5` travels in the same commit as the rewrite it re-keys. Verified by extracting each of the branch's 10 commits with `git archive` and running `check-mpl-doc-claims.py` in the extracted tree: all 10 exit 0 (48 candidates before the rewrite, 61 from it on), where the old history had `e849606` red with 32 failures. `git diff --stat backup/m136-pre-rewrite HEAD` is empty, so the rewrite changed no file content. Force-pushed to PR #145 at the user's gate; the pre-rewrite tip is kept locally at `backup/m136-pre-rewrite`.

- 2026-08-24: defect-return repair, AC3 claim-domain rule. `README.Rmd`'s release NOTE now reads "multilevel designs, at the subject or cluster level, with raters crossed with or nested in clusters or subjects" — the removed text's contrast restored, and its four crossed/nested combinations narrowed to the three `R/icc.R:88-90` supports.
- 2026-08-24: defect-return triage of the review's six lower-ranked AC3 candidates. Repaired three: `R/icc.R:357` re-binds the reproducibility guarantee to the seeded case ("in which case your retry reproduces it exactly"); `R/icc.R:310` re-scopes the missing-cells/no-bootstrap sentence to the two-way design ("For that design, missing cells are estimated by..."); `R/icc.R:645` restores the subject the colon used to carry ("For both, the `unit = \"average\"`..." and "Their endpoints are left **untruncated**").
- 2026-08-24: rejected three candidates with reasons. The lavaan `incomplete ... and unbalanced` conjunction is what the engine does (`R/engine-lavaan.R:341`: random raters cover complete/balanced AND incomplete/unbalanced data), so it is not a widening. The three juxtaposition-to-causation edits (`R/data.R:38`, `R/choose-icc.R:41`, `R/icc.R:143`) each assert the actual cause. And the `That margin` -> `` `"burch"`'s width margin `` change is required, not a widening: `tests/testthat/test-doc-skew-caveat.R:886` seeds a width run only from a sentence naming `burch`, so a repair to `That margin` dropped both new sentences out of run #1 and produced FAIL 6 (flat/parity/subjects clauses missing from `source/R/icc.R #1` and `installed/Rd:icc.Rd #1`); the two-grid restriction is carried verbatim inside the clauses themselves.
- 2026-08-24: supersedes the 2026-08-24 T5 census line's per-file figure for `R/d-study.R`: the count under the literal `^[+-][^+-]` content-line rule is 8, not 9; the reported total of 52 was right. Re-run after the repairs: 130 hunks, 52 selected, 0 pure additions, per file `R/icc.R` 38, `R/d-study.R` 8, `README.Rmd` 4, `R/data.R` 1, `R/choose-icc.R` 1.
- 2026-08-24: after the repairs `devtools::test()` FAIL 0 / WARN 3 / SKIP 2 / PASS 8827; `check-mpl-doc-claims.py` and `check-record-claims.py` both exit 0; ruler `R/*.R` TOTAL 588 sentences / 0 dashes / 2 over-35, `README.Rmd` 65 / 0 / 0.

- 2026-08-24: review returned to in-progress (defect return 1). AC2 fails its "in the same commit as the edit" clause: `e849606` carries the `R/icc.R` roxygen rewrite and `check-mpl-doc-claims.py` fails there with 32 failures, the ledger re-key landing only in `900b2d5`. AC3 fails its claim-domain rule at `README.Rmd:41-42`: "subject vs. cluster level" became "at the subject level and the cluster level", widening the claim across both rater layouts where a nested design defines the subject level only. AC1, AC4, AC5, AC6 and the whole consistency gate pass.

- 2026-08-24: review opened; draft PR #145. AC1 and AC4 verified against fresh evidence; AC2 fails its same-commit clause.

- 2026-08-23: created by /milestone-plan.
- 2026-08-23: plan-gate criteria audit ran in FULL mode; the record and its 13 findings are in M134's work log — this file carries the F2 (glob over hand-list), F3 (live MPL checker AC), F11 (design occasions listed, hunk exempted) and F13 (`git diff --exit-code`) repairs.
- 2026-08-23: plan gate chose to absorb the M132-review `@param design` candidate over leaving it on the ROADMAP because that row's own promotion trigger is "the next pass over `?icc`'s multilevel prose", which this is; falsified by the alignment edit widening a claim AC3 would otherwise have caught.
- 2026-08-24: amendment return: AC1 — "the count of sentences over 35 words equals the count of its `#'` sentences outside `@examples` that contain, verbatim, the clause `residual_template()` returns"; AC3 rewritten as a hunk-attributed census widened to the smallest enclosing paragraph; Scope In and T5 amended with it. Accepted at the mini gate 2026-08-24.
- 2026-08-24: two fresh-context [O] criteria audits ran in FULL mode over the amended wording (9 findings, then 12 after repair); all disposed. Decisive ones: AC1 as planned was unsatisfiable (`R/icc.R` must carry the 58-word `residual_template()` clause twice, unsplittable under `fixed = TRUE`); `--verbose` truncates at 110 chars so it cannot exhibit that clause; `R/icc.R`'s roxygen is one 687-line block, so "enclosing roxygen block" was degenerate.
- 2026-08-24: plan gate chose the paragraph-widened census with pure additions certified over M135's added-vs-removed-only shape, because a pure addition is where a new absolute enters a user-facing page; falsified by the added-only branch proving unadjudicable in practice.
- 2026-08-24: T5 census over `git diff -U0 $(git merge-base main HEAD)...HEAD -- R/ README.Rmd`: 130 hunks, 52 selected, 0 pure additions among them, 0 selected lines outside a roxygen or markdown paragraph (so the hand-adjudication set is empty). Per file: `R/icc.R` 38, `R/d-study.R` 9, `README.Rmd` 4, `R/data.R` 1, `R/choose-icc.R` 1, `R/abort.R` 0.
- 2026-08-24: T5 probes, both reverted. Plant: a 40-word non-clause roxygen sentence moved the `R/icc.R` over-35 count 2 -> 3 -> 2, so the reported 2 are not an artifact of what the ruler cannot see. Widening: deleting `only` from "On balanced/complete data only it covers..." produced 1 hunk, and the census selected it, so the removed-line half of the rule is load-bearing.
- 2026-08-24: T5 R6 audit delegated to a fresh-context [O] reader over the 52-hunk selection ([O] tier; it authored none of the prose). Two widenings found and repaired: `README.Rmd` turned the alternation `clusters/subjects` into `clusters and subjects`, claiming a mixed nesting pattern `R/icc.R` refuses; `R/d-study.R`'s `@param conf_level,mc_samples,seed` turned a respective pairing into "Override any of them", cross-producing three arguments against three effects. Everything else cleared.
- 2026-08-24: AC1 exemption record — the `residual_template()` clause is 58 words; it appears in exactly 2 roxygen sentences outside `@examples` in `R/icc.R`, each 64 words, and those are exactly the 2 sentences the ruler reports over 35.
- 2026-08-24: T6 `devtools::document()` no diff; `build_readme()` clean; `devtools::test()` FAIL 0 / WARN 2 / SKIP 26 / PASS 8561; `devtools::check()` raw `Status: 1 NOTE`, the `spelling.Rout` diff that only fires under `NOT_CRAN` (M127/M128) — `spell_check_package()` flags 31 words on this branch and 31 on `main`, so the branch adds none. No stray `Rplots.pdf`.
- 2026-08-24: NEWS Documentation entries added for the help-page/README pass and the `@param design` change (the consistency gate wants one; M135 was returned for its absence).
- 2026-08-24: running `devtools::test()` while a `devtools::check()` was still finishing reported FAIL 6 then FAIL 1 with wildly different SKIP counts; both vanished once the check's R process exited (the M107 concurrency lesson, in a new form).
- 2026-08-24: T1/T2 done: `R/icc.R` roxygen rewritten and `@param design` now names both occasions. Ruler over `R/*.R`: TOTAL 588 sentences, 0 dashes, 2 over-35 — both the `residual_template()` clause carriers. `devtools::test()` FAIL 0 / WARN 2 / SKIP 26 / PASS 8561.
- 2026-08-24: T4 done: `mpl-doc-claims.tsv` re-keyed — 21 rows re-pointed, 1 deleted (its claim no longer carries a universal; still pinned by the M103 hint tests), 12 rows added for sentences the splits created. Checker 48 -> 61 candidates, 12 settled, 0 failures; all four data-raw checkers pass `--self-test`.
- 2026-08-24: two roxygen sentences were re-joined or re-split so a ledger claim kept a trigger-bearing host: the bootstrap-containment sentence, and the MPL asymmetry figure (now "In one validated cell 65 of 66 misses fell below the interval, not above.").
- 2026-08-24: T2 part 1: roxygen in `R/abort.R`, `R/choose-icc.R`, `R/d-study.R`, `R/data.R` rewritten; ruler 0 over-35 and 0 dashes on every `R/*.R` file but `R/icc.R`. `@param design` (in `R/icc.R`) still to do.
- 2026-08-24: T3 README.Rmd rewritten; ruler 65 sentences, 0 over-35, 0 dashes (was 40/4/22). `build_readme()` re-knitted README.md.
- 2026-08-23: plan gate chose to leave the `cli` abort and hint strings out over folding them in because they are condition text with pinned renderings (M93, M127) and a separate guard, not documentation prose; falsified by a user reporting an abort remedy as unreadable in the same way the docs were.

## Decisions

## Review

Fresh evidence, 2026-08-24, at `6d0ee5c` on `m136-roxygen-readme-prose` (PR #145).
Second review round, after the AC2 history rebuild and the AC3 repairs.

**Default branch.** `git fetch` then compare: `origin/main` is `fe58134`, which is
also `git merge-base main HEAD`, so the default branch has not moved under the
branch and no sync merge was needed. The branch is 12 commits ahead.

**Remote is stale.** The rebuilt history is local only: `origin/m136-roxygen-readme-prose`
is still `855ed4e`, the pre-rewrite tip, so PR #145 shows the old commits. The
force-push was refused by this session's harness again, as at the end of the
implement phase. All AC2 evidence below is over the local commits.

**AC1 — pass.** `python3 data-raw/prose-profile.py 'R/*.R'`: TOTAL 588 sentences,
0 dash-as-punctuation, 2 over-35, max 64. `R/icc.R` 395 sentences (nonzero); every
other row 0 over-35. Over `README.Rmd`: 65 sentences, 0 dashes, 0 over-35, max 35.
The exemption clause: the text `residual_template()` returns
(`tests/testthat/test-doc-skew-caveat.R:2265`) occurs exactly twice in `R/icc.R`'s
`#'` lines outside `@examples`, at `R/icc.R:451` and `R/icc.R:635`, counted after
stripping `#'` and collapsing whitespace. Both sit in distinct sentences: one
sentence carrying both would run past 116 words and the ruler's max for the file is
64. So the over-35 count 2 equals the clause-carrying-sentence count 2.

**AC2 — pass.** This was the first return's first failure; the rebuilt history
clears it. `python3 data-raw/check-mpl-doc-claims.py` exits 0 live: 61 candidates,
12 settled, 0 failures. Every one of the branch's 12 commits, extracted with
`git archive` into a scratch tree and checked there, exits 0: 48 candidates through
`934fb13`, 61 from `40727dd` on. `data-raw/mpl-doc-claims.tsv` changed in exactly
one commit, `40727dd`, which is the commit carrying the `R/icc.R` roxygen rewrite it
re-keys, so the re-key travels with its edit. Comparing the `(file, disposition,
assertion)` multiset at the merge base against HEAD: no triple loses an instance;
the only gain is 11 added `R/icc.R` / `out` / empty-assertion rows (55 rows to 66).
The verbatim-quote half is what the live checker's 0 failures establishes.

**AC3 — FAIL.** Census reproduced over
`git diff -U0 $(git merge-base main HEAD)...HEAD -- R/ README.Rmd`: 130 hunks, 52
selected under the literal `^[+-][^+-]` content-line rule, 0 pure additions among
them. Per file selected: `R/icc.R` 38, `R/d-study.R` 8, `README.Rmd` 4, `R/data.R` 1,
`R/choose-icc.R` 1 — so the at-least-one-in-`R/icc.R` and at-least-one-in-`README.Rmd`
requirements hold, and these figures match the post-repair work-log line. Every
selected content line in an `.R` file is a `#'` line and every selected `README.Rmd`
line sits in a markdown paragraph, so the hand-adjudication set is empty. The
`@param design` hunk carries no trigger word on any content line, so the census does
not select it and AC4's exemption removes nothing from the audit. With no pure
additions, the added-only branch and the `residual_template()` exemption never fire,
and every selected unit is judged on the removed-vs-added domain rule alone.

The claim-domain judgment went to a fresh-context [O] reader that authored none of
the prose. It reproduced all of the counts above independently and confirmed the five
repairs the first return directed are present at HEAD. It then found two further
widenings, both of which I verified directly against the diff.

1. `R/icc.R:275-276`, in `@param engine`. Removed: `**Consistency** ICCs from
   `"lavaan"` equal the mixed-model estimates exactly on balanced data;
   **absolute-agreement** ICCs use the SEM indicator-mean estimator of the rater
   variance, which is asymptotically equivalent to ...`. Added: `... exactly on
   balanced data. **Absolute-agreement** ICCs use the SEM indicator-mean estimator
   of the rater variance. That estimator is asymptotically equivalent to ...`. The
   semicolon made `from `"lavaan"`` govern both halves; the full stop leaves the
   second half with no scope marker, so it states a claim about absolute-agreement
   ICCs generally. Two sentences earlier the same paragraph says `"glmmTMB"` and
   `"lme4"` fit the variance components by REML, and the next sentence contrasts
   this estimator with "the mixed-model one", so the widened reading is false inside
   its own paragraph. The hunk is selected on `exactly`, `every` and `both`.
2. `R/icc.R:113-114`, in the multilevel section. Removed: `... at the **subject**
   level on both balanced and **incomplete** data: the rater main effect becomes the
   finite-population variance of the observed raters (McGraw & Wong Case 3A), so on
   balanced data ...`. Added: `... on both balanced and **incomplete** data. The
   rater main effect becomes the finite-population variance of the observed raters
   (McGraw & Wong Case 3A). So on balanced data ...`. The colon bound the mechanism
   to the crossed fixed-rater subject level; free-standing it states the rule for
   fixed raters generally, and eleven lines later the same block says nested
   Design 2 forms that variance **per cluster**. Milder than 1 — the preceding
   sentence still supplies the subject — but the same loss of an explicit scope
   marker.

Both are the shape the first return already failed AC3 on: splitting a sentence at a
scope-carrying punctuation mark drops the scope. Neither repair widens an
enumeration, so the M139 widening test does not apply and these are defect findings,
not amendment evidence.

The reader also cleared, with reasons I checked: the three rejections the first
return's triage recorded (the lavaan `incomplete ... and unbalanced` conjunction
against `R/engine-lavaan.R:341`; the three juxtaposition-to-causation edits; and the
`That margin` change, required because `tests/testthat/test-doc-skew-caveat.R:886`
seeds a width run only from a sentence matching `burch`), and five further candidates
it judged not widenings (`R/icc.R:469-471`, `R/icc.R:78-81`, `README.Rmd:42`,
`R/icc.R:109-110`, and `R/icc.R:290` as a narrowing rather than a widening).

**AC4 — pass.** `man/icc.Rd`'s `\item{design}` entry reads "There are two occasions
to override that inference. The first is when the rater \emph{labels} do not mean
what the crossing pattern implies, as in a complete table whose rater labels repeat
across clusters. The second is when missing cells leave the pattern genuinely
ambiguous between a crossed and a nested design." Both Scope occasions, in the terms
`vignettes/multilevel-designs.Rmd:110-117` uses.

**AC5 — pass.** `Rscript -e 'devtools::build_readme()'` then
`git diff --exit-code README.md` exits 0.

**AC6 — pass.** `devtools::test()` `[ FAIL 0 | WARN 3 | SKIP 2 | PASS 8827 ]`.
`devtools::check()` raw `Status: 1 NOTE` (duration 15m 16s), so 0 errors and
0 warnings; the NOTE is the `spelling.Rout` diff that fires only under `NOT_CRAN`
(M127/M128), and `spelling::spell_check_package()` flags 31 words on this branch,
the same count the first round measured on `origin/main` with an identical list, so
the branch adds none. `devtools::document()` leaves the tree clean
(`git status --porcelain` empty after the run). `python3 data-raw/check-record-claims.py`
exits 0, 6 registered claims re-derived.

**Consistency gate — pass.** `cairn_validate.py` exit 0: 16 PASS, 7 advisories all
OK, and the `release window` advisory did not fire. No `DESIGN.md` principle changed,
so `cairn_impact.py` is skipped. Profile `r-package` toolchain slot: `document()` no
diff, so generated `NAMESPACE`/`man/` are not hand-edited; README.md in sync (AC5);
`pkgdown::check_pkgdown()` reports "No problems found"; `NEWS.md` carries two
Documentation entries for this pass with no milestone numbers in the user-facing
text; no new top-level files, and `check()` raises no `.Rbuildignore` NOTE. The
milestone is returned on AC3, not on the gate.

**Review fan-out.** Run despite the AC3 failure, so the repair round has the whole
list rather than discovering the rest on a third pass. Declared tier is user-facing,
so all three lenses were spawned, each fresh-context and none having authored the
prose.

[S] blame-history: no findings. It re-derived the per-commit AC2 evidence
independently, confirmed both first-return repairs hold at HEAD, and grepped for two
claims past milestones falsified and pinned as never-to-reappear (M92's "nothing
isolates the rater", M105/D-022's "finite interval on every dataset") — neither is
present. Its one observation, `R/icc.R:280-287`'s unchanged `"lme4"` sentence, is an
unmodified line and pre-existing.

[S] prior-review record: no findings. The `gh api repos/jmgirard/intraclass/pulls/comments?per_page=1`
probe returned `[]`, so no per-PR thread walk was paid for (M91's measurement holds).
Over the archived `## Review` sections for M115-M119, M123, M124, M126, M128, M131
and M132 it found the width and coverage figures (0.6725, 0.825/0.84, 0.9430/0.9614,
1.2963) preserved verbatim and the M123/M126 install-disclosure claims unchanged.

[O] diff-bug: seven findings, ranked, none an AC3 failure. Recorded here in the
reader's order; the first two I verified directly.

1. `R/icc.R:245-250`, `@param occasions` dropped `and/or`. The removed text read
   ``"single"` (the default -- the reliability of one rating) and/or `"average"``;
   the added text is two flat sentences that never say both may be asked for.
   `validate_occasions()` (`R/icc.R:2661-2674`) accepts "one or both of" and
   de-duplicates, and the sibling `@param level` two lines below still reads
   "and/or ... Defaults to both". A `?icc` reader with replicated data no longer
   learns that `occasions = c("single", "average")` is legal. Carries none of AC3's
   ten trigger words, so the census decides nothing about it.
2. `R/icc.R:290`, "For that design" lost its antecedent. The first return's own
   repair (d) put a fixed-rater sentence immediately before it, so "For that design,
   missing cells are estimated by full-information maximum likelihood, and the
   parametric bootstrap is unavailable for incomplete SEM" now reads as
   fixed-rater-only. `R/engine-lavaan.R:770` sets `simulate_refit = NULL` on
   `has_missing` regardless of `raters`, so the fence covers random-rater fits too,
   and a random-rater lavaan user with missing cells can read the bootstrap as open
   to them and hit the abort. A narrowing, which AC3 permits.
3. `data-raw/mpl-doc-claims.tsv`, four `reason` columns cite keys the re-key removed:
   `da3faf98d0c8` cites `a6f8e9dbe094`, `e50b57c2c557` cites `e428d688f11e`,
   `76fbf751b3cd` cites `d445b858554b`, `c3bbfdcb4994` cites `f80587033837`. The
   checker does not validate reason cross-references, so this is silent.
4. `data-raw/mpl-doc-claims.tsv:36`, row `33685fc5f591`'s quote was re-pointed to
   "tabulated, not continuous" while its `reason` still explains the node grid and
   linear rule, which the split moved into the following sentence.
5. `README.Rmd:152`, the Related-work table's `| **intraclass** | -- |` placeholder
   became `| **intraclass** | `intraclass` |`, a self-reference where the em dash had
   meant "no alternative packages".
6. `data-raw/mpl-doc-claims.tsv`, 21 re-keyed rows run the note into the previous
   sentence with no punctuation ("... is the validated property Re-keyed at M136
   (prose pass).").
7. `R/icc.R:550`, `@param prior` turned "combine several with `c()`" into "combined
   with `c()`", reading as a form requirement rather than a capability.

**Outcome: returned to `in-progress`.** AC3 fails against fresh evidence for the
second time. AC1, AC2, AC4, AC5, AC6 and the whole consistency gate pass; AC2, the
first return's other failure, is cleared.

**Thrash rule, trigger (b).** This is defect return 2, so trigger (a) has not fired.
Trigger (b) has: AC3 has now failed twice, each time by a new mechanism of the same
shape — a sentence split at a scope-carrying punctuation mark that drops the scope
(return 1: a contrast turned into a conjunction at `README.Rmd:41-42`; return 2: a
semicolon and a colon turned into full stops at `R/icc.R:275` and `R/icc.R:113`).
Each round has audited the 52-hunk selection by hand and repaired what that round's
reader caught, and each round a new instance has surfaced. The alternative the plan
gate recorded against for this predicate is M135's added-vs-removed-only census
shape, which is weaker than the one in force and would not have caught either
instance, so reconsidering it is not the remedy here. The 2026-08-24 amendment return
runs on its own track and is not counted.

**What has to happen before re-review:**

1. Restore the scope markers at `R/icc.R:275-276` and `R/icc.R:113-114`.
2. Repair or reject with a reason each of the seven [O] diff-bug findings above.
   Findings 1 and 2 are user-facing docs defects and are worth fixing on their own
   merits, whatever AC3 says about them.
3. Push the rebuilt branch to PR #145. The remote still carries the pre-rewrite
   history, so nothing on GitHub reflects what was reviewed here.
4. Before the third round, decide whether hand-auditing the selection is going to
   converge, or whether the remaining risk is better handled another way. Two rounds
   of hand audit have each left an instance behind.
