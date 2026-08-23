# Doctrine: the data-raw checker suite and the check-references CI job

This page owns the operating knowledge for the repo's `data-raw/` record
checkers and the `check-references` CI job that runs them — what each checker
gates, what stales each ledger, and when to run them locally. It is a doctrine
module graduated from `cairn/LESSONS.md` (the M85 family, extended at M91, M97,
M104, M105, and M111) under the maturation exit; the checkers' own headers and
`data-raw/README.md` stay the reference for invocation details, and the
milestone measurements live in `cairn/milestones/archive/` (cross-references
only).

## The job, and why local green is not enough

The `check-references` CI job runs four python3 checkers that
`cairn_validate` does **not** cover — so a locally-green consistency gate
(`cairn_validate`, `devtools::check()`, lintr, air) can still fail CI (measured
at M85 and again, all-local-gates-green, at M104):

1. `enumerate-generalizing-claims.py --check` — the M74 generalizing-claim
   completeness gate over `cairn/references/` pages.
2. `check-reference-observations.py` — D-009 dated-observation settling
   directives on references pages.
3. `check-mpl-doc-claims.py` — MPL roxygen/NEWS sentence pins (M94).
4. `check-record-claims.py` — registered figures in tracking prose (M102).

**Run all four locally before any push touching `cairn/references/`, ROADMAP
terminal rows, or a `data-raw/` ledger.**

The job runs on a **python-only runner with no R**: a D-009 `check:` directive
written as `Rscript -e ...` always reports FALSIFIED there (`Rscript: command
not found`) while passing locally. Every `check:` directive must be settleable
with python3/shell/git alone; a claim about `.rds` contents is restated against
committed text (a markdown table, a script literal) and mutation-verified to
red when the fact changes (M91).

## What stales each ledger

- **Generalizing claims** (`data-raw/generalizing-claims-triage.tsv`): any edit
  to a `references/` page that adds a range/superlative/"never"/"exactly
  one"/decimal-range claim needs a triage row keyed by the enumerator's
  `citekey:hash`; a repo-internal claim (derived result, committed fixture)
  triages `OUT-oracle-pin` (M85, M76). Correcting an EXISTING claim in place
  stales it the same way — the hash is over the claim text, so the old row
  orphans and the corrected text enumerates as un-triaged. Rekey the row in
  place, keeping its class when the claim's nature has not changed, and re-run
  after every such edit: M133 paid this twice on one `ORACLES.md` line, once on
  an already-pushed branch tip.
- **MPL doc claims** (`data-raw/mpl-doc-claims.tsv`): rewording the pinned
  `@param conf_level`/`ci_method` roxygen blocks or NEWS MPL-scope sentences
  needs the row re-triaged (quote + claim key); a **new** universal/negative
  sentence needs a new row (M97). A claim the ledger's fixture cannot settle
  still needs a row, dispositioned `out` with a reason naming the instrument
  that does settle it (M104). Striking one clause stales the row by
  **full-sentence key-hash** while the quoted fragment is untouched — grepping
  the ledger for the changed words finds nothing, so re-run the checker after
  any edit inside those blocks, however small (M105).
- **Record claims** (`data-raw/record-claims.tsv`): a ROADMAP terminal-row
  rotation stales the `roadmap-terminal-rows` expectation — update the row **in
  the same commit** as the rotation. A docs-only push to main never runs the
  job (the M77 `paths-ignore` behavior), so the red surfaces on the next PR
  that touches any non-ignored file: a `check-references` failure on a branch
  is therefore not evidence the branch caused it — re-run against a clean `git
  archive origin/main` before attributing, and fix a main-side stale record at
  its own trivial tier on main (rotation and job mechanics M111; the
  attribution-and-remedy rule M114/M122 — recurrence history in the standing
  LESSONS line). The `no-citations-in-decisions` rule reds on a literal claim
  token quoted in `cairn/DECISIONS.md` or an archive summary — name the claim,
  never paste the bracket form (M111).
