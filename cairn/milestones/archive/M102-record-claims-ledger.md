# M102: A registered claims ledger, and the CI checker that re-derives it

**Status:** done (2026-08-03, PR #109 https://github.com/jmgirard/intraclass/pull/109)

**Goal:** Commit a registered ledger of (claim, command, expected output) rows over tracking prose and a
CI checker that re-derives every row, so a transcribed figure that drifts from its artifact reds a check.

**Outcome:** `data-raw/record-claims.tsv` carries five rows over four figures — the `data-raw` checker
inventory, the `lint.yaml` invocation count (8), the three κ_m worst-downward-steps (−0.046/−0.068/−0.162),
the ROADMAP's five terminal rows in order. `data-raw/check-record-claims.py` is stdlib-only; its 11-column
grammar and its shape, refused-form and route lists PARSE OUT of its own docstring, so a statement and its
code cannot drift. Four shapes (`ls`/`grep`/`awk`/`python3`), every `git` command refused by one test on
`argv[0]`, 16 routes each probed and shown load-bearing by excising its own block, a citation gate whose
scope parses out of D-020 rule 4, a committed falsifier per `absence` row that must fail its expectation.

**Decisions:** D-020 + Amendments 1–4: refusal is one test, not a parse (1); rule 9's "a shell is
inexpressible" withdrawn as false rather than met (2); the checker's `D-045`/`IP4` named ids this repo never
defined (3); Amendment 3's own id count was wrong (4). D-021 (+Amdt 1): records-verification work needs a
trigger in what the package computes.

**Review:** Five passes, four defect returns and one amendment return. AC2 failed 1–4 by four channels —
missed ref spellings, a `--` belonging to `-e`, an `awk` shell escape, a missing disclaimer — establishing that
a rule over what a command NAMES cannot guarantee what it DOES; the guarantee was withdrawn, not met. Pass 5:
24 findings, none ≥80, two lenses zero; the highest (78) was a false sentence this milestone itself authored.
