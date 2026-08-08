<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M114: Runtime skew/kurtosis warn trigger — design & validation (assessment only)

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP5, GP6   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m114-skew-warn-trigger   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Decide, against pre-frozen reliability criteria read over per-rep trigger
statistics joined to the committed M111 coverage data, whether a
data-measurable runtime statistic can reliably signal the one-way MC default's
skew/kurtosis under-coverage (D-027's `warn` commission) — recording the
trigger spec, or the degrade-to-`document` disposition, as a D-entry.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** frozen criteria page (candidate family = the shipped Burch
excess-kurtosis statistic `burch_kappa_hat()`/`burch_kappa_bc()`
(`R/ci-classical.R:147-158`) + a sample-skewness analog on the same
decomposition; per-cell fire-rate floors/ceilings; threshold-search grid,
selection rule, tie-break; degrade rule; held-out battery spec); a
derivation script regenerating the M111 reps from their seed scheme with a
per-rep consistency proof; a small held-out generalization sweep; the
verdict D-entry.

**Out:** shipping the warning (or the doc caveat) → the response milestone,
planned after this verdict (plan gate 2026-08-08); the high-abort
selection-conditioned phenomenon → D-026's reopening class, not re-opened
here; any default-method change → D-001-fenced, not touched (assessment
only); re-running the M111 sweep or its checkpoint cache → not needed (reps
regenerate from seeds); the stale-checkpoint hardening stays its own
candidate row.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: The reliability criteria page
      `cairn/references/mc-skew-warn-trigger.md` is frozen (GP5) in a commit
      that precedes every derivation-artifact commit (derivation artifacts:
      T2's script, T3's derived table, T4's held-out sweep script and
      outputs); any post-freeze edit to the page lands in its own commit
      before the first derivation-artifact commit (M113 lesson). The page
      defines, before derivation: the candidate statistic family
      (kurtosis + skewness, plan gate 2026-08-08), the per-cell fire-rate
      floors/ceilings that constitute "reliable", the threshold-search grid,
      the selection rule among passers and its tie-break, the degrade rule,
      and the held-out battery (cells, distributions, geometry, n_rep,
      seeding, floor applicability) — so the verdict is a function of
      (frozen page, derived tables) alone.
- [ ] AC2: `data-raw/m114-warn-trigger-derivation.R` regenerates every
      (cell, rep) dataset from the M111 seed scheme
      (`cell$id * 1000000L + rep`) and proves the regeneration is the
      fixture's: for every one of the 64 × 2000 reps, the recomputed SEARLE
      interval equals the endpoints stored in the fixture's long `raw` table
      (`lower`/`upper` on `method == "searle"` rows, keyed by (cell, rep))
      within 1e-12 — asserted in-script, on a platform matching the
      fixture's recorded `meta$platform` (aborted searle reps, if any,
      compared on their aborted flag instead).
- [ ] AC3: Per-rep candidate trigger statistics for all M111 reps and all
      held-out reps are committed as a derived table
      (`data-raw/m114-warn-trigger-stats.tsv`), re-derivable by re-running
      the scripts (byte-stable on re-run under the committed seeds).
- [ ] AC4: The held-out battery — ≥ 2 data-generating distributions not in
      the M111 grid, ≥ 1 geometry off the M111 (k, n) set, cell ids ≥ 65 so
      seed streams stay disjoint from the M111 ids 1–64, all named on the
      frozen page before it runs — is swept per-rep (MC-leg coverage +
      trigger statistic) and its cells enter the frozen rules' verdict
      alongside the M111-derived cells (GP6).
- [ ] AC5: The verdict is read mechanically from the frozen rules over the
      derived tables — the derivation script applies the frozen selection
      rule with no free choices — and recorded as a D-entry: either (a) a
      trigger spec (statistic, threshold, measured per-cell operating
      characteristics), or (b) the degrade-to-`document` disposition, worded
      as the bounded finding "no candidate in the frozen family met the
      frozen floors/ceilings on the derived tables". The page's
      Results/Disposition sections carry the per-cell table.
- [ ] AC6: The milestone ships no exported-code change:
      `git diff --stat main...HEAD -- R/ src/ man/ NAMESPACE DESCRIPTION
      NEWS.md tests/ vignettes/ data/` is empty at review.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2
- AC3 → T2, T4
- AC4 → T4
- AC5 → T5
- AC6 → T1–T5 (nature of the work; verified by the AC6 command at review)

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Author and freeze `cairn/references/mc-skew-warn-trigger.md` —
      candidate family, floors/ceilings, threshold-search grid + selection
      rule + tie-break, degrade rule, held-out battery spec — committed
      before any derivation artifact (own commit; M113 lesson).
- [x] T2: Write `data-raw/m114-warn-trigger-derivation.R`: regenerate the
      64 × 2000 reps from seeds, assert the AC2 SEARLE consistency proof,
      compute per-rep kurtosis + skewness statistics, join to stored
      `mc_covered`/`mc_aborted` (non-aborted reps carry the trigger
      evaluation), emit the M111 half of the derived table.
- [x] T3: Commit the derived table `data-raw/m114-warn-trigger-stats.tsv`
      (M111 + held-out rows) with byte-stability on re-run.
- [x] T4: Write and run the held-out sweep (`data-raw/m114-heldout-sweep.R`,
      cell ids ≥ 65, per the frozen spec; M112-hardened harness idioms —
      mclapply NULL-slot guard, status-based abort classification); append
      its per-rep rows to the derived table.
- [x] T5: Apply the frozen selection rule mechanically over the derived
      tables; record the verdict D-entry; fill the page's
      Results/Disposition sections; add the response-milestone candidate
      row to the ROADMAP (successor to the D-027 commissioning row this
      plan consumed).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-08: created by /milestone-plan (promotes the D-027 warn-trigger commissioning row; plan gate: two milestones — assessment now, response after the verdict; held-out battery in; candidate family = kurtosis + skewness).
- 2026-08-08: criteria audit ([O] fresh reader) returned 9 findings, all fixed in the AC wording pre-gate: fixture endpoint columns live in the long `raw` table not the wide table; 1e-12 platform-scoped; held-out table given a committed home + disjoint seed ids; AC1 additionally freezes the threshold-selection procedure so AC5's mechanical read is reachable; degrade limb bounded to the frozen family; AC6 pathspec extended to the full installed surface.
- 2026-08-08: T3 done — AC3 byte-stability VERIFIED: full re-run of both scripts reproduced the 138,000-row table byte-identically (cmp clean vs the run-1 copy). The 6b5653c checkpoint had captured the tsv mid-re-run (m111 half only, 128,000 rows); this commit lands the complete table — the verdict ledgers were derived from the complete run-1 table before the re-run and are unaffected.
- 2026-08-08: air format pass over the three m114 data-raw scripts (argument-per-line reflow only; behavior-identical, the committed table and ledgers stand).
- 2026-08-08: plan gate chose seed-scheme regeneration + per-rep consistency proof over re-running the M111 sweep with statistics added, because reps regenerate deterministically without refitting (36 min saved; the stale-checkpoint candidate's promotion condition stays unfired); falsified by the AC2 consistency assertion failing on any rep.
- 2026-08-08: T1 done — frozen page authored (48-candidate closed family, W1–W3 tiered floors per the implement gate, mechanical selection ordering, 10-cell held-out battery ids 65–74) + INDEX.md line; freeze commit precedes every derivation artifact.
- 2026-08-08: T2 done — derivation script + shared stats helper (`m114-trigger-stats.R`, sourced by both halves so no copy drift); AC2 proof PASSED: 128000/128000 non-aborted searle reps matched within 1e-12 on the recording platform; minor amendment: verdict logic factored into `m114-warn-trigger-verdict.R` (T5's mechanical read gets its own artifact, no selection logic in the measuring scripts).
- 2026-08-08: T4 done — held-out battery ran (10 cells, ids 65–74): four T-b targeted cells (66/68/70/72, every (50,5) lognormal/laplace cell, worst 0.825), (20,3) cells all cover ≥ 0.939; no checkpoint cache by design (the M112-review staleness trap).
- 2026-08-08: T5 done — VERDICT: DEGRADE (D-028). 0/48 candidates pass W1 or W2 (28/48 pass W3 alone; best min targeted fire 0.1625 vs 0.90/0.50 floors — not a near-miss); measured cause is dilution (cluster effect at weight² ≈ 0.04 in the pooled z at n = 5), so reopening routes to a cluster-effect-direct family, never re-thresholding. Page Results/Disposition filled; two candidate rows added (document-caveat response; direct-family reopening).
- 2026-08-08: T3 checkpoint — derived table written (138,000 rows) and committed with this checkpoint; the AC3 byte-stability proof (full re-run of both scripts + cmp) is IN FLIGHT, not yet verified — T3 stays unticked until the cmp returns clean.
- 2026-08-08: plan gate chose kurtosis + skewness candidate family over kurtosis-only and over a wider open family (Shapiro–Wilk, tail ratios), because both failing families are moment-detectable while skewed-light-tailed data would escape kurtosis alone, and a wider family multiplies selection multiplicity on a frozen page; falsified by a held-out or user-reported under-coverage case both frozen statistics miss.

## Decisions
<!-- owner: implement / review · append-only -->

- 2026-08-08: implement gate fixed the frozen bar (severity-tiered floors: fire ≥ 0.90 at cov < 0.80 cells, ≥ 0.50 at 0.80–0.93 cells, ≤ 0.10 at well-covered gaussian cells) and made the 26 high-abort cells descriptive-only (their under-coverage is D-026's selection phenomenon, fenced out of this verdict; a moment statistic cannot detect gaussian selection effects, so binding them would guarantee degradation for a reason the trigger does not target).

## Review
<!-- owner: review · exclusive -->
