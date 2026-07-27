# M93: Boundary-abort hint for the deterministic boundary-robust `ci_method` families

**Status:** done (2026-07-27, PR #100 https://github.com/jmgirard/intraclass/pull/100)

**Goal:** When the Monte-Carlo default aborts near the σ²→0 boundary, name an opt-in
`ci_method` only after RUNNING it on the data in hand — never from a design predicate.

**Outcome:** `R/boundary-hint.R` splices `i =` bullets into the two reachable MC aborts.
ADMISSIBILITY mirrors `icc()`'s fences (balanced one-way → `searle`/`burch`; balanced
two-way random agreement → `mpl`; else nothing); USABILITY runs the shipped reducer via
`boundary_method_usable()`, keeping a method only when every endpoint is finite, ordered
and in D-010 support (`< 1`, and `> -1/(n0-1)` for ICC(1), both open). Keyed by method
string, so M97 adds `npbootstrap` as a row. Lazily forced, never raises, additive — a
no-hint abort is byte-identical. Five design predicates deleted as subsumed.

**Decisions:** D-018 (promoted) — computing a candidate interval to decide whether to
NAME its method, then discarding it, is not the fallback-on-abort default D-012 fenced out.

**Review:** Ten passes, three re-cuts. 1-5: the hint named a method that then failed, a new
mechanism each time → verify-instead-of-predict. 6-9: AC5 evidence, a leak guard blind to
part of its surface; T11 made it an invariant over the producer's own bullets, and §8
certification found seven description defects across three rounds. 10: three lenses 0
findings, ~4,400 adversarial aborts, 0 violations. To M97: detector blind to non-finite
endpoints. Graduated: the M90/M91/M92 guard-craft lesson → `guard-doctrine.md` (D-055).
