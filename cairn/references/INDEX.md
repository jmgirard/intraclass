# References index

One line per committed page in this directory. Cite `citekey (p. N)` from tests
and milestones; never restate a value here.

## Registry and bibliography

- [ORACLES.md](ORACLES.md) — the repo's **declared oracle-registry home**
  (D-007): 39 entries, each naming its oracle ID, type, asserting test, source,
  and provenance. Every oracle value in the test suite traces to an entry here.
- [BIBLIOGRAPHY.md](BIBLIOGRAPHY.md) — the bibliography (34 entries). Primary
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
- [donner2002.md](donner2002.md) — source note (M67): testing `H₀: ρ₁ = ρ₂` for two
  **dependent** ICCs — two observer panels rating the same subjects, the
  interobserver case. The cluster's closest approach to package territory, so its
  IP2 fence is stated twice. Outside the contract boundary.
- [fleiss1973.md](fleiss1973.md) — source note (M64): weighted kappa with squared
  weights ≡ the two-way random single-rating **agreement** ICC at k = 2; shelf
  evidence for the kappa–ICC boundary, not an oracle.
- [hedges2012.md](hedges2012.md) — source note (M66): delta-method large-sample
  variances of variance-share ICCs in three- and four-level nested designs
  (Eqs. 1, 4–6, 10–15) with a worked Kentucky example. **Outside the contract
  boundary (IP2) — no rater facet**; its "multilevel ICC" is not the package's.
  Its symmetric Wald intervals are the contrast case for `PRINCIPLES.md` #3.
- [jorgensen2021.md](jorgensen2021.md) — source note (M64): the **O-SEM** source.
  Eq. 6 defines σ²_i as the raw variance of the effects-coded indicator intercepts
  (÷ k−1, no bias correction); p. 124 documents the SEM-vs-mixed-model gap.
- [koo2016.md](koo2016.md) — source note (M64): the interpretation bands and the
  load-bearing "judge against the 95% CI, not the point estimate" guidance
  (p. 161); band inclusivity is ambiguous as printed.
- [konishi1989.md](konishi1989.md) — source note (M67): the general `q`-population
  approximate LRT for `H₀: ρ₁ = ⋯ = ρ_q`. Its null distribution is **not** `χ²`
  but a weighted sum of `χ²₁` variates; exact `χ²₁` needs normality **and** equal
  `p` **and** `q = 2` together. Outside the contract boundary.
- [mcgraw1996.md](mcgraw1996.md) — source note (M64): the ICC(A,·)/ICC(C,·) labels,
  the five models, and **Case 3A** (θ²_c = Σc²_j/(k−1)); includes the published
  correction (1(4):390).
- [mehta2018.md](mehta2018.md) — source note (M65): two-way random `ICC(2,1)`
  under five subject distributions — convex < uniform < concave at identical rater
  quality, because subject variance moves and rater error variance does not.
  Reports no coverage; `N = 80` matches `N = 300` on the point estimate only.
- [naik2007.md](naik2007.md) — source note (M67): equality of `g` ICCs under
  unequal family sizes **and unequal variances** — five tests, recommending the
  score test or `T₀`. Reports that substituting Srivastava's estimator into the
  LRT (as `young1998` does) gives a **negative `−2 log Λ` on up to 25 % of
  samples**. Outside the contract boundary.
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
  interval over the point estimate; surveys three incompatible band schemes
  (IP3-fenced). Shelf copy is online-first with **no journal pagination**.
- [ukoumunne2003.md](ukoumunne2003.md) — source note (M62): the non-parametric
  bootstrap CI for the one-way ICC (subject-resample + `log F` variance-stabilizing
  transformed bootstrap-t + infinitesimal-jackknife SE); under-covers at k=10.
- [vanderark2023.md](vanderark2023.md) — source note (M66, corrected 2026-07-19):
  optimizing a planned-missing observational design for IRR on a fixed budget —
  budget / workload / team-size algebra (Table 1) and **per-cell** coverage in
  `[0.934, 0.956]` across 24 cells under 83–99 % missingness on `ICC(A,1)`.
  Replaces the `jorgensen2019` note, which was written from an author manuscript
  of this study under a different first author.
- [xiao2009.md](xiao2009.md) — source note (M65): profile-likelihood CI for a
  **common** ICC across populations of unequal-size families. Naive PL covers
  0.931–0.950 against a nominal 0.95 here — the design contrast that shows PL's
  under-coverage in `xiao2013` is design-specific, not a property of PL.
- [xiao2013.md](xiao2013.md) — source note (M65): the **modified profile
  likelihood** (`κ_m`) for the two-way random interrater ICC — the named source
  for the PL sibling candidate. Documents naive PL bottoming out at 0.796 vs a
  nominal 0.90, and calibrates `κ_m` only over ρ ∈ [0.6, 0.9].
- [young1998.md](young1998.md) — source note (M67): equality of **two** ICCs under
  unequal family sizes, assuming equal variances; recommends the LRT — a
  recommendation `naik2007` later contradicts. Its real-data example returns
  **negative** ICC estimates (≈ −0.27), which the compound-symmetric
  parameterization admits. Outside the contract boundary.

## Synthesis notes

- [sem-multilevel-pilot.md](sem-multilevel-pilot.md) — synthesis note (M53): the
  two-level lavaan mapping of the ten Hove (2022) Design-1 components, its
  sourcing status (none — D-005 parameterization), and the pilot ledger.

- [ohyama2025.md](ohyama2025.md) — synthesis/oracle note (M62): published coverage/
  width comparison of one-way-ICC CI methods (SEARLE/SMITH/NBOOT/REML/BETA);
  REML best, NBOOT slightly worse than SEARLE — the M62 NBOOT-prototype oracle.
  **M70 recovered its §4 worked examples** (pp. 599–600), which the first pass
  never reached: two published ANOVA tables with all five methods' 95 % limits,
  exact reference values that beat plot-reading Figs. 1–2. Note also that the
  width figures (Figs. 3–4) **exclude NBOOT**, so no NBOOT width claim traces
  here — coverage only.

- [npbootstrap-oneway-comparison.md](npbootstrap-oneway-comparison.md) — synthesis
  note (M62): the pre-registered "not worse" criterion + one-way cell grid, and
  the coverage/width results + GO/NO-GO verdict for the non-parametric
  bootstrap vs the incumbent MC / parametric-bootstrap intervals.

## Source shelf inventory

`sources/` is **gitignored** (renamed from `pdf/` at M68); this inventory is the
committed record of what is on the shelf and which milestone ingests it. **30 PDFs
— observed 2026-07-19**: the 30 verified against their own title pages at M63/T1,
less the superseded `jorgensen2019.pdf` preprint (since deleted, as the M66
correction anticipated), plus `vanderark2023`, added by the maintainer 2026-07-19
and verified against its title page when ingested. Citekey convention:
same-author-same-year takes a letter suffix ordered by issue — `tenhove2025a`
(MBR 60(3)), `tenhove2025b` (MBR 60(5)).

**Ingested (source/synthesis note exists) — 30:** `bartko1966`, `bartko1976`,
`bhandary2006`, `bobak2018`, `donner2002`, `fleiss1973`, `hedges2012`,
`jorgensen2021`, `konishi1989`, `koo2016`, `mcgraw1996`, `mehta2018`, `naik2007`,
`ohyama2025`, `saha2005`,
`saha2012`, `shieh2015`, `shrout1979`, `tenhove2018`, `tenhove2020`, `tenhove2022`,
`tenhove2024`, `tenhove2025a`, `tenhove2025b`, `trevethan2017`, `ukoumunne2003`,
`vanderark2023`, `xiao2009`, `xiao2013`, `young1998`. The ten load-bearing primary
sources were ingested by M64;
`ohyama2025` and `ukoumunne2003` by M62; the seven interval-methods/robustness
sources by M65; the seven foundational/interpretation sources by M66; the four
equality-testing sources by M67. **Every shelf PDF now carries a note, and every
note has a shelf PDF — 30/30, no orphan in either direction (observed
2026-07-19).**

**Extraction status across the shelf (2026-07-19).** Of the 30 notes, **23 are
dated-verified** — the ten load-bearing ones by M69, the seven
foundational/interpretation ones at ingest by M66, and six by M70
(`ukoumunne2003`, `ohyama2025`, `donner2002`, `konishi1989`, `naik2007`,
`young1998`). The remaining **seven are M65's and stay unverified** until M71:
`bhandary2006`, `bobak2018`, `mehta2018`, `saha2005`, `saha2012`, `xiao2009`,
`xiao2013`. A claim sourced to one of those seven is not yet re-read against its
PDF — `young1998`'s two `bhandary2006` cross-references are marked accordingly.

Four shelf PDFs are **not** the issue version of record — each note carries a
pagination callout: `tenhove2022` and `tenhove2024` are advance-online copies
(© 2021 and © 2022 respectively, no journal pagination), `tenhove2020` is an
author/accepted manuscript with no publisher fields at all, and `trevethan2017` is
an online-first copy with no journal pagination (M66) — though for that one the
issue version's year, volume, and pages are now recorded from a maintainer-supplied
citation, so only its *anchors* remain PDF-based (corrected 2026-07-19). A fifth,
`jorgensen2019`,
was an author manuscript with no year, venue, or pagination at all; the published
version of record arrived on the shelf as `vanderark2023` and **supersedes it**
(corrected 2026-07-19); the preprint PDF has since been removed from the shelf,
and nothing cited it (observed 2026-07-19).

Two citekeys are **not** corroborated by their source's printed publication year, and neither was
renamed (renaming would break the milestone Scope lists and every cross-reference):
`shieh2015` is *Behavior Research Methods* 48(3):994–1003, **2016** — the 2015 is
the online/copyright year printed on the same page.
`trevethan2017` **was** the second and milder case: its shelf copy prints no
publication year at all (only © 2016 and an online date), leaving the `2017`
*uncorroborated* rather than contradicted. It is no longer an open case — the
maintainer supplied the issue version on 2026-07-19 (*Health Services and Outcomes
Research Methodology* **17, 127–143, 2017**), which corroborates the citekey, and
`BIBLIOGRAPHY.md` now carries year, volume, and pages (corrected 2026-07-19).
So `shieh2015` is the only citekey still uncorroborated by its own source.

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

**M66 — foundational & interpretation (7): ingested 2026-07-19.** Read cold, the
cluster splits three ways rather than being uniformly "guidance": two bear on
selection (`tenhove2018`, `shieh2015`), two are the package's prehistory
(`bartko1966`, `bartko1976`), two are design/efficiency
(`vanderark2023`, `hedges2012`), and one is a reporting-cautions paper
(`trevethan2017`). **Nothing in the package traces to any of the seven** — no
oracle, test, or vignette cites them — which is the honest state, not a gap.
`hedges2012` is additionally outside the contract boundary (IP2): its ICCs have
no rater facet. `vanderark2023` is **not** the 2021 SEM paper, and it replaced
M66's `jorgensen2019` note once the published version of record reached the shelf
(corrected 2026-07-19). Every note was
read to its source's final page and carries a dated *verified* extraction status,
so none joins the re-verify backlog.

Source findings recorded by M66, none affecting a repo value: `bartko1976`
Table 3 misprints `MSW` for `MSE` in rows 3–4 (found by recomputation);
`tenhove2018` Table 1 gives the `Vision` scale maximum as 3 where p. 69 says 4
(unresolved — needs the `irr` package); `shieh2015` Appendix Eq. A2 writes `ρ`
for `ρ*` (typographical, confirmed by re-deriving Eq. 5).

**M67 — ICC-equality testing (4): ingested 2026-07-19.** `donner2002` ·
`konishi1989` · `naik2007` · `young1998`. Outside the contract boundary (IP2);
ingested as boundary evidence, and `DESIGN.md`'s IP2 now points here as the
citable record for it. Read cold, the cluster is **five** papers, not four:
M65's `bhandary2006` belongs to it by subject, its own note says so, and all
five now cross-reference each other under one fence.

Two findings. `donner2002` is the only member inside the interrater setting at
all — same subjects, two observer panels, ANOVA ICC estimators — which is why
its note states the fence twice, once for the tests and once for the pooled
interval in its second worked example. And the unequal-family-size pair
**disagree**: `young1998` recommends the LRT, while `naik2007` (p. 6503) reports
that same Srivastava-into-LRT substitution producing a negative `−2 log Λ` on up
to 25 % of simulated data sets and recommends the score test or `T₀` instead —
so the two must not be cited as a concordant pair — **that disagreement was
re-verified against `naik2007` p. 6503 at M70 and the 25 % figure is exact.**

Per the M67 plan gate these four notes shipped at **unverified** first-pass
status by design (AC3 made them non-load-bearing), unlike M66's, and joined the
re-verify backlog rather than being exempt from it. **M70 cleared them
(2026-07-19): all four are now dated-verified**, each read to its source's final
page, alongside M62's `ukoumunne2003` and `ohyama2025`. What the re-verification
found, per note:

- `donner2002` — the simulated-`ρ` enumeration was right for the significance
  tables and wrong for the power table, which uses unequal *pairs*; the 0.4 floor
  it was cited for is unaffected.
- `konishi1989` — a **false illegibility claim**: the `q = 2` scale `c` (p. 99)
  had been left untranscribed as unreadable, but renders cleanly at 400 DPI. The
  scan's real defect is its text layer (`62Hl5` for 62H15).
- `naik2007` — the score-vs-`T₀` verdict is stated twice with different outcomes
  (`g = 3` vs `g = 2`) and only one was recorded; plus a source erratum in §6's
  degrees of freedom.
- `young1998` — additions only, no error: the M67 restoration of `−2 log Λ` is
  confirmed correct. Two of its claims about `bhandary2006` are now marked as
  **inherited, not verified** — that note is M71's.

**Backlog status.** The re-verify backlog now holds **seven** notes, all M65's:
`bhandary2006`, `bobak2018`, `mehta2018`, `saha2005`, `saha2012`, `xiao2009`,
`xiao2013` — M71's scope. `ORACLES.md` and `BIBLIOGRAPHY.md` are tracked
separately under M72, on a bar split by entry kind.
