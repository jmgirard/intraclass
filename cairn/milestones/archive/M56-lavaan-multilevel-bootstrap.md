# M56: Multilevel SEM (lavaan) — parametric bootstrap CI (done 2026-07-17)

**Goal:** serve `ci_method = "bootstrap"` for the shipped crossed (Design 1)
random-rater balanced multilevel lavaan fit. **Done.**
PR: https://github.com/jmgirard/intraclass/pull/62 (squash bbccb36).

- `R/engine-lavaan.R`: `lavaan_multilevel_model(k)` (two-level CFA string,
  shared by point fit + refit); `lavaan_multilevel_components()` (boundary-safe
  five-component reader, NULL on Heywood); `lavaan_ml_simulate_refit()` — the
  two-level parametric DGP rebuilt from the five fitted components (cluster means
  ~ MVN(ν, svb·11'+diag(evb)); within devs ~ MVN(0, svw·11'+diag(evw))), refit
  per resample, NA-fill on failure. Wired into `fit_lavaan_multilevel`'s
  `simulate_refit` slot (was NULL). Random raters only.
- Oracle: subject-level MC↔bootstrap endpoint parity (≤.01) + structural sanity
  at both levels; the fully-NA discard contract; reproducibility + RNG hygiene.
- Three-lens review: **zero findings** (properly supersedes the M54 deferral
  with the oracle D-005 required).
- **AC1 amended at the review gate** (user, option A): cross-method CI endpoint
  agreement is pinned at the SUBJECT level only — the wide, few-cluster, ML
  cluster level's MC↔bootstrap tail agreement is BLAS/OS-sensitive (flaked on
  Windows at abs .08, then rel .326 of interval width; Linux/macOS ~.02), a
  platform-numeric artifact, not a code bug. Cluster faithfulness rests on the
  shared refit factory (subject-validated) + the M54 glmmTMB parity oracle.
- Verify: CI green all platforms (incl. Windows); full suite 1725 pass, 0 fail.
- Follow-on: M57 (fixed) and M58 (incomplete/unbalanced) siblings remain planned.
