# M158: glmmTMB fits retry a variance stuck at zero, and a zero-width interval is refused

**Status:** done (2026-10-11, PR #177 https://github.com/jmgirard/intraclass/pull/177)

**Goal:** A default-engine fit that stops with a variance near zero is refit once from a second start. On the planted grid the second fit reaches the REML optimum. On a glmmTMB fit under `ci_method = "montecarlo"` or `"bootstrap"`, `icc()` refuses an interval whose two limits are exactly equal. The Monte-Carlo overflow abort no longer tells a glmmTMB user to refit with glmmTMB.

**Outcome:** `fit_glmmtmb_ml_model()` refits a glmmTMB fit whose random-effect or residual SD is below 1e-2 of `sd(score)` from a second start (`glmmtmb_retry_start()`).
If the second REML objective is lower by more than 1e-6 (`glmmtmb_keep_tol`), or only it is finite, `glmmtmb_second_wins()` keeps the second fit.
A first fit that fails shows its held warnings through `glmmtmb_warn()`, and its error propagates unchanged.
`refuse_zero_width()` runs in `mc_ci()` and `bootstrap_ci()`. On a glmmTMB interval whose limits are finite and exactly equal, it raises `intraclass_zero_width_interval`, also `intraclass_singular_fit`.
`mc_interval()` takes the engine object, and its overflow remedy names glmmTMB only to callers on other engines.
The degenerate-data test in `test-boundary-abort-hint.R` accepts an error or a result with no exactly equal interval (GP9).
Tests: `test-glmmtmb-false-zero.R`, with the shared frame in `helper-glmmtmb-frames.R`.

**Decisions:** D-048 (second start and refusal, superseding three D-004 cells) and D-049 (exact equality and the 1e-6 margin, superseding D-048's width bound and kept-fit rule).

**Review:** Pass 1 returned the milestone. The width bound `sqrt(.Machine$double.eps)` refused correct tight intervals near ICC 1, and the user chose exact equality at a re-cut.
Pass 2 used the three-lens fan-out and had 32 findings. Five were fixed on the branch in `004aaae`: the error stack is kept, warning text is not read as cli markup, and the refusal message names no unchecked cause.
Nine went to the candidate row "M158 review follow-ups on the glmmTMB boundary path", and 18 were rejected. Two claim audits corrected 5 and 7 claims.
AC1 to AC7 were verified. CI was green on the PR head `f163e72`: three R-CMD-check jobs, test-coverage, lint, pkgdown and the checkers. `devtools::check()` gave Status OK.
Graduated at hygiene: the candidate rows on the false zero ICC and on the degenerate-data test. No lesson was added, because LESSONS.md was at 19,993 of 20,000 bytes.
