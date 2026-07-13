# Design

<!-- Seeded by /cairn-init migration (2026-07-12); Purpose/boundary/posture
     deepened by /design-interview Phase 1 (2026-07-12). Phase 2 (IP/GP
     formalization) pending — see the seam block at the bottom. -->

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

The repo's 19 load-bearing domain principles (the "constitution") are maintained
in [`PRINCIPLES.md`](PRINCIPLES.md) with their original numbering `#1`–`#19`,
reproduced verbatim from the founding brief (`CLAUDE_CODE_KICKOFF.md` §2) and
cited by number in ~70 source comments across the package.

**IP/GP formalization is deliberately deferred** to `/design-interview` Phase 2
(Phase 1 completed 2026-07-12; banked candidates in the seam block below).
Reshaping the numbered principles into cairn's IP<n>/GP<n> taxonomy must not
strand the in-code `PRINCIPLES.md #N` citations. Until Phase 2 lands,
`PRINCIPLES.md` is the authoritative principles home; this section is a pointer,
not a second copy.

## Known issues

- No cairn-canonical oracle-registry home yet: the working oracle registry lives in
  [`references/REFERENCES.md`](references/REFERENCES.md) (bibliography + registry).
  Whether cairn adopts a dedicated `ORACLES.md` is an open cairn-side question
  (cairn D-024; assessed by cairn M42).
- **brms/Stan verification is structurally weaker** than the other engines':
  live-Stan tests can't run on CI (no toolchain), flake on MCMC noise locally, and
  coverage sweeps are ~2-hour background jobs. (Wart confirmed 2026-07-12.)
- **Cross-engine parity has no standing matrix:** parity was established
  milestone-by-milestone, so a new estimator or an upstream engine update could
  open a silent gap. (Wart confirmed 2026-07-12.)
- **Boundary-fit convergence handling is accumulated case law**, not one
  principled policy — near-zero variance components are the common applied case.
  (Wart confirmed 2026-07-12.)
- **Statistical corners are held by ADR memory:** correct-but-non-obvious
  subtleties (e.g. the fixed-rater 2b moment correction in the shared draw
  helper) risk being "simplified" into wrongness by a future contributor or
  session. (Wart confirmed 2026-07-12.)

<!-- ============================================================
     design-interview SEAM (2026-07-12) — banked candidates for Phase 2.
     Interview working state: Phase 2 consumes this block and removes it.
     Proposed strengths are hypotheses; Phase 2 classifies (IP/GP/skip),
     stress-tests, and resolves the mapping onto PRINCIPLES.md #1–#19
     without stranding in-code #N citations.

     B1 faithful-implementer — new estimators require a published primary
        source; the package never ships a novel/unpublished method
        (sharpens #1/#4). Proposed: IP.
     B2 icc-only-identity — the contract boundary is the interrater ICC
        family, permanently; other coefficients route elsewhere. Proposed: IP.
     B3 applied-first-design-center — defaults, errors, and front-door docs
        optimize for the applied non-expert; methodologist tier is secondary
        (sharpens #13). Proposed: GP.
     B4 which-not-how-good — the package never qualitatively labels ICC
        magnitude (no poor/good/excellent, no benchmark cutoffs in output).
        Proposed: IP or GP — decide.
     B5 cran-one-way-door — exported behavior free-with-D-entry until first
        CRAN submission; lifecycle deprecation after (paper examples must
        keep running). Proposed: GP + possibly a D-entry.
     B6 platform-honesty — commit only to platforms/R versions CI verifies;
        fix the R>=3.5 leftover at release prep. Proposed: GP.
     B7 engine-roster-closed — four engines, one per paradigm; a new engine
        must enable an unreachable estimand. Proposed: GP.
     B8 precision-planning-gated — CI-width d_study direction stays open,
        gated on an oracle strategy. Likely a ROADMAP fact, not a principle
        (Phase 2: skip → keep as candidate row).
     Wart-derived candidates for Phase 2 to weigh (principle vs. work item):
     W1 standing engine×estimator parity matrix (work candidate?)
     W2 boundary-fit convergence policy consolidation (work candidate?)
     W3 ADR-held corners get in-code guard tests/comments so they can't be
        "simplified" away (possible GP or LESSONS entry).
     ============================================================ -->
