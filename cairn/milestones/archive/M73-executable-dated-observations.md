# M73: Make every dated observation executable

**Status:** done (2026-07-21, PR #79 https://github.com/jmgirard/intraclass/pull/79)

**Goal:** Make every claim a references page makes about the repo's own state
settled by a re-runnable command rather than by a reader's care.

**Outcome:** D-009 defines the convention: each repo-state observation carries an
inline `<!-- check: <cmd> -->` directive (exit 0 = holds; idiom `! git grep -qlF
'tok' -- <paths>`); provenance `Extraction:` statuses are exempt; `check: none —
reason` marks the unsettleable. `data-raw/check-reference-observations.py` parses
the 30 source notes + `INDEX.md`, runs every directive, and exits non-zero on any
unmarked/falsified observation (with a `--self-test`). 60 observations settled: 48
runnable directives, 12 `none`; 5 source-facts restated as standing facts; ~28
provenance statuses exempt. Corrected one stale claim — tenhove2018's "`irr` is not
a package dependency" (`irr` in Suggests since M42). Docs-only + one `data-raw/`
script; no package file touched.

**Decisions:** D-009 (cross-cutting; in `DECISIONS.md`).

**Review:** three fresh-context lenses + scorer. Blame-history and diff-bug: zero
defects. Prior-review: no regressions but flagged tenhove2018 self-contradiction
(scored 88, the `irr` fix missed line 179) — fixed at review. Two below-threshold
logged (44, 55). CI green across the full `R CMD check` matrix.
