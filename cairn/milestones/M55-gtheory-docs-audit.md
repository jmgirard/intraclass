<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M55: gtheory-reference docs audit — historical-citation framing

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP1   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m55-gtheory-docs-audit   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [ ] AC1: In the four in-scope files (`README.Rmd`, the two named vignettes,
      `R/engine-lavaan.R`), no `gtheory` mention presents it as an installable
      package, a capability-matrix peer, or a live/reproducible comparison
      target — established by a re-grep of those files plus a reading pass,
      recorded in the work log.
- [ ] AC2: Exactly one user-facing location states plainly that `gtheory` was
      archived from CRAN (2025-03-24) and is no longer a dependency, so its
      comparison figures cite historical behavior; the other surviving mentions
      inherit or cross-reference that framing.
- [ ] AC3: The historical validation citation (agreement ≤ .001 G-coef /
      ≤ .005 D-coef, ten Hove/Vispoel et al. 2022 per `references/REFERENCES.md`)
      is retained and reads as a citation of committed reference values, not an
      instruction to re-run `gtheory`.
- [ ] AC4: `README.md` is regenerated from `README.Rmd`; both edited vignettes
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
- [ ] T4: `R/engine-lavaan.R` (L34) — reframe the engine comment as a historical
      validation citation.
- [ ] T5: Verification pass — re-grep the four in-scope files for `gtheory`;
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

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
