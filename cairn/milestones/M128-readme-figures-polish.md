<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M128: Show the plotting surface in the README, and polish the front page

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3, GP1, GP8
- **Branch/PR:** `m128-readme-figures-polish`

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

- [ ] AC1 `devtools::build_readme()`, run once on the branch head in the review
      session, regenerates `README.md` and its figures with no diff against what
      is committed: `git status --porcelain -- README.md man/figures/` prints
      nothing afterwards.
- [ ] AC2 A scan over `README.md` that enumerates both image forms — the HTML
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
- [ ] AC5 `spelling::spell_check_package(".")` on the branch head returns no word
      absent from the same call in a detached worktree at the default branch —
      `setdiff(branch, base)` is empty. Words that disappear are reported, not
      gated. Any `inst/WORDLIST` addition is logged with the sentence that
      introduced it.
- [ ] AC6 `cairn/LESSONS.md`'s M127 spelling line no longer asserts a
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
- [ ] T5 Derivation ledger for AC4 — classify each added `README.Rmd` line and
      record its deriving command or source; grep the new prose for bare counts
      and universals ("only", "every", "exactly", "all") and re-check each against
      its source (the M72 lesson).
- [ ] T6 Run the one-off checks: the AC2 parity scan, the two doc-claim walks, and
      the AC5 spelling measurement against a detached worktree at the default
      branch. No new committed checker.
- [ ] T7 Correct `cairn/LESSONS.md:45` in place; run the profile `verify` slot and
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

## Decisions

## Review
