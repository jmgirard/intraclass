<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M108: Adjudicate the oracle-bayesian.R k=2 convergence divergence

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP5   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m108-oracle-bayesian-k2-adjudication`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Execute the maintainer's D-024 escalation decision for the `oracle-bayesian.R`
`diverged-escalated` ledger row: adaptive warmup, regenerated fixture, recorded
adjudication.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** bounded per-rep adaptive warmup in `data-raw/oracle-bayesian.R`
(double warmup until R̂ < 1.10 and ESS > 100, ≤ 3 doublings — the source's own
protocol, which our fixed budget replaced); the regenerated
`bayesian-oracle.rds` — a maintainer-decided re-baseline under D-024 clause 4,
decided at this plan gate (2026-08-07); the D-entry recording the
adjudication; the O-Bayes ORACLES.md refresh plus the bounded doc sweep; the
`check-references` checkers and installed suite.

**In (added by 2026-08-07 amendment):** the base-template seeding fix in
`data-raw/oracle-bayesian.R` — `set.seed(base_seed)` before the template data
draw and an explicit Stan `seed` on the template fit — so the script is a
deterministic function of its declared seeds (M108 finding: `update()` refit
draws depend on the unseeded template fit, making every prior run an
unreproducible realization); `n_rep` raised 250 → 500 (maintainer choice at
the 2026-08-07 amendment gate, halving the MC noise under the strict
coverage-ordering pin); the fixture is regenerated under the seeded template,
and AC4's harness re-run is then expected `reproduced` (bit-level). A pin
failing on the deterministic realization → stop and return to the gate, never
re-run to green.

**Out:** the 19 sibling `oracle-bayesian-*.R` scripts' sampler budgets — any
sibling divergence surfaces as an M109 escalation and is adjudicated with this
milestone's remedy as precedent, never batch-fixed here; the ~20
`test-icc-brms.R` `converged_frac >= 0.90` assertions — they read committed
fixtures and are untouched by this remedy; the M107 harness — no changes.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: A new D-entry in `cairn/DECISIONS.md` records the adjudication of
      the `oracle-bayesian.R` `diverged-escalated` ledger row (run
      2026-08-06): the measured attribution of the k=2 convergence shortfall,
      the remedy chosen, and its rationale, citing D-024 as the policy it
      executes; the ROADMAP candidate row retires to it.
- [ ] AC2: The work log records `converged_frac` for the k=2 cell at the
      current sampler settings and, if the chosen remedy amends sampler
      settings, at the amended settings — both measured on the script's own
      seed stream (`base_seed = 20200`) — so the shortfall's attribution is a
      measured claim, not an inference.
- [ ] AC3: `data-raw/oracle-bayesian.R` implements the chosen remedy; if the
      remedy regenerates the fixture, the regenerated
      `tests/testthat/fixtures/bayesian-oracle.rds` is committed and the
      generating run passes all four `stopifnot` pin blocks (the work log
      records 4/4 from the run transcript — save-first ordering means the
      script can write a fixture and then abort, so the transcript is the
      evidence).
- [ ] AC4: A post-remedy harness re-run (`Rscript data-raw/rerun-oracle.R
      oracle-bayesian.R`) records a non-escalated verdict — `reproduced` or
      `drift-within-noise`, pins 4/4 — in `data-raw/oracle-rerun-ledger.tsv`,
      replacing the `diverged-escalated` row.
- [ ] AC5: `cairn/references/ORACLES.md`'s O-Bayes entry's observed
      statistics and convergence caveat match the script and fixture as they
      stand after the adjudicated remedy; and a recorded `git grep -n` sweep
      for the stems `converg`, `warmup`, and `0.90` over `R/ man/ vignettes/
      NEWS.md tests/testthat/ cairn/references/` has each hit either updated
      or recorded in the work log as not stating the changed fact (the claim
      is about what that sweep enumerates, nothing wider).
- [ ] AC6: The three `check-references` checkers
      (`data-raw/enumerate-generalizing-claims.py --check`,
      `data-raw/check-reference-observations.py`,
      `data-raw/check-oracle-registry.py`) pass locally after the ORACLES.md
      edit, and the installed-package suite at `NOT_CRAN=true CI=true` sums
      failed + error = 0 against the fixture as committed after the remedy.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T3
- AC2 → T2
- AC3 → T1, T2
- AC4 → T3
- AC5 → T4
- AC6 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Amend `data-raw/oracle-bayesian.R` (brm_args at
      data-raw/oracle-bayesian.R:66): per-rep bounded adaptive warmup —
      refit with doubled warmup (≤ 3 doublings) while R̂ ≥ 1.10 or
      ESS ≤ 100 — and update the header's divergence-from-source notes
      (lines 229–239), which the remedy partly obsoletes.
- [x] T2: Run the amended script in the background (both cells, ~500+ fits;
      check for concurrent R sessions first — M107 contention lesson);
      work-log k=2/k=5 `converged_frac` beside the 2026-08-06 run's .864;
      commit the regenerated fixture with transcript-verified 4/4 pins. A
      pin still failing → stop and return to the gate, never re-run to green.
- [x] T3: Harness re-run → non-escalated ledger row; append the D-entry
      (adjudication + rationale, citing D-024); retire the ROADMAP candidate
      row to it.
- [x] T4: ORACLES.md O-Bayes refresh; the AC5 grep sweep with per-hit
      disposition in the work log; run the three checkers and the installed
      suite (`NOT_CRAN=true CI=true`).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-07: created by /milestone-plan (promotes the M107 k=2 adjudication candidate row; the plan gate's remedy choice IS the D-024 escalation decision).
- 2026-08-07: criteria audit ([O] fresh-context reader) returned 5 findings on this file's ACs — AC2/AC3/AC5/AC6 presupposed the warmup remedy before the gate decided it (AC3 as drafted mandated a re-baseline D-024 clause 4 reserves to the escalation outcome), AC4 over-pinned `reproduced`; all fixed with the auditor's repairs (remedy-conditional wording; `reproduced` or `drift-within-noise`) before the gate.
- 2026-08-07: plan gate chose adaptive warmup doubling + fixture regeneration over (a) a larger fixed budget and (b) revising the .90 floor to .85, because the source's own protocol is adaptive and a fixed budget re-fails at the next engine upgrade, while a floor cut moves the bar to fit the evidence (GP5); falsified by the amended script's k=2 `converged_frac` still landing below .90 on the same seed stream.
- 2026-08-07: status → in-progress; branch `m108-oracle-bayesian-k2-adjudication` cut from pushed main; question gate skipped (the plan gate already fixed the remedy and its parameters — nothing genuinely open).
- 2026-08-07: T1 done — `one_rep()` now refits with doubled warmup (≤ 3 doublings, `iter = warmup + 1000`) while R̂ ≥ 1.10 or bulk ESS ≤ 100 on the monitored components; per-rep `n_doublings` and per-cell `frac_adapted` recorded; fixed-warmup divergence notes rewritten (observed-stats line filled at T2 from the regeneration run); air + parse clean.
- 2026-08-07: T2 done — AC2: k=2 `converged_frac` 1.000 and k=5 1.000 at the amended settings (seed stream 20200; frac adapted .116/.032) vs the 2026-08-06 fixed-warmup harness run's k=2 .864 (ledger row; committed fixture .904) — the shortfall is attributable to the fixed warmup budget, removed by the source's own adaptive protocol. AC3: regeneration transcript shows the run exiting 0 past all four save-first `stopifnot` pin blocks (4/4; no R sessions were running concurrently); regenerated fixture committed (k=5 σ_r MAP relbias moved −.147→−.246, divergence note figure updated).
- 2026-08-07: T3 harness re-run → `diverged-escalated` 3/4, failing pin 4c (`k2$coverage_icc < k5$coverage_icc`: fresh .964 vs .940) with max delta .13 vs the same-seed T2 fixture — a different pin than the adjudicated one; stopped per the T2 stop rule and probed instead of re-running.
- 2026-08-07: attribution probes — a 30-rep slice of the real pipeline is bit-identical across repeated direct runs AND under the harness `source()` mechanism when the template stage is seeded; changing only the template's data seed (42→43) changes every rep's draws (template seeds 999/888 coincidentally identical — channel partial, unresolved, immaterial to the fix). The script's non-reproducibility is the unseeded template stage; explains the historical .864/.904/.924 spread.
- 2026-08-07: substantive amendment (gate): Scope-In adds the template seeding fix + n_rep 250→500; maintainer chose "seed fix + n_rep 500" over 250-only, pin-softening, and pause.
- 2026-08-07: T2 re-done under the amendment — AC2/AC3 at the final settings (seeded template, n_rep 500, seed stream 20200): k=2 `converged_frac` 1.000 (frac adapted .112), k=5 1.000 (.008), vs .864 at k=2 on the 2026-08-06 fixed-warmup run; transcript shows exit 0 past all four save-first pin blocks (4/4); coverage .918 (k=2) < .958 (k=5), the ordering pin's gap now .04; fixture committed.
- 2026-08-07: T3 done — AC4: harness re-run verdict `reproduced`, pins 4/4, max_abs_delta 0.000e+00 over 21 leaves (ledger row replaces `diverged-escalated`); D-025 appended (adjudication + rationale, executing D-024 clauses 3–4); the motivating ROADMAP candidate row was already retired at the 2026-08-07 plan commit (promoted into the M108 row), so AC1's retirement clause is carried by that commit + D-025.
- 2026-08-07: T4 AC5 sweep (`git grep -n -E "converg|warmup|0.90"` over R/ man/ vignettes/ NEWS.md tests/testthat/ cairn/references/) — updated: ORACLES.md O-Bayes entry (observed stats + caveat rewritten to the n_rep-500 seeded-template fixture, divergences 2→1, harness `reproduced` recorded) and test-icc-brms.R:589 fixture-test comment (fixed-budget → adaptive). Not stating the changed fact: sibling O-Bayes-* "fixed-warmup budget" comments (true of those unamended scripts, M109 scope); R/engine-brms.R + R/icc.R + snapshots (shipped convergence warning / source protocol, not the script's budget); MPL/classical `0.90` conf-level and coverage figures; other engines' "converge" prose (lavaan/glmmTMB/bootstrap); references pages' unrelated coverage/budget figures; committed data fixtures (kappa-m-table, abort-remedy-sweep).
- 2026-08-07: T4 done — AC6: three `check-references` checkers pass (orphan triage-ledger row for the removed ORACLES.md claim line dropped; 294/294 in sync); installed-package suite at `NOT_CRAN=true CI=true`: failed=0 error=0 (5854 pass, 23 live-Stan CI skips, 2 known engine fitting warnings); lintr clean on the two changed code files. Status → review.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
