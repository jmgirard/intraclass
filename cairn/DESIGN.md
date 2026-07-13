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

## Conventions

- **Oracle-first:** every exported estimator passes ≥2 independent oracle types;
  no fabricated reference values (cited source or committed seeded script).
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
  constitutional amendment (D-entry + user decision).
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

## Known issues

- No cairn-canonical oracle-registry home yet: the working oracle registry lives in
  [`references/REFERENCES.md`](references/REFERENCES.md) (bibliography + registry).
  Whether cairn adopts a dedicated `ORACLES.md` is an open cairn-side question
  (cairn D-024; assessed by cairn M42).
- **brms/Stan verification is structurally weaker** than the other engines':
  live-Stan tests can't run on CI (no toolchain), flake on MCMC noise locally, and
  coverage sweeps are ~2-hour background jobs. (Wart confirmed 2026-07-12;
  disposition: ROADMAP candidate "brms/Stan verification hardening" — largely
  inherent, mitigate + document.)
- **Cross-engine parity has no standing matrix:** parity was established
  milestone-by-milestone, so a new estimator or an upstream engine update could
  open a silent gap. (Wart confirmed 2026-07-12; → planned M49.)
- **Boundary-fit convergence handling is accumulated case law**, not one
  principled policy — near-zero variance components are the common applied case.
  (Wart confirmed 2026-07-12; → planned M50.)
- **Statistical corners are held by ADR memory:** correct-but-non-obvious
  subtleties (e.g. the fixed-rater 2b moment correction in the shared draw
  helper) risk being "simplified" into wrongness by a future contributor or
  session. (Wart confirmed 2026-07-12; → planned M51, boundary corner → M50.)

