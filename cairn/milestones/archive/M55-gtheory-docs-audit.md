# M55: gtheory-reference docs audit — historical-citation framing

- **Status:** done · **Priority:** normal · **Principles:** GP1 (worked under)
- **PR:** https://github.com/jmgirard/intraclass/pull/61 (squash-merged 2026-07-17)

## Goal
Reframe user-facing `gtheory` mentions as historical validation citations; drop
it from live-comparison / installable-peer contexts, ahead of v0.1.0 (gated M48).

## Outcome
`gtheory` (archived off CRAN 2025-03-24, dep removed M42/ADR-052) no longer
appears as an installable peer: dropped from the comparison-vignette capability
table + incomplete-data mention and the README "Related work" list. Its genuine
agreement (lavaan vs `gtheory`, ≤ .001) is **kept** as an explicitly-historical
citation with one archived-from-CRAN note (also `engines.Rmd`, the
`engine-lavaan.R` comment); added a NEWS Documentation bullet. No behavior change.

## Key decisions
Plan gate (2026-07-17): remove-as-peer + keep the historical citation (user's
lean), user-facing docs only. Column removal is a plan-gated continuation of
ADR-052's citation-only disposition (blame-history lens: not a silent undo).

## Verification
AC1–AC4 met with fresh evidence; tests 1712 pass / 0 fail; three-lens review
zero findings; full CI matrix green. Pre-existing `lavaan's` flag → M48 AC3.
