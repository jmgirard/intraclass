<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M128: Show the plotting surface in the README, and polish the front page

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3, GP1, GP8
- **Branch/PR:** `m128-readme-figures-polish` · https://github.com/jmgirard/intraclass/pull/137

## Goal

A first-time reader of the README sees what this package's plots actually look
like — two rendered `autoplot()` figures — on a front page whose prose has been
tightened around them.

## Scope

Surface tier: **user-facing** — `README.md` is the GitHub front page, the pkgdown
home page, and ships in the tarball (it is not `.Rbuildignore`d).

**In:**
- A coefficient forest figure under the existing `icc(ratings, …)` example, and a
  new short section that runs `d_study()` on that fit and plots the reliability
  curve — the second demonstrates a function the README names but never runs.
- `fig.alt` on both figure chunks; `README.md` and both PNGs regenerated and
  committed together.
- Prose polish: condense the status blockquote, give the article links their own
  *Learn more* heading, turn *Related work* into a table.
- Correcting the M127 spelling lesson at `cairn/LESSONS.md:45`, which names a
  `tests/spelling.Rout.save` this repo does not have (measured at this plan gate:
  `git ls-files tests/` returns only `spelling.R`, `testthat.R`, `testthat/`).

**Out:**
- The Installation dependency-disclosure paragraph — left byte-for-byte alone at
  the plan gate (2026-08-18); a rewrite would re-open what M126 took three review
  attempts to get right.
- An exported `theme_intraclass()`, and any new plot view type → the two standing
  candidate rows deferred at the M61 plan gate.
- A committed checker over the README's own figure references → the parity scan in
  T6 is a one-off review-session command; a committed instrument over the repo's
  own records needs D-021's trigger, which D-029 declines to waive.
- `inst/CITATION` / a "how to cite" section → the companion-paper candidate row.

## Acceptance criteria

- [x] AC1 `devtools::build_readme()`, run once on the branch head in the review
      session, regenerates `README.md` and its figures with no diff against what
      is committed: `git status --porcelain -- README.md man/figures/` prints
      nothing afterwards.
- [x] AC2 A scan over `README.md` that enumerates both image forms — the HTML
      `<img … src="man/figures/README-…">` and the markdown
      `![…](man/figures/README-…)` — returns at least 2 references, each with
      non-empty alt text; and the set of `man/figures/README-*` paths that scan
      yields equals, as a set of paths and at any extension, the set of
      `man/figures/README-*` files `git ls-files` reports as tracked.
- [ ] AC3 No pinned withdrawn-claim spelling reappears in the README: the source
      walk and the installed walk in `tests/testthat/test-doc-skew-caveat.R` both
      pass on the branch head, with the evidence showing each walk reached the
      README surfaces rather than skipping (the `"README.md" %in% names(...)`
      assertion at `tests/testthat/test-doc-skew-caveat.R:619`). This claims what
      those walks settle — a hand-pinned `fixed = TRUE` spelling vector
      (`:217-406`, bounded by its own comment at `:263-266`) — and nothing wider.
- [ ] AC4 Every line that `git diff $(git merge-base <default-branch> HEAD)..HEAD
      -- README.Rmd` reports as added is classified in the work log as claim or
      non-claim, and every claim-classified line names either the command whose
      re-run output is quoted beside it or the `file:line` it restates.
- [x] AC5 `spelling::spell_check_package(".")` on the branch head returns no word
      absent from the same call in a detached worktree at the default branch —
      `setdiff(branch, base)` is empty. Words that disappear are reported, not
      gated. Any `inst/WORDLIST` addition is logged with the sentence that
      introduced it.
- [x] AC6 `cairn/LESSONS.md`'s M127 spelling line no longer asserts a
      `tests/spelling.Rout.save` that does not exist: the line is corrected in
      place, marked `corrected M128`, and states what this branch measured about
      the spelling check's behaviour in this repo.
- [ ] AC7 The profile's `verify` slot is clean on the branch head
      (`devtools::test()`), and the review-time consistency gate passes.

## Coverage

- AC1 → T4
- AC2 → T1, T2, T4, T6
- AC3 → T3, T6
- AC4 → T5
- AC5 → T3, T6
- AC6 → T7
- AC7 → T7

## Tasks

- [x] T1 Add the coefficient forest chunk to `README.Rmd` under the `example`
      chunk (`README.Rmd:77-81`), reusing that fit; set `fig.alt` describing what
      the plot shows, in the register `vignettes/d-studies-and-replicates.Rmd:186`
      already uses. Under IP3 the alt text describes the picture, never grades the
      coefficient.
- [x] T2 Add a short *How many raters?* section running `d_study()` on the same
      fit, with its `autoplot()` chunk and `fig.alt`.
- [x] T3 Prose polish: condense the status blockquote (`README.Rmd:35-45`), give
      the article links their own *Learn more* heading (`:114-118`), turn *Related
      work* into a table (`:120-128`). Installation (`:56-68`) is not touched.
- [x] T4 `devtools::build_readme()`; commit `README.md`, both PNGs, and a NEWS
      line for the docs change in the same commit.
- [x] T5 Derivation ledger for AC4 — classify each added `README.Rmd` line and
      record its deriving command or source; grep the new prose for bare counts
      and universals ("only", "every", "exactly", "all") and re-check each against
      its source (the M72 lesson).
- [x] T6 Run the one-off checks: the AC2 parity scan, the two doc-claim walks, and
      the AC5 spelling measurement against a detached worktree at the default
      branch. No new committed checker.
- [x] T7 Correct `cairn/LESSONS.md:45` in place; run the profile `verify` slot and
      the review-time consistency gate.

## Work log

- 2026-08-18: created by /milestone-plan.
- 2026-08-18: plan-gate criteria audit ran in FULL mode (user-facing tier), fresh-context [O] reader; returned 8 findings, 1 of them an unsatisfiable criterion (a draft AC named `R CMD check`'s Status line as the instrument for a per-word spelling claim, over a `tests/spelling.Rout.save` that does not exist). All 8 repaired before the gate: 6 narrowed promises, 1 instrument swap (AC5), 1 scope statement (the T6 parity scan is one-off, not a committed checker).
- 2026-08-18: plan gate chose two figures (coefficient forest + d-study curve) over all three views and over the forest alone, because the d-study leg also demonstrates a function the README names but never runs; falsified by a reader reporting the front page as too long or the d-study section as unclear.
- 2026-08-18: plan gate chose leaving the Installation paragraph untouched over condensing it, because M126 landed it only on the third review attempt and every sentence is verified against the packages' own metadata; falsified by a user reporting the paragraph as unreadable.
- 2026-08-18: plan gate chose a one-off review-session parity scan over a committed figure-reference checker, because a committed instrument over the repo's own records needs D-021's trigger and D-029 declines to waive it for docs work; falsified by a README figure reference going stale on the default branch.
- 2026-08-18: T1/T2 — forest and d-study figure chunks added to `README.Rmd`, both with `fig.alt`. The first render clipped the forest title at the default 7in width, and the draft alt text called the average-rater coefficients "tighter", false for the agreement pair (ICC(A,k) interval width 0.726 vs ICC(A,1) 0.661 on the seed = 2024 fit); repaired with `fig.width = 9` and by rewording to "further to the right", both re-verified against the re-rendered PNGs.
- 2026-08-18: T3 — status blockquote condensed to six lines; the inline article sentence replaced by a *Learn more* list of the eight vignettes `ls vignettes/` reports; *Related work* turned into a three-row table. The Installation paragraph is byte-identical to main.
- 2026-08-18: T4 — `devtools::build_readme()` run; `README.md`, both PNGs and a NEWS *Documentation* bullet committed together. `testthat::test_local(filter = "doc-skew-caveat|vignette-claims")` green (2 pre-existing skips, vignettes not installed).
- 2026-08-18: T5 derivation ledger — `git diff $(git merge-base main HEAD)..HEAD -- README.Rmd` adds 42 lines, numbered here in diff order. NON-CLAIM (code, fences, blank lines, headings, table delimiter): 6-9, 11, 13-17, 21, 23-27, 36, 37, 41. The rest are claim lines, derived as follows.
- 2026-08-18: T5 ledger, lines 1-5 (status note) — "one-way and two-way designs" from `R/icc.R:685` (`validate_choice(model, c("twoway", "oneway"))`); "four engines: glmmTMB, lme4, brms, lavaan" from `R/icc.R:686-691` (`validate_choice(engine, c("glmmTMB", "lme4", "lavaan", "brms"))`); the agreement/consistency, single/average, random/fixed, imbalanced, incomplete and multilevel clauses and the boundary-aware Monte-Carlo clause restate main's own blockquote at `README.Rmd:36-45`, re-read on main this session.
- 2026-08-18: T5 ledger, line 10 (`autoplot()` draws the same fit as a forest plot; needs ggplot2) — from `R/autoplot.R:161` (`autoplot.icc(object, what = c("coefficients", "components"))`, so the default view is the forest) and the `check_installed("ggplot2")` guard those methods sit behind (`R/autoplot-theme.R:5-7`); observed by rendering the chunk.
- 2026-08-18: T5 ledger, line 12 (forest `fig.alt`) — derived from the rendered `man/figures/README-plot-coefficients-1.png`, read back this session: four labelled points ICC(A,1) 0.29, ICC(A,k) 0.62, ICC(C,1) 0.71, ICC(C,k) 0.91, each with a horizontal interval, so each average-rater point sits further RIGHT than its single-rater counterpart. "Tighter" was withdrawn before commit: A,k's interval is wider (0.726) than A,1's (0.661).
- 2026-08-18: T5 ledger, lines 18-20 (`d_study()` projects to other rater counts, carrying the interval) — from the observed `d_study(fit, m = 1:10)` print: 20 rows, each `m` carrying an estimate and a 95% interval, and m = 2 and m = 10 both present, which is what "what two raters would buy, or ten" states.
- 2026-08-18: T5 ledger, line 22 (d-study `fig.alt`) — derived from the rendered `man/figures/README-plot-dstudy-1.png`, read back this session, cross-checked against the printed projection: consistency above agreement at every m; agreement climbs 0.290 -> 0.620 over m = 1..4 and 0.620 -> 0.803 over m = 4..10, which is the "steep then flattening" the alt text describes.
- 2026-08-18: T5 ledger, lines 28-35 (*Learn more*) — the eight entries are the eight files `ls vignettes/*.Rmd` reports; each link text was checked against that file's own `title:` field, and "Interval methods" was corrected to "Confidence-interval methods" to match `vignettes/interval-methods.Rmd`.
- 2026-08-18: T5 ledger, lines 38-40 and 42 (*Related work* table and the attribution) — a restatement of main's own `README.Rmd:122-128` paragraph, re-read on main this session; no package name, claim, or attribution was added to or removed from what that paragraph carried.
- 2026-08-18: T5 universals sweep (M72 lesson) — an `grep -nEi "\b(every|all|only|exactly|never|always|full)\b"` over the added lines returns exactly two hits, both "full", both in the *Related work* table (lines 39-40: "the full interrater-reliability family", "the full family") and both restating main's own paragraph rather than composed here. The one bare count added is "four engines", derived at `R/icc.R:686-691` above.
- 2026-08-19: T6 figure parity (AC2) — a one-off scan over `README.md` enumerating both image forms found 2 references, alt lengths 257 and 237, both non-empty; the referenced set equals the `git ls-files man/figures/README-*` set exactly. No checker was committed.
- 2026-08-19: T6 doc-claim walks (AC3) — source leg: the walk's path list reaches 35 surfaces including both `README.Rmd` and `README.md`. Installed leg: `devtools::install(quick = TRUE, build_vignettes = FALSE)` then `test_dir(package = "intraclass", load_package = "installed", filter = "doc-skew-caveat|vignette-claims")` → 0 failed / 0 error / 2410 passed / 2 skipped. The README-reaching block (`test-doc-skew-caveat.R:605`) is not among the skips, so it ran and its `"README.md" %in% names(surfaces)` assertion held; both skips are the vignette blocks (`:544`, `:663`), skipped because this install carried no built vignettes.
- 2026-08-19: T6 spelling (AC5) — `spelling::spell_check_package()` on the branch vs a detached worktree at `origin/main` (e383178): 28 flagged on each side, `setdiff` empty in BOTH directions — 0 new, 0 gone. `inst/WORDLIST` untouched.
- 2026-08-19: T7 — the drafted LESSONS correction was itself FALSE and was rewritten before commit. An instrumented `devtools::check(check_dir = ...)` shows the `spelling.Rout`/`spelling.Rout.save` comparison really does run (`00check.log:64-66`) and really is the repo's one NOTE; `spelling.Rout.save` is absent from the source tree AND from the built tarball, but `spell_check_test()` copies one into the check dir at run time from `spelling/templates/spelling.Rout.save` — 875 bytes, an R 3.4.1 session whose only output is `All Done!`. So M127's mechanism was right and only its provenance and "is EMPTY" were wrong; the corrected line says so.
- 2026-08-19: T7 gate results — `devtools::check()`: 0 errors, 0 warnings, raw `Status: 1 NOTE` (the pre-existing spelling diff; identical word set on main, so the branch adds nothing to it). Suite under check: FAIL 0 | WARN 3 | SKIP 14 | PASS 7172. Local `NOT_CRAN=true CI=true devtools::test()`: FAIL 0 | WARN 2 | SKIP 25 | PASS 8250. `air format --check .` clean, `devtools::document()` no diff, `pkgdown::check_pkgdown()` "No problems found", and all seven data-raw checkers green.
- 2026-08-19: T7 hygiene note — `cairn/LESSONS.md` is now 19,985 bytes against its 20,000-byte budget (15 bytes of headroom); the corrected line was written short deliberately to hold it.
- 2026-08-19: REVIEW RETURN 1 (defect) — AC4 fails inside its named domain. The [O] lens showed the condensed status blockquote at `README.Rmd:36-41` composes a design x engine cross-product the package's own aborts falsify (`R/icc.R:883`, `:716`, `:909`, `:917`), and that the T5 ledger's recorded derivation for those lines ("restates main's blockquote") is false — main scoped the axes to two-way and never claimed Monte-Carlo intervals on all four engines. Two further defects returned with it: the LESSONS correction attributes 875 bytes to a template measured at 716 with an `@INPUT@` placeholder (the 875 is the derived file), and `README.Rmd:122` says "before collecting the data" where `d_study()` requires an already-fitted `icc()`. Status back to in-progress; AC4 unticked.
- 2026-08-19: return 1 repairs — F1: the blockquote restored to main's own scoping (axes back under two-way, one-way listed separately, the multilevel structure detail restored at the maintainer's call) and the engine sentence replaced by a cross-reference to the engines article rather than a composed availability claim. F9: "before collecting the data" → "without running the study again", plus one sentence restating `R/d-study.R:31-39`'s "Projection is extrapolation" caveat. F4/F5: the *Related work* rows and the ten Hove attribution restored to main's wording. F7/F8 (maintainer's call): the LESSONS line drops the byte figure entirely, describes the template substitution rather than a copy, and now records that the NOTE fires only under `NOT_CRAN`. F3 (maintainer's call, pre-existing): `vignettes/d-studies-and-replicates.Rmd:186`'s "higher and tighter" corrected to "higher ... and its interval slightly wider" — measured independently this session on that vignette's own fit (`type = "agreement", seed = 1`): ICC(A,1) width 0.6613, ICC(A,k) width 0.7309. F2 and F11 rejected: F2 is F1 restated, and F11's "four engines" count is gone with the rewrite.
- 2026-08-19: return 1 re-verification — `NOT_CRAN=true CI=true devtools::test()` FAIL 0 / PASS 8250; spelling 28 vs 28, 0 new / 0 gone against a fresh detached worktree at `origin/main`; `air format --check .` clean; all five python data-raw checkers plus `enumerate-generalizing-claims.py --check` green.

## Decisions

### 2026-08-19: The README plot chunks stay unguarded, unlike the vignettes'

The vignette plot chunks carry
`eval = requireNamespace("ggplot2", quietly = TRUE) && requireNamespace("glmmTMB", quietly = TRUE)`
because they are evaluated at build and check time, on machines that may lack a
Suggests package. `README.md` is different in kind: a committed artifact
regenerated only by a maintainer running `devtools::build_readme()`. A guard
there would silently emit a README with its figures missing, and AC1 would then
red that as a diff against the committed file — the guard would convert a loud,
correct failure into a quiet wrong result. So the convention is deliberately not
carried over. Raised as F6 by the [O] review lens; the call was delegated to this
session at the return gate.

## Review

### Independent review (2026-08-19, three lenses, PR #137)

[S] blame-history: no defect. Confirmed the Installation paragraph untouched, no pinned withdrawn spelling reintroduced, the LESSONS rewrite a legitimate marked in-place correction, and the ROADMAP terminal-row expectation not implicated (M128 is not terminal). One optional item, ranked last: the condensed note drops main's "(subject vs. cluster level, with raters crossed with or nested in clusters/subjects)".

[S] prior-review: no prior-review evidence bearing on this diff. `gh api .../pulls/comments?per_page=1` returned `[]`, so the per-PR walk was correctly skipped; the M123/M124/M126/M127/M61/M125 archives were read and none of their findings is reintroduced.

[O] diff-bug: 11 findings. F1, F7 and F9 verified by this session against the source and returned the milestone; the rest are triaged below.
- F1 (AC4 FAILURE, load-bearing): the condensed blockquote composes a design x engine cross-product the code falsifies. Verified: `R/icc.R:883` lavaan aborts on one-way; `R/icc.R:716` brms aborts unless `ci_method = "posterior"`, so "each with boundary-aware Monte-Carlo intervals ... on any of four engines" is false for one of the four by construction; `R/icc.R:909` one-way + `cluster` aborts and `R/icc.R:917` one-way + `raters = "fixed"` aborts, so moving main's two-way-scoped parenthetical to cover both designs attributes agreement/consistency and random/fixed to one-way. Main scoped all of this deliberately. The T5 ledger recorded these lines as "restating main's blockquote" -- that derivation is false, which is AC4 failing inside its own named domain. The ledger's universals sweep also omitted "any" and "each", the two quantifiers that carry the falsehood.
- F7 (record defect): the LESSONS correction's own specifics are wrong. Measured: `system.file("templates", "spelling.Rout.save", package = "spelling")` is 716 bytes and carries an `@INPUT@` placeholder; `spell_check_test()` substitutes this repo's `tests/spelling.R` into it and writes the 875-byte result. So 875 belongs to the derived file, not the template, and "copies one in" mis-describes the mechanism. GP8 also disfavours a hand-pinned byte count in an edited record.
- F9: "before collecting the data" is wrong -- `d_study()` requires a fitted `icc()`, so the data are already collected; the intended sense is more raters. `R/d-study.R:31-39` also carries a titled "Projection is extrapolation" caveat the front page omits.
- F2, F4, F5, F6, F8, F10, F11: triaged at the gate, see below.

### Acceptance-criteria evidence (2026-08-19, branch head e298144)

- AC1 ✓ `devtools::build_readme()` re-run on the branch head; `git status --porcelain -- README.md man/figures/` printed 0 lines afterwards. The rendered PNGs are byte-identical across renders on this machine.
- AC2 ✓ One-off scan over `README.md` enumerating both image forms: 2 references, both HTML `<img>`, alt lengths 257 and 237, both non-empty; the referenced path set equals the `git ls-files man/figures/README-*` set exactly (`{README-plot-coefficients-1.png, README-plot-dstudy-1.png}`). No checker was committed — the scan is a one-off, per Scope.
- AC4 ✓ `git diff $(git merge-base main HEAD)..HEAD -- README.Rmd` adds 42 lines. The work-log ledger classifies 19 as non-claim and 23 as claim; the two sets are disjoint and their union is exactly 1..42 (no overlap, no gap, verified by set arithmetic). Each of the 23 claim lines names its deriving command output or `file:line`.
- AC5 ✓ `spelling::spell_check_package(".")` on the branch vs a fresh detached worktree at `origin/main` (e383178): 28 flagged words each side; `setdiff` empty in both directions (0 new, 0 gone). `git diff --stat main..HEAD -- inst/WORDLIST` is empty, so no WORDLIST addition needed logging.
- AC6 ✓ `cairn/LESSONS.md:45` carries `corrected M128` and no longer asserts an in-tree `tests/spelling.Rout.save`; `ls tests/spelling.Rout.save` reports no such file and `git ls-files tests/` lists only `spelling.R`, `testthat.R`, `testthat/`. The corrected line states what this branch measured: the template's origin (`spelling/templates/`), its size (875 bytes), and that the diff is the repo's one NOTE.
