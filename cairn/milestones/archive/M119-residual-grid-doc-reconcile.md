# M119: Reconcile the shipped width claims with M118's third grid

**Status:** done (2026-08-14, PR #128 https://github.com/jmgirard/intraclass/pull/128)

**Goal:** Restate every shipped claim that no measured grid varies the residual, which M118 falsifies, to what the three grids now jointly measure.

**Outcome:** Six source statements plus their `man/icc.Rd` mirrors carried the falsified bound; a standing walk in `test-doc-skew-caveat.R` (`residual_hits` on grid-plus-residual vocabulary, runs filtered to those naming Burch, per-surface floors in `residual_expected_runs`) enumerates them instead of any recorded list. Each now carries `residual_template()` verbatim: the two subject-effect-only grids put `"burch"` narrower nearly everywhere, while the third puts it wider at every symmetric heavy-tailed family measured (median ratio 1.2963 at t(5), k=100) and narrower at every lighter-tailed one. New pins: the `ratio_family` canonical shape against the M118 fixture cell, `n_grids` extended to "three", `residual_scope_violations` requiring a verbatim scope clause beside any grid-pair mention, and a per-family direction test recomputed from the fig2 block. The M117 mutation harness gained a second mutated surface (`?icc` roxygen) and eight break forms. Nothing `"searle"` or `"burch"` computes changed; D-027's preference is untouched.

**Decisions:** none milestone-local. The M118 verdict it executes is D-030; `D-029`'s extend-not-duplicate precedent decided the instrument.

**Review:** Three-lens fan-out + scorer: 16 findings, 3 actioned (D4 82, D7 80, D13 80), 13 below the bar. All three were prose defects this milestone introduced — a figure restated against `ci-classical.R`'s own prohibition, an `?icc` pointer promising tables the article does not carry, and a duplicated lead-in orphaning a pronoun in NEWS — fixed on the branch and re-verified. The blame lens's headline finding (four dead withdrawn-claim patterns) was refuted by re-measuring against whitespace-squashed surfaces, which is what the instrument matches. Final: installed-surface suite 7788 passing, 0 skips; `cairn_validate` clean; CI green on all seven checks.
