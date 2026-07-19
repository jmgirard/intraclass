# tenhove2024 — Updated guidelines on selecting an ICC for IRR

**Citation.** ten Hove D, Jorgensen TD, van der Ark LA (2024). "Updated Guidelines
on Selecting an Intraclass Correlation Coefficient for Interrater Reliability,
With Applications to Incomplete Observational Designs." *Psychological Methods*
29(5):967–979. DOI 10.1037/met0000516.
PDF: `cairn/references/sources/tenhove2024.pdf` (gitignored).

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

## Why the article exists — three stated limitations (p. 2)

Current guidelines (Koo & Li 2016; McGraw & Wong 1996; Shrout & Fleiss 1979) are
faulted on three counts (p. 2): (i) they cover only one-way and **complete**
two-way designs, while large observational studies routinely use incomplete
designs; (ii) they give "no clear perspective on the error variance in an ICC"
(p. 2), clouding the agreement/consistency choice; (iii) they leave the
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
  assesses a single subject. Under nesting, `σ²_r` and `σ²_sr` are confounded, so
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
- On estimation (p. 11): MLE via `lme4` or MCMC via `brms`; existing packages
  `irr`, `gtheory`, GENOVA are named as not covering incomplete/unbalanced
  two-way designs. Future work should find "the most appropriate estimation
  technique" (p. 12), noting MLE needs Monte-Carlo CIs "specifically useful for
  coefficients such as ICCs" whose sampling distributions are non-normal (p. 12).

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

- **Figure 2 vs Table 2 — an apparent internal inconsistency in the source.** The
  crossed · absolute · average · **unbalanced** terminal box on p. 8 prints the
  error term as `σ²_r:s / k̂` (verified at 300 dpi), i.e. the *nested* component,
  while Table 2 (p. 9) gives the two-way incomplete absolute-average error as
  a `σ²_r`-plus-`σ²_sr`-over-`k̂` form and Eq. 18 (p. 6) gives
  `σ²_r/k̂ + σ²_sr/k̂`; neither contains `σ²_r:s`. Recorded as read;
  **not reconciled here** and no oracle value is affected — the package follows
  Eq. 18 / Table 2. Worth an escalation at review if any doc quotes Figure 2's
  box.
- **Table 2's `k̂` cells are typeset ambiguously.** In the shelf PDF the
  division bar before `k̂` does not render in several Table 2 cells (p. 9): the
  two-way incomplete absolute-average cell prints as `σ²_r + σ²_sr k̂` and the
  one-way unbalanced cells as `σ²_r:s k̂`, while the relative-average cell
  `qσ²_r + σ²_sr/k̂` in the same table shows its slash normally. Read as a
  rendering artifact for `/k̂`; **Eq. 18 (p. 6) `σ̂²_ε.abs = σ²_r/k̂ + σ²_sr/k̂`
  is taken as the authoritative form** in the body of this note. Even so, Eq. 18
  divides `σ²_r` by `k̂` and Table 2's cell appears to leave it undivided — a
  residual discrepancy recorded, not resolved.
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
  content above was read from a 300 dpi render. Small sub/superscripts were
  legible, but a second reader confirming the `σ²_r:s/k̂` box would be prudent.
