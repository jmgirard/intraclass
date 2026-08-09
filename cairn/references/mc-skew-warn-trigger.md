# Runtime skew/kurtosis warn trigger — frozen reliability criteria (M114)

**Provenance.** Ingested 2026-08-08 by M114 from the committed M111 sweep
artifacts (`data-raw/m111-fallback-results.rds`, seed scheme
`cell$id * 1000000L + rep` in `data-raw/m111-fallback-sweep.R`), the M113
derived table (`data-raw/m113-skew-response-coverage.tsv`), and the frozen
precedent pages `mc-skew-response-comparison.md` (M113) and
`fallback-on-abort-comparison.md` (M111); no shelf source of its own.
Pagination: —.
Extraction: derived — no external source of its own, only as current as its
inputs, none re-read since 2026-08-08 — observed 2026-08-08.

**Scope.** The pre-registered reliability criteria for a runtime
data-measurable trigger for the one-way MC default's skew/kurtosis
under-coverage (the D-027 `warn` commission), and (once T2–T5 land) the
per-cell results they are read against. Assessment only: nothing here
changes exported behavior; the D-001 default fence and D-026's abort-side
adjudication are untouched. This is a reference, not an authority — status
lives in `ROADMAP.md`, decisions in `DECISIONS.md`.

**Evidence snapshot.**

- `data-raw/m111-fallback-results.rds` — committed M111 fixture; long `raw`
  table carries per-rep `lower`/`upper`/`aborted` per leg; wide `reps` table
  carries per-rep `mc_covered`/`mc_aborted`; per-rep seeded
  `base = cell$id * 1000000L + rep` — observed 2026-08-08. <!-- check: git grep -qF 'base <- cell$id * 1000000L + rep' data-raw/m111-fallback-sweep.R  # text-level proxy: the generating script pins the seed scheme; the rds columns are settled live by the T2 derivation script's own assertions -->
- `data-raw/m113-skew-response-coverage.tsv` — per-cell non-abort coverage
  and abort rate for the `mc` leg over the 64 M111 cells — observed
  2026-08-08. <!-- check: head -1 data-raw/m113-skew-response-coverage.tsv | grep -q 'coverage_nonabort' && grep -cq $'\tmc\t' data-raw/m113-skew-response-coverage.tsv -->

## Pre-registered rules — frozen 2026-08-08, before any derivation artifact (GP5)

**Known priors (authored with these in hand).** The mc leg's failing set and
its two-bucket partition are published (M113 page; D-027): 10 low-abort
failing cells (all t5/chisq1, worst non-abort coverage 0.6725) and 26
high-abort failing cells. The M111 grid, seeds, and per-rep coverage are all
committed. The genuinely blind content is every per-rep trigger statistic,
every fire rate, and the held-out battery's coverage — none has been
computed at freeze time.

### Candidate statistic family (plan gate 2026-08-08: kurtosis + skewness)

Both statistics read off the Burch standardized decomposition already shipped
in `burch_kappa_hat()` (`R/ci-classical.R:147-153`, eq. 13 of burch2011):
with subject means m_i, grand mean m, and one-way mean squares MSA/MSE,
z_ij = (y_ij − m_i)/√MSE + (m_i − m)/√MSA.

- **κ̂_bc** — excess kurtosis mean(z⁴) − 3, bias-corrected per
  `burch_kappa_bc()` (`R/ci-classical.R:156-158`, eq. 15; E = 0 under
  normality by construction).
- **γ̂** — the skewness analog mean(z³), uncorrected (no shipped bc form).

Both are computable at runtime from exactly the data a user passes; both are
undefined at MSA = 0 or MSE = 0 (a rep whose statistics are undefined counts
as *not fired*; the MC default's own singular-fit abort owns that corner).

**Candidate trigger set (48, closed):** K(c_k): fire iff κ̂_bc > c_k, for
c_k ∈ {0.5, 1.0, 1.5, 2.0, 3.0, 4.0}; S(c_g): fire iff |γ̂| > c_g, for
c_g ∈ {0.25, 0.5, 0.75, 1.0, 1.5, 2.0}; K(c_k) ∨ S(c_g) for all 36 pairs.
No other statistic, threshold, or combining form may enter the verdict.

### Cell classification (procedure-defined, over the derived tables)

Evaluated per cell among **non-aborted reps** (the trigger runs only where an
interval is returned). Let cov = non-abort mc coverage, ab = abort rate —
from `data-raw/m113-skew-response-coverage.tsv` for the 64 M111 cells and
from the held-out sweep's own per-rep rows for cells 65+.

- **Targeted:** ab ≤ 0.1 and cov < 0.93 (the bucket-(i) rule, D-027).
  Severity tiers: **T-a** cov < 0.80; **T-b** 0.80 ≤ cov < 0.93.
- **Protected:** gaussian cells with ab ≤ 0.1 and cov ≥ 0.93.
- **Descriptive:** everything else (high-abort cells — D-026's phenomenon,
  fenced out of this verdict; well-covered non-gaussian cells; uniform
  well-covered cells are reported against the W3 line but do not bind, the
  gate having named gaussian).

### Binding rules (severity-tiered floors, plan gate 2026-08-08)

Fire rate = share of a cell's non-aborted reps on which the candidate fires.

| # | Rule (binding) |
|---|---|
| W1 | Fire rate ≥ 0.90 at every T-a targeted cell (M111 and held-out alike). |
| W2 | Fire rate ≥ 0.50 at every T-b targeted cell (M111 and held-out alike). |
| W3 | Fire rate ≤ 0.10 at every protected cell (M111 and held-out alike). |

**Selection rule (mechanical, no free choices).** Among candidates passing
W1–W3 on every applicable cell: (1) minimize the maximum fire rate over
protected cells; (2) tie-break: maximize the minimum fire rate over targeted
cells; (3) tie-break: prefer form K over S over K∨S; (4) tie-break: larger
c_k, then larger c_g. The derivation script applies this ordering and emits
one winner (or none).

**Degrade rule.** If no candidate passes W1–W3, the D-027 disposition
degrades to `document`, recorded in the verdict D-entry as the bounded
finding: no candidate in the frozen family met the frozen floors/ceilings on
the derived tables.

### Held-out generalization battery (GP6; named before it runs)

10 cells, ids 65–74, n_rep = 1000, seeds `id * 1000000L + rep` (disjoint
from M111 ids 1–64; MC leg seed base + 100000L, per the M111 scheme), swept
by `data-raw/m114-heldout-sweep.R` with the M112-hardened harness idioms:

- **lognormal** — a_i = scaled (LN(0, 0.5²) − mean), variance ρ (skewed,
  heavy right tail; off-grid family): ρ ∈ {0.30, 0.60} × (k, n) ∈
  {(20, 3), (50, 5)} → ids 65–68.
- **laplace** — a_i = scaled double-exponential, variance ρ (symmetric,
  excess kurtosis 3; off-grid family): same ρ × geometry set → ids 69–72.
- **gaussian** — ρ = 0.30 × {(20, 3), (50, 5)} → ids 73–74 (protected-side
  generalization: false-fire ceiling off-grid).

(20, 3) is off the M111 (k, n) set {(10,5),(30,5),(50,5),(10,2)}. Held-out
cells enter W1–W3 through the same classification rules above (floor
applicability decided by their own measured cov/ab, same 0.93/0.80/0.1
constants). Errors stay normal; only the cluster effect is shaped — the M76
convention the M111 grid follows.

### Aggregation (frozen)

The verdict is one D-entry: either the selected trigger spec — statistic,
threshold, per-cell fire-rate table — or the degrade disposition. Read
mechanically by the derivation script from (this page, the derived tables);
any post-freeze edit to this page lands in its own commit before the first
derivation-artifact commit (M113 lesson).

## Results — derived 2026-08-08 from the committed tables

Backing tables: `data-raw/m114-warn-trigger-stats.tsv` (138,000 per-rep rows:
64 M111 cells × 2000 + 10 held-out cells × 1000), candidate ledger
`data-raw/m114-warn-trigger-candidates.tsv` (48 rows), per-cell verdict table
`data-raw/m114-warn-trigger-verdict.tsv`. Every figure re-derives by
re-running the three scripts; the identity proof (128000/128000 regenerated
SEARLE endpoints within 1e-12 of the stored fixture) certifies the
regenerated data are the fixture's own.

- **Classification** (frozen rules over the derived tables): 2 targeted T-a,
  12 targeted T-b (10 M111 bucket-(i) cells + held-out 66/68/70/72 — every
  (50, 5) lognormal/laplace cell; worst held-out non-abort coverage 0.825 at
  (0.60, 50, 5, lognormal)), 11 protected gaussian, 49 descriptive. The
  held-out (20, 3) cells all cover ≥ 0.939 — the defect tracks the
  large-k/n = 5 corner off-grid too.
- **Verdict: 0/48 candidates pass.** No candidate passes W1 (T-a floor 0.90)
  or W2 (T-b floor 0.50); 28/48 pass W3 alone. Best minimum targeted-cell
  fire rate: 0.1625 (K(0.5)∨S(0.25)) — not a near-miss anywhere.
- **Measured cause — dilution, not threshold placement.** The z-decomposition
  pools all k·n values; at n = 5 the cluster component carries ~20% of z's
  variance, so its kurtosis enters at weight² ≈ 0.04. At the worst cell
  (chisq1, cluster kurtosis 12, non-abort coverage 0.6725 — corrected at
  review from 0.676, which is cell 56's coverage while the median is cell
  60's) κ̂_bc has median
  0.11 and spread ≈ 0.35 against gaussian's median −0.03 — no separating
  threshold exists at any operating point the floors accept.

## Disposition

**Degrade** (frozen degrade rule): no candidate in the frozen family met the
frozen floors/ceilings on the derived tables. Recorded as D-028: the D-027
S2 disposition becomes `document`; the caveat ships via the response
milestone (ROADMAP candidate row, added by M114). Reopening class: a frozen
assessment of a cluster-effect-direct statistic family (D-028) — never
re-thresholding this one.
