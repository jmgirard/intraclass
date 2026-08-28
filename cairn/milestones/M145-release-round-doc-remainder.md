<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M145: The v0.1.0 release-round documentation remainder

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP8
- **Branch/PR:** `m145-release-round-doc-remainder` / https://github.com/jmgirard/intraclass/pull/156

## Goal

Close the documentation debts the v0.1.0 release round left open, so the
shipped release notes stand on their own and the spelling gate can fail.

## Scope

Surface tier: **user-facing**. Three of the four deliverables are shipped
surfaces — `NEWS.md` prose and `tests/spelling.R`, which guards the prose in
`NEWS.md`, the vignettes and the Rd files; only the decision-record correction
is internal, so the milestone is classified by the wider of the two.

**In:**
- `NEWS.md` *Confidence intervals*: an orienting sentence naming the two
  classical closed forms and the three simulation grids, so the surviving width
  bullets have antecedents. M142 cut the bullets that introduced them.
- `NEWS.md` *Engines*: the brms engine's documented guarantees, which the M142
  condensation dropped down to the bare `"posterior"` string.
- A superseding `DECISIONS.md` entry: D-019's Consequences says its
  perfect/near-perfect-agreement abort is "documented in NEWS", and that NEWS
  text is gone. The abort is documented — at `R/icc.R:482` and in the message
  built at `R/ci-mpl.R:204` — so the record is stale, not the package.
- `tests/spelling.R`: `error = FALSE` → `error = TRUE`, so an unlisted word
  can red a run. Measured clean on `main` 2026-08-28.

**Out:**
- The CRAN submission walk itself → `/cairn-release`, after this merges.
- The two test-suite defects (`render_condition()` glue re-interpolation; the
  three `devtools::test()` WARNs) → they stay the existing candidate row;
  both are invisible to `R CMD check` and neither blocks submission.
- A mechanical guard that every NEWS referring expression has an antecedent →
  the "Three prose-apparatus deferrals" candidate row, item (c). Barred by
  D-021, which D-029 does not exempt for apparatus.
- The ROADMAP byte-budget prune → this milestone's post-merge hygiene pass,
  at the maintainer's direction (2026-08-28).

## Acceptance criteria

- [x] AC1 `NEWS.md`'s *Confidence intervals* section states, above the bullet
      beginning "Which of the two closed forms", that `"searle"` and `"burch"`
      are the two classical closed forms and that three simulation grids
      measure their widths: the smaller grid's 16 cells and the larger grid's
      64 cells, both drawing only the subject effects from the non-normal
      family, and a third drawing the residual from the same family as the
      subject effect. The two counts are those `tests/testthat/fixtures/classical-width-by-cell.tsv`
      holds (`grid == "m76"`, `grid == "m113"`); the third grid's description
      is that of `tests/testthat/fixtures/width-reversal-by-cell.tsv`, whose
      cell count is deliberately not stated (it is blocked, not flat).
- [x] AC2 Each of the five referring expressions M142's review round 2 recorded
      as antecedent-less — `the two closed forms`, `both grids`,
      `the smaller grid`, `the larger grid`, `the three grids` — first occurs
      in `NEWS.md` at a line at or after the line AC1 adds.
- [x] AC3 `NEWS.md`'s *Engines* section states three facts about the brms
      engine, each derived from the shipped roxygen rather than composed: the
      sourced half-*t*(4, 0, 1) prior on every random-effect standard deviation
      (`R/icc.R:556-558`); that a custom `prior` warns and voids the coverage
      results (`R/icc.R:558-561`); and that the point estimate is the posterior
      mode and the interval a percentile credible interval
      (`R/icc.R:322-323`).
- [x] AC4 `cairn/DECISIONS.md` gains exactly one new entry, superseding D-019's
      "documented in NEWS" clause and naming the surfaces that do document that
      abort (`R/icc.R:482`, `man/icc.Rd:360`, `R/ci-mpl.R:204`). D-019's own
      text is byte-identical to its text at `2076e1f`.
- [x] AC5 `tests/spelling.R` passes `error = TRUE`, and on the branch head
      `Rscript -e 'spelling::spell_check_package(".")'` reports no spelling
      errors.
- [x] AC6 On the branch head: `devtools::test()` reports 0 FAIL and no WARN
      beyond the three the ROADMAP candidate row records; `devtools::check()`
      run with vignettes built reports `Status: OK` on its raw Status line
      (read raw, not from the 0/0/0 summary); each of the six `data-raw/`
      checkers passes, run with `--self-test` where it offers one; and
      `awk -f data-raw/m142-bullet-lines.awk NEWS.md` reports no bullet over
      500 bytes except the 797-byte mpl anchor bullet.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T6

## Tasks

- [x] T1 Derive the grid facts before writing them (GP8): count
      `grid == "m76"` and `grid == "m113"` rows in
      `tests/testthat/fixtures/classical-width-by-cell.tsv`, and read the
      residual-draw description from `width-reversal-by-cell.tsv`'s header
      comment. Record the two counts and the command in the work log.
- [x] T2 Add the orienting text to `NEWS.md` as its own bullet ABOVE the
      "Which of the two closed forms" bullet — never inside the three width
      bullets, which are byte-adjacent to the `test-doc-skew-caveat.R` pins.
      Phrase the counts as `the smaller grid's 16 cells` /
      `the larger grid's 64 cells` so the existing `grid_size` walk pattern
      (`tests/testthat/test-doc-skew-caveat.R:1391`) derives them from the
      fixture; confirm that walk's surface set includes `NEWS.md` and extend
      it if not. Then `grep -n` the five AC2 strings and check the ordering.
- [x] T3 Add the brms guarantees to `NEWS.md`'s *Engines* section, reading
      `R/icc.R:322-323` and `R/icc.R:552-561` in this session and writing from
      what they say. Add a pin in `tests/testthat/` that reds when any of the
      three facts is removed from the installed `NEWS.md` — every documented
      claim gets a test, and these three are claims about engine behavior.
- [x] T4 Append the superseding D-entry to `cairn/DECISIONS.md`. Decision and
      rationale only; no derived measurements in the entry.
- [x] T5 Flip `tests/spelling.R` to `error = TRUE`; run
      `spelling::spell_check_package(".")` and `devtools::test()` and confirm
      both green. Do not pad `inst/WORDLIST`.
- [x] T6 Run the gate: `devtools::test()`, `devtools::check()` (vignettes
      built, raw Status line), the six `data-raw/` checkers with
      `--self-test`, `air format .`, and the bullet-size awk. Re-measure the
      awk after any prose fix made at the gate, not only after the last
      content commit.

## Work log

- 2026-08-28: created by /milestone-plan.
- 2026-08-28: criteria audit ran in FULL mode (user-facing tier), in-session rather than in a fresh-context [O] subagent, because agent delegation is not authorized in this session; that is a departure from the instrument the gate specifies. It returned one finding: AC2 as first drafted also required the `grep -n` output be recorded in the Review section, an instrument property rather than a property of `NEWS.md`; the recording clause was moved to T2 and AC2 narrowed to the ordering. AC2's domain was deliberately narrowed to the five expressions M142's review recorded, since "no antecedent-less reference in NEWS" is not enumerable by any stated procedure.
- 2026-08-28: plan gate chose narrowing AC2 to M142's recorded five expressions over a mechanical antecedent checker, because such a checker is apparatus over this repo's own prose, which D-021 bars and D-029 declines to exempt; falsified by a user reaching an antecedent-less claim in the shipped notes that the recorded five do not cover.
- 2026-08-28: plan gate chose stating the two grid cell counts in NEWS over an unpinned qualitative phrasing, because the existing `grid_size` walk pattern derives both from the committed fixture, so the counts are procedural rather than hand-pinned (GP8); falsified by the walk turning out not to cover `NEWS.md` and not being cheaply extendable, in which case the qualitative phrasing is the fallback.
- 2026-08-28: plan gate included the `tests/spelling.R` flip despite its D-021-adjacent framing in the candidate row, because the row's own promotion condition ("or on the next release round") is met by the window the maintainer declared today, and D-029 puts shipped user-facing prose outside D-021's subject; falsified by the flip reddening CI on prose no user reads.
- 2026-08-28: measured on `main` before planning — `spelling::spell_check_package(".")` reports no spelling errors; `awk -f data-raw/m142-bullet-lines.awk NEWS.md` reports 17 bullets, one over 500 bytes (797, the mpl anchor); `R CMD check` on a `--no-build-vignettes` tarball reports 2 WARNINGs, both artifacts of that build flag (`inst/doc` absent), so a vignette-building check is expected clean.
- 2026-08-28: T1 — `awk -F'\t' 'NR>1{c[$1]++} END{for (g in c) print g, c[g]}' tests/testthat/fixtures/classical-width-by-cell.tsv` gives m76 = 16 rows, m113 = 64 rows. `width-reversal-by-cell.tsv`'s header says both the subject effect A_i and the residual e_ij are drawn from `dist`, located and scaled per burch2011 sec 3 — the third grid's residual-draw description.
- 2026-08-28: T2 — orienting bullet added above the "Which of the two closed forms" bullet (`NEWS.md:74-77`, 300 bytes). The `test-doc-skew-caveat.R` surface set already carries `NEWS.md` on both legs, so no extension was needed; its `grid_size` and `n_grids` shapes consume the new figures. Discrimination checked: `16` -> `15` in the new bullet reds that file; restored. The residual-draw sentence is a separate sentence carrying no "grid", so it does not seed the residual walk, which requires its own verbatim clause.
- 2026-08-28: T3 — brms bullet added to NEWS *Engines* (own bullet, chosen at the implement gate over folding into the existing engine bullet), written from `R/icc.R:320-323` and `R/icc.R:554-561` read this session. Pinned by the new `tests/testthat/test-news-brms-claims.R`, which slices the *Engines* section out of the installed `NEWS.md` and requires a tolerant pattern per fact (phrase patterns chosen at the implement gate over verbatim sentences). Discrimination: each of the three facts deleted in turn reds exactly that expectation; the anti-vacuity control (section found, non-empty, carrying the glmmTMB sentence) is stated independently of all three. `devtools::test()`: FAIL 0, WARN 3 (the three the candidate row records), SKIP 2, PASS 9121.
- 2026-08-28: T4 — D-043 appended to `cairn/DECISIONS.md`. All three surfaces it names were read this session (`R/icc.R:482`, `man/icc.Rd:360`, `R/ci-mpl.R:204`); D-019 untouched.
- 2026-08-28: T5 — `tests/spelling.R` flipped to `error = TRUE`. `spelling::spell_check_package(".")` reports no spelling errors, so `inst/WORDLIST` gained nothing. Discrimination: `Rscript spelling.R` from `tests/` exits 0 clean and exits 1 naming the word on a planted misspelling in `NEWS.md`; the plant was reverted.
- 2026-08-28: T6 — gate on the branch head: `devtools::test()` FAIL 0, WARN 3 (the three the candidate row records), SKIP 2, PASS 9121; `devtools::check()` with vignettes built reports `Status: OK` on its raw Status line (0 errors, 0 warnings, 0 notes, 12m 45s); all six `data-raw/` checkers pass, five of them under `--self-test` (`check-abort-remedy-verdicts.R` offers none and passes plain); `air format --check .` clean; `awk -f data-raw/m142-bullet-lines.awk NEWS.md` reports one bullet over 500 bytes, the 797-byte mpl anchor, the two new bullets at 300 and 355. D-019 verified byte-identical to its text at `2076e1f` (3,600 bytes).
- 2026-08-28: T5 correction — running `spelling.R` locally wrote `tests/spelling.Rout.save`, which the T4-T5 commit swept in; `R CMD check` then compared the test's output against it. Removed and gitignored: it is not what makes the gate red (`error = TRUE` is, shown by the planted misspelling) and a committed output transcript is a cross-platform check hazard. The gate was re-run on the corrected head.
- 2026-08-28: gate re-run on the corrected head (`b1ee51f`): `devtools::check()` with vignettes built reports `Status: OK`, 0 errors / 0 warnings / 0 notes. `spelling::spell_check_test()` writes `spelling.Rout.save` into whatever test directory it runs in, so `R CMD check` still reports the comparison and still passes it; the file being gitignored changes nothing in the check, only what the repo carries.
- 2026-08-28: review correction, superseding the T6 line's bullet sizes — the two new bullets measure 300 and 398 bytes, not 300 and 355; `NEWS.md` had not changed since T3 (`f791045`), so 355 was wrong when written. AC6's predicate is unaffected.
- 2026-08-28: fixed at the merge gate — `NEWS.md`'s brms bullet said the engine "fits the random-rater model" while `R/icc.R:327-335` documents it covering three fixed-rater designs as well; widened to "both random- and fixed-rater models" and pinned as a fourth claim in `tests/testthat/test-news-brms-claims.R`.

## Decisions

## Review

Reviewed 2026-08-28 on branch head `dc05186`, PR #156. All evidence below is
fresh — re-run this session, not carried from the implement work log.

**Departure from the specified instrument.** The declared tier is user-facing
and the diff touches executable surface (`tests/spelling.R`,
`tests/testthat/test-news-brms-claims.R`), so the gate specifies a
three-lens fresh-context fan-out. Agent delegation is not authorized in this
session, so the three lenses were run in-session by the reviewing orchestrator
instead. Same departure the plan phase recorded on 2026-08-28.

### Acceptance criteria

- **AC1 — pass.** `NEWS.md:80-83` carries the orienting bullet; the
  "Which of the two closed forms" bullet begins at `NEWS.md:84`, so the new
  text is above it. It names `"searle"` and `"burch"` as the two classical
  closed forms, says three grids measure their widths, gives the smaller
  grid's 16 cells and the larger grid's 64 cells as drawing only the subject
  effects from the non-normal family, and describes the third as drawing the
  residual from the same family as the subject effect, with no cell count.
  `awk -F'\t' 'NR>1{c[$1]++} END{for (g in c) print g, c[g]}'
  tests/testthat/fixtures/classical-width-by-cell.tsv` re-derives m76 = 16 and
  m113 = 64. `width-reversal-by-cell.tsv`'s header states both `A_i` and
  `e_ij` are drawn from `dist`, which is the third grid's description. Both
  figures are procedural, not hand-pinned: the `grid_size` shape at
  `tests/testthat/test-doc-skew-caveat.R:1392` derives them from the fixture
  by `min`/`max` of the per-grid row counts, and `n_grids` at `:1359` derives
  the three.

- **AC2 — pass.** `grep -n` for each of the five expressions, first hit only:
  `the two closed forms` 84, `both grids` 85, `the smaller grid` 81,
  `the larger grid` 81, `the three grids` 80. AC1's bullet occupies
  `NEWS.md:80-83`, so every first occurrence is at or after line 80. Nothing
  earlier in the file matches any of the five.

- **AC3 — pass.** `NEWS.md:56-61` (the *Engines* section's brms bullet) states
  the sourced half-*t*(4, 0, 1) prior on every random-effect standard
  deviation, that the point estimate is the posterior mode and the interval a
  percentile credible interval with `ci_method = "posterior"` forced, and that
  a custom `prior` makes `icc()` warn and voids the coverage results. Each was
  read back against the shipped roxygen this session: the prior and the
  custom-prior cost at `R/icc.R:553-561` (`@param prior`), the summary and
  interval kind at `R/icc.R:322-323` (`@details`). Derivation, not
  composition: every load-bearing term in the NEWS sentences appears in the
  roxygen. The pin `tests/testthat/test-news-brms-claims.R` was verified to
  RUN, not skip, against a real install (`R CMD INSTALL` to a scratch library;
  6 expectations, 0 failed, skipped FALSE) and to discriminate: each of the
  three facts deleted in turn from the installed `NEWS.md` reds exactly one
  expectation, and the restored control is clean at 0 failed.

- **AC4 — pass.** `git diff main...HEAD -- cairn/DECISIONS.md` adds exactly one
  `### D-` heading (D-043) and removes no line. D-043 states that D-019's
  "documented in NEWS" clause no longer holds and names `R/icc.R:482`,
  `man/icc.Rd:360` and `R/ci-mpl.R:204`; all three were read this session and
  each carries the degenerate-fit / near-perfect-agreement abort. D-019's own
  text extracted from `2076e1f:cairn/DECISIONS.md` and from the branch head is
  byte-identical, 3,601 bytes both sides. `check-record-claims.py`'s
  `no-citations-in-decisions` rule passes, so the entry quotes no claim token.
- **AC5 — pass.** `tests/spelling.R` reads `error = TRUE`.
  `Rscript -e 'spelling::spell_check_package(".")'` on the branch head reports
  "No spelling errors found." Discrimination re-run this session: the clean
  tree exits 0 with "All Done!", and with `delibberate devviation` planted in
  `NEWS.md` the same run fails as
  `Error: Potential spelling errors: delibberate, devviation` followed by
  `Execution halted` — the identity `spell_check_test(error = TRUE)` signals,
  not some other failure. The plant was reverted; the tree is clean.

- **AC6 — pass.** On branch head `dc05186`:
  `devtools::test()` reports `FAIL 0 | WARN 3 | SKIP 2 | PASS 9121`, the three
  WARNs being the lavaan and glmmTMB fitting diagnostics and the fixed-rater
  advisory the ROADMAP candidate row records, so none beyond them.
  `devtools::check(vignettes = TRUE)` reports `Status: OK` on its raw Status
  line, read from the check log rather than the summary, with 0 errors,
  0 warnings, 0 notes in 18m 31s; the log contains no NOTE, WARNING or ERROR
  token anywhere. All six `data-raw/` checkers pass:
  `enumerate-generalizing-claims.py --check` (367 candidates, 367 ledger rows,
  0 un-triaged, 0 orphans), `check-reference-observations.py` (67 runnable,
  0 unmarked, 0 falsified), `check-mpl-doc-claims.py` (60 candidates,
  12 settled, 0 failures), `check-record-claims.py` (7 claims re-derived,
  0 failures), `check-checkpoint-sites.R --self-test` (130 mutations over
  5 sites, each detected) and `check-abort-remedy-verdicts.R --self-test`
  (52 cells, 24 accepted, 0 broken promises). `awk -f
  data-raw/m142-bullet-lines.awk NEWS.md` reports 19 bullets, one over
  500 bytes and it is the 797-byte mpl anchor.

### Consistency gate

Universal cairn-file checks: `cairn_validate.py` exits 0 — 16 PASS, 7 advisory
OK, none fired, `release window` included. `cairn_impact.py` skipped: the diff
touches no `DESIGN.md` principle (no `DESIGN.md` change at all), so no
principle reference needs reconciling.

Toolchain checks, the `r-package` profile's `consistency-gate` slot:
`devtools::document()` leaves the tree clean, so `NAMESPACE`, `man/` and
`data/` show no hand-edit drift; `README.Rmd` is untouched by the diff and
`README.md` is in sync; `pkgdown::check_pkgdown()` reports "No problems
found."; `NEWS.md` carries this milestone's user-visible changes and names no
milestone number; the diff adds no top-level file, so no `.Rbuildignore` entry
is owed; `devtools::check()` is clean at 0/0/0. `air format --check .` exits 0.
CI on PR #156: `lint`, `format-check`, `pkgdown`, `checkpoint-guard` and
`check-references` all pass.

### Findings

Three lenses, run in-session per the departure noted above, each on a distinct
evidence base. Ranked most severe first.

**[O] diff-bug lens** — the full diff against the criteria, `DESIGN.md` and
`DECISIONS.md`.

1. `NEWS.md:56` says the brms engine "fits the random-rater model", but the
   shipped roxygen at `R/icc.R:327-335` also documents brms covering the
   two-way **fixed**-rater single-level design (Case-3A), the crossed Design 1
   multilevel fixed-rater design, and the nested Design 2 fixed-rater design.
   The release-notes sentence reads as though brms is random-rater only. It
   under-claims rather than over-claims, and the bullet above it points readers
   at *Estimation engines* and `?icc` for per-engine coverage — but it is a
   scope statement about a shipped engine in user-facing prose, which is why it
   ranks first.
2. The T6 work-log line records "the two new bullets at 300 and 355". The
   orienting bullet is 300 bytes and the brms bullet 398; `NEWS.md` has not
   changed since T3 (`f791045`), so 355 was wrong when written. AC6's predicate
   — no bullet over 500 but the named 797-byte anchor — holds either way.
3. `tests/testthat/test-news-brms-claims.R:22` asserts `expect_length(start,
   1L)` and then indexes with `start`. Were the `## Engines` heading absent or
   duplicated, the file would error inside `seq()` instead of reporting the
   clean expectation failure. The anti-vacuity control covers the case that
   matters in practice; this is an unreached branch.
4. The `posterior_summary` pattern uses an unbounded `.*` between "posterior
   mode" and "percentile credible interval" over the whole collapsed *Engines*
   section, so in principle the two halves could be satisfied by text in
   different bullets. Verified empirically to red on deletion, so the concern
   is theoretical.
5. The orienting bullet restates a fact the last width bullet already carries
   — that the third grid draws the residual from the same family as the
   subject effect — now stated twice, four bullets apart. AC1 required it.

**[S] blame-history lens** — `git log`/`git blame` on the modified lines.

6. `tests/spelling.R`'s `error = FALSE` dates to `6dc3daf`, the M0 scaffold
   bootstrap, and is `spell_check_test()`'s own default; no commit since argued
   for keeping it non-fatal. The flip changes a never-revisited default, not a
   recorded choice. The new NEWS text restores material M142 deleted
   deliberately, but M142's own review filed that deletion's remainder as the
   candidate row this milestone absorbed, so it is the recorded remedy rather
   than an undo. No regression found.

**[S] prior-review lens** — archived `## Review` sections on the touched files,
then the GitHub thread surface.

7. M128's archive corrected an M127 lesson that had claimed an in-tree
   `tests/spelling.Rout.save`, establishing the file is built at run time from
   `spelling`'s own template. The branch's `.gitignore` entry is consistent
   with that finding, and `spell_check_test()`'s source read this session
   confirms it writes the file into whatever test directory it runs in. No
   contradiction of a prior review's lesson on the touched files.
   `gh api repos/jmgirard/intraclass/pulls/comments` returns empty, so there is
   no GitHub inline-review surface to walk — as M91 measured.

**Return floor.** None of 1-7 demonstrates an acceptance criterion failing, so
none returns the milestone. Finding 1 is the only one touching what the
shipped docs tell a user; it goes to the maintainer at the gate.

### Fixed at the merge gate

Findings 1 and 2 were actioned at the maintainer's direction; 3, 4 and 5 were
rejected (3 and 4 are unreached branches in a pin verified to discriminate,
5 is what AC1 asked for), and 6 and 7 reported no regression.

Finding 1: `NEWS.md:56` now reads "fits both random- and fixed-rater models",
derived from `R/icc.R:325-337`, which documents brms covering the two-way
fixed-rater single-level (Case-3A), crossed Design 1 multilevel fixed-rater
and nested Design 2 fixed-rater designs alongside the random ones. The claim
is pinned as a fourth pattern in `tests/testthat/test-news-brms-claims.R`,
verified against a real install: 7 expectations, 0 failed, skipped FALSE; with
"both random- and fixed-rater models" reverted to "the random-rater model" in
the installed copy exactly one expectation reds, and the restored control is
clean.

Finding 2: corrected by a superseding work-log line, since work logs are
append-only.

Re-verification after the fix: `spelling::spell_check_package(".")` reports no
spelling errors; `awk -f data-raw/m142-bullet-lines.awk NEWS.md` reports
19 bullets, one over 500 bytes and it is the 797-byte mpl anchor (the brms
bullet grew 398 -> 411); `air format --check .` exits 0; all six `data-raw/`
checkers exit 0; `cairn_validate.py` exits 0. AC1-AC6 are unaffected: the
edit touches only the *Engines* section's first clause, and AC3's three facts
are unchanged and still pinned.

