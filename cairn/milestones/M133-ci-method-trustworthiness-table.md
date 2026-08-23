<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M133: Tell users which interval method is trustworthy for their design

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** M130   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, GP5   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m133-ci-method-trustworthiness-table`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create -->

Let a reader see, per `ci_method`, which designs it computes an interval for,
which it refuses, and how deeply that interval is independently verified.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**Surface tier: user-facing** — the deliverable is a table and caveats shipped
in `vignettes/interval-methods.Rmd`. Nothing here is a records artifact.

**In:** one table row per value of the `ci_method` choice vector at
`R/icc.R:692-703` (`montecarlo`, `bootstrap`, `posterior`, `npbootstrap`,
`searle`, `burch`, `mpl`) — supported family, refused family, verification
depth — each row's supported/refused claim established by running a call on
each side of the fence, and each row's verification depth read off
`cairn/references/ORACLES.md`. Any row not backed by two independent oracles
says so in the reader's terms.

**Out:** a `cairn/references/` page or committed checker enumerating the
surface → **not built**: that is records apparatus, barred by D-021 and expressly
retained by D-029, whose closing warning at `cairn/DECISIONS.md:1300` names this
exact framing. A standing test asserting the table matches the surface →
ROADMAP candidate row, promoted on a user reaching a cell the table
misdescribes. A full factorial over `type`/`raters`/`unit` with committed
per-combination fixtures → **not attempted**: 224 cells at the floor and
unbounded on `unit` (which `normalize_unit` accepts as any number ≥ 1), 32 of
them forced-brms MCMC fits, against a 5 MB CRAN package budget. Extending the
M113 skew battery to `"bootstrap"`, and the two-way heavy-tail grid → stay
ROADMAP candidates on their own promotion conditions.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: `vignettes/interval-methods.Rmd` ships a table with one row per value
      of the `ci_method` choice vector at `R/icc.R:692-703` — read from that
      source, never from `formals(icc)$ci_method`, which returns only the
      default `"montecarlo"` — stating for each: the design/estimand family it
      computes an interval for, the family it refuses, and its verification
      depth.
- [ ] AC2: For every row, `tests/testthat/test-vignette-claims.R` runs one call
      inside the family that row names as supported and asserts an interval is
      returned, and one call outside it and asserts the abort class that row
      names. No row ships without both.
- [ ] AC3: Every row's verification depth is one of: backed by two or more
      independent oracles named in `cairn/references/ORACLES.md`; backed by
      one; or carrying a stated coverage caveat. Every row that is not the
      first says so in the vignette's shipped prose, in the reader's terms —
      not only in the work log.
- [ ] AC4: For each row, a planted perturbation of each of these forms reds
      AC2's tests: a changed `ci_method`, a changed design argument, and an
      inverted supported/refused direction. Each planted run is logged.
- [ ] AC5: `NOT_CRAN=true CI=true devtools::test()` 0 failures;
      `air format --check .` clean; `R CMD check`'s raw `Status:` line no worse
      than main's; `pkgdown::check_pkgdown()` and `build_site()` clean;
      `cairn_validate` exit 0.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T3
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: For each of the seven `ci_method` values, run one supported call and
      one refused call and record the outcome (interval, or abort class) — the
      run is ephemeral evidence in the work log, not a committed fixture.
      Cross-check each fence against its D-entry (D-010 npbootstrap, D-013
      searle/burch, D-015 mpl, ADR-033 posterior/brms coupling).
- [x] T2: Write the per-row supported/refused tests, RED-first.
- [x] T3: Read each row's verification depth off `cairn/references/ORACLES.md`;
      draft the table and the caveat prose for every row below two oracles.
- [x] T4: Planted-perturbation runs, three forms per row.
- [ ] T5: Full gate-lite sweep.

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

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
