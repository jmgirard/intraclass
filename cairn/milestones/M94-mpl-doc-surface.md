# M94: Exported documentation of the MPL interpolation evidence, with a fixture-reading check

- **Status:** in-progress
- **Branch:** m94-mpl-doc-surface
- **Priority:** normal
- **Depends on:** M92
- **Driving RR:** —
- **Principles touched:** GP1, GP7

## Goal

Tell users what M92 measured about `ci_method = "mpl"` — in `@param` and NEWS — under a
committed check that fails when a documented claim stops being true of the fixture.

## Scope

**In:** the exported prose surface M92's re-cut fenced out — `@param ci_method` and
`@param conf_level` in `R/icc.R`, the regenerated `man/`, and a `NEWS.md` entry:
that the interpolated-subject-count path is coverage-checked at each supported level,
and what the validated cells do and do not license about the interval's asymmetry. Plus
the enforcement that makes those claims safe: a committed script that reads
`data-raw/m92-interp-sweep.rds`, settles every universal/negative claim the docs make
about the cells, and runs in CI.

**Out:** re-running or re-calibrating anything — M92's fixtures are frozen inputs here ·
the `interval-methods.Rmd` vignette treatment of all four opt-in `ci_method` values →
stays its own ROADMAP candidate (a method-wide writing job, not this `@param` pass) ·
any change to `mpl_kappa_lookup` or the κ_m table → M92 settled that, D-015 · claims
about 0.90/0.99, which M91 already documents.

## Acceptance criteria

- [ ] AC1 (GP1): `@param ci_method` states that the constant is interpolated between
      subject nodes and that the interpolated path is coverage-checked at each
      supported level, in language an applied reader can act on — and says plainly what
      it does not establish (nodes are individually calibrated; interpolated values are
      validated at a handful of geometries, not calibrated).
- [ ] AC2 (GP7, the M71 lesson made mechanical): every **universal or negative** claim
      the exported docs make about M92's validated cells — "no cell…", "the cells
      differ in…", "every cell…", "nothing isolates…" — is listed in a committed ledger
      with the assertion that settles it.
- [ ] AC3: `data-raw/check-mpl-doc-claims.py` reads `data-raw/m92-interp-sweep.rds`,
      evaluates every ledger assertion, and exits non-zero when any fails. A claim in
      the docs with no ledger row, or a ledger row with no claim, also fails it.
- [ ] AC4: the check is mutation-verified — inverting each documented claim in turn, and
      separately pointing the script at the superseded
      `data-raw/m92-interp-sweep-run1-collided.rds`, each make it exit non-zero. A
      by-hand record of the inversions is committed if no automated harness fits.
- [ ] AC5: the check runs in CI, not only locally — `cairn_validate` does not cover
      `data-raw/` checkers, so a locally-green consistency gate can still ship a false
      doc claim (M85).
- [ ] AC6: the specific claim M92's review found false is settled, not repeated: **E2
      and E3 differ only in rater count** (`n_s` 40, `delta` 4, `rho` 0.60, `conf` 0.95;
      `n_r` 10 vs 2), so any "nothing isolates the rater axis" wording is refused by the
      check. Whatever the docs say about asymmetry across raters carries its own row.
- [ ] AC7: `devtools::check()`, `devtools::test()`, `lintr::lint_package()` and
      `air format --check` clean; `devtools::document()` no-diff; `pkgdown::check_pkgdown()`
      clean; the references-CI checkers green; and `NEWS.md` carries the user-facing entry.

## Coverage

- AC1 → T2
- AC2 → T1, T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T1, T3
- AC7 → T5

## Tasks

- [x] T1: Enumerate, from `data-raw/m92-interp-sweep.rds`, what the cells actually
      license — including which pairs vary in one factor alone — and draft the claim
      ledger from that, before writing any prose. Reversing this order is how M92's
      P3-1 was written.
- [x] T2: Write the `@param ci_method` / `@param conf_level` text and the `NEWS.md`
      entry against the ledger; `devtools::document()`.
- [x] T3: Implement `data-raw/check-mpl-doc-claims.py` — parse the ledger, evaluate each
      assertion against the fixture, and cross-check ledger↔docs both ways.
- [x] T4: Mutation-verify: invert each claim in turn, and point the script at the
      collided fixture; record that each reds.
- [ ] T5: Wire the check into the CI job that already runs the references checkers, run
      the full gate, open the PR.

## Work log

- 2026-07-25: created by /milestone-plan as the second half of M92's re-cut (M92 failed review three times, every failure in this exported prose surface; the thrash rule sent it back to plan). The rule this milestone exists to enforce — a universal or negative claim about the repo's own fixture must carry the command that settles it — is `cairn/LESSONS.md:30` (M71), which until now had no enforcement on the roxygen surface.

- 2026-07-31: T1 done — fixture enumerated (single single-factor pair: E2 vs E3, n_r only; all cells δ=4/ρ=0.60/0.95; floors clear at min 0.944; miss direction non-uniform: 31/2, 42/14, 0/1; no endpoint saturation); ledger drafted at `data-raw/mpl-doc-claims.tsv` (9 settle + 1 absent row, keys recomputed at T3). Gate choices: stdlib RDS parser in-script (no new dep), committed TSV ledger.

- 2026-07-31: T2 done — interpolation paragraph added to `@param ci_method`, one sentence to `@param conf_level`, NEWS bullet added (no milestone numbers, per tracking rules); every ledger quote appears verbatim; `devtools::document()` clean, `man/icc.Rd` regenerated.

- 2026-07-31: T3 done — checker implemented with a stdlib-only RDS reader (no R, no pip in the R-free CI job); wide-recall sentence enumerator over the two `@param` blocks + the NEWS bullet found 30 candidates; ledger finalized (12 settle, 2 absent AC6-refusal, 21 out rows); check green both directions.

- 2026-07-31: T4 done — mutation verification is the automated `--self-test` (no by-hand record needed): inverting each of the 12 settle assertions reds, deleting each settled claim sentence from the docs reds, injecting the refused rater-axis wording reds, an unledgered universal reds, and the collided run-1 fixture reds on exactly the three number-citing rows (0.944; 31/2 and 42/14; E3 missed once, above).

## Decisions

## Review
