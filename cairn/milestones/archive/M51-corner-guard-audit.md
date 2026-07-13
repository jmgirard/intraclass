# M51: Statistical-corner guard audit — DONE (2026-07-13)

PR: https://github.com/jmgirard/intraclass/pull/57 · Principles: GP5, GP6, GP7

**Goal.** Guard the correct-but-non-obvious statistical corners so a future
"simplification" fails a test instead of requiring ADR archaeology (GP7).
Test + comment insurance only — no R behavior change.

**Outcome.** New `tests/testthat/test-corner-guards.R` (consolidated GP7 asset,
mirrors M50's `test-boundary-policy.R`). A curated + "silently-wrong-number"
filter over the ~40 R/ ADRs kept six corners; two unguarded ones now pinned:
- **A. Fixed-rater 2b moment family** (`theta2r_moment_draws` /
  `theta2r_nested_draws` / `brms_theta2r_moment_draws`): direct hand-computed
  guards pinning **2b-not-1b** + **average- not per-group floor** (ADR-037/038;
  0.4725 vs 1b 0.7475 vs per-group 0.75). Mutation-confirmed the gap — the
  frozen O-NFI fixture + a live containment check both missed it.
- **D. Ragged `n_rep ≥ 240`** pin on the incomplete-fixed-nested fixture (GP5).
Already-guarded B/C/E/F (brms MAP mode / SEM Case-3A / cluster axis /
incomplete-agreement) confirmed live + cross-referenced. Helpers got in-place
guard references; DESIGN.md § Known-issues wart → RESOLVED.

**Verification.** Installed `devtools::check` 0/0/0 both ways (`NOT_CRAN=false`;
`NOT_CRAN=true CI=true`); guards green; all CI green. Three-lens review: 1
finding (blame-history, scored 85, fixed) — nested guard test mislabeled
ADR-046 vs ADR-038.
