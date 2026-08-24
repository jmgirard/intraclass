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
- [ ] AC2 `python3 data-raw/check-mpl-doc-claims.py` exits 0 in live mode
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

Fresh evidence, 2026-08-24, at `be1e38c` on `m136-roxygen-readme-prose` (PR #145).

**AC1 — pass.** `python3 data-raw/prose-profile.py 'R/*.R'`: TOTAL 588 sentences,
0 dash-as-punctuation, 2 over-35, max 64. `R/icc.R` 395 sentences (nonzero); every
other row 0 over-35. Over `README.Rmd`: 65 sentences, 0 dashes, 0 over-35, max 35.
The exemption clause: the 58-word text `residual_template()` returns occurs exactly
twice in `R/icc.R`'s `#'` lines outside `@examples` (counted after stripping `#'`
and collapsing whitespace). Both occurrences sit in distinct sentences — a single
sentence carrying both would run to at least 116 words, and the ruler's max for the
file is 64 — so the over-35 count 2 equals the clause-carrying-sentence count 2.

**AC2 — FAIL on the same-commit clause.** The other two clauses hold:
`python3 data-raw/check-mpl-doc-claims.py` exits 0 live (61 candidates, 12 settled,
0 failures), all 41 re-keyed rows carry their quote verbatim under the checker's own
`normalize()` and scope extraction, and no `(file, disposition, assertion)` triple
present at the merge base is absent from the edited ledger (the only new triples are
11 added `R/icc.R`/`out`/empty-assertion rows). But the re-key did not travel with
the edit. Running the checker against each branch commit extracted with `git archive`:
`dba21ad`, `139a285`, `0d33928` OK (48 candidates); `e849606` **FAIL, 32 failures**
(6 stale keys, 15 out-rows whose quote no longer exists, 11 uncovered claims);
`900b2d5` OK (61); `be1e38c` OK (61). `e849606` carries a 456-line `R/icc.R` roxygen
rewrite under a commit message naming only the criteria amendment, and the ledger
re-key lands one commit later in `900b2d5`.

**AC3 — FAIL.** Census reproduced over
`git diff -U0 $(git merge-base main HEAD)...HEAD -- R/ README.Rmd`: 130 hunks, 52
selected under the literal `^[+-][^+-]` content-line rule, 0 pure additions among
them. Per file selected: `R/icc.R` 38, `R/d-study.R` 8, `README.Rmd` 4, `R/data.R` 1,
`R/choose-icc.R` 1, `R/abort.R` 0 — so the at-least-one-in-`R/icc.R` and
at-least-one-in-`README.Rmd` requirements hold. The T5 work-log line records
`R/d-study.R` 9, which does not sum to its own reported 52; 8 does. With no pure
additions, the added-only branch and the `residual_template()` exemption never fire,
and every selected unit is judged on the removed-vs-added domain rule alone.

The claim-domain judgment went to a fresh-context [O] reader that authored none of
the prose. It re-ran the census independently (130 hunks; 52 under the literal rule,
53 if markdown bullet lines whose diff prefix is `+-`/`--` are also counted; it
audited all 53), confirmed 0 selected lines lie outside a roxygen block or a markdown
paragraph so the hand-adjudication set is empty, and confirmed the `@param design`
unit is not selected by the regex, so AC4's exemption removes nothing from the audit.
It confirmed both widenings the T5 pass repaired are repaired at HEAD.

It then found a further widening, which I verified directly against the diff.
`README.Rmd:41-42`, inside the release NOTE block on the GitHub landing page:

    removed: multilevel designs (subject vs. cluster level, with raters crossed
             with or nested in clusters/subjects)
    added:   multilevel designs, at the subject level and the cluster level, with
             raters crossed with or nested in clusters or subjects

`subject vs. cluster level` is a contrast; `at the subject level and the cluster
level` is a conjunction, and it now distributes across both the crossed and the
nested rater layouts. `R/icc.R:88-90` states that a nested design defines the
subject level only, and restricts `level` to `"subject"` there. So the added text
states a claim whose domain is wider than the removed text, which is exactly what
AC3 forbids — and it is the same alternation-to-conjunction defect as the
`clusters/subjects` repair made two words later in the same sentence.

Six further candidates the reader ranked below it, reported here and left to triage:
(2) `R/icc.R:357-359`, a reproducibility guarantee de-parenthesized from `(your
retry reproduces it exactly)` to a coordinate clause, loosening its binding to the
seeded case — the next sentence still limits it; (3) `R/icc.R:313-315` lavaan
`incomplete ... or unbalanced` -> `incomplete ... and unbalanced`; (4)
`R/icc.R:308-310`, a lavaan parenthetical scoped to the two-way design promoted to
a free-standing sentence covering all of lavaan; (5) `R/icc.R:443`, `That margin`
-> `` `"burch"`'s width margin ``, dropping the named two-grid antecedent;
(6) `R/icc.R:645-647`, a shared-convention list item promoted to a sentence whose
subject no longer names the two methods; (7) three juxtapositions turned into
asserted causation (`R/data.R:38`, `R/choose-icc.R:41-42`, `R/icc.R:143-144`), which
the reader judged substantively correct. The reader also flagged, out of AC3 scope,
that `R/icc.R:285-287`'s unchanged `"lme4"` line already asserts the same
crossed-and-nested-at-both-levels cross-product that finding 1 introduces.

**AC4 — pass.** `man/icc.Rd`'s `\item{design}` entry reads "There are two occasions
to override that inference. The first is when the rater \emph{labels} do not mean
what the crossing pattern implies, as in a complete table whose rater labels repeat
across clusters. The second is when missing cells leave the pattern genuinely
ambiguous between a crossed and a nested design." — both Scope occasions, in the
terms `vignettes/multilevel-designs.Rmd:110-117` uses.

**AC5 — pass.** `Rscript -e 'devtools::build_readme()'` then
`git diff --exit-code README.md` exits 0: README.md is in sync with README.Rmd.

**AC6 — pass.** `devtools::test()` `[ FAIL 0 | WARN 3 | SKIP 2 | PASS 8827 ]`; the
three warnings are lavaan's "some estimated lv variances are negative" surfaced
through `cli_warn()` at `R/engine-lavaan.R:415`, engine behaviour the suite exercises
deliberately, not new. `devtools::check()` raw `Status: 1 NOTE`, so 0 errors and 0
warnings. The NOTE is the `spelling.Rout` diff that fires only under `NOT_CRAN`
(M127/M128): `spelling::spell_check_package()` flags 31 words on this branch and 31
on `origin/main`, and the two sorted word lists are identical, so the branch adds
none. `devtools::document()` produces no diff (`git status --porcelain` after the run
names only this milestone file). `python3 data-raw/check-record-claims.py` exits 0
(6 registered claims re-derived, 0 failures).

**Consistency gate.** `cairn_validate.py` exit 0 — 16 PASS, 7 advisories all OK; the
`release window` advisory did not fire. No `DESIGN.md` principle changed, so
`cairn_impact.py` is skipped. Profile `r-package` toolchain slot: `document()` no
diff (recorded above); generated `NAMESPACE`/`man/` therefore not hand-edited;
README.md in sync (AC5); `pkgdown::check_pkgdown()` reports "No problems found";
NEWS.md carries two Documentation entries for this pass, with no milestone numbers in
the user-facing text; no new top-level files, and `devtools::check()` raises no
`.Rbuildignore` NOTE. The gate's toolchain half passes; the milestone is returned on
AC2 and AC3, not on the gate.

**Outcome: returned to `in-progress`.** Two criteria fail against fresh evidence —
AC2's same-commit clause and AC3's claim-domain rule. Both are defect returns
(neither repair widens an enumeration, so the M139 widening test does not apply).
This is the first defect return on this milestone; the 2026-08-24 amendment return
runs on its own track. The step-5 review fan-out was not spawned: the branch has to
change to clear AC2, so a diff review now would be reviewing a diff that will be
recommitted.

**What has to happen before re-review:**

1. Make the ledger re-key travel with the roxygen edit it re-keys, so no commit on
   the branch leaves `check-mpl-doc-claims.py` red. Today only `e849606` is red.
   `e849606` also carries the T1 `R/icc.R` rewrite under a message naming only the
   criteria amendment, so separating the amendment from the rewrite and folding the
   ledger re-key into the rewrite commit fixes both the criterion and the message.
2. Repair the `README.Rmd:41-42` widening — restore the contrast the removed text
   drew between the subject and cluster levels, rather than conjoining them across
   both rater layouts.
3. Triage the six lower-ranked AC3 candidates above, repairing or rejecting each
   with a reason.
