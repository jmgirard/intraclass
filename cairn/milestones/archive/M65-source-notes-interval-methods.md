# M65: Source notes — the interval-methods and robustness cluster (done 2026-07-18)

**Goal & outcome.** Ingest the seven interval-method / distributional-robustness papers the two
open CI candidates would need as primary sources. Seven notes shipped (`xiao2013`, `xiao2009`,
`saha2012`, `saha2005`, `bhandary2006`, `mehta2018`, `bobak2018`), each with the five
validation-doctrine fields, page/table anchors, and a **design-applicability table**.
`BIBLIOGRAPHY.md` 18 → 27 entries (incl. `ukoumunne2003`/`ohyama2025`, which had M62 notes but
no entry); `INDEX.md` +7 lines, shelf inventory 12 → 19. Docs-only under `.Rbuildignore`d
`cairn/`. **No oracle value changed.**

**The finding that matters.** The cluster is **not** the one-way-interval-methods group its name
implied: three are two-way (`xiao2013`, `mehta2018`, `bobak2018`), two **binary** beta-binomial
(`saha2012`, `saha2005`), one a familial multi-sample common ICC (`xiao2009`), one a **hypothesis
test** (`bhandary2006`, M67 territory); four report no interval at all. Only `xiao2013` serves
either CI candidate, and its `κ_m` is calibrated only over ρ ∈ [0.6, 0.9]. **No source simulates
ρ = 0.** Naive PL under-covers only in `xiao2013` (0.796 vs nominal 0.90) but covers 0.931–0.950
in `xiao2009` — PL calibration is design-specific, vindicating the M62 gate split. `mehta2018` +
`bobak2018` converge from opposite directions on ICC tracking subject heterogeneity, not
instrument quality (IP3). **MD-1:** the Goal's premise is false; Goal left unedited (plan-owned).

**Review.** Three lenses + scorer; transcriptions verified against all seven PDFs, **zero numeric
errors**. Six actioned and fixed: F1 (95) a false "Appendices not present / not retrieved" claim
(they were in the PDF); F3 (92) a 9.5 % SE gap called "~1 %"; F7 (92) a stale open question
resolved in the same diff; F4 (90) 734 vs 731; F2 (88) two non-verbatim quotes; F5 (88) a
misattributed citation. F6 (74) logged. PR: https://github.com/jmgirard/intraclass/pull/71
