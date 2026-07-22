# M79: Complete the oracle registry — an entry for every asserted oracle + a census gate (D-007 invariant)

**Status:** done (2026-07-21, PR #86 https://github.com/jmgirard/intraclass/pull/86)

**Goal:** Make the D-007 registry invariant ("every oracle value traces to an entry here") true again and machine-checked: write an `ORACLES.md` entry for every oracle family the suite asserts but the registry omits, correct the M46/M47-stale cluster-`ICC(c,k)` language, and ship a checker that fails when an asserted oracle has no entry.

**Outcome:** The D-007 invariant now holds and is machine-checked. Shipped `data-raw/check-oracle-registry.py` — exact base-ID coverage of every `O-*` label asserted in `tests/testthat/*.R` against `ORACLES.md` headings/bold-defined sub-oracles + an audited ALIASES allowlist, with a `--self-test` harness bite; exits non-zero on any un-entried oracle. Wrote **16 `ORACLES.md` entries** to the D-008 bar (Kind bullet; fixture/inline confirmation without re-running; source legs anchored to the M72 Source-leg table): frequentist multilevel `O-FML`/`O-IFML`/`O-IML`/`O-NML`/`O-FNML`, lme4-engine `O-LME`/`O-LME2`, d-study `O-IDS`/`O-Boot-DS`, `O-cc`, `O-invariance`, lavaan-ML `O-SEM-ML`/`-BOOT`/`-FIXED`/`-INC`, Bayesian `O-Bayes-cluster-ck`. Corrected the one stale claim (O-Bayes-IML's "averaged cluster ICC(c,k) undefined on incomplete" — M46/M47 shipped it via inverse-Simpson k_c^eff) while preserving the still-open per-cluster M9 §9 divisor mentions; reconciled `INDEX.md` + the registry header (dropped the false "M1–M39 scope" and pinned "39 entries"). No R/test code changed. Left out of scope: a pre-existing D-009 checker failure (candidate below).

**Decisions:** none (governed by D-007/D-008/D-009, PRINCIPLES #4/#12; no new cross-cutting decision).

**Review:** 3 lenses + scorer. Blame-history + prior-review clean. Diff-bug found F1 (scored 82, fixed): `normalize()` stripped `-lme4`/`-sim` off the standalone oracles `O-lme4`/`O-sim`, collapsing them to a wildcard `"O"` registry token that could mask a future gap — guarded the strip past `O-XX`, fixed the false comment, strengthened `--self-test`. No sub-threshold findings.
