# Project status

- Milestone: M7 — SEM engine (`lavaan`) — **in progress** (scope fixed by ADR-014)
- Active task: M7 **done pending PR** on branch `m7-sem-engine` (Slices 1+2:
  `engine = "lavaan"` two-way random + docs; `check()` 0/0/0, full suite green).
  Next: open the PR for the full CI matrix, then merge
- Last green CI: PR #10 (M6) full matrix green (9/9); merged to `main` at eb7102d
- Blockers: —
- Updated: 2026-07-07 by main session (Opus)

## Where we are

Shipped M0–M6 (see [`MILESTONES.md`](MILESTONES.md) for the full record):

- **M0** scaffolding; **M1** two-way random absolute agreement `ICC(A,1)`/`ICC(A,k)`;
  **M2** consistency `ICC(C,·)` + fixed-vs-random; **M3** imbalanced/incomplete
  designs (`k_eff`, connectedness guard, real fixed-effect fit); **M4** the
  flagship "Choosing an ICC" vignette + `ratings`/`ratings_incomplete` datasets;
  **M4.5** D-study projection (`d_study()`, numeric `unit`, `autoplot()`); **M5**
  multilevel subject-/cluster-level ICCs (ten Hove Design 1, five-component fit);
  **M5.5** lme4 as a selectable `engine =` (merDeriv-backed MC CI); **M6** one-way
  random `ICC(1)`/`ICC(1,k)` — the last classic Shrout–Fleiss member.
- The classic SF family is now complete; both glmmTMB and lme4 are selectable
  engines through the M5.5 engine × design dispatch seam.

## M7 scope (fixed this session, maintainer-approved — ADR-014)

M7 promotes **lavaan (SEM / common-factor GT) to a selectable `engine = "lavaan"`**
for the two-way and one-way random paths, plugging a third engine into the M5.5
engine × design dispatch seam behind `check_installed()` (Suggests; light install
preserved). **No new estimand, no estimand-spec** (an engine for existing estimands,
cf. M5.5). Two maintainer decisions:

1. **Lead engine = SEM/lavaan** (over Bayesian brms/rstanarm) — mirrors the low-risk
   M5.5 pattern: reuse the existing Monte-Carlo path (lavaan exposes `vcov()` → no
   new `ci_method`), light install (no Stan compile → CI fast/green), and pinnable to
   a **textbook oracle** (Jorgensen 2021, which also argues for MC CIs — corroborates
   ADR-003).
2. **Design scope = two-way + one-way random.** `raters="fixed"`, multilevel, and
   incomplete/unbalanced designs abort for lavaan (deferred, recorded). The Bayesian
   engine (rstanarm + a new `ci_method = "posterior"`) is deferred to a later slice
   or follow-on milestone.

Two CI-green slices (see [`MILESTONES.md`](MILESTONES.md) M7, [`TASKS.md`](TASKS.md)):
Slice 1 lavaan two-way (congeneric/mean-structure), Slice 2 lavaan one-way (parallel)
+ docs. Named boundary risk (#3): lavaan estimates variances on the raw scale
(Heywood cases) — `to_components` must stay valid at the zero-variance boundary,
pinned by a boundary oracle (the ADR-012 merDeriv-scale analog).

## Next action

**Open the PR for `m7-sem-engine`** (both slices committed) to run the full CI
matrix, then merge; post-merge, reconcile `project/` on `main` (finish-task policy).

M7 shipped `engine = "lavaan"` for the **two-way random** path — the SEM/GT
common-factor model (Jorgensen 2021). Consistency ≡ glmmTMB exactly; absolute
agreement uses the **indicator-mean estimator** σ²_r = Σν²/(k−1) (Jorgensen 2021
Eq. 6; an earlier *unsourced* bias correction was removed, ADR-014) — a distinct,
asymptotically-equivalent estimator that differs from the mixed model by O(1/n) on
small designs (0.284 vs 0.290 on SF), validated against GENOVA/`gtheory` by Vispoel
et al. (2022). One-way SEM deferred (no faithful sourced route → ROADMAP). Oracles
O-SEM; `data-raw/oracle-sem.R`; advanced-vignette SEM section; `check()` 0/0/0.

**Reading-the-source lesson this milestone** (now a memory,
[[ask-for-inaccessible-sources]]): the method was first inferred from abstracts
(publisher blocked the PDFs) and got a bias correction wrong; the maintainer
supplied the PDFs and the plan was corrected. Ask for inaccessible sources rather
than guessing.

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).
