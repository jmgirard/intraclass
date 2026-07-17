<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M52: brms/Stan verification hardening

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP5, GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m52-brms-verification-hardening · https://github.com/jmgirard/intraclass/pull/58   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create -->

Consolidate the brms engine's offline committed-fixture verification strategy
into a standing documented asset (`data-raw/README.md`) with a mechanical
fixture↔script map guard, resolving the `DESIGN.md § Known issues` wart
(disposition "largely inherent — mitigate + document"; promoted from the
ROADMAP candidate row of 2026-07-12).

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:**

- `data-raw/README.md` — the single developer-facing statement of the strategy:
  the three inherent constraints (no Stan toolchain on CI, MCMC flake, ~2 h
  sweeps); the test-tier/skip taxonomy in `tests/testthat/test-icc-brms.R`
  (CRAN-safe fixture assertions / `skip_on_ci` live-Stan / local-only parity);
  the fixture lifecycle (seeded provenance-headed script → checkpoint →
  fixture written *before* hard assertions → committed `.rds` → test pins);
  the regeneration protocol (background job from the start, per-rep seeding,
  checkpoint resume, AV/concurrent-R contention ~doubling per-fit time,
  `devtools::check(env_vars = c(NOT_CRAN = "false"))` to keep live-Stan out of
  a check run); and the explicit 20-pair script↔fixture map (two irregular
  abbreviations: `*-multilevel.R` → `*-ml-oracle.rds`).
- A standing guard test asserting the bidirectional script↔fixture map
  (GP7); skips when `data-raw/` is absent (built package / CRAN).
- `DESIGN.md § Known issues`: strike the brms wart RESOLVED, retaining the
  inherency note (the constraint stands; it is now mitigated + documented).

**Out:**

- Regenerating any fixture or re-running coverage sweeps — the committed
  fixtures are valid; regeneration happens only when behavior changes
  (per-oracle scripts).
- Any change to the brms engine, priors, estimators, or test assertions →
  none planned; statistical changes get their own milestone.
- CI Stan toolchain setup → inherent constraint, not attempted (DESIGN GP3).
- Per-script convention lint (set.seed/fixture-path greps) → declined at the
  plan gate 2026-07-16 (brittle prose-guard risk across 20 heterogeneous
  scripts); revisit as a candidate only if the map guard proves insufficient.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] AC1: `data-raw/README.md` exists and documents all five In-scope
      elements (constraints, skip taxonomy, fixture lifecycle, regeneration
      protocol, 20-pair map); the map matches the files on disk exactly.
- [x] AC2: a standing guard test fails when the script↔fixture map breaks in
      either direction (a fixture without a mapped script, a script without a
      mapped fixture, a stale map row) — demonstrated by mutation (temporarily
      break the map, observe red, revert; M50/M51 lessons), and skips cleanly
      when `data-raw/` is absent.
- [x] AC3: the `DESIGN.md § Known issues` brms wart is struck through as
      RESOLVED in the established M49–M51 style, retaining the inherency note
      and pointing at `data-raw/README.md` + the guard test.
- [x] AC4: the active profile's verify commands run clean locally with
      `NOT_CRAN=true` (full suite incl. the new guard), plus
      `lintr::lint_package()` and `air format --check` clean.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2, T3
- AC3 → T4
- AC4 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Write `data-raw/README.md` (content per Scope In; harvest the
      operational lore currently only in oracle-script headers and
      `test-icc-brms.R` comments; include the explicit 20-pair map table and
      name the two `ml` abbreviations).
- [x] T2: Write `tests/testthat/test-brms-oracle-map.R`: an explicit named map
      (script → fixture) asserted bidirectionally complete against
      `data-raw/oracle-bayesian-*.R` and `tests/testthat/fixtures/bayesian-*-oracle.rds`
      globs; `skip_if_not(dir.exists("../../data-raw"))`-style guard for built
      packages; source comment citing this milestone + GP7.
- [x] T3: Mutation-check T2's guard (drop a map row; add a dummy fixture;
      confirm both go red; revert) — record the evidence line in the work log.
- [x] T4: Update `DESIGN.md § Known issues` (strikethrough + resolution note);
      add a pointer line in the `test-icc-brms.R` file header to
      `data-raw/README.md` as the strategy home.
- [x] T5: Run the profile verify (`NOT_CRAN=true` full local suite),
      `lintr::lint_package()`, `air format .`; fix fallout.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-16: created by /milestone-plan (promoted from the ROADMAP candidate
  row; doc home, guard scope, and wart disposition fixed at the plan gate).
- 2026-07-16: T1 done — data-raw/README.md (constraints, tiers, lifecycle,
  regeneration, 20-pair map). Minor plan correction: the ml abbreviation hits
  THREE fixtures (ml, incomplete-ml, incomplete-fixed-ml), not two.
- 2026-07-16: T2+T3 done — guard test (4 assertions; also pins the README's
  map table to the authoritative map, a minor addition strengthening AC1).
  Mutations: dropped map row FAIL 3, unmapped dummy fixture FAIL 1, README
  row tamper FAIL 1; reverted, clean run 4 PASS.
- 2026-07-16: T4 done — DESIGN wart struck RESOLVED (inherency note kept);
  test-icc-brms.R header points at data-raw/README.md.
- 2026-07-16: T5 done — NOT_CRAN=true CI=true suite: 0 fail/0 error, 1658
  pass, 23 skips (gated tiers), 1 pre-existing expected WARN (Design-3 cli
  message, no R/ code in this diff); lintr 0; air clean. Status → review.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->

Reviewed 2026-07-16. PR #58 (draft while evidence gathered).

**Criterion evidence (all fresh, by command):**
- AC1: README present (5,977 B); all five `##` sections confirmed by grep
  (constraints / tiers / lifecycle / regeneration / map); 20 map rows; map
  matches disk via the guard test's setequal assertions (4 PASS clean run).
- AC2: mutations re-run fresh at review — dropped map row FAIL 3; unmapped
  dummy fixture FAIL 1; README row tamper FAIL 1; `data-raw/` moved aside →
  2 SKIP 0 FAIL (built-package path); restored clean run 4 PASS.
- AC3: grep confirms `~~…structurally weaker~~ — RESOLVED by M52` at
  DESIGN.md:209, inherency note + README/guard pointers present.
- AC4: `NOT_CRAN=true CI=true` suite 0 fail / 0 error / 1658 pass / 23
  gated skips; `lintr::lint_package()` 0; `air format --check` clean.

**Consistency gate:** cairn_validate exit 0 (15 PASS); no principle changed
(GP5/GP7 worked-under) → cairn_impact skipped; `devtools::check(env_vars =
c(NOT_CRAN = "false"))` 0 errors / 0 warnings / 0 notes; `document()` no
diff; `pkgdown::check_pkgdown()` no problems; README.Rmd untouched by this
diff (sync verified at the M51 gate, no commits since); NEWS.md skipped —
no user-visible changes (dev docs + test guard only).

**Independent review:** [S] blame-history — no findings (all cited
ADR/milestone ids verified against the legacy record; map verified
bijective). [S] prior-PR-comments — no prior-PR evidence (only automated
Codecov comments repo-wide), clean no-op. [O] diff-bug — 4 findings, all
scored ≥80 by the [S] scorer (none excluded), all fixed on the branch:
1. (87) README-pin test vacuous against deletion of the README itself
   (file.exists skip) → gate on dir.exists + expect_true(file.exists);
   new mutation evidence: README deleted → FAIL 2; restored → 5 PASS.
2. (92) Lifecycle steps 2–3 stated as universal but false for the 5
   earliest scripts (no checkpoint; pins before saveRDS) → README now
   scopes the pattern to the 15 long-sweep scripts + explicit caveat.
3. (84) "gitignored checkpoints" false for 12/15 paths (3 literals, no
   glob; pre-existing gap, new claim) → .gitignore now globs
   data-raw/.oracle-*-checkpoint.rds (check-ignore verified).
4. (83) No-fit tier row over-claimed "none — every job incl. CRAN" →
   now notes the two Suggests-dependent skip_if_not_installed gates.
Post-fix re-verification: guard clean 5 PASS; data-raw-absent → 2 SKIP;
lintr 0; air clean.
