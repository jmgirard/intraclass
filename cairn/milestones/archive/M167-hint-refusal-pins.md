# M167: The boundary hint's verification counts a refused interval as unusable on glmmTMB and lme4, pinned by tests

**Status:** done (2026-10-19, PR #186 https://github.com/jmgirard/intraclass/pull/186)

**Goal:** Tests pin that `boundary_method_usable()` judges a Monte-Carlo or bootstrap candidate unusable when the equal-limits refusal fires on a glmmTMB or lme4 engine.

**Outcome:** Tests only, in `tests/testthat/test-boundary-abort-hint.R`. Stub engines (`hr_stub()`: zero `vcov`, constant `simulate_refit`, subject = residual = 1, one-way ICC 0.5) named glmmTMB and lme4 reach `intraclass_zero_width_interval` in `mc_ci()` and `bootstrap_ci()`; `boundary_method_usable()` returns FALSE for both methods on both engines, and TRUE in the same block with `refuse_zero_width()` mocked to a pass-through. `bh_site()` labels the refusal "Z" (matched on "lower and upper limits are equal"), the file header lists it as a fourth site, and the M93 sweep asserts Z is never reached. T3 probed 144 real bootstrap fits (glmmTMB and lme4; permuted, small-integer and near-flat data) and found no equal-limits refusal, so no near-collapse case was confirmed. The PR also rotated the `roadmap-terminal-rows` claim in `data-raw/record-claims.tsv`, which the M166 done pass had left stale on main.

**Decisions:** none.

**Review:** four-lens fan-out. 21 findings: 9 fixed now (refusal site in the file header and sweep comment; control in the same block as the FALSE assertions; mock keeps the real defaults; missing seed), 12 rejected with reasons, 1 follow-up to the new parked row "Equal-limits refusal unseen on real fits". CI on PR #186 first failed `check-references` on the stale claim row; fixed on the branch. Hygiene: graduated "M158 review follow-ups on the glmmTMB boundary path"; narrowed "M162 review follow-ups on the engine re-raise" to (a) and (c); M164 rotated out; claim row rotated to M167, M166, M165; no lesson captured (LESSONS at its byte cap), none retired.
