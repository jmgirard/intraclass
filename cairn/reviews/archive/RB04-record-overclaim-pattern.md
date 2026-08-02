# RB04: Why this milestone's records keep overclaiming, and what would stop it (M100)

- **Date:** 2026-08-01
- **Output required:** write findings to `cairn/reviews/RR04-record-overclaim-pattern.md`

You are performing an independent expert review. This brief is fully
self-contained — do not assume any conversation context. Read only what this
brief directs you to read, answer the numbered questions, and write your
findings to the output path above using the same numbering.

## Background

`intraclass` is an R package computing interrater-reliability intraclass
correlation coefficients. It is governed by a written constitution
(`cairn/PRINCIPLES.md`); the two rules that matter here are **#5 fail loudly on
ill-posed designs** and **#8 all user messaging via `cli`, all errors via classed
`rlang::abort()`**. A tracking system (`cairn/`) records milestones, decisions and
review evidence, with a hard rule that history is append-only and never edited.

**The milestone.** Several confidence-interval reducers under `R/ci-*.R` abort on
degenerate data, and their error messages end with a remedy bullet telling the
user to switch to a different `ci_method`. M100 set out to measure whether those
suggestions are true — whether the named method actually returns a usable
interval on the data that reached the abort.

**The measurement is finished and is not in question.** A committed sweep
(`data-raw/abort-remedy-sweep.tsv`, 210 rows) found the suggested Monte-Carlo
default usable on 0 of 6 datasets at one guard, 0 of 3 at a second, 1 of 8 at a
third, and 9 of 9 at a fourth. Three of the four shipped suggestions are
untruthful; one is earned. An independent reviewer at the latest gate re-ran two
sweep cells end-to-end and they byte-matched their committed rows.

**The problem is the milestone's records, and it has recurred four times.**
M100 has now failed its review gate in four consecutive passes. Every pass failed
on the same shape — **a durable record asserting more than the artifact it
describes actually supports** — and every pass's repair introduced a fresh
instance of that shape:

- **Pass 1.** An error message asserted a cause ("every rater gave each subject
  the same score") that was false on one disjunct of its own guard condition.
- **Pass 2.** The repair asserted a different false cause (a NaN from overflow
  read as a NaN from 0/0), and a completeness gate was described by three
  separate records as catching a class of code shape it did not catch.
- **Pass 3.** A message stated a *requirement* the guard does not test, and the
  narrowly-repaired gate from pass 2 was re-advertised broadly by three records
  again — described at the time as "the identical 'record outruns the code'
  pattern the amendment was written to correct".
- **Re-cut.** The milestone was re-planned and split: M100 now ships
  **measurement and tooling only** and changes nothing user-facing (`R/`,
  `NEWS.md` and `cairn/DECISIONS.md` were reverted to `main`); all message
  changes moved to M101. The re-cut wrote two new acceptance criteria, AC2 and
  AC5, *specifically* to forbid the overclaim shape.
- **Pass 4 (current).** The tooling verified correct. AC2 and AC5 both failed on
  their first outing, in the very text written to satisfy them.

That last point is the reason for this brief. The question is **not** which
statements are wrong — they are enumerated below and each is individually a
one-line fix. The question is what structure, if any, would stop the next pass
from producing new ones. Four passes of evidence say the implementing session
cannot settle that itself.

## Materials

Read these, in this order. Line references are to the branch
`m100-abort-remedy-truthfulness` at commit `ae478a6`; `git diff main..HEAD` is
the full change.

1. `cairn/milestones/M100-abort-remedy-truthfulness.md` — the whole file. Its
   `## Acceptance criteria` (AC1–AC6) are the re-cut set. Its `## Work log` and
   `## Review` sections record all four passes; note that the review evidence for
   passes 1–3 was measured against a **different, now-deleted** criteria set.
2. `data-raw/enumerate-ci-method-remedies.py` — the enumerator. Its module
   docstring (the section "What the predicate does not match", L1–L6), its
   `_limit_shapes()`, `_unreported_splices()`, `_check_probes()` and `self_test()`
   functions are the ones under discussion. Run
   `python3 data-raw/enumerate-ci-method-remedies.py --self-test` and `--check`.
3. `data-raw/abort-remedy-sites.tsv` — the classification ledger. Its header
   block beginning `WHAT THIS LEDGER DOES NOT COVER` is one of the two records
   that overclaims.
4. `data-raw/sweep-abort-remedies.R` — the sweep. Its file header and the grid
   construction are relevant to finding O6 below.
5. `cairn/PRINCIPLES.md` (#1, #4, #5, #8) and `cairn/DESIGN.md` (the IP/GP block).
6. `cairn/DECISIONS.md` — read by scanning its `### D-` headings and reading whole
   any entry that looks relevant. **D-018** (running a candidate method inside an
   abort path to decide whether to name it) and **D-019** (evidence-based boundary
   endpoints) are the two this milestone touches.

### The eight findings that failed the current gate

Each was scored 80–93 for confidence by an independent scorer, and each was
reproduced. Verbatim, with their scores:

- **O1 (93)** — The ledger header enumerates **seven** shapes the enumeration
  predicate misses (six labelled L1–L6, plus "anything outside `R/ci-*.R`") and
  then asserts *"Each of those shapes is CONSTRUCTED and shown unmatched by a
  probe in `enumerate-ci-method-remedies.py --self-test`"*. `_limit_shapes()`
  returns **six**; there is no probe for the file-scope limit. The milestone's
  `## Decisions` section repeats the claim. AC2's clause *"No record claims
  detection coverage broader than a probe demonstrates"* is violated by two
  durable records at once. Note the script's own docstring is careful and does
  not overclaim, so this is a record error, not a code error.
- **O5 (92)** — A work-log line states *"breaking `BULLET_RE` reds 7"*. Three
  plausible mutations red 8, 8 and 14. Its cited recompute command is
  `--self-test`, which prints `self-test OK` and reproduces neither that figure
  nor the paired *"reds 5"*.
- **O2 (90)** — The milestone's live `## Decisions` section reads *"(D-020,
  promoted to `cairn/DECISIONS.md`)"*. `grep -c 'D-020' cairn/DECISIONS.md`
  returns 0: the re-cut reverted that file. No mechanical check catches it.
- **O10 (88)** — *"all five `data-raw` checkers pass"*. Four exist besides this
  milestone's own. The same drift was logged at pass 1 and recurred.
- **O14 (85)** — *"The 80 unreached rows split 30 point-fit failures and 50 cells
  where the reducer returned an interval."* Both figures are row counts; in cells
  they are 6 and 10.
- **O6 (85)** — The sweep's header claims measurement *"across the whole class of
  data that triggers the abort"*. The classical guard fires on
  `ss$mse == 0 || !is.finite(f)`, but the grid feeds that site only the
  `gen_mse0` generator, so the second disjunct is never generated.
- **O9 (82)** — A broader pattern of claims carrying no reproducing command,
  including *"Verified diagonal on live conditions"* and *"the per-site reach
  counts are identical to the pre-confirmation run"* — the latter unrecomputable
  in principle, because that earlier run was never committed.
- **O11 (82)** — AC4 reads *"This milestone changes nothing user-facing and
  states no rule"*. The git-diff half passes. But the milestone's live
  `## Decisions` section states a rule verbatim — *"static remedy text may name a
  `ci_method` only on swept evidence over the abort's whole trigger class"* — and
  another, *"these guards REPORT the quantities that failed and diagnose
  nothing"*. The reverted code satisfies neither. On merge, that rule lands on the
  default branch while the shipped code contradicts it, which the milestone's own
  Scope section names as the outcome the re-cut exists to prevent.

### The structural tension you are being asked about

AC2 and AC5 are **self-referential**: they are criteria about the accuracy of the
prose that describes the work, enforced by reading that prose. Their text:

> **AC2** The script's docstring, the ledger header and this milestone's records
> state the predicate's LIMITS — the message shapes the script does not match —
> and each stated limit is demonstrated by a self-test probe that constructs that
> shape and shows it unmatched. No record claims detection coverage broader than
> a probe demonstrates.

> **AC5** Every factual claim this milestone's records make about a measured
> result, a count, a ledger key, or this milestone's own review history is
> accompanied by a command that recomputes or locates it, and that command
> reproduces the stated figure or string.

Three properties of these that may or may not be defects — this is for you to
judge, not for the brief to assert:

- They are unbounded over a growing surface. The work log is append-only and
  grows every task; each new line is new surface for AC5 to govern, and the
  criterion is evaluated only at the gate, after all of it is written.
- The prose that describes a verification is necessarily written *after* the
  verification, and often is not re-run afterwards. O5's "reds 7" is exactly this:
  a count observed once, transcribed, never re-derived.
- Nothing mechanical enforces either. `cairn_validate` passes on this branch with
  all checks green, and the enumerator's own `--check` is not wired into CI (the
  repo's `check-references` job runs three other `data-raw` checkers but not this
  one), so the only enforcement is a human reading prose at a gate.

## Questions

1. **Is the recurrence a criteria defect, an enforcement defect, or an authoring
   defect?** Four passes each enumerated the wrong claims, fixed exactly those,
   and produced new ones. Which of these best explains that, and what is your
   evidence: (a) AC2/AC5 are unsatisfiable or near-unsatisfiable as written, so
   any pass fails them; (b) they are satisfiable but nothing mechanical checks
   them, so satisfaction is luck; (c) the milestone simply carries too much prose
   for the claim density to be auditable; (d) something else?

2. **Are AC2 and AC5 achievable as written?** For each, state what state of the
   world satisfies it exactly as written, and whether that state is reachable by
   an author working in a single pass. If either is not achievable, give a
   replacement criterion that captures the same intent and *is* achievable, as a
   binding criterion.

3. **Should this be mechanically enforced, and can it be?** The repo's
   established pattern is a committed `data-raw/` checker wired into the CI lint
   job (there are four such checkers today). Is a "claims checker" — one that
   extracts factual claims and their cited commands from tracking prose, runs the
   commands, and fails on a mismatch — feasible and worth its own cost? If yes,
   specify precisely what it should check and what it must *not* attempt. If no,
   say what should replace it.

4. **How should a re-cut handle history that its new scope contradicts?** O2 and
   O11 both arise from the milestone's `## Decisions` section, which carries dated
   entries written before the re-cut: one says a decision was promoted to a file
   the re-cut then reverted; another states a rule the re-cut moved to a
   successor milestone. The tracking rules make that section append-only history
   that must never be edited, yet it will land on the default branch stating
   things that are false of the tree. What is the correct resolution, and does it
   generalize to any re-cut?

5. **Is the criteria set jointly satisfiable?** Consider AC1–AC6 together, not
   individually. AC4 forbids the milestone from "stating a rule" while AC2
   requires its records to state the predicate's limits, and AC5 requires every
   factual claim to carry a reproducing command while the work log is
   append-only. Identify any pair that cannot both hold, and say which should
   give way.

6. **What should happen to M100 now?** The options on the table are: a scoped
   fifth fix pass under revised criteria; parking the milestone; splitting the
   evidence artifacts from the records that describe them; or dropping it and
   re-planning the measurement from scratch. Recommend one, with reasoning, and
   state what would falsify your recommendation.

7. **Beyond the eight findings, is anything else in the shipped tooling
   overclaiming?** Examine the enumerator docstring, the ledger header, the sweep
   header, and the two `cairn/ROADMAP.md` candidate rows in the diff, and report
   any further claim the artifact does not support. This is a check on whether
   the enumerated list is complete.

## Constraints

Fixed; flag disagreement explicitly rather than silently working around it.

- **The measurement stands.** The sweep results are verified and are not being
  re-litigated. Do not propose re-running or re-designing the sweep except where
  question 1 or 6 makes it unavoidable, and say so explicitly if it does.
- **History is never edited.** `cairn/DECISIONS.md`, work logs, the milestone-local
  `## Decisions` section, and archived files record what was decided at a time and
  are superseded, never rewritten. Any proposal that requires editing one of them
  must say so explicitly and argue for the exception. This constraint is what
  makes question 4 hard; do not resolve it by assuming it away.
- **The split stands.** M100 ships measurement and tooling only; every message
  change belongs to M101 (`cairn/milestones/M101-degeneracy-message-claims.md`).
  Do not propose folding them back together without addressing why the re-cut's
  reasoning was wrong.
- **D-018** governs the runtime route — verifying a candidate method on the
  caller's own data at abort time. **D-019** governs evidence-based boundary
  endpoints. Neither is open for revision here; if a recommendation touches
  either, say which and why.
- The package must stay installable from the default branch at all times, and
  M100 must not change user-facing behaviour.

## Output format

In `RR04-record-overclaim-pattern.md`: answer each question by number with your
reasoning and evidence; list any additional findings separately under "Beyond the
brief"; end with concrete recommendations, each marked apply / consider /
reject-with-reason. Where findings bind implementation, also emit a
`## Binding criteria` section: numbered `BC1…`, each a measurable assertion
checkable against evidence, with any numeric projection stating its tolerance.
These are ingested VERBATIM into the constrained milestone's acceptance criteria
and mechanically diffed against this file; departures are legal only through that
milestone's shown "Deviations from RR04" table.
