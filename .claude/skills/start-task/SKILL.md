---
name: start-task
description: Begin the next task on the board. Use when the maintainer says "start the next task", "begin work", or "let's do the next thing".
allowed-tools: Read, Grep, Glob, Edit, Write
---

## Board
@project/TASKS.md

## Instructions
1. Select the **next unblocked** task from `project/TASKS.md` (top-down within the
   active milestone). If every remaining task is blocked, say so and stop.
2. Restate the task's **acceptance criteria** and name the specific
   `project/PRINCIPLES.md` items it must honor (e.g. #1 oracle-first, #2 name the
   estimand, #3 boundary-aware CIs, #8 cli/classed errors).
3. Set `project/STATUS.md` "Active task" to this task and "Updated" to today.
4. **Outline a plan before editing any code.** For a statistical task, name the
   estimand and the oracle set first (PRINCIPLES.md #2, #14). Do not begin
   implementation until the plan is stated.

Respect the milestone gate (PRINCIPLES.md #14): do not start a task from milestone
N+1 while milestone N is unfinished.
