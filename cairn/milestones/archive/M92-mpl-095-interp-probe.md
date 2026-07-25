# M92: Off-node S coverage probe for `ci_method = "mpl"` at the shipped `conf_level = 0.95`

**Status:** done (2026-07-25, PR #99 https://github.com/jmgirard/intraclass/pull/99)

**Goal:** give `mpl_kappa_lookup()`'s linear-in-S interpolation coverage evidence at the DEFAULT `conf_level = 0.95`, the one level where every cell ever swept sat on an `s_grid` node.

**Outcome:** three cells frozen pre-run (GP5) in § M92 of `mpl-twoway-random-comparison.md` — E1
(R=3,S=25), E2 (R=10,S=40, across 0.95's worst dip −0.068), E3 (R=2,S=40, a large-κ_m concave
bracket), all δ=4, ρ=0.60, floor ≥0.93, `n_rep` 1000 — each cleared under the shipped linear rule
(0.967 / 0.944 / 0.999), so the pre-registered bracket-max consequence did NOT fire and
`mpl_kappa_lookup` is unchanged: zero non-comment `R/` lines, no user-visible change. New:
`data-raw/m92-mpl-095-interp-sweep.R` (role-vs-geometry and M91-seed-disjointness `stopifnot`s,
`M92_RULE=linear|bracketmax`), both run fixtures, and a `test-ci-mpl.R` pin of the three validated
constants plus a non-midpoint S=22 pin discriminating any bracket-symmetric rule. Exported docs → M94.

**Decisions:** none promoted. Local: bracket-max over M91's node-restriction as the 0.95 shortfall
consequence, since restricting the shipped default would break working calls; AC5 re-amended twice, to
forbid summarizing the review record, a deleted passage, another file's contents, or its own claims.

**Review:** seven passes; 1–6 each failed AC5 on prose authored about the work, never on the
measurement, code or fixtures — F1 (87) a seed collision falsifying independence, F-A/F-B/F-C stale
figures, P3-1 a false corpus negative, P5-1 a relocated conclusion, P6-1 (92) a false enforcement claim
(mutation: 152 of 162 κ_m cells red nothing). Pass 3 hit the thrash rule → re-cut, exported surface to
M94; pass 5's merge was withdrawn on a post-hoc lens report. Pass 7: zero findings from three lenses,
three advisories unactioned; two candidate rows carried out; lessons captured, none retired.
