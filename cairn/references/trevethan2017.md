# trevethan2017 — cautions on ICC selection, reporting, and the interpretation bands

**Provenance.** Ingested 2026-07-19 by M66 from `cairn/references/sources/trevethan2017.pdf` (gitignored).
Pagination: **PDF pages 1–17**. The shelf copy is an online-first version carrying no journal pagination at all — no volume, no issue, no page range appears anywhere in it (see Open questions), so every anchor below is a PDF page and is written `PDF p. N` to keep that explicit.
Extraction: verified 2026-07-19 against the source (all 17 PDF pages read through the reference list); Table 1, Table 2, both figure captions, and the § 4 band criteria confirmed in place — observed 2026-07-19.

**Citation.** Trevethan, R. "Intraclass correlation coefficients: clearing the
air, extending some cautions, and making some requests." *Health Services and
Outcomes Research Methodology*. DOI 10.1007/s10742-016-0156-6. The shelf copy
prints the running head "Health Serv Outcomes Res Method", the dates "Received:
28 March 2016 / Revised: 30 July 2016 / Accepted: 18 August 2016", "© Springer
Science+Business Media New York 2016", and "Published online: 23 August 2016".
Author affiliation as printed: "Independent academic researcher and author,
Albury, NSW, Australia". **The 2017 in the citekey is the issue year, which this
copy does not print** — see Open questions.

**Role.** A cautions-and-reporting paper, not a methods paper: it supplies no
estimator and no reference value. Its relevance to this package is that it is the
clearest published statement of the *selection* misconceptions the
`choosing-an-icc.Rmd` vignette and `choose_icc()` exist to prevent, and it is a
second independent source (alongside `koo2016.md`) for judging an ICC against its
confidence interval rather than its point estimate. **No oracle value traces
here**, and no test, vignette, or `ORACLES.md` entry reads it — its only
in-repo citations are the `BIBLIOGRAPHY.md` entry and `INDEX.md` line added by
M66 itself.

## The model / form / type scheme (Table 1, PDF p. 4)

Trevethan uses a three-axis vocabulary — **Model** (1, 2, 3), **Form** (1, 2, …
*k*), **Type** (consistency, absolute) — and stresses the second number is *form*,
not the number of raters. Table 1's own summaries:

- **Model 1** — "A range of different raters assess different participants, and
  there is no match between raters and participants. This situation is
  infrequent. This model will usually produce lower ICCs than do the other two
  models." SPSS: "Third option 1-way random".
- **Model 2** — "The same raters assess all participants, and *theoretically* the
  raters are regarded as being randomly selected… It usually produces ICCs that
  lie between those of the other two models, but sometimes they are the same as
  those in Model 3." SPSS: "Second option 2-way random".
- **Model 3** — "The same raters assess all participants, but the raters are the
  only raters of interest for current purposes (the specific study setting)…
  It will usually produce the highest ICCs." SPSS: "First option 2-way mixed".
- **Form 1** — "On any occasion, only one reading/measurement is taken by each
  rater from each participant for purposes of analysis." Forms 2 and *k* cover
  averaged readings; "Any form >1 will produce higher ICCs than those under
  Form 1."
- **Type** — consistency "assesses the extent to which the sequence of scores
  corresponds across data sets"; absolute "assesses not only the sequence of
  scores in different data sets but also the extent to which the data are similar
  according to their magnitude. It produces lower ICCs than does the consistency
  option."

Type applies to Models 2 and 3 only: "for statistical reasons, only the absolute
option is relevant for Model 1. Therefore, Type brings the total number of ICC
versions to 10" (PDF p. 9) — the same count as `mcgraw1996`/`koo2016`.

## The central misconception: Form is not the number of raters

The paper's most-repeated caution (PDF pp. 6–9). Verbatim, PDF p. 6: researchers
"often confuse whether or not the data were averaged… Sometimes, for example, if
single scores were obtained from two raters, the form is incorrectly indicated as
being 2; if the single scores were obtained from three raters the form is
incorrectly indicated as 3." It quotes McGraw and Wong (1996, p. 33) that Form
refers to "the *average* rating for k judges, the *average* score for a k-item
test, or the *average* weight of k litter-mates".

Consequence, PDF p. 8: because averaged-measures ICCs "will always be higher",
and SPSS prints them adjacent to single measures, a researcher who misreads Form
as rater count "will first believe that the form is inevitably >1, namely the
number of raters being assessed" and report the inflated value. Trevethan links
this to publication incentives — "inappropriately choosing the averaged output
makes results look more impressive" (PDF p. 8, citing Franco et al. 2014 on
positive publication bias).

A second, subtler point (PDF p. 7): averaging can silently change *what is being
measured*. Where three raters' readings are averaged per occasion and an ICC is
computed across occasions, "intra*participant* consistency, rather than either
intra- or inter-rater consistency (reliability), would be the prime focus of
assessment because any distinction within or between the raters would have been
lost in the process of averaging."

## Example 1 — one data set, six different ICCs (Table 2, PDF p. 11)

McAra (2015) toe-brachial index (TBI) data, two readings per participant, 97
people, analyzed ten ways in SPSS:

| Type | M1 single (1,1) | M1 average (1,k) | M2 single (2,1) | M2 average (2,k) | M3 single (3,1) | M3 average (3,k) |
|---|---|---|---|---|---|---|
| Consistency | Not applicable | Not applicable | 0.78 | 0.87 | 0.78 | 0.87 |
| Absolute | 0.51 | 0.68 | 0.57 | 0.73 | 0.57 | 0.73 |

"In this case, six different ICCs were produced. They range from 0.51 to 0.87"
(PDF p. 11). Two structural facts the table demonstrates, both relevant to this
package:

- **Models 2 and 3 produce identical output here** — the paper had flagged
  (PDF p. 10) that Hallgren (2012) claims SPSS "always produces identical output
  for Models 2 and 3" while Shrout and Fleiss say only *sometimes*; Table 2 is the
  identical case.
- **The Pearson correlation equals the consistency single-measures ICC**: "the
  Pearson product moment correlation coefficient (calculated separately) is equal
  to the ICC of 0.78… with single measures and consistency agreement in both
  Models 2 and 3" (PDF p. 11). This is Trevethan's argument for why consistency
  "negates the reason for ICCs' existence" (PDF p. 9).

The defensible choice for these data is `ICC(3,1)` absolute agreement = **0.57**,
"the second lowest" of the six, because the tester was fixed and the readings
were not averaged (PDF p. 11). Its 95 % confidence interval "ranged from 0.0 to
0.82" (PDF p. 13).

## Example 2 (PDF pp. 13–15)

A different subset of the same doctoral data (first two of three TBI readings,
97 people, Fig. 2): `ICC(3,1)` absolute agreement = **0.80**, 95 % CI **0.72 to
0.86** (PDF p. 15). Fig. 1's supporting statistics (PDF p. 12): average
inter-foot difference 0.12 across all 97 readings, differences ranging 0.00 to
0.45, "18 % of these differences were larger than 0.20", significant at
`p < 0.001`.

## Judge the interval, not the point estimate

PDF p. 13, on Example 1: "An additional important component of ICC interpretation
involves inspection of confidence intervals. In this case, the 95 % confidence
interval ranged from 0.0 to 0.82 and was therefore obviously negatively skewed
given the obtained ICC of 0.57. This indicates, very informatively, that in
repeated testing with similar samples, in 95 % of cases some of the samples' ICCs
might well extend upward to 0.82, but in more samples they are likely to extend
down toward zero."

Restated as one of the paper's "two main points" (PDF p. 15): "again it seems
important to inspect data and confidence intervals carefully to gain a sense of
the conclusions that can be most appropriately drawn from them".

This is an **independent second source** for the stance `koo2016.md` records at
`koo2016` p. 161 — until M66 that note was the shelf's only source for it — and
it is the same stance as `PRINCIPLES.md` #3 (never a point estimate without an
interval).

## IP3 fence — the interpretation bands in this paper

§ 4 (PDF pp. 13, 15) surveys and criticizes qualitative band schemes. **All of it
stays in this note; none may enter package output** (IP3: the package never
qualitatively labels ICC magnitude — no poor/good/excellent, no benchmark cutoffs
in output, not even opt-in). Recorded because the paper is *anti*-band evidence,
which is the use IP3 explicitly permits in vignettes:

Bands as the paper reports them (PDF p. 13):

| Source (as cited by Trevethan) | Bands as reported |
|---|---|
| Fleiss (1986) | "ICCs <0.40 are poor, those from 0.40 to 0.75 are fair to good, and those >0.75 are excellent" |
| Portney and Watkins (2009) | "<0.75 poor to moderate, ≥0.75 good, and >0.90 'reasonable for clinical measurements'" |
| Nunnally and Bernstein (1994) | "ICCs should attain at least 0.90… for clinical measurements" |

The paper's own position is against unqualified use of any of them:

- PDF p. 13: the two common sets "seem to have acquired an unquestioned status
  despite Fleiss asserting that 'no universally applicable standards are possible
  for what constitutes poor, fair, or good reliability' and Portney and Watkins
  stating that their categories should be regarded as guidelines only and that
  the specific context of a study should be taken into account."
- PDF p. 15: "in some research the word *excellent* should be converted to become
  merely *good*, and descriptions of *fair* and *good* should become *poor to
  moderate*. This is not merely a superficial downward shift in the nature of the
  adjectives."
- PDF p. 15, refusing the opposite overcorrection: "The above is not intended to
  imply that the Fleiss categories should be discarded. As indicated above,
  different criteria might apply in different contexts."

Note the relationship to the existing shelf: `koo2016.md` records the *Koo & Li*
bands (the ones `getting-started.Rmd` reproduces) and `BIBLIOGRAPHY.md` records
Cicchetti (1994) as "the older sibling rule of thumb". Trevethan cites neither —
his three are Fleiss (1986), Portney & Watkins (2009), and Nunnally & Bernstein
(1994), i.e. a third, fourth, and fifth scheme. All five disagree with each
other, which is itself the strongest available argument for IP3. (`tenhove2018`
adds Landis & Koch (1977) as a sixth.)

## What this could source

Nothing is proposed here — M66 writes notes, not code (Scope). Available:

- **Anti-cutoff material for the vignettes.** `getting-started.Rmd`
  leads with the Koo & Li band table (lines ~113–120) and caveats after (~123–128)
  — observed 2026-07-19 (a framing question
  `koo2016.md` already raises for the maintainer). This paper supplies citable
  evidence that at least four incompatible band schemes are in circulation and
  that two of their own authors disclaimed universality — stronger than a caveat
  sentence. Any such change is a separate milestone (Scope).
- **A worked "same data, six answers" illustration.** Table 2 is a compact,
  citable demonstration of exactly what `choosing-an-icc.Rmd` argues. It is not
  an oracle — the underlying data are unpublished doctoral data not reproduced in
  the paper, so the six values cannot be recomputed (see Open questions).

## Bearing on `choose_icc()`

Not one of the two sources AC3 fences (`shieh2015`, `tenhove2018`), but recorded
because it bears on the same surface. Trevethan's axes are **Model / Form /
Type**; `choosing-an-icc.Rmd` (line 37) uses **type / unit / raters / design**.
The mapping is clean — his Type → the package's `type`, his Form → `unit`, his
Model → `raters` plus the one-way case — with one asymmetry: the package adds a
*design* axis (complete vs. incomplete) that Trevethan has no counterpart for,
and treats one-way as a design consequence rather than as a "Model 1" choice. No
divergence in *guidance*: his Model-1 caution ("no match between raters and
participants… infrequent") agrees with the vignette's framing of one-way, and his
Model-3 caution matches `icc()`'s existing warning on `raters = "fixed"`. **No
finding for a separate milestone from this source** — see the work log for the
AC3 pair.

## Traces to

Nothing in `R/`, `tests/`, `vignettes/`, or `ORACLES.md` reads this page — observed 2026-07-19.

- `cairn/references/koo2016.md` — the sibling interpretation source; same
  "judge the interval" stance, a different band scheme.
- `cairn/references/BIBLIOGRAPHY.md` (Trevethan entry) and `INDEX.md`.

## Open questions

- **The shelf copy has no journal pagination.** It prints a DOI, the received/
  revised/accepted dates, an online-publication date of 23 August 2016, and a
  © 2016 line — but no volume, issue, or page range, so it is an online-first
  copy rather than the issue version of record — `INDEX.md`'s shelf inventory
  lists this note among four such copies, alongside `tenhove2022`, `tenhove2024`,
  and `tenhove2020`. The citekey's
  `2017` is therefore *not* corroborated by this PDF. `BIBLIOGRAPHY.md`'s entry
  should carry volume/issue/pages from the issue version, which is not on the
  shelf and was not consulted here — flagged for the maintainer rather than
  filled in from memory (`PRINCIPLES.md` #4) — observed 2026-07-19.
- The six Table 2 values rest on unpublished doctoral data (McAra 2015) that the
  paper does not reproduce, so they are recorded as printed and **cannot** be
  independently recomputed — unlike the `bartko1966`/`bartko1976` examples, which
  were — observed 2026-07-19.
