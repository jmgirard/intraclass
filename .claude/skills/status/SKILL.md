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
