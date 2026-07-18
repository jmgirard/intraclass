# M63: References migration — ORACLES.md + BIBLIOGRAPHY.md, citekey reconciliation

**Status:** done (2026-07-18) · **PR:** https://github.com/jmgirard/intraclass/pull/69

**Goal.** Convert `cairn/references/` to the cairn file family — declared oracle
registry, bibliography, reconciled citekeys — changing no oracle value.
**Outcome.** `REFERENCES.md` (1346 ln) → `ORACLES.md` (39-entry registry) +
`BIBLIOGRAPHY.md` (16), bodies byte-identical to the original (39→39 oracles,
16→16 items, 14→14 `Status:` lines); a 6-line stub retained so links from the
entombed `legacy/` / kickoff / `data-raw/reviews/` docs still resolve.
`DESIGN.md` Conventions gained the validation-doctrine **registry pointer**,
closing the "no cairn-canonical oracle-registry home" issue (repo side; upstream
cairn D-024 stays open). 12 cross-references retargeted; `INDEX.md` rebuilt with
a 30-PDF shelf inventory tagged by ingesting milestone (M64–M67).

**Key decisions.** **D-007** — `ORACLES.md` is the declared registry home; split
by *kind*, NOT a per-citekey shred (entries keyed by oracle ID, tests cite those
IDs, many span several sources — sharding breaks the ≥2-types audit). Duplicate
author-years take a letter suffix by issue. Also covers `PRINCIPLES.md` #12.

**Review.** AC5 **failed** first pass: implement miscounted the shelf at 29 PDFs
and recorded `jorgensen2021.pdf` (the O-SEM source) as missing — it was present.
Caught by the diff-bug lens (93); AC5 amended via gate, phantom ROADMAP blocker
dropped, M64 unblocked 9→10. F3/F5 actioned on request; F2/F4 logged. Gate:
`cairn_validate` PASS · `check(--as-cran)` 0/0/0 · 1802 pass/0 fail · CI 11/11.
