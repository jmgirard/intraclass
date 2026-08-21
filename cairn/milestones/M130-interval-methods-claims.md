<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M130: Back the interval-methods vignette's claims, and read it through

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** M129   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP5   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create -->

Give `interval-methods.Rmd` — the 374-line article carrying every `ci_method`
claim, and the only live-code vignette with no claims test — the numeric
backing and the editorial read the other six already have.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**Surface tier: user-facing** — the deliverable is a shipped vignette.

**In:** backing the article's quantified claims with tests in
`tests/testthat/test-vignette-claims.R`; resolving its 14 link targets; linking
its glossary terms; the editorial prose read the plan gate folded in here rather
than into a separate milestone.

**Out:** the four brms transcript blocks and the two brms prose sections →
M129, which lands first; `glossary.Rmd`'s own definitions → untouched, this
milestone links to them and does not rewrite them; hardening
`data-raw/check-mpl-doc-claims.py`, whose promotion condition this milestone
fires → stays a ROADMAP candidate, being a checker over the repo's own records
and the checker-regress shape; the other six vignettes' prose → M48's check pass.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: Every line that
      `grep -nE '\b(any|each|every|all|only|both|exactly|never|always|full)\b' vignettes/interval-methods.Rmd`
      returns (39 today) states a claim that is backed by a test in
      `tests/testthat/test-vignette-claims.R`, rendered live by an evaluated
      chunk, source-cited with a `citekey (p. N)` pointer, or reworded so the
      quantifier is gone. Each line's disposition is recorded in the work log
      with its line number. The promise is exactly what this sweep returns; it
      is not a claim about every claim in the file.
- [ ] AC2: `tests/testthat/test-vignette-claims.R` gains tests attributed to
      `interval-methods.Rmd` covering the Monte-Carlo vs parametric-bootstrap
      comparison, the under-coverage caveat, and each opt-in method the article
      names as reachable (`"npbootstrap"`, `"searle"`, `"burch"`, `"mpl"`), run
      on the article's own data. `grep -c 'interval-methods' tests/testthat/test-vignette-claims.R`
      returns 0 before this milestone.
- [ ] AC3: For each test AC2 adds, a planted perturbation of each of these
      forms reds it: a changed expected numeral, an inverted comparison
      direction, and a changed `ci_method` argument. Each run is logged.
- [ ] AC4: Every link target that
      `grep -oE '\]\([^)]+\)|<https?://[^>]+>|\]\[[^]]+\]' vignettes/interval-methods.Rmd`
      returns (14 unique today) resolves — an in-page or cross-vignette
      `#anchor` to a heading `pkgdown::build_site()` actually emits in the built
      HTML, a `man/` topic to an installed topic, a URL to a live URL — with
      each target and its resolution recorded in the work log.
- [ ] AC5: For every term that `grep -n '^## ' vignettes/glossary.Rmd` returns
      (32 headings) and that appears verbatim in `vignettes/interval-methods.Rmd`
      — the intersection enumerated by looping the 32 headings against the
      article — the article links that term to its glossary anchor on first use,
      or the work log records why it does not.
- [ ] AC6: `NOT_CRAN=true CI=true devtools::test()` 0 failures;
      `air format --check .` clean; `R CMD check`'s raw `Status:` line no worse
      than main's; `pkgdown::check_pkgdown()` and `build_site()` clean;
      `urlchecker::url_check()` all-correct; `cairn_validate` exit 0.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T5
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Run the quantifier sweep; tabulate all 39 lines with a proposed
      disposition each before writing any test.
- [ ] T2: Write the claims tests RED-first, extending the existing per-vignette
      block idiom in `tests/testthat/test-vignette-claims.R`.
- [ ] T3: Planted-perturbation runs, three forms per added test.
- [ ] T4: Enumerate the link targets; build the site; resolve each anchor
      against the emitted HTML.
- [ ] T5: Glossary-term intersection, first-use linking, and the editorial
      prose read; reword the quantified lines T1 dispositioned as reword.
- [ ] T6: Full gate-lite sweep.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-21: created by /milestone-plan (pre-M48 CRAN-readiness slate; user selected this item, and chose at the plan gate to fold the vignette prose read into the milestones already touching each vignette rather than give it its own).
- 2026-08-21: criteria audit ran in FULL mode (user-facing tier), two rounds, fresh-context [O] reader. Round 1 found AC1-as-drafted unsatisfiable — it named `data-raw/enumerate-generalizing-claims.py`, whose `REF_DIR` is hardcoded to `cairn/references` (`:37`, consumed `:129`) and which takes no path argument (`:283-290`), so it can never return a claim from a vignette; AC5-as-drafted vacuous — `grep -c '^###' vignettes/glossary.Rmd` returns 0, the headings being `##`; AC4-as-drafted resting on `urlchecker` where the article has zero URLs among its 14 targets; AC3 varying probe location but not form. Round 2 found AC2's stated verification count wrong (the grep returns seven lines, one of which, `comparison.Rmd`, is a test-name prefix and not a file) and flagged AC5's "uses" as unenumerated. All fixed before writing.
- 2026-08-21: plan gate chose the M72/M128 quantifier sweep as AC1's enumerator over the M74 generalizing-claim script, because the M74 script is scoped to `cairn/references/` and disclaims claim-truth by its own docstring (`:12-14`); falsified by a false claim in this article carrying none of the ten quantifiers.
- 2026-08-21: plan gate chose leaving `data-raw/check-mpl-doc-claims.py` unhardened over promoting its candidate row, whose condition this milestone's MPL doc-surface change fires, because widening an existing checker over the repo's own records is the checker-regress shape and D-021 bars the class; falsified by a user reaching a false MPL claim the checker's current net misses.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
