# M80: Repair the D-009 reference-observation checker — exclude the M74 triage ledger + wire into CI

**Status:** done (2026-07-21, PR #87 https://github.com/jmgirard/intraclass/pull/87)

**Goal:** Make `data-raw/check-reference-observations.py` exit 0 again by excluding the M74 triage ledger from the 22 stale directives, and wire it into CI so it can never silently sit red on main.

**Outcome:** All 22 `check:` directives across 11 off-shelf source notes (bhandary2006, bobak2018, donner2002, konishi1989, mehta2018, naik2007, saha2005, saha2012, xiao2009, xiao2013, young1998) now carry `':(exclude)data-raw/generalizing-claims-triage.tsv'`, with each note's `data-raw/` prose enumeration qualified to match (bookkeeping, not a package reference). The checker returns to exit 0 (0 falsified, 0 unmarked); `--self-test` intact. A new R-free `check-references` job in `.github/workflows/lint.yaml` runs the checker + `--self-test` on push/PR. Built R package byte-identical (only Rbuildignored paths changed).

**Decisions:** none (implements D-009; exclude-ledger form chosen over narrowing `data-raw/*.R` to preserve the claim's asserted scope).

**Review:** three fresh-context lenses (diff-bug [O], blame-history [S], prior-review-record [S]) — zero findings; scorer not invoked. All 5 acceptance criteria verified with fresh evidence; consistency gate clean; full CI matrix green. Retired the M79 lesson's "check-reference-observations.py not in CI" clause (now guarded).
