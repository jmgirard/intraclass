# M139: The declared R floor is a measured number CI runs (GP3)

**Status:** done (2026-08-26, PR #150 https://github.com/jmgirard/intraclass/pull/150)

**Goal:** Replace the inferred `R (>= 4.0.0)` floor with the oldest R release that actually installs the Imports chain and passes `R CMD check`, and put a CI job on that exact version, closing GP3's recorded tension before submission.

**Outcome:** `DESCRIPTION` declares `R (>= 4.5.0)`, measured rather than
inferred. A temporary `r-floor-sweep.yaml` (run 33016177595, deleted at T7) ran
eight candidate versions on one fixed `ubuntu-22.04` runner recording four
outcomes each — `setup-r`, Imports-chain install, check-dependency install,
`R CMD check` — so a provisioning failure and a Suggests-only failure stay
distinguishable from a package floor. `setup-r` succeeded on all eight; the
Imports chain failed on 4.0.0 through 4.4.3 and installed on 4.5.0 and 4.5.1. Two mechanisms: `pbkrtest` declares `R >= 4.2.0`,
and `Deriv` 4.3.0 fails to compile below 4.5.0 (`R_ClosureFormals` undeclared).
The chain is `glmmTMB` -> `pbkrtest` -> `doBy` -> `Deriv`; nothing in this
package's own code needs 4.5.0. `check-standard.yaml:38` gains an
`ubuntu-latest` R 4.5.0 job on both the `push` and `pull_request` events (six
and three configs). GP3's parenthetical now states the matrix per event; the
Platforms bullet, `cran-comments.md` and a NEWS Requirements section carry the
new literal; `record-claims.tsv` gains the `r-floor-declared` row, proved able
to red by planting `R (>= 4.4.0)`.

**Decisions:** D-039 — the floor is measured, not inferred, superseding the M48 review gate's decision to leave 4.0.0 untested; the Known-issues entry it created is resolved.

**Review:** Three fresh-context reviewers (user-facing tier). Blame-history [S] and prior-review-record [S] returned zero findings; diff-bug [O] returned twelve. Actioned: `cran-comments.md`'s stale five/two matrix description and the ledger row's claim wording, both fixed at the gate; the DESCRIPTION-to-workflow binding gap cross-referenced to the existing M48 AC7 candidate row. Eight rejected as intentional, pre-existing, or already handled in the pass; the `paths-ignore` filter going unnamed in GP3 was put to the maintainer and declined. Nothing retired or graduated.
