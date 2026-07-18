# M64: Source notes — the ten load-bearing primary sources (done 2026-07-18)

**Goal.** Give each primary source the suite depends on its own
`cairn/references/<citekey>.md` note, re-read from the PDF with page anchors.
**Outcome.** Ten notes shipped (`shrout1979`, `mcgraw1996`, `fleiss1973`,
`koo2016`, `jorgensen2021`, `tenhove2020`, `tenhove2022`, `tenhove2024`,
`tenhove2025a`, `tenhove2025b`), each with the five validation-doctrine fields
and 37–117 anchors. `BIBLIOGRAPHY.md` trimmed to citation + role + pointer
(18 entries; `fleiss1973` and the 60(3) `tenhove2025a` were **missing entirely**
and were added, not trimmed); `INDEX.md` +10 lines. Docs-only under
`.Rbuildignore`d `cairn/`. Confirmed as printed: Case 3A `θ²_c = Σc²_j/(k−1)`,
O-SEM Eq. 6 (raw, ÷ k−1, no bias correction), O-Bayes half-*t*(4,0,1) on SDs,
`tenhove2022` Eqs. 6–7/12–13. **No oracle value changed.**

**Escalated, not reconciled** (detail in each note's Open questions): ADR-003
describes a boundary-respecting MC scale `tenhove2025b` does not (its own
example prints a negative variance CI limit, p. 1057); no `ICC(Q,·)`/`q` from
`tenhove2024` Fig. 2 is implemented; `ORACLES.md` cites §4.1.1–4.1.3 of
`tenhove2020`, absent from the shelf manuscript; two source-internal errors
(`tenhove2024` Fig. 2's crossed-unbalanced cell; `mcgraw1996` Table 8).

**Review.** Three lenses + scorer. F1 (90) `tenhove2022` self-contradicted on
journal-vs-AOP pagination; F2 (90)/F3 (88) `fleiss1973`/`tenhove2025a` shipped
open questions their own T5 had closed — all fixed. F4 (74) fixed at maintainer
election; F5 (32) logged. PR: https://github.com/jmgirard/intraclass/pull/70
