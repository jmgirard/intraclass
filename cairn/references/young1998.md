# young1998 — Equality of two ICCs under unequal family sizes (Srivastava estimator)

**Provenance.** Ingested 2026-07-19 by M67 from `cairn/references/sources/young1998.pdf` (gitignored).
Pagination: printed journal pages 1363–1373. The shelf copy is a JSTOR scan
(download stamp 2016-04-15).
Extraction: verified 2026-07-19 against the source (all 11 PDF pages read to the final page — the references end p. 1373 and the publication dates sit *below* them; the French Résumé is on p. 1372, before the references, no appendix); every equation anchor and every quoted string re-checked, the §3 simulation settings confirmed value by value, the Figs. 1–4 shapes re-read off the page images, and the real-data estimates confirmed digit-for-digit. The M67 review's restoration of `−2 log Λ` to the Eq. (2.6) quotation is confirmed correct against p. 1367 — observed 2026-07-19.

**Citation.** Young DJ, Bhandary M (1998). "Test for Equality of Intraclass
Correlation Coefficients Under Unequal Family Sizes." *Biometrics*
54:1363–1373, December 1998. The article heads "BIOMETRICS 54, 1363-1373" —
neither an issue number nor a DOI is printed, so neither is given here.
Received April 1996; revised September 1997; accepted November 1997 — these dates
are printed on the **last page (p. 1373), below the references**, not on the
title page, which carries no dates at all.
Young: North Dakota State Department of Health and
Consolidated Labs, Bismarck; Bhandary (corresponding): Department of Statistics,
North Dakota State University, Fargo. Carries a French *Résumé* (p. 1372) per
*Biometrics* convention of the period.

**Role.** Ingested by M67 as the first of the unequal-family-size pair. It is the
**two-population** case; `naik2007` generalizes it, and that note carries the
full overlap analysis (a shared-vs-differs table) rather than repeating the
derivation here — observed 2026-07-19. Ingested as
evidence of a contract boundary; nothing in the package traces to it — observed
2026-07-19.

## The gap it fills

The paper's own framing (p. 1363): inference on a single-sample `ρ` is
well studied, but its "extension to multisample problems based on several
multivariate normal distributions has received very little attention", and of the
multisample work that exists — Donner & Bull (1983), `konishi1989`, Huang & Sinha
(1993) — **"none of the above authors derived any test for unequal family
sizes"**. The motivating objection is blunt: "In real practice, we come across
families with unequal numbers of children and, hence, this is a very important
practical problem… In real world research, having families of equal size is
artificial" (p. 1363).

## Design assumptions

| Axis | What the paper assumes |
|---|---|
| **Inferential target** | Hypothesis test, `H₀: ρ₁ = ρ₂` vs `H₁: ρ₁ ≠ ρ₂` — **exactly two** populations |
| Distribution | Multivariate normal, `x_i ~ N_{p_i}(μ_i, Σ_i)`; Rao (1973) compound-symmetric structure, Eq. (2.1), p. 1364 |
| Structure | Familial / one-way — families are clusters, **no rater facet** |
| Balance | **Unequal family sizes**, by conditional analysis "assuming family sizes fixed though unequal" (p. 1363) |
| Variances | **`σ²₁ = σ²₂ = σ²` is assumed** — stated flatly on p. 1366. This is the restriction `naik2007` removes |
| `ρ` range | `max_{1≤i≤k}(−1/(p_i−1)) ≤ ρ ≤ 1` (p. 1364) — **negative `ρ` admitted** |

The machinery is a **Helmert orthogonal transformation** `U_i = Q x_i` (Eq. 2.2,
p. 1364; the `Q_{p_i}` matrix is printed in full, with
`c_{p_i} = Σ_{r=1}^{p_i−1} r²` on p. 1365), of which the paper says the
transformation from `x` to `u` "is independent of ρ", plus **Srivastava's (1984)
estimator** `ρ̂ = 1 − γ̂²/σ̂²` (Eq. 2.3, p. 1365).

## The three tests

- **LRT**, Eq. (2.6), pp. 1366–1367 — asymptotically `χ²` with 1 df. It is an
  *approximate* LRT: Srivastava's estimators "are not MLEs but are CAN", so
  (2.6) "is an approximation to the true likelihood ratio test statistic −2 log Λ.
  But, in the asymptotic sense, it converges to the same distribution" (p. 1367).
- **Large-sample `Z`-test**, Eq. (2.8), p. 1367 —
  `Z = (ρ̂₁ − ρ̂₂)/{S√(1/k₁ + 1/k₂)}`, with `S²` the pooled variance estimator
  under `H₀` built from the Srivastava & Katapa (1986) asymptotic variance
  (Eq. 2.7, p. 1367). Asymptotically `N(0,1)`.
- **`Z*`-test**, Eq. (2.9), p. 1367 — same numerator over
  `√(S²₁/k₁ + S²₂/k₂)`, a consistent estimator of `var(ρ̂₁ − ρ̂₂)` under
  `H₀ ∪ H₁` rather than under `H₀` alone.

## Simulation and the recommendation (§3, pp. 1368–1371)

FORTRAN + IMSL; 30 family vectors per population; family sizes from a truncated
negative binomial with **mean 2.86 and success probability 0.483**, held to
2–15 siblings, citing Rosner et al. (1977) and Srivastava & Keen (1988);
`ρ₁, ρ₂` over all combinations of 0.1–0.9 in steps of 0.1 — the paper's words are
that they "took on all combinations possible over the range of values from 0.1 to
0.9 at increments of 0.1" (p. 1370); **10,000 replications** per combination
(p. 1371); `α ∈ {0.01, 0.05, 0.10}`.

**What was run and what is printed are not the same.** All combinations were
simulated, but Table 1 (pp. 1368–1369) *reports* a selected subset — for each
`ρ₁` only four or five `ρ₂` values, chosen to straddle `ρ₂ = ρ₁`. So the table is
a digest of the run, and an absent `(ρ₁, ρ₂)` cell means unprinted, not
unsimulated. Table 1 gives rejection proportions in nine columns, three per test
at the three `α` levels: `NORM01`/`NORM05`/`NORM10` are the `Z`-test,
`CHI01`/`CHI05`/`CHI10` the LRT (the legend calls it "the χ²-test statistic",
which is the same object — the LRT is asymptotically `χ²₁`), and
`NORM*01`/`NORM*05`/`NORM*10` the `Z*`-test (legend, p. 1369).

**Label drift between table and figures.** Figures 1–4 label the `Z*`-test
**`STAR05`**, not `NORM*05` as Table 1 does; `CHI05` and `NORM05` keep their
table names. Same three tests, two naming schemes in one paper.

The conclusion is unambiguous and repeated at least four times (Summary p. 1363,
§1 p. 1364, §3 p. 1371, and twice on p. 1372 — closing §3 and again in §4):
the **LRT is consistently more powerful** than either
asymptotic test across the `(ρ₁, ρ₂)` grid, and "we strongly recommend the
likelihood ratio test for use in practice", its computational complexity being
"easily overcome" with modern computing. Figures 1–4 (pp. 1370–1371) plot the
`α = 0.05` power curves at `ρ₁ = 0.1, 0.4, 0.6, 0.8`, in each case bottoming out
at `ρ₂ = ρ₁` where `H₀` is true — a V for Figs. 2–4, and for Fig. 1 only the
rising right arm, since `ρ₁ = 0.1` sits at the left edge of the plotted range.

## Real-data illustration (§4, p. 1372)

Srivastava & Katapa's (1986) pattern-intensity-on-soles-of-feet data, 14 families
(Table 2, p. 1372), **randomly split into two samples**; `H₀` is accepted at all
three levels by all three tests, which the paper concedes it should be, the two
samples being one population split in half. A null-case sanity check, not a
demonstration of power — and not reproduced here, this note being boundary
evidence rather than an oracle source.

**One detail is worth keeping.** All three point estimates are **negative**
(`ρ̂₁ = −0.2917`, `ρ̂₂ = −0.2504`, pooled `−0.2682`) — admissible under the
compound-symmetric parameterization (see the `ρ` range above), impossible for a
variance-components ICC constrained to `[0, 1]`. The three values and the
two-samples-of-seven partition (Table 2, p. 1372: sample A = families 1, 3, 4, 6,
8, 11, 12; sample B = 2, 5, 7, 9, 10, 13, 14) are confirmed against this source.

`bhandary2006` is said to apply the **same** Srivastava (1984) estimator to this
same 14-family data set and report *positive* estimates (0.8804, 0.9567, 0.8508),
the difference being the partition — three samples of 5/5/4 families with
daughters' and sons' values put together — rather than the estimator.
**That half is asserted from the `bhandary2006` note, not from this source, and
`bhandary2006` is still at unverified extraction status (M71).** The young1998
side of the comparison is verified; the bhandary2006 side inherits whatever M71
finds — observed 2026-07-19.

## Boundary (IP2)

**Testing whether two ICCs are equal is outside this package's contract.**
`intraclass` estimates interrater ICCs and their intervals; it does not test
hypotheses comparing coefficients across populations. Adopting such a test would
require an **IP2 constitutional amendment — a D-entry and an explicit user
decision — not a feature request.** The familial one-way design here has no rater
facet at all, which puts it doubly outside the interrater contract.

## Traces to

- **Nothing in the package** — no estimator, interval method, oracle, or
  documented claim reads this page, by design. No `ORACLES.md` entry cites it.
  A grep for this citekey and for the author surnames across `R/`, `tests/`,
  `man/`, `vignettes/`, `NEWS.md`, `README.md`, `data-raw/`, and `ORACLES.md`
  returned no hits — observed 2026-07-19.
- `cairn/references/naik2007.md` — the direct generalization (`g` populations,
  unequal variances); **the overlap between the two papers is analyzed there**.
- `cairn/references/bhandary2006.md` — Bhandary's three-population sibling, which
  reuses this paper's estimator, transformation, simulation design, and worked
  data set; a fifth member of this cluster by subject, under the same IP2 fence.
- `cairn/references/konishi1989.md` — the equal-family-size multisample test this
  paper cites as leaving the unequal case unsolved.
- `cairn/references/BIBLIOGRAPHY.md` and `INDEX.md`.

## Open questions

- **The `σ²₁ = σ²₂` assumption is never tested or justified**, only stated
  (p. 1366). `naik2007` §1 makes exactly this objection and builds its
  generalization on it.
- **No `ρ = 0` cell.** The grid runs 0.1–0.9, so the boundary is unexercised —
  despite the estimator explicitly admitting negative `ρ`, and despite the real
  data example landing at `ρ̂ ≈ −0.27`, well outside the simulated range.
- **The `k = 30` families per population is the only sample size tried**
  ("Thirty vectors of family data were created for each of the two populations",
  p. 1370; confirmed as the sole sample size across all 11 pages). No small-`k`
  cell, so the paper's LRT recommendation is unsupported at small family counts —
  the point at which `bhandary2006` is reported to have found asymptotic LRT size
  inflation as high as 0.4089 at `K = 5`. That figure comes from the
  `bhandary2006` note, **still unverified (M71)**; the "only k = 30 was tried"
  half is verified here and stands on its own.
