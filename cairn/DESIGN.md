# Design

<!-- Seeded by /cairn-init migration (2026-07-12) from DESCRIPTION, CLAUDE.md,
     and the migrated project/ board. Marked for the user to refine — the deep
     elicitation (contract boundary, IP/GP formalization) is /design-interview. -->

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

**In scope:** rater-reliability ICCs and their intervals for a stated design.
**Out of scope (as of migration):** subject-count / power / CI-width-target design
helpers — an open design question (see ROADMAP; the estimand is rater reliability,
and the CI-width flavor has no independent oracle).

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

**IP/GP formalization is deliberately deferred** to `/design-interview`: reshaping
these numbered principles into cairn's IP<n>/GP<n> taxonomy at migration time would
be invention-prone and would strand the in-code `PRINCIPLES.md #N` citations.
Until then `PRINCIPLES.md` is the authoritative principles home; this section is a
pointer, not a second copy.

## Known issues

- No cairn-canonical oracle-registry home yet: the working oracle registry lives in
  [`references/REFERENCES.md`](references/REFERENCES.md) (bibliography + registry).
  Whether cairn adopts a dedicated `ORACLES.md` is an open cairn-side question
  (cairn D-024; assessed by cairn M42).
