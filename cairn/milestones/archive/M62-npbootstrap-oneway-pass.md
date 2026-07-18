# M62: Non-parametric bootstrap CI pass — one-way ICC (GO/NO-GO)

- **Status:** done · **PR:** https://github.com/jmgirard/intraclass/pull/68 · archived 2026-07-18
- **Principles touched:** IP1, GP5, GP6

**Goal.** Decide whether a non-parametric bootstrap CI for the one-way random ICC
is "not worse" than the incumbent Monte-Carlo / parametric-bootstrap intervals —
GO/NO-GO with committed evidence, no exported method.

**Outcome. GO** for the `log F` variance-stabilized **transformed bootstrap-t**
(ukoumunne2003): the only method near-nominal (≥.93) at all four pre-registered
cells (.940/.940/.937/.934), validated against ukoumunne2003 Table I exact values
(6 deltas ≤ .017, tolerance ±.03). **NO-GO** for percentile/BCa (under-cover at
the few-subjects/boundary cells). Ships no code — zero `R/` changes.

**Key finding.** The glmmTMB **MC default under-covers *and* aborts** on 28–39 %
of near-zero-ICC one-way datasets — why the bootstrap wins here, reversing the
ohyama2025 prior (measured against boundary-robust classical F/REML).
**Decisions.** D-006 (GO/NO-GO, framing, implementation conditions); MD-1 (RR01
ingestion). Independent Fable review RB01/RR01 (archived) → **concur-GO**.
**Seeded candidates.** Exported one-way transformed-bootstrap-t `ci_method` (D-006
conditions + 4 deferred review findings); boundary-robust classical default
(SEARLE-F / Burch REML); profile-likelihood sibling pass (MPL, two-way, xiao2013).
**Evidence.** `references/npbootstrap-oneway-comparison.md` (pre-registration →
results → verdict), `ukoumunne2003.md`, `ohyama2025.md`, `data-raw/m62-*`.
