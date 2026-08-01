# M96: Failure accounting in the three MPL coverage-sweep generators

**Status:** done (2026-07-31, PR #103 https://github.com/jmgirard/intraclass/pull/103)

**Goal:** Make a failed `mpl_interval()` fit abort an MPL coverage sweep instead of
being scored as a covered replication.

**Outcome:** The covering-sentinel handler (`error = function(e) c(lower = 0, upper = 1, ...)`)
is gone from all three MPL sweep generators (m90/m91/m92); they route through shared
helpers in `data-raw/m86-mpl-lib.R` (`mpl_failure_log`, `mpl_interval_counted`,
`mpl_cell_failures`, `mpl_assert_no_failures`): failures are recorded per cell, every
summary row carries a `failures` count, and per-cell + pre-write asserts abort naming
the failing cell, removing any checkpoint — no fixture survives a failing run.
`MPL_INJECT_FAILURE="<cell>:<rep>"` injects a failure (run in a disposable copy only);
`data-raw/m96-sentinel-audit.R` audited the four frozen fixtures: 0 sentinel reps in
36000. Pre/post smoke runs bit-identical on the same seeds — accounting-only.

**Decisions:** none milestone-local; the env-var injection mode (over a `--self-test`
flag) is AC4's recorded "or" alternative, matching the generators' `M90_SMOKE` idiom.

**Review:** 3 lenses + scorer, 17 findings, 1 actioned — D2 (83), the documented
injection recipe could delete/overwrite a committed fixture from the repo root; fixed
by disposable-copy guidance in the lib header. 16 sub-threshold logged. Nothing
graduated or retired.
