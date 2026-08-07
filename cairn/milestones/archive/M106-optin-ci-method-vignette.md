# M106: The opt-in `ci_method` values are documented in the vignettes

**Status:** done (2026-08-06, PR #114 https://github.com/jmgirard/intraclass/pull/114)

**Goal:** Document the four opt-in interval methods (`"npbootstrap"`, `"searle"`,
`"burch"`, `"mpl"`) in the vignettes, so users can choose one without `?icc`.

**Outcome:** `interval-methods.Rmd` gains an opt-in-methods section — npbootstrap,
the shared classical searle/burch pair (gated AC1 amendment), and mpl — each
stating fence, determinism, `conf_level` set, `unit` behavior, and
when-over-default, with two live chunks (`ratings` one-way trio at
`seed = 1, boot_samples = 199`; a `set.seed(88)` simulated 20×4 two-way for mpl,
which no shipped dataset serves). Four glossary entries with verified anchors; a
NEWS Documentation entry. `check-mpl-doc-claims.py` now sweeps the vignette MPL
subsection via one `build_scopes()` shared by the live check, self-test, and
`--list` (the stale `scopes0` duplicate is gone); 4 `out` ledger rows + 1 refusal
row; 41 candidates, 0 failures, self-test green.

**Decisions:** none.

**Review:** 12 findings, 4 actioned and fixed (F1 92 false unbalanced-exclusivity
claim; F4 88 glossary Burch citation vs `references/burch2011.md`; F5 83 "two
default methods" mislabel; F2 82 "wider" contradicted by the article's own table);
two defect returns + one AC1 amendment return; F3/F4's roxygen siblings →
candidate row, F9's "any"-token miss noted on the hardening row.
