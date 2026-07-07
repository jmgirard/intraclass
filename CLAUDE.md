# CLAUDE.md — working guide for `intraclass`

`intraclass` computes interrater-reliability **intraclass correlation
coefficients** within the generalizability-theory framework using **modern
mixed-model variance-component estimation** (not classical ANOVA mean squares),
with boundary-aware Monte-Carlo confidence intervals and guidance on choosing the
right coefficient.

This file is deliberately lean — it is paid for on every turn. Detail lives in
`project/`, loaded on demand.

## Read these first
- **`project/PRINCIPLES.md`** — the constitution (19 load-bearing principles).
  Change-controlled; when it conflicts with instinct, it wins.
- **`project/STATUS.md`** — current milestone, active task, blockers, next action.
- **`project/MILESTONES.md`** — the plan *and* the task board (the active milestone's
  DoD checklist is the board; no separate `TASKS.md` — ADR-015).
- **`project/DECISIONS.md`** — ADR log (why things are the way they are).
- **`project/REFERENCES.md`** — bibliography + the oracle registry every test value
  traces to.
- **`project/estimand-specs/`** — the precise population definition per estimator.
- Founding brief: `CLAUDE_CODE_KICKOFF.md`.

## Non-negotiable rules (see PRINCIPLES.md for the full text)
- **Oracle-first (#1):** correctness is *established* by numerical agreement with
  ≥2 independent oracles, never by a formula "looking right".
- **Name the estimand before coding (#2, #14):** plan before code; respect
  milestone gates; thin vertical slices.
- **Intervals are Monte-Carlo and boundary-aware (#3):** never a point estimate
  without an interval; report the method.
- **No fabricated reference values (#4):** cited source or committed seeded script.
- **Fail loudly on ill-posed designs (#5)** via the classed `abort_*()` layer.
- **All user messaging via `cli`; all errors via `rlang::abort()` classed (#8).**
  No bare `stop()`/`warning()`/`cat()`/`print()`.
- **Tracking files update in the same commit as the work (#16).**
- **Format with `air` before committing** (`air format .`); CI enforces
  `air format --check`. `lintr` owns the semantic linters only. See ADR-004.

## Model routing (§6 of the brief)
| Work type | Model |
|---|---|
| Main session, architecture, public API, statistical code, code review | **Opus** (default) |
| Mechanical: roxygen tidying, NEWS, lint fixes, boilerplate, search | **Sonnet** (e.g. the `doc-polisher` agent) |
| High-stakes statistical *review* (derivations, unpinnable results) | **Fable — manual only, after explicit maintainer approval** (#19); never a subagent, never auto-delegated |
| Anything | **Never Haiku** |

Fable is a gated escalation, not an agent. `verify-estimator` may *recommend* a
Fable review and must then stop and wait.

## Skills (invoke as `/name`)
`status`, `start-task`, `finish-task`, `verify-estimator`, `new-estimator`,
`add-decision` — see `.claude/skills/`.

## Engines & install
- Default engine **glmmTMB** (Imports); **lme4** (Suggests) is an alternate engine
  and an independent oracle. See ADR-002.
- Light-install path: base install pulls only `glmmTMB`, `cli`, `rlang`,
  `generics`. Optional engines (Bayesian/SEM, M5) live in `Suggests` behind
  `rlang::check_installed()` — never `Imports`.
