# M144: NEWS's *What ships* names the designs the package actually supports

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m144-news-what-ships-designs` / https://github.com/jmgirard/intraclass/pull/155

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

- [x] AC1. `NEWS.md`'s *What ships* section names the three design capabilities the
      `Description` field of `DESCRIPTION` sells and *What ships* does not name
      today, quoting `DESCRIPTION:13-14` verbatim: "support for imbalanced,
      incomplete, and multilevel (nested) designs". It additionally names
      cluster-level coefficients and within-cell replicates. Those two are NOT in
      `DESCRIPTION` — the lineage row's "`DESCRIPTION:12-14` sells all four" is
      wrong, measured 2026-08-27 — so they are named here on the strength of the
      *Multilevel designs: subject and cluster level* and *D-studies and within-cell
      replicates* articles the same section already lists.
- [x] AC2. After this milestone,
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
- [x] T4. Gate: `devtools::test()`, `--as-cran`, the six `data-raw/` checkers,
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
- 2026-08-28: T4 done. `devtools::check(args = "--as-cran")` Status: OK, 0 errors / 0 warnings / 0 notes, 13m57s, its own `testthat.R` leg OK. The six `data-raw/` checkers and `cairn_validate` pass. All tasks checked; status to review. No plan amendment was needed and no milestone-local decision arose.

## Decisions

## Review

- 2026-08-28: PR #155 opened as draft. `main` in sync with `origin/main`; branch 2 ahead / 0 behind, so no merge-forward was needed.

### Acceptance-criterion evidence

- AC1 — PASS. `DESCRIPTION` lines 13-14 read "boundary-aware Monte-Carlo confidence intervals, support for imbalanced, / incomplete, and multilevel (nested) designs, decision-study projection to". `NEWS.md`'s *What ships* now carries the phrase "support for imbalanced, incomplete, and multilevel (nested) designs" — matched against the DESCRIPTION field with whitespace normalized, since both surfaces hard-wrap the sentence at different columns (raw `grep` for the flat string finds it in neither file). The same bullet names cluster-level reporting ("reports reliability at the cluster level as well as the subject level") and cites *Multilevel designs: subject and cluster level*; the following bullet names within-cell replicates ("gives a within-cell replicate design", "the mean of the replicates") and cites *D-studies and within-cell replicates*. Both cited article titles appear verbatim in the section's own eight-article bullet.
- AC2 — PASS. `LC_ALL=C awk -f data-raw/m142-bullet-lines.awk NEWS.md | sort -rn`: exactly one bullet over 500 bytes, the 797-byte bullet opening "The `ci_method = \"mpl\"` documentation states the interpolati", which is the anchor `news_scope()` (`data-raw/check-mpl-doc-claims.py:280-294`) matches on. The two added bullets measure 437 and 327 bytes. `python3 data-raw/prose-profile.py NEWS.md`: `sent 53, >35 = 1, dash 0, paren 1, semi 2, max 74` — `dash: 0` and exactly one over-35-word sentence, at 74 words the pinned residual clause.


### Independent fresh-context review — three-lens fan-out (2026-08-28)

User-facing tier, so the full fan-out ran. All findings reported below, ranked as each lens ranked them; dispositions recorded at the merge gate.

**[S] prior-PR-comments lens — no findings.** The `gh api .../pulls/comments` probe returned `[]` (no real inline review threads in this repo), so the per-PR walk was skipped. Primary evidence was the archived `## Review` of M142, the direct predecessor on `NEWS.md`: its round-1 defect was condensation dropping bounding qualifiers and asserting capabilities `icc()` refuses, and it filed the absence of multilevel/incomplete support from *What ships* as the candidate row this milestone promotes. The lens found the diff closes that gap rather than reintroducing or contradicting any prior finding.

**[S] blame-history lens — one finding.**

- [S] 1. The T2 work-log line records the two added bullets as "437 and 393" bytes; `m142-bullet-lines.awk` measures 437 and **327**. A record-accuracy slip in tracking prose, not a scope or intent violation; AC2's condition is unaffected. (The lens also confirmed the change is the authorised item (b) of the M142 candidate row and not a silent reversal of M142's "omission over restoration" direction, which still governs items (a), (c), (d) — all correctly listed Out.)

**[O] diff-bug lens — eight findings.**

- [O] 1. `NEWS.md` — "A `cluster` column switches on the multilevel ICC, which reports reliability at the cluster level as well as the subject level" is true only for Design 1 (crossed). Confirmed against the implementation at review: `R/icc.R:259-260` ("Only `"subject"` is available when raters are nested in clusters"), `R/icc.R:2218-2228` forcing `level = "subject"` for Design 3, `vignettes/multilevel-designs.Rmd:120-123` ("no between-cluster reliability to report … `icc()` returns the subject level only"), `:170` ("the cluster level is gone") and `:297` ("Design 3 reports no fixed-rater or cluster-level coefficient"). A NEWS claim wider than the shipped surface — the M142 round-1 defect class.
- [O] 2. `NEWS.md` — "`icc()` then splits the single-rating residual into a subject-by-rater interaction and pure error" is stated without its refusals. Confirmed: `R/icc.R:1400-1410` aborts replicates for Design 3, `:1414-1420` for fixed-rater multilevel, `:1436-1442` for ragged/incomplete multilevel. The neighbouring `d_study()` bullet carries the house pattern this one drops ("and where it refuses").
- [O] 3. `NEWS.md` — "`occasions` reports the reliability of one rating or of the mean of the replicates" overstates `"average"`. Confirmed: `R/icc.R:1917-1921` aborts `occasions = "average"` on ragged or incomplete replicates, and the roxygen says the same at `:157-158`.
- [O] 4. `NEWS.md` — the imbalanced/incomplete/multilevel sentence carries no refusal pointer, unlike the bullets around it; incomplete fixed-rater cluster-level estimation and ragged multilevel replicates abort (`vignettes/multilevel-designs.Rmd:296-297`, `R/icc.R:1439`).
- [O] 5. `NEWS.md` — "switches on the multilevel ICC" omits that `cluster` is undefined for `model = "oneway"` (`R/icc.R:215-216`). Low impact; two-way is the default.
- [O] 6. Work-log byte figure wrong — the same finding as [S] 1, reached independently.
- [O] 7. All four acceptance criteria were still unticked while every task was ticked. Expected mid-review: AC fencing ticks each box as its evidence line lands, and the lens read the tree before AC3/AC4 evidence existed.
- [O] 8. The two added bullets read "See `?icc` and *Article*" where the section's other bullets read "See *Article* and `?icc*`". Cosmetic ordering.

**Verified clean by [O]:** the `DESCRIPTION:13-14` quote is verbatim; both cited article titles match `vignettes/multilevel-designs.Rmd:2` and `vignettes/d-studies-and-replicates.Rmd:2`; the awk and prose-profile rulers reproduce; `check-mpl-doc-claims.py` passes; the "unequal ratings per subject / missing ratings" gloss and the component names match `R/icc.R:135-152` and `:196-207` for the designs where they apply.
