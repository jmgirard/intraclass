<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below.

     DRAFTING BUDGETS (M99) — guidance, not a gate; the only size check that
     can fail is cairn_validate's <150 over the plan-owned body.
     Goal 7 · Scope 26 · AC 28 · Coverage 11 · Tasks 25 — each the measured p75
     over 99 milestone files, so three drafts in four already fit, and the
     fourth is the one that thrashed.
     ## Decisions reserves nothing: D-074 made it cap-exempt, so it costs the
     budget nothing and plan still spends none of it.
     (Redistributing the ≥21 lines it used to reserve is a ROADMAP candidate,
     deliberately not done at M118.) Together with this preamble they fit
     under the cap with room to spare — the counter prints the running total,
     so no figure here describes this block's own length (it would change each
     time the block was edited, and drifted twice when it did). Every figure is
     measured, never assumed (D-049). /milestone-plan step 4 names the counter. -->
# M106: The opt-in `ci_method` values are documented in the vignettes

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m106-optin-ci-method-vignette   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Document the four opt-in interval methods — `ci_method = "npbootstrap"`,
`"searle"`, `"burch"`, `"mpl"` — in `vignettes/interval-methods.Rmd` and the
glossary, so a user can choose an interval method without reading `?icc`'s
Details end-to-end.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** four new subsections in `interval-methods.Rmd` (fence, determinism,
`conf_level` set, `unit` behavior, when to reach for it — sourced from the
`R/icc.R` roxygen, compressed never contradicted); the lead-in re-scoped to
name them; live-evaluated example chunks (`ratings` for the one-way trio;
a seeded synthetic balanced two-way dataset for `"mpl"`, which no shipped
dataset serves — its κ_m grid needs ≥10 subjects); four glossary entries +
cross-links; `data-raw/check-mpl-doc-claims.py` scope extended to the new
MPL subsection with fixture rows for its claim candidates, self-test scope
kept equal to the live check's.

**Out:** the checker-hardening candidate (recall vocabulary, self-test
injection, brittle anchors) → stays a ROADMAP candidate row, re-deferred
deliberately at this plan gate; README / other vignettes → untouched; any
runtime behavior change → none (docs-only milestone); a new standalone
vignette → rejected at the gate in favor of extending `interval-methods.Rmd`.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1: `vignettes/interval-methods.Rmd` has one subsection per opt-in
      method (`"npbootstrap"`, `"searle"`, `"burch"`, `"mpl"`), each stating
      five things: the supported design (the method's fence), determinism
      (closed-form or seed-dependent), any `conf_level` restriction (or that
      none exists), `unit` behavior including the numeric-`unit` projection,
      and when to reach for it over the default. Verified by a per-subsection
      five-item checklist recorded in the Review section, each item anchored
      to its subsection heading plus a short quoted phrase (never a bare line
      number).
- [ ] AC2: the vignette's lead-in paragraph no longer scopes the article to
      the Monte-Carlo/bootstrap/posterior trio — it names the opt-in methods
      and routes to their subsections.
- [ ] AC3: the new MPL subsection is inside `data-raw/check-mpl-doc-claims.py`'s
      swept doc scope; every claim candidate the script's own enumerator
      reports in that scope has a row in the committed fixture; the self-test's
      scope set equals the live check's (no hardcoded stale duplicate); and
      both the checker and its self-test exit 0.
- [ ] AC4: `vignettes/glossary.Rmd` has an entry for each of the four methods,
      and the new interval-methods subsections link to them via the existing
      `glossary.html#<anchor>` idiom.
- [ ] AC5: all new example chunks evaluate live at vignette build time
      (guarded by `requireNamespace("glmmTMB", quietly = TRUE)` like the
      existing `ci-bootstrap` chunk); the `npbootstrap` chunk — the only
      method taking a `seed` — pins an explicit seed and `boot_samples`, and
      the mpl data-simulation chunk calls `set.seed()`; and the doc gate
      passes: vignettes build cleanly, `pkgdown::check_pkgdown()` +
      `build_site()` clean, `air format --check` clean,
      `lintr::lint_package()` clean.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T1
- AC3 → T3
- AC4 → T4
- AC5 → T2, T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Write the four subsections in `interval-methods.Rmd` (after the
      Monte-Carlo/bootstrap section, before the Bayesian one) and re-scope the
      lead-in (`interval-methods.Rmd:17-24`); source every fence/determinism/
      level/unit claim from `R/icc.R:286-431` and the Details blocks at
      `R/icc.R:480-535`.
- [x] T2: Add the example chunks: the one-way trio on `ratings` with
      `model = "oneway"` (npbootstrap pinned at the test-proven
      `seed = 1, boot_samples = 199` — `test-ci-npbootstrap.R:23-45`); mpl on
      a seeded synthetic balanced two-way dataset ≥10 subjects (pattern:
      `test-ci-mpl.R`).
- [x] T3: Extend `check-mpl-doc-claims.py`: a vignette-scope extractor for the
      new MPL subsection, fixture rows for its reported claim candidates, and
      the self-test's hardcoded `scopes0` (`:459-464`) made equal to the live
      check's scope build; run both to exit 0.
- [ ] T4: Add the four glossary entries and cross-links (idiom:
      `interval-methods.Rmd:33`).
- [ ] T5: Run the doc gate: build vignettes, `pkgdown::check_pkgdown()` +
      `build_site()`, `air format --check`, `lintr::lint_package()`; fix
      what reds.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-06: created by /milestone-plan (promotes the opt-in-`ci_method` vignette candidate; plan gate: extend `interval-methods.Rmd` over a new vignette, checker scope-extension only, glossary entries in).
- 2026-08-06: criteria audit ([O], fresh context) returned five findings, all fixed at the gate: line-number anchors → heading+quote anchors (AC1); self-test scope duplication named and required equal (AC3); "every universal claim" narrowed to the enumerator's reported candidates (AC3); "seed-dependent" enumerated as npbootstrap-only plus simulation chunks (AC5); mpl infeasible on shipped data → synthetic-data chunk (AC5, T2).
- 2026-08-06: plan gate chose extending `interval-methods.Rmd` over a new vignette because one canonical interval article beats a split topic and needs no pkgdown index change; falsified by the article growing past its siblings (~300 lines is the current ceiling, `multilevel-designs.Rmd`) or reader feedback that the article is too long to navigate.
- 2026-08-06: plan gate chose checker scope-extension over folding the hardening candidate in because the hardening defects (recall vocabulary, self-test injection, anchors) bite only under future edits and are orthogonal to writing docs; the row's fired promotion condition is answered by this deliberate re-deferral, recorded on the row; falsified by a vignette claim the token net demonstrably misses shipping unchecked.
- 2026-08-06: plan gate chose writing MPL vignette claims into the checker's scope over a write-around (no checkable claims in the vignette) because the write-around would make the vignette vaguer to keep a script simple; falsified by the scope extension proving brittle enough to red CI on innocent prose edits.
- 2026-08-06: T3 done — one `build_scopes()` now feeds the live check, the self-test, and `--list` (stronger than the equal-sets requirement: the duplicate `scopes0` is gone), a `vignette_scope()` extracts the MPL subsection prose (code chunks excluded), 4 new candidates all dispositioned `out` (each names where its claim IS settled) + 1 vignette refusal row; checker 41 candidates/0 failures, self-test green.
- 2026-08-06: T1+T2 done in one edit (prose and chunks interleave): four subsections + re-scoped lead-in + two live chunks; both chunks executed before their interpretive prose was written — the measured one-way output falsified the drafted "burch widest" reading (burch is narrowest there; the untruncated negative lower limits are the real story) and caught a silent recycling bug in the mpl table (mpl returns 2 agreement rows against montecarlo's 4; fixed with explicit `type = "agreement"`); vignette renders clean against the installed package.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
