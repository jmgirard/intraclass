<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M55: gtheory-reference docs audit — historical-citation framing

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP1   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m55-gtheory-docs-audit · https://github.com/jmgirard/intraclass/pull/61   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Reframe every user-facing mention of the archived `gtheory` package so it reads
as a historical validation citation, and remove it from live-comparison /
installable-peer contexts, ahead of the v0.1.0 release.

## Scope
<!-- owner: plan · create/amend-via-gate -->

Context: `gtheory` was archived off CRAN 2025-03-24 and dropped as a dependency
(M42/ADR-052; gtheory-removed-from-CRAN). Its committed agreement (G-coefs
≤ .001, D-coefs ≤ .005 across 24 real designs) lives in `cairn/references/`.
Disposition: keep `gtheory` where it is a *historical validation oracle*; remove
it wherever it reads as an *installable package* or a *live comparison target*
(the capability matrix, forward-looking "reach for these tools" lists). Approach
resolved at the plan gate (2026-07-17): the user's lean — remove-as-peer, keep
the historical citation — over a minimal in-place reframe.

**In (user-facing docs + the one engine comment):**
- `README.Rmd` "Related work" (~L112–114): drop `gtheory` from the model-based-
  tools live list; regenerate `README.md`.
- `vignettes/comparison-with-other-packages.Rmd`: remove the `gtheory`
  capability-table column (L178) and reconcile the surrounding prose (L167–169
  incomplete-data parenthetical; L187–197 "two rows deserve a word"); **keep**
  the "validated against `gtheory` to within 0.001" citation (L192–193),
  reframed as explicitly historical, and attach the one archived-from-CRAN note.
- `vignettes/engines.Rmd` (L95): reframe "(GENOVA, `gtheory`) closely on real
  data" as a historical citation.
- `R/engine-lavaan.R` (L34): reframe the engine comment as a historical
  validation citation.

**Out (named, stay as-is):**
- `cairn/` internal tracking — `PRINCIPLES.md` #1 oracle example,
  `references/REFERENCES.md` registry (this *is* the committed historical
  agreement the docs cite), estimand specs M3/M5/M17 → internal, not
  user-facing; a separate internal-hygiene pass if ever wanted, not here.
- `tests/*.R` + `data-raw/*.R` provenance comments → dev-facing, already read as
  historical citations → out.
- `CLAUDE_CODE_KICKOFF.md` → frozen founding brief, historical record → out.
- Re-establishing / re-running the gtheory oracle agreement → already committed
  (M42/ADR-052); not re-litigated here.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] AC1: In the four in-scope files (`README.Rmd`, the two named vignettes,
      `R/engine-lavaan.R`), no `gtheory` mention presents it as an installable
      package, a capability-matrix peer, or a live/reproducible comparison
      target — established by a re-grep of those files plus a reading pass,
      recorded in the work log.
- [x] AC2: Exactly one user-facing location states plainly that `gtheory` was
      archived from CRAN (2025-03-24) and is no longer a dependency, so its
      comparison figures cite historical behavior; the other surviving mentions
      inherit or cross-reference that framing.
- [x] AC3: The historical validation citation (agreement ≤ .001 G-coef /
      ≤ .005 D-coef, ten Hove/Vispoel et al. 2022 per `references/REFERENCES.md`)
      is retained and reads as a citation of committed reference values, not an
      instruction to re-run `gtheory`.
- [x] AC4: `README.md` is regenerated from `README.Rmd`; both edited vignettes
      render clean; `air format --check`, `lintr::lint_package()`, and the
      spelling check (`inst/WORDLIST`) are clean.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3, T4, T5
- AC2 → T1
- AC3 → T1, T2, T4
- AC4 → T3, T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: `vignettes/comparison-with-other-packages.Rmd` — remove the `gtheory`
      capability-table column (L178) and reconcile the "two rows deserve a word"
      prose (L187–197) and the incomplete-data parenthetical (L167–169) so
      `gtheory` is no longer offered as a live/installable tool; **keep** the
      "validated against `gtheory` to within 0.001" citation (L192–193),
      reframed as historical, and attach the single archived-from-CRAN note
      (AC2's home).
- [x] T2: `vignettes/engines.Rmd` (L95) — reframe the "(GENOVA, `gtheory`)
      closely on real data" match as a historical citation.
- [x] T3: `README.Rmd` "Related work" (~L112–114) — drop `gtheory` from the
      model-based-tools list; re-knit to regenerate `README.md`.
- [x] T4: `R/engine-lavaan.R` (L34) — reframe the engine comment as a historical
      validation citation.
- [x] T5: Verification pass — re-grep the four in-scope files for `gtheory`;
      confirm no installable/peer/live-target framing remains; regenerate
      `README.md`; render both vignettes; run `air format --check`,
      `lintr::lint_package()`, and the spelling check; record the disposition in
      the work log.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-17: created by /milestone-plan (promotes the gtheory-reference docs-
  audit candidate; plan gate: gate M48 on it, remove-as-peer + keep historical
  citation, user-facing docs only).
- 2026-07-17: T1 done — comparison vignette: dropped `gtheory` capability-table
  column + incomplete-data live mention; kept the validation citation, reframed
  as historical with the archived-from-CRAN note (AC2 home).
- 2026-07-17: T2 done — engines.Rmd: "formerly the `gtheory` package" so the
  Vispoel-2022 agreement reads as a published historical citation, not a live
  target (GENOVA still carries the "conventional GT software" point).
- 2026-07-17: T3 done — README.Rmd "Related work": dropped `gtheory` from the
  model-based-tools list; `devtools::build_readme()` regenerated README.md
  (paragraph reflow only, no stranger changes).
- 2026-07-17: T4 done — engine-lavaan.R comment: "the archived `gtheory`
  package" so the Vispoel-2022 agreement reads as a historical citation
  (comment only, no logic change).
- 2026-07-17: T5 done — re-grep confirms the 3 surviving mentions (comparison
  vignette, engines.Rmd, engine-lavaan.R) all read as historical citations,
  README has none (AC1). `air format --check` clean; `lintr::lint_package()`
  no lints; both edited vignettes render clean; README.md regenerated. Test
  suite CI-parity (NOT_CRAN=true CI=true): 1712 pass, 0 fail, 0 error, 23 skip
  (the flaky live-Stan brms suite; a bare `devtools::test()` hits the known
  MCMC-noise flake, not an M55 regression). Spelling: one PRE-EXISTING flag
  (`lavaan's`, icc.Rd:159, untouched by M55) owned by M48 AC3; M55's own edits
  introduce none.
- 2026-07-17: all tasks done → status review by /milestone-implement.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

**Reviewed:** 2026-07-17 · PR #61 · branch `m55-gtheory-docs-audit` (cut from
`main` @ 9db07f3, no divergence).

### Acceptance-criteria evidence (fresh)

- **AC1** ✓ — re-grep of the four in-scope files: `README.Rmd` 0 matches; the 3
  surviving mentions all read as historical citations, none as installable /
  capability-peer / live target — comparison vignette L191 ("…archived from CRAN
  in…"), `engines.Rmd` L95 ("…formerly the `gtheory` package…"), `engine-lavaan.R`
  L34 ("…the archived `gtheory` package…").
- **AC2** ✓ — one archived-from-CRAN note (comparison vignette L191: archived
  March 2025, not a dependency); a matching NEWS "Documentation" bullet added at
  the consistency gate.
- **AC3** ✓ — the historical validation citation is retained and framed as
  committed reference values ("…agreeing to within 0.001; those committed
  reference values live in the package's reference notes"); `engines.Rmd` /
  `engine-lavaan.R` cite the Vispoel-et-al.-2022 agreement, not a rerun.
- **AC4** ✓ — README.md regenerated via `build_readme()` (paragraph reflow only,
  no stranger changes); both edited vignettes render clean; `air format --check`
  clean; `lintr::lint_package()` no lints; tests (NOT_CRAN=true CI=true):
  1712 pass, 0 fail, 0 error, 23 skip. Spelling: only the PRE-EXISTING `lavaan's`
  (icc.Rd:159, untouched by M55, owned by M48 AC3) — M55 introduces none (an
  "installable" flag from the first NEWS draft was reworded away).

### Consistency gate

- `cairn_validate.py` exit 0; coverage-complete PASS.
- Toolchain (r-package `consistency-gate`): `devtools::document()` no
  generated-file drift; README.md in sync; `pkgdown::check_pkgdown()` no
  problems; NEWS "Documentation" entry present; no new top-level package files.
  Full `R CMD check` → the PR #61 CI matrix (the authoritative cross-platform
  run; the local `devtools::check()` has known Courier-PDF / brms-env infra
  flakes per repo lessons).
- No `DESIGN.md` principle changed (GP1 is worked-under, not modified) →
  `cairn_impact` skipped.

### Independent review (three lenses + scorer)

- **[O] diff-bug (Opus):** No findings. Verified the capability table stays
  well-formed after the column drop (5 cols, 6 rows) and "Two rows deserve a
  word" still maps to real rows; all 3 surviving mentions historical.
- **[S] blame-history (Sonnet):** No findings. Confirmed the column removal is a
  plan-gated continuation of ADR-052's citation-only disposition (not a silent
  undo); validation citation retained + cross-checked against REFERENCES.md;
  no test asserts on removed content; all out-of-scope `gtheory` survivors are
  intended; DESCRIPTION has no `gtheory` dep (consistent with the new wording).
- **[S] prior-PR comments (Sonnet):** No prior-PR evidence — the touched files'
  merged PRs carry only Codecov bot comments, no human review points. Clean
  no-op.
- **Scorer:** no findings to score (all three lenses clean) → no-op.
- Dropped cosmetic item (both statistical lenses, surfaced per IP3): one
  long comment/prose line (`engine-lavaan.R:34`, `engines.Rmd:95`) — excluded,
  `.lintr` sets `line_length_linter = NULL` and `air` owns layout (lintr clean).

**Verdict:** all four acceptance criteria verified with fresh evidence;
consistency gate green; zero actionable review findings. Ready to merge on
CI-green + user approval.
