# searle1971 — the exact-F interval's actual home, and what it does not claim

**Provenance.** Ingested 2026-08-08 by M116 from
`cairn/references/sources/searle1971.epub` (gitignored). **EPUB, not PDF** — the
Wiley Classics Library reflowable edition, so it carries **no fixed pagination**;
anchors below are chapter/section/equation/table numbers, which the edition
preserves, plus the publisher's own page-derived image filenames
(`images/414-2.gif` = printed p. 414) where a figure or table is an image.
Edition: "Copyright © 1971 by John Wiley & Sons, Inc. Wiley Classics Library
Edition Published 1997", Library of Congress Catalog Card Number 70-138919,
ISBN 0-471-18499-3 — a verbatim reprint of the 1971 text, so equation and table
numbers match the original and a `Searle 1971 (eq. N)` citation resolves here.
Extraction: verified 2026-08-08 against the source — Ch. 9 §9d read whole and
Table 9.14 read from its image render; every quotation below re-checked verbatim
against the extracted XHTML; the whole-book search for interval-length language
below was run over all eleven chapter files — observed 2026-08-08.

**Citation.** Searle, S. R. (1971). *Linear Models.* New York: Wiley.

**Role.** The source cited at six package sites for the `ci_method = "searle"`
exact-F interval. M116's source read: it **supplies the interval** and **makes no
claim about its length**.

## Where the interval actually is (Ch. 9, §9 "Normality Assumptions", subsection d)

**Chapter 9, section 9 "Normality assumptions", subsection d "Confidence
intervals", Table 9.14** — captioned verbatim:

> "TABLE 9.14. CONFIDENCE INTERVALS ON VARIANCE COMPONENTS AND FUNCTIONS
> THEREOF, IN THE 1-WAY CLASSIFICATION, RANDOM MODEL, BALANCED DATA"

introduced as:

> "Other exact confidence intervals readily available are those for the 1-way
> classification shown in Table 9.14. The first entry there is the appropriate
> form of (59). The last three entries are equivalent intervals for different
> ratio functions, all based on the fact that for F = MSA/MSE"

— the sentence running into **equation (60)**, the pivot's distributional fact.
Searle's letters: `a` classes, `n` per class (so repo `k` = Searle `a`, repo `n`
= Searle `n`; note this is *not* Burch's lettering, where `a` = classes and
`b` = per class).

**Table 9.14 row 3** is the shipped interval. Read from the table image
(`images/414-2.gif`, printed p. 414):

| parameter | lower limit | upper limit | confidence coefficient |
|---|---|---|---|
| `σ²_α/(σ²_α + σ²_e)` | `(F/F_U − 1)/(n + F/F_U − 1)` | `(F/F_L − 1)/(n + F/F_L − 1)` | `1 − α` |
| `σ²_α/σ²_e` | `(F/F_U − 1)/n` | `(F/F_L − 1)/n` | `1 − α` |

with the table's own footnote notation: `F = MSA/MSE` and
`Pr{F_L ≤ F[a−1, a(n−1)] ≤ F_U} = 1 − α`.

**This matches `searle_endpoints()` exactly** (`R/ci-classical.R`): the code
forms `g = F/F_U` for the lower endpoint and `F/F_L` for the upper, then
`rho_of_g(g) = (g − 1)/(g + n − 1)` — algebraically row 3, with the same
quantile paired to the same endpoint. Row 5 is the same interval on `θ = σ²_α/σ²_e`,
the θ-scale form the reducer's `g` parameterization passes through.

**Onward attribution.** Searle does not claim the ICC interval as his own:

> "The interval for σ²_e/(σ²_α + σ²_e) is given by Graybill (1961, p. 379) and
> that for σ²_α/σ²_e by Scheffé (1959, p. 229)."

Row 3 is the complement of the Graybill row, so the ICC interval traces to
Graybill (1961) through this table. Neither Graybill nor Scheffé is on the shelf.

## What this source does NOT claim: no interval-length property

**Nothing in Chapter 9 asserts that this interval is narrow, narrowest, shortest,
or optimal in length.** §9d is constructive throughout — it derives approximate
intervals (Satterthwaite, Graybill 1961 p. 369), then the exact ones — and the
only comparative remark in the subsection is Scheffé's *coverage* warning, that
his approximate interval can be

> "seriously invalidated by non-normality, especially of the random effects"

A whole-book search for interval-length vocabulary
(`shortest|narrow\w*|length of|lengths|\bwidth\b|shorter`, case-insensitive) over
all eleven chapter files returns hits in **two chapters only**, and neither is
about this interval. Chapter 2 has a single `shorter`, describing a *proof* —
"the much shorter proof of Banerjee (1964)". Chapter 3 has the rest, and they
concern a different object: the symmetric *t*-interval on a regression
coefficient `b_i` in the full-rank model (Ch. 3 §5), where Searle does state a
genuine optimality result —

> "there is only one symmetric confidence interval, the interval which has the
> optimal property that for given N − r and α it is the interval of shortest
> length"

— followed by a worked numeric comparison (7.66 vs 9.31) against a non-symmetric
interval on the same coefficient.

**Bearing on the withdrawn claim (M116).** The package described `"searle"` as
"best-calibrated and narrowest when the data are approximately normal" and cited
Searle 1971 + mcgraw1996 for the pivot. The narrowness half has no support here:
Searle makes no length claim about the Table 9.14 intervals, `mcgraw1996` uses no
width, length or narrowness language anywhere, and `burch2011` (§3, eq. 18;
§5) measures the *opposite* direction for platykurtic data against this very
interval. The Ch. 3 shortest-length result is the closest thing in the book to
the withdrawn wording and is recorded here as the **candidate provenance** for
it — a real optimality theorem attached to the wrong object. M116 does not
assert that is how the claim entered; the record is that no source the repo
holds supports it.

## Traces to (M116)

- The `Searle 1971 eq. 4/6` citation at `R/ci-classical.R` read **ohyama2025's**
  equation numbers as Searle's own; Searle has no eq. 4 or 6 of the kind, and the
  reprint is verbatim, so this was a wrong citation rather than an edition
  mismatch. M116 corrects it to Ch. 9 §9d / Table 9.14 / eq. (60). The
  `ohyama2025.md` cell keeps ohyama's numbering, which is faithful to that
  source, with a note at its table saying whose numbers they are — observed
  2026-08-08.
  <!-- check: ! git grep -qiE 'Searle 1971 eq\.? *4' -- R -->
- The narrowness withdrawal at the six user-facing sites rests on this note plus
  `burch2011.md`'s expected-length section and `data-raw/m116-classical-width-comparison.tsv`.
