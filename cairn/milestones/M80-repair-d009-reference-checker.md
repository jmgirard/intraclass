# M80: Repair the D-009 reference-observation checker — exclude the M74 triage ledger + wire into CI

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3
- **Branch/PR:** m80-repair-d009-reference-checker · https://github.com/jmgirard/intraclass/pull/87

## Goal

Make `data-raw/check-reference-observations.py` exit 0 again by excluding the
M74 triage ledger from the 22 stale directives, and wire it into CI so it can
never silently sit red on main.

## Scope

**In:**
- Narrow the 22 falsified `check:` directives (11 off-shelf notes × 2 —
  bhandary2006, bobak2018, donner2002, konishi1989, mehta2018, naik2007,
  saha2005, saha2012, xiao2009, xiao2013, young1998) by appending
  `':(exclude)data-raw/generalizing-claims-triage.tsv'` to each; all other
  tokens/paths unchanged (D-009 rule 1: per-claim scope).
- Where a note's adjacent prose enumerates the grep scope or asserts a
  `data-raw` result, name the ledger exclusion so prose matches the directive
  (M68: never silence by rewording).
- Add an R-free `check-references` job to `.github/workflows/lint.yaml` running
  the checker + its `--self-test`, on push/PR.

**Out:**
- Wiring `enumerate-generalizing-claims.py --check` (M74) into CI → candidate
  row (its own triage-currency semantics).
- Editing the ledger or M74's triage rows; re-verifying any source's
  `Extraction:` provenance status (D-009 rule 3 exempts those lines).

## Acceptance criteria

- [x] AC1 — `python3 data-raw/check-reference-observations.py` exits 0 with 0
      falsified and 0 unmarked; the 22 directives each hold via the
      ledger-exclusion pathspec. Evidence: checker output.
- [x] AC2 — Directive-scope faithfulness: every note whose prose enumerates the
      grep scope or asserts a `data-raw` result names the ledger exclusion, so
      prose == directive (M68/D-009). Evidence: diff of the 11 notes.
- [x] AC3 — The checker's registered vacuity guard is intact:
      `--self-test` exits 0. Evidence: self-test run.
- [x] AC4 — The checker runs in CI on push/PR as an R-free `check-references`
      job that fails on any falsified or unmarked observation; the PR's own run
      is green and the job sets up no R. Evidence: PR CI run.
- [x] AC5 — No R source, oracle value, committed fixture, or `Extraction:`
      status changed — only `check:` directives, adjacent prose, and CI config.
      Evidence: PR diff scope.

## Coverage

- AC1 → T1, T3
- AC2 → T1, T2
- AC3 → T3
- AC4 → T4
- AC5 → T1, T2, T4, T5

## Tasks

- [x] T1 — Append `':(exclude)data-raw/generalizing-claims-triage.tsv'` to each
      of the 22 falsified directives across the 11 notes; leave existing
      tokens/paths and the `-qiF`/`-qiE` mode as-is.
- [x] T2 — In each note whose prose enumerates the grep scope or asserts a
      `data-raw` result, add a short parenthetical that the M74 triage ledger is
      excluded as bookkeeping (not a package reference).
- [x] T3 — Run the checker (exit 0, 0 falsified/0 unmarked) and `--self-test`
      (exit 0); record both.
- [x] T4 — Add an R-free `check-references` job to `lint.yaml` (checkout +
      checker + `--self-test`); confirm green on the PR run, no R setup.
- [x] T5 — Scope-diff check: only directives, adjacent prose, and `lint.yaml`
      changed — no R source, oracle, fixture, or `Extraction:` line touched.

## Work log

- 2026-07-21: created by /milestone-plan. Diagnosis: all 22 falsifications come
  from the M74 ledger being the sole `data-raw` match for each off-shelf
  citekey; excluding it, every claim holds (verified). Lineage: M74 (ledger) →
  M79 T5 (discovered) → D-009. Gate: exclude-ledger form (preserves asserted
  scope, honest prose) + wire checker into CI (M79 lesson root cause).
- 2026-07-21: T1–T3 — appended the `:(exclude)` ledger pathspec to all 22
  directives (11 notes × 2) and qualified each note's `data-raw/` enumeration
  with the exclusion. Checker exits 0 (0 falsified, 0 unmarked); `--self-test`
  exits 0.
- 2026-07-21: T4 — added an R-free `check-references` job to `lint.yaml`
  (checkout + checker + `--self-test`), push/PR-triggered, no R setup;
  actionlint clean, both commands pass locally. Live green is review evidence
  once the PR exists. T5 — branch scope-diff confirms only the 11 notes' `check:`
  directives + `data-raw` enumerations and `lint.yaml` changed; no R source,
  fixture, oracle value, or `Extraction:` line touched.

## Decisions

## Review

**PR:** #87 (draft). **Evidence gathered 2026-07-21 on branch HEAD.**

- AC1 — `check-reference-observations.py`: 63 in-scope observations, 49 runnable
  directives, 14 `check: none`, **0 unmarked, 0 falsified, exit 0**; 22
  ledger-exclusion directives present (11 notes × 2). PASS.
- AC2 — all 11 notes carry the ledger-exclusion note in the prose adjoining
  their `data-raw/` enumeration (verified multiline; prose == directive). PASS.
- AC3 — `--self-test` exits 0 ("checker distinguishes a holding claim from a
  falsified one"), vacuity guard intact. PASS.
- AC4 — the new R-free `check-references` job **passed on PR #87 in 5s**
  (no `setup-r` step); `format-check` also green. R-CMD-check matrix pending at
  review time — required green before merge. PASS (checker leg); CI matrix
  tracked to merge gate.
- AC5 — branch diffstat: only `.github/workflows/lint.yaml` (+15), the 11
  `cairn/references/*.md`, and tracking files. **Every changed file is under an
  Rbuildignored path** (`^\.github$`, `^cairn$`) → built package byte-identical.
  No R source, fixture, oracle value, or references-page `Extraction:` status
  touched (the lone `Extraction:` diff hit is this file's own AC5 wording). PASS.

**Consistency gate:** `cairn_validate` exit 0 (all checks pass; 333 non-gating
dangling-id-token advisories, long-standing). Toolchain gate (r-package): built
package unchanged (Rbuildignored-only diff), no roxygen/exports/NEWS-worthy
user-visible change → `document()`/pkgdown/NEWS checks trivially satisfied; the
PR's ubuntu+windows R-CMD-check confirms and is required green at merge.
`cairn_impact` skipped — GP3 is worked-under, not changed.

**Independent review (three lenses, fresh context):**
- [O] diff-bug (Opus): no findings. Confirmed the `:(exclude)` pathspec settles
  each claim without masking a genuine reference (ledger is the sole `data-raw`
  hit for every citekey), prose == directive, CI job R-free and exit-propagating.
- [S] blame-history (Sonnet): no findings. All 22 directives are M73-authored
  (D-009), untouched since; the exclusion is a scope bug-fix that preserves the
  original "nothing references it" intent, not a weakening; no M68/M70/M71/M72
  prose-drift resurrection; no D-011/M77/M78 CI conflict.
- [S] prior-review-record (Sonnet): no findings. Diff matches M79's recorded
  D-009-failure diagnosis; no regression of M68/M70/M71/M72/M73/M79 lessons;
  GitHub inline-comment probe returned `[]` (no thread walk).
Scorer not invoked — zero surviving findings to score.
