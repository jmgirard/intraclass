# M86: Profile-likelihood machinery for two-way random ICC(A,1) — implement + validate against xiao2013

**Status:** done (2026-07-23, PR #93 https://github.com/jmgirard/intraclass/pull/93)

**Goal:** Implement naive- and modified-profile-likelihood (MPL) interval
machinery for the two-way random ICC(A,1) and establish its correctness by
reproducing xiao2013's published κ_m constants and coverage/length tables in the
calibration region (ρ ≥ 0.6). No exported method.

**Outcome:** A seeded `data-raw/` prototype (`m86-mpl-lib.R`) of xiao2013's −2l
(Eq. 7), profile MLE, naive-PL/MPL intervals (Eq. 9/10), and the κ_corr/κ_m
calibration (Eq. 11–13) — no `R/` surface. `m86-mpl-validate.R` (deterministic
fixture `m86-mpl-validation-results.rds`) reproduces Table 4 (4/4), Table 6 (3/3),
Table 3 two-sided κ_m (3/3, ±0.10), and Table 7 one-sided coverage (2/2). Estimand
mapping xiao2013 ρ = `ICC(A,1)` (σ²_e ≡ σ²_res) recorded in
`references/mpl-twoway-random-comparison.md`. Unblocks M87 (the GO/NO-GO pass).

**Decisions:** none promoted (milestone-local review fixes only).

**Review:** 3-lens + scorer. F1 (D-009 `xiao` settling directives falsified by the
prototype → CI `check-references` red, scored 97) fixed by excluding the prototype
from the four greps + prose. F2 (one-sided `mpl_kappa_corr` reused the two-sided
folded deviance — latent non-vanishing κ, scored 85) fixed to the signed
likelihood root, validated by 0.956 one-sided coverage. Blame lens: no findings.
