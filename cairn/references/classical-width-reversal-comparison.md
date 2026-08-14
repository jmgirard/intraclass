# Burch's leptokurtic width reversal — frozen disposition rules for a both-components-non-normal grid (M118)

**Provenance.** Ingested 2026-08-13 by M118 from the committed source note
`burch2011.md` (itself ingested from `cairn/references/sources/burch2011.pdf`)
and the two committed sweep fixtures `data-raw/m76-sweep-results.rds` and
`data-raw/m111-fallback-results.rds`.
Pagination: printed journal pages 1018–1028, carried from `burch2011.md`.
Extraction: derived — every source figure here is carried from `burch2011.md`, whose own extraction status records a re-read against the shelf PDF on 2026-08-08; this page adds no reading of the source of its own — observed 2026-08-13.

**Scope.** The pre-registered rules deciding whether Burch (2011)'s reported
width reversal reproduces on a grid drawing *both* variance components from a
non-Gaussian family, and (once T5/T6 land) the per-cell table they are read
against. Not a source summary — `burch2011.md` owns the source. This is a
reference, not an authority: status lives in `ROADMAP.md`, decisions in
`DECISIONS.md`, architecture in `DESIGN.md`.

**Evidence snapshot.**

- Both committed repo grids draw the subject effect from the cell's family and
  the residual from a normal — observed 2026-08-13. <!-- check: git grep -qF 'vals <- rep(a, each = n) + stats::rnorm(k * n, 0, sd_e)' data-raw/m111-fallback-sweep.R && git grep -qF 'vals <- rep(a, each = n) + stats::rnorm(k * n, 0, sd_e)' data-raw/m76-coverage-sweep.R -->
- Burch's expected-length metric (eq. 18) compares against the same exact-F
  interval this package ships as `"searle"` — observed 2026-08-13. <!-- check: git grep -qF "expected-length ratio, not a comparison against some third interval" cairn/references/burch2011.md -->
- The derived table this page is read against does not exist at freeze time. <!-- check: none — written at T5; before then this page carries the rules only -->

## What is being decided

`D-012 Amendment 1` corrected three milestones' worth of shipped documentation
that called `"burch"` the wider of the two intervals: on both committed grids it
is the *narrower* one, in 16 of 16 and 59 of 64 cells. That amendment set its own
reopening condition — "a grid on which Burch's median width exceeds SEARLE's" —
and named where such a grid would most likely be found: Burch's own reversal,
untested here because both grids hold the residual Gaussian.

M118 builds that grid and decides whether the reversal reproduces. It decides
nothing about which interval users should choose: the coverage-based preference
for `"searle"` (D-027) rests on evidence this milestone does not touch, and the
`ci_method` contract is not opened here.

## Grid design (frozen)

Data are generated with both `A_i` and `e_ij` drawn from the cell's family,
each located and scaled per burch2011 §3 (p. 1022) so the population ICC equals
the cell's `rho`. Note Burch's `a` is the subject count (this repo's `k`) and
his `b` the per-subject count (this repo's `n`).

- **Fig. 2 block — the decision block.** `n = 5`, `k = 10(10)100`, `rho = 0.5`,
  over the six symmetric burch2011 Table 2 families: Uniform(0,1) (excess
  kurtosis −1.2), Power exponential(0,1,2.78) (−0.5), Normal(0,1) (0.0), t(10)
  (1.0), Laplace(0,1) (3.0), t(5) (6.0). This is Burch's own Fig. 2 design.
- **Anchor cell — the validation block.** `k = 100`, `n = 5`, `rho = 0.25`,
  uniform for both components: the one cell for which Burch prints both
  coverages and a length ratio (p. 1027).
- **M111 block — the comparison block.** `rho` ∈ {0.05, 0.10, 0.30, 0.60} ×
  `(k,n)` ∈ {(10,5), (30,5), (50,5), (10,2)} × {gaussian, t5, uniform, chisq1},
  differing from the committed M111 grid only in the residual's family.

`n_rep = 2000` per cell, the repo's standing count. Both legs are deterministic
closed forms off the one-way ANOVA sums of squares (D-013), so neither aborts
and both legs' figures are computed over the same replicates.

The asymmetric Table 2 families are outside this grid — dropped at the M118 plan
gate, not deferred. `chisq1` appears in the M111 block for comparability with the
committed grids and supports no disposition below.

## Pre-registered disposition rules — frozen 2026-08-13, before any derivation artifact (GP5)

**Known priors (authored with these in hand).** Three facts were in hand when
these rules were written, and the rules are worded against them:

1. On both committed subject-effect-only grids `"burch"` is narrower than
   `"searle"` almost everywhere, including at every gaussian cell (median ratio
   0.9620 on the larger grid). So at excess kurtosis 0 the ratio already sits
   **below** 1, and W1's t(10) limb requires the crossing to occur somewhere
   between excess kurtosis 0.0 and 1.0. That is a demanding limb and it was
   chosen knowingly.
2. Burch's own prediction is a sign change ordered by tail weight, not a blanket
   widening: shorter for symmetric platykurtic families, wider for symmetric
   leptokurtic ones (p. 1024).
3. The genuinely blind content is every figure this grid produces. No
   both-components measurement exists in this repo at freeze time.

Tag vocabulary for the verdict: `reproduced` | `partial` | `not-reproduced`.

| # | Rule (binding) | Source of the threshold |
|---|---|---|
| W1 | **Reproduced.** Both limbs hold on the Fig. 2 block. *Heavy-tailed limb:* for each of t(10), Laplace(0,1) and t(5), the median `"burch"`/`"searle"` length ratio exceeds 1 at ≥ 7 of the 10 subject counts. *Light-tailed limb:* for each of Uniform(0,1) and Power exponential(0,1,2.78), that ratio falls below 1 at ≥ 7 of the 10 subject counts. Normal(0,1) is descriptive and binds neither limb. | direction: burch2011 p. 1024; the ≥ 7-of-10 majority and the per-family form: frozen here (M118 plan gate 2026-08-13) |
| W2 | **Partial.** Exactly one of W1's two limbs holds. | frozen here |
| W3 | **Not reproduced.** Neither limb holds. The result is recorded as the finding and the question closes — no widened grid, no additional families, no re-set threshold. Reopening needs a superseding frozen assessment. | frozen here (M118 plan gate 2026-08-13) |

**Aggregation (frozen).** W1–W3 are mutually exclusive and exhaustive over the
Fig. 2 block, read directly off the derived table. The verdict is recorded as one
D-entry naming the tag and the per-family limb outcomes.

**Consequence (frozen, and identical under all three tags).** The disposition
changes what the package *says*, never what it *does*: M119 restates the measured
facts across the shipped surfaces, and no method recommendation, default or
`ci_method` behaviour changes on this evidence. D-027's coverage-based preference
for `"searle"` is untouched. Coverage is reported per cell for context — Burch's
claim is explicitly coverage-conditional ("thus wider intervals are warranted",
p. 1024) — but binds no rule above.

**Validation preconditions (binding before any rule is read).** The rules above
are read only if the grid first clears both anchors: the anchor cell reproduces
burch2011 (p. 1027) within the M118 AC4 tolerances, and the M111 block's gaussian
cells reproduce their committed M111 counterparts within stated Monte-Carlo
error. A failure of either is a defect in this grid, not a finding about Burch.

## Results

<!-- filled at T6 from the derived table; outside the freeze -->

## Disposition

<!-- filled at T7; outside the freeze -->

## Open questions

- Whether the crossing point in excess kurtosis can be located from this grid
  is left open: the six families sample tail weight at −1.2, −0.5, 0.0, 1.0, 3.0
  and 6.0, which brackets a crossing but does not resolve it.
