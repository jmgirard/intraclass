# M136: Roxygen and README prose pass

- **Status:** review
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
R2 are gated by the ruler (AC1); R3–R5 are the doctrine's step-3 read-through,
recorded in the work log. The doctrine's step-5 R6 diff audit ran in every
round, and each round found a fresh widening, so it is on record as a search
that did not converge. Every widening it named is repaired, and no criterion
certifies R6 over the branch diff: that certification was descoped at the
return-3 gate (2026-08-24) and leaves M136 for the ROADMAP candidate row
"A mechanical check that a prose pass never widens a claim".
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

That edit changes meaning by design; AC4 states what the changed text must say.

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
- [x] AC3 *Descoped at the return-3 gate (2026-08-24). The R6 claim-domain
      census promises nothing here; it exits to the ROADMAP candidate row "A
      mechanical check that a prose pass never widens a claim". The number is
      held rather than reclaimed so the work log and the three recorded review
      rounds keep pointing at the criteria they were written against.*
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
- AC3 → T5 (descoped; T5 stands as performed history)
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
- [x] T5 Run the AC3 census (AC3 was descoped at the return-3 gate, 2026-08-24;
      T5 and T7 stand as performed history); repair any widening outside the `@param design`
      unit. Record the total hunk count, the selected count and the
      hand-adjudicated count, and the exempt clause's word count beside each
      carrying sentence's. Probe twice, reverting each: plant a 40-word
      non-clause sentence in `R/icc.R` roxygen and confirm the over-35 count
      rises; delete one bounding qualifier from one roxygen sentence and
      confirm the census selects that hunk.
- [x] T6 `devtools::document()`, `devtools::build_readme()`, then the AC6 verify
      block; drop the stray `Rplots.pdf` if an example run leaves one (M131).
- [x] T7 Exhaustive scope-punctuation sweep, the shape both AC3 returns failed on:
      enumerate every hunk of the AC3 diff whose removed text carries a semicolon
      or a mid-sentence colon the added text does not, and take a verdict on each
      from a fresh-context reader. Repair every widening it finds.

## Work log

- 2026-08-24: T6 re-run after the descope amendment and the fourteen repairs. `devtools::check(document = FALSE)` raw `Status: 1 NOTE` (14m 20s), so 0 errors and 0 warnings; the NOTE is the `spelling.Rout` vs `spelling.Rout.save` diff that fires only under `NOT_CRAN` (M127/M128), and its flagged set is the same 31 words `origin/main` carries, so the branch adds none. `devtools::test()` FAIL 0 / WARN 3 / SKIP 2 / PASS 8827. `devtools::document()` leaves `git status --porcelain` empty; `build_readme()` then `git diff --exit-code README.md` exits 0. `check-mpl-doc-claims.py` 61 candidates / 12 settled / 0 failures and `check-record-claims.py` 6 claims both exit 0; `cairn_validate` all checks passed. Ruler `R/*.R` TOTAL 590 sentences / 0 dashes / 2 over-35, `README.Rmd` 65 / 0 / 0. AC1's exemption re-derived by importing the ruler's own segmentation (`strip_roxygen` -> `paragraphs` -> `normalize` -> `sentences`): the over-35 set and the set carrying the 58-word clause `residual_template()` returns are the same two 64-word sentences. `man/icc.Rd`'s `design` entry still names both occasions (AC4). No stray `Rplots.pdf`. Status back to review.
- 2026-08-24: the nine [O] diff-bug findings from the third review round, all repaired, none rejected. (1) `NEWS.md`'s "Every help page and the README have been rewritten" was false — `git diff --name-only fe58134..HEAD -- R/` returns five files and four roxygen-bearing files are untouched (`R/autoplot.R` 19 `#'` lines, `R/icc-methods.R` 12, `R/reexports.R` 4, `R/intraclass-package.R` 2) — so it now reads "held to the same standard, and the ones that needed it rewritten". (2) the README related-work table's `**intraclass**` Packages cell reads `(this package)`, restoring the `--`'s "no entry" meaning without the `no alternatives` competitive claim, and the ruler still reports 0 dashes. (3) "Every design in that list comes with boundary-aware Monte-Carlo intervals" regains the four-item antecedent `Each` lost to the split. (4) the stray blank line at `data-raw/mpl-doc-claims.tsv:79` removed. (5) row `9c736d9cc49c`'s reason narrowed to its re-pointed parity clause, the canonical-template note attributed to the deleted row `b0864228b68f` it came from. (6) row `c4dea14d6d18`'s quote restored to "Each clears the pre-registered 0.93 floor there", the universal its `all(col('adequate'))` assertion exists to settle; the key hashes the whole sentence, so it does not move and `assertion`/`disposition` are untouched. (7) `R/icc.R`'s dangling "Unbalanced, use ..." reads "For a projection on unbalanced data, use `ci_method = \"montecarlo\"`". (8) `R/choose-icc.R:29` regains "The two structural facts". (9) `@param posterior_summary` announces "the default on two grounds", so ten Hove's coverage finding reads as the second ground. Ruler `R/*.R` TOTAL 590 / 0 dashes / 2 over-35, `README.Rmd` 65 / 0 / 0; `check-mpl-doc-claims.py` 61 candidates / 12 settled / 0 failures live and `--self-test` OK.
- 2026-08-24: the five R6 widenings the return-3 reader named, all repaired in `R/icc.R`. `@param model`: the three one-way clauses regain the frame the em dash carried ("In that design the `rater` column ...", "It has no rater main effect ..."), which `R/engine-glmmtmb.R:69` vs `:156` shows is false of the default two-way fit. `@section Estimand`: "In that case only their sum ... is estimable" restores the single-rating-per-cell frame the semicolon carried, which `R/icc.R:135-146` contradicts for within-cell replicates. `@param engine`: "That path is Monte-Carlo only: its fixed-rater bootstrap is not yet available" re-binds the reason to the lavaan multilevel path (`R/engine-lavaan.R:573-575` sets `simulate_refit = NULL` on `raters == "fixed"`), where the promoted `because` clause contradicted `R/icc.R:385-387`. The two unscoped-but-true sites also repaired: the k_eff divisor claim regains "On such data", and lavaan's consistency-ICC agreement regains "Its". Ruler `R/*.R` TOTAL 589 sentences / 0 dashes / 2 over-35; `check-mpl-doc-claims.py` 61 candidates / 12 settled / 0 failures, no re-key needed.
- 2026-08-24: amendment executing the return-3 descope, accepted at the mini gate. AC3 (the R6 claim-domain census) promises nothing and holds its number as a struck placeholder, because `cairn_validate`'s coverage check counts criteria positionally, so a deleted AC3 would force renumbering and break every work-log and Review reference to AC4, AC5 and AC6. The Scope In paragraph drops the certification clause, names the doctrine's R6 audit as the step-5 diff audit it actually is (the draft called it step 3), and records it as a search that did not converge; the `@param design` sentence drops its AC3 exemption; Coverage marks `AC3 -> T5` descoped; T5 gains a parenthetical so its AC3 reference resolves. AC1, AC2, AC4, AC5 and AC6 are unchanged, and no criterion is added or widened. The census exits to a ROADMAP candidate row, paid for by compressing three candidate rows (ROADMAP 23,991 / 24,000 bytes).
- 2026-08-24: criteria audit over the amended wording ran in FULL mode with a fresh-context [O] reader that authored none of it. Six findings: R6 misnamed as the doctrine's step 3 when `cairn/doctrine/prose-style.md:110-115` makes it step 5; the draft Scope claiming R6 treatment without saying the audit found unrepaired widenings; the three verified widenings left ownerless by the descope; `its hunk is named in AC4` vacuous once the census is gone (AC4 names a rendered `.Rd` entry, not a hunk); T5/T7 citing a criterion no live section would define. All fixed in the text below. The sixth confirms no surviving criterion depends on AC3, Coverage leaves none unmapped, and nothing in DESIGN.md or DECISIONS.md makes any of the five unreachable.

- 2026-08-24: disposition after defect return 3, chosen by the maintainer at the return gate: DESCOPE. M136 narrows to its five verified criteria (AC1, AC2, AC4, AC5, AC6) via the gated amendment protocol (`/milestone-implement` step 6); AC3 — the R6 claim-domain certification over the census — exits to a candidate row or a split milestone, that choice settled at the amendment gate. Park, `/milestone-brief` escalation and a same-objective re-cut were the other options offered and were not taken. The three user-facing [O] diff-bug findings (`NEWS.md:355`'s false universal, `README.Rmd:152`'s `no alternatives` cell, `README.Rmd:36-42`'s lost antecedent) are to be repaired in the same round whatever AC3's exit; the other six take triage there.

- 2026-08-24: review returned to in-progress (defect return 3). AC3 fails its claim-domain rule at three further sites, each a sentence split at a scope-carrying punctuation mark the earlier rounds' repairs and T7's semicolon/colon enumeration did not cover: `R/icc.R:211-213` (`@param model`), where an em dash bound three clauses to the `"oneway"` frame and the split leaves them unscoped and false of the default `"twoway"` fit (`R/engine-glmmtmb.R:69` vs `:156`); `R/icc.R:32-34` (`@section Estimand`), where a semicolon carried the single-rating-per-cell frame and the full stop drops it, making "Only their sum ... is estimable" false of within-cell replicates (`R/icc.R:135-146`); and `R/icc.R:307-308` (`@param engine`), where a parenthesis confined the fixed-rater-bootstrap-unavailable claim to the lavaan path and the promoted `because` clause contradicts `R/icc.R:385-387`. Two further widenings (`R/icc.R:93-97`, `R/icc.R:315-316`) are unscoped but true. AC1, AC2, AC4, AC5, AC6 and the whole consistency gate pass. Thrash rule: triggers (a) and (b) both fire; (a) governs the disposition (descope-or-park, no further retry under the current plan) and (b)'s `/milestone-brief` escalation offer carries into it. The three-lens fan-out was run anyway; [S] blame-history and [S] prior-review found nothing, and the nine [O] diff-bug findings are in the Review section, three of them user-facing (a false universal in `NEWS.md`, a `no alternatives` competitive claim in the README related-work table, and `Each comes with boundary-aware Monte-Carlo intervals` losing its four-item antecedent).

- 2026-08-24: T6 re-run after the return-2 and T7 repairs. `devtools::test()` FAIL 0 / WARN 3 / SKIP 2 / PASS 8827; `devtools::check()` raw `Status: 1 NOTE` (19m 21s), the `spelling.Rout` diff that fires only under `NOT_CRAN` (M127/M128), and `spelling::spell_check_package()` flags the same 31 words the review round measured on `origin/main`. `devtools::document()` and `build_readme()` leave no diff; `check-mpl-doc-claims.py` 61 candidates / 12 settled / 0 failures and `check-record-claims.py` 6 claims both exit 0; ruler `R/*.R` TOTAL 588 sentences / 0 dashes / 2 over-35 (both the `residual_template()` carriers, 64 words each), `README.Rmd` 65 / 0 / 0. No stray `Rplots.pdf`. Status back to review.

- 2026-08-24: checkpoint. T7's repairs are committed and `document()`/`build_readme()`/`check-mpl-doc-claims.py`/`check-record-claims.py` and both rulers are clean over them; the AC6 `devtools::test()` and `devtools::check()` runs are still pending, so T6's re-run is not yet recorded.

- 2026-08-24: T7 sweep. 76 of the 130 hunks lose a semicolon or a mid-sentence colon; a fresh-context [O] reader that authored none of the prose gave a verdict on every one. Two widenings, both verified against the code and repaired. `R/icc.R:298-304`: the semicolon run under "With **random** raters the multilevel fit covers..." had left "Incomplete or unbalanced data is Monte-Carlo only" free-standing, which `R/icc.R:386` and the eight `glmmtmb_simulate_refit()` attach sites contradict; the three clauses now read "For that random-rater two-level fit ...", "Its parametric bootstrap ...", "For that fit, incomplete or unbalanced data ...". `R/d-study.R:60-62`: "The **cluster** level is dropped with a note" now reads "On that same data the **cluster** level is dropped with a note", the condition `R/d-study.R:240` actually gates on (`!isTRUE(x$design$balanced)`). The other 74 cleared, four of them the sites earlier rounds repaired.
- 2026-08-24: AC3 census re-run after the T7 repairs: 130 hunks, 53 selected (was 52; the repaired `R/icc.R` engine region now carries a trigger word), 0 pure additions. Per file `R/icc.R` 39, `R/d-study.R` 8, `README.Rmd` 4, `R/data.R` 1, `R/choose-icc.R` 1.

- 2026-08-24: rebuilt branch force-pushed to PR #145 (`855ed4e` -> `b715492`), so the remote now carries the history the second review round read. The two earlier sessions' refusals did not recur.
- 2026-08-24: return-2 AC3 repairs. `R/icc.R:113` regains the scope the colon carried ("For that design and level, the rater main effect becomes..."); `R/icc.R:275` regains the one the semicolon carried ("**Absolute-agreement** ICCs from `"lavaan"` use the SEM indicator-mean estimator...").
- 2026-08-24: the seven [O] diff-bug findings, all repaired, none rejected. (1) `@param occasions` reads "Ask for `"single"` ... and/or `"average"`", the pairing `validate_occasions()` (`R/icc.R:2661`) accepts. (2) `R/icc.R:290` re-scoped to "In the two-way SEM, with either rater type" — `R/engine-lavaan.R:770` sets `simulate_refit = NULL` on `has_missing` regardless of `raters`, so the fence is not fixed-rater-only. (3) four `reason` cross-references re-pointed to the keys the M136 re-key produced: `a6f8e9dbe094` -> `27008f8106f5`, `e428d688f11e` -> `db49f7a5d983`, `d445b858554b` -> `074d24554b69`, `f80587033837` -> `95d6fb664816` and `a0390661cdc1`. (4) row `33685fc5f591`'s reason narrowed to its re-pointed quote, naming the node grid and linear rule as the following sentence's. (5) `README.Rmd`'s related-work table reads `no alternatives` where the em dash had meant it. (6) the run-on note punctuated in 24 rows (the review said 21; 5 more reasons already ended in a full stop). (7) `@param prior` reads "Several priors can be combined with `c()`" as its own sentence.
- 2026-08-24: implement gate chose the exhaustive scope-punctuation sweep (T7) over a third open-ended hand audit of the 52-hunk AC3 selection; the enumeration is 76 of the 130 hunks and contains all three sites the earlier rounds missed, so the search is closed rather than resting on a reader noticing. AC3 itself is unamended.

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

Fresh evidence, 2026-08-24, at `35a0931` on `m136-roxygen-readme-prose` (PR #145).
Fourth review round, over the narrowed criterion set the return-3 descope left:
AC1, AC2, AC4, AC5, AC6. AC3 is descoped and certifies nothing. The records of
rounds 1-3 are in git and summarized in the work log above.

**Default branch.** `git fetch`, then compare: `origin/main` is `fe58134`, which is
also `git merge-base main HEAD`, and `git log HEAD..origin/main` is empty, so the
default branch has not moved under the branch and no sync merge was needed.

**Remote.** `git push` reports "Everything up-to-date";
`origin/m136-roxygen-readme-prose` and local HEAD are both `35a0931`, so PR #145
carries exactly the reviewed history. PR #145 is open and still a draft.

**AC1 — pass.** `python3 data-raw/prose-profile.py 'R/*.R'`: TOTAL 590 sentences,
0 dash-as-punctuation, 2 over-35, max 64. `R/icc.R` 397 sentences (nonzero); every
other row 0 over-35. Over `README.Rmd`: 65 sentences, 0 dashes, 0 over-35, max 35.
The exemption clause was re-derived by importing the ruler's own segmentation
(`strip_roxygen` -> `paragraphs` -> `normalize` -> `sentences`) over `R/icc.R` and
matching the 58-word clause `residual_template()` returns as a literal substring:
the over-35 set and the carrier set are the SAME two sentences, 64 words each. So
the over-35 count 2 equals the carrier count 2, as AC1 requires.

**AC2 — pass.** Live mode: `python3 data-raw/check-mpl-doc-claims.py` exits 0,
61 claim candidates, 12 settled, 0 failures. Same-commit clause verified by
extracting each of the branch's 21 commits with `git archive` into a scratch tree
and running the checker there: all 21 exit 0 (48 candidates through `934fb13`, 61
from `40727dd` on). Three commits change ledger keys — `40727dd`, `7d2b3d8` and
`0707fb5` — and each carries `R/icc.R` in the same commit, so no key change travels
apart from its edit. Assertion/disposition preservation: comparing the
`(file, disposition, assertion)` multiset at the merge base against HEAD, no triple
loses an instance; the only gain is 11 added `R/icc.R` / `out` / empty-assertion
rows (55 rows to 66). Every data row parses to exactly 6 fields, and the blank line
the third round found is gone. The verbatim-quote half is what the live checker's
0 failures establishes.

**AC4 — pass.** `man/icc.Rd`'s `\item{design}` entry reads "There are two occasions
to override that inference. The first is when the rater \emph{labels} do not mean
what the crossing pattern implies, as in a complete table whose rater labels repeat
across clusters. The second is when missing cells leave the pattern genuinely
ambiguous between a crossed and a nested design." Both Scope occasions, in the terms
`vignettes/multilevel-designs.Rmd:110-117` uses.

**AC5 — pass.** `Rscript -e 'devtools::build_readme()'` then
`git diff --exit-code README.md` exits 0, and `git status --porcelain` is empty.

**AC6 — pass.** `devtools::test()` `[ FAIL 0 | WARN 3 | SKIP 2 | PASS 8827 ]`.
`devtools::check(document = FALSE)` raw `Status: 1 NOTE` (duration 19m 14.4s), so
0 errors and 0 warnings; the NOTE is the `spelling.Rout` vs `spelling.Rout.save`
diff that fires only under `NOT_CRAN` (M127/M128). Justified against a fresh
measurement rather than recall: `origin/main` extracted with `git archive` and
`spelling::spell_check_package()` run over both trees returns 31 flagged words on
each and `identical(sort(main), sort(branch))` is TRUE, so the branch adds none.
`devtools::document()` leaves `git status --porcelain` empty.
`python3 data-raw/check-record-claims.py` exits 0, 6 registered claims re-derived.
No stray `Rplots.pdf`.

**Consistency gate — pass.** `cairn_validate.py` exit 0: 16 PASS, 7 advisories all
OK, and the `release window` advisory did not fire. No `DESIGN.md` principle changed,
so `cairn_impact.py` is skipped. Profile `r-package` toolchain slot: `document()` no
diff, so generated `NAMESPACE`/`man/` are not hand-edited; README.md in sync (AC5);
`pkgdown::check_pkgdown()` reports "No problems found"; `NEWS.md` carries two
Documentation entries for this pass with no milestone numbers in the user-facing
text; no new top-level files (`git diff --diff-filter=A --name-only main..HEAD`
finds none at the root) and `check()` raises no `.Rbuildignore` NOTE.

**Review fan-out.** Declared tier is user-facing, so all three lenses were spawned,
each fresh-context, none having authored the prose, each with a distinct evidence
base.

[S] blame-history: no findings. It re-derived the diff against `git blame` and the
milestone archives and confirmed four deliberate past acts are intact — M92's struck
"nothing isolates the rater" claim has not returned, M105/D-022's struck "finite
interval on every dataset" claim has not returned (the text still reads "at the
near-zero-ICC boundary"), D-022's Burch near-zero-MSA asymmetry clause is preserved,
and the M117/M118 scope clause "the two grids that vary only the subject effect" is
named with its scope at all three sites. It spot-checked ~20 re-keyed ledger rows and
found each new quote a verbatim substring of its rewritten host with
`assertion`/`disposition` unchanged. Its one observation is about a work-log
paraphrase, not the deliverable, and is recorded as F11 below.

[S] prior-review record: no findings. The
`gh api repos/jmgirard/intraclass/pulls/comments?per_page=1` probe returned `[]`, so
no per-PR thread walk was paid for (M91's measurement holds). Over the recorded
review findings on the touched files it confirmed every third-round repair is
present in the current tree and none has regressed.

[O] diff-bug: ten findings, ranked, none of them an acceptance-criterion failure.
Recorded here in the reader's order with the disposition taken.

1. `NEWS.md:359`. Added: "Nothing about what the package computes or reports
   changed, and every claim the pass touched was checked against the text it
   replaced." The branch's own record says otherwise: Scope says the R6 diff audit
   "is on record as a search that did not converge" and "no criterion certifies R6
   over the branch diff", and the census adjudicated 53 of 130 hunks. This is the
   strongest user-facing claim on the changelog and it is the one thing the descope
   decided not to promise. The identical sentence in the two bullets above it is
   pre-existing M134/M135 text and out of scope; this instance is new.
2. `NEWS.md:355-357`. Added: "Every help page and the README have been held to the
   same standard, and the ones that needed it rewritten: long sentences split, ..."
   "and the ones that needed it rewritten" has no auxiliary, so a reader cannot tell
   whether the rewriting happened. The third-round repair traded a false universal
   for a broken clause.
3. `R/icc.R:566`, `@param posterior_summary`. Removed: "Percentile is the default
   because it is". Added: "Percentile is the default on two grounds. It is". The
   text that follows gives three properties (monotone-transformation invariance,
   graceful degradation at the variance boundary, and ten Hove et al.'s
   small-rater-count coverage finding), so the count is a new numeric assertion the
   removed text did not make and a reader counting gets three.
4. `R/icc.R:212`, `@param model`. Added: "In that design the `rater` column is used
   only to count the ratings per subject, and its labels are ignored. It has no
   rater main effect to model, so `type` does not apply". The intended antecedent of
   "It" is "that design"; the nearest candidates are "its labels" and "the `rater`
   column", so read literally the rater column has no rater main effect.
5. `R/icc.R:283-285`. Removed: "`\"lme4\"` covers every design `\"glmmTMB\"` does --
   two-way (random or fixed raters), one-way, and the multilevel designs (crossed
   and nested) at both levels -- on both balanced and **incomplete/ragged** data."
   Added: "`\"lme4\"` covers every design `\"glmmTMB\"` does, on both balanced and
   **incomplete/ragged** data: two-way (random or fixed raters), one-way, and the
   multilevel designs (crossed and nested) at both levels." The em-dash pair enclosed
   a gloss on "every design"; the colon now attaches the list to "data", so it reads
   as an enumeration of kinds of data.
6. `R/choose-icc.R:32-33`. Removed: "The choices that actually select the
   coefficient (`type`, `unit`, `raters`, and `level` when multilevel) have no silent
   default: in a non-interactive session, ...". Added: "The choices that actually
   select the coefficient have no silent default: `type`, `unit`, `raters`, and
   `level` when multilevel. In a non-interactive session, ...". The colon originally
   introduced the consequence; it now introduces a list sitting where a reader
   expects the defaults themselves.
7. `README.Rmd:42` / `README.md:33`. Removed: "or nested in clusters/subjects) --
   each with boundary-aware Monte-Carlo intervals." Added: "or nested in clusters or
   subjects. Every design in that list comes with boundary-aware Monte-Carlo
   intervals." The em-dash enumeration bound "each" to four items, one of which,
   "imbalanced and incomplete (missing-cell) data", is a data shape and not a design,
   so "Every design in that list" drops the interval guarantee for the shape the
   previous sentence has just promised coverage of.
8. `cairn/ROADMAP.md:4`. The hygiene line records "ROADMAP 23,991 / 24,000"; `wc -c`
   at HEAD returns 23,986. The figure was measured in `6077f58` and `35a0931` then
   shortened `in-progress` to `review` in the same file without updating it.
9. `data-raw/mpl-doc-claims.tsv` row `9c736d9cc49c`. The new `reason` reads
   "Re-keyed at M136 (prose pass) to the parity clause alone", but the quote is
   "which is also where every cell `\"searle\"` won sits", the searle-won clause and
   not the parity clause, so a future maintainer re-keying the row looks for the
   wrong span.
10. `R/icc.R:174`. Removed: "measured the default's coverage well below its nominal
    level across such data, worst at chi-square(1) subject effects ...". Added:
    "... across such data. It was worst at chi-square(1) subject effects ...". The
    reader reports "It" as lacking a noun.
11. [S] blame-history's observation: the work-log line for the third-round repair
    says the README sentence "regains the four-item antecedent `Each`", where the
    shipped text reads "Every design in that list comes with ...". A loose work-log
    paraphrase, not a content problem.

**Return floor.** None of the eleven demonstrates an acceptance criterion failing:
AC1, AC2, AC4, AC5 and AC6 all pass against the fresh evidence above, and AC3
promises nothing after the descope. Findings 1-7 and 9 are prose defects inside the
deliverable this milestone ships, which is why they are recommended fix-now rather
than follow-ups; none of them is a floor return, so the milestone is not returned
on them.

**Recommended triage, put to the maintainer at the approval gate.** Fix now:
1, 2, 3, 4, 5, 6, 7 and 9 — each a prose or claim defect inside the surface this
milestone exists to improve, each repairable without touching what the package
computes. Fix at the step-9 hygiene pass: 8, since that line is rewritten there
anyway. Reject: 10, because "It" resolves to "the default's coverage", the
sentence's own topic, and 11, because it is about a work-log paraphrase and not
about anything shipped.

**Disposition taken at the approval gate (2026-08-24).** The maintainer chose
"fix 1-7, 9 then merge". All eight are repaired on the branch at `b7c3475`, before
the approval marker. `NEWS.md` drops the "every claim the pass touched was checked
against the text it replaced" universal the descope had declined to promise and
reads "the ones that needed it have been rewritten"; `@param posterior_summary`
reads "on several grounds", asserting no count; `@param model` reads "That design
has no rater main effect to model"; the `"lme4"` coverage list is re-attached to
"every design" and the data clause moved to its own sentence; `choose_icc()`'s
selecting choices are named in an "are ..." sentence with "None of them has a
silent default." following; the README NOTE reads "Everything just listed comes
with boundary-aware Monte-Carlo intervals"; and ledger row `9c736d9cc49c`'s reason
names the searle-won clause it actually pins. Finding 8 is corrected in the
step-9 hygiene pass, which rewrites that line. Findings 10 and 11 rejected, with
the reasons above.

Re-verified over the repairs: ruler `R/*.R` TOTAL 592 sentences / 0 dashes /
2 over-35 with every other row 0, `README.Rmd` 65 / 0 / 0, and the AC1 exemption
identity still holds (the over-35 set and the clause-carrier set are the same two
64-word sentences). `check-mpl-doc-claims.py` 61 / 12 / 0 failures and
`check-record-claims.py` 6 claims both exit 0. `devtools::document()` and
`build_readme()` leave the tree clean and `git diff --exit-code README.md` exits 0.
`devtools::check(document = FALSE)` raw `Status: 1 NOTE` (20m 8.9s), the same
`NOT_CRAN` spelling diff, with the flagged word set still identical to
`origin/main`'s 31. `devtools::test()` `[ FAIL 0 | WARN 3 | SKIP 2 | PASS 8827 ]`.
`cairn_validate.py` all checks passed.
