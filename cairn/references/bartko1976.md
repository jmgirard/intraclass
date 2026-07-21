# bartko1976 — a survey of misused ICC reliability coefficients (and a Table 3 misprint)

**Provenance.** Ingested 2026-07-19 by M66 from `cairn/references/sources/bartko1976.pdf` (gitignored).
Pagination: printed journal pages 762–765; the 4 PDF pages map one-to-one onto printed 762–765.
Extraction: verified 2026-07-19 against the source (all 4 PDF pages read through the reference list and the closing "(Received February 26, 1975)" line); Table 2 was recomputed in full from the Table 1 raw data and Table 3's four coefficients were recomputed from Table 2, which is how the Table 3 formula misprint below was found — observed 2026-07-19.

**Citation.** Bartko, J. J. (1976). "On Various Intraclass Correlation Reliability
Coefficients." *Psychological Bulletin* 83(5), 762–765. Printed masthead:
"Psychological Bulletin / 1976, Vol. 83, No. 5, 762–765". **No DOI is printed**
(the article predates DOI assignment); the reprint address given is National
Institute of Mental Health, Bethesda, Maryland 20014.

**Role.** The critical companion to `bartko1966.md`: a short survey arguing that
several widely used "reliability" coefficients — Winer's anchor-point method, the
Spearman–Brown/`ICC(2)` average-rating form, and Kuder–Richardson Formula 20 —
can be made arbitrarily favorable by transformations that leave the raters'
disagreement untouched. **No oracle value traces here** and no test reads it.
`shrout1979.md:163` cites its position on consistency vs. agreement. It carries
interpretation-flavored content, fenced under IP3 below.

## The three data sets and their ANOVA

Table 1 (p. 762) gives three sets of ratings on a 1-to-10 scale, 5 subjects × 2
raters, with the note "`r = 1.0` throughout" — i.e. all three have a
product-moment correlation of unity:

| Set | Rater pairs | Structure |
|---|---|---|
| 1a | (1,1) (2,2) (3,3) (4,4) (5,5) | perfect agreement |
| 1b | (1,5) (2,6) (3,7) (4,8) (5,9) | additive bias, `R2 = R1 + 4` |
| 1c | (1,2) (2,4) (3,6) (4,8) (5,10) | multiplicative, `R2 = 2·R1` |

Table 2 (p. 763), ANOVA components for those data (`df`, then mean squares for
1a / 1b / 1c):

| Source | df | MS 1a | MS 1b | MS 1c |
|---|---|---|---|---|
| Between subjects (`MSB`) | 4 | 5 | 5 | 11.25 |
| Within subjects (`MSW`) | 5 | 0 | 8 | 5.5 |
| — Between raters (`MSR`) | 1 | 0 | 40 | 22.5 |
| — Residual (`MSE`) | 4 | 0 | 0 | 1.25 |
| Total | 9 | — | — | — |

Sums of squares, same order: between 20 / 20 / 45; within 0 / 40 / 27.5; between
raters 0 / 40 / 22.5; residual 0 / 0 / 5.0; total 20 / 60 / 72.5.

**Independent recomputation (M66, not the paper's arithmetic).** All of Table 2
reproduces exactly from Table 1. For 1c: grand mean 4.5, `ΣX² = 275`, correction
`45²/10 = 202.5` → `SST = 72.5`; subject means `1.5, 3, 4.5, 6, 7.5` →
`SSB = 45`; rater means `3, 6` → `SSR = 22.5`; residual `27.5 − 22.5 = 5.0`. For
1b: `SST = 60`, `SSB = 20`, `SSR = 40`, residual `0`. Confirmed.

## Table 3 — the coefficients, and a misprint in the formula column

Table 3 (p. 763) prints four coefficients for each data set:

| Coefficient | 1a | 1b | 1c |
|---|---|---|---|
| One way: `ICC(1) = (MSB − MSW)/(MSB + [C−1]MSW)` | 1.0 | −.23 | .34 |
| Spearman–Brown: `ICC(2) = (MSB − MSW)/MSB` | 1.0 | −.60 | .51 |
| Two-way, Bartko (1966) | 1.0 | .24 | .48 |
| Winer's anchor point | 1.0 | 1.00 | .80 |

Table note, verbatim: "`ICC` = intraclass correlation, `MSB` = mean square
between, `MSW` = within-subjects variance, `MSE` = mean square residual,
`C` = columns = number of raters (assumed equal), and `R` = rows = number of
subjects."

**Misprint (M66 finding, verified by recomputation).** Rows 3 and 4 print `MSW`
in positions where the tabled values require `MSE` (the residual line). Rows 1
and 2 are correct as printed.

- Row 3 is printed `(MSB − MSW)/(MSB + [C−1]MSW + C[MSR − MSE]/R)`. For 1b as
  printed: `(5 − 8)/(5 + 8 + 2(40 − 0)/5) = −3/29 = −.10`, but the table says
  `.24`. Substituting `MSE`: `(5 − 0)/(5 + 0 + 16) = 5/21 = .238` → `.24` ✓. For
  1c: `(11.25 − 1.25)/(11.25 + 1.25 + 2(22.5 − 1.25)/5) = 10/21 = .476` → `.48` ✓.
- Row 4 is printed `(MSB − MSW)/(MSB + [C−1]MSE)`. For 1c as printed:
  `(11.25 − 5.5)/12.5 = .46`, but the table says `.80`. With `MSE` in the
  numerator: `10/12.5 = .80` ✓. For 1b: `(5 − 0)/(5 + 0) = 1.0` ✓.

Table 2 lists "Within subjects" and "Residual" as distinct lines with different
values (8 vs. 0 for 1b), so this is a genuine misprint and not loose notation.
`bartko1966.md` Eq. [15] — which row 3 is citing — uses the residual, confirming
the intended reading. **No repo value is affected**: nothing cites these
formulas, and the tabled coefficients themselves are correct.

Other formulas, as printed:

- `ICC(1) = (MSB − MSW)/[MSB + (C − 1)MSW]` — Eq. (1), p. 763. "Unequal numbers
  of raters per subject are not considered here." Range: "The `ICC(1)` ranges
  from `−1/(C − 1)` to 1.0."
- `ICC(2) = (MSB − MSW)/MSB` — Eq. (2), p. 764, the Spearman–Brown prediction
  form. "The `ICC(2)` (in absolute value) is greater than or equal to `ICC(1)`."

## The argument

The nondefensible-approach claim (pp. 762–763): "any constant additive operation
on any or all of the judge data in Winer's Table 4.5.3 will produce the same
variance–covariance matrix as the original data set and hence the same
reliability coefficient." Winer's anchor-point method scores data set 1b — where
one rater sits four points above the other on every subject — at `1.00`.

Summary, p. 764: "a high intraclass correlation reliability coefficient should
naturally be associated with small within-subjects variance and that a small
within-subjects variance should yield a high intraclass correlation reliability
coefficient." Concluding criterion, p. 765: the technique "that produces a high
reliability coefficient if and only if the within-subjects variance is small
(relative to the between-subjects variance of course) is the one-way ANOVA
intraclass correlation coefficient, `ICC(1)`."

Stated defect of the anchor-point model, p. 764: "the most severe being that
imperfect rating data can yield a perfect intraclass correlation of unity."

## Dichotomous data (pp. 764–765)

Reported for Winer's Table 4.5.10 data: an "averaged rating" (Spearman–Brown)
ICC of **.3683**, which Bartko notes "is identical to what one would obtain by
using the so-called Kuder–Richardson Formula Number 20"; Winer's single-rater
ICC **.1044**; Bartko's (1966) two-way ICC **.081**; the one-way `ICC(1)`
**.037**; and Fleiss's (1965) dichotomous ICC **.015**. After Winer's Table 4.5.12
rearrangement (p. 296 of Winer), which preserves row totals but changes rater
totals, `ICC(1)` and Fleiss's coefficient "remain unaltered" while Winer's rises
to **.6397** — Bartko's demonstration that the anchor-point coefficient responds
to a change with "no bearing on reliability".

## IP3 fence — interpretation content in this paper

The paper carries two interpretive statements. Both stay in this note; **neither
may enter package output** (IP3: the package never qualitatively labels ICC
magnitude, and no benchmark cutoff appears in output, not even opt-in):

- p. 763: "A negative intraclass correlation is usually taken to be zero
  reliability."
- p. 763: "The `1 − ICC` for intraclass correlation `≥ 0` is interpreted as the
  percentage of variance due to the disagreement among the raters."

Neither is a band or a cutoff, so neither is the kind of content IP3 most guards
against — but the first is a *reporting convention* that would silently floor a
negative estimate, and the package's boundary policy (`DESIGN.md § Boundary-fit
policy`, D-004) is the authority on that behavior, not this paper. Recorded, not
adopted.

## What this could source

- **A second hand-computable fixture.** The 1b/1c data sets (10 integers each)
  discriminate one-way from two-way and consistency from agreement more sharply
  than a random example: 1b has `r = 1.0` and pure additive rater bias, which is
  exactly the configuration where consistency and agreement diverge. Nothing in
  the package uses it — observed 2026-07-19. <!-- check: ! git grep -qiF 'bartko' -- R tests vignettes cairn/references/ORACLES.md -->
- **A negative-ICC example.** Data set 1b gives `ICC(1) = −.23`, a published
  negative value with printed mean squares behind it — potentially useful to the
  boundary-policy guard tests, which build their own fixture
  (`tests/testthat/test-boundary-policy.R`, `boundary_two_way()`) — observed
  2026-07-19. <!-- check: git grep -qF 'boundary_two_way' -- tests/testthat/test-boundary-policy.R -->

Neither is proposed here — M66 writes notes, not code (Scope).

## Traces to

Nothing in `R/`, `tests/`, `vignettes/`, or `ORACLES.md` reads this page — observed 2026-07-19. <!-- check: ! git grep -qiF 'bartko' -- R tests vignettes cairn/references/ORACLES.md -->

- `cairn/references/shrout1979.md:163` — records "Bartko's (1976) position that
  consistency is never an appropriate reliability concept for raters", which
  Shrout & Fleiss (1979, p. 425) report and reject. The position corresponds to
  this paper's p. 765 conclusion quoted above; note that Bartko frames it as a
  criterion on *which coefficient behaves properly*, not in the
  consistency/agreement vocabulary that `mcgraw1996` later established.
- `cairn/references/bartko1966.md` — the sibling paper this one builds on; its
  Eq. [15] is Table 3's row 3.
- `cairn/references/BIBLIOGRAPHY.md` (Bartko 1976 entry) and `INDEX.md`.

## Open questions

- The Winer (1971) Tables 4.5.3 / 4.5.6 / 4.5.10 / 4.5.12 that supply the
  dichotomous figures are **not reproduced in this paper** and Winer is not on
  the shelf, so the `.3683` / `.1044` / `.081` / `.037` / `.015` / `.6397` values
  above are recorded as this paper prints them and have not been recomputed from
  underlying data — unlike Tables 2 and 3, which were — observed 2026-07-19. <!-- check: none — a claim about extraction effort (Winer's dichotomous values transcribed as printed, not recomputed); settled by human re-read like the provenance status, not by a command -->
