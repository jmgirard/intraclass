# M80: Repair the D-009 reference-observation checker — exclude the M74 triage ledger + wire into CI

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3
- **Branch/PR:** —

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

- [ ] AC1 — `python3 data-raw/check-reference-observations.py` exits 0 with 0
      falsified and 0 unmarked; the 22 directives each hold via the
      ledger-exclusion pathspec. Evidence: checker output.
- [ ] AC2 — Directive-scope faithfulness: every note whose prose enumerates the
      grep scope or asserts a `data-raw` result names the ledger exclusion, so
      prose == directive (M68/D-009). Evidence: diff of the 11 notes.
- [ ] AC3 — The checker's registered vacuity guard is intact:
      `--self-test` exits 0. Evidence: self-test run.
- [ ] AC4 — The checker runs in CI on push/PR as an R-free `check-references`
      job that fails on any falsified or unmarked observation; the PR's own run
      is green and the job sets up no R. Evidence: PR CI run.
- [ ] AC5 — No R source, oracle value, committed fixture, or `Extraction:`
      status changed — only `check:` directives, adjacent prose, and CI config.
      Evidence: PR diff scope.

## Coverage

- AC1 → T1, T3
- AC2 → T1, T2
- AC3 → T3
- AC4 → T4
- AC5 → T1, T2, T4, T5

## Tasks

- [ ] T1 — Append `':(exclude)data-raw/generalizing-claims-triage.tsv'` to each
      of the 22 falsified directives across the 11 notes; leave existing
      tokens/paths and the `-qiF`/`-qiE` mode as-is.
- [ ] T2 — In each note whose prose enumerates the grep scope or asserts a
      `data-raw` result, add a short parenthetical that the M74 triage ledger is
      excluded as bookkeeping (not a package reference).
- [ ] T3 — Run the checker (exit 0, 0 falsified/0 unmarked) and `--self-test`
      (exit 0); record both.
- [ ] T4 — Add an R-free `check-references` job to `lint.yaml` (checkout +
      checker + `--self-test`); confirm green on the PR run, no R setup.
- [ ] T5 — Scope-diff check: only directives, adjacent prose, and `lint.yaml`
      changed — no R source, oracle, fixture, or `Extraction:` line touched.

## Work log

- 2026-07-21: created by /milestone-plan. Diagnosis: all 22 falsifications come
  from the M74 ledger being the sole `data-raw` match for each off-shelf
  citekey; excluding it, every claim holds (verified). Lineage: M74 (ledger) →
  M79 T5 (discovered) → D-009. Gate: exclude-ledger form (preserves asserted
  scope, honest prose) + wire checker into CI (M79 lesson root cause).

## Decisions

## Review
