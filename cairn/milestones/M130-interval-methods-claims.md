<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M130: Back the interval-methods vignette's claims, and read it through

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** M129   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP5   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m130-interval-methods-claims`   <!-- owner: implement (branch) / review (PR URL) · create -->

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
      returns (39 on 2026-08-21) states a claim that is (a) backed by a
      test in `tests/testthat/test-vignette-claims.R`; (b) backed by an
      existing test elsewhere under `tests/testthat/`, cited in the work
      log by file, test name, and the expectation that asserts the claim,
      with that expectation inverted once and shown to red; (c) rendered
      live by an evaluated chunk whose printed output carries the claimed
      quantity itself — a chunk rendering the inputs to a comparison the
      prose then makes does not discharge the line; (d) source-cited with
      a `citekey (p. N)` pointer; (e) reworded so the quantifier is gone;
      or (f) an incidental match — the matched substring sits inside a
      code chunk, or is not a quantifier over package behaviour — with
      the substring quoted in the work log and the reason given.
      Dispositions are recorded in the work log keyed by the matched
      line's quoted text, its line number provenance only, and are
      verified against a re-run of the sweep on the final file: that
      run's lines are the domain, and no more than 6 of them may take
      (f). The promise is exactly what this sweep returns; it is not a
      claim about every claim in the file.
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

- [x] T1: Run the quantifier sweep; tabulate all 39 lines with a proposed
      disposition each before writing any test.
- [x] T2: Write the claims tests RED-first, extending the existing per-vignette
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
- 2026-08-21: /milestone-implement started; branch `m130-interval-methods-claims` cut from `main` at 5becdd8.
- 2026-08-21: AMENDMENT (substantive, mini gate, user selected "Amend AC1"): AC1's disposition list rewritten. It admitted only four dispositions, and 23 of the 39 swept lines fit none — 20 lines restate the M113/M116 studies already pinned line-by-line by `tests/testthat/test-doc-skew-caveat.R`, and 3 match incidentally. AC1 now admits (a) a test in `test-vignette-claims.R`, (b) an existing test elsewhere cited by file/test/expectation with that expectation inverted to red, (c) a live chunk whose output carries the claimed quantity itself, (d) a `citekey (p. N)` cite, (e) reword, (f) an incidental match capped at 6 of 39. AC2-AC6 and Scope untouched; AC3 untouched because (b)'s inversion requirement subsumes the probe it would have added.
- 2026-08-21: criteria audit of the amended AC1 ran in FULL mode (user-facing tier), fresh-context [O] reader that did not author the wording. Six findings, four repaired into the text before writing: the incidental disposition was vacuously satisfiable (all 39 lines could take it; only line 289 is actually inside a code chunk) — fenced and floored per GP9; two dispositions were properties of the work log rather than the deliverable — the existing-test one now requires a cited expectation inverted to red; the ledger's line numbers go stale under AC5's own link insertions — the ledger is now keyed by quoted text with the review-gate re-run as the domain; the live-render disposition admitted a chunk that renders a comparison's inputs without asserting the comparison — narrowed. The reader also corrected a citation: `IP4` is cairn's id, not this repo's (`D-020 Amendment 3`), and confirmed D-029 puts a shipped vignette outside D-021's door.
- 2026-08-21: T1 sweep re-run: 39 lines, matching plan's count. Proposed disposition (a) — new test in `test-vignette-claims.R`, 16 lines: 19 "every", 20 "never", 63 "every", 64 "only", 113 "exactly", 114 "each", 122 "only", 124 "only", 125 "both", 140 "both", 223 "all", 249 "never", 262 "any", 263 "any", 266 "each", 267 "never".
- 2026-08-21: T1 proposed disposition (b) — already pinned by `tests/testthat/test-doc-skew-caveat.R`, 20 lines: 69 "only", 77 "all", 85 "only", 86 "always", 88 "both"/"every", 96 "every", 99 "never", 178 "every", 181 "only", 183 "only", 188 "all"/"both"/"only", 191 "each", 192 "only", 195 "only", 199 "always", 203 "both", 207 "only", 209 "every", 211 "every", 217 "every"; per-line file/test/expectation citations and their inversion runs land in T2/T3.
- 2026-08-21: T1 proposed disposition (f) — incidental, 3 lines (cap 6): 42 "full" in "a full refit per resample" (modifies "refit", not a quantifier over package behaviour); 214 "all" in the idiom "most of all"; 289 "each" in the chunk expression `rep(seq_len(n_r), each = n_s)` (inside a code chunk). No line proposed for (c), (d) or (e).
- 2026-08-21: editorial read finding (user selected "Reword to what runs"): line 57's "the upper bounds coincide" is false against its own chunk. Executing `ci-bootstrap`'s calls at their own `boot_samples = 999, seed = 1` and `%.2f` rendering gives MC [0.05,0.71]/[0.18,0.91]/[0.34,0.93]/[0.67,0.98] against bootstrap [0.02,0.72]/[0.09,0.91]/[0.15,0.90]/[0.41,0.97] — only ICC(A,k) coincides, and two upper bounds run lower rather than higher. Reworded in T5.
- 2026-08-21: T2 added nine tests attributed to `interval-methods.Rmd` in `tests/testthat/test-vignette-claims.R`, discharging all sixteen disposition-(a) lines plus AC2's three named topics: intervals on every coefficient; `ci_method` selects the interval not the estimator; the opt-in set enumerated from the validator's own accepted-value message (not a hand list) and each member's classed off-fence abort; bootstrap availability across designs and engines; `"npbootstrap"` alone on unbalanced one-way; seed-sensitivity and `conf_level` monotonicity; the `ci-bootstrap` chunk's own comparison at its own 999 resamples; the under-coverage caveat's behavioural half (a chi-square(1) subject-effect fit returns with no warning and no widening); the shared Spearman-Brown image; the zero-between-variance `"burch"`/`"searle"` asymmetry; and the `"mpl"` fences including its three calibrated `conf_level` values. Suite `NOT_CRAN=true CI=true`: 0 failures, 8351 passing (8263 before). `air format --check .` clean; `pkgdown::check_pkgdown()` clean.
- 2026-08-21: T2 found two false claims in the article while backing it, both corrected in the vignette (the second is a new finding, not the one raised at the gate). Line 57 "the upper bounds coincide" — executing its own chunk leaves only ICC(A,k) coinciding at the chunk's own two-decimal rendering, and two upper bounds run lower rather than higher. Line 64 "`\"lavaan\"` supports Monte-Carlo only" — `R/engine-lavaan.R:119` is a parametric-bootstrap factory (M21 Slice 1, ADR-031) and `R/icc.R:276-280` already documents it; measured: `engine = "lavaan", ci_method = "bootstrap"` returns rows tagged `method == "bootstrap"` differing from the Monte-Carlo endpoints by 12%, while the same call on `ratings_incomplete` aborts `intraclass_unsupported`. The vignette now states what `?icc` states. Both rewordings are backed by the T2 tests; T5's ledger records them under disposition (e).
- 2026-08-21: T2 minor amendment — the two rewordings above were made in T2 rather than T5, because the tests written in T2 are what back the corrected wording; T5 keeps the glossary linking and the remainder of the editorial read.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
