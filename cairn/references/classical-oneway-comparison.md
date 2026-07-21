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

## Results — appended at T5

_Pending the sweep run; this section is authored in T5 against the frozen
criterion above._

## Disposition — appended at T6

_Pending; per-method GO/NO-GO and the default-replacement-vs-opt-in
recommendation land here and in the D-entry._

## Open questions

- Sweep not yet run at pre-registration time; Results/Disposition are authored in
  T5/T6 — observed 2026-07-21. <!-- check: none — a pre-registration status; the sweep runs in T5 and this note is completed then, tracked by the milestone tasks, not a runnable predicate -->
