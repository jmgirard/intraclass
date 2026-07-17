# data-raw/ — oracle provenance scripts

Every committed reference value in the test suite traces to a seeded script
here (PRINCIPLES.md #4/#12) and an entry in the oracle registry
(`cairn/references/REFERENCES.md`). Frequentist oracle scripts follow the
same seeded-provenance pattern and need no special handling; the rest of
this README documents the **brms/Stan offline verification strategy**, which
does (M52; `cairn/DESIGN.md § Known issues`).

## Why the brms engine is verified offline

Three constraints are inherent, not fixable:

1. **No Stan toolchain on CI.** CI runners have the brms *package* but no
   working Stan C++ toolchain, so `brms::brm()` fails at compile time
   (`Boost not found`) — an error, not a skip. Live-Stan tests therefore
   carry `skip_on_ci()` (see `tests/testthat/test-icc-brms.R` ~line 1583).
2. **MCMC flake.** Point/interval values are functions of posterior draws
   and drift across brms/Stan versions and sampler noise — live numeric
   pins and fitted-print snapshots are brittle by construction.
3. **Coverage sweeps are ~2-hour jobs.** A coverage oracle (n_rep ≥ 240 per
   cell × several cells, per-rep seeding) is a long offline run (M47).

The mitigation is the **committed-fixture strategy**: heavy computation runs
once, offline, seeded, with its full provenance in a script header; the test
suite then re-asserts the committed result everywhere, cheaply.

## The three test tiers (tests/testthat/test-icc-brms.R)

| Tier | Gate | What runs |
|---|---|---|
| No-fit | none beyond `skip_if_not_installed()` on two Suggests-dependent tests (coda, brms) | classed coupling/scope aborts, reducers (`posterior_mode()`, `hpdi_interval()` vs the independent coda oracle), deterministic print/tidy structure (never MCMC-numeric snapshots) |
| Fixture | `skip_if_not(file.exists(fixture), "run data-raw/… to generate")` | committed `.rds` references re-asserted against each source's qualitative findings (bias/coverage/convergence contrasts) — fast, no fitting; fixtures are committed, so these run on every CI job |
| Live-Stan | `skip_on_cran()` + `skip_on_ci()` | the one end-to-end Stan smoke fit, plus live parity/reduction oracles (O-Bayes-agree, O-PriorReduce, O-HPDI) — local only, where the toolchain exists |

`devtools::check()` must be run with `env_vars = c(NOT_CRAN = "false")` to
keep the live-Stan suite out of a check run — a shell `NOT_CRAN` alone is
overridden and the suite then flakes on MCMC noise.

## Fixture lifecycle

1. **Script** (`oracle-bayesian-*.R`): seeded (#12), with a provenance
   header — oracle id (O-…), source citations with page/figure anchors, the
   DGP, and the guardrails (#4/#18: divergences from the source are
   *reported*, never tuned away; the MAP estimator is fixed a priori and
   independent of the source's tool).
2. **Checkpoint**: the long-sweep scripts (15 of 20) write a gitignored
   `data-raw/.oracle-*-checkpoint.rds` after each rep so a crashed run
   resumes instead of restarting.
3. **Fixture written *before* the hard assertions** — so a long run is never
   lost to a marginal pin; the script's own validation then runs against the
   file it just wrote. **Caveat:** the five earliest two-way scripts
   (`oracle-bayesian.R`, `-fixed.R`, `-incomplete.R`, `-incomplete-fixed.R`,
   `-oneway.R`) predate both practices — no checkpoint, pins *before*
   `saveRDS()`. When regenerating one of those, adopt the save-first +
   checkpoint pattern in the script first, or a marginal pin aborts the run
   with nothing written.
4. **Commit** the fixture (`tests/testthat/fixtures/*.rds`); the test suite
   pins the qualitative findings with tolerances that absorb finite n_rep.

## Regeneration protocol

Regenerate a fixture **only when shipped behavior changes** (estimator,
prior, reduction); never to make a red pin green — a failing stochastic pin
means *fix the evidence, never the bar* (DESIGN GP5; raise n_rep / per-rep
seeding, as in the ragged n_rep ≥ 240 lesson, ADR-042 Amdt 2).

- Launch as a **background job from the start** (~2 h; AV/concurrent-R
  contention roughly doubles per-fit time — M47).
- Keep per-rep seeding so cells are reproducible and resumable.
- Sweep the known failure axis (DESIGN GP6): include the boundary cell
  (k = 2 undercoverage) and, for cluster-level claims, a high-cluster-count
  cell (ADR-046 Amdt 1).
- Update the script header's DGP/findings notes if the design changed, and
  the oracle registry entry in `cairn/references/REFERENCES.md`.

## Script ↔ fixture map

Authoritative, mechanically guarded copy:
`tests/testthat/test-brms-oracle-map.R` (M52, GP7) — it fails when this
table, the scripts on disk, and the committed fixtures disagree. Note the
irregular abbreviation: three `*multilevel*` scripts map to `*ml*` fixtures,
while `multilevel-fixed` / `multilevel-replicates` stay unabbreviated.

| Script (`data-raw/`) | Fixture (`tests/testthat/fixtures/`) |
|---|---|
| oracle-bayesian.R | bayesian-oracle.rds |
| oracle-bayesian-cluster-ck.R | bayesian-cluster-ck-oracle.rds |
| oracle-bayesian-conflated.R | bayesian-conflated-oracle.rds |
| oracle-bayesian-fixed.R | bayesian-fixed-oracle.rds |
| oracle-bayesian-fixed-replicates.R | bayesian-fixed-replicates-oracle.rds |
| oracle-bayesian-incomplete.R | bayesian-incomplete-oracle.rds |
| oracle-bayesian-incomplete-fixed.R | bayesian-incomplete-fixed-oracle.rds |
| oracle-bayesian-incomplete-fixed-multilevel.R | bayesian-incomplete-fixed-ml-oracle.rds |
| oracle-bayesian-incomplete-fixed-nested.R | bayesian-incomplete-fixed-nested-oracle.rds |
| oracle-bayesian-incomplete-multilevel.R | bayesian-incomplete-ml-oracle.rds |
| oracle-bayesian-incomplete-nested.R | bayesian-incomplete-nested-oracle.rds |
| oracle-bayesian-incomplete-nested-subjects.R | bayesian-incomplete-nested-subjects-oracle.rds |
| oracle-bayesian-incomplete-oneway.R | bayesian-incomplete-oneway-oracle.rds |
| oracle-bayesian-multilevel.R | bayesian-ml-oracle.rds |
| oracle-bayesian-multilevel-fixed.R | bayesian-multilevel-fixed-oracle.rds |
| oracle-bayesian-multilevel-replicates.R | bayesian-multilevel-replicates-oracle.rds |
| oracle-bayesian-nested.R | bayesian-nested-oracle.rds |
| oracle-bayesian-nested-fixed.R | bayesian-nested-fixed-oracle.rds |
| oracle-bayesian-oneway.R | bayesian-oneway-oracle.rds |
| oracle-bayesian-replicates.R | bayesian-replicates-oracle.rds |
