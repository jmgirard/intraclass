# CLAUDE.md — working guide for intraclass

`intraclass` computes interrater-reliability **intraclass correlation
coefficients** within the generalizability-theory framework using
**modern mixed-model variance-component estimation** (not classical
ANOVA mean squares), with boundary-aware Monte-Carlo confidence
intervals and guidance on choosing the right coefficient.

This file is deliberately lean — it is paid for on every turn. Detail
lives in `cairn/`, loaded on demand.

## Read these first

- **`cairn/PRINCIPLES.md`** — the constitution (19 load-bearing
  principles, `#1`–`#19`). Change-controlled; when it conflicts with
  instinct, it wins.
- **`cairn/DESIGN.md`** — purpose, architecture, conventions (a
  migration seed; deepen via `/design-interview`).
- **`cairn/DECISIONS.md`** — live decisions (D-001…); the full ADR log
  (ADR-001..058) is entombed at `cairn/legacy/DECISIONS.md` and still
  cited by id.
- **`cairn/references/REFERENCES.md`** — bibliography + the oracle
  registry every test value traces to.
- **`cairn/estimand-specs/`** — the precise population definition per
  estimator.
- **Status & the task board:** `cairn/ROADMAP.md` + the active
  `cairn/milestones/` file — cairn owns status now (see the Project
  tracking section below).
- Founding brief: `CLAUDE_CODE_KICKOFF.md`.

## Non-negotiable rules (see PRINCIPLES.md for the full text)

- **Oracle-first (#1):** correctness is *established* by numerical
  agreement with ≥2 independent oracles, never by a formula “looking
  right”.
- **Name the estimand before coding (#2, \#14):** plan before code;
  respect milestone gates; thin vertical slices.
- **Intervals are Monte-Carlo and boundary-aware (#3):** never a point
  estimate without an interval; report the method.
- **No fabricated reference values (#4):** cited source or committed
  seeded script.
- **Fail loudly on ill-posed designs (#5)** via the classed `abort_*()`
  layer.
- **All user messaging via `cli`; all errors via
  [`rlang::abort()`](https://rlang.r-lib.org/reference/abort.html)
  classed (#8).** No bare
  [`stop()`](https://rdrr.io/r/base/stop.html)/[`warning()`](https://rdrr.io/r/base/warning.html)/[`cat()`](https://rdrr.io/r/base/cat.html)/[`print()`](https://rdrr.io/r/base/print.html).
- **Tracking files update in the same commit as the work (#16).**
- **Format with `air` before committing** (`air format .`); CI enforces
  `air format --check`. `lintr` owns the semantic linters only. See
  ADR-004.

## Model routing (§6 of the brief)

| Work type | Model |
|----|----|
| Main session, architecture, public API, statistical code, code review | **Opus** (default) |
| Mechanical: roxygen tidying, NEWS, lint fixes, boilerplate, search | **Sonnet** (e.g. the `doc-polisher` agent) |
| High-stakes statistical *review* (derivations, unpinnable results) | **Fable — manual only, after explicit maintainer approval** (#19); never a subagent, never auto-delegated |
| Anything | **Never Haiku** |

Fable is a gated escalation, not an agent. `verify-estimator` may
*recommend* a Fable review and must then stop and wait.

## Skills

Project tracking is handled by the **cairn plugin** (`/milestone-plan` →
`/milestone-implement` → `/milestone-review`, plus `/milestone`,
`/hotfix`, `/cairn-release`, `/design-interview`) — see the Project
tracking section below. The former repo-local skills (`status`,
`start-task`, `finish-task`, `add-decision`, `new-estimator`,
`verify-estimator`) are entombed at `cairn/legacy/skills/` — superseded
by the plugin. Their domain value (estimator scaffolding,
oracle-verification workflow) is not yet re-expressed in cairn terms.

## Engines & install

- Default engine **glmmTMB** (Imports); **lme4** (Suggests) is an
  alternate engine and an independent oracle. See ADR-002.
- Light-install path: base install pulls only `glmmTMB`, `cli`, `rlang`,
  `generics`. Optional engines (Bayesian/SEM, M5) live in `Suggests`
  behind
  [`rlang::check_installed()`](https://rlang.r-lib.org/reference/is_installed.html)
  — never `Imports`.

## Project tracking (cairn)

This repo uses the cairn plugin. **Before acting on any request,
classify it and route** — the tracking rulebook only loads once a cairn
skill fires, so starting work in plain conversation silently bypasses
the work tiers and the git model. Classify first:

- **Trivial** (no runtime surface — typo, comment, tracking edit):
  commit directly to the default branch.
- **User-visible bug**: invoke `/hotfix`.
- **New work, a design decision, or more than one sitting**: invoke
  `/milestone-plan` (then `/milestone-implement` → `/milestone-review`).
- **Status, “what’s next”, or unsure which tier**: invoke `/milestone`.
- **Never implement code on the default branch** outside a
  milestone/hotfix branch; nothing reaches it without the user’s
  explicit approval at the review gate.

Whenever the request is anything but trivial, invoke the skill *first*
so the full rulebook (the plugin’s `skills/shared/tracking-rules.md`)
and its conduct load — do not reconstruct the rules here from memory.
All project state lives under `cairn/` (**Architecture → DESIGN · Status
→ ROADMAP · Tasks → milestone files · Decisions → DECISIONS · History →
archive + git**); never record status or TODOs in this file. Claude’s
persistent memory never holds project state; `cairn/` files win any
conflict.
