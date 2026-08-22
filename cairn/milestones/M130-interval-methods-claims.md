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
- [x] T3: Planted-perturbation runs, three forms per added test.
- [x] T4: Enumerate the link targets; build the site; resolve each anchor
      against the emitted HTML.
- [x] T5: Glossary-term intersection, first-use linking, and the editorial
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
- 2026-08-21: T3 planted 33 perturbations — three forms (changed expected numeral, inverted comparison direction, changed `ci_method` argument) against each of the 11 tests T2 added — one at a time, each run with the file restored afterward. 33 of 33 reddened; none survived. Harness and per-run verdicts: `scratchpad/run-perturb.py`, `perturbations.json`, `perturb-results.txt` (session-local, not committed); the anchors are the test lines themselves.
- 2026-08-21: T3 AC1(b) verification found the T1 ledger's disposition-(b) claim WRONG for half its lines. A fresh-context [S] reader mapped all 20 to `tests/testthat/` and returned 9 strict matches (81, 100, 103, 182, 185, 211, 213, 215, 221), 1 partial (187 — the smaller grid's exclusion of the top true-ICC level is asserted, but not that its levels are only the two lowest), and 10 with nothing asserting them (73, 89, 90, 92, 192, 195, 196, 199, 203, 207). Spot-checked and confirmed: line 92's "2 raters covered worse than 5" is true on the fixture (16 of 16 paired cells) but untested. The 11 affected lines move from disposition (b) to (a) or (d), which is why T3 grew five tests rather than only running inversions.
- 2026-08-21: T3 added five tests over the committed study fixtures for the moved lines: the near-normal/uniform families under-cover only in high-abort cells; two raters cover worse than five in every paired cell (and abort more, the article's reason it is not a recommendation); the smaller grid carries only the two lowest true-ICC values; the between-grid pooled gap closes by more than half on the shared design points and leaves a remainder, with exactly two of the sixteen shared cells agreeing to within 1e-9 and the other fourteen differing by 1e-4 to 8.3e-3; and the two subject-effect grids' normal error draw, read from the M116 generator's own asserted header. Line 207 takes disposition (d) instead — the vignette now cites `burch2011 (§3, eq. 18, pp. 1023–1024)`, the anchor `cairn/references/burch2011.md:113` carries. Suite: 0 failures, 188 passing in this file.
- 2026-08-21: T3 also settled the two suite warnings seen at T2: both are pre-existing and outside this branch's diff — `test-icc-lavaan-multilevel.R:402` (lavaan Heywood fit) and `test-icc-type-vector.R:286` (glmmTMB non-positive-definite Hessian).
- 2026-08-21: T4 built the site (`pkgdown::build_site()`, exit 0) and resolved every link target against the emitted HTML. The sweep now returns 17 unique targets, not the 14 AC4 records as its dated count — T5's glossary linking added `#consistency`, `#reml` and `#variance-component`; AC4's promise is over what the grep returns, so the domain is the 17 and the parenthetical stands as provenance. Resolutions: 2 in-page anchors (`#the-opt-in-boundary-robust-methods`, `#when-the-default-under-covers`) against `docs/articles/interval-methods.html`; 1 cross-vignette anchor (`engines.html#a-bayesian-engine-brms`); 1 bare page (`glossary.html`); 13 glossary anchors. No `man/` topics and no URLs among them.
- 2026-08-21: T4 found one BROKEN link, pre-existing and not added by this milestone: `glossary.html#confidence-interval-vs.-credible-interval` (article line 322) resolves to no heading — pkgdown emits `confidence-interval-vs--credible-interval` for `## Confidence interval vs. credible interval`, mapping the period to a hyphen rather than keeping it. It was the article's only referrer (`git grep` over `vignettes/`, `R/`, `README.Rmd`). Corrected; all 17 targets then resolved against the built HTML.
- 2026-08-21: T5 AC1(b) inversion runs — each cited expectation inverted once, alone, with the file restored after each. All 10 reddened, none survived: L83 `test-doc-skew-caveat.R:34` "the caveat's cells are the ones the fixture measures as failing" (`expect_equal(worst$coverage_nonabort, 0.6725)`); L102 `:51` "both classical opt-ins also under-cover in every one of those cells" (`expect_lt(row$coverage_uncond, 0.93)`); L105 `:77` "burch's worst measured cell is the one the corrected docs name" (`expect_equal(worst$coverage_uncond, 0.6655)`) and `:169` "the caveat quotes only methods the fixture measured" (`expect_setequal(unique(f$method), c("mc", "searle", "burch"))`); L185 `:1696` (`expect_true(all(w$rho[!(w$burch_narrower %in% c(TRUE, "TRUE"))] == 0.6))`); L188 `:1699` "the rater count is confounded with the subject count, marginally" (`expect_true(all(w$k[w$n == 2] == 10))`); L215 `:2335` "every residual statement the walk finds states what three grids measure" (`expect_true(grepl(templates[[tm]], text, fixed = TRUE), ...)`); L217 `:2368` "the residual clause's direction is what the third grid measures" (`expect_true(all(f$median_ratio[f$dist == d] > 1), ...)`); L219 `:2398` "the residual clause's figure is the fixture cell it names" (`expect_true(sh$ok(parts(true_cell)))`); L225 `:2049` "the replacement searle/burch comparison holds on the fixture" (`expect_gt(searle_closer, nrow(s) / 2)`).
- 2026-08-21: T5 AC1 FINAL LEDGER, keyed to a re-run of the sweep on the final file — 40 lines (39 at plan time; the T2 rewordings added two matched lines and removed one). Disposition (a), backed by a test in `tests/testthat/test-vignette-claims.R`, 27 lines: 19 "every", 20 "never", 61 "all", 67 "every", 69 "only", 75 "only", 91 "only", 92 "always", 94 "both"/"every", 119 "exactly", 120 "each", 128 "only", 130 "only", 131 "both", 146 "both", 190 "only", 195 "all"/"both"/"only", 198 "each", 199 "only", 202 "only", 206 "always", 231 "all", 257 "never", 270 "any", 271 "any", 275 "each", 276 "never".
- 2026-08-21: T5 AC1 FINAL LEDGER continued. Disposition (b), an existing expectation cited above and inverted to red, 9 lines: 83 "all", 102 "every", 105 "never", 185 "every", 188 "only", 215 "only", 217 "every", 219 "every", 225 "every". Disposition (d), source-cited in the article, 1 line: 210 "both", now carrying `(Burch 2011, §3, eq. 18, pp. 1023–1024)`, the anchor `cairn/references/burch2011.md:113` holds. Disposition (f), incidental, 3 lines of the 6 permitted: 42 "full" in "a full refit per resample" (modifies "refit"; no quantifier over package behaviour), 222 "all" in the idiom "most of all", 298 "each" in the chunk expression `rep(seq_len(n_r), each = n_s)` (the only matched line inside a code chunk). No line took (c) or (e); 27 + 9 + 1 + 3 = 40.
- 2026-08-21: T5 AC5 glossary ledger — the 32 `##` headings of `glossary.Rmd` looped against the article give 13 terms appearing verbatim in its prose (a 14th, "Absolute agreement", occurs only inside a pasted transcript block and is not linkable). Ten are linked to their glossary anchor on first use: Burch interval, Consistency, Credible interval (the intro's `[**credible**](glossary.html#credible-interval) interval`, the link text splitting the phrase), Exact-F interval, Monte-Carlo interval, Posterior mode (MAP), REML, Variance component, Zero-variance boundary, and the in-page targets. T5 added the links for Consistency, REML and Variance component, which had none.
- 2026-08-21: T5 AC5 ledger — three terms are deliberately NOT linked on first use, the reason AC5 asks for. "Parametric bootstrap", "Transformed bootstrap-*t*" and "Modified profile likelihood" first appear in the opening signpost paragraph, which already carries four links in ten lines and closes by pointing at the glossary wholesale ("Terms are defined in the [*Glossary*](glossary.html)"); each is glossary-linked at the section that defines its use instead, so the term is reachable at the point a reader needs it rather than in a list of names. A fourth, "Engine", is used throughout as an ordinary noun rather than as the glossary's technical term, and the article already links the *Estimation engines* article where the concept is at stake; linking every occurrence would be noise.
- 2026-08-21: T5 editorial read of the remaining prose found no further false or unbacked claim beyond the three already corrected (the two at T2, the broken anchor at T4).
- 2026-08-21: T6 `R CMD check --as-cran` at `NOT_CRAN=false` FAILED the branch with 2 ERRORs, and both were mine. Adding `(Burch 2011, §3, eq. 18, pp. 1023–1024)` at article line 210 put page and equation numbers inside an M117 width neighbourhood, where every digit must be a canonical measured figure or allowlisted: `test-doc-skew-caveat.R` reported `installed/vignette:interval-methods.Rmd #2: figure(s) in no canonical shape and not allowlisted: 3, 1023, 1024` and `#1: no verbatim 'residual' clause`. The guard is working as designed — keeping unmeasured figures out of a width claim is what it is for — so widening its allowlist to admit 3, 1023 and 1024 was refused as weakening a deliberate guard to fit prose, and as the records-apparatus class this milestone's Scope puts Out.
- 2026-08-21: T6 SUPERSEDES the T3 and T5 ledger entries' disposition of line 210. Disposition (d) is unavailable to it — no page pointer can sit in that paragraph — and no existing test asserts the sentence (`git grep` finds "measuring with both the subject effects" only in this vignette). It therefore takes (e): reworded to "measuring with the subject effects and the errors alike drawn from the studied family", same meaning, quantifier gone, no figures added. The line consequently leaves the sweep.
- 2026-08-21: T6 both failures were invisible to `devtools::test()`, which ran green throughout T2-T5. They fire only on the walk's `installed/` leg, which exists once the vignette is installed — i.e. under `R CMD check` and nowhere else. A local-suite-only gate would have shipped this.
- 2026-08-21: T6 AC1 FINAL LEDGER, superseding the T5 entries after the line-210 reword. The sweep re-run on the final file returns 39 lines (line 210 left the domain; line identities are otherwise unchanged, the reword being net-zero on line count): (a) 27 lines — 19, 20, 61, 67, 69, 75, 91, 92, 94, 119, 120, 128, 130, 131, 146, 190, 195, 198, 199, 202, 206, 231, 257, 270, 271, 275, 276; (b) 9 lines — 83, 102, 105, 185, 188, 215, 217, 219, 225, each cited and inverted to red in the T5 entry; (f) 3 lines of the 6 permitted — 42, 222, 298. No line takes (c) or (d). 27 + 9 + 3 = 39.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
