# M100 (dropped): Abort remedies name only a `ci_method` measured to work on the data that triggers them

**Dropped 2026-08-03** at the `/milestone` audit gate, maintainer's disposition.
Branch `m100-abort-remedy-truthfulness` retained; draft PR #108 closed unmerged.

**Why.** D-021 bars a milestone whose deliverable is verification of this repo's
own records or messages absent a defect in what the package computes. M100's
completed measurement supplies such a defect — so the *bug* ships as a hotfix —
but its remaining deliverable was apparatus (enumeration script, ledger,
evidence-bar D-entry), the class D-021 closes. It had returned from review five
times, with a re-cut and an RB04/RR04 escalation both spent.

**What it measured**, committed on the branch and carried into the hotfix:
`data-raw/sweep-abort-remedies.R` → `abort-remedy-sweep.tsv` (210 seeded rows),
`abort-remedy-sites.tsv`, `enumerate-ci-method-remedies.py`,
`abort-remedy-enumeration.txt`. Four reducer-stage guards name
`ci_method = "montecarlo"`; measured usable on data reaching them:

- npbootstrap observed degeneracy, `gen_ssa0`: **0/4** while `bootstrap` is
  **4/4** — the message points away from a working method.
- bootstrap refit convergence / classical MSE = 0 / npbootstrap observed
  degeneracy, `gen_mse0`: **0/6, 0/3, 0/3** — dead ends; nothing is usable there.
- npbootstrap degenerate resamples, `gen_resample_degenerate`: **9/9**, truthful.
- npbootstrap observed degeneracy, `gen_se_zero`: **1/1** — fires the
  runtime-hint candidate's falsifier. Two diagnostic bullets on `main` were also
  proved false (review pass ≤3); both go to the hotfix.

**Dropped with it:** the ledger + CI checker, the evidence-bar D-entry, RR04's
record-overclaim recommendations (RB04/RR04 on the branch only).
