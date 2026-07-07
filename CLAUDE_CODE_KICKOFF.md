# Kickoff Brief — intraclass: Modern Intraclass Correlation Coefficients in R

> **Paste this as your opening message to Claude Code** (or save it at
> the repo root and say “read `CLAUDE_CODE_KICKOFF.md` and follow
> section 0”). It is the founding document for the project. The package
> name is **`intraclass`** (all lowercase). Confirm it is still free
> with `available::available("intraclass")` before the first push. The
> “modern” positioning lives in the package **Title/Description**
> (“Modern Intraclass Correlation Coefficients”), not the name.

------------------------------------------------------------------------

## 0. How to use this brief (read first)

You are bootstrapping a new, high-quality R package. **Do not start
writing statistical code yet.** Your first job is to (a) internalize the
principles in §2, (b) enter **plan mode** and produce the scaffolding +
milestone plan in §7, and (c) **stop and wait for my approval** before
creating anything. Build in thin vertical slices, verify against
numerical oracles, and keep the tracking files in §4 current at all
times.

When anything in this brief conflicts with something you “know,” this
brief wins. When you are unsure about a *statistical* claim, stop and
verify per §5 rather than guessing.

------------------------------------------------------------------------

## 1. Mission & context

Build an R package that operationalizes the **generalizability-theory
(GT) framework for intraclass correlation coefficients (ICCs)**
developed by ten Hove, Jorgensen & van der Ark, using **modern
variance-component estimation** rather than the classical ANOVA /
McGraw–Wong mean-squares approach.

**Why this package should exist (the differentiators):** - Existing
tools split into two camps. The classical ones (`psych`, `irr`, `irrNA`,
`irrICC`, `ICCDesign`) are ANOVA / mean-squares based. Most assume
balanced data, though a few tolerate missing cells — `irrICC` (Gwet) and
`irrNA` compute ICCs from a wide rating matrix with `NA`s, which is the
closest prior art on incomplete designs, but still within the classical
model rather than a mixed-model / MC-CI approach. The model-based ones
(`performance::icc`, `gtheory`, `misty`) extract a *variance-partition
coefficient* from a fitted model but do **not** implement the full
interrater-reliability ICC family (absolute agreement vs. consistency ×
single vs. average × fixed vs. random raters), the error-variance
framing, or a selection framework. - The GT framework’s own reference
code is loose supplementary scripts, not an engineered package. - **The
gap we fill:** a coherent, well-tested package that (1) fits variance
components with modern engines, (2) computes the *correct* ICC for a
stated design with proper interval estimation, (3) handles imbalanced /
incomplete / multilevel designs, and (4) **teaches the user which ICC to
choose and why**.

**Audience:** applied researchers in psychology, education, medicine,
behavioral science who need defensible IRR estimates and guidance.

**A first-class goal, not an afterthought:** the package *and its
pkgdown site* are a place to learn ICC best practices. Every estimator’s
docs and every vignette must explain the estimand, the assumptions, and
the tradeoffs behind each “knob,” and guide the reader to a sensible
choice.

**Estimation engines (dependency discipline):** - **Default engine:**
`lme4` and/or `glmmTMB` (MLE of random-effects models). The framework’s
own 2025 simulation work favors MLE-RE with Monte-Carlo CIs on
feasibility and accuracy, so this is the spine. - **Optional engines (in
`Suggests`, never `Imports`):** `brms` / `rstanarm` (Bayesian) and
`lavaan` / `blavaan` (SEM / common-factor). Keep the base install light
and fast; gate optional-engine code behind
[`rlang::check_installed()`](https://rlang.r-lib.org/reference/is_installed.html).

------------------------------------------------------------------------

## 2. Invariant principles (the constitution)

These are load-bearing. Encode them verbatim in `PRINCIPLES.md`.
Changing any principle requires my explicit approval and a dated entry
in `DECISIONS.md`.

### Statistical correctness

1.  **Oracle-first verification.** No estimator is considered correct
    because a formula “looks right” or a model reasoned about it.
    Correctness is *established* by numerical agreement with independent
    oracles: (a) closed-form / textbook values (e.g., Brennan 2001,
    Shrout & Fleiss 1979 worked examples), (b) at least one established
    package on the balanced case it supports
    ([`psych::ICC`](https://rdrr.io/pkg/psych/man/ICC.html), `gtheory`),
    and (c) simulation with known population variance components. Every
    exported estimator must pass ≥2 independent oracle types.
2.  **Name the estimand.** Every ICC function documents precisely what
    population quantity it estimates (which variance components in
    numerator/denominator, single vs. average, agreement
    vs. consistency, fixed vs. random raters) *before* any code is
    written.
3.  **Interval estimation is engine-agnostic and boundary-aware.**
    Default to Monte-Carlo CIs simulated from the parameter covariance
    matrix (the ICC is a non-normal ratio; the delta method is
    unreliable near the zero-rater-variance boundary, which is the
    common case). Report the method used. Never present a point estimate
    without an interval unless explicitly asked.
4.  **No fabricated reference values, ever.** Oracle values in tests
    must come from a cited source or a reproducible script committed to
    the repo (with seed). If a value cannot be sourced or reproduced,
    the test is not written and the estimator is not shipped.
5.  **Fail loudly on ill-posed designs.** If a requested ICC is not
    identified by the supplied design (e.g., a variance component that
    cannot be separated), error with a classed, explanatory condition —
    do not silently return a plausible-looking number.

### Software design

6.  **Stable, small public API.** Exported surface is deliberate and
    documented. Internal helpers are not exported. Breaking changes
    require a `DECISIONS.md` entry.
7.  **Tidy S3 generics.** Provide `print`, `summary`, and `format`
    methods; `tidy`/`glance`/`augment` (via the `generics` package) and
    an `autoplot` where sensible. Fitted-object classes are explicit and
    documented.
8.  **All user-facing messaging via `cli`.** Progress, warnings, and
    informative notes use `cli`. All errors use
    [`rlang::abort()`](https://rlang.r-lib.org/reference/abort.html)
    with a classed condition and an actionable message. No bare
    [`stop()`](https://rdrr.io/r/base/stop.html)/[`warning()`](https://rdrr.io/r/base/warning.html)/[`cat()`](https://rdrr.io/r/base/cat.html)/[`print()`](https://rdrr.io/r/base/print.html)
    for user communication.
9.  **Pure functions, explicit state.** No reliance on global options
    for correctness; no writing to the user’s filesystem or `.GlobalEnv`
    as a side effect.

### Testing

10. **testthat 3e, everything exported is tested.** Oracle tests
    (principle 1), edge/boundary tests, error-path tests, and snapshot
    tests for printed output and error messages. No `skip()` without a
    documented, time-bound reason.
11. **Coverage is a floor, not a goal.** Target ≥90% but treat oracle
    coverage of statistical paths as the real bar. CI fails on coverage
    regression.

### Reproducibility & provenance

12. **Seeded and sourced.** Any stochastic code (simulation, MC CIs) is
    seeded in tests. Every statistical method in the code and docs cites
    its source (paper + equation where possible) in a comment and in
    `REFERENCES.md`.

### Documentation-as-teaching

13. **Explain the “why.”** Every exported statistical function’s docs
    include a short “Which ICC is this, and when should you use it?”
    note and the key tradeoff. Vignettes actively guide decisions rather
    than just demonstrating syntax.

### Process

14. **Plan before code; respect milestone gates.** No implementation
    without an approved plan for the current milestone. No starting
    milestone N+1 before N meets its Definition of Done (§8).
15. **Thin vertical slices.** Prefer one estimator working end-to-end
    (fit → estimate → CI → print/tidy → tested → documented → CI green)
    over broad half-built scaffolding.
16. **Tracking files are always current.** After each completed unit of
    work, update the §4 files atomically in the same commit. The
    tracking system is the single source of truth for project state.
17. **No scope creep.** New ideas go to `ROADMAP.md` as proposals, not
    into the current milestone.

### Agent conduct

18. **Escalate uncertainty, don’t paper over it.** On any statistical
    doubt, invoke the verification procedure (§5) and the routing policy
    (§6). State assumptions explicitly. It is always acceptable to stop
    and ask me.
19. **Fable is never invoked automatically.** No subagent, skill, hook,
    or auto-delegation may route work to Fable (or any Mythos-tier
    model). Fable is used only after I explicitly approve it for a
    specific, named task, because it incurs additional token cost.
    Agents may *recommend* a Fable review and must then wait; they may
    not perform it. Default all automated verification to Opus.

------------------------------------------------------------------------

## 3. Modern tooling requirements

Scaffold with `usethis`; prefer generating config via `usethis`/`use_*`
helpers so versions stay current.

- **Package skeleton:** `usethis::create_package()`, MIT license
  (confirm with me), `use_readme_rmd()`, `use_news_md()`,
  `use_lifecycle()` for badges.
- **Testing:** testthat **3rd edition** (`use_testthat(3)`), snapshot
  tests, `use_coverage()` (covr → Codecov).
- **Messaging & conditions:** `cli` for messaging; `rlang` classed
  conditions for errors/warnings. Add a small internal `abort_*()`
  helper layer.
- **Generics:** `generics` (for `tidy`/`glance`/`augment`);
  [`ggplot2::autoplot`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  methods where a plot aids interpretation.
- **Docs:** `roxygen2` with markdown enabled; `use_package_doc()`; spell
  check (`use_spell_check()`, maintain `inst/WORDLIST`).
- **Website:** `pkgdown` with a deliberate reference index (grouped by
  design type), plus vignettes:
  - *Getting started* — fit → ICC → interpret, on a clean balanced
    example.
  - *Choosing an ICC* — the decision framework: agreement
    vs. consistency, single vs. average, fixed vs. random raters,
    complete vs. incomplete, subject- vs. cluster-level. This is the
    flagship teaching article.
  - *Advanced / imbalanced & multilevel* — incomplete designs,
    multilevel ICCs, engine choice (LMM vs. SEM vs. Bayesian) and when
    each matters, CI methods.
- **CI (GitHub Actions via `usethis::use_github_action()`):**
  `R-CMD-check` (matrix: release + devel + oldrel, at least Linux +
  macOS + Windows), `test-coverage`, `lint`, `pkgdown` deploy on
  release/main. Add a scheduled `reference-values` job that reruns the
  oracle/simulation scripts and diffs against committed expectations.
- **Style & hygiene:** `lintr` + `air` (or `styler`) formatting;
  `use_pre_commit()` if you use pre-commit; `use_tidy_description()`.
- **Dependency discipline:** minimal `Imports`; optional engines and
  heavy deps in `Suggests` with
  [`rlang::check_installed()`](https://rlang.r-lib.org/reference/is_installed.html)
  guards; document the light-install path.

------------------------------------------------------------------------

## 4. Documentation-based design, milestone & tracking system

Create a `project/` directory (committed) as the single source of truth.
Keep **`CLAUDE.md` lean** — it should mostly *point to* these files and
the skills in §5, because `CLAUDE.md` is paid for on every turn while
these load on demand.

    project/
    ├── PRINCIPLES.md     # §2 verbatim. Change-controlled.
    ├── ROADMAP.md        # long-range vision + proposed (not-yet-scheduled) work
    ├── MILESTONES.md     # ordered milestones, each with Definition of Done + status
    ├── TASKS.md          # current-milestone task board (checkbox list, one owner-agent each)
    ├── STATUS.md         # compact current-state snapshot the skills read/update
    ├── DECISIONS.md      # ADR log: dated statistical & architectural decisions + rationale + refs
    └── REFERENCES.md     # bibliography + registry of oracle values used in tests, with provenance

**Conventions the agents must follow:** - `STATUS.md` is short and
structured (current milestone, active task, last green-CI commit,
blockers). It is updated on every task transition. - Every non-trivial
statistical or API decision gets a `DECISIONS.md` entry (ADR format:
context → decision → consequences → references). - `REFERENCES.md` links
each oracle value in the test suite to its source (citation or committed
script + seed). - Tracking updates ship *in the same commit* as the work
they describe.

**Seed templates** (create these on bootstrap):

`STATUS.md`

``` markdown
# Project status
- Milestone: M0 — scaffolding (not started)
- Active task: —
- Last green CI: —
- Blockers: —
- Updated: <date> by <agent>
```

`DECISIONS.md` entry template

``` markdown
## ADR-000: <title>
- Date: <yyyy-mm-dd>
- Status: proposed | accepted | superseded
- Context: <why this came up>
- Decision: <what we chose>
- Consequences: <tradeoffs, what it rules out>
- References: <paper + equation / issue / package>
```

`MILESTONES.md` entry template

``` markdown
## M<n>: <name>
- Goal: <one sentence>
- Definition of Done: <checklist, see §8>
- Status: not started | in progress | done (commit <sha>)
```

------------------------------------------------------------------------

## 5. Custom skills (operate the system)

Create these as `.claude/skills/<name>/SKILL.md` (folder per skill, YAML
frontmatter + markdown body). They are both auto-loadable and invocable
as `/name`. Descriptions are the trigger — write them concretely. Flesh
out bodies during bootstrap following these specs.

- **`status`** — *“Report current project state and what to do next.”*
  Reads `STATUS.md` + `MILESTONES.md` + `TASKS.md`; prints current
  milestone, active task, blockers, next action. Read-only.
- **`start-task`** — *“Begin the next task on the board.”* Selects the
  next unblocked task, restates its acceptance criteria and the specific
  PRINCIPLES it must honor, sets `STATUS.md` to in-progress, and
  outlines a plan before editing code.
- **`finish-task`** — *“Close out the current task.”* Runs
  `devtools::check()`, tests, lint, and coverage; only on green, updates
  `TASKS.md`/`STATUS.md`, adds a `DECISIONS.md` entry if a decision was
  made, and proposes a conventional commit message. Never marks done on
  red.
- **`verify-estimator`** — *“Verify a statistical estimator against
  oracles.”* Implements §2 principle 1: assembles the oracle set
  (textbook/analytic, established package, simulation), runs the
  comparison **on Opus**, and reports agreement to tolerance. Writes
  results to `REFERENCES.md`. If a result cannot be pinned by any
  oracle, it does **not** escalate on its own — it surfaces the gap and
  *recommends* I approve a Fable review (§6, principle 19), then stops.
- **`new-estimator`** — *“Scaffold a new ICC estimator.”* Generates the
  function stub, the documented estimand block, the test skeleton with
  the required oracle checklist, and a `DECISIONS.md` stub. Refuses to
  leave an estimator without its oracle tests.
- **`add-decision`** — *“Record an architectural/statistical decision.”*
  Appends a filled ADR to `DECISIONS.md`.

Example `SKILL.md` skeleton (`.claude/skills/status/SKILL.md`):

``` markdown
---
name: status
description: Report current project state and the next action. Use when I ask "where are we", "what's next", or "status".
allowed-tools: Read, Grep, Glob
---
## Current state
!`cat project/STATUS.md`

## Instructions
Summarize the active milestone and task, list blockers, and state the single next action.
Do not modify files. If STATUS.md is stale relative to git history, say so.
```

------------------------------------------------------------------------

## 6. Agent / model routing policy

**Baseline: Opus.** Run the main session on Opus and default subagents
to Opus. Encode this policy in `CLAUDE.md` and in per-subagent `model:`
frontmatter.

| Work type | Model | How it runs |
|----|----|----|
| Main session, architecture, public API, non-trivial implementation, statistical code, code review | **Opus** | Default session model + default subagent model |
| Mechanical / low-complexity: roxygen tidying, NEWS/changelog, lint auto-fixes, boilerplate, file discovery/search | **Sonnet** | Pinned via `model: sonnet` on specific subagents |
| High-stakes statistical *review* — checking a derivation, stress-testing an estimator whose result no oracle can pin, or vetting a novel CI method | **Fable** | **Manual only, after my explicit approval** — never a subagent, never auto-delegated (principle 19) |
| Anything | **Never Haiku** | Excluded by policy |

**Subagents (auto-delegable) are Opus or Sonnet only.** Encode them in
`.claude/agents/`. Example:

``` markdown
---
name: doc-polisher
description: Tidies roxygen, NEWS, and prose. Use for low-risk documentation edits only.
tools: Read, Edit, Grep, Glob
model: sonnet
---
You tidy documentation without changing behavior or public API. Never edit R logic or tests.
```

**Fable is a manual, gated escalation — not an agent.** Do **not**
create a Fable subagent (auto-delegation is driven by the description
field, so a Fable subagent could fire itself and burn tokens; and it is
not established that a subagent can even run above the session’s model
tier). Instead, when `verify-estimator` reports that a result cannot be
pinned by any oracle, it presents the gap and stops. If I approve a
Fable review, I will run it deliberately — by switching the session
model with `/model` or opening a separate Fable session — using this
checklist as the reviewer prompt:

> *Statistical review (Fable). Correctness is established by numerical
> oracles, not by assertion. (1) Check the derivation and assumptions
> against the cited source and equation. (2) Identify
> boundary/degenerate cases the current oracles miss (e.g., zero rater
> variance, single rater, fully incomplete rows). (3) Flag anything
> unproven and name the specific oracle that would settle it. Do not
> approve a result that lacks an oracle.*

Record the outcome (and the fact that Fable was used) in `DECISIONS.md`.

**Two honesty caveats — do not skip:** - **Review ≠ a smarter model.** A
more capable model can *reason* about correctness but cannot *establish*
it. Oracle tests (§2.1) remain the source of truth; a Fable review
stress-tests and finds gaps, it does not certify. - **Fable availability
is unconfirmed** here, and Mythos-tier models have a safeguards
mechanism that can route some queries to Opus 4.8. Confirm it resolves
via `/model` before relying on it; if it doesn’t, do the review on Opus
and note it in `DECISIONS.md`.

Note: the built-in Explore agent inherits the main model, capped at
Opus, so with an Opus main session no exploration falls to Haiku —
consistent with policy.

------------------------------------------------------------------------

## 7. First actions (do these now, then STOP)

1.  **Environment check.** Report R version, and presence of `git`,
    `gh`, `pandoc`, and whether `lme4`/`glmmTMB` install cleanly.
    Confirm which of Opus/Sonnet/Fable your `/model` actually exposes.
2.  **Name.** The name is decided: **`intraclass`**. Confirm it is still
    available with `available::available("intraclass")` and set the
    package `Title` to “Modern Intraclass Correlation Coefficients” with
    a `Description` that states the GT framework + modern-engine
    positioning. If (unexpectedly) the name is now taken, stop and tell
    me rather than picking a substitute.
3.  **Enter plan mode.** Produce, for my approval and *without creating
    files yet*:
    - a draft of `PRINCIPLES.md` (from §2),
    - the `project/` tracking files and their seed content,
    - the `.claude/skills/` and `.claude/agents/` set (§5–6),
    - the CI + pkgdown plan (§3),
    - a `MILESTONES.md` draft whose **M1 is a single vertical slice**
      (see below),
    - a lean `CLAUDE.md` that points to `PRINCIPLES.md`, the tracking
      files, and the routing policy. **Then stop and wait for my
      sign-off.**
4.  **On approval:** create the scaffolding, get an empty-but-green CI
    and a stub pkgdown site building, commit.
5.  **Milestone 1 (vertical slice), proposed:** implement **two-way
    random-effects, absolute-agreement ICC — `ICC(A,1)` and `ICC(A,k)`**
    — via the `lme4`/`glmmTMB` engine, with Monte-Carlo CIs,
    `print`/`summary`/`tidy` methods, oracle tests against (a) a
    Shrout–Fleiss / Brennan worked example, (b)
    [`psych::ICC`](https://rdrr.io/pkg/psych/man/ICC.html) on the
    balanced case, and (c) a seeded simulation, plus the *Getting
    started* vignette — all CI green. Prove the whole pipeline on one
    estimator before widening.
6.  **Only then** propose Milestone 2, re-planned in light of what M1
    taught us.

### Milestone strategy: map the arc now, specify only M1

Draft a **lightweight milestone map** now for directional coherence, but
write full acceptance criteria for **M1 only**. Everything past M1 is a
one-line, explicitly **provisional** entry in `MILESTONES.md` (mark it
`status: provisional`), to be detailed at the *start* of its milestone
after a short retro on the previous one. Detailed specs for M2+ written
today would just be rework once M1 surfaces the real API shape and the
estimator abstraction. A proposed arc (adjust freely):

- **M1** — two-way random, absolute agreement, `ICC(A,1)`/`ICC(A,k)`,
  LMM engine, MC CIs, full pipeline. *(fully specified)*
- **M2** — consistency variants `ICC(C,1)`/`ICC(C,k)`; fixed-vs-random
  rater handling; the estimand/selection abstraction generalized.
  *(provisional)*
- **M3** — imbalanced & incomplete designs (missing rater×subject
  cells); the “Choosing an ICC” flagship vignette. *(provisional)*
- **M4** — multilevel ICCs (subject-level vs. cluster-level, ten Hove
  2021). *(provisional)*
- **M5** — optional engines behind `Suggests`: Bayesian
  (`brms`/`rstanarm`) and/or SEM (`lavaan`) backends with a shared
  interface. *(provisional)*
- **M6** — release polish: `pkgdown` site, advanced vignette, CRAN
  submission prep. *(provisional)*

Treat this arc as a hypothesis, not a contract. Re-order or split when
reality demands, and record any change in `DECISIONS.md`.

------------------------------------------------------------------------

## 8. Definition of Done

**Per estimator:** estimand documented; ≥2 independent oracle types
passing; boundary/error paths tested; `cli` messaging + classed errors;
`print`/`summary`/`tidy` methods; snapshot tests; roxygen with a “which
ICC / when” note; `REFERENCES.md` updated; `DECISIONS.md` entry if a
choice was made.

**Per milestone:** all its tasks done to the above bar; `R-CMD-check`
clean on the full matrix (0 errors/warnings; notes justified); coverage
floor met with statistical paths oracle-covered; pkgdown builds;
relevant vignette written and knits; `MILESTONES.md`/`STATUS.md`
updated; a clean tagged commit.

------------------------------------------------------------------------

*End of brief. Begin at §7 step 1.*
