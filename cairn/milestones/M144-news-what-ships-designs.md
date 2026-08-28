# M144: NEWS's *What ships* names the designs the package actually supports

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m144-news-what-ships-designs`

## Goal

`NEWS.md`'s *What ships* section names the design support `DESCRIPTION` sells and
the package delivers, which M142's condensation left out.

## Scope

Surface tier: **user-facing** — `NEWS.md` is a shipped surface a reader meets the
package through, and `cairn/doctrine/prose-style.md` governs it.

**In:** item (b) of the "What the 0.1.0 NEWS entry no longer says" candidate row.
*What ships* gains the imbalanced, incomplete and multilevel (nested) design
support that `DESCRIPTION:13-14` sells, and the cluster-level coefficients and
within-cell replicates that two of the eight listed article titles already name
but no bullet does. The added prose satisfies `prose-style.md`'s R1 and R2 and
M142's per-bullet byte cap.

**Out:** items (a), (c) and (d) of that row — the surviving simulation bullets'
missing antecedents, D-019's stale "documented in NEWS" self-reference, and the
vanished brms guarantees. They stay on the candidate row; omission over
restoration was the maintainer's explicit M142 repair direction. Any change to
`glance()$raters` reporting → M143.

## Acceptance criteria

- [ ] AC1. `NEWS.md`'s *What ships* section names the three design capabilities the
      `Description` field of `DESCRIPTION` sells and *What ships* does not name
      today, quoting `DESCRIPTION:13-14` verbatim: "support for imbalanced,
      incomplete, and multilevel (nested) designs". It additionally names
      cluster-level coefficients and within-cell replicates. Those two are NOT in
      `DESCRIPTION` — the lineage row's "`DESCRIPTION:12-14` sells all four" is
      wrong, measured 2026-08-27 — so they are named here on the strength of the
      *Multilevel designs: subject and cluster level* and *D-studies and within-cell
      replicates* articles the same section already lists.
- [ ] AC2. After this milestone,
      `LC_ALL=C awk -f data-raw/m142-bullet-lines.awk NEWS.md | sort -rn` reports
      exactly one bullet over 500 bytes and it is the 797-byte `news_scope()`
      anchor, M142's named exemption; and `python3 data-raw/prose-profile.py
      NEWS.md` reports `dash: 0` and exactly one sentence over 35 words, the pinned
      residual clause. Whole-file figures, since neither instrument scopes to a
      diff. The 500-byte cap is M142's AC1 and the awk header, not a
      `prose-style.md` rule; `dash: 0` is R1, whose four exemptions are unaffected.
- [ ] AC3. The three pinned `NEWS.md` regions still bind: `devtools::test()` passes
      `tests/testthat/test-doc-skew-caveat.R`, whose `width_templates()` (`:976`)
      and `residual_template()` (`:2306`) read the installed `NEWS.md`; and
      `python3 data-raw/check-mpl-doc-claims.py` passes with its three
      `mpl-doc-claims.tsv` NEWS rows still quoting the `news_scope()` anchor
      bullet. All three normalize whitespace, so this claims what they bind, not
      byte identity.
- [ ] AC4. `R CMD check --as-cran` is clean and the six `data-raw/` checkers pass.

## Coverage

- AC1 → T1, T2
- AC2 → T3
- AC3 → T3, T4
- AC4 → T4

## Tasks

- [x] T1. Read `DESCRIPTION:7-17` and the current *What ships* bullets; list what
      each names, and confirm the five capabilities against the shipped surface
      (`?icc`, `?d_study`, the two article titles) rather than against older prose
      — the M142 lesson.
- [x] T2. Write the added text into *What ships*, under the byte and sentence caps
      by construction, touching no pinned region.
- [x] T3. Run both rulers and both NEWS-reading checkers; re-measure after any
      later edit, including one made at the merge gate (M142 lesson).
- [ ] T4. Gate: `devtools::test()`, `--as-cran`, the six `data-raw/` checkers,
      `cairn_validate`.

## Work log

- 2026-08-27: created by /milestone-plan.
- 2026-08-27: criteria audit ran in FULL mode (user-facing tier). Returned a finding on all three drafted criteria: AC1 citing a line range that does not delimit its three noun phrases, resting its universal on a hand-quoted list, and silently narrowing the lineage row's four items to three; AC2 attributing a 500-byte cap and a "zero dashes" rule to `prose-style.md`, which states neither, and scoping to added-or-edited bullets that neither ruler can enumerate; AC3 naming `check-record-claims.py`, whose `SCOPE` (`:156-161`) excludes `NEWS.md` entirely, for two regions that are testthat functions, and claiming byte identity that all three instruments normalize away — the exact word M142's own review returned. All fixed at the gate; none became a question.
- 2026-08-27: plan gate chose deriving AC1's domain from `DESCRIPTION`'s own clause over honouring the candidate row's four-item list because the row's "sells all four" is false against `DESCRIPTION:7-17`; the two items outside it are named on a separately stated basis. Falsified by a capability `DESCRIPTION` sells that this criterion's clause does not reach.
- 2026-08-27: plan gate chose whole-file ruler figures over diff-scoped ones because neither `m142-bullet-lines.awk` nor `prose-profile.py` enumerates added-or-edited bullets, and M142's a-fortiori superset argument is unavailable here — the whole-file figures are non-zero. Falsified by a widened bullet that keeps the whole-file counts at their exemptions.
- 2026-08-27: T1 done. Confirmed all five capabilities against the shipped surface: imbalanced (`man/icc.Rd:292,733`, "unequal ratings per subject"), incomplete (`:68`), multilevel/nested (`cluster` arg `:71-74`; `design` values `:142-143`), cluster-level reporting (`level` arg `:127-129`), within-cell replicates (`occasions` arg `:119-124`; `man/d_study.Rd:156`). `DESCRIPTION:7-17` reads "imbalanced" where `?icc` reads "unbalanced"; AC1 fixes the NEWS wording to `DESCRIPTION`'s.
- 2026-08-27: T2 done. Two bullets added to *What ships* after the `icc()` bullet: one for the imbalanced/incomplete/multilevel design support and cluster-level reporting, one for within-cell replicates and `occasions`. Bullet bytes 437 and 393, both under M142's 500 cap; no pinned region touched.
- 2026-08-27: T3 partial. Both rulers and both NEWS-reading checkers green on the edited file: exactly one bullet over 500 bytes (the 797-byte `news_scope()` anchor), `dash: 0`, one sentence over 35 words (the 74-word pinned residual), `check-mpl-doc-claims.py` OK, and `test-doc-skew-caveat.R` FAIL 0 / PASS 2293 against a fresh install carrying the new bullets. Its two vignette-leg skips are pre-existing: an identical 2293/2-skip run on a stashed clean tree. All six `data-raw/` checkers and `cairn_validate` pass. Not ticked: the full `devtools::test()` verify run is still in flight, and `--as-cran` (T4) has not run.
- 2026-08-27: T3 ticked. The verify slot returned clean: `devtools::test()` FAIL 0 / WARN 3 / SKIP 2 / PASS 9107, exit 0. T4's `--as-cran` leg is still outstanding.

## Decisions

## Review
