# M100 (dropped): Abort remedies name only a `ci_method` measured to work on the data that triggers them

**Dropped 2026-08-03** at the `/milestone` audit gate, maintainer's disposition.
Branch `m100-abort-remedy-truthfulness` kept; draft PR #108 closed unmerged.
D-021 bars records-verification work absent a defect in what the package
computes. M100's measurement supplies such a defect — so the *bug* ships as a
hotfix — but its remaining deliverable was apparatus (enumeration script,
ledger, evidence-bar D-entry), the class D-021 closes. It had returned from
review five times, with a re-cut and an RB04/RR04 escalation both spent.

**What it measured**, committed on the branch and carried into the hotfix:
`data-raw/sweep-abort-remedies.R` → `abort-remedy-sweep.tsv` (210 seeded rows),
plus `abort-remedy-sites.tsv`, `enumerate-ci-method-remedies.py`, and its
`.txt` output. Four guards name `montecarlo`; measured usable where they fire:

- npbootstrap observed degeneracy, `gen_ssa0`: **0/4** while `bootstrap` is
  **4/4** — the message points away from a working method.
- bootstrap refit convergence / classical MSE = 0 / npbootstrap observed
  degeneracy, `gen_mse0`: **0/6, 0/3, 0/3** — dead ends; nothing is usable there.
- `gen_resample_degenerate`: **9/9**, truthful. `gen_se_zero`: **1/1** — fires
  the runtime-hint candidate's falsifier. Two `main` diagnostic bullets were
  also proved false (review pass ≤3); both go to the hotfix.

**Dropped with it:** the ledger + CI checker, the evidence-bar D-entry, RR04's
record-overclaim recommendations (RB04/RR04 on the branch only).
