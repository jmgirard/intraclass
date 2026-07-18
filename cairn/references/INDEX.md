# References index

One line per committed page in this directory. Cite `citekey (p. N)` from tests
and milestones; never restate a value here.

## Registry and bibliography

- [ORACLES.md](ORACLES.md) — the repo's **declared oracle-registry home**
  (D-007): 39 entries, each naming its oracle ID, type, asserting test, source,
  and provenance. Every oracle value in the test suite traces to an entry here.
- [BIBLIOGRAPHY.md](BIBLIOGRAPHY.md) — the bibliography (18 entries). Primary
  sources include ten Hove, Jorgensen & van der Ark (2022)
  <doi:10.1037/met0000391>, Brennan (2001), and Shrout & Fleiss (1979).
- [REFERENCES.md](REFERENCES.md) — 6-line pointer stub only; the pre-migration
  single page, kept so links from the entombed `cairn/legacy/`,
  `CLAUDE_CODE_KICKOFF.md`, and `data-raw/reviews/` documents still resolve.

## Source notes (`<citekey>.md`)

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
- [shrout1979.md](shrout1979.md) — source note (M64): the six ICC forms, the three
  cases, and the **O1** worked example (Tables 2–4); Table 4 prints two decimals.
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
- [ukoumunne2003.md](ukoumunne2003.md) — source note (M62): the non-parametric
  bootstrap CI for the one-way ICC (subject-resample + `log F` variance-stabilizing
  transformed bootstrap-t + infinitesimal-jackknife SE); under-covers at k=10.

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

## PDF shelf inventory

`pdf/` is **gitignored**; this inventory is the committed record of what is on
the shelf and which milestone ingests it. 30 PDFs, each verified against its own
title page (M63/T1). Citekey convention: same-author-same-year takes a letter
suffix ordered by issue — `tenhove2025a` (MBR 60(3)), `tenhove2025b` (MBR 60(5)).

**Ingested (source/synthesis note exists) — 12:** `fleiss1973`, `jorgensen2021`,
`koo2016`, `mcgraw1996`, `ohyama2025`, `shrout1979`, `tenhove2020`, `tenhove2022`,
`tenhove2024`, `tenhove2025a`, `tenhove2025b`, `ukoumunne2003`. The ten
load-bearing primary sources were ingested by M64; `ohyama2025` and
`ukoumunne2003` by M62.

Three shelf PDFs are **not** the issue version of record — each note carries a
pagination callout: `tenhove2022` and `tenhove2024` are advance-online copies
(© 2021 and © 2022 respectively, no journal pagination), and `tenhove2020` is an
author/accepted manuscript with no publisher fields at all.

**M65 — interval methods & robustness (7):** `xiao2013` (modified profile
likelihood) · `xiao2009` (profile-likelihood CIs, common ICC) · `saha2012`
(profile-likelihood CI) · `saha2005` (bias-corrected MLE) · `bhandary2006`
(small-sample inference) · `mehta2018` (ICC under various distributions) ·
`bobak2018` (assumption violations).

**M66 — foundational & interpretation (7):** `bartko1966` · `bartko1976` ·
`hedges2012` (ICC variance, 3-/4-level) · `jorgensen2019` (planned-missing
efficiency on a fixed budget — **not** the 2021 SEM paper) · `shieh2015`
(best average-score index) · `tenhove2018` (20 coefficients compared) ·
`trevethan2017` (cautions).

**M67 — ICC-equality testing (4):** `donner2002` · `konishi1989` · `naik2007` ·
`young1998`. Outside the contract boundary (IP2); ingested as boundary evidence.
