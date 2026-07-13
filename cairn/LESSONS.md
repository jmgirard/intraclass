# Lessons

Durable repo lessons — build quirks, testing tricks, gotchas worth
remembering next time — captured at milestone end and surfaced at plan time.
Not status, not decisions: a lesson is a reusable "how this repo actually
behaves" note. Cross-cutting *choices* still go to `DECISIONS.md`.

Append-only; one line per lesson: `- YYYY-MM-DD (M<NN>): <lesson>`. Capped at
50 lines — when full, prune the stalest lessons rather than letting it grow;
git history keeps the full record.

<!-- lessons appended below by /milestone-review post-merge hygiene -->
- 2026-07-12 (M49): to test the INSTALLED package's full suite, use `R CMD check` / `devtools::check(env_vars=...)` — a bare `test_dir` with the package only attached hides internals (spurious "could not find function summarize_design/validate_type" errors), and `env=asNamespace(pkg)` breaks helper sourcing (sealed namespace).
- 2026-07-12 (M49): `icc()`'s engine roster is not in `formals(icc)$engine` (that's just the default "glmmTMB") — it lives in the `validate_choice(engine, c(...))` call; extract via a regex over `deparse(body(icc))` if a test needs the authoritative list.
- 2026-07-12 (M49): lavaan absolute-agreement ICCs are only *asymptotically* equal to the REML estimate (SEM small-sample term ≈ 3e-3 complete / 8e-3 incomplete at N=40); consistency is exact on balanced data. Cross-engine parity tolerances must split by index class (tight C, looser A).
- 2026-07-12 (M49): trust the roxygen/probe over stale inline comments — the dispatch comment at `R/icc.R:551` wrongly claimed lme4 refuses nested/fixed multilevel; the authoritative `@param engine` roxygen (`R/icc.R:230`) and actual behavior show lme4 covers every design glmmTMB does.
- 2026-07-12 (M49): the milestone-file weight cap is <150 lines — a verbose work-log plus a full Review section overshoots; keep log/review entries terse (git history holds the detail).
- 2026-07-13 (M50): when a consolidation doc cites an ADR as governing behavior "across all shapes", verify that ADR's ACTUAL scope in `legacy/DECISIONS.md` — the origin ADR often covers only the first shape and later ADRs extend it (lme4 `isSingular`: ADR-012 = two-way random only; ADR-023 fixed/multilevel, ADR-024 incomplete "reuse per shape"). The three-lens review catches this even on a no-code "pin existing behavior" milestone.
- 2026-07-13 (M50): boundary guard tests go vacuous silently — `expect_gte(component, 0)` / `is.finite(ci)` are trivially true for any interior fit. Pin that the boundary was actually REACHED (`component ≈ 0`, or fixed-rater θ²_r floored to *exactly* 0), and note the ICC coefficient itself need not be near 0 when a variance component is (subject variance dominates: no-rater-effect fixture → rater var 0 but ICC ~0.8).
