# M101 (dropped): What a degeneracy message may assert, and the messages made to obey it

**Dropped 2026-08-03** at the `/milestone` audit gate, maintainer's disposition.
Never implemented — planned 2026-08-01 as M100's re-cut companion, no branch.

**Why.** Its deliverable was the rule and its apparatus: a `DECISIONS.md` entry
stating what a CI-reducer degeneracy message may assert, per-guard assertion
tables mapping each assertion to the condition entailing it, mutation-verified
per-assertion fixtures, and a self-history recompute rule. D-021 bars that class
absent a defect in what the package computes. The defect exists (M100's sweep),
but it is fixed by correcting four abort messages, not by erecting the rule that
governs them — so the messages go to a hotfix and the rule is dropped.

**What survives**, as the hotfix's whole content: drop the `montecarlo` name
where M100's sweep measured it unusable, name `bootstrap` at the `gen_ssa0` site
where it is usable 4/4, keep each abort's condition class and leading line, and
leave every message with something the user can act on. The two false diagnostic
bullets on `main` are in that scope.

**Dropped with it:** the may-assert D-entry, the per-guard assertion tables, the
disjunct-and-cause fixture matrix, and the records-recompute criteria (AC5/AC6).

**Spun out:** a candidate row for `burch_ci()`'s raw unclassed error on SSA = 0
data (out of the hotfix's scope); the runtime `boundary_method_hint()` candidate
is corrected in place on the ROADMAP — M100's sweep fired its falsifier.
