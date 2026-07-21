# tenhove2018 — 20 IRR coefficients on 4 datasets: the choice dominates the answer

**Provenance.** Ingested 2026-07-19 by M66 from `cairn/references/sources/tenhove2018.pdf` (gitignored).
Pagination: printed book pages 67–75; the 9 PDF pages map one-to-one onto printed 67–75. This copy **is** the version of record (full pagination, volume, and DOI printed), unlike the three ten Hove shelf copies `INDEX.md` flags.
Extraction: verified 2026-07-19 against the source (all 9 PDF pages read through the reference list); Tables 1–3 re-read off the PDF text layer as well as the page images, which is how the Table 1 `Vision` discrepancy below was found — observed 2026-07-19.

**Citation.** ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2018). "On the
Usefulness of Interrater Reliability Coefficients." In M. Wiberg, S. Culpepper,
R. Janssen, J. González, & D. Molenaar (Eds.), *Quantitative Psychology*
(Springer Proceedings in Mathematics & Statistics, Vol. 233, pp. 67–75). Springer.
DOI 10.1007/978-3-319-77249-3_6. © Springer International Publishing AG, part of
Springer Nature 2018. Affiliation for all three authors: Research Institute of
Child Development and Education, University of Amsterdam.

**Role.** The earliest of the ten Hove papers on the shelf and the **problem
statement** the later ones answer: it demonstrates empirically that the choice of
IRR coefficient, not the data, drives the reported reliability. It supplies **no
estimator, no selection rule, and no reference value** — nothing in `ORACLES.md`
cites it and no test reads it. Its bearing on `choose_icc()` is motivational
rather than prescriptive; see the AC3 section below.

## The four datasets (Table 1, p. 68)

All four ship with the R package `irr` (Gamer et al. 2012), version 0.84.

| Dataset | S (subjects) | R (raters) | NR | Min | Max | Level |
|---|---|---|---|---|---|---|
| Diagnoses | 30 | 6 | 180 | 1 | 5 | Nominal |
| Vision | 7477 | 2 | 14954 | 1 | 3 | Ordinal |
| Video | 20 | 4 | 80 | 2 | 5 | Interval |
| Anxiety | 20 | 3 | 60 | 1 | 6 | Interval |

Table note, verbatim: "`S` = number of subjects; `R` = number of raters;
`NR` = number of ratings (`S × R`); `Min` = minimum score; `Max` = maximum
score".

Descriptions from the body (p. 68–69): *Diagnoses* (Fleiss 1971) is six
psychiatrists classifying 30 patients into five nominal categories; *Vision*
(Stuart 1953) is distance-vision performance of 7477 subjects on left and right
eye, "the two eyes are considered the two instruments (i.e., two raters)";
*Video* is "an artificial dataset consisting of four raters rating the
credibility of 20 videotaped testimonies"; *Anxiety* is "also an artificial
dataset". Both interval datasets are Likert-type but treated as interval on
Rhemtulla et al. (2012) grounds — "unbiased results may be obtained by treating
Likert-type rating scales containing at least five points as interval-level
rather than ordinal-level data" (p. 69).

**Discrepancy in the `Vision` row (M66 finding).** Table 1 gives `Max = 3`
(confirmed in both the page image and the PDF text layer), but the body text
p. 69 states the Vision ratings "were measured on a scale from 1 (*low
performance*) to 4 (*high performance*)". The `Video` row resolves the same
pattern in favour of *observed* rather than *scale* extremes — the text there
says ratings "could vary from 1 … to 6 … though observed scores only ranged from
2 to 5", matching its `Min = 2, Max = 5` row. Read that way, `Vision`'s `Max = 3`
asserts no subject was ever rated 4. **This was not resolved against the `irr`
data**: `irr` is a Suggests dependency (added at M42 for the comparison vignette,
corrected here — M66 recorded it as "not a package dependency") but was not loaded
to check, so the discrepancy is recorded as printed and left open — observed 2026-07-19. <!-- check: git grep -qwF 'irr' -- DESCRIPTION --> No repo
value depends on it.

## The 20 coefficients (Table 2, p. 70)

Nine nominal (`κ`, `κ_W`, `κ_W²`, `κ_Fleiss`, `κ_Exact`, `κ_Light`, `PA_N`,
`α_N`, `ι_N`), four ordinal (`W`, `ρ̄`, `PA_O`, `α_O`), and seven interval
(`PA_I`, `α_I`, `ι_I`, `Finn₂`, `ICC₂`, `r̄`, `A`). Table 2 records four
properties per coefficient: standard errors available, NHST available, missing
data handleable other than by listwise deletion, and whether `R > 2` is
supported.

Three `irr` coefficients were **excluded** (p. 70) "because they clearly measured
something different than the IRR": Stuart–Maxwell and Bhapkar (which "assess
homogeneity in marginal distributions") and Eliasziw et al. (1994) (which
"estimates intrarater reliability").

**How the ICC was specified** (p. 70, the load-bearing sentence for this
package): "we specified two-way models to treat both raters and subjects as each
being randomly drawn from a population, which is often the case in social and
behavioral research. In addition, for the ICC we computed the level of
consistency rather than the level of absolute agreement."

## Results (Table 3, p. 72)

The `ICC₂` row — the only row inside this package's contract — reads: *Diagnoses*
`c` (not computed, nominal data), *Vision* **0.70**, *Video* **0.16**, *Anxiety*
**0.20**. (Superscripts in Table 3: `*` > 0.40, `**` > 0.60, `***` > 0.80; `a`
not computable with more than two raters, `b` a version for another measurement
level was computed instead, `c` data are nominal.)

The spread across coefficients is the paper's result. Ranges as printed:

| Dataset | Range (matching measurement level) | Range (all coefficients) |
|---|---|---|
| Diagnoses | 0.17 – 0.46 | 0.17 – 0.46 |
| Vision | 0.71 – 0.85 | 0.60 – 0.85 |
| Video | 0.10 – 0.92 | 0.04 – 0.92 |
| Anxiety | 0.00 – 0.50 | −0.04 – 0.54 |

Summary statistics from the body (p. 71): *Diagnoses* `M = 0.40, SD = 0.11`;
*Vision* `M = 0.69, SD = 0.09`; *Video* `M = 0.26, SD = 0.24`; *Anxiety*
`M = 0.22, SD = 0.21`. The extremes are named there — *Video* runs from 0.04
(`κ_Fleiss`) to 0.92 (`Finn₂`), *Anxiety* from −0.04 (`κ_Fleiss`) to 0.54 (`W`).

Availability findings (pp. 72–73): standard errors exist for 13 of the 20
coefficients; a test that the coefficient equals zero exists for nine. On missing
data — "no dataset contained missing values", but `α_N`, `α_O`, `α_I` "use all
available data by counting disagreements among any observed pair of ratings on
the same subject (i.e., pairwise deletion)", `ι_N` and `ι_I` return a missing
value if any rating is missing, "whereas all other coefficients handle missing
data by listwise deletion".

## IP3 fence — the Landis & Koch benchmarks

The paper applies Landis and Koch (1977) heuristic labels (p. 71): "negative
values indicate a poor IRR; values between 0 and 0.20 indicate a slight IRR;
values between 0.21 and 0.40 indicate a fair IRR; values between 0.41 and 0.60
indicate a moderate IRR; values between 0.61 and 0.80 indicate a substantial
IRR, and values between 0.81 and 1.00 indicate an almost perfect IRR."

**This stays in the note and never enters package output** (IP3). It is the sixth
band scheme on the shelf, after Koo & Li (`koo2016.md`), Cicchetti
(`BIBLIOGRAPHY.md`), and the three schemes `trevethan2017.md` records — Fleiss
(1986), Portney & Watkins (2009), and Nunnally & Bernstein (1994) — and the paper uses it to make an *anti*-band point
(p. 72): "the interpretation of the IRR of a dataset by means of the benchmarks
of Landis and Koch (1977) depends on the choice of coefficient. For the dataset
*Diagnoses*, the IRR could be labelled either slight, fair, or moderate; for the
dataset *Vision* … moderate, substantial, or almost perfect; for the dataset
*Video*, the IRR could be labeled anywhere from slight to almost perfect."

The paper then questions the benchmarks directly (p. 74): "A relevant question
may be whether these benchmarks, which were designed for `κ`, can be used for
coefficients stemming from different conceptualizations of IRR."

## Bearing on `choose_icc()` (AC3)

`icc()`'s defaults are `type = "agreement"`, `raters = "random"`,
`unit = "single"` (`R/icc.R:373–375`); `choose_icc()` walks the
`choosing-an-icc.Rmd` decision tree over the same axes. Three anchored points:

1. **Random raters — agrees with the package default.** p. 70: two-way models
   treating "both raters and subjects as each being randomly drawn from a
   population, which is often the case in social and behavioral research". This
   is the same stance `icc()` encodes by defaulting to `raters = "random"` and
   warning on `raters = "fixed"`, and the same direction `tenhove2024.md` later
   hardens into "raters should seldom (if ever) be considered fixed".
2. **Consistency over agreement — a study choice, not guidance.** p. 70 records
   the authors computing consistency "rather than the level of absolute
   agreement", which is the opposite of `icc()`'s `type = "agreement"` default.
   The paper gives **no rationale and states no rule**: it is a specification
   choice for a coefficient-comparison exercise, not a recommendation about when
   to prefer consistency. It is therefore **not a divergence in guidance** and
   nothing follows for `choose_icc()`.
3. **Missing-data capability as a selection criterion** (p. 73): "a useful
   coefficient must be estimable with missing data", motivated by planned
   missingness where an assessment "takes approximately 6–8 h". The package's
   incomplete-design support is the same commitment; the sourcing for it is
   `tenhove2025b.md` (ADR-002/ADR-003), not this paper.

**What it does not supply.** No selection rule. The paper's own conclusion (p. 73)
is that the question is open — "Only if the theories and models behind IRR are
sorted out, we can start investigating why some IRR coefficients produce higher
values than others" — and its closing call is for future research
into per-coefficient benchmarks (p. 74). Its value to `choose_icc()` is as
citable evidence that a principled selection surface is *needed*, which is the
premise `choosing-an-icc.Rmd` already assumes.

**No divergence from current guidance was found** — see the work log.

## What this could source

Nothing is proposed here — M66 writes notes, not code (Scope).

- **Citable motivation for `choosing-an-icc.Rmd`.** Table 3's *Video* row (0.04
  to 0.92 on one dataset) is a sharper version of the argument
  `trevethan2017`'s Table 2 makes (0.51 to 0.87), and both are stronger than the
  vignette's current framing. Any such change is a separate milestone (Scope).
- **Not an oracle.** The `ICC₂` values (0.70 / 0.16 / 0.20) are printed to two
  decimals, computed by `irr` under a consistency specification, on datasets not
  reproduced in the paper. They are neither hand-checkable nor precise enough to
  pin against, and `irr` is not a dependency. Recorded as evidence, not as a
  candidate fixture.

## Traces to

Nothing in `R/`, `tests/`, `vignettes/`, or `ORACLES.md` reads this page — observed 2026-07-19. <!-- check: ! git grep -qiF 'tenhove2018' -- R tests vignettes cairn/references/ORACLES.md -->

- `cairn/references/tenhove2024.md` — the later selection-guidance paper by the
  same first author; this one poses the question that one answers.
- `cairn/references/tenhove2025b.md` — the planned-incomplete-data source that
  carries the missing-data commitment sketched here (p. 73).
- `cairn/references/trevethan2017.md` — the sibling "one dataset, many answers"
  demonstration, on ICC variants rather than across coefficient families.
- `cairn/references/fleiss1973.md` — `κ_Fleiss` here is the same author's
  nominal-agreement coefficient; `fleiss1973.md` records the kappa–ICC boundary.
- `cairn/references/BIBLIOGRAPHY.md` (ten Hove et al. 2018 entry) and `INDEX.md`.

## Open questions

- The `Vision` `Max = 3` vs. "scale from 1 … to 4" discrepancy above is
  unresolved; checking it needs the `irr` package, a Suggests dependency (M42;
  corrected here) that was not loaded — observed 2026-07-19. <!-- check: git grep -qwF 'irr' -- DESCRIPTION -->
