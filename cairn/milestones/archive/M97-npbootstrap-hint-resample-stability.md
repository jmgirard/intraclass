# M97: `npbootstrap` in the boundary hint — verified by running it, not predicted

**Status:** done (2026-07-31, PR #104 https://github.com/jmgirard/intraclass/pull/104)

**Goal:** Name `ci_method = "npbootstrap"` in the unbalanced one-way boundary abort —
the only method shipping that cell — only after RUNNING it, never from a predicate.

**Outcome:** `npbootstrap` is a row in M93's `boundary_method_usable()`: the trial
runs under the caller's own `seed` and `boot_samples` (no seed → the fixed
`npb_hint_seed = 1L`, which the bullet then names — the one licensed digit in any
bullet), so the verified run IS the promised retry; RNG-neutral via `with_rng_seed()`,
pinned direct and end-to-end. Unbalanced one-way row restored with the numeric-`unit`
fence mirrored; the sweep spans imbalance shape (balanced/ragged/double-code); the
leak detector now sees `Inf`/`NaN`/`NA`. NEWS + `@param`; the false "negligibly rare
at k >= 10" comment corrected (guard rate 3/8 on the 8×3, all seeds on double-code).

**Decisions:** no-seed case → verify under a fixed, bullet-named seed (gate-approved);
leak-detector carry-in → value-free bullets AND non-finite widening; review
correction — the recorded seed-split was a wrong-divisor artifact (production k_eff
gives 5/8), the decision stands; D-018's discard line held throughout.

**Review:** three lenses + scorer: 12 findings, 6 ≥80, all fixed in-pass — the
harnesses verified a non-production estimand (raw k vs harmonic k_eff) and the check
ignored the caller's `boot_samples` (hinted-at-999/aborts-at-2000); both reproduced,
re-gated (FAIL 0/PASS 5466; check 0/0/0). Two CI-only ledger re-triages. No retirement.
