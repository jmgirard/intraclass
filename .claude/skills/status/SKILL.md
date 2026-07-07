---
name: status
description: Report current project state and the next action. Use when the maintainer asks "where are we", "what's next", or "status".
allowed-tools: Read, Grep, Glob, Bash(git log:*), Bash(git status:*)
---

## Current state
@project/STATUS.md

## Instructions
Read `project/STATUS.md`, `project/MILESTONES.md`, and `project/TASKS.md`.
Summarize, concisely:
1. the active milestone and its goal,
2. the active task and any blockers,
3. the single next action.

Do **not** modify any files (read-only). Cross-check against git: if
`project/STATUS.md` looks stale relative to recent commits (e.g. it names a task
already completed in `git log`), say so explicitly rather than trusting it.

Also flag **stale transient markers**: grep `project/` for `pending push`,
`done (local)`, or `in progress`, and check each against reality. Use
`git status -sb` (shows ahead/behind vs `origin`) and `git log` — if a
"pending push" milestone/task is in fact already on `origin` (local not ahead),
or an "in progress" milestone has a fully-checked board, report the contradiction
and name the file/line so it can be reconciled.

Also audit **`project/REFERENCES.md` for lapsed oracle statuses** (this file has no
CI gate, so it drifts silently — it once sat two milestones behind). Grep it for
`planned` / `not yet asserted` / `to be committed`; for each hit, cross-check the
milestone it names against `MILESTONES.md` (is that milestone `done`?) and the test
file it names (does it exist with `expect_` assertions?). If a `planned` oracle's
milestone has shipped, report it as a lapse with file/line — it should read
`asserted`.
