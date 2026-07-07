# Project status

- Milestone: M1 — two-way random, absolute agreement (complete, pending sign-off)
- Active task: — (awaiting go-ahead to plan M2)
- Last green CI: pending push (local: check 0/0/0, coverage 94%, air/lint clean)
- Blockers: —
- Updated: 2026-07-06 by main session (Opus)

## Next action

M1 is built and locally green: `icc()` for `ICC(A,1)`/`ICC(A,k)` (glmmTMB engine,
boundary-aware Monte-Carlo CIs, `print`/`summary`/`format`/`tidy`/`glance`),
verified against 5 oracles (Shrout & Fleiss, `psych::ICC`, ANOVA mean squares,
seeded simulation, lme4 cross-check), plus the Getting-started vignette. Push and
confirm CI green, then **await sign-off before planning M2** (consistency ICCs +
fixed raters + generalized estimand abstraction — see [`MILESTONES.md`](MILESTONES.md)).
