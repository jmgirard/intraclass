---
name: new-estimator
description: Scaffold a new ICC estimator with its estimand block, test skeleton, and oracle checklist. Use when adding a new ICC variant (e.g. consistency, one-way, multilevel).
allowed-tools: Read, Grep, Glob, Edit, Write
---

## Instructions
Scaffold a new estimator **without** leaving it un-oracled (refuse otherwise —
PRINCIPLES.md #1). Produce, in order:

1. **Estimand block first** (PRINCIPLES.md #2, before any code): a short spec
   naming the population quantity — which variance components are in the
   numerator/denominator, single vs. average, agreement vs. consistency, fixed vs.
   random raters, and the identifiability conditions. Follow the pattern in
   `project/estimand-specs/`. Represent the ICC as **(signal component, {error
   component set}, averaging divisor)** so variants are choices of the error set and
   divisor, not new code paths.
2. **Function stub** in `R/` with roxygen including the "Which ICC is this, and
   when should you use it?" note and the key tradeoff (PRINCIPLES.md #13), `cli`
   messaging and classed errors via the `abort_*()` layer (PRINCIPLES.md #8).
3. **Test skeleton** in `tests/testthat/` with the required **oracle checklist**
   (≥2 independent types): textbook/analytic, established package, seeded
   simulation. The oracle *plan* lives in the estimand-spec (its oracle-set section);
   **register a row in `project/REFERENCES.md` only once the oracle is asserted
   green**, naming the test file and provenance (ADR-015 single-source — REFERENCES
   holds no "planned" state; PRINCIPLES.md #4).
4. **A `project/DECISIONS.md` stub** if the estimator involves a modeling choice.

Add the task to the **active milestone's board in `project/MILESTONES.md`** (ADR-015;
there is no separate `TASKS.md`). Do not implement the numerics until the estimand
and oracle plan are written.
