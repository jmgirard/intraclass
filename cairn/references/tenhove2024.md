# tenhove2024 — Updated guidelines on selecting an ICC for IRR

**Provenance.** Ingested 2026-07-18 by M64 from `cairn/references/sources/tenhove2024.pdf` (gitignored).
Pagination: advance-online (AOP) PDF pages 1–13 — NOT the journal pages of the version of record, 29(5):967–979.
Extraction: verified 2026-07-18 against the source (M69) — all 13 PDF pages re-read; Eqs. 16–20, Table 1, Table 2 and all ten Figure 2 terminal cells re-read at 300–900 DPI, both M64 open questions about the source's internal consistency resolved, four prose claims corrected — observed 2026-07-18.

**Citation.** ten Hove D, Jorgensen TD, van der Ark LA (2024). "Updated Guidelines
on Selecting an Intraclass Correlation Coefficient for Interrater Reliability,
With Applications to Incomplete Observational Designs." *Psychological Methods*
29(5):967–979. DOI 10.1037/met0000516.

**Role.** The package's primary source for **guidance on choosing an ICC** — the
material `vignettes/choosing-an-icc.Rmd` and `choose_icc()` render into
user-facing advice, and the cited authority for the fixed-rater warning in
`R/abort.R`. Also the source for the incomplete-design error-variance definitions
used by M3/M9.

> **Two metadata traps on this PDF — read before citing a page.**
> 1. The shelf copy is the **advance-online (AOP) version**: the copyright line
>    reads © 2022, ISSN 1082-989X, with no volume/issue and no journal
>    pagination; the back matter reads "Accepted May 23, 2022" (p. 13). The paper
>    of record is the 2024 issue version, 29(5):967–979. Cite 2024; the 2022 line
>    on the PDF is not a different work. (Same trap as `tenhove2022.md`.)
> 2. **All page anchors below are AOP PDF pages 1–13**, not journal pages
>    967–979. The title printed on the title page is the long form quoted above;
>    BIBLIOGRAPHY.md carries the short form.
> 3. **Citation trap in this paper's own reference list (added M69).** It cites
>    the multilevel paper — this repo's `tenhove2022` — as **"Ten Hove et al.
>    (2021)"**, because it was written against that paper's advance-online
>    posting (its reference entry reads "Psychological Methods. Advance online
>    publication"). So "Ten Hove et al. (2021)" on pp. 10 and 12 here means
>    `tenhove2022.md`, not a separate 2021 work. Its "Ten Hove et al. (2020)" is
>    `tenhove2020.md` and its "Ten Hove et al. (2018)" is `tenhove2018`.

## Why the article exists — three stated limitations (p. 2)

Current guidelines (Koo & Li 2016; McGraw & Wong 1996; Shrout & Fleiss 1979) are
faulted on three counts (p. 2): (i) they cover only one-way and **complete**
two-way designs, while large observational studies routinely use incomplete
designs; (ii) they "do not provide a clear perspective on the error variance in
an ICC for IRR" (p. 2) — the Abstract puts it as "no coherent perspective"
(p. 1); M64 quoted a blend of the two — clouding the agreement/consistency
choice; (iii) they leave the
fixed-vs-random rater distinction "often misunderstood" (Abstract, p. 1).
Contributions are listed on p. 3 (five items), including the flowchart and three
empirical examples.

## Definitions and the coefficient grid (pp. 2–5)

General form, Eq. 3 (p. 2): `ICC = σ²_true/(σ²_true + σ²_error) = σ²_τ/(σ²_τ + σ²_ε)`.

Designs, **Figure 1 (p. 3)**: (a) one-way (raters nested in subjects), (b)
complete two-way, (c) **incomplete** two-way (raters crossed with but varying
across subjects). Decompositions: two-way Eqs. 4–5 (p. 4)
`y_sr = μ + μ_s + μ_r + μ_sr`, `σ²_ysr = σ²_s + σ²_r + σ²_sr`; one-way Eqs. 6–7
(p. 4) `y_r:s = μ + μ_s + μ_r:s`, `σ²_yr:s = σ²_s + σ²_r:s`.

Most elaborated two-way coefficient, **Eq. 8 (p. 4)**:
`ICC(A,k) = σ²_s / (σ²_s + (σ²_r + σ²_sr)/k)`; one-way, **Eq. 9 (p. 5)**:
`ICC(k) = σ²_s / (σ²_s + σ²_r:s/k)`.

**Table 1 (p. 4)** is the classification grid: two-way × {agreement,
consistency} × {random, fixed} × {single, average} = 8 coefficients, plus the two
one-way (random-only) cells — 10 in all. The three classifying characteristics
are named on p. 4: "agreement versus consistency," "average versus single
ratings," "random versus fixed raters."

GT layer (pp. 5–7): universe-score variance equals subject variance, Eqs. 10–11
(p. 5). Absolute error `σ²_ε.abs = σ²_r + σ²_sr` (Eq. 12, p. 5); relative error
`σ²_ε.rel = σ²_sr` (Eq. 13, p. 6). Averaged over `k`: Eqs. 14–15 (p. 6),
`(σ²_r + σ²_sr)/k` and `σ²_sr/k`.

## Incomplete/unbalanced designs — the new machinery (pp. 6–7)

- **Harmonic-mean rater count, Eq. 16 (p. 6):**
  `k̂ = ((k₁⁻¹ + k₂⁻¹ + … + k_S⁻¹)/S)⁻¹` (Brennan 2001a, p. 229).
- **Proportion of nonoverlap, Eq. 17 (p. 6):**
  `q = 1/k̂ − [ΣΣ_{s≠s'} k_{s,s'}/(k_s k_{s'})] / (S(S−1))`, where `k_{s,s'}` is
  the number of raters subjects `s` and `s'` share.
- **Incomplete error variances, Eqs. 18–19 (p. 6):**
  `σ̂²_ε.abs = σ²_r/k̂ + σ²_sr/k̂` and `σ̂²_ε.rel = q σ²_r + σ²_sr/k̂`.
  For a complete design `q = 0` and `k̂ = k`, reducing to Eqs. 14–15 (p. 6).
- **One-way as a limiting case, Eq. 20 (p. 7):** with no rater overlap
  (`k_{s,s'} = 0`), `q = 1/k̂`, so absolute and relative error coincide — "in a
  one-way design absolute error variance and relative error variance are thus
  identical" (p. 7).
- Consequence quoted at p. 9: ICCs of consistency "gradually change into ICCs of
  interrater agreement with increasing nonoverlap."

## What is *updated* relative to Shrout & Fleiss / McGraw & Wong

1. **Incomplete designs are admitted as a first-class case** (Eqs. 16–19, p. 6;
   Figure 1c, p. 3), where prior guidelines covered only one-way and complete
   two-way. Treating incomplete data as if it were complete "goes against"
   Bartko's advice that ICC use "should be restricted by the underlying model
   which most adequately describes the experimental situation" (Bartko 1966,
   quoted p. 2).
2. **Fixed raters are demoted, not merely explained.** The paper "challenge[s]
   conventional wisdom about ICCs for IRR by claiming that raters should seldom
   (if ever) be considered fixed" (Abstract, p. 1); p. 3 puts it as: treating
   raters as fixed is "rarely—if ever—appropriate in an IRR study." Three reasons
   (p. 7): raters are seldom the entire potential population; few studies can let
   all raters rate all subjects; ICCs exist to generalize to a population. Four
   situations where fixation is *considered* are rebutted in turn (p. 7):
   (a) studies not pertaining to IRR, (b) convenience samples, (c) raters are
   irreplaceable, (d) raters rarely replaced. The fixed-rater bias mechanics are
   given on p. 7 (`Σ μ_sr = 0` induces expected covariance bias `−1/(k−1)`;
   Shavelson et al. 1989 correction `σ̃²_s = ξ²_s − σ²_sr/(k−1)`).
3. **A coherent error-variance perspective replaces coefficient-by-coefficient
   naming:** the agreement/consistency split is derived as absolute vs relative
   error, Eqs. 21–22 (p. 9), so the choice follows from the inference the ratings
   serve rather than from a table lookup. **Table 2 (p. 9)** tabulates the error
   variance for every design × {absolute, relative} × {single, average} cell.
4. **New coefficients are named for cells prior schemes never defined:**
   `ICC(Q,1)`, `ICC(Q,k̂)`, `ICC(A,k̂)`, `ICC(k̂)` (Figure 2, p. 8), with the note
   marking `ICC(Q,1)`, `ICC(A,k̂)`, `ICC(k̂)` as footnote `e` = "ICC has not been
   defined in the literature" (p. 8) and `ICC(Q,k̂)` as Putka et al. (2008).

## The decision structure — four steps, Figure 2 (p. 8)

Steps are stated in prose on pp. 9–10 and drawn as a flowchart on p. 8:

- **Step 1 — crossed or nested?** (p. 9) Crossed if each rater assessed multiple
  subjects and each subject was assessed by ≥ 2 raters; nested if each rater
  assesses a single subject **and each subject is assessed by ≥ 2 raters** (M64
  dropped the second half of the nested definition — corrected M69; the ≥ 2
  requirement holds on both branches). Under nesting, `σ²_r` and `σ²_sr` are confounded, so
  agreement and consistency "cannot be distinguished either" (p. 9).
- **Step 2 — absolute or relative inferences?** (p. 9) Absolute if scores are
  compared to a fixed criterion (cut-score, pass/fail); relative if the subject's
  relative position is of interest — "most statistical analyses" (p. 9).
- **Step 3 — single or average ratings?** (p. 10) Decided by how the instrument
  is used *after* the IRR study, not by how the IRR data were collected.
- **Step 4 — complete/incomplete (relative branch) or raters balanced/unbalanced
  (absolute and nested branches)?** (p. 10) Note the asymmetry the flowchart
  encodes: nonoverlap `q` only enters the relative error, so the *absolute*
  branch asks only about balance, and the *single*-rating absolute branch skips
  Step 4 entirely.

Terminal cells of Figure 2 (p. 8), as error term → coefficient:

| Branch | Error term | ICC |
|---|---|---|
| Crossed · Relative · Single · Complete | `σ²_sr` | `ICC(C,1)` |
| Crossed · Relative · Single · Incomplete | `qσ²_r + σ²_sr` | `ICC(Q,1)` |
| Crossed · Relative · Average · Complete | `σ²_sr/k` | `ICC(C,k)` |
| Crossed · Relative · Average · Incomplete | `qσ²_r + σ²_sr/k̂` | `ICC(Q,k̂)` |
| Crossed · Absolute · Single | `σ²_r + σ²_sr` | `ICC(A,1)` |
| Crossed · Absolute · Average · Balanced | `(σ²_r + σ²_sr)/k` | `ICC(A,k)` |
| Crossed · Absolute · Average · Unbalanced | `σ²_r:s/k̂` *(as printed — see Open questions)* | `ICC(A,k̂)` |
| Nested · Single | `σ²_r:s` | `ICC(1)` |
| Nested · Average · Balanced | `σ²_r:s/k` | `ICC(k)` |
| Nested · Average · Unbalanced | `σ²_r:s/k̂` | `ICC(k̂)` |

Note that **random-vs-fixed is not a step in the flowchart** — the paper folds
that axis away by arguing raters should be random (p. 7).

## Empirical examples (pp. 10–11) — no numerical ICCs printed

Three worked *selections*, not computations; the article reports **no estimated
ICC values, no variance-component estimates, and no simulation** (a guidelines
paper). Software is at OSF https://osf.io/8j26u/ (p. 11).

- **Example 1** (p. 10, Yuen et al. 2020): 29 clinicians, 6 raters, 2 raters per
  clinician; crossed, absolute, single → error `σ²_r + σ²_sr` → **ICC(A,1)**;
  Step 4 "is redundant" for single absolute ratings (p. 10).
- **Example 2** (p. 10–11, Zee et al. 2020): 8 raters, each drawing rated by 3;
  crossed, relative, average, incomplete → `qσ²_r + σ²_sr/k̂` → **ICC(Q,k)**,
  with `k̂ = k` because every subject has the same number of raters (p. 11).
- **Example 3** (p. 11, Majdandžić et al. 2021): 4 raters coded ~20 % of parents,
  1 rater the remaining 80 %; crossed, relative, average, incomplete *and*
  unbalanced → **ICC(Q,k̂)** with `k̂ ≠ k` (p. 11).

Sizing rule of thumb (p. 10): two raters per subject is the minimum to estimate
an ICC, "though at least three raters are required to yield accurately estimated
ICCs" (p. 10, citing Briesch et al. 2014; ten Hove et al. 2020).

## Reporting recommendations (pp. 11–12)

- Report **all variance components, not just the ICC** (p. 11) so later users can
  derive the coefficient that suits their own purpose.
- "all reliability estimates should be accompanied by measures of uncertainty
  (i.e., confidence intervals or standard errors)" (p. 12, citing AERA/APA/NCME
  2018) — the same posture as the package's never-a-point-estimate-alone rule.
- Describe *which* ICC was used so reviewers can verify appropriateness (p. 12).
- On estimation (p. 11): the OSF code estimates ICCs by MLE via `lme4` or MCMC
  via `brms`. The paper's survey of existing tools names `irr` and **the SPSS
  `RELIABILITY` command** for complete one- and two-way designs, and `gtheory`
  and the Windows program GENOVA for variance components and generalizability
  coefficients; its claim about the gap is its own flat sentence — "Software for
  estimating IRR in unbalanced or incomplete designs is not yet available"
  (p. 11), stated as of 2022. (M64 omitted SPSS and attributed the gap to the
  named packages individually — corrected M69.)
- Future work should find "the most appropriate estimation
  technique" (p. 12), noting MLE needs Monte-Carlo CIs "specifically useful for
  coefficients such as ICCs" whose sampling distributions are non-normal (p. 12).
- **The MLE-vs-MCMC agreement claim (p. 12).** "The MCMC and MLE estimation
  methods we provide on the OSF were shown to yield similar point estimates (Ten
  Hove et al., 2021)" — that citation is this repo's `tenhove2022` (see the
  citation trap in the pagination block at the top of this note), whose own p. 14 makes the same claim about its
  illustrative example. Both are qualitative; neither prints paired numbers, so
  neither is an oracle for the package's REML route. Added M69.

## Traces to

- **`vignettes/choosing-an-icc.Rmd`.** The vignette's four-choice spine and its
  ordering are recognisably this paper's Steps 1–4: the "prior question: are the
  raters crossed?" section is Step 1, §2 single-vs-average is Step 3, §4
  complete-vs-incomplete is Step 4, and §1 agreement-vs-consistency is Step 2.
  **Two honest divergences.** (a) The vignette's §3 is *random vs fixed raters*,
  an axis this paper deliberately **removes** from the decision (p. 7); the
  vignette keeps it as a user-facing choice while echoing the paper's preference
  ("random is the recommended default"). (b) The vignette frames Step 2 as
  value-vs-rank; the paper frames it as the downstream *inference* the ratings
  serve (p. 9). The vignette's static `choosing-icc-tree.svg` is therefore the
  package's own tree, not a redraw of Figure 2 — it should not be described as
  reproducing this paper's flowchart.
- **`R/abort.R::warn_fixed_raters()`** — cites "ten Hove et al. 2024" for
  random-raters-as-default; sourced by p. 7 and the Abstract claim (p. 1).
- **`choose_icc()`** — the interactive walk over the same four questions.
- **M3/M9 incomplete designs** — `k_eff` is Eq. 16 (p. 6), and the package's
  "use one effective `k` for both the `σ²_r` and `σ²_sr` terms" convention for
  absolute agreement is exactly Eq. 18 (p. 6). Cited already by
  `cairn/estimand-specs/M1`, `M2`, `M3`, `M9`.
- The Monte-Carlo-CI posture (ADR-002/ADR-003) is reinforced here (p. 12), though
  the primary source for it is ten Hove et al. (2025).

## Open questions

- **RESOLVED (M69) — Figure 2's `ICC(A,k̂)` box is a source erratum.** M64
  flagged the crossed · absolute · average · **unbalanced** terminal box (p. 8)
  as printing `σ²_r:s / k̂`, the *nested* component, and asked for a second
  reader. Re-read at **900 DPI**: the box does read `σ²_r:s / k̂`, and it is
  **glyph-identical to the `ICC(k̂)` box** at the far right of the same row (the
  nested · average · unbalanced terminal). The `ICC(1)` and `ICC(k)` boxes
  beside it read `σ²_r:s` and `σ²_r:s/k` correctly, so the nested branch is
  fine. Diagnosis: the nested branch's terminal box was duplicated into the
  crossed · absolute branch. The correct content is the two-way form given three
  times elsewhere in the paper (Eq. 18 p. 6, the p. 7 prose, Table 2 p. 9), none
  of which contains `σ²_r:s`. **No oracle value is affected** — no repo doc
  quotes this box (grepped across `cairn/`, `R/`, `tests/`, `vignettes/` and
  `man/` — the only hit is M69's own work log — observed 2026-07-18 <!-- check: ! git grep -qF 'σ²_r:s' -- R tests vignettes man -->). Read
  Figure 2's structure, not this cell's content.
- **RESOLVED (M69) — Table 2's absolute-average-incomplete cell is a source
  typo; Eq. 18 is authoritative.** Two separate issues were tangled in M64's
  note, and they resolve differently.
  1. *The missing division bar is a rendering artifact* — **confirmed**. In
     Table 2 (p. 9) the slash before `k̂` fails to render in the
     absolute-average-incomplete cell and in the one-way unbalanced average
     cells, while the relative-average-incomplete cell `qσ²_r + σ²_sr/k̂` in the
     **same table** renders its slash normally. The cells that render prove the
     intended form for the cells that don't.
  2. *The undivided `σ²_r` is real, and it is the source that is wrong* —
     **newly resolved**. Even granting the artifact, Table 2's cell reads
     `σ²_r + σ²_sr/k̂`, leaving `σ²_r` undivided, where Eq. 18 gives
     `σ²_r/k̂ + σ²_sr/k̂`. Eq. 18 wins on three independent grounds: it is
     stated twice (Eq. 18, p. 6; and again in prose on p. 7 —
     "the absolute-error variance was defined as `σ²_ε.abs = σ²_r/k̂ + σ²_sr/k̂`",
     both terms divided, read at 300 DPI); and only the Eq. 18 form satisfies
     the reduction the paper explicitly claims on p. 6 — that Eqs. 18–19 reduce
     to Eqs. 14–15 when `q = 0` and `k̂ = k`, since
     `σ²_r + σ²_sr/k ≠ (σ²_r + σ²_sr)/k`. **The package follows Eq. 18 and is
     therefore correct**; M64's phrase "the package follows Eq. 18 / Table 2"
     was an impossible conjunction for this cell — corrected M69.
- **Scope: the package does not implement the `q` branch.** No `ICC(Q,·)`,
  and no nonoverlap term `q` (Eq. 17, p. 6), appears anywhere in `R/` or the
  estimand specs; the package computes incomplete *consistency* as `σ²_res/k_eff`
  (M3 §5), which is this paper's `ICC(C,k̂)` — a cell Figure 2 (p. 8) does not
  offer for incomplete data. This is a real coverage gap against the source's
  recommendation, not a disagreement about a value. Candidate milestone material.
- **Posture: no benchmarks, no verdict.** The paper proposes **no cut-offs or
  qualitative labels** of its own and in fact warns that a single dataset's
  qualitative label "can range from poor to almost perfect" depending on the
  coefficient chosen (p. 2), calling that a researcher-degrees-of-freedom risk.
  It goes further than the package: it suggests interpreting ICCs via attenuation
  formulas rather than thresholds (p. 12). No conflict with the package's
  no-verdict rule — this source **supports** it, and `choosing-an-icc.Rmd`'s
  "treat published cutoffs as rough conventions" line is consistent with p. 2.
- **Recommendation the package does not follow:** report *all* variance
  components alongside the ICC (p. 11). Worth checking at review whether
  `icc()`'s printed output and `tidy()` expose the full decomposition, or only
  the coefficients and interval.
- **Pagination.** Anchors here are AOP pages 1–13. Existing repo citations of
  this work (`M1`–`M3`, `M9`, `R/abort.R`) cite the paper without page numbers,
  so no conflict exists today; if page cites are added, state the basis.
- Figure 2 is a vector figure whose text `pdftotext` does not extract; all its
  content above was read from a 300 dpi render. M64 asked for a second reader on
  the `σ²_r:s/k̂` box — **done at M69** (900 DPI; see the resolved entry above),
  along with all ten terminal cells and their footnote markers, which match the
  table in the body of this note. Eq. 20's `q = 1/k̂` was re-read at 300 DPI with
  both hats legible.
