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

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m106-optin-ci-method-vignette · https://github.com/jmgirard/intraclass/pull/114   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1: `vignettes/interval-methods.Rmd` documents each opt-in method
      (`"npbootstrap"`, `"searle"`, `"burch"`, `"mpl"`) in a dedicated
      subsection — `"searle"` and `"burch"` sharing the classical
      closed-forms subsection — each subsection stating five things per
      method: the supported design (the method's fence), determinism
      (closed-form or seed-dependent), any `conf_level` restriction (or that
      none exists), `unit` behavior including the numeric-`unit` projection,
      and when to reach for it over the default. Verified by a per-subsection
      five-item checklist recorded in the Review section, each item anchored
      to its subsection heading plus a short quoted phrase (never a bare line
      number).
- [x] AC2: the vignette's lead-in paragraph no longer scopes the article to
      the Monte-Carlo/bootstrap/posterior trio — it names the opt-in methods
      and routes to their subsections.
- [x] AC3: the new MPL subsection is inside `data-raw/check-mpl-doc-claims.py`'s
      swept doc scope; every claim candidate the script's own enumerator
      reports in that scope has a row in the committed fixture; the self-test's
      scope set equals the live check's (no hardcoded stale duplicate); and
      both the checker and its self-test exit 0.
- [x] AC4: `vignettes/glossary.Rmd` has an entry for each of the four methods,
      and the new interval-methods subsections link to them via the existing
      `glossary.html#<anchor>` idiom.
- [x] AC5: all new example chunks evaluate live at vignette build time
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
- [x] T4: Add the four glossary entries and cross-links (idiom:
      `interval-methods.Rmd:33`).
- [x] T5: Run the doc gate: build vignettes, `pkgdown::check_pkgdown()` +
      `build_site()`, `air format --check`, `lintr::lint_package()`; fix
      what reds.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-06: created by /milestone-plan (promotes the opt-in-`ci_method` vignette candidate; plan gate: extend `interval-methods.Rmd` over a new vignette, checker scope-extension only, glossary entries in).
- 2026-08-06: criteria audit ([O], fresh context) returned five findings, all fixed at the gate: line-number anchors → heading+quote anchors (AC1); self-test scope duplication named and required equal (AC3); "every universal claim" narrowed to the enumerator's reported candidates (AC3); "seed-dependent" enumerated as npbootstrap-only plus simulation chunks (AC5); mpl infeasible on shipped data → synthetic-data chunk (AC5, T2).
- 2026-08-06: plan gate chose extending `interval-methods.Rmd` over a new vignette because one canonical interval article beats a split topic and needs no pkgdown index change; falsified by the article growing past its siblings (~300 lines is the current ceiling, `multilevel-designs.Rmd`) or reader feedback that the article is too long to navigate.
- 2026-08-06: plan gate chose checker scope-extension over folding the hardening candidate in because the hardening defects (recall vocabulary, self-test injection, anchors) bite only under future edits and are orthogonal to writing docs; the row's fired promotion condition is answered by this deliberate re-deferral, recorded on the row; falsified by a vignette claim the token net demonstrably misses shipping unchecked.
- 2026-08-06: plan gate chose writing MPL vignette claims into the checker's scope over a write-around (no checkable claims in the vignette) because the write-around would make the vignette vaguer to keep a script simple; falsified by the scope extension proving brittle enough to red CI on innocent prose edits.
- 2026-08-06: defect return 2: review F1 (92, false unbalanced-exclusivity claim) hit the M130 return floor; F1/F2/F4/F5 all fixed on the branch same-session, re-verified (checker 41/0, self-test green, renders, air), status re-entered review. Defect-return count: 2.
- 2026-08-06: defect return 1: AC1 item 5 (when-over-default) had no in-subsection evidence for the classical pair — the T2 interpretation rewrite had dropped the boundary sentence; fixed on the branch (one sentence restored in the classical subsection, "near-zero-ICC boundary" not "every dataset", consistent with the burch MSA = 0 asymmetry note), vignette re-renders, checker still 41/0; re-review proceeds.
- 2026-08-06: amendment return: AC1 — "documents each opt-in method (`"npbootstrap"`, `"searle"`, `"burch"`, `"mpl"`) in a dedicated subsection — `"searle"` and `"burch"` sharing the classical closed-forms subsection" (the shipped three-subsection layout is the better writing; gated at the review mini-gate, user approved; re-review proceeds).
- 2026-08-06: T5 done, status → review — doc gate all green: `air format --check` clean, `lintr::lint_package()` 0 lints, `pkgdown::check_pkgdown()` no problems, `pkgdown::build_site()` finished clean, both touched vignettes render individually against the installed package. No R code changed (docs + data-raw checker only), so the profile's after-code-change test run was not triggered.
- 2026-08-06: T4 done — four glossary entries in alphabetical position + five References additions (Burch, McGraw & Wong, Searle, Ukoumunne, Xiao & Liu); both vignettes render and every anchor verified present in the generated HTML (the four entry ids + the parent section id the links target).
- 2026-08-06: T3 done — one `build_scopes()` now feeds the live check, the self-test, and `--list` (stronger than the equal-sets requirement: the duplicate `scopes0` is gone), a `vignette_scope()` extracts the MPL subsection prose (code chunks excluded), 4 new candidates all dispositioned `out` (each names where its claim IS settled) + 1 vignette refusal row; checker 41 candidates/0 failures, self-test green.
- 2026-08-06: T1+T2 done in one edit (prose and chunks interleave): four subsections + re-scoped lead-in + two live chunks; both chunks executed before their interpretive prose was written — the measured one-way output falsified the drafted "burch widest" reading (burch is narrowest there; the untruncated negative lower limits are the real story) and caught a silent recycling bug in the mpl table (mpl returns 2 agreement rows against montecarlo's 4; fixed with explicit `type = "agreement"`); vignette renders clean against the installed package.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

**AC1 evidence (2026-08-06).** Per-subsection five-item checklist, anchored heading + quoted phrase:
- "The transformed bootstrap-*t*": fence "serves the **one-way random design** (`model = "oneway"`), on balanced and unbalanced data alike" · determinism "the only opt-in method that takes a `seed` (and `boot_samples`)" · level "Any `conf_level` in `(0, 1)` is accepted" · unit "exact monotone Spearman-Brown image of the ICC(1) endpoints … a numeric `unit` (a D-study projection) is restricted to balanced data" · when "Reach for it for boundary robustness — an interval that exists where the Monte-Carlo default aborts".
- "The classical closed forms" (searle + burch, shared per the gated AC1 amendment): fence "for the **balanced one-way random design**" · determinism "no resampling, so `mc_samples`, `boot_samples`, and `seed` do not apply and no `std.error` is reported" · level "Any `conf_level` in `(0, 1)` is accepted" · unit "both project ICC(k) — and a numeric `unit` — through the same Spearman-Brown image" · when "Their value over the default is a finite, well-calibrated interval at the near-zero-ICC boundary where the Monte-Carlo default aborts" (restored at defect return 1) plus the within-pair "Prefer `"searle"` for near-normal data and `"burch"` when heavy tails are a concern".
- "The modified profile likelihood": fence "serves the **balanced, complete two-way random absolute-agreement** ICC(A,1) … aborts on any other design" · determinism "deterministic closed form — no resampling, no `seed`" · level "`conf_level` must be 0.90, 0.95, or 0.99" · unit "ICC(A,k) and any numeric-`unit` projection its pole-safe Spearman-Brown image" · when "returns an interval at the near-zero-ICC boundary where the two-way Monte-Carlo default aborts; it is deliberately conservative … opt-in and not the default".

**AC2 evidence (2026-08-06).** Lead-in read fresh (`sed -n '18,28p'`): it names the two default frequentist methods, all four opt-in methods by name and `ci_method` string with an in-page link to the section, and the Bayesian credible interval — the montecarlo/bootstrap/posterior-only scoping sentence is gone.

**AC3 evidence (2026-08-06).** `python3 data-raw/check-mpl-doc-claims.py` → "OK: 41 claim candidates, 12 settled … 0 failure(s)" including 4 vignette candidates + 1 vignette refusal row, each `out` row naming where its claim is settled; `--self-test` → "OK — every mutation reds, baseline green". Scope parity is structural, stronger than equal-sets: the former hardcoded `scopes0` duplicate is deleted and one `build_scopes()` feeds the live check, the self-test, and `--list`.

**AC4 evidence (2026-08-06).** Built site greps: 4/4 entry ids present in `docs/articles/glossary.html` (`burch-interval`, `exact-f-interval`, `modified-profile-likelihood`, `transformed-bootstrap-t`); 4/4 `glossary.html#<anchor>` links present in `docs/articles/interval-methods.html`; the parent section id the entries link back to is present (1/1).

**Fresh-context review (2026-08-06).** Three lenses ([O] diff-bug, [S] blame-history, [S] prior-review — the last found no prior-review evidence regressed and an empty PR-thread probe), 12 candidates, scored by a fresh [S] scorer. Actioned (≥80), all fixed on the branch (defect return 2):
- F1 (92): the npbootstrap subsection claimed "on an unbalanced one-way design it is the one interval method available" — measured false (montecarlo returns an ordinary interval on unbalanced one-way data). Fixed: "of the four opt-in methods it is the only one that serves unbalanced one-way data".
- F2 (82): the classical subsection's categorical "wider" for Burch was contradicted by the article's own chunk output three paragraphs later. Fixed: "its width tracks the data's tail weight" (the mechanism, direction-neutral).
- F4 (88): the new glossary Burch citation copied the roxygen `@references` block, which mismatches the PDF-verified source note `cairn/references/burch2011.md` (wrong title/journal/pages). Fixed to the verified citation (*Computational Statistics and Data Analysis, 55*, 1018–1028).
- F5 (83): the rewritten lead-in called montecarlo and bootstrap "the two default frequentist methods"; only montecarlo is the default. Fixed: "the Monte-Carlo default and the parametric bootstrap".
Logged sub-80 (surfaced, not actioned): F3 (15, pre-existing roxygen "every dataset" staleness M105 left at `R/icc.R:368` — candidate row at hygiene, with F4's roxygen sibling); F6 (68, hint-machinery "names none" case unstated in section intro); F7 (35, MPL abort list mirrors the roxygen's own fence structure); F8 (25, pre-existing self-test refusal-injection weakness, inside the deferred hardening row); F9 (45, "any"-token miss inherited from pre-existing roxygen phrasing; noted on the hardening row at hygiene); F10 (20, pre-existing `out`-row quote-coverage design); F11 (40, lead-in "and when they diverge" clause dropped in an intentional AC2 re-scope); F12 (3, reviewer verification note). Post-fix re-verify: checker 41/0, self-test green, both vignettes render, `air` clean.

**Consistency gate (2026-08-06).** `cairn_validate` exit 0, all checks pass (the long-standing `dangling id tokens` advisory now reports OK — the plugin shipped its legacy-id tolerance today, the fix this morning's candidate row asked for). Profile slot: `devtools::document()` no diff · generated files untouched by hand · README.Rmd unchanged and in sync · `pkgdown::check_pkgdown()` passes · NEWS.md gained the milestone's Documentation entry (no milestone numbers in the text) · no new top-level files · `devtools::check(env_vars = c(NOT_CRAN = "false"))` — 0 errors, 0 warnings, 0 notes, 2m35s.

**AC5 evidence (2026-08-06).** All three evaluated chunks carry `eval = requireNamespace("glmmTMB", quietly = TRUE)` (lines 44/114/166); the npbootstrap call pins `boot_samples = 199, seed = 1` (the test-proven pair); the mpl simulation chunk opens with `set.seed(88)`. Doc gate, all fresh post-fix: `air format --check` exit 0 · `lintr::lint_package()` 0 lints · `pkgdown::check_pkgdown()` no problems · `pkgdown::build_site()` finished clean · `interval-methods.Rmd` renders against the installed package. Both chunks were executed standalone during implement and their printed tables match the interpretive prose (work log, T1+T2 line).
