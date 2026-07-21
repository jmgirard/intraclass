<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M73: Make every dated observation executable

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M71   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m73-executable-dated-observations · https://github.com/jmgirard/intraclass/pull/79   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Make every claim a references page makes about the repo's own state settled by
a re-runnable command rather than by a reader's care.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** the **87 dated observations** across the 30 source notes and
`INDEX.md` (measured 2026-07-19; only 2 currently carry a settling command).
Each is brought to a recorded convention — the claim carries inline the exact
command that settles it — or, where no command can settle it, is restated as a
standing fact about the source or removed. A **committed checker script**
re-runs every settling command and reports claim-vs-reality, exiting non-zero
on a falsified claim. A D-entry records the convention.

**Out:** `ORACLES.md` and `BIBLIOGRAPHY.md` → M72 owns those pages (if M72
lands first, it adopts this convention rather than M73 revisiting them).
Generalizing claims about a *source's* table ("the four lowest cells are all
at low `ρ`") → M74; they need a full-table recomputation, not a command.
The seven notes' source-fidelity (values, quotations, anchors) → M71.
A `cairn_validate` check enforcing the convention plugin-side → the cairn
repo, not this one.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] A `cairn/DECISIONS.md` entry defines the convention: what a dated
      observation must carry, what counts as a settling command, and what to
      do with a claim no command can settle.
- [x] A committed checker script re-runs every settling command in the
      references corpus and reports, per claim, the command and whether the
      claim holds. It **exits non-zero on a falsified claim** — the property
      being protected is that a false claim fails a run, not that a reader
      notices it.
- [x] The checker fails when a claim is falsified: demonstrated by mutating a
      true claim to a false one and showing the run go red, not by inspection
      (tracking-rules "a guard must fail when the rule it locks is deleted").
- [x] Every dated observation in the 30 source notes and `INDEX.md` either
      carries a settling command, or is restated as a standing fact about its
      source, or is removed — none is left asserting repo state on a reader's
      word.
- [x] The checker run is clean, and every claim it falsified along the way was
      corrected at its source with the correction's basis recorded.
- [x] No package value changes: any correction that would move an oracle
      value, test fixture, or documented behavior is escalated as a review
      finding with its citation, not silently applied.
- [x] `cairn_validate` passes and the r-package `verify` slot is clean.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4, T5, T6
- AC5 → T7
- AC6 → T4, T5, T6, T7
- AC7 → T8

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: draft the D-entry defining the convention; it governs the rest of
      the milestone, so it lands first. Settle there what to do with a claim
      that is true but not command-settleable (the honest options are
      restate-as-standing-fact or delete, not stamp-and-hope).
- [x] T2: write the checker script — parse the references corpus for dated
      observations, extract each settling command, run it, compare against the
      claim. Site it per repo convention alongside the other `cairn/scripts/`
      tooling or `data-raw/`, whichever the profile's layout indicates.
- [x] T3: prove the checker bites — mutate a true claim to a false one, show
      the run go red, revert. Register the mutation so a later refactor cannot
      make the checker vacuous.
- [x] T4: bring the seven M71 notes' 22 observations to the convention (they
      are the best-understood and the ones review already probed).
- [x] T5: bring the M69/M70 notes' observations to the convention.
- [x] T6: bring the remaining source notes' and `INDEX.md`'s observations to
      the convention.
- [x] T7: run the checker over the whole corpus; correct every falsified
      claim at its source, recording the basis of each correction.
- [x] T8: run `cairn_validate` and the r-package `verify` slot; confirm the
      diff touches no package value.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-07-20 (T8, status → review): `cairn_validate` exit 0 (all checks pass; dangling-id advisory 294→295 = tenhove2018's two M42 provenance citations, consistent with existing pre-migration id citations). `devtools::document()` clean, no roxygen drift, no package file touched. `devtools::test()` deliberately not run: docs-only diff (no R/test/DESCRIPTION change) cannot affect it, and the suite carries ~2h flaky brms live-Stan work — flagged for the review consistency-gate's `check()`. Checker exit 0, self-test passes.
- 2026-07-20 (T6+T7 complete): remaining notes (bartko1966, bartko1976, hedges2012, shieh2015, tenhove2018, trevethan2017, vanderark2023, INDEX) brought to the convention. **One falsified claim corrected (T7/AC5):** tenhove2018 stated "`irr` is not a package dependency" (:57, :199) — `irr` has been a Suggests dependency since **M42** (`DESCRIPTION:35`, added by PR #48 for the comparison vignette), so the claim was already false when M66 wrote it; corrected in place to "a Suggests dependency … not loaded", basis recorded inline, directive now checks `irr` present. Restated as standing facts (source/citation-structure, not repo state): bartko1976:178, trevethan2017:240 (extraction-effort), vanderark2023:257 (citation drift). Final checker: 60 observations, 48 runnable + 12 `none`, 0 unmarked, 0 falsified, exit 0. Branch diff touches no package file (AC6).
- 2026-07-20 (T5 complete): M69 notes done — fleiss1973 (multi-token grep), young1998 (overlap-in-naik + young trace), tenhove2024 (box absent from code), tenhove2025b:302/329 (legacy-ADR + ORACLES greps); 4 restated to standing facts (konishi1989:142 bound-absent-in-paper; tenhove2025b:165/308/315 source-structure facts about the article PDF); 3 `none` (tenhove2022 S4 shelf, tenhove2025a footnote + OSF-retrieval — all repo-local/gitignored-shelf). Checker: 30 runnable + 7 none, 0 falsified, 24 unmarked (T6).
- 2026-07-20 (T5, parser fix): position-based parsing — a stamp whose `observed` keyword and date straddle a soft newline (young1998:24, saha2005:29, donner2002:19, bartko1976:153, tenhove2025a:282, tenhove2025b:165/315, vanderark2023:60) was invisible to line scanning; the directive is now the first `<!-- check -->` following the stamp in the same paragraph. True in-scope count rises 57 → 64. Began T5 M70 notes: donner2002, konishi1989 (with :142 restated to a standing fact — the bound's absence is a claim about the source), naik2007.
- 2026-07-20 (T4): brought the seven M71 notes to the convention — 17 body observations (bhandary2006, bobak2018, mehta2018, saha2005, saha2012, xiao2009, xiao2013): 14 runnable `git grep`/`grep` directives (author-token trace claims + the ordinal never-swept compound), 3 `check: none` (bobak/mehta GP6-registry-is-a-concept ×2; bobak non-Gaussian-DGP is a judgment over grep hits). Checker: 0 falsified.
- 2026-07-20 (T3): proved the checker bites on a real claim — mutated bhandary2006:229's directive to a false assertion (`icc` absent from R/), run reported `falsified: 1` and exit 1, reverted to green. Permanent `--self-test` registers the harness bite so a refactor cannot make it vacuous (AC3).
- 2026-07-20 (T2 fix): checker now excludes the whole provenance *paragraph*, not just lines literally containing `Extraction:` — the soft-wrapped extraction status lands its `— observed` stamp on a continuation line (xiao2009:12, xiao2013:7, saha2005:8, saha2012:8, mehta2018:9). In-scope body observations resolve to **57** (the plan's raw 87 less ~28 exempt provenance statuses); T4's "22" is 17 body observations + 5 exempt provenance.
- 2026-07-20 (T2): committed `data-raw/check-reference-observations.py` — parses the in-scope corpus (all `references/*.md` less ORACLES/BIBLIOGRAPHY/REFERENCES), excludes `Extraction:` provenance lines, requires a `check:` directive per observation, runs each (exit 0 = holds), exits nonzero on unmarked/falsified. `--self-test` and `--list-unmarked` modes. Baseline: 62 in-scope observations, all 62 unmarked (pre-authoring); self-test passes.
- 2026-07-20 (T1): D-009 drafted and committed defining the dated-observation convention. Implement gate resolved three open choices (HTML-comment directive syntax; Python checker in `data-raw/`; provenance exempt + `check: none — reason` escape) — all recommendations accepted.
- 2026-07-19: created by /milestone-plan, re-cutting M71 after the thrash rule fired on its third review return. Plan gate: audit all 30 notes (87 observations) rather than M71's seven; mechanize with a committed checker rather than a one-off audit. Rationale from M71's three review attempts — every value-level correction survived independent verification all three times, while interpretive claims about repo state failed every time, twice in prose written to fix the previous cycle's prose; the measured cause is that only 2 of 87 dated observations carry the command that would settle them, so each review re-derives them by hand.

## Decisions
<!-- owner: implement / review · append-only -->

- 2026-07-20 (T1): convention promoted to cross-cutting D-009 (repo-side): HTML-comment
  `<!-- check: <cmd> -->` directive with exit-0-means-holds semantics; Python checker in
  `data-raw/`; provenance `Extraction:` lines exempt; `check: none — reason` for the
  genuinely un-settleable. Three implement-gate choices (syntax, siting, unsettleable
  handling) confirmed by the user.

## Review
<!-- owner: review · exclusive -->

**Reviewed 2026-07-20 · PR #79 · docs-only + one `data-raw/` tooling script.**

Fresh evidence per acceptance criterion (all by command, not recall):

- **AC1 (D-009 defines the convention).** `cairn/DECISIONS.md:245` — D-009 states
  the four rules: exit-0-means-holds directive, what counts as a settling command,
  provenance `Extraction:` exemption + `check: none — reason` for the unsettleable,
  mechanized completeness.
- **AC2 (checker re-runs + exits non-zero on falsified).**
  `data-raw/check-reference-observations.py` run over the corpus: 60 observations,
  48 runnable + 12 `none`, 0 unmarked, 0 falsified, **exit 0**. Reports per-claim.
- **AC3 (fails on a falsified claim, by mutation not inspection).** Fresh mutation:
  flipped hedges2012:158's directive to a false assertion (`icc` absent from R/) →
  run reported `falsified: 1` and **exit 1**; reverted → exit 0. Plus the permanent
  `--self-test` (registered harness bite) passes.
- **AC4 (every observation settled/restated/removed).** Checker: **0 unmarked** of
  60 in-scope. 5 restated as standing facts (konishi1989:142, tenhove2025b:165/308/315,
  vanderark2023:257); the ~28 provenance `Extraction:` statuses are exempt by rule.
- **AC5 (clean run + falsified claims corrected at source).** Checker exit 0. One
  claim falsified along the way — tenhove2018's "`irr` is not a package dependency"
  (`irr` in Suggests since M42, `DESCRIPTION:35`) — corrected in place at :56 and
  :199, basis recorded inline; directive now checks `irr` present.
- **AC6 (no package value changes).** `git diff --name-only main` touches zero files
  under `R/ tests/ data/ man/ NAMESPACE DESCRIPTION _pkgdown NEWS`. No oracle value,
  fixture, or documented behavior moved.
- **AC7 (`cairn_validate` + verify slot).** `cairn_validate` **exit 0** — all checks
  pass; the sole advisory is dangling id tokens (294→295 = tenhove2018's two M42
  provenance citations, consistent with the repo's existing pre-migration id
  citations). `devtools::document()` clean, no roxygen drift. `devtools::test()` not
  run: docs-only diff cannot affect it (no R/test/DESCRIPTION change) and the suite
  carries ~2h flaky brms live-Stan work — the full cross-platform `R CMD check` runs
  via PR #79 CI, required green before merge.

**Consistency gate.** `cairn_validate` exit 0. Toolchain (r-package): `data-raw/`
and `cairn/` both `.Rbuildignore`'d (new script raises no check NOTE); no
R/roxygen/NEWS/README/pkgdown change → no NEWS entry or pkgdown-index obligation;
`document()` no-diff. Full `R CMD check` delegated to PR #79 CI.

**Independent review (3 fresh-context lenses + scorer).** Blame-history [S]: zero
findings — every prose change is a faithful correction, valid restatement, or
read-only directive; scope fence (ORACLES/BIBLIOGRAPHY untouched) respected.
Diff-bug [O]: no correctness/contract/convention defects — checker parser sound
(provenance exemption, position-based association, self-test bite all verified),
directives faithful, `irr` correction accurate; two explicitly-non-defect latent
observations. Prior-review [S]: no prior-review regressions (GitHub inline-comment
probe empty; archived `## Review` findings on the touched files not regressed),
but flagged the finding below for the diff lens.

*Actioned finding (scored 88):* **tenhove2018.md — self-contradiction after the
`irr` correction.** Lines 56 and 199 were corrected to "`irr` is a Suggests
dependency", but line 179 still read "`irr` is not a dependency" (no `— observed`
stamp, so the checker did not track it). Fixed at review: line 179 → "`irr` is only
a Suggests dependency (not loaded here)"; file now consistent, checker + cairn_validate
still exit 0.

*Below-threshold, logged not actioned (IP3):* (1) score 44 — `--self-test` exercises
only `evaluate()`, not the `observations()` parser (matches its D-009-stated scope;
intentional). (2) score 55 — a negated grep over a mistyped/nonexistent pathspec
exits 1 → spuriously "holds"; latent authoring fragility, no active instance (all
current pathspecs verified present).
