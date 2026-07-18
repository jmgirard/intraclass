# References index

One line per committed page in this directory. Cite `citekey (p. N)` from tests
and milestones; never restate a value here.

## Registry and bibliography

- [ORACLES.md](ORACLES.md) — the repo's **declared oracle-registry home**
  (D-007): 39 entries, each naming its oracle ID, type, asserting test, source,
  and provenance. Every oracle value in the test suite traces to an entry here.
- [BIBLIOGRAPHY.md](BIBLIOGRAPHY.md) — the bibliography (16 entries). Primary
  sources include ten Hove, Jorgensen & van der Ark (2022)
  <doi:10.1037/met0000391>, Brennan (2001), and Shrout & Fleiss (1979).
- [REFERENCES.md](REFERENCES.md) — 6-line pointer stub only; the pre-migration
  single page, kept so links from the entombed `cairn/legacy/`,
  `CLAUDE_CODE_KICKOFF.md`, and `data-raw/reviews/` documents still resolve.

## Source notes (`<citekey>.md`)

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

**Ingested (source/synthesis note exists):** `ohyama2025`, `ukoumunne2003`.

**M64 — load-bearing (10):** `fleiss1973` (weighted kappa ≡ ICC) · `jorgensen2021`
(*Psych* 3(2):113–133, SEM absolute-error — the **O-SEM** source) · `koo2016`
(selection/reporting guideline) · `mcgraw1996` (forming inferences) · `shrout1979`
(the O1 worked example) · `tenhove2020` (hyperprior comparison) · `tenhove2022`
(multilevel IRR, the M5 estimand) · `tenhove2024` (updated selection guidelines) ·
`tenhove2025a` (interdependent social-network data) · `tenhove2025b` (planned
incomplete data).

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
