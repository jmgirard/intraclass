# Classical boundary-robust one-way ICC CIs vs the incumbents — comparison (M76)

**Provenance.** Ingested 2026-07-21 by M76 from a first-hand simulation:
`data-raw/m76-coverage-sweep.R` over the two classical prototypes in
`data-raw/m76-classical-oneway-prototype.R`, against the package incumbents
(`ci_method` = `montecarlo` / `bootstrap` / `npbootstrap`). The method
constructions trace to `burch2011.md`, `mcgraw1996.md`, `ohyama2025.md`,
`ukoumunne2003.md`.
Pagination: —.
Extraction: first-hand record, nothing to re-verify against — observed 2026-07-21.

**Scope.** This is the M76 GO/NO-GO evidence page: the pre-registered criterion
(frozen before any run, GP5) plus the sweep results and per-method verdict. It is
not a source summary. It is a reference, not an authority — status lives in
`ROADMAP.md`, the durable GO/NO-GO decision in `DECISIONS.md`, the boundary-fit
contract in `DESIGN.md`. The criterion below is frozen: results are read against
it, never the reverse.

**Evidence snapshot.**

- Pre-registered criterion frozen before the sweep ran — this file, committed at T4 — observed 2026-07-21. <!-- check: none — a pre-registration claim about authoring order; git history (this file's introducing commit predates the results commit) is the record, not a runnable predicate -->
- Sweep results — `data-raw/m76-sweep-results.rds` — appended at T5 (see Results). <!-- check: none — the results row is authored in T5 after the ~5h run; before then the fixture does not exist and this page carries the criterion only -->

## What is being compared

Two **classical** boundary-robust interval constructions for the balanced one-way
random ICC, both prototyped and oracle-validated in T3:

- **SEARLE exact-F** — the exact-F pivot (mcgraw1996 Table 7 / ohyama2025 §2;
  Burch 2011 eq. 3 normal-based). Exact **under normality**.
- **Burch (2011) REML** — kurtosis-adjusted `log(1+nθ̂)` limits (burch2011 eq.
  6/13/15/16/17); interval width depends on the data kurtosis, the source of its
  claimed non-normality robustness.

against the three package incumbents: the **MC default** (glmmTMB REML
parameter-covariance simulation), the **parametric bootstrap**
(`ci_method="bootstrap"`, simulate-from-fit + refit), and the **npbootstrap**
(`ci_method="npbootstrap"`, ukoumunne2003 transformed bootstrap-t, M75).

The motivating defect (D-006): the MC default aborts (`intraclass_singular_fit`)
on a large fraction of near-zero-ICC datasets, where a classical closed-form
interval always exists.

## Sweep design (frozen)

- **Grid (16 cells):** `ρ ∈ {0.05, 0.10}` × `(k,n) ∈ {(10,5),(30,5),(50,5),(10,2)}`
  × `dist ∈ {gaussian, t5}`, where `t5` makes the **cluster effect** leptokurtic
  (scaled `t(5)`, kurtosis ≈ 6; errors stay normal — GP6). ICC = ρ in both.
- **n_rep:** 2000 per cell for the cheap methods (SEARLE, Burch, MC, npbootstrap).
  The parametric bootstrap (~19 s/dataset at 999 refits — ~86 h over the grid, so
  infeasible at full scale) runs **only at the two near-zero corner cells**
  (ρ=0.05, k=10, n=5; gaussian + t5) at n_rep=500, boot_samples=299 — a documented
  baseline point, not a full arm.
- **Seeding:** per-cell distinct seeds, per-rep (RR01 findings 1–2); data seed
  `cell·10⁶+rep`, incumbent resampling on disjoint offset streams.

## Pre-registered GO/NO-GO criterion — frozen 2026-07-21, before any run (GP5)

Tag vocabulary for the verdict ledger (filled at T6): `GO` | `NO-GO` per method.

| # | Rule (binding unless marked) | AC |
|---|---|---|
| C1 | **Abort.** Each classical method returns a finite interval on **100%** of datasets (0 aborts) at every cell; per-method n_ok/abort reported, and the MC default's abort rate reported alongside as the defect being addressed. | AC2 |
| C2 | **Coverage floor.** At each cell, two-sided coverage ≥ **0.93** (source-grounded: ukoumunne's own worst tabulated is 0.931, Burch's near-ρ=0 is "just under 0.93"). Over-coverage up to ~0.97 is tolerated; coverage < 0.93 is an under-cover fail at that cell. | AC3/AC4 |
| C3 | **Gaussian width dominance.** On **gaussian** cells, a classical method passes only if its **median width ≤ the MC default's median width computed on MC's non-aborted reps** at that cell (dominates MC where MC works). | AC3 |
| C4 | **Non-normal rule (binding, not descriptive).** On **t5** cells, a classical method passes only if coverage ≥ 0.93 **AND** no more than **0.02** below the better of {npbootstrap, MC} at that cell. SEARLE is expected to fail here (exact only under normality); Burch REML is the method this rule tests. | AC4 |
| C5 | **Tail symmetry.** Lower/upper miss-rates reported per method × cell. A passing cell needs roughly symmetric tails: neither tail-miss exceeds **0.045**, and `|lower_miss − upper_miss| ≤ 0.03`, so a two-sided pass cannot hide an asymmetric one (the BCa 14.2%/2.4% failure ukoumunne Table I exposes). | AC5 |
| C6 | **Verdict.** Aggregating C1–C5 across cells, a per-method GO/NO-GO is recorded as a D-entry; on GO, it recommends **default-replacement** (stating the `#3`/ADR-003 contract change) vs **opt-in `ci_method`**, decided from the evidence — not assumed. | AC6 |

**Aggregation rule (frozen).** A method earns an overall **GO** only if it passes
its applicable rules at **every** cell in the grid (a single under-covering or
non-dominating cell is a NO-GO for replacement, though it may still support an
opt-in recommendation — C6 decides which). SEARLE and Burch are judged
separately; the incumbents are the comparison baseline, not under test.

## Results — sweep of 2026-07-21

Backing data `data-raw/m76-sweep-results.rds` (129,000 rows; generated by
`data-raw/m76-coverage-sweep.R`, ~3.2 h). All figures are two-sided 95% nominal.
Coverage/tails are over each method's non-aborted reps; the C3 width is the
matched median over MC's non-aborted reps (as C3 specifies).

**C1 — abort (the motivating defect).** **SEARLE and Burch each returned a finite
interval on 100% of 32,000 datasets — 0 aborts, every cell.** The MC default
aborted (`intraclass_singular_fit`) on a large fraction of near-zero cells,
confirming and extending D-006's 28–39%:

| cell (Gaussian) | MC abort rate |
|---|---|
| ρ=0.05, k=10, n=2 | 0.43 |
| ρ=0.05, k=10, n=5 | 0.38 |
| ρ=0.05, k=30, n=5 | 0.24 |
| ρ=0.05, k=50, n=5 | 0.17 |
| ρ=0.10, k=10, n=2 | 0.38 |
| ρ=0.10, k=30, n=5 | 0.08 |
| ρ=0.10, k=50, n=5 | 0.04 |

npbootstrap also never aborted; the parametric bootstrap did not abort at the two
corner cells it ran.

**C2 / C4 — coverage.** SEARLE is **near-nominal and symmetric** across almost the
whole grid (0.940–0.957), failing the 0.93 floor at exactly **one** cell — the
high-`k` leptokurtic corner (ρ=0.10, k=50, n=5, t5) = **0.924** — which is also its
only C4 (non-normal) miss. This is the expected normal-theory degradation under
kurtosis as `k` grows (Burch §3). Burch **never under-covers** (0.937–0.991) and
passes C4 at every t5 cell (it exceeds both incumbents there), but it
**over-covers** at small `k` (0.96–0.99 at k≤30), the classic REML small-sample
conservativeness — it approaches nominal only by k=50.

**C3 — Gaussian width (matched to MC's non-aborted reps).** At k≥30 both classical
methods are **narrower** than MC (e.g. ρ=0.05, k=50: SEARLE/Burch 0.21/0.21 vs MC
0.27). At the **n=2** cells both are **wider** than MC (≈1.02–1.13 vs 0.86–0.89) —
a C3 failure **as written**, but MC's narrowness there is an artifact of its
**catastrophic under-coverage** (MC coverage 0.70–0.82 at n=2): a width comparison
against an interval that covers 70% of the time is not a fair dominance test. The
classical methods are wider precisely because they hold coverage.

**C5 — tail symmetry.** SEARLE passes at **every** cell (tail-difference ≤ 0.010,
no tail > 0.043). Burch fails at the four **n=2** cells: its miss is entirely
lower-tail (0.034–0.039 lower, 0.000 upper — `|diff|` up to 0.039 > 0.03),
reflecting its over-coverage asymmetry near the boundary at the smallest design.

**Ledger — fails against the frozen criterion:**

| method | C1 abort | C2 cover (/16) | C3 Gaussian width (/8) | C4 non-normal (/8) | C5 tails (/16) |
|---|---|---|---|---|---|
| SEARLE | 0 | **1** (0.10,50,5,t5) | 2 (both n=2) | **1** (0.10,50,5,t5) | 0 |
| Burch | 0 | 0 | 2 (both n=2) | 0 | 4 (all n=2) |

## Disposition

Per the frozen aggregation rule, an overall **GO for default replacement** needs a
clean pass at **every** applicable cell. Neither method achieves that, so both are
**NO-GO for replacement**; both are **GO as an opt-in `ci_method`** and both
decisively solve the motivating abort defect. The durable verdict is D-012.

- **D1 — SEARLE exact-F → NO-GO replace / GO opt-in.** Passes C1 (0 aborts) and C5
  (symmetric at every cell), near-nominal C2 at 15/16 cells. Blocks replacement on:
  the single leptokurtic under-coverage (C2/C4 at ρ=0.10, k=50, t5 = 0.924) and the
  n=2 C3 width fails (against a 0.70-covering MC). It is the **best-calibrated,
  narrowest** classical interval when data are ≈ normal, and holds up on t5 better
  than normal theory predicts (fails only the hardest leptokurtic cell).
- **D2 — Burch REML → NO-GO replace / GO opt-in (the robust/conservative choice).**
  Passes C1, C2 (all cells), C4 (all t5 cells — best on non-normality, exceeding
  both incumbents). Blocks replacement on: over-coverage/width at small `k` and the
  n=2 C5 tail asymmetry. It **never under-covers** and is the **non-normality-robust,
  never-under-cover** option, bought with width.
- **D3 — recommendation (C6): a follow-on opt-in implementation milestone, no
  default change.** Both are cleared to be planned as opt-in `ci_method` values
  (SEARLE for near-normal data; Burch for non-normality robustness / guaranteed
  coverage), whose primary value is a finite, well-calibrated interval **where the
  MC default aborts (4–44% of near-zero datasets)**. The default stays glmmTMB MC —
  **no `#3`/ADR-003 contract change**. This parallels D-006 → M75 (npbootstrap
  opt-in). → ROADMAP candidate + D-012; the follow-on plan decides whether to ship
  one or both and whether a classical **fallback-on-abort** default behavior (a
  distinct, later `#3` question) is worth a separate assessment.

**Scope fence.** This assessment is **normality-cell-limited on the non-normal axis
to one leptokurtic shape (t5)** and to `ρ ≤ 0.10`, `n ∈ {2,5}`, `k ≤ 50`. A
replacement verdict would need a wider non-normal battery (platykurtic + skewed,
per Burch Table 2) and larger ρ; the opt-in recommendation does not, since it adds
an option rather than changing the contract.

## Open questions

- The non-normal axis was assessed on **one** leptokurtic shape (t5); a
  default-replacement verdict would need Burch's wider battery (platykurtic +
  skewed, Table 2) and `ρ > 0.10`. Left to the follow-on opt-in milestone / a
  future replacement assessment — observed 2026-07-21. <!-- check: none — a scope note about evidence not gathered here; nothing in the committed repo settles whether a wider battery was run, and the follow-on milestone owns it -->
