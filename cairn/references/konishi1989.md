# konishi1989 — Approximate LRT for the equality of several intraclass correlations

**Provenance.** Ingested 2026-07-19 by M67 from `cairn/references/sources/konishi1989.pdf` (gitignored).
Pagination: printed journal pages 93–105.
Extraction: verified 2026-07-19 against the source (all 13 PDF pages read to the final page — the references end p. 105, no appendix); every equation number, theorem anchor and quoted passage re-checked against the page images, and the Tables 1–2 grids re-read. One correction: the `q = 2` scale `c` on p. 99 had been recorded as untranscribable because the scan was "unreliable at that line" — it renders cleanly at 400 DPI and is now transcribed; the scan's real defect is its text layer, which returns the AMS classification as `62Hl5`/`62HIO` — observed 2026-07-19.

**Citation.** Konishi S, Gupta AK (1989). "Testing the equality of several
intraclass correlation coefficients." *Journal of Statistical Planning and
Inference* 21:93–105. The first-page journal banner prints "21 (1989) 93-105"
(the running head on pp. 94–105 carries the authors *and* a truncated title —
"S. Konishi, A.K. Gupta / Tests for intraclass correlations" — with no volume or
pagination) — neither an issue number nor a DOI appears on the article, so
neither is given here. The first-page footer prints
"0378-3758/89/$3.50 © 1989, Elsevier Science Publishers B.V. (North-Holland)".
North-Holland (Elsevier). Received 1 June 1987; revised
manuscript received 29 December 1987; recommended by T. Hayakawa. AMS
classification 62H15 (primary), 62H10 (secondary) — the title page OCRs both as
letters (`62Hl5`, `62HIO`). Konishi: Institute of
Statistical Mathematics, Tokyo; Gupta: Bowling Green State University, Ohio.

**Role.** Ingested by M67 as the general-case member of the equality-testing
cluster — the `q`-population hypothesis test that the rest of the cluster
specializes. It is here **as evidence of a contract boundary**, not as a
capability source. Nothing in the package traces to it (see "Traces to") —
observed 2026-07-19.

## The estimand is a hypothesis, not a coefficient

`H₀: ρ₁ = ⋯ = ρ_q = ρ` with `ρ` unspecified, against `H₁` that not all the
intraclass correlations are equal (p. 93). The object produced is a **test
statistic and a rejection rule**, never a coefficient or an interval — which is
the whole reason this paper documents a boundary rather than crossing one.

## Design assumptions

| Axis | What the paper assumes |
|---|---|
| **Inferential target** | A hypothesis test across `q` populations, `q ≥ 2` |
| Distribution | Multivariate normal (§3.2); extended to elliptic (§3.3) and to general nonnormal populations with finite fourth cumulants (§3.1) |
| Structure | `Σ_α = σ²_α[(1−ρ_α)I_{p_α} + ρ_α e_α e_α′]` — compound symmetry, one-way/familial; **no rater facet, no crossed design** (p. 93) |
| Samples | `q` **independent** samples, sizes `N_α`; dimensions `p_α` may differ, except §4 which requires `p₁ = ⋯ = p_q = p` |
| Motivating domain | Sibling resemblance — "blood pressure, stature, body weight or lung capacity" (p. 93) |

## The two test procedures

**Approximate LRT (ALR), Eq. (2.6), p. 96.** The exact LRT is unavailable: under
`H₀` the ML estimates of `σ²_α` and `ρ` "can not be expressed in closed form"
and need "a complicated iterative procedure which is not readily available"
(p. 95). So the paper substitutes the closed-form pooled estimate
`r = Σ N_α p_α(p_α−1)r_α / Σ N_α p_α(p_α−1)` (Eq. 2.5, p. 95) for the common
`ρ`, where `r_α` is the per-population ML estimator (Eq. 2.2, p. 95).

**The null distribution is not `χ²`.** This is the paper's main technical point
(§3, p. 96): `−2 log Λ` "does not, in general, have an asymptotic chi-squared
distribution under the null hypothesis". Its limit is a **linear combination of
independent `χ²₁` variates**, `Σ ω_α χ²₁(α)`, whose weights `ω_α` are the latent
roots of `ΨG` (Theorem 3.1, p. 99; normal case Theorem 3.3, p. 100; elliptic
case Theorem 3.4, pp. 100–101). **Exact `χ²₁` requires all three of normality,
equal `p`, and `q = 2` — none of them suffices on its own.** In the general
finite-fourth-cumulant case at `q = 2`, the limit is `c·χ²₁` — the latent roots
of `ΨG` are `c` and 0 — with

```
c = {√2(1−ρ)}⁻² (a²₁h₂ + a²₂h₁)(φ²₁ + φ²₂)                       (p. 99)
```

where `a_α` is defined at Eq. (3.2), `h_α = f_α p_α(p_α−1)/{1+(p_α−1)ρ}²`
(p. 98), and `φ²_α` is the fourth-cumulant term of Eq. (3.10). So `c` depends on
the unknown `ρ` *and* on per-population cumulants, and must be estimated —
p. 99 says the coefficients "have to be estimated from the data" and points at
the literature on linear combinations of `χ²` variates without recommending a
route.

*(An earlier version of this note declined to transcribe this expression,
recording that "the shelf scan [was] unreliable at that line". That was wrong:
the line renders cleanly at 400 DPI and is transcribed above. The scan is in fact
poor in a different place — the **text layer**, not the image: `pdftotext` returns
the AMS classification as `62Hl5`/`62HIO`, letters for digits, while the page
image plainly prints 62H15/62H10. Judge legibility from a rendered image, never
from the extracted text.)*

Under normality
with `p₁ = ⋯ = p_q = p`, the weights stop depending on unknown parameters
(Theorem 3.3 and the remark following, p. 100), but the limit remains a weighted
sum. Only in conjunction — two `p`-variate *normal* samples — is the asymptotic
null exactly `χ²₁` (p. 100).

**Z-transformation test (ZT), Eq. (4.4), p. 102** — asymptotically `χ²` with
`q−1` df. Built on the variance-stabilizing transformation
`z(r_α) = {(p−1)/2p}^{1/2} log[{1+(p−1)r_α}/(1−r_α)]` (Eq. 4.1, p. 101), with
the improved normal approximation of Konishi (1985): mean
`m_α = z(ρ_α) + N_α⁻¹(7−5p)/{18p(p−1)}^{1/2}`, variance `(N_α−2)⁻¹` (Eq. 4.2,
p. 101). A bias-corrected variant `Σ(N_α−2){z*(r_α) − z*}²` (Eq. 4.5, p. 102)
is also `χ²_{q−1}`; **for `q = 2` the two are the same test** (p. 102).

## Numerical results (§5, pp. 102–104)

1000 replicated samples, two `p`-variate normal populations, `α = 0.05`;
Table 1 (p. 103) is `p = 3`, Table 2 (p. 104) is `p = 5`, both at
`(N₁,N₂) = (25,25)` and `(25,50)`, entries ×1000. Findings as stated on p. 103:
empirical significance levels are "not significantly different from the nominal
level 0.05" for all `ρ₁ = ρ₂` — the paper's own yardstick being that no observed
relative frequency sits more than `2{(0.05)(0.95)/1000}^{1/2}` (≈ 0.0138) from
0.05; the ALR test is more powerful than ZT when
`ρ₁ ≠ ρ₂`; and the power of both increases as the dimension `p` increases. Other
`(N₁, N₂, p, α)` combinations were tried and left the picture "essentially
unchanged" (p. 103).

## Boundary (IP2)

**Testing whether two or more ICCs are equal is outside this package's
contract.** `intraclass` estimates interrater ICCs and their intervals; it does
not test hypotheses comparing coefficients across groups or populations. That is
IP2's ICC-only identity, and adopting an equality test would be a
**constitutional amendment — a D-entry plus an explicit user decision — not a
feature request**. This note exists so the question is settled from a citable
record rather than re-argued from memory.

## Traces to

- **Nothing in the package** — no test, no oracle, no vignette, no documented
  claim reads this page, and that is by design (see Boundary above). No
  `ORACLES.md` entry cites it. A grep for this citekey and for the author
  surnames across `R/`, `tests/`, `man/`, `vignettes/`, `NEWS.md`, `README.md`,
  `data-raw/`, and `ORACLES.md` returned no hits — observed 2026-07-19.
- `cairn/references/bhandary2006.md` — a fifth member of this cluster by
  subject; its own cluster-reassignment finding asks that the two be read
  together, and the same IP2 fence covers both.
- `cairn/references/donner2002.md` — extends the Konishi transformation to
  *dependent* ICCs and cites this paper directly.
- `cairn/references/BIBLIOGRAPHY.md` and `INDEX.md`.

## Open questions

- **The `ρ = 0` boundary is untested**, as in the rest of this cluster: the
  simulations start at `ρ₁ = 0.1` (Tables 1–2). The near-zero corner where this
  package's own known failure modes live is not exercised here.
- **The admissible `ρ` range is never stated.** Compound symmetry requires
  `ρ ≥ −1/(p−1)` for `Σ_α` to be positive definite, and the sibling papers in
  this cluster state that bound explicitly; this one does not. Re-checked across
  all 13 pages (title page through the references ending p. 105, no appendix) —
  the bound appears nowhere, observed 2026-07-19.
- **The `ω_α` weights must be estimated.** The paper notes the coefficients
  "have to be estimated from the data" (p. 99) and points at the literature on
  distributions of linear combinations of `χ²` variates, but supplies no
  recommended computational route — one reason the normal / equal-`p` / `q = 2`
  conjunction carries the applied weight.
