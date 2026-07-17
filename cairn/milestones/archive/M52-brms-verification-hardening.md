# M52: brms/Stan verification hardening — done 2026-07-16

**Goal:** consolidate the brms engine's offline committed-fixture
verification strategy into a standing documented asset, resolving the
DESIGN § Known issues wart ("largely inherent — mitigate + document").

**Outcome:** `data-raw/README.md` documents the three inherent constraints
(no CI Stan toolchain, MCMC flake, ~2 h sweeps), the three test tiers of
`test-icc-brms.R`, the fixture lifecycle (with an honest caveat: the five
earliest scripts lack the checkpoint/save-before-pin pattern), the
regeneration protocol, and the explicit 20-pair script↔fixture map.
`tests/testthat/test-brms-oracle-map.R` (GP7) guards the map bidirectionally
and pins the README's table; mutation-checked five ways (dropped row,
unmapped fixture, README tamper, README deletion, data-raw-absent skip).
DESIGN wart struck RESOLVED, inherency note kept. `.gitignore` checkpoint
entries consolidated to a glob. No R/ code changes.

**Key review catches (diff-bug lens, all fixed):** README-pin guard was
vacuous against deletion of the README itself; two README claims were
stated as universal but false for the earliest scripts (no checkpoints,
pins before saveRDS; 12/15 checkpoint paths not actually gitignored).

**PR:** https://github.com/jmgirard/intraclass/pull/58 (squash-merged
04eecce; suite 1658 pass, check 0/0/0, full CI matrix green).
