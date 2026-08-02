# M99: MPL interval — distinguish a true boundary limit from a root-finding failure

**Status:** done (2026-08-01, PR #107 https://github.com/jmgirard/intraclass/pull/107)

**Goal:** Make `mpl_interval()` return a boundary endpoint only on evidence of
no deviance crossing, and abort classed on a genuine failure instead of 0/1.

**Outcome:** `R/ci-mpl.R` sign test per side (boundary only when the profile
deviance at the outer bracket edge is finite and ≤ crit) + a degenerate-fit
sanity guard on `f(rho_hat)` (perfect/near-perfect agreement now aborts
`intraclass_engine_error` where the swallow fabricated a vacuous [0, 1]);
mockable `mpl_uniroot` seam; twin `data-raw/m86-mpl-lib.R` mirrored (`stop()`);
five claim surfaces + NEWS narrowed; D-019 records the contract change;
DESIGN.md interval-time table gained the MPL row. Endpoints bit-identical to
pre-M99 on all non-degenerate probes.

**Decisions:** D-019 (narrows D-014/D-015's "interval on every dataset"
framing; degenerate-fit abort + no-method-named chosen at the review gate).

**Review:** one return — the [O] diff-bug lens falsified the plan's
"failure branch unreachable with real data" premise (F1/F2, scored 95);
7 actioned findings (F1-F3, F8, F11-F13) all fixed, 12 sub-80 logged
(7 folded into the fixes, 4 rejected with reason, 1 subsumed by the guard).
