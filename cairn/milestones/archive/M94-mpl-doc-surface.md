# M94: Exported documentation of the MPL interpolation evidence, with a fixture-reading check

**Status:** done (2026-07-31, PR #101 https://github.com/jmgirard/intraclass/pull/101)

**Goal:** tell users what M92 measured about `ci_method = "mpl"` — in `@param` and NEWS —
under a committed check that fails when a documented claim stops being true of the fixture.

**Outcome:** `@param ci_method`/`@param conf_level` now state node calibration, linear-in-S
interpolation, validated-not-calibrated (three off-node 0.95 cells, floor 0.93 as a −2pp
tolerance, min coverage 0.944, no endpoint pinning, miss direction non-uniform via the E2/E3
single-factor rater pair). New enforcement: `data-raw/check-mpl-doc-claims.py` (stdlib-only
RDS reader; the CI job stays R-free) settles every universal/negative claim in the scoped doc
blocks against `m92-interp-sweep.rds` via the ledger `mpl-doc-claims.tsv` (12 settle / 2
absent refusing "nothing isolates the rater axis" / 21 out), cross-checks ledger↔docs both
ways, mutation self-tests, and runs in lint.yaml's `check-references` job.

**Decisions:** none promoted. Local: stdlib parser over a pip dependency; committed TSV
ledger over in-script claims; merge-gate fixes O-12/O-13 (fail-closed ledger guards) and O-7
(false out-row reason corrected — the whole-table pin is M95's).

**Review:** three lenses + scorer, 0 of 37 findings ≥ 80; top sub-80s fixed at the gate;
scorer falsified one claimed repro (O-11 reds via stale-key). Remaining hardening items
carried to a ROADMAP candidate row. No lessons retired.
