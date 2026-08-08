# M113: MC-default skew response — frozen-rules disposition from the M111 data

**Status:** done (2026-08-08, PR #121 https://github.com/jmgirard/intraclass/pull/121)

**Goal:** Decide, against pre-frozen rules read over the committed M111 per-rep data, how the one-way MC default should respond to its measured skew under-coverage — replace, warn, document, or no change — assessment only.

**Outcome:** No code. Frozen S1/S2 rules page `cairn/references/mc-skew-response-comparison.md` (committed before any derivation artifact); `data-raw/m113-skew-response-derivation.R` + derived `m113-skew-response-coverage.tsv` (192 rows = 64 cells × 3 legs, wholly re-derived from the M111 fixture, byte-stable on re-run). Verdict D-027: searle no-GO (21/64 cells below the 0.93 floor, worst 0.674), burch no-GO (16/64, worst 0.6655 — M76's "never under-covers" fails on the wider battery), mc **warn** — the 36 failing cells split 10 low-abort skew/kurtosis (all t5/chisq1) + 26 selection-conditioned high-abort (D-026's phenomenon). Warn-trigger design commissioned as a ROADMAP candidate row; degrades to document, with its own D-entry, if no reliable trigger exists.

**Decisions:** D-027 (cross-cutting). Milestone-local: S2 clarified pre-verdict to non-abort coverage; the clarification's commit landed with T2, so commit order corroborates only the bare freeze — recorded dated on the page; verdict invariant under both readings (unconditional 49/64, also warn).

**Review:** devtools::check 0/0/0. Fan-out 14 + 0 + 1 findings; 6 actioned ≥ 80, all fixed on-branch (D1 90 / P1 85 taxonomy partition 5+26≠36 recounted to 10+26; D4 88 freeze-amendment commit-order caveat recorded; D2 82 gaussian-limb framing; D8 82 tail-column conditioning docs; D9 82 empty Decisions section); 9 logged sub-80. Hygiene: LESSONS partition-check extension + freeze-amendment line added; the M63 live-directory/absence lesson pruned — owned by tracking-rules' dated-observation doctrine and the D-009 checker's unmarked-observation FAIL.
