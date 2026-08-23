<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M133: Tell users which interval method is trustworthy for their design

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** M130   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, GP5   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m133-ci-method-trustworthiness-table` / https://github.com/jmgirard/intraclass/pull/142   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create -->

Pin, in the test suite, at least one call each `ci_method` computes an interval
for and at least one call it refuses.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**Surface tier: internal** — the deliverable is test coverage in
`tests/testthat/test-vignette-claims.R`. Nothing user-facing ships.

**In:** one supported call and one refused call per value of the `ci_method`
choice vector — the `validate_choice()` call for `ci_method` in `R/icc.R`, at
`:714-726` when last read — and their tests; plus the O-MPL `Decision` line in
`cairn/references/ORACLES.md`, corrected in place (D-021's own correct-in-place
clause).

**Out:** the seven-row trustworthiness table and its depth prose in
`vignettes/interval-methods.Rmd` → **reverted from the branch**, with its own
ROADMAP candidate row. D-021 does not bar the table: D-029 holds that user-facing
documentation plans normally. What two review rounds showed is that its cells
need deriving from the fences rather than composing from a reading; the
standing-guard route to that is the *existing* candidate row, which does need
D-021 superseded first. A `cairn/references/` page or committed checker
enumerating the surface → **not built**, the apparatus class D-021 bars and D-029
expressly retains. A full factorial over `type`/`raters`/`unit` with committed
per-combination fixtures → **not attempted**: 224 cells at the floor and
unbounded on `unit`, 32 of them forced-brms MCMC fits, against a 5 MB CRAN
package budget. Extending the M113 skew battery to `"bootstrap"`, and the two-way
heavy-tail grid → stay ROADMAP candidates on their own promotion conditions.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: For each value of the `ci_method` choice vector validated in
      `R/icc.R` (the `validate_choice()` call for `ci_method`),
      `tests/testthat/test-vignette-claims.R` runs one call the method computes
      an interval for and asserts an interval is returned, and one call it
      refuses and asserts the abort class. The `posterior` value's supported
      call requires a Stan toolchain and is gated `skip_on_ci()`/
      `skip_on_cran()`; it is verified in a run without `CI=true`. No value has
      fewer than both.
- [ ] AC2: For each value, a planted perturbation of each of these forms reds
      AC1's tests: a changed `ci_method`; a changed design argument or input
      dataset; an inverted supported/refused direction.
- [ ] AC3: `NOT_CRAN=true CI=true devtools::test()` 0 failures;
      `air format --check .` clean; `R CMD check`'s raw `Status:` line no worse
      than main's under the same command on the same machine;
      `pkgdown::check_pkgdown()` and `build_site()` clean; `cairn_validate`
      exit 0.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T6, T7
- AC2 → T4, T6, T7
- AC3 → T5, T7

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: For each `ci_method` value, run one supported call and one refused
      call and record the outcome (interval, or abort class) — ephemeral
      evidence in the work log, not a committed fixture. Cross-check each fence
      against its D-entry (D-010 npbootstrap, D-013 searle/burch, D-015 mpl,
      ADR-033 posterior/brms coupling).
- [x] T2: Write the per-value supported/refused tests, RED-first.
- [x] T3: *(superseded by T6 — this task shipped the table the descope reverts.)*
- [x] T4: Planted-perturbation runs, three forms per value.
- [x] T5: Full gate-lite sweep.
- [x] T6: Revert the vignette's `Which method serves which design` section and
      its NEWS entry. Retarget the suite's table-facing prose onto the fences
      **by procedure, not by hand-list**: grep `tests/testthat/` for
      table-referring terms (`table`, `row`, `cell`, `trustworthiness`) and
      retarget every hit, the block header's stale `R/icc.R:692-703` locator
      included. Add a ROADMAP candidate row for the table itself, leaving the
      existing standing-guard row intact.
- [x] T7: Re-run AC2's three plant forms against the retargeted blocks, then
      re-run the gate — including one suite run without `CI=true` so the
      `posterior` supported call executes. Log each planted run.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-21: created by /milestone-plan (pre-M48 CRAN-readiness slate). The user asked for confidence that everything is statistically correct and chose "audit only, fix what it finds" at the plan gate; this milestone is that choice with the audit as the means and shipped user guidance as the deliverable.
- 2026-08-21: criteria audit ran in FULL mode (user-facing tier), two rounds, fresh-context [O] reader, and this milestone was RE-CUT between them. Round 1 found the whole drafted scope barred by D-021/D-029 — its deliverable was a `cairn/references/` page plus a committed enumerating script, the apparatus class exactly, with no trigger in what the package computes — and found AC1's enumerator broken (`formals(icc)$ci_method` returns the single string `"montecarlo"`; the seven-value vector lives in the `validate_choice` call at `R/icc.R:692-703`), AC5's two named checkers disclaiming claim-truth by their own docstrings, and AC2/AC3 binding properties of a records page rather than of the deliverable. The re-cut moved the deliverable into the shipped vignette. Round 2 found the re-cut still failing: "committed per-combination fixtures" re-imported the apparatus D-029 warns about at `:1300`, and the declared factorial was 224 cells at its floor and unbounded on `unit` (`normalize_unit`, `R/icc.R:2691-2717`, accepts any number ≥ 1), with a large share aborting in argument validation rather than in any interval method. Re-cut again to seven rows and fourteen calls, no new fixtures, no new checker. Both re-cuts are the reason this milestone's criteria differ most from their first draft.
- 2026-08-21: plan gate chose a seven-row per-`ci_method` table over a full (ci_method × design × type × raters × unit) factorial, because the factorial is intractable at any reading and would mostly document `validate_type`/`validate_choice` rather than interval-method trustworthiness; falsified by a user meeting a refusal the seven-row fence does not predict.
- 2026-08-21: plan gate chose shipping the guidance in the vignette over building a standing test that the table matches the surface, because a guard over the repo's own records needs D-021's trigger and none exists; falsified by the table going stale against a `ci_method` fence change.
- 2026-08-22: T1 — all fourteen fence probes run on the branch (`devtools::load_all`). Supported side returns an interval for: `montecarlo` (two-way `ratings`), `bootstrap` (two-way `ratings`, 19 resamples), `posterior` (live brms fit on `ratings`, 2 chains x 1000 iter, `ICC(A,1)` [0.0380, 0.6602]), `npbootstrap` (one-way `ratings`, and unbalanced `ratings_incomplete`), `searle` and `burch` (balanced one-way `ratings`), `mpl` (the article's seeded 20x4 two-way agreement sim). Refused side aborts `intraclass_unsupported` for all seven: brms with explicit `montecarlo`; lavaan bootstrap on `ratings_incomplete`; `posterior` off brms; `npbootstrap` on two-way; `searle`/`burch` on unbalanced one-way; `mpl` on explicit consistency. Fences cross-checked against D-010 (npbootstrap), D-013 (searle/burch), D-015 (mpl) and the brms coupling at `R/icc.R:735-756` (ADR-033); no disagreement with the source fences at `R/icc.R:1598-1683`.
- 2026-08-22: implement question gate — live brms fit gated `skip_on_ci()`/`skip_on_cran()` for the posterior row's supported call (the repo's existing idiom for every live Bayesian test; CI has brms but no Stan toolchain, so that one call reports as skipped); table placed directly after the article's intro rather than as a closing summary; depth column carries a short plain-language label with the per-row anchors and caveats in prose below it. Fable escalation was offered on the depth judgments and declined.
- 2026-08-22: T2 — three test blocks appended to `tests/testthat/test-vignette-claims.R`: the six frequentist rows' supported cells (plus a lavaan-complete control for the bootstrap row, whose fence message is generic), the Bayesian row's supported cell behind a live brms fit (`skip_on_ci`/`skip_on_cran`), and all seven refused cells. Each refused call is pinned to its own fence message and differs from a passing call in exactly the one attribute the fence names; balance and completeness of `ratings` vs `ratings_incomplete` are asserted rather than assumed. `test_local(filter = "vignette-claims")` 389 passing, 0 failures, 0 skipped locally. `air format` clean.
- 2026-08-22: T3 — the seven-row table plus its caveat paragraphs ship in `vignettes/interval-methods.Rmd` as a new `## Which method serves which design` section directly after the intro. Depth read off `cairn/references/ORACLES.md`: `montecarlo` (O1/O2/O3 plus the cross-engine O-LME and O-SEM legs), `bootstrap` (O-SEM M21 Slice 1, O-SEM-ML-BOOT, O-Boot-DS, the replicate oracles' both-`ci_method` legs), `posterior` (O-Bayes, ten Hove 2020 §4.2 findings plus the committed coverage fixtures), `npbootstrap` (O-NPBoot: ukoumunne2003 Table I and ohyama2025), `searle`/`burch` (O-Classical-OW: two independent published worked examples each) all clear two or more independent checks; `mpl` (O-MPL) rests on xiao2013 alone, its kappa_m constants script-derived below rho = 0.6. Caveats stated in the reader's terms: the measured skew under-coverage for `montecarlo`/`searle`/`burch` (D-027) and `npbootstrap` (D-031, stated without figures), the unmeasured skew behaviour of `bootstrap` and `mpl`, `posterior`'s two-rater bias, and `npbootstrap`'s unbalanced-SE and ICC(k) inheritance. NEWS.md Documentation entry added. Vignette renders (`rmarkdown::render` exit 0); `air format --check .` clean.
- 2026-08-22: T4 — 21 planted perturbations (three forms x seven rows) plus an unperturbed control, each run as its own copy of the M133 test blocks at `NOT_CRAN=true`: control green, all 21 red, each for the reason its form targets. Changed-`ci_method` plants red on the `method` assertion (bootstrap, npbootstrap, searle, burch, mpl), on an unexpected abort (montecarlo -> `"mpl"`), or on a refusal that stopped refusing (posterior). Changed-design plants red on the index-set assertion (montecarlo, bootstrap, posterior) or on an unexpected abort (npbootstrap `"twoway"`, searle/burch on `ratings_incomplete`, mpl `model = "oneway"`). Inverted-direction plants red on the supported call aborting (montecarlo, posterior) or the refused call no longer throwing `intraclass_unsupported` (bootstrap, npbootstrap, searle, burch, mpl). Two assertions were added to the supported test to make design and method changes detectable at all — the row's coefficient family and its `method` label, previously checked only for the four opt-in rows. Harness ephemeral, as T1's probes; nothing committed under `data-raw/` (scope excludes a committed checker).
- 2026-08-22: T5 — gate-lite sweep clean on the branch tip. Suite at `NOT_CRAN=true CI=true`: 0 failures, 0 errors, 8590 passing, 26 skipped (one more skip than main's 25 — the Bayesian row's live brms fit). `air format --check .` clean; `devtools::document()` no diff; `pkgdown::check_pkgdown()` no problems, `build_site()` exit 0; `data-raw/check-record-claims.py` 6 claims, 0 failures; `cairn_validate` exit 0, all checks passed. `R CMD check --as-cran --no-manual` (with `_R_CHECK_CRAN_INCOMING_=false`) on `R CMD build` tarballs of the branch tip and of `git archive origin/main` (17bf072), same command and machine: both raw `Status: OK`. That command differs from M132's by `--no-manual`, which sidesteps this machine's missing `pdflatex`; under it neither tree has any condition to compare, so the branch is no worse than main's.
- 2026-08-22: review returned M133 to in-progress (defect return 1). AC1 fails: five of the seven rows misdescribe the shipped surface — the lavaan multilevel bootstrap fenced to the cluster level rather than to the fit, npbootstrap's numeric-`unit` fence omitted, montecarlo overreaching on the lavaan engine and naming a brms refusal that fires only on an explicit value, mpl's numeric-`unit` projection omitted, and burch's zero-variance clause naming an `intraclass_singular_fit` in a column otherwise about design refusals. AC3 fails: the caveat prose omits `posterior` from the methods never run on the skew study, and reports `posterior`'s two-rater point bias without its measured two-rater interval under-coverage. AC2, AC4, AC5 passed on fresh evidence. Nine further findings logged for the return, plus one pre-existing stale line in `ORACLES.md`'s O-MPL entry.
- 2026-08-22: return fixes, AC1 — five table cells rewritten against calls run, not recollection. `montecarlo` now reads "every design the package fits, whichever of the `\"glmmTMB\"`, `\"lme4\"` and `\"lavaan\"` engines fits it" (the old cell implied lavaan fits every design; one-way lavaan aborts) and its refusal is stated as explicit-only. `bootstrap` names a multilevel `\"lavaan\"` fit rather than the cluster level, matching the fit-level fence at `R/engine-lavaan.R:573-576` and the article's own existing wording. `npbootstrap` names the numeric-`unit` fence on both sides. `mpl` names the numeric-`unit` projection it admits. `burch`'s Refuses cell is now "the same as `\"searle\"`" — their design fences are identical, and the zero-between-variance stop is an `intraclass_singular_fit` already carried by the article's burch section and pinned at `test-vignette-claims.R:1547`.
- 2026-08-22: return fixes, AC3 — the never-measured-under-skew bullet now names `posterior` alongside `bootstrap` and `mpl` (D-027 and D-031 cover `mc`, `searle`, `burch`, `npbootstrap` only), and the `posterior` row and bullet state the two-rater interval under-coverage `ORACLES.md` records, not only the point-estimate bias. The `bootstrap` depth label carries the breadth gap the [O] lens found: its checks were run on the two-way random single-level design.
- 2026-08-22: return fixes, smaller findings — NEWS corrected from "Five of the seven" to six, and its two overclaims narrowed (the depth column has no call behind it; the Bayesian row's call is skipped without a Stan toolchain). Both anti-vacuity guards now compare list NAMES against the validator's own accepted set rather than counting to 7. The header comment no longer claims the `differs` field enforces anything; it records the contrast and the pinned message enforces identity. The index-family assertion is labelled (`expect_setequal()` takes no `info`, so it is the `expect_true(setequal(...))` form). `vc_mpl_sim()` is now shared with the older `\"mpl\"` fences test, which read the same seeded construction inline; that test derives its rater count from the frame. A new block runs the three extra cell claims. Pre-existing: `ORACLES.md`'s O-MPL Decision line said `conf_level = 0.95` only, superseded by M91/D-017 — corrected in place and marked.
- 2026-08-22: the M130 width-claim guard (`test-doc-skew-caveat.R`) reddened on the first draft of these fixes: writing "on a narrow set of designs" into the bootstrap depth cell put the word "narrow" beside "burch" in the same block, so the whole table read as a width statement and its `conf_level` numerals and "two raters" came back as unchecked figures. Reworded to "on a limited set of designs"; guard green (2347 passing). The guard caught a real hazard — the table sits in a file whose width claims are pinned — and nothing about the claim itself was wrong.
- 2026-08-22: gate re-run after the fixes — suite 0 failures / 0 errors / 8600 passing / 26 skipped at `NOT_CRAN=true CI=true`; `air format --check .` exit 0; `devtools::document()` no diff; `pkgdown::check_pkgdown()` no problems and `build_site()` exit 0; `check-record-claims.py` 6 claims / 0 failures; `cairn_validate` exit 0. `R CMD check --as-cran --no-manual` on a fresh branch-tip tarball: raw `Status: OK`, matching main measured under the same command earlier this session.
- 2026-08-22: review round 2 returned M133 to in-progress (defect return 2). AC1 fails again on three new cells of the same shape: the `mpl` row omits the calibration-geometry fence (12 raters, 8 subjects and 150 subjects all abort inside what the Computes cell describes), the `burch` Refuses cell rewritten to "the same as `searle`" is now false against D-022's zero-between-variance asymmetry, and the `npbootstrap` numeric-`unit` promise is unqualified where the Spearman-Brown pole refuses it. AC3 fails again on three prose inaccuracies: "three methods measured under skew" against four, the `bootstrap` evidence understated against O-SEM-ML-BOOT and O-Boot-DS, and the `posterior` two-rater coverage attributed to the published source rather than to this package's reproduction. AC2, AC4, AC5 passed on fresh evidence. Thrash trigger (b) fires — the disposition goes to the user with the plan gate's recorded alternatives.
- 2026-08-22: parked as `blocked` at the user's decision after defect return 2. **Blocker:** the seven-row table's cells are composed from a reading of the fences, and two review rounds have each found new cells that misdescribe the surface (round 1: five; round 2: the `mpl` calibration grid, the `burch` refusal equality, the `npbootstrap` numeric-`unit` promise). Unblocking needs a decision the milestone cannot take for itself — whether to derive the cells from the code by a standing guard, which the plan gate declined under D-021 with D-029 retaining the bar and whose ROADMAP candidate row requires superseding D-021 first, or to narrow what the criteria promise to what a run has confirmed. The branch `m133-ci-method-trustworthiness-table` and draft PR #142 stand as they are; AC2, AC4 and AC5 hold on round-2 evidence, AC1 and AC3 do not.
- 2026-08-22: unparked at the user's decision for a descope. `/milestone-review` reached its session start with the milestone `blocked`; the recorded blocker's decision was put to the user, who chose narrowing the milestone to its already-verified criteria over deriving the cells by a standing guard (which needs D-021 superseded first), over an override re-review, and over dropping. Status back to `in-progress` for the gated criterion-amendment protocol (`/milestone-implement` step 6) and that amendment alone; re-review follows the narrowed set. No defect-return increment — this is the disposition of return 2, not a third.
- 2026-08-23: DESCOPE amendment (gated, `/milestone-implement` step 6) executing the user's disposition of defect return 2. Criteria narrowed and renumbered: old AC1 (the shipped table) and old AC3 (the depth prose) REMOVED, their promise exiting to a ROADMAP candidate row; old AC2 → AC1, old AC4 → AC2, old AC5 → AC3. Surface tier drops user-facing → internal; the deliverable is now the fence tests alone. Not an amendment return and not a defect return — the defect-return count stays at 2.
- 2026-08-23: amendment criteria audit ran in FULL mode by a fresh-context [O] reader, twice (the tier is now internal, which earns only the reduced audit; full was run anyway rather than lighten rigor inside a descope). Round 1 returned 15 findings, round 2 — the once-round on wording the mini gate changed — returned 12. Fixed at the gate: the Goal's "so a later fence change reds rather than passing silently" universal dropped (the exemplar-vs-universal overreach both returns died on); `R/icc.R:692-703` corrected to the `validate_choice()` call, the range a hint only, after the reader measured the drift to `:714-726` inside this milestone's own life; the hand-pinned count "seven" dropped per GP8; "each planted run is logged" moved from criterion to task as a recording act; `posterior`'s `skip_on_ci()` carve-out stated, with a run without `CI=true` added to T7 and mapped, since AC3's mandated run skips it; AC2's plant-form wording matched to what T4 ran (dataset, not only design argument) and its coverage extended to T6/T7, whose retarget rewrites the very blocks T4 planted against; T3 marked superseded; T6's hand-list of table-facing prose restated as a grep procedure after the reader found four sites it missed; a candidate row for the table added, distinct from the standing-guard row; the `ORACLES.md` correction brought inside Scope In; AC3 given "under the same command on the same machine". Held deliberately: AC2 stays at three plant forms (D-118 — widening a twice-returned milestone's probe matrix is the direction the rule recommends against), and `pkgdown` stays in AC3 because T6 edits a vignette.
- 2026-08-23: Scope Out cited the wrong door and was corrected. The draft made re-shipping the table conditional on superseding D-021; D-029 (`cairn/DECISIONS.md:1271-1303`) holds D-021 governs records apparatus and expressly not user-facing documentation, which "plans normally". Only the standing-guard candidate row carries the D-021 bar.
- 2026-08-23: mini gate — the revert is bound as T6 rather than as a new AC4 (D-118: adding a criterion widens a twice-returned milestone), and AC1 holds at class-only rather than regaining the fence-message clause the descope draft had added. Recorded gap: `intraclass_unsupported` is one class across 46 abort sites and the lavaan bootstrap message is shared by three fences, so AC1 is satisfiable by a test that drops the `regexp` pins the shipped tests currently carry; the promise is what narrowed, not the checks. That gap, and AC2's unprobed axes (`unit`, the anti-vacuity enumerator), go to the table's candidate row.
- 2026-08-23: T6 — `vignettes/interval-methods.Rmd` and `NEWS.md` restored to `origin/main` byte-for-byte (`git diff origin/main --` empty for both). Test prose retargeted by the grep procedure: the sweep over `tests/testthat/` for `table|row|cell|trustworthiness` returned 40 hits, all but the M133 additions being unrelated senses (the kappa_m lookup table, grid cells, data rows), so the domain was narrowed to the branch's own added lines — 24 hits, two of them the R `table()` function. 18 edits: the block header rewritten from "the per-`ci_method` trustworthiness table" to "the per-`ci_method` fence pins", all four `test_that()` names re-anchored from "interval-methods.Rmd: the table's ..." to "icc(): ...", the loop variable `row` renamed `entry`, and every remaining "the row's cell"/"the table's row" reworded to name the method. The stale `R/icc.R:692-703` in the header corrected to the `validate_choice()` call at `:714-726`; the older `"mpl"` fences block's cross-reference at `:1625` retargeted too — a site T6's first hand-list had missed, which is why the task was restated as a procedure. ROADMAP: the standing-guard candidate row rewritten (its premise "M133 ships a seven-row table" is now false) and a second row added for the table itself, with D-029's distinction recorded — the table is not barred, only the guard is. Both files under budget: ROADMAP 54 lines / 23,996 bytes (the 24,000-byte budget was met by compressing the two new rows and the three widest pre-existing ones, main having sat 11 bytes under the ceiling). `air format --check .` clean; `cairn_validate` exit 0, all checks passed; `vignette-claims`/`doc-skew-caveat`/`ci-mpl` 0 failures at `NOT_CRAN=true CI=true`.
- 2026-08-23: T7, discovered fix — `check-references` was RED on the pushed branch tip (`data-raw/enumerate-generalizing-claims.py --check`: 1 un-triaged candidate, 1 orphan ledger row). Cause: the M133 return fixes corrected the O-MPL `Decision` line at `cairn/references/ORACLES.md:1824` in place (the `conf_level = 0.95` claim superseded by M91/D-017) without refreshing the M74 triage ledger, whose rows are keyed by a hash of the claim text — so the old key `ORACLES:1d6bed4aa7` orphaned and the corrected text enumerated as un-triaged under `ORACLES:8465c34a03`. The triage CLASS is unchanged (`OUT-oracle-pin` — the repo's own MPL verdict, not an external source-table generalization), so the row was rekeyed in place rather than reclassified. Checker now 367 candidates / 367 rows / 0 un-triaged / 0 orphan. This was live on the branch since the return fixes and is inside Scope In, which carries the `ORACLES.md` correction.
- 2026-08-23: T7 — plants re-run against the RETARGETED blocks (T4's runs were against the pre-descope text T6 rewrote). Harness ephemeral as before: the block plus its `vc_mpl_sim()` helper copied to a temp test file, one perturbation applied per run, file removed after. Unperturbed control GREEN in both modes; all 21 plants (3 forms x 7 `ci_method` values) RED. The six frequentist values ran at `NOT_CRAN=true CI=true`; `posterior`'s three ran at `NOT_CRAN=true` alone so its live brms fit executes, and that no-CI control passing is also AC1's evidence that the `skip_on_ci()` call is reached and green rather than merely skipped. Gate: suite 0 failures / 0 errors / 8600 passing / 26 skipped at `NOT_CRAN=true CI=true`; `air format --check .` exit 0; `devtools::document()` no diff; `pkgdown::check_pkgdown()` no problems and `build_site()` exit 0; `check-record-claims.py` 6 claims / 0 failures; `enumerate-generalizing-claims.py --check` 367/367, 0 un-triaged, 0 orphan; `cairn_validate` exit 0, all checks passed. `R CMD check --as-cran --no-manual` (with `_R_CHECK_CRAN_INCOMING_=false`) on `R CMD build` tarballs of the branch tip and of `git archive origin/main`, same command and machine: both raw `Status: OK`.
- 2026-08-23: descope complete; status to `review`. AC1, AC2 and AC3 are the amended criteria and are left UNTICKED — the round-2 evidence they inherit predates T6's retarget, so review verifies them on fresh evidence under AC fencing. Defect-return count stays at 2.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

**PR:** https://github.com/jmgirard/intraclass/pull/142 (draft) · reviewed 2026-08-22 at branch tip 2217c27, `origin/main` 17bf072 (branch not behind).

### Acceptance criteria

- **AC1 — FAILED.** The row set is right and the three columns are present: the
  table at `vignettes/interval-methods.Rmd:37-45` carries `montecarlo`,
  `bootstrap`, `posterior`, `npbootstrap`, `searle`, `burch`, `mpl` — the seven
  values of the `ci_method` choice vector, in source order, matching it exactly.
  (Locator drift, not a defect: that vector sat at `R/icc.R:692-703` at plan
  time and sits at `R/icc.R:714-726` today, moved by M130 and M131 roxygen
  above it; verified with `git show 6ce0088:R/icc.R`.) What fails is what the
  rows *state*. Five rows misdescribe the surface, each confirmed by running the
  call: the `bootstrap` row fences the lavaan multilevel bootstrap to the
  cluster level when the fence is on the fit (a subject-level multilevel lavaan
  bootstrap returns an interval — the passing M130 assertion at
  `test-vignette-claims.R:1265`); the `npbootstrap` row's "balanced or
  unbalanced" omits the numeric-`unit` fence (`unit = 2` on unbalanced one-way
  aborts `intraclass_unsupported`, `R/icc.R:1626-1637`, while balanced returns
  `ICC(2)`); the `montecarlo` row claims every design on the lavaan engine
  (one-way lavaan aborts `intraclass_unsupported`) and names a brms fit as
  refused when only an *explicit* `"montecarlo"` is (unset upgrades to
  `"posterior"`, `R/icc.R:735-737`); the `mpl` row omits the numeric-`unit`
  projection it admits (`unit = c("single", 7)` returns `ICC(A,7)`); the `burch`
  row's zero-between-variance clause is an `intraclass_singular_fit`, a data
  degeneracy, not the design refusal the column is otherwise about.
- **AC2 — PASSED.** All fourteen cells run and assert. Fresh run at
  `NOT_CRAN=true CI=true`: supported-cell block 50 passing / 0 failed;
  refused-cell block 10 passing / 0 failed; Bayesian-row block skipped (its live
  brms fit is gated `skip_on_ci`, the repo's idiom — it passes locally, and
  T2/T4 record its interval).
- **AC3 — FAILED.** Every row carries a depth label and every row below the top
  tier says so in shipped prose, so the criterion's form is met; two of the
  statements are false. The caveat prose names `bootstrap` and `mpl` as the
  methods never run on the skew study, but `posterior` was never on it either
  (D-027 and D-031 cover `mc`, `searle`, `burch`, `npbootstrap` only). And the
  `posterior` row reports only the two-rater point-estimate bias, omitting the
  measured two-rater interval under-coverage — the load-bearing figure for a
  table about intervals — which `ORACLES.md` records at k = 2 against k = 5.
- **AC4 — PASSED.** Re-read the T4 record and re-ran the harness's control: 21
  planted perturbations (three forms x seven rows) plus an unperturbed control,
  each as its own copy of the M133 blocks at `NOT_CRAN=true`; control green, all
  21 red, each on the assertion its form targets.
- **AC5 — PASSED.** Fresh: suite 0 failures / 0 errors / 8590 passing / 26
  skipped at `NOT_CRAN=true CI=true`; `air format --check .` exit 0;
  `devtools::document()` no diff; `pkgdown::check_pkgdown()` no problems;
  `build_site()` exit 0 (T5). `R CMD check --as-cran --no-manual` on built
  tarballs of the branch tip and of `git archive origin/main` (17bf072), same
  command and machine: both raw `Status: OK`, so no worse than main's.

### Consistency gate

`cairn_validate` exit 0, all checks passed. `data-raw/check-record-claims.py` 6
claims / 0 failures. No principle changed, so `cairn_impact` was not run.
Toolchain slot: `document()` no diff; no generated file hand-edited; README.Rmd
untouched; `check_pkgdown()` clean; NEWS.md carries a Documentation entry; no new
top-level files.

### Independent review — three-lens fan-out

[O] diff-bug, [S] blame-history, [S] prior-PR-comments, all fresh-context. The
prior-review lens reported no prior-review evidence reintroduced (the GitHub
inline-comment probe returned empty, so it read the archived `## Review`
sections for M106, M115, M130, M132 and the LESSONS lines, and cleared the diff
against every regression class they name). Findings and disposition:

- **Return-causing (AC1):** the five misdescribing rows above — [O]2 lavaan
  multilevel bootstrap fenced to the wrong axis; [O]3 npbootstrap numeric-`unit`
  fence omitted; [O]7 montecarlo overreaches on lavaan; [O]8 montecarlo's brms
  refusal is explicit-only; [O]9 mpl's numeric-`unit` projection omitted; [O]4
  burch's zero-variance clause is a different abort class and ships untested.
- **Return-causing (AC3):** [O]5 `posterior` omitted from the never-measured
  group; [O]6 `posterior`'s two-rater interval under-coverage omitted; [S]B4
  independently reached [O]6's conclusion from the other direction.
- **Fix on return, not criterion-failing:** [O]1 / [S]B1 NEWS says "Five of the
  seven" where the table says six; [O]13 NEWS's "Every cell ... backed by a pair
  of live calls" is untrue of the depth column and unconditional about the
  CI-skipped Bayesian row; [O]10 the `bootstrap` depth label is asserted across
  every glmmTMB/lme4 design but measured on one cell (no registry entry exists
  for that bootstrap; its legs are O-SEM Slice 1's known-population coverage and
  the cross-engine lavaan-glmmTMB agreement); [O]11 the anti-vacuity guards
  count 7 by coincidence (six rows plus a control) and check no names; [O]12 the
  `differs` field is documentation, not enforcement, and the header comment
  overstates it; [O]14 one assertion in the supported loop lacks `info = nm`;
  [S]B2 `vc_mpl_sim()` re-pastes the seeded construction already inline at
  `test-vignette-claims.R:1602-1615` instead of being shared with it.
- **Adjacent, pre-existing:** [O]15 `ORACLES.md`'s O-MPL Decision line still says
  `conf_level = 0.95` only, superseded by M91/D-017 ({0.90, 0.95, 0.99}); the
  vignette follows the code and is right, the registry entry is stale. Current
  knowledge, so correctable in place with the correction marked.
- **Noted, no action:** [S]B3 the milestone file cites `R/icc.R:692-703`, correct
  at plan time and moved since — plan-owned text, recorded above rather than
  edited at review.

### Round 2 (2026-08-22, branch tip b6146f7)

Re-reviewed after the return fixes. Full three-lens fan-out again.

- **AC1 — FAILED again**, three new cells, same shape as round 1: cells composed
  from a reading of the fences rather than derived from them. (a) The `"mpl"`
  row omits the calibration-geometry fence entirely — a balanced, complete,
  two-way random absolute-agreement design at 12 raters aborts
  `intraclass_unsupported` ("calibrated for 2-10 raters"), as do 8 subjects and
  150 subjects ("calibrated for 10-100 subjects"), all squarely inside what the
  row's Computes cell describes; the article's own `"mpl"` section 300 lines
  below states this grid, so the summary contradicts the prose it summarises.
  (b) The `"burch"` Refuses cell, rewritten to "the same as `\"searle\"`" on the
  round-1 return, is now false the other way: D-022 decided precisely that Burch
  at zero between-subject variance aborts `intraclass_singular_fit` while Searle
  returns an interval, and `test-vignette-claims.R:1560` pins that asymmetry.
  Their *design* fences are identical (verified: both refuse unbalanced and
  two-way); the cell does not say "design". (c) The `"npbootstrap"` Computes cell
  promises "a numeric `unit` projection on balanced data" unqualified, but
  `npb_guard_sb_pole()` refuses it where the Spearman-Brown map crosses the pole
  — on a balanced 15x3 low-ICC design `unit = 2` returns an interval while
  `unit = 50` and `unit = 500` abort.
- **AC2 — PASSED.** Fresh at the tip: the M133 blocks run 89 passing, 0 failed,
  1 skipped (the Bayesian row on CI).
- **AC3 — FAILED again**, three inaccuracies in the caveat prose. The first
  bullet says "The three methods measured under skew" while the next bullet and
  NEWS both say four (D-031 put `npbootstrap` on the same grid). The
  `"bootstrap"` bullet says its checks "were run on the two-way random
  single-level design", which understates `ORACLES.md` — O-SEM-ML-BOOT is the
  two-level lavaan bootstrap and O-Boot-DS covers multilevel and
  incomplete-subject bands. The `"posterior"` bullet attributes the two-rater
  interval under-coverage to the published source; O-Bayes records the published
  finding as near-nominal above two raters and the two-rater coverage as this
  package's own seeded reproduction.
- **AC4 — PASSED.** T4's harness re-read; the assertions it plants against are
  unchanged in kind, and the supported/refused blocks it targets still carry
  them.
- **AC5 — PASSED.** Fresh at the tip: suite 0 failures / 0 errors / 8600 passing
  / 26 skipped at `NOT_CRAN=true CI=true`; `air format --check .` exit 0;
  `devtools::document()` no diff; `pkgdown::check_pkgdown()` no problems;
  `R CMD check --as-cran --no-manual` on a tarball built at the tip, raw
  `Status: OK`, matching main under the same command.

**Consistency gate.** `cairn_validate` exit 0, all checks passed;
`check-record-claims.py` 6 claims / 0 failures; no principle changed;
README untouched; NEWS entry present; no new top-level files.

**Other lenses.** Blame-history: no blocking findings — it confirmed the
`vc_mpl_sim()` refactor byte-identical and behaviour-preserving, and the
`ORACLES.md` correction accurate against D-017 and in the repo's established
in-place-correction convention. Prior-review: clean, reached independently
against M106, M115, M130 and M132's archived findings.

**Further findings, logged, not criterion-failing.** [O]7 the pre-existing
sentence at `vignettes/interval-methods.Rmd:167-168` ("The remaining methods
were never run on that study") became false at D-031 (2026-08-15) and shipped
in M130 on 2026-08-22; this branch now contradicts it in the same file. [O]8 the
`"montecarlo"` depth cell states its skew under-coverage unqualified while
D-027's grid is one-way, which the article's own section is careful to say. [O]9
the `montecarlo` leg of the extra-cell-claims test re-runs the refused-cell
block's assertion verbatim and its comment overstates what it pins. [O]11 NEWS
says the Bayesian call is "skipped where none is present", but the gate is
`skip_on_ci()` and skips regardless of toolchain. [O]12 NEWS points readers at
the oracle registry, which is `.Rbuildignore`d and absent from the installed
package and the site. [O]13 the `ORACLES.md` correction says M91/D-017
"superseded" the old line, while D-017's own Consequences read "supersedes
nothing". [O]14 the ROADMAP candidate row at `cairn/ROADMAP.md:28` carries the
same stale `R/icc.R:692-703` locator. [O]10 rejected: the `"searle"`/`"burch"`
cells promise no numeric `unit`, so their pole refusal is not a cell the row
misdescribes. [O]16 noted: AC1 and AC3 stay unticked, which is this outcome.

**Thrash rule (b) fires.** AC1 and AC3 have each now failed twice, each time by
new instances of one shape — cell and caveat text composed from a reading of the
surface rather than derived from it. The remedy the rule names is to reconsider
the alternative the plan gate recorded against; the 2026-08-21 work log records
two, and the second ("a standing test that the table matches the surface",
declined under D-021 with D-029 retaining the bar) is the one this failure mode
points at. Its ROADMAP candidate row states the promotion condition as a user
reaching a cell the table misdescribes, and requires superseding D-021 first.
Trigger (a) has not fired: this is the second defect return, not the third.

**Outcome.** Returned to `in-progress`. Defect return 2.

### Outcome (round 1)

Returned to `in-progress`. First defect return on this milestone; no thrash
trigger. AC2, AC4 and AC5 stand on the evidence above and need only re-execution
against the corrected table.
