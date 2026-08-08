<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M113: MC-default skew response — frozen-rules disposition from the M111 data

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP5   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m113-mc-skew-response   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Decide, against pre-frozen rules read over the committed M111 per-rep data,
how the one-way MC default should respond to its measured skew
under-coverage — replace, warn, document, or no change — assessment only.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a frozen criteria page (synthesis note) defining per-cell decision
rules before any new derivation artifact, with the already-published M111
figures acknowledged as known priors and the 0.93 floor traced to its M76
C2 / M111 F-rules lineage; a `data-raw` derivation script re-deriving
per-cell unconditional coverage for the `searle`, `burch`, and `mc` legs
from the committed `m111-fallback-results.rds` (no re-run, no MC/glmmTMB
dependency); a committed derived fixture + page summary; a D-entry verdict
naming each arm's disposition.

**Out:** any change under `R/`, `tests/`, `man/`, `vignettes/` — the
disposition's implementation (default change, runtime warning, or doc pass)
is a follow-on milestone planned from the verdict; designing a runtime skew
diagnostic (none is shipped; needed only if "warn" wins) → that same
follow-on; harness hardening → M112; a fresh classical-only sweep → not
needed, the committed fixture carries per-rep legs (falsifier logged in the
work log).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: A frozen criteria page under `cairn/references/` defines, before
      any new derivation artifact is committed (verified by commit order),
      the per-cell decision rules: the 0.93 floor traced to its external
      precedent (M76 C2 / M111 F-rules lineage), the arms assessed, the
      64-cell grid, and an aggregation rule mapping outcomes to per-arm
      dispositions — {replace-GO, no-GO} for each classical arm and {warn,
      document, no-change} for the MC incumbent — with the already-published
      M111 figures acknowledged on the page as known priors.
- [ ] AC2: Per-cell unconditional coverage for the `searle`, `burch`, and
      `mc` legs is re-derived from the committed
      `data-raw/m111-fallback-results.rds` over the full 64-cell grid by a
      committed derivation script with no MC/glmmTMB dependency; the
      derived table is committed as a fixture, summarized on the criteria
      page, and its MC column matches the two ROADMAP-quoted cells
      (0.676 / 0.673) at their quoted precision.
- [ ] AC3: The verdict against the frozen rules is recorded as a
      `cairn/DECISIONS.md` entry naming each arm's disposition; a
      replace-GO disposition stops at the merge gate for the maintainer's
      explicit decision (superseding the default-method fence takes its own
      D-entry — PRINCIPLES #3 / D-001) and ships nothing in this milestone.
      (RB tripwire: ip-touching)
- [ ] AC4: `git diff --stat` over the branch shows no change under `R/`,
      `tests/`, `man/`, or `vignettes/` — assessment only.
- [ ] AC5: `air format --check`, `lintr::lint_package()`, and all four
      `data-raw` checkers pass locally before the PR push — the new
      references page carries its `INDEX.md` line, provenance block, and
      generalizing-claims triage rows (M76/M85 lessons).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Author the frozen criteria page from
      `templates/synthesis-note.md` (rules, floor lineage, known-priors
      acknowledgment, disposition vocabulary, provenance, INDEX line,
      triage rows); commit it before any derivation artifact.
- [x] T2: Write `data-raw/m113-skew-response-derivation.R` reading the
      committed fixture; emit per-cell × leg unconditional coverage (and
      the per-tail miss splits the warn/document rules need) as a committed
      fixture; verify the MC column against the two quoted cells.
- [x] T3: Read the derived table against the frozen rules; record per-arm
      outcomes on the page's results section; draft the D-entry; on a
      replace-GO, stop at the gate for the maintainer decision.
      (RB tripwire: ip-touching)
- [x] T4: Gate evidence pass — branch `git diff --stat` scope check, air,
      lintr, the four `data-raw` checkers; fix what reds.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-08: created by /milestone-plan (promotes the MC-skew-under-coverage candidate row; plan gate 2026-08-08).
- 2026-08-08: criteria audit ([O], fresh-context) returned: AC1's "frozen before any sweep artifact" unsatisfiable — the M111 results already exist and are quoted in the ROADMAP, so commit order cannot establish blindness (fixed: frozen before any *new* derivation artifact, known priors acknowledged, floor traced externally); AC2 confirmed fully re-derivable from the committed fixture's per-rep leg rows; AC3 confirmed reachable — the default-method choice is D-entry-tradeable under the D-001 fence, not IP-blocked; AC4's path allowlist over-tight (fixed: negative check on the four dirs).
- 2026-08-08: plan gate chose the full four-way disposition over (a) replace-only GO/NO-GO and (b) document-only-without-assessment, because one cheap derivation over already-committed data settles all four dispositions under frozen rules; falsified by the frozen rules proving unable to discriminate warn vs document on this evidence.
- 2026-08-08: plan chose derivation-from-committed-fixture over a classical-only re-sweep because the fixture carries per-rep `covered`/miss columns for all three legs (audit-verified at `m111-fallback-sweep.R:130-152`); falsified by the committed fixture proving to hold cell summaries rather than per-rep rows — the re-sweep then returns and M113 gains a Depends-on: M112.
- 2026-08-08: set in-progress by /milestone-implement; branch m113-mc-skew-response cut from pushed main (e7e0a45).
- 2026-08-08: implement question gate adopted the S1/S2 frozen rule set as proposed (every-cell 0.93 replace bar per classical arm, width descriptive; warn-vs-document by generator-family spread for the incumbent); escalation via /milestone-brief offered on the ip-touching tag and declined.
- 2026-08-08: T1 done — frozen criteria page cairn/references/mc-skew-response-comparison.md committed before any derivation artifact, with INDEX line, provenance, D-009 settling directives, and 4 OUT-repo-analysis triage rows; all four data-raw checkers + cairn_validate green.
- 2026-08-08: minor amendment (pre-derivation, blind content untouched) — S2 clarified to read coverage among non-aborted reps, since the bare "coverage" wording would fire on the near-zero abort cells and re-open D-026's adjudicated abort; clarification dated on the page itself.
- 2026-08-08: T2 done — derivation script + committed data-raw/m113-skew-response-coverage.tsv (192 rows = 64 cells × 3 legs); fixture-shape and quoted-cell assertions pass (0.676 exact; the k=50 cell is exactly 0.6725, rendered 0.673 half-up on the M111 page, so the pin is a ±0.0005 band); lintr 0, air clean.
- 2026-08-08: T3 done — verdict recorded as D-027 (searle no-GO 21/64 cells below floor, worst 0.674; burch no-GO 16/64, worst 0.6655 incl. one gaussian cell; mc warn, 36/64 below floor among non-aborted reps across all four families — 5 zero-abort skew/kurtosis cells + 26 selection-conditioned high-abort cells); page Results/Disposition filled; warn-trigger candidate row added; no replace-GO, so the ip-touching stop did not fire and the D-001 fence is untouched.
- 2026-08-08: T4 done — branch scope check clean (no R/, tests/, man/, vignettes/ paths in main...HEAD), air format --check clean, lintr::lint_package() 0 lints, all four data-raw checkers OK, cairn_validate all checks passed. The profile verify slot's devtools::test() was not re-run: the branch changes no package code or tests, so the suite outcome cannot differ from main; review's consistency gate runs the fuller check.
- 2026-08-08: all tasks done; status → review.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
