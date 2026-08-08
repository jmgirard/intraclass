<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M113: MC-default skew response — frozen-rules disposition from the M111 data

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP5   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m113-mc-skew-response · https://github.com/jmgirard/intraclass/pull/121   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1: A frozen criteria page under `cairn/references/` defines, before
      any new derivation artifact is committed (verified by commit order),
      the per-cell decision rules: the 0.93 floor traced to its external
      precedent (M76 C2 / M111 F-rules lineage), the arms assessed, the
      64-cell grid, and an aggregation rule mapping outcomes to per-arm
      dispositions — {replace-GO, no-GO} for each classical arm and {warn,
      document, no-change} for the MC incumbent — with the already-published
      M111 figures acknowledged on the page as known priors.
- [x] AC2: Per-cell unconditional coverage for the `searle`, `burch`, and
      `mc` legs is re-derived from the committed
      `data-raw/m111-fallback-results.rds` over the full 64-cell grid by a
      committed derivation script with no MC/glmmTMB dependency; the
      derived table is committed as a fixture, summarized on the criteria
      page, and its MC column matches the two ROADMAP-quoted cells
      (0.676 / 0.673) at their quoted precision.
- [x] AC3: The verdict against the frozen rules is recorded as a
      `cairn/DECISIONS.md` entry naming each arm's disposition; a
      replace-GO disposition stops at the merge gate for the maintainer's
      explicit decision (superseding the default-method fence takes its own
      D-entry — PRINCIPLES #3 / D-001) and ships nothing in this milestone.
      (RB tripwire: ip-touching)
- [x] AC4: `git diff --stat` over the branch shows no change under `R/`,
      `tests/`, `man/`, or `vignettes/` — assessment only.
- [x] AC5: `air format --check`, `lintr::lint_package()`, and all four
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

- 2026-08-08: D-027 promoted to cairn/DECISIONS.md (S1 searle no-GO, S1 burch no-GO, S2 mc warn; no default-method change). Milestone-local: the S2 non-abort clarification and its commit-order caveat (review finding D4) are recorded, dated, on the criteria page itself.

## Review
<!-- owner: review · exclusive -->

**Evidence (2026-08-08, fresh, by command):**

- AC1 ✓ — commit order: 3ad9a30 (page) precedes ff78052 (script + TSV); page carries floor lineage (M76 C2), arms, 64-cell grid, aggregation rule, per-arm vocabulary, known-priors block. Caveat, recorded dated on the page (finding D4): the S2 non-abort clarification landed in ff78052, so commit order corroborates the bare rule's freeze only; the verdict is invariant under both readings (unconditional: 49/64 fail, also warn).
- AC2 ✓ — fresh re-run reproduces the committed TSV byte-identically (git diff empty); no MC/glmmTMB dependency (sole grep hit is the script's own comment line 3); the quoted-cell pin asserts in-script (0.676 exact; 0.6725 within the ±0.0005 band of the half-up-rendered 0.673); [O] reviewer independently recomputed 6 random cells + every headline figure from the fixture — all match. Note (D5, logged): the "ROADMAP-quoted" wording refers to the candidate row absorbed at plan time; the figures live on fallback-on-abort-comparison.md / D-026 lineage.
- AC3 ✓ — D-027 names each arm's disposition (searle no-GO, burch no-GO, mc warn); no replace-GO, so the merge-gate stop clause is vacuously satisfied and the D-001 fence untouched.
- AC4 ✓ — `git diff --name-only main...HEAD`: 8 files, zero under R/, tests/, man/, vignettes/.
- AC5 ✓ — air --check clean; lintr 0 (full package at T4, `lint_dir("data-raw")` 0 fresh at review); all four data-raw checkers OK fresh; INDEX line, provenance block, 9 triage rows present.

**Consistency gate:** cairn_validate all checks passed; `devtools::document()` no diff; `pkgdown::check_pkgdown()` no problems; `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors / 0 warnings / 0 notes (2m52s); NEWS — no user-visible change, no entry owed; no principle change → cairn_impact skipped.

**Fan-out:** [O] diff-bug 14 findings, [S] blame-history 0, [S] prior-review 1 (duplicate of D1 via the M111 review record). Scorer actioned 6 ≥ 80, all fixed on-branch this pass: D1 90 + P1 85 (the 5+26 taxonomy did not partition the 36 failing cells — recounted to 10 low-abort + 26 high-abort on the page, D-027, and the candidate row), D4 88 (S2 clarification commit-order caveat — recorded on the page and in AC1 evidence), D2 82 ("including gaussian" was selection-driven — family-limb sentence added everywhere the claim appeared), D8 82 (tail columns are non-abort-conditional — script header documents it), D9 82 (empty Decisions section — entry added). Return floor: none demonstrates an AC failing inside its named procedure, none is a ≥90 user-deliverable defect → fix-now, no status return. Logged sub-80 (9): D3 75 (clarification rationale sentence — fixed anyway in the D4 rewrite), D13 55 (prose "worsening with k" — fixed), D10 55 (TSV blank line — fixed), D5 40 (AC2 source attribution — noted above), D6 25 (pin tolerance intentional), D7 25 (width-ratio extremes verified at zero-abort cells, mechanism claim inapplicable), D11 25 (verify-slot deferral — resolved by this gate's clean devtools::check), D14 25 (the shape assertion runs in the derivation script), D12 10 (unticked-AC state expected under fencing).
