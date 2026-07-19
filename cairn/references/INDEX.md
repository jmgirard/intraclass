# References index

One line per committed page in this directory. Cite `citekey (p. N)` from tests
and milestones; never restate a value here.

## Registry and bibliography

- [ORACLES.md](ORACLES.md) — the repo's **declared oracle-registry home**
  (D-007): 39 entries, each naming its oracle ID, type, asserting test, source,
  and provenance. Every oracle value in the test suite traces to an entry here.
- [BIBLIOGRAPHY.md](BIBLIOGRAPHY.md) — the bibliography (27 entries). Primary
  sources include ten Hove, Jorgensen & van der Ark (2022)
  <doi:10.1037/met0000391>, Brennan (2001), and Shrout & Fleiss (1979).
- [REFERENCES.md](REFERENCES.md) — 6-line pointer stub only; the pre-migration
  single page, kept so links from the entombed `cairn/legacy/`,
  `CLAUDE_CODE_KICKOFF.md`, and `data-raw/reviews/` documents still resolve.

## Source notes (`<citekey>.md`)

- [bartko1966.md](bartko1966.md) — source note (M66): the one-way/two-way/mixed
  ICC formulas and the argument that an ICC is a correlation only when the
  denominator carries an observation's full variance. Its 4×2 Ebel example
  (one-way 0.1236, two-way-random 0.2778, two-way-mixed 0.4286) is
  hand-reconstructible; no oracle uses it.
- [bartko1976.md](bartko1976.md) — source note (M66): three `r = 1.0` data sets
  that separate agreement from consistency, and the case against Winer's
  anchor-point method. **Table 3 misprints `MSW` for `MSE` in rows 3–4** (found
  by recomputation; no repo value affected).
- [bhandary2006.md](bhandary2006.md) — source note (M65): Gaussian familial
  `F_max` **equality test** across three populations, unequal family sizes; the
  asymptotic LRT's size reaches 0.41 against a nominal 0.05 at few families and
  low ρ. Outside the contract boundary (belongs to the M67 cluster by subject).
- [bobak2018.md](bobak2018.md) — source note (M65): two-rater **fixed-rater
  consistency** ICC estimated in a Bayesian hierarchy with a variance function;
  ignoring bounded-scale heteroscedasticity or pooling across studies inflates the
  ICC. Reports no coverage.
- [fleiss1973.md](fleiss1973.md) — source note (M64): weighted kappa with squared
  weights ≡ the two-way random single-rating **agreement** ICC at k = 2; shelf
  evidence for the kappa–ICC boundary, not an oracle.
- [jorgensen2021.md](jorgensen2021.md) — source note (M64): the **O-SEM** source.
  Eq. 6 defines σ²_i as the raw variance of the effects-coded indicator intercepts
  (÷ k−1, no bias correction); p. 124 documents the SEM-vs-mixed-model gap.
- [koo2016.md](koo2016.md) — source note (M64): the interpretation bands and the
  load-bearing "judge against the 95% CI, not the point estimate" guidance
  (p. 161); band inclusivity is ambiguous as printed.
- [mcgraw1996.md](mcgraw1996.md) — source note (M64): the ICC(A,·)/ICC(C,·) labels,
  the five models, and **Case 3A** (θ²_c = Σc²_j/(k−1)); includes the published
  correction (1(4):390).
- [mehta2018.md](mehta2018.md) — source note (M65): two-way random `ICC(2,1)`
  under five subject distributions — convex < uniform < concave at identical rater
  quality, because subject variance moves and rater error variance does not.
  Reports no coverage; `N = 80` matches `N = 300` on the point estimate only.
- [saha2005.md](saha2005.md) — source note (M65): bias-corrected MLE (BCML) of the
  **binary** beta-binomial ICC; a point-estimation paper with no coverage results.
  Table I quantifies near-boundary non-convergence (~15 % acceptance at worst).
  §4 contradicts Appendix A on `var(φ̂_ML)`; Appendix A is correct.
- [saha2012.md](saha2012.md) — source note (M65): profile-likelihood CI for the
  **binary** beta-binomial ICC; PL near-nominal where four asymptotic Wald
  intervals under-cover badly. Outside the contract boundary.
- [shieh2015.md](shieh2015.md) — source note (M66): the conventional average-score
  index `ICC(2) = 1 − 1/F*` is negatively biased (`−2(1−ρ*)/(N−3)`) and
  MSE-dominated by four alternatives in a `ρ̂*(c) = 1 − c/F*` family. **Critiques an
  ANOVA plug-in the package does not use** (`unit = "average"` is REML
  component-based); also sources "groups beat judges at fixed `N·K`".
- [shrout1979.md](shrout1979.md) — source note (M64): the six ICC forms, the three
  cases, and the **O1** worked example (Tables 2–4); Table 4 prints two decimals.
- [tenhove2018.md](tenhove2018.md) — source note (M66): 20 IRR coefficients on 4
  `irr` datasets — the *Video* set spans 0.04 to 0.92, so the coefficient choice,
  not the data, drives the reported reliability. A problem statement with no
  selection rule; `ICC₂` here is the **two-way** consistency ICC.
- [tenhove2020.md](tenhove2020.md) — source note (M64): the **O-Bayes** source —
  half-*t*(4,0,1) hyperpriors on random-effect **SDs**, the crossed-random DGP, and
  MAP-over-EAP with percentile BCIs at k > 2.
- [tenhove2022.md](tenhove2022.md) — source note (M64): the **M5 multilevel
  estimand** — Design-1 five-component decomposition (Eqs. 6–7), the subject- and
  cluster-level ICCs (Eqs. 12–13), and the Table 3 coverage grid.
- [tenhove2024.md](tenhove2024.md) — source note (M64): the updated ICC-selection
  guidance — the four-step Figure 2 flowchart, the `k̂`/`q` incomplete-design
  machinery, and the demotion of fixed raters.
- [tenhove2025a.md](tenhove2025a.md) — source note (M64): the rater-extended social
  relations model for round-robin data (seven components, consistency-only ICCs);
  contract-boundary evidence — nothing in the package traces to it.
- [tenhove2025b.md](tenhove2025b.md) — source note (M64): the ADR-002/ADR-003
  basis — MLE of random-effects models with Monte-Carlo CIs preferred for planned
  incomplete data.
- [trevethan2017.md](trevethan2017.md) — source note (M66): ICC selection and
  reporting cautions — Form is *not* the rater count, and one data set yields six
  ICCs from 0.51 to 0.87 (Table 2). A second independent source for judging the
  interval over the point estimate; surveys four incompatible band schemes
  (IP3-fenced). Shelf copy is online-first with **no journal pagination**.
- [ukoumunne2003.md](ukoumunne2003.md) — source note (M62): the non-parametric
  bootstrap CI for the one-way ICC (subject-resample + `log F` variance-stabilizing
  transformed bootstrap-t + infinitesimal-jackknife SE); under-covers at k=10.
- [xiao2009.md](xiao2009.md) — source note (M65): profile-likelihood CI for a
  **common** ICC across populations of unequal-size families. Naive PL covers
  0.931–0.950 against a nominal 0.95 here — the design contrast that shows PL's
  under-coverage in `xiao2013` is design-specific, not a property of PL.
- [xiao2013.md](xiao2013.md) — source note (M65): the **modified profile
  likelihood** (`κ_m`) for the two-way random interrater ICC — the named source
  for the PL sibling candidate. Documents naive PL bottoming out at 0.796 vs a
  nominal 0.90, and calibrates `κ_m` only over ρ ∈ [0.6, 0.9].

## Synthesis notes

- [sem-multilevel-pilot.md](sem-multilevel-pilot.md) — synthesis note (M53): the
  two-level lavaan mapping of the ten Hove (2022) Design-1 components, its
  sourcing status (none — D-005 parameterization), and the pilot ledger.

- [ohyama2025.md](ohyama2025.md) — synthesis/oracle note (M62): published coverage/
  width comparison of one-way-ICC CI methods (SEARLE/SMITH/NBOOT/REML/BETA);
  REML best, NBOOT slightly worse than SEARLE — the M62 NBOOT-prototype oracle.

- [npbootstrap-oneway-comparison.md](npbootstrap-oneway-comparison.md) — synthesis
  note (M62): the pre-registered "not worse" criterion + one-way cell grid, and
  the coverage/width results + GO/NO-GO verdict for the non-parametric
  bootstrap vs the incumbent MC / parametric-bootstrap intervals.

## Source shelf inventory

`sources/` is **gitignored** (renamed from `pdf/` at M68); this inventory is the
committed record of what is on the shelf and which milestone ingests it. 30 PDFs,
each verified against its own
title page (M63/T1). Citekey convention: same-author-same-year takes a letter
suffix ordered by issue — `tenhove2025a` (MBR 60(3)), `tenhove2025b` (MBR 60(5)).

**Ingested (source/synthesis note exists) — 19:** `bhandary2006`, `bobak2018`,
`fleiss1973`, `jorgensen2021`, `koo2016`, `mcgraw1996`, `mehta2018`, `ohyama2025`,
`saha2005`, `saha2012`, `shrout1979`, `tenhove2020`, `tenhove2022`, `tenhove2024`,
`tenhove2025a`, `tenhove2025b`, `ukoumunne2003`, `xiao2009`, `xiao2013`. The ten
load-bearing primary sources were ingested by M64; `ohyama2025` and
`ukoumunne2003` by M62; the seven interval-methods/robustness sources by M65.

Three shelf PDFs are **not** the issue version of record — each note carries a
pagination callout: `tenhove2022` and `tenhove2024` are advance-online copies
(© 2021 and © 2022 respectively, no journal pagination), and `tenhove2020` is an
author/accepted manuscript with no publisher fields at all.

**M65 — interval methods & robustness (7): ingested 2026-07-18.** Reading them
cold established that the cluster is **not** the one-way-interval-methods group
its name suggests — only `mehta2018` and `bobak2018` are inside the package's
contract boundary. Design applicability per note: `xiao2013` two-way random
interrater (modified profile likelihood) · `xiao2009` familial multi-sample
common ICC · `saha2012` **binary** beta-binomial ICC interval · `saha2005`
**binary** beta-binomial point estimator · `bhandary2006` Gaussian familial
**equality test** (M67 territory) · `mehta2018` two-way random `ICC(2,1)` under
varying subject distributions · `bobak2018` two-rater fixed-rater consistency ICC
under heteroscedasticity.

**M66 — foundational & interpretation (7):** `bartko1966` · `bartko1976` ·
`hedges2012` (ICC variance, 3-/4-level) · `jorgensen2019` (planned-missing
efficiency on a fixed budget — **not** the 2021 SEM paper) · `shieh2015`
(best average-score index) · `tenhove2018` (20 coefficients compared) ·
`trevethan2017` (cautions).

**M67 — ICC-equality testing (4):** `donner2002` · `konishi1989` · `naik2007` ·
`young1998`. Outside the contract boundary (IP2); ingested as boundary evidence.
