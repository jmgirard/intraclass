# donner2002 — Testing the equality of two *dependent* ICCs (same subjects, two observer panels)

**Provenance.** Ingested 2026-07-19 by M67 from `cairn/references/sources/donner2002.pdf` (gitignored).
Pagination: printed journal pages 367–379. The shelf copy is a JSTOR scan
(download stamp 2016-04-15).
Extraction: unverified — first pass, values not yet re-read against the source. One point was spot-checked at the M67 review send-back (p. 367 prints no DOI); the page as a whole remains unchecked — observed 2026-07-19.

**Citation.** Donner A, Zou G (2002). "Testing the equality of dependent
intraclass correlation coefficients." *The Statistician* 51(Part 3):367–379.
© 2002 Royal Statistical Society. Received March 2001; final revision January
2002. Both authors: University of Western Ontario, London, Canada. *The
Statistician* is JRSS Series D; the paper prints the journal's short title, not
the series name, so cite it as printed.

**Role.** Ingested by M67 as the *dependent*-ICC member of the equality-testing
cluster. It is **the cluster's closest approach to this package's own territory**
— the ICCs it compares are interobserver-agreement ICCs on the same subjects,
estimated by the familiar ANOVA route — which makes its boundary line the most
load-bearing of the four. Nothing in the package traces to it — observed
2026-07-19.

## Why it is in the interrater literature at all

The motivating problem is squarely interrater: Browman et al. (1990) had four
readers — two radiologists and two clinical haematologists — independently
assess the radiographic vertebral index on 40 radiographs from myeloma
patients, asking "how interobserver agreement varied according to expertise in
radiologic diagnosis" (p. 367). That is one ICC for radiologists and one for
non-radiologists, both computed from **the same 40 patients** — so the two
coefficients are dependent, and the independent-sample tests of `konishi1989`
and its siblings do not apply.

## Design assumptions

| Axis | What the paper assumes |
|---|---|
| **Inferential target** | A hypothesis test of `H₀: ρ₁ = ρ₂`, two panels, **dependent** |
| Distribution | Multivariate normal, `X_i ~ N(μ, Σ)`, model (1), p. 368 |
| Structure | Two observer panels of sizes `k₁`, `k₂` rating the same `N` subjects; within-panel ICCs `ρ₁`, `ρ₂` and a between-panel interclass correlation `ρ₁₂` assumed **constant across all subjects** (p. 368) |
| Balance | `k₁ ≠ k₂` allowed — "an imbalance which may arise either because of experimental circumstance or as a result of data attrition" (p. 368); `k_l` constant across subjects within a panel |
| Estimator | ANOVA: `r_lA = (MSA_l − MSW_l)/(MSA_l + (k_l−1)MSW_l)`, "virtually indistinguishable in practice" from Elston's (1975) ML estimates (p. 368) |
| Admissibility | `k₁k₂ρ²₁₂ < {1+(k₁−1)ρ₁}{1+(k₂−1)ρ₂}` is required for (8) to be a non-singular normal likelihood (p. 371) |

Bross (1959) is cited for the sharp negative result: **an exact test of `H₀`
exists only if `k₁ = k₂` and `ρ₁₂ = 0`** (p. 368) — i.e. only in the independent,
balanced case this paper is written to escape.

## The five procedures compared

- **`T_Z`** — Fisher's classical `Z`-test. `Z_l = ½ln{(1+(k_l−1)r_lA)/(1−r_lA)}`
  (Eq. 2, p. 368), `V_l = k_l/{2(k_l−1)(N−2)}` (p. 369).
- **`T_ZM`** — the paper's proposal: the **Konishi–Gupta modified**
  transformation `Z_lM = √{(k_l−1)/(2k_l)} ln{(1+(k_l−1)r_lA)/(1−r_lA)}`
  (Eq. 4, p. 369), with the `(7−5k_l)/(N√{18k_l(k_l−1)})` bias correction
  (Eq. 5, p. 370) and the `H₀` covariance (Eq. 7, p. 370) that accounts for the
  dependence.
- **LR test** — §3.3, p. 370; numerical minimization only, "no expressions exist
  for `μ̂₁, μ̂₂, σ̂²₁` and `σ̂²₂`"; approximately `χ²` with 1 df.
- **`T_AF`** — Alsawalmeh & Feldt (1994), an `F`-moment approximation extending
  the Feldt (1980)/Kraemer (1981) Cronbach-α comparison (§3.4, p. 371); accurate
  only for `N ≥ 100` and `k_l ≥ 5`.
- **`T*_ZM`** — the naive comparator: `T_ZM` with `ρ̂₁₂` set to 0, i.e. ignoring
  the dependence.

**Why the modified transformation.** Fisher's `Z` "is effective only for `k = 2`;
for `k > 2`, normality and variance stabilization cannot be achieved
simultaneously" (§7, p. 378) — `Z_M` is what fixes that, and the approximation
improves as `k` grows.

## Simulation findings (§4–5, pp. 372, 373–375)

5000 runs per cell, SAS IML, `α = 0.05` two-sided, `μ₁ = μ₂ = 0`,
`σ²₁ = σ²₂ = 1`. Tables 1–2 (pp. 373–374) are significance levels at
`N = 25, 50, 100`; Table 3 (p. 375) is power.

- **Ignoring the dependence costs power, not validity.** `T*_ZM` is increasingly
  **conservative** as `ρ₁₂` grows, at every `N`; the power gap to `T_ZM` "often
  exceeds five or even 10 percentage points" at `N = 50` when `ρ₁₂ ≥ 0.4`
  (p. 372).
- **`T_AF` is anticonservative at small `N`** — type I error "often exceeds 0.07"
  at `N = 25` (p. 372), consistent with its own `N ≥ 100` precondition.
- `T_Z`, `T_ZM`, and LR all hold their level across the parameter values
  examined. `T_ZM` beats `T_Z` on power at `N = 50` (usually by under two
  percentage points) and is "virtually identical" to the LR test, "which demands
  considerably more computation and does not exist in closed form" (p. 372).

## Worked examples (§6, pp. 372–378)

Two, both with raw data committed to the paper (Tables 4–5, pp. 376–377) and
neither reproduced here — this note is boundary evidence, not an oracle source.
The first (CT scans, `N = 50`) is a straightforward rejection the paper itself
calls illustrative. **The second is the one that matters for the fence:** knee
joint angles, `N = 29`, `k₁ = k₂ = 3` (Eliasziw et al. 1994), where the two ICCs
are "clearly homogeneous", **no test is run**, and the paper instead *pools*
them into an approximate 95 % interval for the common `ρ` of **(0.973, 0.991)**
(p. 378). See the Boundary section for why that interval is still out of scope.

## Boundary (IP2)

**Testing whether two ICCs are equal is outside this package's contract**, and
that holds even here, where the coefficients being compared are exactly the kind
`intraclass` estimates. The package's job is to estimate an interrater ICC and
report a boundary-aware interval for it; comparing two such coefficients — with
or without a dependence correction — is a different inferential target. Adopting
it would require an **IP2 constitutional amendment (a D-entry plus an explicit
user decision), not a feature request**.

The second worked example is where the fence needs stating most carefully,
because the pooled interval on p. 378 *is* an ICC interval. It is still out of
scope: it is an interval for a common `ρ` assumed shared across two dependent
panels, reached by first accepting `H₀` — a post-test pooled estimand, not the
single-design ICC this package's estimand specs define.

## Traces to

- **Nothing in the package** — no estimator, interval method, oracle, or
  documented claim reads this page, by design. No `ORACLES.md` entry cites it.
  A grep for this citekey and for the author surnames across `R/`, `tests/`,
  `man/`, `vignettes/`, `NEWS.md`, `README.md`, `data-raw/`, and `ORACLES.md`
  returned no hits — observed 2026-07-19.
- `cairn/references/konishi1989.md` — the independent-sample general case this
  paper extends; `Z_M` is Konishi's transformation, and §7 (p. 378) notes
  Konishi & Gupta (1987) "considered only the case in which two intraclass
  correlation coefficients are independent".
- `cairn/references/bhandary2006.md` — a fifth cluster member by subject; the
  same IP2 fence covers it.
- `cairn/references/BIBLIOGRAPHY.md` and `INDEX.md`.

## Open questions

- **Unequal `k_l` across subjects is only approximated.** Missing observers are
  handled by substituting the Weinberg & Patel (1981) average
  `k_l0 = (N−1)⁻¹(Σk_li − Σk²_li/Σk_li)` (p. 378), valid "if the variability is
  not too substantial" — with no bound on what that means. The paper lists the
  general variable-`k_l` problem as open.
- **Non-normality is untested.** §7 closes by naming "the effect of
  non-normality on these procedures" as a subject for future research — notable
  because the whole cluster rests on the normal-theory compound-symmetric model.
- **Subjects must be rated by both panels.** The LR test is said to extend to
  the case where not all subjects are exposed to both panels (p. 379); the
  transformation-based tests are not.
- **No `ρ = 0` or near-zero cell.** The simulated `ρ` values are 0.4, 0.6, 0.8,
  0.95 (Tables 1–3) — **the highest floor of the five cluster papers**, the other
  four all reaching down to 0.1 (`konishi1989`, `young1998`, `naik2007`,
  `bhandary2006`; checked against all five notes, observed 2026-07-19). None of
  them reaches 0, so the near-zero corner where this package's own known failure
  modes live is untested across the whole cluster.
