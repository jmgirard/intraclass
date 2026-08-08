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

## Results — sweep of 2026-08-08

Backing data `data-raw/m111-fallback-results.rds` (384,000 raw rows: 64 cells ×
2000 reps × 3 legs; generated by `data-raw/m111-fallback-sweep.R`, ~36 min at 4
workers on macOS/arm64); the per-cell rule ledger is
`data-raw/m111-fallback-rules.rds`, produced by
`data-raw/m111-fallback-verdict.R`, which applies the frozen rules mechanically
— every figure below re-derives from it by re-running that script.

**F1 — interval always: PASS, both arms** (0 composite NAs over all 128,000
rep×arm outcomes; the closed-form legs never failed to compute).

**The abort landscape (the surprise).** Aborts are **not confined to the
near-zero boundary**: the 10×2 design aborts on 16–23% of reps at ρ = 0.30 and
3–9% at ρ = 0.60, and the 10×5 design aborts on 6–12% at ρ = 0.30 (t5/chisq1).
36 of 64 cells reached the ≥ 100-abort reporting floor, including cells at
every ρ level swept.

**F3 — conditional-on-abort coverage: the decisive failure.** The abort event
is *informative*: at true ρ away from the boundary, the reps that abort are
exactly the samples whose between-subject variance collapsed, and a classical
interval computed from such a sample excludes the truth.

- **Burch-composite** holds conditional coverage 1.000 at 28 of the 29
  ρ ≤ 0.10 abort cells (its fallback intervals there are wide and cover the
  small truth) but **fails 4/36**: cond. coverage 0.49 at
  (0.10, 50, 5, chisq1) — the one ρ ≤ 0.10 miss — 0.072/0.077 at
  (0.30, 10, 5, t5/chisq1), 0.21 at (0.60, 10, 2, chisq1).
- **SEARLE-composite fails 23/36**: even inside the boundary region its
  conditional coverage drops with design size (0.87–0.88 at ρ=0.05 k=30,
  0.79–0.87 at k=50 — the exact-F interval is narrow and the selected samples
  bias it low), and off-boundary it collapses (0.19–0.30 at the ρ ≥ 0.10
  informative-design cells, 0.000 at (0.60, 10, 2, chisq1)).

**F2 — unconditional composite coverage ≥ 0.93: SEARLE fails 45/64, Burch
30/64.** Most F2 failures are inherited from the MC leg, which the composite
keeps on every converged rep: the MC default under-covers at the n=2 designs
(composite 0.82–0.89 there) and degrades badly on skewed data at large ρ —
at (0.60, k≥30, 5, chisq1) the composite ≈ MC alone covers **0.67–0.67** with
0 aborts, an incumbent defect the fallback never touches.

**F5 — tail symmetry: SEARLE fails 45/64, Burch 48/64**, dominated by the MC
leg's lower-tail miss asymmetry (lo_miss up to 0.16 vs hi_miss ~0.02 at the
n=2 cells; Burch's 0.000 upper-tail conditional misses add asymmetry of the
other kind).

**F4 (descriptive).** Median fallback width among abort reps, summed over the
36 reporting cells: SEARLE 21.68, Burch 20.96 — moot given F3.

**Per-cell conditional-on-abort coverage (every ≥ 100-abort cell; re-derived
by `data-raw/m111-fallback-verdict.R`):**

| ρ | k | n | dist | n_abort | SEARLE cond. | Burch cond. |
|---|---|---|---|---|---|---|
| 0.05 | 10 | 5 | gaussian | 764 | 0.937 | 1.000 |
| 0.05 | 10 | 5 | t5 | 756 | 0.929 | 1.000 |
| 0.05 | 10 | 5 | uniform | 723 | 0.925 | 1.000 |
| 0.05 | 10 | 5 | chisq1 | 791 | 0.922 | 1.000 |
| 0.05 | 30 | 5 | gaussian | 528 | 0.866 | 1.000 |
| 0.05 | 30 | 5 | t5 | 529 | 0.883 | 1.000 |
| 0.05 | 30 | 5 | uniform | 493 | 0.878 | 1.000 |
| 0.05 | 30 | 5 | chisq1 | 558 | 0.873 | 1.000 |
| 0.05 | 50 | 5 | gaussian | 344 | 0.837 | 1.000 |
| 0.05 | 50 | 5 | t5 | 349 | 0.848 | 1.000 |
| 0.05 | 50 | 5 | uniform | 344 | 0.872 | 1.000 |
| 0.05 | 50 | 5 | chisq1 | 387 | 0.791 | 1.000 |
| 0.05 | 10 | 2 | gaussian | 835 | 0.949 | 1.000 |
| 0.05 | 10 | 2 | t5 | 889 | 0.942 | 1.000 |
| 0.05 | 10 | 2 | uniform | 914 | 0.942 | 1.000 |
| 0.05 | 10 | 2 | chisq1 | 891 | 0.945 | 1.000 |
| 0.10 | 10 | 5 | gaussian | 524 | 0.906 | 1.000 |
| 0.10 | 10 | 5 | t5 | 508 | 0.896 | 1.000 |
| 0.10 | 10 | 5 | uniform | 483 | 0.919 | 1.000 |
| 0.10 | 10 | 5 | chisq1 | 591 | 0.892 | 1.000 |
| 0.10 | 30 | 5 | gaussian | 163 | 0.736 | 1.000 |
| 0.10 | 30 | 5 | t5 | 209 | 0.727 | 1.000 |
| 0.10 | 30 | 5 | uniform | 160 | 0.725 | 1.000 |
| 0.10 | 30 | 5 | chisq1 | 254 | 0.654 | 1.000 |
| 0.10 | 50 | 5 | chisq1 | 118 | 0.186 | 0.492 |
| 0.10 | 10 | 2 | gaussian | 801 | 0.943 | 1.000 |
| 0.10 | 10 | 2 | t5 | 761 | 0.929 | 1.000 |
| 0.10 | 10 | 2 | uniform | 823 | 0.948 | 1.000 |
| 0.10 | 10 | 2 | chisq1 | 794 | 0.940 | 1.000 |
| 0.30 | 10 | 5 | t5 | 125 | 0.296 | 0.072 |
| 0.30 | 10 | 5 | chisq1 | 233 | 0.240 | 0.077 |
| 0.30 | 10 | 2 | gaussian | 361 | 0.853 | 1.000 |
| 0.30 | 10 | 2 | t5 | 411 | 0.825 | 1.000 |
| 0.30 | 10 | 2 | uniform | 317 | 0.874 | 1.000 |
| 0.30 | 10 | 2 | chisq1 | 457 | 0.803 | 1.000 |
| 0.60 | 10 | 2 | chisq1 | 186 | 0.000 | 0.210 |

**Conditional-insufficient cells (abort count < 100 — reported, never judged;
no conditional claim is made for any of them):**
(0.10, 50, 5, gaussian: 88), (0.10, 50, 5, t5: 80), (0.10, 50, 5, uniform: 62),
(0.30, 10, 5, gaussian: 65), (0.30, 10, 5, uniform: 36),
(0.30, 30, 5, gaussian: 2), (0.30, 30, 5, t5: 3), (0.30, 30, 5, uniform: 0),
(0.30, 30, 5, chisq1: 10), (0.30, 50, 5, gaussian: 0), (0.30, 50, 5, t5: 0),
(0.30, 50, 5, uniform: 0), (0.30, 50, 5, chisq1: 3),
(0.60, 10, 5, gaussian: 2), (0.60, 10, 5, t5: 6), (0.60, 10, 5, uniform: 1),
(0.60, 10, 5, chisq1: 56), (0.60, 30, 5, gaussian: 0), (0.60, 30, 5, t5: 0),
(0.60, 30, 5, uniform: 0), (0.60, 30, 5, chisq1: 0),
(0.60, 50, 5, gaussian: 0), (0.60, 50, 5, t5: 0), (0.60, 50, 5, uniform: 0),
(0.60, 50, 5, chisq1: 0), (0.60, 10, 2, gaussian: 62), (0.60, 10, 2, t5: 83),
(0.60, 10, 2, uniform: 35)

## Disposition

Per the frozen aggregation rule, **NO-GO for both arms** — neither passes its
binding rules at every applicable cell, and the failures are structural, not
marginal (1 SEARLE / 4 Burch near-misses; the rest fail by wide margins):

- **D1 — the fallback question dies on selection, not on the fallback's own
  calibration.** Conditional on an off-boundary abort, no fixed classical
  interval covers: the abort selects degenerate samples, and the better the
  design (larger k·n), the narrower the classical interval and the worse the
  conditional miss. A GO would hand users a confident-looking interval in
  exactly the reps where the data are least representative.
- **D2 — the status-quo abort is vindicated for the off-boundary case** (it
  refuses to report where no assessed method covers conditionally) and the
  boundary case is already served by the opt-in `ci_method` values (D-012/
  D-013): a user who hits the abort is told which opt-in applies (M93/D-018),
  which keeps the choice — and the interpretation burden — with the user.
- **D3 — reopening evidence class:** a fallback construction that models the
  selection event itself (an interval valid conditional on
  `intraclass_singular_fit`, e.g. via conditional-likelihood or
  post-selection-inference arguments) demonstrated to hold conditional
  coverage across this grid's ≥ 100-abort cells; or a user-facing need
  restricted to the ρ ≤ 0.10 boundary region where Burch's conditional
  coverage measured 1.000 (28/29 cells; the (0.10, 50, 5, chisq1) exception
  bounds that region). Composite-vs-abort preference alone does not reopen it.
- **Landscape (not under test):** the MC default's own unconditional
  under-coverage on skewed high-ρ data (0.67 at (0.60, k≥30, 5, chisq1),
  0 aborts) is an incumbent defect this sweep surfaced; it goes to a ROADMAP
  candidate row, not this verdict.

The durable verdict is the M111 D-entry in `DECISIONS.md`.

## Open questions

- Whether both arms passing would favor per-data-kurtosis arm selection
  (SEARLE on ≈normal, Burch on heavy-kurtosis data) rather than one fixed
  fallback — out of this page's scope; the frozen tie-break picks one arm,
  and adaptive selection would need its own assessment — observed 2026-08-08. <!-- check: none — a scope note about a design not assessed here; nothing committed settles it -->
