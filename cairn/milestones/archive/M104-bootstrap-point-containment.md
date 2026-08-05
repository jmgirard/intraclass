# M104: What the parametric bootstrap reports when its interval sits above its own point

**Status:** done (2026-08-05, PR #112 https://github.com/jmgirard/intraclass/pull/112)

**Goal:** Measure where `ci_method = "bootstrap"` reports a lower limit above its own point
estimate, commit that measurement, and document the relation it actually holds.

**Outcome:** `data-raw/sweep-bootstrap-point-containment.R` walks the between-subject-variance
axis over two generators into `tests/testthat/fixtures/bootstrap-point-containment.tsv` (48 rows,
12 returned cells per arm, a `status` column keeping an aborting cell visible). `conf.low >
estimate` in 22 rows, all zero-variance-arm, none nonzero; largest gap 2.12e-09, largest point
among them 2.90e-09. `test-bootstrap-point-containment.R` pins that bound against the fixture and
the motivating 6x3 call live. The `@param ci_method` `"bootstrap"` text gains the relation, the
`"npbootstrap"` `@details` claim that the point "reads `0`" is corrected in place, and
`DESIGN.md`'s Bootstrap row carries it. No reported value changed.

**Decisions:** Measure and document over reconciling the numbers or warning — the divergence sits
inside the numerical-zero floor, and a boundary fit yields boundary resamples. Sweep at the
shipped `boot_samples = 999`, not a reduced count.

**Review:** Three lenses, 15 candidates, one >= 80: F1 (88), a causal clause describing the
parametric mechanism inside the `"npbootstrap"` section, where that method aborts at the boundary
— removed; F2 (76) fixed with it, verified false against `lme4`. CI `check-references` red on
unregistered doc claims, fixed. F3/F4/F8 to a candidate row. Prior art the plan gate missed:
RR02 BC6 already recorded `point_outside_rate` for npbootstrap.
