# M90: MPL κ_m recalibration + coverage GO/NO-GO at conf_level ∈ {0.90, 0.99}

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** RR03
- **Principles touched:** IP1, GP5, GP6
- **Branch/PR:** m90-mpl-conf-level-calibration · https://github.com/jmgirard/intraclass/pull/97

## Goal

GO/NO-GO on whether the two-way random ICC(A,1) MPL interval, with κ_m
recalibrated at α∈{0.10, 0.01}, covers at nominal across the ρ range (incl. the
near-zero boundary) at conf_level 0.90 and 0.99 — the prerequisite for M91.

## Scope

**In:** Recalibrate the MPL correction constant κ_m at two new confidence levels
so a later milestone can export them. Parametrize the M87/M88 calibration by α;
re-earn xiao2013's published α=0.10 κ_m oracle through the parametrized pipeline
(BC1), then generate seeded κ_m tables at α∈{0.10, 0.01} (two-sided) over the
shipped (R,S) grid (R 2:10 × S {10,15,20,30,50,100}) with M88's scan→top-k
bias-correction (α=0.01 sizes per BC2). Freeze the RR03-determined coverage
criterion (BC3 floors, BC4 replication, BC5 8-cell set) in a references note
before any run (GP5), run the coverage sweep recording the BC6 diagnostics, and
render a per-level GO/NO-GO verdict (BC7). κ_m fixtures land in `data-raw/`
(`.rds`); they are NOT yet wired into `R/sysdata.rda`.

**Out:** No exported code, no fence lift, no `R/` change → M91 (consumes this
milestone's fixtures + GO). Levels other than {0.90, 0.99} → candidate row.
Arbitrary continuous conf_level via α-interpolation → out (off-level aborts,
decided in M91). Design/geometry fences (fixed, consistency, unbalanced,
off-grid) → unchanged, separate candidates.

## Acceptance criteria

Driving RR = RR03; BC1–BC7 are ingested verbatim as AC4–AC10 (`binding
criteria` string-compares them). No departures — no "Deviations from RR03" table.

- [x] AC1: Seeded κ_m tables at α=0.10 (conf_level 0.90) and α=0.01 (conf_level
      0.99) exist over the full shipped (R,S) grid, provenance in `meta`; the
      generator's `kappa_corr_draws` collector reproduces the oracle-validated
      `mpl_kappa_corr` at a shared seed (equivalence assertion). The 0.90 external
      cross-check is BC1/AC4; the 0.99 table has no external κ_m anchor and is
      validated by coverage (AC6/BC3), per the M86 defining-property doctrine.
- [x] AC2: A per-level GO/NO-GO verdict applying the frozen BC3/BC4 criterion to
      the sweep, recorded with evidence in the references comparison note; a
      NO-GO level is named and routed to a candidate row, not exported (BC7).
- [x] AC3: The note states the **level-specific** oracle posture — conf_level
      0.90's κ_m is externally oracle-backed over ρ∈[0.6,0.9] (xiao2013 Table
      3/6, IP1); its sub-0.6 tail and all of conf_level 0.99 have no external
      oracle (D-014(i) inherited), established by simulated coverage only.
- [x] AC4 (BC1): Before any α=0.01 production calibration, the α-parametrized
      pipeline, run at α=0.10 two-sided over ρ ∈ [0.6, 0.9] × δ = 2^(−1..4) with
      n_mc ≥ 6000, reproduces all six published two-sided κ_m values — 0.32,
      0.52, 0.67 at (R=3, S=10/25/50) and 0.13, 0.23, 0.33 at (R=5, S=10/25/50)
      — each within ±0.10 (the M86 tolerance). S = 25 is evaluated explicitly (it
      is off the shipped `s_grid`).
- [x] AC5 (BC2): The α=0.01 table generator uses n_mc_scan ≥ 3000, top_k ≥ 5,
      n_mc_final ≥ 12000. The fixture records, for at least one representative
      geometry per R ∈ {2, 3, 10}, a bootstrap SE of the final κ̂_m (resampling
      the final-cell deviance sample); each recorded SE ≤ 0.05. The α=0.10
      generator may retain M88's sizes (1500/3/6000).
- [x] AC6 (BC3): Per-cell pass floor: empirical coverage ≥ 0.88 at conf_level
      0.90; ≥ **0.98** at conf_level 0.99 (supersedes the proposed c − 0.02 =
      0.97). Over-coverage passes at both levels.
- [x] AC7 (BC4): n_rep ≥ 2000 per cell at 0.99 (coverage MC-SE at the 0.98 floor
      ≤ 0.0032); n_rep ≥ 1000 per cell at 0.90. The verdict fixture reports an
      exact (Clopper–Pearson) 95 % CI for coverage at every cell.
- [x] AC8 (BC5): The decisive set at each level is M87's C1–C5 **plus** C6 =
      (R=3, S=100, δ=4, ρ=0.60), C7 = (R=2, S=15, δ=1, ρ=0.05), and C8 = (R=3,
      S=20, δ=1, ρ=0.02). All eight are decisive: the floor (BC3) must hold at
      every one.
- [x] AC9 (BC6): The sweep fixture records per cell: miss-below and miss-above
      counts; median and 90th-percentile interval width; P(lower endpoint = 0);
      P(upper endpoint ≥ 0.999); vacuous fraction (both clamps simultaneously).
      These do not gate the verdict, except: the M91 documentation (or the
      references note if 0.99 is NO-GO) must state the small-geometry width
      finding wherever a decisive cell's median 0.99-interval width ≥ 0.90.
- [x] AC10 (BC7): M91 may export conf_level 0.99 only if BC1–BC6 all pass at that
      level; conf_level 0.90 gates only on BC1 and on BC3–BC6 at its own level. A
      BC failure at one level routes that level to a candidate row (NO-GO)
      without blocking the other. No level deeper than 0.99 is authorized by this
      review.

## Coverage

- AC1 → T2
- AC2 → T4
- AC3 → T1, T4
- AC4 (BC1) → T2
- AC5 (BC2) → T2
- AC6 (BC3) → T1, T4
- AC7 (BC4) → T3, T4
- AC8 (BC5) → T1, T3
- AC9 (BC6) → T3
- AC10 (BC7) → T4

## Tasks

- [x] T1: Freeze the RR03-determined coverage criterion + level-specific oracle
      disclosure in a references note (extend
      `references/mpl-twoway-random-comparison.md` or a sibling): the BC3 floors
      (0.88 at 0.90; 0.98 at 0.99), BC4 replication (n_rep ≥ 2000 at 0.99,
      Clopper–Pearson CIs), and the BC5 8-cell set (C1–C8). Dated before any
      sweep run (GP5).
- [x] T2: Parametrize the κ_m calibration
      (`data-raw/m87-mpl-kappa-recalibration.R`, `data-raw/m88-mpl-kappa-table.R`)
      by α. First run the **BC1 precondition** — the α=0.10 published-oracle
      reproduction (6 geometries incl. off-grid S=25, n_mc ≥ 6000, each within
      ±0.10). Then generate the production tables at α=0.10 (M88 sizes) and α=0.01
      (**BC2 sizes:** scan ≥ 3000, top_k ≥ 5, final ≥ 12000; record bootstrap
      SE ≤ 0.05 for R ∈ {2,3,10}), seeded. Background (~5 h for α=0.01). → `data-raw/*.rds`.
- [x] T3: Coverage sweep at each level across the 8 BC5 cells, seeded, at the BC4
      n_rep; record the BC6 diagnostics (miss-below/above, median + p90 width,
      P(lower=0), P(upper≥0.999), vacuous fraction) per cell (mirror
      `data-raw/m87-mpl-comparison-sweep.R`, MPL-only). Background. → sweep fixture.
- [x] T4: Verdict script applying the BC3 floors + BC4 Clopper–Pearson CIs per
      cell → per-level GO/NO-GO (BC7 gating); record verdict + evidence + the BC6
      width finding in the note. GO authorizes M91; a NO-GO level → candidate row.

## Work log

- 2026-07-24: created by /milestone-plan (with M91); conf_level {0.90,0.99} for MPL, level set chosen at the plan gate; lineage D-015 → this.
- 2026-07-24: /milestone-implement start; status → in-progress; branch m90-mpl-conf-level-calibration cut from main.
- 2026-07-24: amended AC1/AC4 (gate) — conf_level 0.90's κ_m over ρ≥0.6 has a direct external oracle (xiao2013 Table 3/6 at α=0.10, IP1; M86 already reproduced 0.32/0.67/0.33); no-oracle posture now level-specific (0.90 sub-0.6 tail + all 0.99 only). Principles touched += IP1; AC1 coverage += T4.
- 2026-07-24: escalating to Fable via /milestone-brief (RB tripwire: no-oracle) before freezing the T1 criterion or running any sweep — the α=0.01 (0.99) deep-tail κ_m + sub-0.6 extrapolation have no external oracle; question per the gate. T1–T4 paused pending the RR.
- 2026-07-24: blocked on RB03 (cairn/reviews/RB03-mpl-conf-level-extrapolation.md).
- 2026-07-24: T1 done — froze the conf_level 0.90/0.99 pre-registration (BC1–BC7 criterion: cells C1–C8, floors 0.88/0.98, n_rep, oracle posture) in `references/mpl-twoway-random-comparison.md` (GP5, dated 2026-07-24); 2 new generalizing claims triaged OUT-repo-analysis; enumerator/reference-obs/cairn_validate all green.
- 2026-07-24: ingested RR03 (Fable) → D-017. Verdict: 0.90 GO (external oracle), 0.99 conditional GO under BC1–BC7. Set Driving RR = RR03; ingested BC1–BC7 verbatim as AC4–AC10; dropped the plan's c−0.02 floor (superseded by BC3's 0.98@0.99); refined T1–T4 to the BCs. Status → in-progress. RB03/RR03 archived.
- 2026-07-24: T2 done — `data-raw/m90-mpl-kappa-tables.R` generated the α=0.10 (0.90) + α=0.01 (0.99) κ_m tables (54/54 nodes each) → `data-raw/m90-kappa-tables.rds`. **BC1 PASS** 6/6 (max \|diff\| 0.020 vs published). **BC2 PASS** — 0.99 κ̂_m bootstrap SE 0.037/0.033/0.026 for R∈{2,3,10}, all ≤0.05. κ_m ranges 0.90 [0.106,1.742], 0.99 [0.104,0.999]. No sysdata.rda (M91).
- 2026-07-24: T3 done — `data-raw/m90-mpl-coverage-sweep.R` swept the 8 BC5 cells × 2 levels (n_rep 1000@0.90, 2000@0.99), recording BC6 diagnostics → `data-raw/m90-coverage-sweep.rds`. Every cell clears its BC3 floor; 0.90 min cov 0.915 (C4), 0.99 min cov 0.997 (C6). No decisive cell's median 0.99 width ≥ 0.90 (max 0.852 at C4), so BC6's mandatory width-doc trigger did not fire.
- 2026-07-24: T4 done — `data-raw/m90-mpl-verdict.R` applied BC3/BC7 → **conf_level 0.90 GO, 0.99 GO** (both: every cell ≥ floor, BC1 ✓; 0.99 also BC2 ✓) → `data-raw/m90-verdict.rds`. Verdict + per-cell coverage table + the BC6 one-sided-miss/width diagnostics recorded in `references/mpl-twoway-random-comparison.md` (§ M90 verdict); 1 generalizing claim triaged OUT-repo-analysis. D-017's conditional GO conditions met; M91 export authorized for both levels. All gates green.
- 2026-07-24: all tasks (T1–T4) done; `devtools::test()` clean (FAIL 0, PASS 3947; M90 touched no R/ code); enumerator + reference-obs + cairn_validate green. Status → review. Draft PR #97.
- 2026-07-24: review sent back — AC1 defect. Its "scan-vs-top-k internal cross-check (M88's guard) agrees within MC tolerance" clause mis-specified: scan→top-k is a winner's-curse bias correction (scan−final up to 0.21 by design), not a consistency check; M88's actual guard was cross-pipeline vs M87. Amended AC1 (gate-approved) to the real internal validation — the `kappa_corr_draws==mpl_kappa_corr` equivalence assertion + BC1 (0.90 external) + coverage (0.99). AC2–AC10 all had fresh passing evidence; single bounce. Status → in-progress.

## Decisions

- 2026-07-24 (RR03/D-017): Fable review of the no-oracle 0.99 + sub-0.6 ρ
  extrapolation. **0.90 GO** on the xiao2013 published κ_m oracle; **0.99
  conditional GO** on simulated-coverage evidence alone, gated on BC1–BC7 (now
  AC4–AC10). Nothing numeric is extrapolated in α (κ_m recalibrated at the 0.99
  quantile); the shape-dependence (Q1) and boundary (Q4) risks measured bounded
  + conservative-direction. Rejected: holding 0.99 back categorically; a
  tail-model κ_corr estimator (deep tail non-χ²-shaped → anti-conservative). No
  level deeper than 0.99 authorized. Promoted to D-017. Beyond-brief → M91
  (non-equal-tailed doc, near-vacuous-width doc, `R/ci-mpl.R` interpolation
  comment) + a 0.95 sub-grid-floor backfill candidate.

## Review

**Verdict: both conf_level 0.90 and 0.99 GO.** Fresh evidence re-derived from the
committed fixtures (`data-raw/m90-kappa-tables.rds`, `m90-coverage-sweep.rds`,
`m90-verdict.rds`) and by re-running `data-raw/m90-mpl-verdict.R`.

Acceptance-criterion evidence (each verified fresh):
- **AC1** — both tables present, 54 nodes each over R 2:10 × S {10,15,20,30,50,100},
  `meta` provenance complete (generator/seed/levels/grids, `smoke=FALSE`). The
  `kappa_corr_draws` collector reproduced `mpl_kappa_corr` at a shared seed
  (equivalence assertion OK, T2 log). 0.90 external cross-check = AC4; 0.99 = coverage (AC6).
- **AC2/AC3** — verdict + per-cell coverage table recorded in
  `references/mpl-twoway-random-comparison.md` § "M90 verdict (T4)"; level-specific
  oracle posture stated (§ "Oracle posture (level-specific)", note l.360).
- **AC4/BC1** — 6/6 published κ_m reproduced within ±0.10, S=25 evaluated
  explicitly; max |diff| **0.020** (0.30/0.535/0.677/0.133/0.219/0.311).
- **AC5/BC2** — α=0.01 sizes scan=3000/top_k=5/final=12000; bootstrap SE
  **0.037/0.033/0.026** for R∈{2,3,10}, all ≤ 0.05.
- **AC6/BC3** — every cell ≥ floor: 0.90 min **0.915** (C4) ≥ 0.88; 0.99 min
  **0.997** (C6) ≥ 0.98.
- **AC7/BC4** — n_rep 1000 (0.90) / 2000 (0.99); Clopper–Pearson CIs present per cell.
- **AC8/BC5** — all 8 cells C1–C8 swept at both levels.
- **AC9/BC6** — all diagnostic columns present (miss ±, width med/p90, clamp rates,
  vacuous); no decisive cell median 0.99 width ≥ 0.90 (max 0.852 at C4), so the
  mandatory width-doc trigger did not fire; the one-sided-miss asymmetry (C4/C6) is
  carried to M91.
- **AC10/BC7** — gating logic applied by the verdict script (both GO); "no level
  deeper than 0.99" recorded in the note.

**Projections vs outcomes (Driving RR = RR03):**
- BC1 |diff| ≤ 0.10 (projected) → measured max **0.020**.
- BC2 bootstrap SE ≤ 0.05 (projected) → measured max **0.037**.
- BC3 floor 0.98 @ 0.99 (projected) → measured min **0.997**; floor 0.88 @ 0.90 → min **0.915**.
- BC4 MC-SE ≤ 0.0032 at the 0.99 floor (projected) → n_rep=2000 gives SE ≈ 0.0031.
All measured outcomes clear their projected thresholds; no shortfall.

**Amendment during review:** AC1's original "scan-vs-top-k cross-check within MC
tolerance" clause was sent back (mis-specified — scan→top-k is a bias correction,
not a consistency check) and gate-amended to the real internal validation; single
bounce, AC2–AC10 unaffected.

**Consistency gate:** `cairn_validate` exit 0 (binding criteria, coverage
complete, scaffold, roadmap↔disk all PASS); `enumerate-generalizing-claims --check`
+ `check-reference-observations` green; `devtools::document()` no diff; no `R/` or
`DESIGN.md` change (so `cairn_impact` no-ops; full R CMD check delegated to PR #97
cross-platform CI, required green before merge). PR #97 format-check initially
failed (new `data-raw/*.R` un-air-formatted) → `air format` applied, verdict
re-runs identically, pushed.

**Independent 3-lens review + scorer:** diff-bug [O] — no defects (all 3 scripts
verified correct incl. the `kappa_corr_draws`≡`mpl_kappa_corr` mirror run live at
both α; every note number matches the fixtures). blame-history [S] — method
fidelity + decisions consistent; 1 finding. prior-review [S] — zero regressions
(M86-F1 gates green, M86-F2 κ_m recalibrated per level, PR probe empty). Two
findings scored:
- **F1 (84, actioned+fixed):** the note's Provenance line (l.13) named only M90's
  pre-registration, omitting the verdict section M90 also appended (M72
  stale-summary pattern) → corrected to "pre-registration and GO verdict".
- **F2 (34, below threshold — logged):** `m90-mpl-coverage-sweep.R:83` per-rep seed
  overlaps RNG state across adjacent 0.99 cells (C1 r2000 ≡ C2 r1000); result-neutral
  (within-cell seeds distinct, per-cell coverage independent) — cosmetic, in a
  data-raw research script; not actioned.
