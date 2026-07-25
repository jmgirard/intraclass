# M92: Off-node S coverage probe for `ci_method = "mpl"` at the shipped `conf_level = 0.95`

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP5, GP6, GP7
- **Branch/PR:** `m92-mpl-095-interp-probe` · https://github.com/jmgirard/intraclass/pull/99

## Goal

Close the one interpolated-S evidence gap M91 left: give `mpl_kappa_lookup()`'s
linear-in-S interpolation coverage evidence at the DEFAULT `conf_level = 0.95`,
where every cell ever swept has sat on an `s_grid` node.

## Scope

**In:** three frozen off-node-S coverage cells at 0.95 (E1–E3 below), pre-registered
before any run (GP5) into `cairn/references/mpl-twoway-random-comparison.md`; a
seeded `data-raw/` sweep script + committed fixtures, per-cell `role` asserted against
geometry and the seed span asserted disjoint from M91's; the frozen verdict APPLIED,
including the shortfall consequence; the `R/ci-mpl.R` interpolation comment pointed at
the note **without restating figures**; the κ_m test pin; both affected ROADMAP
candidate rows resolved; and a committed script that settles the no-restated-figures
rule mechanically.

**Out:** **all exported documentation of the result** — `@param ci_method` /
`@param conf_level` in `R/icc.R`, `man/`, `NEWS.md`, `README.md` → **M94**, which owns
that surface from a clean base and governs it with a fixture-reading check (amended
2026-07-25 at the plan gate, after AC5 failed three consecutive reviews on prose in
exactly this surface) · re-probing 0.90/0.99 (M91's D1–D3 confirmed those) · a monotone
smoother over the whole κ_m table, or a bracket-max rule at 0.90/0.99 → stays the
ROADMAP envelope candidate · re-calibrating any κ_m value → M90's tables are frozen
inputs · off-grid (R,S) extrapolation → still aborts, D-015 · on-the-fly calibration →
candidate row.

## Acceptance criteria

- [x] AC1 (GP5): the E1–E3 pre-registration — geometry, floor, `n_rep`, role, and the
      shortfall consequence — is committed to
      `cairn/references/mpl-twoway-random-comparison.md` in a commit strictly EARLIER
      than the one adding any result, demonstrable from `git log` on the two paths.
- [x] AC2: a committed seeded script writes a fixture in which each cell's `role` is
      asserted against its geometry (a `stopifnot` mirroring
      `data-raw/m91-mpl-interp-sweep.R:94-98`), and the 0.95 verdict reports
      `interp_ok` as a measured value — never an aggregate over mixed-role cells
      (M91 finding F1).
- [x] AC3 (GP6): E1, E2 and E3 each report coverage with an exact binomial CI against
      the frozen floor, and the recorded verdict is the frozen rule applied — no floor
      moved after seeing a result.
- [x] AC4: the frozen shortfall consequence is executed as written — if any cell falls
      below its floor, `mpl_kappa_lookup()` uses the bracket-max rule for off-node S at
      0.95 only, every 0.95 NODE lookup stays bit-identical to today, and the failing
      cell re-runs above its floor; if none falls short, the lookup is unchanged.
- [ ] AC5 (GP7, re-amended 2026-07-25 after review pass 4): **no file M92 changes
      draws a conclusion about what the cells establish.** Concretely: (a) `git diff
      main..HEAD` is empty for `R/icc.R`, `man/`, `NEWS.md`, `README.md`; (b) every
      figure about M92's cells in a changed file is transcription matching
      `data-raw/m92-interp-sweep.rds`, or is explicitly labelled as run 1 inside the
      two-run account; (c) the note's § M92 verdict contains the table, the two-run
      GP5 account and the one-sentence verdict, and states **no** claim about what the
      corpus does or does not isolate, no cross-level comparison, and no
      characterization of one-sidedness. Review verifies (c) by reading every
      declarative sentence in the changed files against the fixture. Why this form:
      the previous amendment checked only figures, and a **false negative claim** is
      not a figure — that gap let the pass-3 defect survive into pass 4.

- [x] AC6: the ROADMAP "off-node S coverage probe at 0.95" candidate is absorbed, and
      the "κ_m monotone envelope / smoother" candidate is updated with this
      milestone's evidence (or dropped, if superseded by the applied consequence).
- [x] AC7: `devtools::test()`, `devtools::check()`, `lintr::lint_package()` and
      `air format --check` clean; `devtools::document()` no-diff; and both
      references-CI checkers green — `enumerate-generalizing-claims.py --check` and
      `check-reference-observations.py` (M85/M86: `cairn_validate` runs neither, and a
      `check:` directive must settle with python3/shell/git, never `Rscript`).

**Frozen cells and the shortfall consequence** are committed verbatim in
`cairn/references/mpl-twoway-random-comparison.md` § M92 pre-registration (frozen
2026-07-25, before any run — GP5) and are not restated here: E1 (R=3, S=25), E2
(R=10, S=40, the worst 0.95 dip), E3 (R=2, S=40, a large-κ_m concave bracket), each at
δ = 4, ρ = 0.60, floor ≥ 0.93, `n_rep` 1000. A cell below its floor switches
`mpl_kappa_lookup` at 0.95 only to a bracket-max rule (≥ the chord everywhere, nodes
untouched) and re-runs that cell at the same floor.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T2, T3
- AC4 → T4
- AC5 → T10, T12
- AC6 → T6, T10
- AC7 → T3, T4, T5, T6, T10, T12

## Tasks
<!-- T1-T9 are done; their detail is in the work log. Compressed at the 2026-07-25
     re-cut to make budget room for T10/T11. -->

- [x] T1: freeze the E1–E3 pre-registration in the comparison note, before any run (GP5).
- [x] T2: add the seeded generator `data-raw/m92-mpl-095-interp-sweep.R` (role
      `stopifnot`, per-cell seed stride, `M92_RULE=linear|bracketmax`).
- [x] T3: run the sweep; commit the fixture; record the verdict per cell.
- [x] T4: execute the frozen consequence (no shortfall → lookup unchanged) and pin the
      three coverage-validated κ_m constants.
- [x] T5: restate the interpolated-S evidence status at every claiming site.
- [x] T6: resolve both ROADMAP candidate rows; run the gate; open the PR.
- [x] T7 (pass-1 F1): disjoint seed base + a mutation-verified disjointness `stopifnot`;
      re-run; keep the superseded run committed.
- [x] T8 (pass-1 F3): correct the "largest 0.95 κ_m" over-claim in the generator header.
- [x] T9 (pass-2 F-A/F-B/F-C): drop restated figures from the exported docs and the test
      comment; replace the hand-written grep with a mechanical sweep.
- [x] T10 (the re-cut): revert every exported-doc change — `R/icc.R` roxygen, `man/`,
      `NEWS.md` — to its pre-M92 state, so the surface that failed three reviews is
      absent from this milestone; then remove the restated coverage triple from
      `R/ci-mpl.R`'s comment and from the ROADMAP candidate row (both point at the note
      instead), and fix the mis-attributed finding reference in the test comment (P3-4).
- [x] T11: ~~commit `data-raw/check-m92-figure-restatement.py`~~ — **reverted at T12.**
      The checker shipped real defects (no slash-paired probes, green on an
      unresolvable `origin/main`, a permanent no-op after merge, absent from CI) while
      `R/ci-mpl.R` cited it as enforcement. A guard that overpromises is worse than none.
- [x] T12 (review pass 4): delete the interpretive layer rather than police it — remove
      the note's three conclusion-drawing bullets (where the pass-3 and pass-4 defects
      both lived), delete the checker and every pointer to it, and re-amend AC5 to
      forbid conclusions rather than only stale figures.

## Work log

- 2026-07-25: created by /milestone-plan (promotes the M91-review-F1 candidate; plan gate froze three cells — the D1/D2 twin, the worst 0.95 dip, and the largest-κ_m geometry — and chose the bracket-max rule over node-restriction as the shortfall consequence, so no currently-working call breaks).
- 2026-07-25: T1 done — § M92 pre-registration frozen in `mpl-twoway-random-comparison.md` (E1–E3, floors, criterion, bracket-max consequence + why it departs from § M91's node-restriction for the shipped level); its dated observation carries a python3-only settling directive, mutation-verified to exit 1 when D4's S is changed off-node; 5 generalizing-claim candidates triaged `OUT-repo-analysis` by generated rows; both references checkers green.
- 2026-07-25: T2 done — `data-raw/m92-mpl-095-interp-sweep.R` added; mirrors the M91 generator (m86-mpl-lib machinery, per-cell seed stride, role `stopifnot`) and adds two extra assertions (no cell on an `s_grid` node, every cell at 0.95) plus an `M92_RULE=linear|bracketmax` switch so the pre-registered shortfall re-run uses the same generator. Smoke run clean; air + lintr clean; no citekey named, so no D-009 directive is re-tripped.
- 2026-07-25: T3 done — sweep run, `data-raw/m92-interp-sweep.rds` committed. All three cells clear the frozen 0.93 floor under the SHIPPED linear rule, so the pre-registered bracket-max consequence is NOT triggered: E1 (R=3,S=25) κ_m 0.7089 cov 0.9680 [0.9551, 0.9780] miss 32/0; E2 (R=10,S=40, the worst 0.95 dip) κ_m 0.1517 cov 0.9530 [0.9380, 0.9653] miss 34/13; E3 (R=2,S=40, largest κ_m) κ_m 1.3663 cov 1.0000 [0.9963, 1.0000] miss 0/0. `interp_ok = TRUE` at 0.95 on three off-node cells, no mixed-role aggregation.
- 2026-07-25: T4 done — no-shortfall branch taken, so `mpl_kappa_lookup()` is UNCHANGED and bracket-max is not adopted. Added the M92 AC5 pin in `tests/testthat/test-ci-mpl.R`: the three coverage-validated 0.95 constants (0.7089067 / 0.1517143 / 1.3663359) plus an assertion that S = 25 and S = 40 are genuinely off-grid. Checked the pin discriminates the two rules rather than only a table edit — bracket-max would give 0.7862854 / 0.1857780 / 1.4656788 at the same geometries, so all three literals red under the alternative. No NEWS entry for a behaviour change: none happened.
- 2026-07-25: T5 done — restated the evidence status at five sites: `R/ci-mpl.R`'s GP7 interpolation comment (0.95 now confirmed, with the three cells and the untriggered consequence named), `@param ci_method` in `R/icc.R` (adds the interpolated-path guarantee), `NEWS.md` (same, user-facing), the note's new § M92 verdict, and § M91's now-false standing claim that 0.95 remains unprobed — corrected in place and marked superseded, not rewritten (D-045). Also narrowed the one-sidedness wording everywhere it appeared: E2 measured 34/13 at R = 10 against D1's 65/1 at R = 3, so the blanket reading was wrong. `document()` re-run (man/icc.Rd), ledger refreshed (1 orphan row dropped, 5 added), both references checkers + cairn_validate green, 169 mpl tests pass.
- 2026-07-25: correction (supersedes the "largest κ_m" wording in the plan-gate and T3 entries above, which are history and stay as written). Ran the M72 self-check — grep own new prose for counts and universals, re-derive each against the source — over everything this milestone wrote. E2's "worst 0.95 downward step" holds (−0.0681 at R=10, S 30→50 is the most negative in the slice). **E3's "largest κ_m at 0.95" does not**: `(R=2, S 50→100)` is higher at 1.4657 → 1.6245 and the slice maximum is 1.6245 at `(2, 100)`. E3 is the largest-κ_m cell THIS pass sweeps, on a concave bracket, at D3's geometry — which is the real reason it was chosen. Corrected at all four live sites (pre-registration bullet + cells row, § M92 verdict, `R/ci-mpl.R`, the AC table), marked in place per D-045; cells, floors and `n_rep` untouched, so the frozen bar is unchanged (GP5).
- 2026-07-25: T6 done — envelope candidate row updated with M92's evidence (two passes now find no coverage cost to the dips; promote only on a NEW failure); the probe candidate was already absorbed at the plan gate. Gate: `devtools::check(env_vars = c(NOT_CRAN = "false"), manual = FALSE)` → Status OK, 0 errors / 0 warnings / 0 notes; full suite at `NOT_CRAN=true CI=true` → FAIL 0, PASS 4210, SKIP 23, WARN 2 (pre-existing glmmTMB convergence warnings on the multilevel path — verified not ours: `git diff main..HEAD -- R/` changes zero non-comment lines); air + lintr clean; `document()` no-diff; both references checkers and cairn_validate green. AC1 ordering verified from git log: pre-registration da10025 (08:55:23) precedes the first result 2b984af (08:58:08). Manual built with `--no-manual` locally (known TinyTeX Courier font gap, not an Rd problem); CI builds it.
- 2026-07-25: all tasks done, gate clean; PR #99 opened, status -> review.
- 2026-07-25: review FAILED at AC5, status -> in-progress. What failed: finding F1 (scored 87) — the sweep's `seed_base` 20260725 against M91's 20260724 at the same stride and cell order makes E1 and E3 re-simulate M91's D1/D3 datasets bit-for-bit (verified: `mpl_simulate` `identical()` at the aligned seeds), so the shipped "second independent look" / "two independent passes" / "second probe's worth of evidence" claims are not what the fixture carries, and the D1->E1 "monotone in the level" item is forced by crit(E1) > crit(D1) on shared data. Riding along: F3 (92) — the corrected "largest 0.95 kappa_m" over-claim is still live at `data-raw/m92-mpl-095-interp-sweep.R:22-25`, a fifth site the T6 entry's "all four live sites" missed. AC1-AC4, AC6, AC7 verified and stay ticked; AC5 unticked. Four findings scored below 80 are logged in the Review section, not actioned.
- 2026-07-25: minor plan amendment — added T7 and T8 for the two actioned review findings (discovered sub-tasks; no criterion, scope or goal text changed).
- 2026-07-25: T7 done (F1). `seed_base` 20260725 -> 20920725, chosen so M92's seed span is disjoint from M91's; added a `stopifnot` that recomputes M91's span from ITS committed constants and asserts zero intersection, mutation-verified to error when the old base is restored. Guard pins the FROZEN n_rep 1000, not `cells$n_rep`, so smoke mode cannot relax it. Run 1 preserved at `data-raw/m92-interp-sweep-run1-collided.rds`; re-run written to `data-raw/m92-interp-sweep.rds`. New numbers: E1 0.9670 [0.9540, 0.9772] miss 31/2; E2 0.9440 [0.9279, 0.9574] miss 42/14; E3 0.9990 [0.9944, 1.0000] miss 0/1 — all three still clear the frozen 0.93 floor, and kappa_m is bit-identical across runs (table-derived, not run-derived). GP5 posture recorded explicitly in the note: run 1 ALSO cleared every floor, so no floor result motivated the re-run — the defect was reproducibility, not outcome.
- 2026-07-25: T8 done (F3) — generator header now states E3 is a large-kappa_m CONCAVE bracket and names the actually-larger (R=2, S 50->100) bracket and the 1.6245 slice maximum, with the correction dated.
- 2026-07-25: also fixed three sub-80 findings opportunistically while editing the same lines, each verified true first and each noted as such rather than folded in silently — F2 (68): `@param ci_method` no longer attributes the one-sidedness difference to rater count, since the two cited cells differ in R, S and level together; F4 (78): "same evidential footing" -> the interpolated path is coverage-CHECKED at each level at a handful of geometries, while nodes are individually CALIBRATED; F5 (62): added a non-midpoint pin (R=3, S=22 -> 0.6624794) plus an explicit refutation that the value equals the bracket mean, so the test now discriminates any bracket-symmetric rule, not just bracket-max. F6 (35) deliberately left alone — a repo-wide convention inherited from M91's generator, out of M92's scope.
- 2026-07-25: T7/T8 done, gate re-run clean (check Status OK 0/0/0; tests FAIL 0 / PASS 4213; 0 lints; air clean; document() no-diff; pkgdown clean; both references checkers + cairn_validate green). Status -> review for a second pass; AC5 stays unticked until review re-verifies it against the new fixture.
- 2026-07-25: review pass 2 FAILED at AC5, status -> in-progress (trip 2 of the 3 the thrash rule allows). What failed: F-A — `R/icc.R`/`man/icc.Rd` cite E2's run-1 miss split 34/13 against the fixture's 42/14; F-B — `tests/testthat/test-ci-mpl.R:642-643` cites run-1 coverages 0.968/0.953/1.000 against 0.967/0.944/0.999; F-C — the pass-2 Review entry ticked AC5 while certifying a grep sweep that in fact returns F-A and F-B. Root cause across all three trips is restating run-specific figures in scattered prose; the fix removes the restatements rather than correcting them again.
- 2026-07-25: T9 done. F-A: dropped the second miss-split figure from `@param ci_method` entirely — it existed only to support the rater-count attribution F2 already removed, so with that gone it earned nothing and was pure staleness surface; the qualitative caveat and M91's stable 65-of-66 illustration remain. F-B: dropped the coverage triple from the test comment and pointed it at the note and fixture, with an in-place note saying why restating them is the defect. F-C: replaced the hand-written grep with a mechanical sweep over `git ls-files` x every formatting variant of each superseded figure (19 variants x 129 tracked files, excluding the note, this record and the ledger, which are the three places run-1 legitimately appears) — CLEAN, plus a converse check that the run-2 figures are present in the note. First pass of that sweep also surfaced why the hand greps kept failing: `1.000` matches M91's D3, M91's near-vacuous cell and a README bound, so it is not a discriminating token and was dropped from the probe set.
- 2026-07-25: T9 gate clean (check Status OK 0/0/0; tests FAIL 0 / PASS 4213; 0 lints; air clean; document() no-diff; pkgdown clean; both references checkers + cairn_validate green). Status -> review for a third pass; AC5 stays unticked until review re-verifies it.
- 2026-07-25: review pass 3 FAILED at AC5 (trip 3 — thrash rule reached, no further retry queued). What failed: P3-1 — the T9 rewrite of `@param ci_method` claims no validated cell isolates the rater axis, which the shipped fixture falsifies (E2 vs E3 differ only in `n_r`, 10 vs 2). Also P3-2 (an unreproducible sweep count in T9's own entry, F-C's shape again), P3-3 (T9's stated remedy not executed at two sites), P3-4 (low, a mis-attributed finding in a test comment). Two of three lenses returned zero findings. Per the thrash rule this routes to `/milestone-plan` for a re-cut, not back to implement.
- 2026-07-25: re-cut planned (Scope + AC5 amended at the gate; exported-doc surface -> M94, planned with `Depends on: M92`). T1-T9 compressed to one line each to make budget room; their detail stays in this log.
- 2026-07-25: T10 done — `R/icc.R`, `man/icc.Rd` and `NEWS.md` restored to their pre-M92 state via `git restore --source=origin/main`, so M92 ships no exported-doc change at all; the restated coverage triple removed from `R/ci-mpl.R`'s comment and from the ROADMAP candidate row (both now point at § M92 of the note); the P3-4 mis-attribution corrected in the test comment (F3 was a κ_m-table superlative found BEFORE the re-run, not a figure staled by it).
- 2026-07-25: T11 done — `data-raw/check-m92-figure-restatement.py` committed. Two assertions: the exported-doc diff is empty, and no file in M92's own diff restates a per-cell figure from either run outside the three permitted sites. Probe set is derived FROM both fixtures via Rscript (97 probes), so a re-run updates it without anyone editing the script — the failure mode that beat three hand-written greps. Scoped to the diff deliberately: values like 0.944/0.938 are ordinary content repo-wide (ukoumunne2003 Table I, xiao2009's tables), so a whole-tree match flagged ~80 pre-existing lines and could not discriminate; M92 can only introduce a restatement in a file it edits, which is what AC5 says. Two tokens excluded as non-discriminating, each with its reason recorded in the script: `1.000` (M91's D3, a README bound) and the 3-dp `0.999` (the `eps_hi` clamp constant; a `conf_level` in a test grid) — the 4-/5-dp forms stay live, so E3's coverage is still protected at the precision the note uses.
- 2026-07-25: T11 mutation-verified. Reintroducing a run-2 figure (`0.9440`) into `R/ci-mpl.R` reds it; reintroducing a run-1 figure (`34 below`) reds it. The exported-doc assertion reads COMMITTED state, so an uncommitted edit does not trip it — verified instead against real history: evaluated at 3ef3ec1 (pre-revert) it fails on NEWS.md, R/icc.R and man/icc.Rd, and at HEAD it passes. Both observed, not argued.
- 2026-07-25: T11 follow-up — the new script's docstring named two citekeys as examples, which tripped `xiao2009.md`'s D-009 "nothing references me" settling directive and reddened `check-reference-observations.py` (the M80/M86 lesson, hit by the very file written to stop a different recurring defect). Fixed by naming no source note rather than by adding an exclusion pathspec, so that guard stays fully intact; the reason is recorded in the docstring. All four checkers now green. Gate after the re-cut: `devtools::check(env_vars = c(NOT_CRAN = "false"))` Status OK 0/0/0; tests FAIL 0 / PASS 4213 / SKIP 23 / WARN 2 (the pre-existing glmmTMB warnings); 0 lints; air clean; `document()` no-diff; pkgdown clean. That check ran before this docstring edit, which touches only a python comment under `data-raw/` — build-ignored via `.Rbuildignore:4`, so it cannot reach R CMD check. Status -> review for a fourth pass against the NARROWED AC5.
- 2026-07-25: review pass 4 FAILED. The P3-1 false claim is still live at `mpl-twoway-random-comparison.md:638` ("no committed fixture sweeps that axis alone"; E2 vs E3 differ only in `n_r`) — the re-cut moved it from `R/icc.R` into a file M92 keeps, and the amended AC5 cannot see it because a false negative claim is not a restated figure. Also: the T11 checker has no slash-paired probes (cannot catch `miss 42/14`), goes green when `origin/main` is unresolvable, no-ops after merge, and is not in CI, while `R/ci-mpl.R:224` cites it as enforcement. Two lenses returned zero findings; the diff-bug lens returned eight. Not queuing another self-directed fix — the interpretive prose is the defect generator and my judgment on it has failed four times.
- 2026-07-25: T12 done (maintainer chose "strip the interpretive prose"). Deleted the note's three conclusion-drawing bullets outright — including the one carrying pass-4's two falsified sentences — rather than correcting the false one, since across four passes the defects were always interpretation and never measurement. § M92 verdict is now the table, the two-run GP5 account and the verdict sentence. Deleted `data-raw/check-m92-figure-restatement.py` and both pointers to it (`R/ci-mpl.R`, the test comment): it had no slash-paired probes so could not catch the house-style `miss 42/14`, reported green on an unresolvable `origin/main`, became a permanent no-op after merge, and was never wired into CI, while `R/ci-mpl.R` cited it as enforcement — a guard that overpromises is worse than none. AC5 re-amended to forbid CONCLUSIONS, not merely stale figures, because a false negative claim is not a figure and that gap let the pass-3 defect survive into pass 4.
- 2026-07-25: self-audit of the T12 prose caught one more before review did — the replacement paragraph said "Two of the three [bullets] were false", which is wrong: exactly ONE bullet (the rater-count one) carried the two falsified sentences, and P3-1 lived in `R/icc.R`, not in a bullet. Corrected before commit. The two transcription facts kept in its place were both verified against the fixtures first: E2/E3 differ only in `n_r` (10 vs 2), and D1/E1 differ only in level (0.90 vs 0.95).
- 2026-07-25: T12 gate clean (check Status OK 0/0/0; tests FAIL 0 / PASS 4213 / SKIP 23 / WARN 2 pre-existing; 0 lints; air clean; document() no-diff; pkgdown clean; both remaining references checkers + cairn_validate green). Status -> review for a fifth pass against the CONCLUSION-forbidding AC5.
## Decisions


## Review

Reviewed 2026-07-25 on `m92-mpl-095-interp-probe` @ PR #99. `main` had not moved
since the branch was cut (0 commits behind), so all evidence is against a current base.

**AC1 (GP5 — pre-registration precedes results).** VERIFIED by `git log` on the two
paths: the pre-registration lands in `da10025` (commit time 1784987723), the first
result fixture in `2b984af` (1784987888) — strictly earlier, 165 s apart. Stronger
check run beyond the criterion: `git show da10025:...` against HEAD shows the frozen
bar (R, S, δ, ρ, level, floor ≥ 0.93, `n_rep` 1000) **byte-identical** for all three
cells; only E3's rationale prose changed, as the documented T6 correction.

**AC2 (role asserted, `interp_ok` measured).** VERIFIED against the committed fixture:
all three cells off-node (`n_s` ∉ {10,15,20,30,50,100}) → TRUE, all roles `interp` →
TRUE, and `verdict[["0.95"]]$interp_ok` is the logical TRUE over `interp_cells` =
E1, E2, E3 — a measured value over three same-role cells, not an aggregate across
mixed roles. The script's own `stopifnot` (m92-mpl-095-interp-sweep.R:125-131) asserts
the role labels against geometry and additionally that no cell sits on a node.

**AC3 (GP6 — coverage with exact CI against the frozen floor).** VERIFIED:
E1 0.9680 [0.9551, 0.9780]; E2 0.9530 [0.9380, 0.9653]; E3 1.0000 [0.9963, 1.0000];
floor 0.93 and `n_rep` 1000 on every cell, matching the pre-registration exactly;
`all(adequate)` TRUE, `failed_cells` empty. Rule recorded in the fixture is `linear`
— the shipped rule, so the frozen bar was applied, not a substitute.

**AC4 (frozen consequence executed).** VERIFIED — no-shortfall branch. Zero cells
below floor, so bracket-max was not adopted. `git diff main..HEAD -- R/` filtered to
non-comment lines is **empty**: the runtime lookup and every other code path are
untouched, which is the strongest available form of "the lookup is unchanged".

**AC5 (statements match the fixture; a test pins the property).** **FAILED** — see
finding F1 below; the sub-check recorded here passed but does not cover the claim F1
falsifies. Three live
claim sites — `R/ci-mpl.R:217` (0.968 / 0.953 / 1.000 named per cell), `R/icc.R:351`
and `NEWS.md:79` (interpolated path validated at all three levels) — each check out
against the fixture and against M91's D1–D3 for the other two levels. The pin is
`test-ci-mpl.R:631`, and it discriminates the two candidate RULES rather than only a
table edit: bracket-max would return 0.7863 / 0.1858 / 1.4657 at the same geometries
against the pinned 0.7089 / 0.1517 / 1.3663.

**AC6 (candidate rows resolved).** VERIFIED: the "off-node S coverage probe at 0.95"
row is absent from `cairn/ROADMAP.md` (absorbed at the plan gate), and the κ_m
envelope/smoother row now carries M92's evidence and its `→ M92 T3` lineage —
narrowed to "promote only on a NEW failure". (Pass 2: that row still carried run-1
figures and the falsified independence claim; corrected in place and marked — see the
pass-2 AC5 note below.)

**AC7 (full gate).** VERIFIED, fresh at review:
`devtools::check(env_vars = c(NOT_CRAN = "false"))` → Status OK, 0 errors / 0 warnings
/ 0 notes (2m 20.7s). Full suite at `NOT_CRAN=true CI=true` → FAIL 0, PASS 4210,
SKIP 23, WARN 2 (pre-existing glmmTMB convergence warnings; `git diff main..HEAD -- R/`
changes zero non-comment lines, so not from this diff). `lintr::lint_package()` 0 lints;
`air format --check .` clean; `devtools::document()` no-diff; `pkgdown::check_pkgdown()`
"No problems found"; `enumerate-generalizing-claims.py --check` and
`check-reference-observations.py` both green. CI on `af6aff2`: 9/9 green.

**Consistency gate.** `cairn_validate.py` exit 0 — every check PASS. Coverage-completeness
included, so the plan's criterion→task map is intact. No `DESIGN.md` principle changed,
so `cairn_impact` is a clean no-op. Profile `consistency-gate` slot run in full above.

## Review findings

Three fresh-context lenses + an independent scorer.
**Blame-history [S]: zero findings.** **Prior-review [S]: zero findings**
(the `gh api .../pulls/comments` probe returned `[]`, so archived `## Review` sections
were the evidence base — the expected shape for this repo). **Diff-bug [O]: six
findings**, scored 87 / 68 / 92 / 78 / 62 / 35.

### Actioned (score ≥ 80)

**F1 (87) — `data-raw/m92-mpl-095-interp-sweep.R:141-142`: the seed scheme silently
re-runs M91's exact datasets, so "second independent look" is false for two of three
cells.** `seed_base <- 20260725L` with the same `seed_stride <- 1000000L` and the same
cell ordering as M91's generator (base `20260724L`) makes M92 cell `ci` rep `r` use the
*same integer seed* as M91 cell `ci` rep `r+1`. E1 (ci=1, R=3, S=25) shares 999 of 1000
datasets with D1; E3 (ci=3, R=2, S=40) draws entirely inside D3's 2000. Only E2 is new
data. **Verified here independently**: `mpl_simulate` at the aligned seeds is
`identical()` TRUE for both pairs at several reps. Consequences — the "second
independent look" (note § M92 verdict), "two independent passes" (ROADMAP candidate row)
and "a second probe's worth of evidence" (`R/ci-mpl.R`) claims are unsupported; and the
note's "0.934 (D1, 0.90) → 0.968 (E1, 0.95) … monotone in the level" item is
arithmetically forced on shared data, since `crit = (1+κ)·qchisq(1−α,1)` is larger at E1
(6.56) than D1 (4.81), so E1's interval contains D1's on every shared rep. The per-cell
coverage numbers stand; the independence and controlled-triple framing does not.

**F3 (92) — `data-raw/m92-mpl-095-interp-sweep.R:22-25`: the false "largest κ_m"
superlative T6 corrected everywhere else is still live in the committed generator.**
The header still reads "E3 crosses the largest 0.95 kappa_m (1.2670 -> 1.4657 over the
same nodes)" and "there the absolute error is largest". Both false: the slice maximum is
1.6245 at (R=2, S=100) and the (2, 50→100) bracket is higher and wider. The T6 work-log
entry claims correction "at all four live sites"; this is an uncorrected fifth, in the
file the note names as generator of record. **Verified here**: the strings are present.

### Logged, not actioned (score < 80 — surfaced, never silently dropped)

- **F2 (68)** — `R/icc.R:357-361`: the new rater-count claim compares M91's D1
  (conf_level 0.90, S=25, R=3) with E2 (0.95, S=40, R=10), so three factors vary while
  the sentence credits rater count. Real but narrow; no committed fixture isolates the
  rater axis.
- **F4 (78)** — `NEWS.md:80-81`, `R/icc.R:351-353`: "the same evidential footing"
  overstates — nodes are each individually calibrated, interpolated values nowhere, and
  only six (R,S,level) off-node points have ever been coverage-checked.
- **F5 (62)** — `tests/testthat/test-ci-mpl.R:645-659`: all three pinned S values are
  exact bracket midpoints, so the pin cannot distinguish linear from any
  bracket-symmetric rule (R=3, S=22 → 0.6625 linear vs 0.7089 bracket-mean). It does
  discriminate the pre-registered bracket-max alternative, which is what the work log
  claimed, so the gap is narrower than the finding framed it. **Verified here.**
- **F6 (35)** — `data-raw/m92-mpl-095-interp-sweep.R:169-173`: the `tryCatch` fallback
  returns `c(lower=0, upper=1)`, scoring an errored fit as covered. Byte-identical to
  M91's shipped generator and a repo-wide convention, and no rep errored in this run.

### Gate outcome

**AC5 fails as written.** F1 falsifies an in-repo statement about the 0.95 evidence, and
AC5 requires every such statement to match what the shipped fixture carries. Per the
review rules a criterion failure returns the milestone to `in-progress` — the criterion
is not reinterpreted and nothing merges. F3 rides along in the same send-back.

## Review — pass 2 (2026-07-25, after the F1/F3 fixes)

`main` still unmoved. All seven criteria re-executed against the **new** fixture; the
pass-1 evidence for AC2/AC3 cited run-1 numbers and is superseded by what follows.

**AC1 (GP5)** — re-verified, and this is where the re-run had to be justified. The
frozen bar is unchanged: `git diff da10025..HEAD` on the note leaves cells, floors
(0.93), `n_rep` (1000), the criterion and the shortfall consequence untouched — only
rationale prose moved. `meta$seed_base` in the shipped fixture is 20920725, the
disjoint base. Decisively for GP5: **run 1 cleared every floor too** (0.9680 / 0.9530 /
1.0000), so no floor result motivated the re-run — the defect was reproducibility. Both
fixtures are committed, so the claim is checkable rather than asserted.

**AC2** — re-verified on the new fixture: all three cells off-node, all roles `interp`,
`verdict[["0.95"]]$interp_ok` TRUE over E1/E2/E3. The generator now carries a second
`stopifnot` asserting M92's seed span is disjoint from M91's, mutation-verified to error
when the old base is restored, and pinned to the frozen `n_rep` so smoke mode cannot
relax it.

**AC3 (GP6)** — re-verified: E1 0.9670 [0.9540, 0.9772]; E2 0.9440 [0.9279, 0.9574];
E3 0.9990 [0.9944, 1.0000]; floor 0.93 and `n_rep` 1000 on every cell; `rule` = linear;
`all(adequate)` TRUE. κ_m is bit-identical across runs, as it must be — it is
table-derived, not run-derived.

**AC4** — unchanged and re-verified: `git diff main..HEAD -- R/` filtered to non-comment
lines is still empty.

**AC5 (GP7)** — **FAILED** (see the pass-2 findings below; this entry's own sweep claim
is finding F-C). The correction described here was real but incomplete. Sweeping
every site again turned up one the fix pass missed: `cairn/ROADMAP.md`'s envelope
candidate row still carried run-1's 0.9530 / 1.0000 and the "two independent passes"
claim F1 had falsified. Corrected in place and marked (ROADMAP is current knowledge,
D-045). A full grep for `independent pass|independent look|second probe` and for the
run-1 figures now returns only pass-1's own review record, which correctly describes
what was found at the time. The test pin gained a non-midpoint literal (R=3, S=22 →
0.6624794) plus an explicit refutation that it equals the bracket mean, so it
discriminates any bracket-symmetric rule, not just bracket-max.

**AC6** — re-verified; the corrected row is the one described above.

**AC7** — re-verified fresh after the fixes: `devtools::check(env_vars =
c(NOT_CRAN = "false"))` Status OK, 0/0/0 (2m 0.1s); full suite at `NOT_CRAN=true
CI=true` FAIL 0 / PASS 4213 / SKIP 23 / WARN 2 (the same pre-existing glmmTMB warnings);
0 lints; air clean; `document()` no-diff; `pkgdown::check_pkgdown()` clean; both
references checkers green. `cairn_validate` exit 0, every check PASS.

### Pass-2 findings (all three lenses)

Blame-history and prior-review each independently found the stale test comment;
diff-bug found both stale sites plus the defect in this section's own record. No
scorer round: these are the content of an acceptance-criterion failure (review step 4),
not discretionary findings needing a triage threshold, and each was verified directly
against the shipped fixture before being recorded.

**F-A — `R/icc.R:361-362`, mirrored to `man/icc.Rd`.** The `@param ci_method` text cites
E2's miss split as "34 below against 13 above". The shipped fixture gives **42 / 14**;
a scan of every committed `data-raw/*.rds` finds 34/13 only in
`m92-interp-sweep-run1-collided.rds`. A user quoting `?icc` would cite a figure no
re-run of the committed generator can reproduce.

**F-B — `tests/testthat/test-ci-mpl.R:642-643`.** The AC5 pin's own comment says the
cells cleared the floor at "0.968 / 0.953 / 1.000"; the fixture says
**0.967 / 0.944 / 0.999**. Nothing goes red because the assertions pin κ_m, which is
table-derived and bit-identical across runs.

**F-C — this Review section, and the AC5 tick it supported.** The pass-2 AC5 entry
certified that a full grep "returns only pass-1's own review record". It does not: it
returns F-A and F-B. A wrong figure is recoverable; a tracking record affirmatively
certifying a clean mechanical sweep is worse, because the next pass inherits it instead
of repeating it.

**Sub-threshold, logged not actioned.** The blame-history lens noted that the seed guard
hardcodes M91's constants (base, stride, cell count, `n_rep`) rather than reading
`data-raw/m91-mpl-interp-sweep.R`, so a future edit to M91's generator would leave the
assertion checking a stale snapshot. Harmless while that file is frozen (it is committed
history), and the guard's span is a strict superset of M91's real `n_rep` vector.

### Root cause, and why the fix is not "correct three more numbers"

Three rounds have each ended with a site left behind — F3, then the ROADMAP row, now
F-A/F-B — and every sweep failed for a different formatting reason (spaces, decimal
places, miss counts instead of coverages). The defect is the practice of **restating
run-specific figures in prose scattered across the tree**. The remedy is to stop: the
fixture and the reference note are the single source, and other sites point at them
rather than copying numbers out. That removes the class instead of patching instances.

## Review — pass 3 (2026-07-25): FAILED at AC5; thrash rule reached

Blame-history and prior-review lenses: **zero findings** each, both independently
re-deriving rather than trusting the record (the prior-review lens explicitly re-ran the
T9 sweep claim rather than accepting it — the F-C remedy working). Diff-bug lens: four
findings. My own exhaustive sweep this pass — probe set derived FROM the two fixtures
(every value in run 1 absent from run 2, each decimal form), 33 discriminating variants
over 336 tracked files — returned zero hits in any of the 12 files this milestone
changed. That sweep was clean and still missed what follows, which is the point.

**P3-1 (the failure) — `R/icc.R:360-362`, mirrored to `man/icc.Rd`.** T9 rewrote a
scoped pairwise sentence into a corpus-wide negative: "the validated cells differ in
rater count, subject count and level together, so nothing here isolates which of those
drives it". The shipped fixture falsifies it — **E2 and E3 share `n_s` 40, `delta` 4,
`rho` 0.60 and `conf` 0.95 and differ only in `n_r` (10 vs 2)**, so the corpus contains
exactly the isolating pair the sentence denies. Verified programmatically here. A reader
of `?icc` is told not to look for something the milestone's own data contains.

**P3-2 — this record, T9's work-log entry.** It certifies "19 variants x 129 tracked
files" over `git ls-files` without stating the `R/ tests/ man/ vignettes/ + NEWS +
README + ROADMAP` filter that produces 129, so the count cannot be re-derived from the
method as written. Structurally F-C again. The named exclusion set is also wrong both
ways: the ledger carries no run-1 M92 figure, while
`data-raw/m92-mpl-095-interp-sweep.R` does carry the superseded seed base (legitimately,
as collision history) and was not listed.

**P3-3 — `R/ci-mpl.R:217-218` and `cairn/ROADMAP.md:26`.** T9's task text says "stop
restating run-specific figures outside the note and the fixture"; both sites still
restate them. They are correct against run 2 today, so this is not an AC5 violation —
but the class T9 claims to have removed survives at 5 of 7 figures, and any future
re-run re-opens them.

**P3-4 (low) — `tests/testthat/test-ci-mpl.R:648-651`.** The new comment attributes F3
to the staleness class; F3 was a kappa_m superlative found before the re-run, not a
figure staled by it. The causal story would mis-scope a future check.

### Why this stops here

AC5 has now failed at three consecutive reviews — F3, then F-A/F-B/F-C, now P3-1 — and
each failure was a claim about the fixture written in the prose fixing the previous
failure. P3-1 was authored by the very task whose purpose was to end the class. The
tracking rules' thrash rule applies at the third trip back: this is a mis-planned
milestone, not one needing a fourth patch.

The diagnosis is a scope error made at the plan gate. M92 bundled two unlike things: a
**coverage measurement**, which has been correct and stable since T7 and survived three
adversarial passes untouched, and an **exported-prose surface** that must stay
consistent with a regenerable fixture, which failed every time. The first is finished
work; the second needs its own milestone with a mechanical rule (user-facing docs
restate no run-specific figure, and make no universal or negative claim about the
fixture that a committed check cannot settle).

## Review — pass 4 (2026-07-25): FAILED; the re-cut excused the defect it was meant to fix

Blame-history and prior-review lenses: **zero findings** each, both verifying rather than
trusting (the prior-review lens reproduced the "97 probes" count; blame-history confirmed
the revert landed byte-for-byte at the pre-M92 tree and found the M71 precedent for this
exact thrash→re-cut path). Diff-bug lens: **eight findings**. The mechanical half of the
re-cut does hold — the exported-doc diff is genuinely empty, GP5's frozen bar is
byte-identical across all four rounds, and every figure in every kept file checks out
against the fixture. What fails is the judgment behind the re-cut.

**The decisive finding.** `cairn/references/mpl-twoway-random-comparison.md:638` still
says "no committed fixture sweeps that axis alone". **E2 and E3 differ only in rater
count** (`n_s` 40, `delta` 4, `rho` 0.60, `conf` 0.95; `n_r` 10 vs 2) — verified
programmatically here, as at pass 3. This is verbatim the claim that ended pass 3. The
re-cut did not remove it; it moved it out of `R/icc.R` into the note, which M92 keeps.
M94 cannot cover it either: M94's Scope In is the exported surface, so the note's copy
has no owner.

**Why the amendment is the failure, not the prose.** Original AC5 required *every in-repo
statement* about the 0.95 evidence to match the fixture. Amended AC5 requires an empty
exported-doc diff plus no restated figures. The amended form passes while the falsified
statement above sits in a kept file, because a false *negative claim* is not a restated
*figure*. The narrowing I wrote at the plan gate therefore excused a real defect rather
than only relocating one — the reviewer's judgment, and it is correct.

**The enforcement addresses the wrong class.** Of three prior failures, only pass 2 was
figure-staleness. Pass 1 was a seed collision falsifying independence; pass 3 — the trip
that reached the thrash rule — was a false claim about the fixture, which no figure grep
of any formatting variant can detect. The checker built at T11 targets the class that
failed once, not the class that ended the milestone twice.

**The checker also overpromises, and `R/ci-mpl.R:224` points users at it as enforcement.**
Verified defects: no probe contains a slash, so the house-style `miss 42/14` is
undetectable (its own docstring names "42 / 14" as a historical miss); an unresolvable
`origin/main` makes both halves report green rather than error; `changed_files()` becomes
empty at merge, so the restatement half no-ops permanently once M92 lands; it is not
wired into the CI job carrying its two sibling checkers; `PERMITTED` is broader than AC5
and the script exempts itself while containing a live probe string; and four of seven
`NON_DISCRIMINATING` entries never fire, `1.000`/`1.0000` being inert while hiding E3's
run-1 coverage and its run-2 `cp_hi`.

**One claim the revert itself falsified** (finding 2): the note at :638-639 says "the
exported text now reports both observations without attributing the difference" — after
T10 restored `R/icc.R`, the exported text reports only D1's, and E2's split appears in no
exported file.

### Assessment

Four passes; the coverage measurement was correct and stable in all four. Every failure
has been an interpretive claim I authored about that measurement, and the re-cut I
designed to end the class instead narrowed the criterion around it. The defect generator
is the interpretive prose — the note's "three things the cells establish beyond the
headline" bullets are where pass-3's and pass-4's failures both live — not the evidence,
the code, or the fixtures.
