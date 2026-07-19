# Design

<!-- Seeded by /cairn-init migration (2026-07-12); deepened by /design-interview
     (both phases completed 2026-07-12; D-001..D-003). -->

## Purpose & Scope

`intraclass` estimates interrater-reliability **intraclass correlation
coefficients (ICCs)** within the generalizability-theory framework using **modern
mixed-model variance-component estimation** (linear mixed models) rather than the
classical ANOVA mean-squares approach. It provides the full ICC family (absolute
agreement vs. consistency, single vs. average, fixed vs. random raters, one-way vs.
two-way) with boundary-aware Monte-Carlo confidence intervals, support for
imbalanced/incomplete/multilevel (nested) designs, decision-study projection, and
an interactive helper for choosing the correct coefficient. Multilevel methods
follow ten Hove, Jorgensen & van der Ark (2022, <doi:10.1037/met0000391>).

**Audience (design center):** applied behavioral/clinical researchers who must
report a defensible ICC — defaults, error messages, and the front-door vignettes
optimize for the user who doesn't yet know which ICC they need. Methodologists are
the secondary audience, served by the technical tier (`engines`/`interval-methods`
vignettes, `cairn/estimand-specs/`). (Design interview, 2026-07-12.)

### Contract boundary (elicited 2026-07-12)

- **ICC-only, permanently.** Interrater-reliability ICCs and their intervals are
  the whole job. Categorical agreement (kappa, alpha), internal consistency, and
  general multi-facet G-studies are out forever; requests for other coefficients
  route to other packages.
- **Faithful implementer, never a methods contributor.** Every estimator traces to
  a published primary source (plus the ≥2-oracle bar); parked items stay blocked
  until the literature moves, however tractable a derivation looks.
- **Guidance covers "which," never "how good."** The package guides estimand
  choice and interval reading; it never labels a value poor/good/excellent.
  Qualitative cutoffs are context-dependent and citing them would lend false
  authority — `print`/`summary` stay label-free (vignettes may discuss why
  cutoffs are problematic, with citations).
- **`d_study()` projects reliability inputs only** (rater/occasion counts —
  facets that change the coefficient's value). Precision planning (CI-width
  targeting, "how many subjects for a ±.1 interval?") is a legitimate future
  direction **gated on finding an oracle strategy** (open ROADMAP candidate);
  subject-count-for-power as such is not in scope.

## Commitments & posture (elicited 2026-07-12)

- **Distribution:** CRAN is the canonical channel, with a companion
  software/methods paper as the citation target (the M42 comparison article is a
  paper seed). Release *timing* stays a ROADMAP call.
- **API stability:** exported behavior may change with just a D-entry until the
  first CRAN submission; from then on every breaking change takes a lifecycle
  deprecation cycle — the paper's examples must keep running. Submission is the
  one-way door; pre-CRAN cleanups happen before it.
- **Platforms:** the commitment is exactly the CI matrix — R release, oldrel-1,
  and devel on macOS/Windows/Ubuntu. The declared `R (>= 3.5)` floor is a known
  leftover to correct honestly (raise to what the dependency chain requires) at
  release prep.
- **Engine roster: closed at four.** glmmTMB (frequentist default), lme4
  (frequentist oracle), brms (Bayesian), lavaan (SEM) — each paradigm represented
  once. A new engine must enable an estimand the four can't reach, not just be
  another fitter; per-estimator parity cost stays capped at ×4.
- **Contribution posture:** solo-maintained; issues welcome, code contributions
  not solicited (the oracle-first bar is hard to enforce on drive-by PRs).
  External PRs triage through the cairn intake path.

## Architecture

- **Estimation engines** behind one interface: **glmmTMB** (default, `Imports`);
  **lme4**, **brms** (Bayesian), and **lavaan** (SEM) are alternate engines and
  independent oracles, all in `Suggests` behind `rlang::check_installed()` — never
  `Imports` (light-install path pulls only glmmTMB, cli, rlang, generics).
- **Public surface:** `icc()` (fit → estimate → interval), `d_study()`
  (decision-study projection), and `choose_icc()` (selection helper), plus tidy S3
  methods (`print`/`summary`/`format`/`tidy`/`glance`/`augment`/`autoplot`).
- **Intervals** default to boundary-aware Monte-Carlo CIs from the parameter
  covariance matrix; bootstrap and posterior methods are selectable.
- **Ill-posed designs fail loudly** through a classed `abort_*()` layer.
- **Cross-engine parity** is held by one standing asset,
  `tests/testthat/test-engine-parity-matrix.R` (M49): it enumerates the
  (estimand × engine) grid, pins frequentist point-estimate agreement to
  calibrated tolerances, asserts every documented engine refusal fires, and
  reads `icc()`'s engine roster from its own source so a new engine breaks the
  matrix until a row is added (GP4). Its header carries the "add a row" rule.
  Interval parity and the brms engine's live-Stan agreement are cross-referenced
  to the per-engine tests, not re-run there.

## Conventions

- **Oracle-first:** every exported estimator passes ≥2 independent oracle types;
  no fabricated reference values (cited source or committed seeded script).
- **Oracle records:** the central registry `cairn/references/ORACLES.md` (one
  entry per oracle: ID, type, asserting `test:line`, source, provenance).
  Sources live in `references/BIBLIOGRAPHY.md` + the `<citekey>.md` source
  notes indexed by `references/INDEX.md`. (D-007)
- **Name the estimand before coding;** thin vertical slices; plan before code.
- **All user messaging via `cli`; all errors classed via `rlang::abort()`** — no
  bare `stop()`/`warning()`/`cat()`/`print()`.
- **Format with `air`** (`air format .`); CI enforces `air format --check`;
  `lintr` owns semantic linters only.
- Tracking travels with code (cairn: same commit as the work).

## Design Principles

Two homes, one taxonomy (D-001): the founding constitution stays in
[`PRINCIPLES.md`](PRINCIPLES.md) as `#1`–`#19`, strength-tagged **[IP]/[GP]** in
place so its ~70 in-code `PRINCIPLES.md #N` citations stay valid (statistical
core #1–#5, #12 and the Fable gate #19 are IP; #6–#10, #13, #18 are GP; #11
amended by D-002; #14–#17 retired into cairn's rulebook by D-003). The
principles below were derived by the 2026-07-12 design interview; numbers run
within each type and are never reused or renumbered (retiring one takes a
D-entry).

### Inviolable (IP)

- IP1: **Faithful implementer.** Every exported statistical method — estimator
  *or interval procedure* — traces to a published primary source; the package
  never ships a novel/unpublished method. Parked capabilities stay blocked until
  the literature moves, however tractable a derivation looks. Numerical
  implementation details (optimizer, parameterization) are fenced off: they need
  correctness, not a citation. (Sharpens `PRINCIPLES.md #1/#4`.)
- IP2: **ICC-only identity.** The contract boundary is the interrater ICC
  family, permanently: categorical agreement, internal consistency, and general
  multi-facet G-studies route to other packages. Scope expansion requires a
  constitutional amendment (D-entry + user decision). Citable record for the
  hypothesis-testing side of this boundary: the ICC-equality cluster in
  `cairn/references/` (`konishi1989`, `donner2002`, `young1998`, `naik2007`,
  and `bhandary2006` by subject).
- IP3: **Which, not how good.** The package never qualitatively labels ICC
  magnitude — no poor/good/excellent, no benchmark cutoffs in output, not even
  opt-in. Guidance covers estimand choice and interval reading; vignettes may
  discuss why cutoffs are problematic, with citations.

### Guiding (GP)

- GP1: **Applied-first design center.** Defaults, error messages, and
  front-door docs optimize for the applied non-expert; the methodologist tier
  (engines/interval-methods vignettes, estimand specs) is secondary. (Sharpens
  `PRINCIPLES.md #13`.)
- GP2: **CRAN is the one-way door.** Exported behavior may change with just a
  D-entry until the first CRAN submission; from then on, breaking changes take a
  lifecycle deprecation cycle — the companion paper's examples must keep
  running.
- GP3: **Platform honesty.** Support commitments are exactly what CI verifies
  (currently R release/oldrel-1/devel × macOS/Windows/Ubuntu); no declared floor
  CI doesn't test.
- GP4: **Engine roster closed at four.** glmmTMB, lme4, brms, lavaan — one per
  paradigm. A new engine must enable an estimand the four cannot reach, not just
  be another fitter; per-estimator parity cost stays capped at ×4.
- GP5: **Fix the evidence, never the bar.** A failing stochastic validation pin
  is answered by strengthening the evidence (more replications, per-rep
  seeding), never by loosening the pin post hoc. A genuinely mis-set pin may be
  corrected prospectively with a D-entry, never to turn a red test green.
  (Canonical citation: legacy ADR-042 Amdt 2.)
- GP6: **Sweep the known failure axis.** A simulation-coverage claim includes
  cells along whatever axis the known failure mode grows (cluster count,
  incidence, raggedness), not just comfortable interior cells. (Canonical
  citation: legacy ADR-046 Amdt 1.)
- GP7: **Guard load-bearing subtleties in code.** A correct-but-non-obvious
  statistical corner ships with a guard test plus an in-place comment naming its
  ADR/D-entry, so a future "simplification" fails a test instead of requiring
  archaeology. (E.g. the fixed-rater 2b moment correction.)

## Boundary-fit policy

When a variance component is estimated at or near zero — the boundary of the
parameter space, and the common applied case for interrater data — every engine
and CI method resolves it by one of **three documented behaviors**. This section
is the single home for that policy, consolidating the case law of
ADR-002/003/012/014/023/024/025/031/033/037/038/044 under one statement (recorded
as D-004). It documents *existing* behavior: changing any cell below is a change
to the boundary-aware-interval contract (`PRINCIPLES.md #3`) and takes a D-entry.

- **Smooth (boundary-aware by construction).** The component is held strictly
  positive by the parameterization, so the boundary is approached smoothly with
  no clamp and no abort — via an internal log-SD scale that maps the boundary to
  −∞ (glmmTMB natively; lme4 by delta-transform; lavaan), or via natural-scale
  posterior draws that are positive by construction (brms).
- **Classed deferral.** A boundary fit whose covariance cannot support an
  interval aborts with the classed condition `intraclass_singular_fit`, pointing
  the user at the boundary-robust default engine (glmmTMB).
- **Reach-zero (kept or floored).** A boundary value is admitted rather than
  discarded, so the estimate/interval can reach 0: a resample or posterior draw
  with a component at exactly 0 is a legitimate draw and is **kept**
  (bootstrap, posterior); and the fixed-rater θ²_r **average is floored** at 0
  (never per group; see below).

Fit-time, per engine:

| Engine | Boundary handling | Source |
|---|---|---|
| glmmTMB | Smooth log-SD; the boundary maps to −∞ and the fit stays finite — the reference boundary-robust engine | ADR-002/003 |
| lme4 | Interval draws delta-transformed to log-SD (Smooth); an exactly-singular fit (`lme4::isSingular`) has a singular merDeriv covariance → classed deferral to glmmTMB. The guard was introduced for the two-way-random path (ADR-012) and **reused per shape** as later fits were added (ADR-023 fixed/multilevel; ADR-024 incomplete/ragged) — all 7 fit shapes | ADR-012/023/024 |
| brms | Posterior draws on the natural variance scale, strictly positive → Smooth by construction; the point estimate is the boundary-aware mode of the draws | ADR-033 |
| lavaan | Variances on the log-SD scale (Smooth); a Heywood boundary (non-positive variance, `sv`/`ev` ≤ 0) → classed deferral to glmmTMB | ADR-014/031 |

Interval-time, per CI method:

| CI method | Boundary handling | Source |
|---|---|---|
| Monte-Carlo (default) | Sampled on the engine's internal log scale → boundary-aware by construction; covariance eigenvalues floored at 0 (`pmax`) where a Cholesky factor would fail; a genuinely rank-deficient covariance → classed deferral | ADR-003 |
| Bootstrap | Parametric refit per resample; a singular/boundary refit is a valid draw (variance pinned at 0) and is **kept**. Separately, *non-convergent* refits are discarded: past `warn_frac` a classed warning (`intraclass_bootstrap_dropouts`), past `min_frac` a classed abort (`intraclass_singular_fit`) — never a silent NA interval | ADR-025 |
| Posterior | The engine's own draws (natural scale), **kept**; percentile or HPDI; boundary-aware mode with bounded-density smoothing; degenerate all-equal draws return the common value | ADR-033/044 |

**Fixed-rater θ²_r average-floor (cross-engine).** The fixed-rater θ²_r estimand
adds a boundary-aware *average-floor*: the 2b-corrected per-group draws are
averaged and the **average** is floored at 0 — never per group, since per-group
flooring gives zero boundary coverage. Shared across all four engines' fixed-rater
paths (`theta2r_moment_draws()` / `brms_theta2r_moment_draws()`); ADR-038
(frequentist) / ADR-037 (brms); GP7-guarded.

## Known issues

- ~~No cairn-canonical oracle-registry home yet~~ — RESOLVED by M63 (D-007): the
  registry is [`references/ORACLES.md`](references/ORACLES.md), declared in the
  Conventions section above per the validation doctrine's registry-pointer rule.
  This settles the repo side only; whether *cairn itself* mandates an `ORACLES.md`
  shape remains the upstream open question (cairn D-024, assessed by cairn M42) —
  the repo's choice here is compatible with either outcome.
- ~~**brms/Stan verification is structurally weaker**~~ — RESOLVED by M52
  (mitigate + document; the constraint itself is inherent and stands: no Stan
  toolchain on CI, MCMC flake, ~2-hour sweeps). The offline committed-fixture
  strategy is now documented in `data-raw/README.md` (constraints, test tiers,
  fixture lifecycle, regeneration protocol) and the script↔fixture map is
  mechanically guarded by `tests/testthat/test-brms-oracle-map.R` (GP7).
  (Wart confirmed 2026-07-12.)
- ~~**Cross-engine parity has no standing matrix**~~ — RESOLVED by M49: the
  standing `tests/testthat/test-engine-parity-matrix.R` now enumerates the grid
  and breaks on a silent gap (see Architecture). (Wart confirmed 2026-07-12.)
- ~~**Boundary-fit convergence handling is accumulated case law**~~ — RESOLVED by
  M50: one documented policy in § Boundary-fit policy (three behaviors mapped per
  engine + per CI method, each cell citing its ADR; recorded as D-004) with guard
  tests in `tests/testthat/test-boundary-policy.R`. (Wart confirmed 2026-07-12.)
- ~~**Statistical corners are held by ADR memory**~~ — RESOLVED by M51: the
  audit (inventory in the M51 work log) enumerated the load-bearing corners and
  pinned the unguarded ones in `tests/testthat/test-corner-guards.R` (the
  fixed-rater 2b moment family — 2b-not-1b + average- not per-group floor,
  ADR-037/038 — and the ragged `n_rep ≥ 240` fixture pin, GP5), each with an
  in-place source comment naming its ADR (GP7); the already-guarded corners are
  cross-referenced there. (Wart confirmed 2026-07-12; boundary corner → M50.)

