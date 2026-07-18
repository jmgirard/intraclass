# Bibliography

The repo's bibliography. Oracle provenance lives in
[`ORACLES.md`](ORACLES.md); per-source extractions with page/table anchors live
in the `<citekey>.md` source notes indexed by [`INDEX.md`](INDEX.md).

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
- Jorgensen, T. D. (2021). How to estimate absolute-error components in structural
  equation models of generalizability theory. *Psych, 3*(2), 113–133.
  doi:10.3390/psych3020011. (M7 lavaan engine — the SEM absolute-error method; Eq. 6
  defines σ²_i as the raw variance of the effects-coded indicator intercepts.)
- Koo, T. K., & Li, M. Y. (2016). A guideline of selecting and reporting intraclass
  correlation coefficients for reliability research. *Journal of Chiropractic
  Medicine, 15*(2), 155–163. doi:10.1016/j.jcm.2016.02.012. (Primary
  interpretation-band source for `getting-started.Rmd`, M40: ICC < 0.5 poor,
  0.5–0.75 moderate, 0.75–0.90 good, > 0.90 excellent — and, load-bearing for the
  vignette's caveat, the guideline is to **judge against the 95% CI of the estimate,
  not the point** (§ "Interpretation"). Cited as one convention among several; the
  package deliberately computes no verdict — #4/#18.)
- Lee, H., & Vispoel, W. P. (2024). A robust indicator mean-based method for
  estimating generalizability theory absolute error and related dependability indices
  within structural equation modeling frameworks. *Psych, 6*(1), 401–425.
  doi:10.3390/psych6010024. (Confirms the raw indicator-mean formula, Eqs. 8/25;
  "robust" = an ordinal scale-coarseness correction, not a bias correction.)
- McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some intraclass
  correlation coefficients. *Psychological Methods, 1*(1), 30–46 (+ errata p. 390).
- Rosseel, Y. (2012). lavaan: An R package for structural equation modeling.
  *Journal of Statistical Software, 48*(2), 1–36. (M7 SEM engine.)
- Searle, S. R., Casella, G., & McCulloch, C. E. (2006). *Variance Components.* Wiley.
- Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in assessing
  rater reliability. *Psychological Bulletin, 86*(2), 420–428.
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2020). Comparing hyperprior
  distributions to estimate variance components for interrater reliability
  coefficients. In M. Wiberg et al. (Eds.), *Quantitative Psychology* (Springer
  Proceedings in Mathematics & Statistics, Vol. 322, pp. 79–93). Springer.
  doi:10.1007/978-3-030-43469-4_7. OSF: `shkqm` (companion code/materials). **The M23
  Bayesian source (O-Bayes):** fixes the half-*t*(4, 0, 1) prior on random-effect SDs
  (§3.3/§4.1), the two-way crossed-random DGP (§4.1.1: N = 30, σ²_s = σ²_sr = 0.5,
  σ²_r ∈ {.01, .04}, k ∈ {2, 3, 5}), and reports MAP unbiased / EAP biased for σ_r and
  percentile-BCI nominal coverage at k > 2 (§4.2, Figs 1–4). Open-access PDF via UvA
  DARE / pure.uva.nl.
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater
  reliability for multilevel data: A generalizability theory approach.
  *Psychological Methods, 27*(4), 650–666 (advance online publication 2021;
  doi:10.1037/met0000391). (M5 multilevel estimand — subject- and cluster-level IRR
  ICCs. `choosing-an-icc.Rmd`'s "fifth choice" cites this entry, corrected in M5
  Slice 2 from an earlier wrong-paper/year reference.)
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2025). How to estimate
  intraclass correlation coefficients for interrater reliability from planned
  incomplete data. *Multivariate Behavioral Research, 60*(5), 1042–1061.
  doi:10.1080/00273171.2025.2507745. (Simulation comparison concluding MLE of
  random-effects models with **Monte-Carlo CIs** is preferred — the engine + CI
  basis for ADR-002/ADR-003.)
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2024). Updated guidelines
  on selecting an ICC for interrater reliability. *Psychological Methods, 29*(5),
  967–979.
- Vispoel, W. P., Hong, H., Lee, H., & Xu, G. (2022). Accuracy of absolute error
  estimates within a G-theory SEM framework. Paper presented at the meeting of the
  National Council on Measurement in Education (NCME), April 9, 2022. (Conference
  paper — validates the SEM indicator-mean absolute-error method against GENOVA /
  `gtheory` / SAS / SPSS: G-coefs agree to ≤ .001, D-coefs to ≤ .005 across 24 real
  scales. External corroboration for O-SEM, M7.)
- Weeks, D. L., & Williams, D. R. (1964). A note on the determination of
  connectedness in an N-way cross classification. *Technometrics, 6*(3), 319–324.
