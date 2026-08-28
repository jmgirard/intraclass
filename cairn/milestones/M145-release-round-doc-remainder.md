<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M145: The v0.1.0 release-round documentation remainder

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP8
- **Branch/PR:** `m145-release-round-doc-remainder`

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

- [ ] AC1 `NEWS.md`'s *Confidence intervals* section states, above the bullet
      beginning "Which of the two closed forms", that `"searle"` and `"burch"`
      are the two classical closed forms and that three simulation grids
      measure their widths: the smaller grid's 16 cells and the larger grid's
      64 cells, both drawing only the subject effects from the non-normal
      family, and a third drawing the residual from the same family as the
      subject effect. The two counts are those `tests/testthat/fixtures/classical-width-by-cell.tsv`
      holds (`grid == "m76"`, `grid == "m113"`); the third grid's description
      is that of `tests/testthat/fixtures/width-reversal-by-cell.tsv`, whose
      cell count is deliberately not stated (it is blocked, not flat).
- [ ] AC2 Each of the five referring expressions M142's review round 2 recorded
      as antecedent-less — `the two closed forms`, `both grids`,
      `the smaller grid`, `the larger grid`, `the three grids` — first occurs
      in `NEWS.md` at a line at or after the line AC1 adds.
- [ ] AC3 `NEWS.md`'s *Engines* section states three facts about the brms
      engine, each derived from the shipped roxygen rather than composed: the
      sourced half-*t*(4, 0, 1) prior on every random-effect standard deviation
      (`R/icc.R:556-558`); that a custom `prior` warns and voids the coverage
      results (`R/icc.R:558-561`); and that the point estimate is the posterior
      mode and the interval a percentile credible interval
      (`R/icc.R:322-323`).
- [ ] AC4 `cairn/DECISIONS.md` gains exactly one new entry, superseding D-019's
      "documented in NEWS" clause and naming the surfaces that do document that
      abort (`R/icc.R:482`, `man/icc.Rd:360`, `R/ci-mpl.R:204`). D-019's own
      text is byte-identical to its text at `2076e1f`.
- [ ] AC5 `tests/spelling.R` passes `error = TRUE`, and on the branch head
      `Rscript -e 'spelling::spell_check_package(".")'` reports no spelling
      errors.
- [ ] AC6 On the branch head: `devtools::test()` reports 0 FAIL and no WARN
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
- [ ] T3 Add the brms guarantees to `NEWS.md`'s *Engines* section, reading
      `R/icc.R:322-323` and `R/icc.R:552-561` in this session and writing from
      what they say. Add a pin in `tests/testthat/` that reds when any of the
      three facts is removed from the installed `NEWS.md` — every documented
      claim gets a test, and these three are claims about engine behavior.
- [ ] T4 Append the superseding D-entry to `cairn/DECISIONS.md`. Decision and
      rationale only; no derived measurements in the entry.
- [ ] T5 Flip `tests/spelling.R` to `error = TRUE`; run
      `spelling::spell_check_package(".")` and `devtools::test()` and confirm
      both green. Do not pad `inst/WORDLIST`.
- [ ] T6 Run the gate: `devtools::test()`, `devtools::check()` (vignettes
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

## Decisions

## Review
