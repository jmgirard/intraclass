# M135: Vignette prose pass — the method articles

**Status:** done (2026-08-24, PR #144 https://github.com/jmgirard/intraclass/pull/144)

**Goal:** Apply M134's style rules to the five method articles, the ones whose prose is watched by five separate guards, without moving any pinned claim.

**Outcome:** `engines.Rmd`, `comparison-with-other-packages.Rmd`, `d-studies-and-replicates.Rmd`, `multilevel-designs.Rmd` and `interval-methods.Rmd` rewritten against R1–R6 of `cairn/doctrine/prose-style.md`. Ruler at merge 68/0/0, 75/0/0, 92/0/0, 127/0/0, 164/1/0: every dash count 0, one exempt over-35 sentence at `interval-methods.Rmd:217-224` carrying the 58-word clause `residual_template()` pins with `fixed = TRUE`. The capability matrix's 11 "not provided" cells became the word `no`. Guard surface moved with the prose: four `mpl-doc-claims.tsv` re-keys plus a new row `0e83d1125bf2` for the MPL near-zero-boundary claim (checker 47 -> 48 candidates), and two `m117-width-pin-mutations.R` anchors re-pointed across a split sentence. NEWS Documentation bullet added; ROADMAP's terminal-row comment and `record-claims.tsv`'s `roadmap-terminal-rows` row corrected, both left false by M134's archive pass.

**Decisions:** none cross-cutting. Two maintainer calls at mini gates: the matrix cells take `no` rather than `❌`; AC1 exempts one pinned over-length sentence.

**Review:** two passes, full three-lens fan-out each. Pass 1 returned the milestone (consistency gate, missing NEWS entry), six fix-now findings, plus an AC2 amendment return narrowing AC2 to what its census mechanically settles. Pass 2: five criteria green on fresh evidence, gate clean, 12 findings — one fixed (the two MPL reporting caveats disambiguated with "separately", ledger re-keyed `d78ce12088ef` -> `c3bbfdcb4994`), two recorded, nine rejected. Blame and prior-review lenses zero regressions. Nothing retired or graduated.
