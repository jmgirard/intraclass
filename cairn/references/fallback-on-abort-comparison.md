# Fallback-on-abort composite vs the abort status quo — comparison (M111)

**Provenance.** Ingested 2026-08-08 by M111 as the pre-registered GO/NO-GO
criterion page for the fallback-on-abort default assessment; results appended
by M111 T5 from a first-hand simulation (`data-raw/m111-fallback-sweep.R` over
the composite procedures built from the M76 prototypes in
`data-raw/m76-classical-oneway-prototype.R`). Method constructions trace to
`burch2011.md`, `mcgraw1996.md`, `ohyama2025.md`; thresholds to
`classical-oneway-comparison.md` (M76 C1–C5).
Pagination: —.
Extraction: first-hand record, nothing to re-verify against — observed 2026-08-08.

**Scope.** This is the M111 GO/NO-GO evidence page: the pre-registered
criterion (frozen before any run, GP5) plus, once the sweep lands, the results
and per-arm verdict. It is not a source summary. The criterion below is
frozen: results are read against it, never the reverse. Status lives in
`ROADMAP.md`, the durable verdict in `DECISIONS.md` (D-012/D-013/D-018 fence
the question this page answers).

## What is being compared

The **composite procedure** — the MC default (`ci_method = "montecarlo"`)
where it converges, a classical closed-form interval where the MC default
aborts classed `intraclass_singular_fit` — in two arms distinguished by the
fallback leg:

- **SEARLE-composite** — fallback = SEARLE exact-F (mcgraw1996 Table 7 /
  ohyama2025 §2; exact under normality; burch2011 §5 prefers it near ρ ≈ 0,
  which is the abort region).
- **Burch-composite** — fallback = Burch (2011) REML kurtosis-adjusted
  interval (burch2011 eq. 6/13/15/16/17; never under-covered in the M76
  sweep).

The baseline being improved on is the **status quo**: the MC default alone,
which returns no interval at all on its abort reps (4–44% of near-zero cells,
M76 C1). Both fallback legs are deterministic closed forms; the composite's
RNG use is the MC default's own.

## Sweep design (frozen)

- **Grid (64 cells):** `ρ ∈ {0.05, 0.10, 0.30, 0.60}` ×
  `(k,n) ∈ {(10,5), (30,5), (50,5), (10,2)}` ×
  `dist ∈ {gaussian, t5, uniform, chisq1}`. The distribution shapes the
  **cluster effect** (errors stay normal — GP6, the M76 convention): `t5` =
  scaled t(5) (κ = 6.0), `uniform` = scaled Uniform(0,1) (κ = −1.2,
  platykurtic), `chisq1` = scaled χ²(1) (κ = 12.0, skewed) — all three from
  burch2011 Table 2 (p. 1021), located and scaled per §3 (p. 1022). The
  gaussian and t5 arms at ρ ≤ 0.10 carry over the M76 cells.
- **n_rep:** 2000 per cell per arm (the two arms share data and MC reps; only
  the fallback leg differs).
- **Seeding:** per-cell distinct seeds, per-rep; data seed `cell·10⁶ + rep`
  (the M76 scheme); the MC default's simulation draws on a disjoint offset
  stream. Per-rep abort indicator and the generating platform recorded in the
  fixture.
- **Parallelism:** `mclapply` over cells, 4 workers (plan gate 2026-08-08);
  per-cell seed streams are independent, so results are worker-count-invariant.

## Pre-registered GO/NO-GO criterion — frozen 2026-08-08, before any run (GP5)

Tag vocabulary for the verdict ledger (filled at T5): `GO` | `NO-GO` per arm.

| # | Rule (binding unless marked) | Source of the threshold | AC |
|---|---|---|---|
| F1 | **Interval always.** Each composite arm returns a finite interval on 100% of reps at every cell; the MC-alone abort rate is reported alongside as the defect being addressed. | M76 C1 | AC3 |
| F2 | **Unconditional coverage floor.** At each cell, each arm's two-sided composite coverage ≥ 0.93. Over-coverage to ~0.97 tolerated. | M76 C2 (ukoumunne2003 worst tabulated 0.931; burch2011 §5 "just under 0.93") | AC3 |
| F3 | **Conditional-on-abort coverage.** At each cell with abort count ≥ 100, the fallback leg's coverage among abort reps fails only if its exact one-sided 95% upper Clopper–Pearson bound is below 0.93 (the conditional subset is small, so the strict-floor form would false-alarm on MC noise; the bound form fails only on evidence). Cells with < 100 aborts are conditional-insufficient: reported, never judged. | floor: M76 C2; bound form: frozen here | AC4 |
| F4 | **Width (descriptive, not binding).** Median fallback-interval width among abort reps, per cell × arm, reported beside the MC median width on MC's non-aborted reps. No dominance rule: the fallback only ever replaces an abort, so there is no width regression to guard. | M76 C3, demoted to descriptive | AC3 |
| F5 | **Tail symmetry.** Unconditional composite tails at every cell: neither tail-miss > 0.045 and `|lower − upper| ≤ 0.03`. Conditional-on-abort tails reported (descriptive) at ≥ 100-abort cells. | M76 C5 | AC3 |
| F6 | **Verdict.** Aggregating F1–F5, a per-arm GO/NO-GO is recorded as a D-entry; a GO states that the default contract change is D-001-fenced and names D-018's return fence as what it lifts. | M76 C6 | AC5 |

**Aggregation rule (frozen).** An arm earns **GO** only if it passes every
binding rule (F1, F2, F3, F5) at every applicable cell. If both arms pass, the
D-entry names the arm with the fewer binding near-misses (a near-miss = a
binding statistic within 0.005 of its threshold on the failing side of
nominal); if still tied, the narrower median fallback width among abort reps,
summed over ≥ 100-abort cells. If neither passes, NO-GO with the reopening
evidence class stated. The status quo (an abort, no interval) is the
comparator F1 exists to beat; a NO-GO leaves it in place.

## Results — appended at T5

*(empty until the sweep of `data-raw/m111-fallback-sweep.R` lands; per AC1,
this page's introducing commit predates every `data-raw/m111-fallback-*`
file.)*

## Open questions

- Whether both arms passing would favor per-data-kurtosis arm selection
  (SEARLE on ≈normal, Burch on heavy-kurtosis data) rather than one fixed
  fallback — out of this page's scope; the frozen tie-break picks one arm,
  and adaptive selection would need its own assessment — observed 2026-08-08. <!-- check: none — a scope note about a design not assessed here; nothing committed settles it -->
