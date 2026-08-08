<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M111: Fallback-on-abort default assessment — GO/NO-GO (composite MC → classical)

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, GP5, GP6   <!-- owner: plan · create/amend-via-gate; plus PRINCIPLES.md #3 [IP] via its D-001 fence — the ip-touching tag on AC5 -->
- **Branch/PR:** m111-fallback-on-abort · https://github.com/jmgirard/intraclass/pull/120   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Decide, against a pre-registered frozen criterion, whether the one-way default
should return a classical fallback interval where the MC default aborts
(`intraclass_singular_fit`) — assessment only, no exported code; verdict as a
D-entry answering the question D-012/D-013/D-018 fenced open.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a frozen pre-registered criteria page (GP5; adapted M76 C1–C5
thresholds + a new conditional-on-abort coverage rule); a 64-cell sweep of the
**composite procedure** (MC where it converges, classical where it aborts) —
ρ ∈ {0.05, 0.10, 0.30, 0.60} × (k,n) ∈ {(10,5),(30,5),(50,5),(10,2)} ×
dist ∈ {gaussian, t5, platykurtic, skewed per burch2011 Table 2} — with both
SEARLE exact-F and Burch REML as fallback arms (Burch §5 prefers normal-based
near ρ≈0, the abort region, so the sweep picks the method); per-rep abort
indicator + platform recorded in the fixture (the M84/M105 platform lesson);
GO/NO-GO D-entry.

**Out:** any exported code or actual default change → follow-on implementation
milestone on GO; unbalanced designs (classical forms are balanced-only,
D-013) → the unbalanced `n₀`/`n_i` candidate row; two-way designs → the MPL
track; re-litigating the opt-in GO (D-012 stands) or D-018's diagnostic
licence (a GO supersedes its return fence explicitly, in the D-entry).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] AC1: The pre-registered criterion page
      `cairn/references/fallback-on-abort-comparison.md` is committed with its
      GO/NO-GO rules, grid, and aggregation rule before any sweep artifact:
      every sweep artifact lives under `data-raw/m111-fallback-*`, and
      `git log --diff-filter=A` shows the page's introducing commit predates
      every commit introducing a file under that path set (the settling
      procedure); every number in the page's Criteria table names its source
      (an adapted M76 C1–C5 rule or a cited value).
- [x] AC2: The frozen grid includes at least one platykurtic and at least one
      skewed cluster-effect distribution, each traced to `burch2011` Table 2
      (page/table anchor in the criteria page), and at least one ρ ≥ 0.30
      level, alongside near-zero cells (ρ ≤ 0.10) with gaussian and t5 arms
      carried over from M76.
- [x] AC3: The composite fallback procedure — MC default where it converges,
      the classical method where it raises `intraclass_singular_fit` — is
      assessed for both SEARLE exact-F and Burch REML at every grid cell at
      n_rep ≥ 2000 per cell, from a committed seeded script under
      `data-raw/m111-fallback-*` whose fixture (with per-rep abort indicator
      and the generating platform recorded) lands in the same milestone;
      unconditional composite coverage, width, and tail-miss rates are
      reported per cell × method against the frozen criteria.
- [x] AC4: Conditional-on-abort coverage of each classical fallback is
      reported at every cell whose abort count is ≥ 100, and every cell below
      that floor is listed as conditional-insufficient in the criteria page's
      results section; that section makes no conditional claim for a
      below-floor cell, with `enumerate-generalizing-claims.py --check`
      (AC6) as the mechanical backstop on its claims.
- [x] AC5: A D-entry records the per-method GO/NO-GO verdict per the frozen
      aggregation rule; on any GO it names the fallback method, states that
      superseding the MC-default contract is D-001-fenced (a D-entry, not a
      constitutional amendment), names D-018's return fence as what a GO
      lifts, and recommends (not performs) the implementation milestone; on
      all-NO-GO it states what evidence class would reopen the question.
      (RB tripwire: ip-touching)
- [x] AC6: `python3 data-raw/enumerate-generalizing-claims.py --check` and
      `python3 data-raw/check-reference-observations.py` both exit 0 on the
      branch head, and `cairn_validate` passes — run fresh at review (the
      three commands are the procedure).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T2
- AC2 → T1, T2
- AC3 → T3, T4
- AC4 → T5
- AC5 → T6
- AC6 → T1, T2, T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Extract the burch2011 Table 2 battery from the shelf PDF
      (`cairn/references/sources/`); choose the platykurtic and skewed
      generators with page/table anchors; extend `burch2011.md`'s note and
      the m76 prototype generators (`data-raw/m76-classical-oneway-prototype.R`
      stays untouched; new code under `data-raw/m111-fallback-*`).
- [x] T2: Author and commit the frozen criteria page
      `cairn/references/fallback-on-abort-comparison.md` (grid, adapted
      C1–C5 + conditional-on-abort rule, aggregation rule, INDEX line,
      triage rows) before any sweep artifact.
- [x] T3: Build the sweep harness under `data-raw/m111-fallback-*`, reusing
      the m76 sweep structure parallelized over cells (`mclapply`, 4 workers
      — plan gate 2026-08-08): per-cell checkpointing, per-cell distinct
      per-rep seeds, per-rep abort indicator, platform capture; size the run
      per design family (M107/M109 lessons) and check for concurrent R
      sessions / live R.INSTALL before launch.
- [x] T4: Run the ~4 h sweep as a background job; commit the fixture.
- [x] T5: Analyze against the frozen criteria; write the results and
      per-method ledger into the criteria page; run the three AC6 checkers
      locally.
- [x] T6: Record the GO/NO-GO D-entry; update the ROADMAP candidate row
      (absorbed by this milestone) and the work log.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-08: created by /milestone-plan (promotes the classical fallback-on-abort candidate; plan gate: full 64-cell grid, both fallback arms, adapted M76 thresholds, verdict in-session with the ip-touching tag held on AC5).
- 2026-08-08: criteria audit ([O] fresh-context) returned 3 findings — AC1's "any sweep result" and "each threshold" universals bounded to the `data-raw/m111-fallback-*` path set and the Criteria table; AC4's claims-ban scoped to the results section with the claim-enumerator as backstop; AC3 gains the per-rep abort indicator + platform requirement — all fixed pre-gate.
- 2026-08-08: plan gate chose the composite-procedure framing (assess MC-with-fallback as delivered) over a second full replacement-grade re-assessment because D-012 already answered replacement NO-GO and the fallback is the candidate's actual question; falsified by evidence the composite's coverage differs materially from its per-arm components at cells the sweep did not isolate.
- 2026-08-08: plan gate chose both fallback arms over Burch-only because burch2011 §5 prefers the normal-based method near ρ≈0 — the abort region; falsified by neither arm passing the frozen bar where a third construction would.
- 2026-08-08: plan gate (follow-up): sweep harness parallel over cells at 4 workers (~4 h) rather than M76's serial structure (~13 h), at the maintainer's choice; per-cell seed streams are already independent so results are worker-count-invariant.
- 2026-08-08: set in-progress by /milestone-implement; branch m111-fallback-on-abort cut from main (3079634). Implementation question gate skipped — the plan gate settled grid, arms, thresholds, workers, and verdict routing; T1's generator picks are AC2-fenced to burch2011 Table 2, not an open choice.
- 2026-08-08: T1 done — Table 2 extracted verbatim into burch2011.md (11 distributions + κ, p. 1021, read from the shelf PDF pp. 4/8) with the located-and-scaled convention (§3 p. 1022); arms chosen: Uniform(0,1) κ=−1.2 (platykurtic) and χ²(1) κ=12.0 (skewed, the §5 boundary-caveat distribution); one enumerator superlative triaged OUT-quote; both references checkers green.
- 2026-08-08: T2 done — frozen criteria page `fallback-on-abort-comparison.md` committed before any sweep artifact (F1–F6 adapted from M76 C1–C6; F3's conditional-on-abort rule uses a Clopper–Pearson bound because a strict floor on a ~100-rep conditional subset false-alarms ~18%/cell at true-nominal; F4 width demoted to descriptive — a fallback only replaces an abort, so no dominance rule); INDEX line + 7 OUT-repo-analysis triage rows appended programmatically; all three checkers + cairn_validate green.
- 2026-08-08: T3 done — `data-raw/m111-fallback-sweep.R`: 64-cell grid, per-rep mc/searle/burch legs with composite derived at summary time, mclapply 4 workers, per-cell checkpoint files (gitignored, resume-safe), platform metadata in the fixture; lintr 0 lints, air-formatted; smoke test (3 reps × 3 cells incl. both new arms) shows aborts on the uniform ρ=0.05 cell and the composite filling them.
- 2026-08-08: T4 done — sweep ran 36 min at 4 workers (well under the ~4 h projection: no bootstrap refits in this harness), 64/64 cells, fixture `m111-fallback-results.rds` (384k rows) committed with platform metadata (macOS/arm64).
- 2026-08-08: T5 done — `m111-fallback-verdict.R` applies the frozen rules mechanically (ledger `m111-fallback-rules.rds`): F1 PASS both arms; F3 fails 23/36 (SEARLE) and 4/36 (Burch) — the abort event is informative, so off-boundary aborts select degenerate samples no fixed classical interval covers (cond. coverage 0.00–0.49 there; Burch 1.000 at 28/29 ρ≤0.10 cells); F2 fails 45 and 30 of 64 (mostly inherited from the MC leg, incl. an incumbent defect: MC alone covers 0.67 on skewed ρ=0.60 k≥30 cells with 0 aborts); F5 fails 45/48. Results + NO-GO disposition appended to the criteria page; one figure corrected against the ledger before commit (28-of-29, not all-29); 7 new claims triaged; all three checkers + cairn_validate green.
- 2026-08-08: T6 done — D-026 recorded (NO-GO both arms; abort informative; fences unchanged; reopening evidence class stated); the MC-skew incumbent defect added as a ROADMAP candidate row (search-first: no existing row or D-entry covers the MC default's non-normal coverage; the fallback row this milestone absorbed was about aborts).
- 2026-08-08: all tasks done; full devtools::test() suite green (failed+error = 0; no package code changed — the diff is data-raw/ + cairn/ only); status → review.
- 2026-08-08: review evidence pass failed AC4 (defect return 1): the criteria page summarized F3 but did not report the per-cell conditional table nor list the 28 below-floor cells as conditional-insufficient in its results section; status → in-progress.
- 2026-08-08: AC4 fix — the 36-cell conditional table and the 28-cell conditional-insufficient list added to the results section, generated from `m111-fallback-rules.rds` (never hand-transcribed); checkers + cairn_validate green; status → review.
- 2026-08-08: CI `check-references` red on a PRE-EXISTING stale `record-claims.tsv` row (not this branch's doing): M110's hygiene rotated M105 out of the terminal-row window without updating the [claim:roadmap-terminal-rows] expectation, unseen on main because docs-only pushes skip the job (M77 paths-ignore); expectation corrected in place on this branch (M105→M110), checker locally green. Lesson: the check-references job now runs FOUR checkers — `check-record-claims.py` (M102) was absent from the local pre-push list.

## Decisions
<!-- owner: implement / review · append-only -->

- 2026-08-08: verdict decided in-session (the plan-gate choice on AC5's ip-touching tripwire): the frozen rules returned an unambiguous structural NO-GO for both arms (1 SEARLE / 4 Burch near-misses; every other failure by a wide margin), so no Fable escalation was raised; the escalation option remains reachable via D-026's reopening clause. Promoted cross-cutting verdict: D-026.
- 2026-08-08 (review correction of the entry above): its near-miss figures were the wrong statistic — F2 near-PASSES (the tie-break count), not marginal failures; the correct margins are 4 SEARLE / 5 Burch F2 fails within 0.005 of the floor, with the decisive F3 failures structural (0.00–0.49 vs 0.93, review finding D2 scored 90). The escalation-skip conclusion stands on the corrected basis: the verdict rests on F3, which is unambiguous.

## Review
<!-- owner: review · exclusive -->

Evidence gathered fresh 2026-08-08 (second pass; the first failed AC4, defect return 1 — see work log):

- AC1 ✓: criteria page introduced at f3fd283 (2026-08-08 11:58:11), earliest `data-raw/m111-fallback-*` artifact at f16c485 (12:00:01) — `git log --diff-filter=A` ordering holds for every artifact under the path set; each Criteria-table row carries its "Source of the threshold" entry (M76 C1–C6 or "frozen here").
- AC2 ✓: grid names uniform (κ=−1.2, platykurtic) and chisq1 (κ=12.0, skewed) traced to burch2011 Table 2 (p. 1021); ρ levels {0.05, 0.10, 0.30, 0.60} include two ≥ 0.30; gaussian/t5 arms at ρ ≤ 0.10 carry the M76 cells.
- AC3 ✓: fixture holds 64 cells × 2000 reps with both composite-arm columns, per-rep `mc_aborted` indicator, and platform metadata (Darwin arm64, R 4.6.1); per-cell × arm coverage/width/tails reported in the summary table and on the criteria page.
- AC4 ✓: the 36-cell conditional table and the 28-cell conditional-insufficient list are in the page's results section (added at the return-1 fix, generated from the ledger); `enumerate-generalizing-claims.py --check` green as the claims backstop.
- AC5 ✓: D-026 records per-arm NO-GO under the frozen aggregation rule, states the reopening evidence class (all-NO-GO clause), and names the D-001 fence and D-018's licence as unchanged.
- AC6 ✓: `enumerate-generalizing-claims.py --check`, `check-reference-observations.py`, and `cairn_validate` all exit 0 on the branch head (8e967de).

Consistency gate: cairn_validate exit 0 (all checks); no DESIGN.md principle changed (cairn_impact skipped). Driving RR: — (no projections to juxtapose). Full devtools::test() suite green pre-review (failed+error = 0; diff touches no package code). Toolchain gate: devtools::document() no diff; pkgdown check_pkgdown clean; README untouched. CI: check-references red on a pre-existing stale record-claims row (corrected, see work log); remaining jobs green/pending at gate time.

Fan-out (3 lenses → scorer): prior-review lens clean (no regressions; repo has no PR-thread history); blame-history 7 observations; diff-bug 15 findings with headline figures re-derived clean (generators, seeds, CP bound, all rule counts match the ledger). Scored ≥80 and FIXED on the branch:
- D2 (90): the disposition's "(1 SEARLE / 4 Burch near-misses; the rest fail by wide margins)" quoted F2 near-PASSES (the tie-break stat) as failure margins — corrected on the page and in D-026 (true margins: 4 SEARLE / 5 Burch F2 fails within 0.005; F3 structural); the milestone Decisions escalation-skip entry corrected by an appended dated line (conclusion stands on F3).
- D7 (88): F5's conditional-tail reporting was unimplemented and the page's one conditional-tail claim inverted — verdict.R now computes cond_lo/hi_miss into the ledger (all conditional misses are upper-tail; lower-tail 0.000 everywhere), page corrected.
- D1 (85): "no assessed method covers conditionally off-boundary" overgeneralized — Burch covers 1.000 at all four (0.30,10,2,·) cells; page + D-026 rescoped to informative-design cells (the boundary is informational, not a ρ threshold).
- D3 (80): verdict.R's F1 assertion was vacuous (comp_*_covered is never NA by construction) — replaced with the real per-leg abort-row assertion (0 of 256,000).
- D9 (80): failing n=2 composite range "0.82–0.89" understated — corrected to 0.816–0.929 / 0.838–0.920.
Logged sub-80 (13): B4 62 (Table 2 extraction lacked its own dated line — added), B6 68 (folded into D1's fix), B7 60 (candidate-row hedge tightened), D4 78 / D5 78 / D10 78 / D15 72 / D8 70 / D12 68 / D13 55 (factual/wording slips on the page and script header — all corrected as part of the D1/D2 page pass), D6 58 + D11 52 (latent harness gaps → new hardening candidate row), D14 55 (work-log phrasing; append-only, left).
