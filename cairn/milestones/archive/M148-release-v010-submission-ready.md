# M148: v0.1.0 is submission-ready, and the upload is handed off

**Status:** done (2026-08-29, PR #159 https://github.com/jmgirard/intraclass/pull/159)

**Goal:** Close the v0.1.0 release the maintainer declared open: a tarball that checks clean, a `cran-comments.md` in which every environment named carries a result, and an ordered handoff checklist for the acts ADR-022 reserves to the maintainer.

**Outcome:** No change to what the package computes; the deliverable is the submission
record. `R CMD check --as-cran` on the `R CMD build` tarball reports `Status: 1 NOTE` —
CRAN incoming feasibility's `Maintainer:` + `New submission`; a
`_R_CHECK_CRAN_INCOMING_=FALSE` re-run returns `Status: OK`, pinning that NOTE's identity.
`cran-comments.md` carries that run's own header (R 4.6.1, `aarch64-apple-darwin23`, macOS
Tahoe 26.6.2) and result, and its *Test environments* section names only environments
already run against 0.1.0, each with its outcome: the local run, and
`check-standard.yaml:38`'s six-configuration push matrix read `completed`/`success` from
`gh api .../commits/0d651437c5e01ed76551c729be9e5ee456caa999/check-runs`. Matrix-to-tarball
identity is established, not asserted: all eight paths changed since that SHA are absent
from the 197-entry `tar tzf` manifest, with `DESCRIPTION`/`NAMESPACE`/`R/icc.R` as passing
controls; the scheduled-but-unrun block is gone, so win-builder and R-hub appear nowhere in
the file. New `cairn/RELEASE-HANDOFF.md`: seven numbered maintainer steps with commands —
win-builder devel/release, R-hub (rhub 2.x setup, absent locally), `submit_cran()`, the CRAN
confirmation email, `use_github_release()`, `use_dev_version()` — plus a send-back route.

**Decisions:** Milestone-local: the plan gate pinned M147's merge SHA plus a tarball-manifest identity check rather than resting a criterion on the six-config matrix, which runs only post-merge; AC1 was amended at an implement-phase mini gate from `Status: OK` to 0 errors / 0 warnings with any NOTE being the new-submission NOTE, that demand being unreachable on a networked `--as-cran` run for a package not yet on CRAN.

**Review:** Three-lens fan-out (user-facing tier), run in-session rather than in fresh-context subagents — delegation not authorized this session, the departure M145–M147 also recorded. One round, no defect returns. Blame-history [S] zero findings; prior-review [S] found no PR-thread surface (0 inline comments repo-wide) and one regression from the archived record; diff-bug [O] the same one. Finding 1, fixed at the gate on the maintainer's selection: `cran-comments.md` justified the tarball exclusion by "all under `cairn/` and `data-raw/`" while `cran-comments.md` itself was among the eight changed paths and under neither — the same hand-authored-release-fact class as M48's twice-failing AC3 and M139's stale matrix description. All five criteria verified fresh; `cairn_validate` exit 0; 11 of 11 PR checks green.
