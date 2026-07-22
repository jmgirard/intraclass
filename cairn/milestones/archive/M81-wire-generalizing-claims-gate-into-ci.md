# M81: Wire the M74 generalizing-claim completeness gate into CI + harden its vacuity

**Status:** done (2026-07-21, PR #88 https://github.com/jmgirard/intraclass/pull/88)

**Goal:** Make `enumerate-generalizing-claims.py --check` run in CI so an un-triaged generalizing claim on a references page can never sit red on main unnoticed.

**Outcome:** Two steps added to M80's R-free `check-references` job in `.github/workflows/lint.yaml` — `enumerate-generalizing-claims.py --check` (enumeration-completeness gate) and `--self-test` (vacuity guard); job comment broadened to D-009 + M74. In the script, the completeness set-diff was factored into `completeness_diff()` and `self_test()` extended to assert the gate reds on an un-triaged candidate and an orphan ledger row — mutation-proven (sabotaging the diff fails `--self-test`). Gates completeness only, never claim truth (D-009 fence). R build byte-identical (`data-raw/` + `.github/` Rbuildignored).

**Decisions:** none (implements D-009; job-structure and vacuity-hardening chosen at the plan gate).

**Review:** 6/6 ACs verified with fresh evidence (incl. AC4 mutation proof); consistency gate clean; three fresh-context lenses zero findings. Retired the "not wired into CI" clause from the M76 lesson and the M79 lesson's aside (the gate M81 shipped now catches that mistake in CI).
