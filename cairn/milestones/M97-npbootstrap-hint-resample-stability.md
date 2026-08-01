# M97: `npbootstrap` in the boundary hint — verified by running it, not predicted

- **Status:** review
- **Branch:** m97-npbootstrap-hint
- **PR:** https://github.com/jmgirard/intraclass/pull/104
- **Priority:** normal
- **Depends on:** M93
- **Driving RR:** —
- **Principles touched:** GP1, GP7

## Goal

Let the boundary abort name `ci_method = "npbootstrap"` on unbalanced one-way designs —
the only method shipping that cell (D-013) — by RUNNING the bootstrap on the data in
hand and naming it only if it returned a usable interval, rather than predicting from
the design whether its resampling will hold up.

## Scope

**In:** `"npbootstrap"` added to M93's verification helper — the same run-it-and-look-at-
the-interval check, extended to a method that resamples: run `npbootstrap_ci()` at the
shipped `boot_samples` under the seed the user's own call would use, catch every error,
accept only a finite, correctly ordered, in-support interval on every estimand (M93's
predicate, unchanged); the unbalanced one-way row
restored in `boundary_method_hint()` behind it; RNG neutrality (#9) via the existing
`with_rng_seed()`, so a hint that fires cannot perturb the user's stream; a decision,
recorded in this file, on what to do when the caller set no `seed` — a run that succeeds
under one seed can fail under another, measured at this gate as 8/8 seeds succeeding on
a 20×3 design and 1/8 on a 6×2; M93's AC3 sweep extended over imbalance shape incl. the
double-code design; the stale `R/ci-npbootstrap.R:177` comment ("negligibly rare at
k >= 10") corrected against measurement; NEWS + `@param`.

**Out:** deriving an ANALYTIC stability predicate from the observed data (subjects
carrying within-subject variance, ties among subject means) — this milestone's original
premise, dropped at the 2026-07-26 gate once running the bootstrap was measured at
135 ms, which answers the same question exactly rather than approximately; revive only
if the seed question makes running it unworkable · a SECOND verification helper — M93
ships the generic one and M97 registers a method with it; a divergent copy is the
drift pattern that produced M93's pass-2 finding · changing `npbootstrap_ci()`'s own
guards, message or design fence — this evaluates the shipped guard, it does not move it
→ ROADMAP candidate · the deterministic rows → M93 · fallback or auto-routing on abort,
the `#3`/ADR-003 change D-012 fenced out and D-018 draws the line against → standing
ROADMAP candidate.

## Acceptance criteria

- [x] AC1: `"npbootstrap"` is registered with M93's verification helper rather than
      given a second one — it runs `npbootstrap_ci()` on the data in hand and returns
      TRUE only under M93's unchanged predicate (every estimand finite,
      `conf.low <= conf.high`, in support); every error is caught, so the check itself
      can never turn the boundary abort into a different error (the M93 pass-4 F2
      failure mode, in a new place). A test asserts one helper serves both families.
- [x] AC2 (#9): the check is RNG-neutral — a committed test captures `.Random.seed`
      across an `icc()` call that fires it and asserts the stream is unchanged, so a
      user who never asked for a bootstrap cannot have their draws perturbed by one.
- [x] AC3: the no-seed case is decided, and the decision recorded in this file with its
      rationale; a test pins whatever behaviour is chosen. Measured at the plan gate:
      `npbootstrap_ci()` succeeded at 8/8 seeds on a 20×3 design and 1/8 on a 6×2, so
      the risk is real and size-dependent, not theoretical.
- [x] AC4 (GP7): M93's message-driven sweep, re-run with `npbootstrap` in the mapping
      and extended over imbalance SHAPE (balanced, mildly ragged, and the double-code
      design that defeated M93 pass 3), records ZERO hinted-then-unusable runs at the
      shipped `boot_samples = 999` — never a reduced count, which lowers the chance of
      tripping a guard that fires on any degenerate resample (M93 pass-3 F3).
- [x] AC5: the added cost is measured and recorded — the check runs only on a path that
      has already failed, and this gate measured 135 ms at 999 resamples; a recorded
      measurement confirms the success path is untouched, the hint being a promise
      forced only inside an abort message.
- [x] AC6: documented where users meet it — a `NEWS.md` entry, the `@param ci_method`
      note, and `R/ci-npbootstrap.R:177`'s "negligibly rare at k >= 10" comment
      corrected against AC4's measurement (contradicted by it, and pre-existing).
- [x] AC7: `devtools::test()`, `devtools::check()`, `lintr::lint_package()` and
      `air format --check` clean; `devtools::document()` no-diff; snapshot changes
      reviewed via `testthat::snapshot_review()`, never accepted blind; CI green.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T5
- AC5 → T1, T5
- AC6 → T6
- AC7 → T6

## Tasks

- [x] T1: Register `"npbootstrap"` with M93's verification helper — run
      `npbootstrap_ci()` at the shipped `boot_samples`, catch everything, accept only
      under M93's unchanged predicate — with unit tests over designs where it succeeds
      and where it fails, and record its measured cost.
- [x] T2: Wrap it RNG-neutral via `with_rng_seed()`, and add the AC2 test capturing
      `.Random.seed` across a firing `icc()` call.
- [x] T3: Settle the no-seed case at the implement gate and record it here: name it
      anyway with the run as evidence, stay silent unless the caller set a `seed`, or
      name it and say which seed reproduces the run. Pin the choice.
- [x] T4: Restore the unbalanced one-way row in `boundary_method_hint()` behind the
      check, worded as availability (D-012's 0-abort evidence is a searle/burch result,
      never an npbootstrap one).
- [x] T5: Extend M93's sweep over imbalance shape at `boot_samples = 999`; require zero
      hinted-then-unusable runs.
- [x] T6: NEWS, `@param`, the `R/ci-npbootstrap.R:177` comment correction,
      `devtools::document()`, full AC7 gate, PR.

## Work log

- 2026-07-25: created by /milestone-plan as the remainder of the M93 re-cut — the half three M93 review passes could not fence with design predicates (pass-2 F1: raw subject count; pass-3 F1: the count is decoupled from the effective one under imbalance). Depends on M93 because both edit `R/boundary-hint.R` and its test file.
- 2026-07-26: re-scoped at the second M93 re-cut gate — the analytic stability predicate is dropped in favour of RUNNING the bootstrap (135 ms at 999 resamples, on an already-failed path), which answers the same question exactly rather than approximately. The seed question is what keeps this separate from M93: 8/8 seeds succeed on a 20×3 design, 1/8 on a 6×2, so a run is evidence about that seed, not about every seed. GP6 drops from the header slot — the failure axis is no longer swept for a formula, it is run directly.
- 2026-07-26: amended at the M93 third re-cut gate — M93 now adopts verification for the deterministic methods too, and ships the helper generic over a method name, so M97's own T1/AC1 narrow from "add an internal check" to "register `npbootstrap` with M93's helper"; a second copy is explicitly out (the M93 pass-2 drift pattern). M93's acceptance predicate gains an in-support clause (D-010) that M97 inherits unchanged, and D-018 records why running a candidate inside an abort path is not D-012's fenced fallback.

- 2026-07-27: inherited constraint, carried in from the M93 review pass-10 [O] lens so it is not rediscovered here — M93's AC5 leak detector (`num_tokens()`) matches DIGIT strings only, so a leaked NON-finite endpoint (`Inf`, `-Inf`, `NaN`, `NA`) is invisible to both the bullet invariant and the whole-message enumeration. Unreachable in M93 by construction, because a bullet is built only for a method whose every reported endpoint is finite (measured: 0 of 28 endpoints inspected across the guard's grid were non-finite). It becomes live the moment an `npbootstrap` bullet quotes or characterises a REJECTED candidate, which is exactly the shape T3's "name it and say which seed reproduces the run" wording invites. Settle at the M97 implement gate: either keep bullets free of any candidate-derived value, or widen the detector to non-finite tokens before adding such a bullet.

- 2026-07-31: question gate — both recommendations accepted: the no-seed case verifies under a fixed seed the bullet then names (AC3), and the leak-detector carry-in gets both remedies (value-free bullets + non-finite widening); rationale in Decisions below.
- 2026-07-31: T1+T2+T3+T4+T5 in one commit (they rewrite the same two functions and one test file, and T2's end-to-end test needs T4's restored row, so per-task splitting would leave the suite red at a checkpoint — the M93 T1/T2 precedent): `npbootstrap` registered as a row in `boundary_method_usable()` (shipped `boot_samples` default, caller seed else `npb_hint_seed = 1L`); the unbalanced one-way row restored behind the run with the numeric-`unit` fence mirrored; the message-driven sweep extended over imbalance shape (balanced / mildly-ragged / double-code at 15–60 subjects) with the named==usable identity asked under the abort's own seed; leak guard rebuilt: two npbootstrap renderings pinned (distinct-count 3→5), `num_tokens()` widened to non-finite word-tokens with positive controls, whole-message enumeration licenses exactly the named seed; RNG neutrality pinned direct and end-to-end (seeded: stream unchanged; unseeded: stream equal to a hint-disabled mock of the same call). AC5 cost: 124 ms median at 999 resamples on a 20×3 unbalanced design, and the existing laziness guard shows the success path untouched. Hint test file green with its CRAN-skipped sweeps active, `lintr` 0, `air format --check` clean; the full-suite `NOT_CRAN=true CI=true` run was still executing at this checkpoint — its result gets its own line.

- 2026-07-31: full suite at `NOT_CRAN=true CI=true`: FAIL 0 / ERROR 0 / SKIP 23 / PASS 5455 on the T1–T5 checkpoint tree; no `_snaps/` path in `git diff main..HEAD`, so no snapshot moved and none was accepted.
- 2026-07-31: T6 gate — `devtools::check(env_vars = c(NOT_CRAN = "false"))` **0 errors / 0 warnings / 0 notes** (2m09s); `devtools::document()` no-diff; NEWS/`@param`/comment-correction landed with the T1–T5 commit (same files). PR #104 opened. Status -> review.
- 2026-07-31: review-time CI catch, fixed on the branch rather than a status flip (no runtime surface; the M93 precedent for a check-references trip) — the `@param ci_method` rewrite changed two sentences the M94 doc-claims ledger pins: row 40's quote+key re-triaged to the reworded sentence, row 42 ("It never names npbootstrap") deleted with its claim; `check-mpl-doc-claims.py` 0 failures + self-test OK and `check-reference-observations.py` 0 falsified locally. The M94 checker is CI-only, not in the local verify slot — which is why the local gate missed it.
- 2026-07-31: review pass 1 — [O] diff-bug lens returned 12 findings, 6 scored ≥80, all fixed on the branch (details in Review): the load-bearing pair — the test harness verifying a different estimand configuration than production (raw rater count vs harmonic k_eff) and the verification ignoring the caller's boot_samples — both reproduced independently before fixing; hint file re-run post-fix FAIL 0 / PASS 1248 with sweeps active. Return count for the thrash rule: this is M97's first return, and it was fixed in-pass rather than sent back.

## Decisions

- 2026-07-31 (T3/AC3, question gate): **No caller `seed` → verify under the fixed `npb_hint_seed = 1L` and name that seed in the bullet.** A bootstrap run is evidence about one seed's resamples, not all of them (measured this session: the same unbalanced 8×3 dataset verifies under seed 8 and fails under seeds 1–7), so an unqualified hint after an ambient run could promise an interval the user's own unseeded retry fails to produce — the hinted-then-unusable failure five M93 passes closed. With a caller seed the bullet stays seed-free: their own retry re-runs the verified draws. Rejected: staying silent without a caller seed (most callers set none, and npbootstrap is the only method shipping the unbalanced one-way cell, so the hint would rarely fire where it matters most); naming unqualified off an ambient-stream run (re-opens hinted-then-unusable on small designs).
- 2026-07-31 (M93 pass-10 carry-in, question gate): **Bullets stay free of candidate-derived values AND the leak detector widens to non-finite tokens.** The named seed is a producer-chosen input, never a value the verification run returned (those stay discarded, D-018), and the whole-message invariant enumerates it as the one licensed literal. `num_tokens()` now also matches `Inf`/`NaN`/`NA` word-tokens, with positive controls, so a leaked non-finite endpoint — invisible to the digit-only detector — reds the invariant.
- 2026-07-31 (review pass 1 correction — supersedes the measurement sentence in the first entry above, whose decision stands): the "verifies under seed 8 and fails under seeds 1–7" figure was an artifact of the direct tests building estimands with the raw rater count (3) where production passes the harmonic k_eff (2.4) — under the production configuration the same 8×3 dataset is usable under seeds 1,3,4,7,8 and unusable under exactly 2,5,6, each failure being the resample-stage guard (review F1/F2/F3, reproduced independently). The decision itself survives on the corrected evidence: usability still varies by seed (5/8 on the 8×3, 0/8 at every probed seed on double-code), so running under the seed the retry would use — and naming the fixed seed when none was set — remains load-bearing. The same review threaded the caller's `boot_samples` through the verification (F5): the verified run must be the promised retry in *every* argument that changes the resamples, and a run that succeeded at 999 was measured aborting at a caller's 2000.

## Review

Fresh evidence gathered 2026-07-31, this session, on the branch head (post ledger
re-triage; code identical to the gated tree). "Fresh hint-file run" = the full
`test-boundary-abort-hint.R` file with its CRAN-skipped sweeps active
(`NOT_CRAN=true CI=true`): **FAIL 0 / ERROR 0 / SKIP 0 / PASS 1237**.

- AC1 — `boundary_method_usable()` gains an `npbootstrap` row calling the shipped
  `npbootstrap_ci()` (shipped `boot_samples` default, every condition swallowed to a
  bare logical); the "ONE verification helper serves both method families (AC1)"
  test pins the namespace to exactly the two `*_usable` functions and drives both
  families through the same helper; the no-leak test's hostile list adds five
  npbootstrap abort surfaces (observed-data degeneracy, NA, empty, resample guard)
  so the check can never replace the user's boundary abort. Fresh hint-file run
  green.
- AC2 — committed tests capture `.Random.seed` across firing calls: direct
  (no-seed, seeded, and a FAILING run), end-to-end seeded (`icc()` abort whose
  message names npbootstrap leaves the stream bit-identical), and end-to-end
  unseeded (stream state equals a hint-disabled mock of the same call, isolating
  the verification's contribution to exactly zero). Fresh hint-file run green.
- AC3 — decision recorded in this file's Decisions (2026-07-31, question-gate
  approved; measurement corrected by the review-pass-1 entry): caller seed when
  set, else fixed `npb_hint_seed = 1L` named in the bullet. Pinned under the
  PRODUCTION estimand configuration (harmonic k_eff, review F1/F2 fix): the same
  8×3 dataset is hinted under `seed = 1` (and with no seed — the same run) and
  silent under `seed = 2`; verdict-level pins TRUE at seeds {1,4,8} / FALSE at
  {2,5,6}. Fresh hint-file run green post-fix.
- AC4 — the message-driven sweep (named == usable identity, asked under the abort's
  own `seed = 1`) now spans imbalance SHAPE: balanced, mildly-ragged (sizes 3,2),
  and double-code at 15/30/60 subjects, at `boot_samples = 999` — and since the
  review-pass fix the verification threads the CALLER's `boot_samples` (F5), so a
  count the retry will not use can never be the one verified; pins at the builder
  and verdict level show hinted-at-999 / silent-at-2000 on the same data+seed.
  Zero hinted-then-unusable runs (the identity held in every aborting cell of the
  fresh post-fix run) and the row is shown FIRING (`named_unbal > 0` pin).
- AC5 — measured cost recorded in the work log: 124 ms median at 999 resamples on a
  20×3 unbalanced design; the "verification never runs on a successful call" guard
  passes in the fresh run, so the success path is untouched and the run is forced
  only inside the abort message promise.
- AC6 — NEWS.md boundary-hint entry rewritten (npbootstrap named on unbalanced
  one-way, the seed AND boot_samples story in user terms); `@param ci_method`
  updated the same way; `R/ci-npbootstrap.R` "negligibly rare at k >= 10" comment
  corrected against measurement — figures re-corrected at review pass 1 (F3):
  double-code trips the guard under every probed seed, the unbalanced 8×3 under
  3 of 8 (2,5,6); `man/icc.Rd` regenerated.
- AC7 — re-run in full on the FINAL post-fix tree (b56da5a), by command:
  `devtools::test()` at `NOT_CRAN=true CI=true` FAIL 0 / PASS 5466 / SKIP 23;
  `devtools::check(env_vars = c(NOT_CRAN="false"))` 0 errors / 0 warnings /
  0 notes; `lintr::lint_package()` 0 lints; `air format --check` clean;
  `devtools::document()` no-diff; no `_snaps/` path in the branch diff (no
  snapshot moved or accepted). CI: first run caught the M94 doc-claims ledger
  drift (fixed above, logged); green CI on the final head is verified at the
  merge step's blocking watch.

Consistency gate (by command, this session): `cairn_validate` exit 0 (all checks
PASS; the 321-token "dangling id tokens" WARN is the standing pre-migration
COVERAGE.md advisory, untouched by this diff); no DESIGN.md principle changed →
`cairn_impact` skipped; profile slot: `document()` no-diff ✓, generated files
untouched by hand ✓, README.Rmd/md in sync ✓, `pkgdown::check_pkgdown()` no
problems ✓, NEWS entry present ✓, no new top-level files ✓, full `check()` clean ✓.

Independent fresh-context review: [S] blame-history — **no findings** (planned
M93→M97 reversal, guards strengthened, no unplanned regressions); [S]
prior-review-record — **no findings** (each M93 pass-closed shape verified as
guarded, not reintroduced: pass-2 F1/pass-3 F1 predicates replaced by the run,
pass-4 F2 condition-escape covered for the new row, pass-10 non-finite carry-in
closed with positive controls); [O] diff-bug — **12 findings**, all scored by a
fresh [S] scorer; the two load-bearing ones reproduced independently by the
orchestrator before any fix.

Actioned (≥80), all FIXED on the branch this pass:
- F1 (95): the direct-test harness built estimands/n0 from the raw rater count
  (3) where production passes harmonic k_eff (2.4) — opposite usability verdicts
  on the 8×3. Fixed: `bh_hint()` and `bh_usable()` now use summarize_design()'s
  own harmonic expression.
- F2 (90): the AC3 seed-split pins were a pole-crossing artifact of F1. Fixed:
  re-pinned to production-config verdicts (TRUE 1,3,4,7,8 / FALSE 2,5,6).
- F3 (88): the corrected rarity comment's "8×3 under 7 of 8" was the wrong-divisor
  figure; the true resample-guard rate is 3 of 8. Fixed in the comment.
- F4 (82): the same disputed figure sat in R/boundary-hint.R comments and the
  Decisions rationale. Fixed in comments; Decisions corrected by an appended
  superseding entry (history never edited).
- F5 (92): verification hardcoded boot_samples=999 while the retry honors the
  caller's value — hinted-at-999, aborts-at-2000 measured. Fixed: boot_samples
  threaded icc() → hint → helper; pinned at builder and verdict level.
- F12 (82): NEWS/@param stated the reproduction promise without its boot_samples
  precondition. Fixed: both now say the trial uses your call's own boot_samples
  and seed.

Logged sub-80 (surfaced, not actioned as found — three fixed anyway as rides on
the same edits, marked ✓):
- F8 (68) ✓ whole-message enumeration was self-referential — now anchored to the
  licensed constant. - F6 (66) ✓ bh_usable's D-010 floor used raw rater count —
  now harmonic. - F9 (58) ✓ seed-exception arm's unique() could hide a colliding
  leak — now pins the exact two-token vector. - F11 (55) ✓ stale "PURE function"
  header comment updated (rode along). - F10 (48) not actioned: run-seed↔named-
  seed correspondence is pinned end-to-end by the GP7 acceptance row. - F7 (40) ✓
  rotting line-number citation replaced with a stable anchor (rode along).
