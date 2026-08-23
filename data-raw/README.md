# data-raw/ — oracle provenance scripts

## Record-claim checkers

Six checkers live here — `check-mpl-doc-claims.py`, `check-oracle-registry.py`,
`check-record-claims.py`, `check-reference-observations.py`,
`check-vignette-render-warnings.py` and `enumerate-generalizing-claims.py`
[claim:data-raw-checker-inventory] — all stdlib-only `python3` so the R-free
`check-references` CI job can run them. Four
of the six are wired into that job, which invokes a `data-raw` checker eight
times [claim:lint-checker-invocations]: each wired checker twice, once for the
check and once for its vacuity self-test. `check-oracle-registry.py` is run
locally only. `check-vignette-render-warnings.py` runs in the `pkgdown` job
instead, because what it checks is the built site rather than the sources: it
reads `docs/` after `build_site_github_pages()` and before the deploy step, and
reds if a built page shows a load-time dependency version-skew warning. That
warning is what a binary `glmmTMB` built against an older `TMB` prints from
`.onLoad`; because `intraclass` imports `glmmTMB` it renders into every vignette
that loads the package. The workflow prevents it by rebuilding `glmmTMB` from
source against the installed `TMB` when the two are skewed; this checker is the
guard that the prevention held.

Two more checkers here are R rather than `python3`, so neither is matched by
that `ls` and neither runs in the R-free job. `check-checkpoint-sites.R` parses
the R sources it checks and runs in the `checkpoint-guard` job beside the guard
demonstration; it replaced a `python3` predecessor that matched text, which
three separate reversions of a site's guard call walked straight past.
`check-abort-remedy-verdicts.R` is the second, and is run locally.

Whether a checker probes itself is a committed claim rather than an impression
[claim:checker-self-test-status]. Six of the seven carry a `--self-test` that
plants mutations and requires each to red the check, printing one PASS line per
planted mutation so its coverage is counted rather than asserted.
`check-abort-remedy-verdicts.R` is the one that does not: it parses no arguments
at all, so it *accepts* `--self-test` and exits 0 having planted nothing, which
reads exactly like a self-test that passed. It is also the checker with the
least to plant into — what it emits is a verdict ledger over committed sweep
results rather than a check with a pass/fail a mutation could red.

`check-record-claims.py` (M102) re-derives the figures registered in
`record-claims.tsv`. A record states a load-bearing figure by citing the row
that settles it — a `[claim:<id>]` marker — and the checker reads those
citations from the four correctable tracking records the convention names, and
from nowhere else. `cairn/DECISIONS.md` and `cairn/milestones/archive/` carry no
claim citation [claim:no-citations-in-decisions], because a decision entry or an
archived milestone proven wrong is superseded rather than corrected, so a
citation could neither be added to one later nor a drifted figure repaired in
place. Run it, and its `--self-test`, before pushing an edit to a registered
figure.

Every committed reference value in the test suite traces to a seeded script
here (PRINCIPLES.md #4/#12) and an entry in the oracle registry
(`cairn/references/ORACLES.md`). Frequentist oracle scripts follow the
same seeded-provenance pattern and need no special handling; the
**brms/Stan offline verification strategy** below does (M52;
`cairn/DESIGN.md § Known issues`).

## The prose ruler

`prose-profile.py` is not a record-claim checker and is wired into no CI job. It
is a one-shot ruler for the documentation prose passes, run by hand over a glob
of `.Rmd` or `.R` files: it reports, per file, the sentence count, how many
sentences run past 35 words, how many dashes stand in for sentence-level
punctuation, how many parentheticals run past 15 words, and how many semicolons
appear. What it counts as prose, and the writing rules it measures, are defined
in `cairn/doctrine/prose-style.md`.

```
python3 data-raw/prose-profile.py 'vignettes/*.Rmd' --verbose
```

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
2. **Checkpoint**: the long-sweep scripts (15 of 21) write a gitignored
   `data-raw/.oracle-*-checkpoint.rds` after each rep so a crashed run
   resumes instead of restarting.
3. **Fixture written *before* the hard assertions** — so a long run is never
   lost to a marginal pin; the script's own validation then runs against the
   file it just wrote. The five earliest two-way scripts (`oracle-bayesian.R`,
   `-fixed.R`, `-incomplete.R`, `-incomplete-fixed.R`, `-oneway.R`) had their
   fixture write moved ahead of the pins (M107). **Two caveats:** those five
   still have no checkpoint — a crashed run restarts from rep 1; and two
   checkpointed sweeps (`-incomplete-fixed-multilevel.R`,
   `-incomplete-multilevel.R`) still write their *fixture* after their pins —
   the checkpoint preserves the rows on a marginal pin, but adopt
   fixture-save-first when next regenerating either.
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
  the oracle registry entry in `cairn/references/ORACLES.md`.

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
| oracle-bayesian-vignette.R | bayesian-vignette-oracle.rds |
