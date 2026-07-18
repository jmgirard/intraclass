# Bibliography

The repo's bibliography. Oracle provenance lives in
[`ORACLES.md`](ORACLES.md); per-source extractions with page/table anchors live
in the `<citekey>.md` source notes indexed by [`INDEX.md`](INDEX.md).

- Bhandary, M., & Fujiwara, K. (2006). A small sample test for the equality of
  intraclass correlation coefficients under unequal family sizes for several
  populations. *Communications in Statistics — Simulation and Computation, 35*(3),
  765–778. doi:10.1080/03610910600716894. (Gaussian familial `F_max` equality
  test; outside the contract boundary, ingested as boundary evidence — see
  [`bhandary2006.md`](bhandary2006.md).)
- Bobak, C. A., Barr, P. J., & O'Malley, A. J. (2018). Estimation of an inter-rater
  intra-class correlation coefficient that overcomes common assumption violations
  in the assessment of health measurement scales. *BMC Medical Research
  Methodology, 18*, 93. doi:10.1186/s12874-018-0550-6. (Bounded-scale
  heteroscedasticity and pooled-study inflation of the inter-rater ICC — see
  [`bobak2018.md`](bobak2018.md).)
- Brennan, R. L. (2001). *Generalizability Theory.* Springer.
- Brooks, M. E., et al. (2017). glmmTMB balances speed and flexibility among
  packages for zero-inflated generalized linear mixed models. *The R Journal,
  9*(2), 378–400.
- Cicchetti, D. V. (1994). Guidelines, criteria, and rules of thumb for evaluating
  normed and standardized assessment instruments in psychology. *Psychological
  Assessment, 6*(4), 284–290. doi:10.1037/1040-3590.6.4.284. (Interpretation-band
  source for `getting-started.Rmd`, M40 — the older sibling rule of thumb: ICC < 0.40
  poor, 0.40–0.59 fair, 0.60–0.74 good, 0.75–1.00 excellent. Cited as one convention
  among several, with caveats; the package computes no verdict — #4/#18.)
- Fleiss, J. L., & Cohen, J. (1973). The equivalence of weighted kappa and the
  intraclass correlation coefficient as measures of reliability. *Educational and
  Psychological Measurement, 33*, 613–619. (The kappa–ICC boundary; shelf evidence,
  not an oracle — see [`fleiss1973.md`](fleiss1973.md).)
- Jorgensen, T. D. (2021). How to estimate absolute-error components in structural
  equation models of generalizability theory. *Psych, 3*(2), 113–133.
  doi:10.3390/psych3020011. (The M7 lavaan engine's SEM absolute-error method —
  see [`jorgensen2021.md`](jorgensen2021.md).)
- Koo, T. K., & Li, M. Y. (2016). A guideline of selecting and reporting intraclass
  correlation coefficients for reliability research. *Journal of Chiropractic
  Medicine, 15*(2), 155–163. doi:10.1016/j.jcm.2016.02.012. (The primary
  interpretation-band source for `getting-started.Rmd` — see
  [`koo2016.md`](koo2016.md).)
- Lee, H., & Vispoel, W. P. (2024). A robust indicator mean-based method for
  estimating generalizability theory absolute error and related dependability indices
  within structural equation modeling frameworks. *Psych, 6*(1), 401–425.
  doi:10.3390/psych6010024. (Confirms the raw indicator-mean formula, Eqs. 8/25;
  "robust" = an ordinal scale-coarseness correction, not a bias correction.)
- McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some intraclass
  correlation coefficients. *Psychological Methods, 1*(1), 30–46 (+ correction,
  *1*(4), 390). (The package's ICC(A,·)/ICC(C,·) labels and Case 3A — see
  [`mcgraw1996.md`](mcgraw1996.md).)
- Mehta, S., Bastero-Caballero, R. F., Sun, Y., Zhu, R., Murphy, D. K., Hardas, B.,
  & Koch, G. (2018). Performance of intraclass correlation coefficient (ICC) as a
  reliability index under various distributions in scale reliability studies.
  *Statistics in Medicine, 37*(18), 2734–2752. doi:10.1002/sim.7679. (How the
  subject distribution, not scale quality, drives `ICC(2,1)` — see
  [`mehta2018.md`](mehta2018.md).)
- Ohyama, T. (2025). A comparison of confidence interval methods for the
  intraclass correlation coefficient based on the one-way random effects model.
  *Japanese Journal of Statistics and Data Science, 8*, 587–602.
  doi:10.1007/s42081-025-00292-3. (Independent published coverage/width comparison
  of one-way-ICC CI methods; the M62 NBOOT-prototype oracle — see
  [`ohyama2025.md`](ohyama2025.md).)
- Rosseel, Y. (2012). lavaan: An R package for structural equation modeling.
  *Journal of Statistical Software, 48*(2), 1–36. (M7 SEM engine.)
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
- Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in assessing
  rater reliability. *Psychological Bulletin, 86*(2), 420–428. (The six ICC forms
  and the O1 worked example — see [`shrout1979.md`](shrout1979.md).)
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
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2024). Updated guidelines
  on selecting an ICC for interrater reliability. *Psychological Methods, 29*(5),
  967–979. doi:10.1037/met0000516. (The ICC-selection guidance behind
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
- Ukoumunne, O. C., Davison, A. C., Gulliford, M. C., & Chinn, S. (2003).
  Non-parametric bootstrap confidence intervals for the intraclass correlation
  coefficient. *Statistics in Medicine, 22*(24), 3805–3821. doi:10.1002/sim.1643.
  (The M62 primary source for the transformed bootstrap-t, D-006 — see
  [`ukoumunne2003.md`](ukoumunne2003.md).)
- Vispoel, W. P., Hong, H., Lee, H., & Xu, G. (2022). Accuracy of absolute error
  estimates within a G-theory SEM framework. Paper presented at the meeting of the
  National Council on Measurement in Education (NCME), April 9, 2022. (Conference
  paper — validates the SEM indicator-mean absolute-error method against GENOVA /
  `gtheory` / SAS / SPSS: G-coefs agree to ≤ .001, D-coefs to ≤ .005 across 24 real
  scales. External corroboration for O-SEM, M7.)
- Weeks, D. L., & Williams, D. R. (1964). A note on the determination of
  connectedness in an N-way cross classification. *Technometrics, 6*(3), 319–324.
- Xiao, Y., Liu, J., & Bhandary, M. (2009). Profile likelihood based confidence
  intervals for common intraclass correlation coefficient. *Communications in
  Statistics — Simulation and Computation, 39*(1), 111–118.
  doi:10.1080/03610910903324834. (Familial multi-sample common ICC; naive profile
  likelihood covers well in *this* design — see [`xiao2009.md`](xiao2009.md).)
- Xiao, Y., & Liu, H. (2013). Modified profile likelihood approach for certain
  intraclass correlation coefficients. *Computational Statistics, 28*(5),
  2241–2265. doi:10.1007/s00180-013-0405-x. (The named source for the
  profile-likelihood CI candidate — two-way random interrater, and the naive-PL
  under-coverage finding; see [`xiao2013.md`](xiao2013.md).)
