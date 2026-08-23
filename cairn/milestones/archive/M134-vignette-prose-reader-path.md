# M134: Vignette prose pass — the reader path, and the house style standard

**Status:** done (2026-08-23, PR #143 https://github.com/jmgirard/intraclass/pull/143)

**Goal:** Rewrite the three reader-path articles so no sentence runs past 35 words and no dash stands in for punctuation, and write down the style rules applied.

**Outcome:** `getting-started.Rmd`, `choosing-an-icc.Rmd` and `glossary.Rmd` now
report 0 dash-as-punctuation occurrences each (66 at `72f9cc2`) and 0 / 0 / 1
sentences over 35 words (20 at baseline); the residue is one 64-word glossary
sentence carrying the 58-word clause `residual_template()` pins, which admits no
split. New `cairn/doctrine/prose-style.md` states R1–R6, the ruler's prose
boundary, its six blind spots, and the frozen-ruler rule; new
`data-raw/prose-profile.py` measures them, by hand, wired to no CI job (D-021).

**Decisions:** the glossary keeps one over-35-word sentence rather than relaxing
`test-doc-skew-caveat.R`'s `fixed = TRUE` match (milestone-local). Cross-cutting:
**D-034** — `cairn/doctrine/` also admits a directly-authored standard.

**Review:** four passes, full three-lens fan-out each. Two defect and two
amendment returns, all on AC1's "counted class as the doctrine defines it", each
by a new clause of R1's exclusion list; pass 4 hit the amendment-return
second-occurrence stop and the maintainer accepted the residual gap (pandoc
simple/grid separator rows score dashes, unreachable here). Fixed at the gate:
the blind-spot count to six, a long line, a falsified `data-raw/README.md`
sentence; `RE_DASH`'s dash runs and AC1's shape go to a candidate row.