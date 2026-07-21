# Bibliography

**Provenance.** Ingested 2026-07-18 by M63 from the D-007 split of the pre-migration `cairn/references/REFERENCES.md` (16 entries, body moved byte-identically), then extended and corrected in place by M64 (→ 18 entries), M65 (→ 27), and M66 (→ 34); M68 added only this block. On 2026-07-19 the `jorgensen2019` entry was replaced in place by `vanderark2023` — the published version of record of the same study, under a different first author — leaving the count at 34; M67 then added the four equality-testing entries (→ 38).
Pagination: per-entry; each entry states whether a field is printed on its own source.
Extraction: **verified 2026-07-19 (M72)**, at a depth set by provenance (D-008). The two depths are AC6's and are **not** interchangeable: the sixteen entries that moved as text at the D-007 split were taken field-by-field through their sources' title pages — title, byline, venue, year, volume, issue, pages, DOI — for the ten of them whose source is on the shelf, while the twenty-two authored from shelf PDFs by M64–M67 took the lighter consistency pass, whose title-page extraction was delegated and whose every acted-on finding was then re-derived in-session against the PDF. Do not read the second depth as the first. Across both, every field the source does not print is now annotated as unprinted at the entry rather than left to read as transcribed. Entries whose source is absent from the shelf carry an in-place marking saying so at the entry itself, so a reader meets the limit where they meet the claim; that is a limit of the shelf, not an omission of this pass. What the pass changed: `tenhove2024`'s title was restored (it had been abbreviated and its subtitle dropped); the `vispoel2022` entry's compared-program list lost **GENOVA**, which that source never mentions and which belongs to `lee2024a`; `xiao2009` was found to be a **second** citekey-vs-issue-year case alongside `shieh2015` (its own header prints 2010, the cover sheet 2009); and the unprinted-issue-number annotations were added across the MDPI, Elsevier, Wiley, Springer and T&F entries that assert one. `mcgraw1996`'s bound-in correction page carries no folio, volume, or issue of its own, so that correction's `1(4), 390` is publisher-record too. Counts are deliberately not pinned here (LESSONS 2026-07-19/M70).

The repo's bibliography. Oracle provenance lives in
[`ORACLES.md`](ORACLES.md); per-source extractions with page/table anchors live
in the `<citekey>.md` source notes indexed by [`INDEX.md`](INDEX.md).

- Bartko, J. J. (1966). The intraclass correlation coefficient as a measure of
  reliability. *Psychological Reports, 19*, 3–11. (No DOI or issue number is
  printed on the article.) (The one-way/two-way/mixed ICC formulas and the
  correlation-coefficient argument; guidance only, no oracle — see
  [`bartko1966.md`](bartko1966.md).)
- Bartko, J. J. (1976). On various intraclass correlation reliability
  coefficients. *Psychological Bulletin, 83*(5), 762–765. (No DOI is printed.)
  (The case against Winer's anchor-point method; **Table 3 misprints `MSW` for
  `MSE` in rows 3–4**, found by recomputation, no repo value affected — see
  [`bartko1976.md`](bartko1976.md).)
- Bhandary, M., & Fujiwara, K. (2006). A small sample test for the equality of
  intraclass correlation coefficients under unequal family sizes for several
  populations. *Communications in Statistics — Simulation and Computation, 35*(3),
  765–778. doi:10.1080/03610910600716894. (The issue number is not printed on the
  article; it is the publisher's, recorded 2026-07-19, M72.) (Gaussian familial `F_max` equality
  test; outside the contract boundary, ingested as boundary evidence — see
  [`bhandary2006.md`](bhandary2006.md).)
- Bobak, C. A., Barr, P. J., & O'Malley, A. J. (2018). Estimation of an inter-rater
  intra-class correlation coefficient that overcomes common assumption violations
  in the assessment of health measurement scales. *BMC Medical Research
  Methodology, 18*, 93. doi:10.1186/s12874-018-0550-6. (Bounded-scale
  heteroscedasticity and pooled-study inflation of the inter-rater ICC — see
  [`bobak2018.md`](bobak2018.md).)
- Brennan, R. L. (2001). *Generalizability Theory.* Springer. (**Chapter 3 is on the
  shelf** as `brennan2001_ch3`, supplied by the maintainer 2026-07-19; the rest of the
  book is not, so the *whole-book* fields — publisher, city, year — are still taken
  from outside it. They are corroborated secondarily by the reference list of
  `tenhove2020`, which cites "Brennan, R. L. (2001). Generalizability theory.
  New York, NY: Springer" — a citation of the book, not the book. The two-facet
  decomposition this work is cited for in `ORACLES.md` (O-Bayes-Rep) **is verified**
  against Ch. 3, printed pp. 56 and 58, M72, 2026-07-19.)
- Brooks, M. E., et al. (2017). glmmTMB balances speed and flexibility among
  packages for zero-inflated generalized linear mixed models. *The R Journal,
  9*(2), 378–400. (**Not on the shelf — fields not verified against the source**,
  M72, 2026-07-19. The byline is also abbreviated "et al." rather than enumerated;
  the paper has further authors this entry does not name.)
- Burch, B. D. (2011). Assessing the performance of normal-based and REML-based
  confidence intervals for the intraclass correlation coefficient. *Computational
  Statistics and Data Analysis, 55*, 1018–1028. doi:10.1016/j.csda.2010.08.007.
  (Issue number not printed in the PDF; the running foot gives only
  `55 (2011) 1018–1028`. M76 primary source for the REML-based CI leg — its §4
  arsenic example is a published REML ρ-interval oracle — see
  [`burch2011.md`](burch2011.md).)
- Cicchetti, D. V. (1994). Guidelines, criteria, and rules of thumb for evaluating
  normed and standardized assessment instruments in psychology. *Psychological
  Assessment, 6*(4), 284–290. doi:10.1037/1040-3590.6.4.284. (Interpretation-band
  source for `getting-started.Rmd`, M40 — the older sibling rule of thumb: ICC < 0.40
  poor, 0.40–0.59 fair, 0.60–0.74 good, 0.75–1.00 excellent. Cited as one convention
  among several, with caveats; the package computes no verdict — #4/#18.)
  (**Not on the shelf — fields and bands not verified against the source**, M72,
  2026-07-19. The bands are load-bearing for `getting-started.Rmd`, so this is the
  most consequential of the entries whose source is off the shelf.)
- Donner, A., & Zou, G. (2002). Testing the equality of dependent intraclass
  correlation coefficients. *The Statistician, 51*(Part 3), 367–379. (Published in
  the JRSS Series D journal, which prints only the short title.) (No DOI is
  printed on the article.) (Two ICCs from
  the same subjects rated by two observer panels — the cluster's only genuinely
  interrater member; outside the contract boundary, ingested as boundary evidence
  — see [`donner2002.md`](donner2002.md).)
- Fleiss, J. L., & Cohen, J. (1973). The equivalence of weighted kappa and the
  intraclass correlation coefficient as measures of reliability. *Educational and
  Psychological Measurement, 33*, 613–619. (The kappa–ICC boundary; shelf evidence,
  not an oracle — see [`fleiss1973.md`](fleiss1973.md).)
- Hedges, L. V., Hedberg, E. C., & Kuyper, A. M. (2012). The variance of intraclass
  correlations in three- and four-level models. *Educational and Psychological
  Measurement, 72*(6), 893–909. doi:10.1177/0013164412445193. (Delta-method
  large-sample variances for variance-share ICCs in nested designs; **outside the
  contract boundary — no rater facet** — see [`hedges2012.md`](hedges2012.md).)
- Jorgensen, T. D. (2021). How to estimate absolute-error components in structural
  equation models of generalizability theory. *Psych, 3*(2), 113–133.
  doi:10.3390/psych3020011. (The article prints "Psych 2021, 3, 113–133" with **no
  issue number**; the 2 is decoded from the MDPI DOI, whose `psych3020011` encodes
  volume 3, issue 02, article 0011 — recorded 2026-07-19, M72.) (The M7 lavaan
  engine's SEM absolute-error method —
  see [`jorgensen2021.md`](jorgensen2021.md).)
- Konishi, S., & Gupta, A. K. (1989). Testing the equality of several intraclass
  correlation coefficients. *Journal of Statistical Planning and Inference, 21*,
  93–105. (Neither a DOI nor an issue number is printed on the article, which
  heads "21 (1989) 93-105".) (The general `q`-population
  approximate LRT, whose null distribution is a weighted sum of `χ²₁` variates
  rather than `χ²`; outside the contract boundary, ingested as boundary evidence
  — see [`konishi1989.md`](konishi1989.md).)
- Koo, T. K., & Li, M. Y. (2016). A guideline of selecting and reporting intraclass
  correlation coefficients for reliability research. *Journal of Chiropractic
  Medicine, 15*(2), 155–163. doi:10.1016/j.jcm.2016.02.012. (The article heads
  "Journal of Chiropractic Medicine (2016) 15, 155–163" with **no issue number**;
  the 2 is the publisher's — recorded 2026-07-19, M72.) (The primary
  interpretation-band source for `getting-started.Rmd` — see
  [`koo2016.md`](koo2016.md).)
- Lee, H., & Vispoel, W. P. (2024). A robust indicator mean-based method for
  estimating generalizability theory absolute error and related dependability indices
  within structural equation modeling frameworks. *Psych, 6*(1), 401–425.
  doi:10.3390/psych6010024. (The article prints "Psych 2024, 6, 401–425" with **no
  issue number**; the 1 is decoded from the MDPI DOI, whose `psych6010024` encodes
  volume 6, issue 01, article 0024 — recorded 2026-07-19, M72.) (Confirms the raw
  indicator-mean formula, Eqs. 8 (printed p. 405) and 25 (printed p. 407), both
  dividing by n_i − 1 with no bias correction — **verified against the source**
  2026-07-19, M72, after the maintainer put the PDF on the shelf mid-milestone;
  "robust" = an ordinal scale-coarseness correction, not a bias correction.)
- McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some intraclass
  correlation coefficients. *Psychological Methods, 1*(1), 30–46 (+ correction,
  *1*(4), 390). (Journal, year, volume, issue, and pages of the article itself are
  printed on its title page and confirmed. The **correction's** own volume, issue,
  and page are *not*: the correction is bound into the shelf copy as a final page
  carrying no folio, volume, or issue of its own — it cites only the original
  article — so `1(4), 390` comes from the publisher record, recorded 2026-07-19,
  M72. The correction page also misprints the article's title as "Intraclass
  Correlations Coefficients"; the title page reads "Correlation".) (The package's
  ICC(A,·)/ICC(C,·) labels and Case 3A — see
  [`mcgraw1996.md`](mcgraw1996.md).)
- Mehta, S., Bastero-Caballero, R. F., Sun, Y., Zhu, R., Murphy, D. K., Hardas, B.,
  & Koch, G. (2018). Performance of intraclass correlation coefficient (ICC) as a
  reliability index under various distributions in scale reliability studies.
  *Statistics in Medicine, 37*(18), 2734–2752. doi:10.1002/sim.7679. (The issue
  number is not printed on the article; it is the publisher's, recorded
  2026-07-19, M72.) (How the
  subject distribution, not scale quality, drives `ICC(2,1)` — see
  [`mehta2018.md`](mehta2018.md).)
- Naik, D. N., & Helu, A. (2007). On testing equality of intraclass correlations
  under unequal family sizes. *Computational Statistics & Data Analysis, 51*,
  6498–6510. doi:10.1016/j.csda.2007.02.029. (No issue number is printed on the
  article.) (Equality of `g` ICCs with unequal family sizes **and** unequal
  variances; recommends the score test or `T₀`, and reports the Srivastava-based
  LRT going negative on up to 25 % of samples. Outside the contract boundary,
  ingested as boundary evidence — see [`naik2007.md`](naik2007.md).)
- Ohyama, T. (2025). A comparison of confidence interval methods for the
  intraclass correlation coefficient based on the one-way random effects model.
  *Japanese Journal of Statistics and Data Science, 8*, 587–602.
  doi:10.1007/s42081-025-00292-3. (Independent published coverage/width comparison
  of one-way-ICC CI methods; the M62 NBOOT-prototype oracle — see
  [`ohyama2025.md`](ohyama2025.md).)
- Rosseel, Y. (2012). lavaan: An R package for structural equation modeling.
  *Journal of Statistical Software, 48*(2), 1–36. (M7 SEM engine.) (**Not on the
  shelf — fields not verified against the source**, M72, 2026-07-19.)
- Saha, K. K. (2012). Profile likelihood-based confidence interval of the
  intraclass correlation for binary outcome data sampled from clusters.
  *Statistics in Medicine.* doi:10.1002/sim.5489. (Beta-binomial ICC intervals;
  binary outcomes, outside the contract boundary — see
  [`saha2012.md`](saha2012.md).)
- Saha, K. K., & Paul, S. R. (2005). Bias-corrected maximum likelihood estimator of
  the intraclass correlation parameter for binary data. *Statistics in Medicine,
  24*, 3497–3512. doi:10.1002/sim.2197. (The BCML point estimator underlying
  Saha (2012); binary outcomes — see [`saha2005.md`](saha2005.md).)
- Searle, S. R., Casella, G., & McCulloch, C. E. (2006). *Variance Components.* Wiley.
  (**Not on the shelf — fields not verified against the source**, M72, 2026-07-19.)
- Shieh, G. (2016). Choosing the best index for the average score intraclass
  correlation coefficient. *Behavior Research Methods, 48*(3), 994–1003.
  doi:10.3758/s13428-015-0623-y. (Cited as `shieh2015` after the 2015
  online-publication/copyright year printed on the same page; the issue year is
  2016. The issue number is not printed on the article — the header reads
  "Behav Res (2016) 48:994–1003" — and is the publisher's, recorded
  2026-07-19, M72. See `xiao2009` below for the second citekey-vs-issue-year case.) (`ICC(2) = 1 − 1/F*` is negatively biased and MSE-dominated by four
  alternatives — but it is an ANOVA plug-in the package does not use — see
  [`shieh2015.md`](shieh2015.md).)
- Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in assessing
  rater reliability. *Psychological Bulletin, 86*(2), 420–428. (The six ICC forms
  and the O1 worked example — see [`shrout1979.md`](shrout1979.md).)
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2018). On the usefulness of
  interrater reliability coefficients. In M. Wiberg et al. (Eds.), *Quantitative
  Psychology* (Springer Proceedings in Mathematics & Statistics, Vol. 233,
  pp. 67–75). Springer. doi:10.1007/978-3-319-77249-3_6. (20 IRR coefficients on
  4 `irr` datasets; the coefficient choice, not the data, drives the reported
  reliability — see [`tenhove2018.md`](tenhove2018.md).)
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2020). Comparing hyperprior
  distributions to estimate variance components for interrater reliability
  coefficients. In M. Wiberg et al. (Eds.), *Quantitative Psychology* (Springer
  Proceedings in Mathematics & Statistics, Vol. 322, pp. 79–93). Springer.
  doi:10.1007/978-3-030-43469-4_7. OSF: `shkqm`. (The O-Bayes hyperprior and DGP
  source — see [`tenhove2020.md`](tenhove2020.md).)
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater
  reliability for multilevel data: A generalizability theory approach.
  *Psychological Methods, 27*(4), 650–666 (advance online publication 2021;
  doi:10.1037/met0000391). (The M5 multilevel estimand — see
  [`tenhove2022.md`](tenhove2022.md).)
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2024). Updated guidelines on
  selecting an intraclass correlation coefficient for interrater reliability, with
  applications to incomplete observational designs. *Psychological Methods, 29*(5),
  967–979. doi:10.1037/met0000516. (Title corrected against the source 2026-07-19,
  M72: the entry had abbreviated "intraclass correlation coefficient" to "ICC" and
  dropped the subtitle entirely. Volume, issue, and pages are the version of record
  and are **not printed** on the shelf copy, an advance-online PDF marked © 2022.)
  (The ICC-selection guidance behind
  `choosing-an-icc.Rmd` — see [`tenhove2024.md`](tenhove2024.md).)
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2025a). Interrater
  reliability for interdependent social network data: A generalizability theory
  approach. *Multivariate Behavioral Research, 60*(3), 444–459.
  doi:10.1080/00273171.2024.2444940. (Round-robin/social-relations designs —
  contract-boundary evidence, not a dependency; see
  [`tenhove2025a.md`](tenhove2025a.md).)
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2025b). How to estimate
  intraclass correlation coefficients for interrater reliability from planned
  incomplete data. *Multivariate Behavioral Research, 60*(5), 1042–1061.
  doi:10.1080/00273171.2025.2507745. (The engine + CI basis for ADR-002/ADR-003 —
  see [`tenhove2025b.md`](tenhove2025b.md).)
- Trevethan, R. (2017). Intraclass correlation coefficients: clearing the air,
  extending some cautions, and making some requests. *Health Services and
  Outcomes Research Methodology, 17*, 127–143. doi:10.1007/s10742-016-0156-6.
  (Year, volume, and pages are the issue version of record, supplied by the
  maintainer 2026-07-19; the shelf copy is online-first — published online
  23 August 2016, © 2016 — and prints none of them, so the citekey's `2017` is
  corroborated externally rather than by the PDF. No issue number was supplied.
  M66, corrected 2026-07-19.) (Selection and reporting cautions — Form is
  not the rater count; surveys three incompatible band schemes, IP3-fenced — see
  [`trevethan2017.md`](trevethan2017.md).)
- Ukoumunne, O. C., Davison, A. C., Gulliford, M. C., & Chinn, S. (2003).
  Non-parametric bootstrap confidence intervals for the intraclass correlation
  coefficient. *Statistics in Medicine, 22*(24), 3805–3821. doi:10.1002/sim.1643.
  (The issue number is not printed on the article; it is the publisher's, recorded
  2026-07-19, M72.)
  (The M62 primary source for the transformed bootstrap-t, D-006 — see
  [`ukoumunne2003.md`](ukoumunne2003.md).)
- van der Ark, L. A., Jorgensen, T. D., & ten Hove, D. (2023). Factors affecting
  efficiency of interrater reliability estimates from planned missing data designs
  on a fixed budget. In M. Wiberg, D. Molenaar, J. González, J.-S. Kim, & H. Hwang
  (Eds.), *Quantitative Psychology. IMPS 2022* (Springer Proceedings in Mathematics
  & Statistics, Vol. 422, pp. 1–15). Springer, Cham.
  doi:10.1007/978-3-031-27781-8_1. OSF: `g5hvs`. (Meeting, editors, and city are
  publisher metadata, not printed on the shelf copy. Springer's own citation
  generator mis-splits the Dutch tussenvoegsels as "Ark, L.A.v.d." and "Hove, D.t.";
  the chapter byline reads "L. Andries van der Ark" and "Debby ten Hove", which is
  what is used here.) (Planned-missing design efficiency
  for IRR — per-cell coverage on `ICC(A,1)` under 83–99 % missingness. Supersedes
  the `jorgensen2019` preprint entry, whose byline led with a different first
  author; **not** the 2021 Jorgensen SEM paper above — see
  [`vanderark2023.md`](vanderark2023.md).)
- Vispoel, W. P., Hong, H., Lee, H., & Xu, G. (2022). Accuracy of absolute error
  estimates within a G-theory SEM framework. Paper presented at the meeting of the
  National Council on Measurement in Education (NCME), April 9, 2022. (Conference
  paper, unpaginated — cited by PDF page for that reason. Validates the SEM
  indicator-mean absolute-error method against `lavaan` / `lmer` / `psych` /
  `gtheory` in R, SAS `PROC VARCOMP`, and SPSS — "12 procedures within R, SAS, and
  SPSS": G-coefs agree to ≤ .001, global D-coefs to ≤ .005 across 24 real
  scales (PDF p. 6; tables pp. 9–10). External corroboration for O-SEM, M7.
  **Verified against the source 2026-07-19, M72**, after the maintainer put the PDF
  on the shelf mid-milestone. *Correction: this entry previously listed **GENOVA**
  among the compared programs. The paper never mentions GENOVA; that program
  belongs to the sibling source Lee & Vispoel (2024), whose abstract cites
  agreement with GENOVA and `gtheory`. The two validation sets had been conflated;
  the ≤ .001 / ≤ .005 figures and the 24-scale count are as printed and unchanged.*)
- Weeks, D. L., & Williams, D. R. (1964). A note on the determination of
  connectedness in an N-way cross classification. *Technometrics, 6*(3), 319–324.
  (**Not on the shelf — fields not verified against the source**, M72, 2026-07-19.)
- Xiao, Y., Liu, J., & Bhandary, M. (2009). Profile likelihood based confidence
  intervals for common intraclass correlation coefficient. *Communications in
  Statistics — Simulation and Computation, 39*(1), 111–118.
  doi:10.1080/03610910903324834. (**Citekey-vs-issue-year case, found 2026-07-19,
  M72 — the second such case, alongside `shieh2015`.** The shelf copy's Taylor &
  Francis cover sheet cites the article as "(2009) … 39:1, 111-118" and records
  "Published online: 10 Nov 2009", but the article's *own* running header on the
  next page reads "39: 111–118, **2010**". So the issue version of record is 2010
  and the citekey's `2009` follows the online-publication year. Not renamed —
  renaming would break the milestone Scope lists and every cross-reference.
  Volume, issue, and pages come from the cover sheet, not the article header,
  which omits the issue.) (Familial multi-sample common ICC; naive profile
  likelihood covers well in *this* design — see [`xiao2009.md`](xiao2009.md).)
- Xiao, Y., & Liu, H. (2013). Modified profile likelihood approach for certain
  intraclass correlation coefficients. *Computational Statistics, 28*(5),
  2241–2265. doi:10.1007/s00180-013-0405-x. (The issue number is not printed on the
  article; it is the publisher's, recorded 2026-07-19, M72.) (The named source for the
  profile-likelihood CI candidate — two-way random interrater, and the naive-PL
  under-coverage finding; see [`xiao2013.md`](xiao2013.md).)
- Young, D. J., & Bhandary, M. (1998). Test for equality of intraclass correlation
  coefficients under unequal family sizes. *Biometrics, 54*, 1363–1373. (Neither a
  DOI nor an issue number is printed on the article, which heads "BIOMETRICS 54,
  1363-1373"; it appeared in the December 1998 issue.) (Two ICCs, unequal family
  sizes, equal variances
  assumed; recommends the LRT — a recommendation `naik2007` later contradicts.
  Outside the contract boundary, ingested as boundary evidence — see
  [`young1998.md`](young1998.md).)
