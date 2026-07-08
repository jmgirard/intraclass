# Project status

- Milestone: **M14 — lme4 engine parity** — shipped (PR #18). `engine = "lme4"` now
  matches glmmTMB across every balanced/complete design. The ADR-017 arc (M0–M13) plus
  M14 are all shipped; the package is at v0.1.0, submission-ready. No milestone in flight.
- Active task: — (M14 shipped; next code work is another maintainer-chosen backlog
  promotion — see Next action.)
- Last green CI: PR #18 (M14) full matrix green incl. Windows and R-devel; merged to
  `main` at 474e0c1
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M14 merged (PR #18) + `project/` reconciled

## Where we are

**Shipped M0–M14** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
source; not restated here, ADR-015). In short: the classic Shrout–Fleiss ICC family
is complete; glmmTMB, lme4, and lavaan are selectable engines through the M5.5 engine ×
design dispatch seam, and **lme4 now has full balanced design parity with glmmTMB —
two-way random/fixed, one-way, and every multilevel design (M14)**; the multilevel
estimator covers ten Hove et al. (2022) Designs
1–3 (crossed + both nested-rater); the crossed design handles **incomplete (ragged)**
data (subject level + cluster-level `ICC(c,1)`) with a declared-`design` disambiguation
and oracle-pinned identifiability guards (M9); and the crossed design also supports
**fixed raters** at the subject level, balanced (M10). The multilevel family is now
crossed × {complete, incomplete} × {random, fixed} at the subject level. Every fitted
`icc` object now has `autoplot()`/`plot()` methods — a coefficient forest plot and a
variance-component decomposition (M11). And `choose_icc()` turns the *Choosing an ICC*
decision tree into an interactive/programmatic helper that recommends a coefficient and
emits the exact `icc()` call — teaching/API, no new estimand (M12). And release polish
brought the pkgdown site, the M9–M12 showcase in `advanced.Rmd`, and a **CRAN-submittable
v0.1.0** (`--as-cran` 0/0/0), closing the ADR-017 arc (M13).

## Next action

**No milestone is in flight — M14 is shipped.** Two independent threads remain, both
maintainer-initiated:

1. **CRAN submission (out of band, ADR-022).** The package is submission-ready. Before
   uploading, run **win-builder** (R-devel + release) and **R-hub**, then update the
   "will be run immediately before submission" line in `cran-comments.md` with the
   results. `intraclass` does not (and cannot) submit for you. *(Note: M14 folded its
   lme4-parity changes into the existing `0.1.0` NEWS section rather than bumping to a
   dev version, on the basis that 0.1.0 has not yet been uploaded — revisit if 0.1.0 is
   frozen for submission.)*
2. **Next code milestone = another backlog promotion** (no pre-planned M15). The strongest
   remaining candidates, each needing a start-of-milestone scope pass + ADR: the
   **Bayesian engine** (rstanarm + `ci_method = "posterior"`); the M9 **averaged
   cluster-level `ICC(c,k)` on incomplete data** (open divisor — a simulation-oracle/Fable
   candidate); **incomplete/ragged lme4** for the M14 shapes (the natural follow-up now
   that balanced lme4 parity is complete); **replicate ratings within cell**.

Deferred out of M14 and still parked (not scheduled): **incomplete/ragged lme4** for the
new shapes; the **parametric-bootstrap `ci_method`** (bootMer); the **Bayesian engine**
(rstanarm + `ci_method = "posterior"`); the M9 **averaged cluster-level `ICC(c,k)` on
incomplete data** (open divisor, spec §3b); **one-way / general ICC(1) via SEM** (no
faithful sourced route — ADR-014). All in [`ROADMAP.md`](ROADMAP.md).

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).
