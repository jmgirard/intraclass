# M69: Re-verify the ten load-bearing source extractions — done 2026-07-18

**Goal.** Re-read M64's ten load-bearing sources against their shelf PDFs, correct mis-extracted values in place, and upgrade each extraction status from unverified to dated-verified. PR https://github.com/jmgirard/intraclass/pull/73.

**Outcome.** All ten notes (`fleiss1973`, `jorgensen2021`, `koo2016`, `mcgraw1996`, `shrout1979`, `tenhove2020`, `tenhove2022`, `tenhove2024`, `tenhove2025a`, `tenhove2025b`) are dated-verified. 146 PDF pages read, each source to its final page; every claimed page count matched `pdfinfo`. Docs only — no R code, tests, or `ORACLES.md` touched, per Scope.

**Substantive corrections.** `tenhove2025a` Tables 6–7 were read one column off (the `M(SD)` summary column taken for substantial/good-design), which **inverted** the paper's finding that coverage was near-nominal especially in good-design conditions. `tenhove2025b`: MLE-CF *over*estimates ICC(C,1) at 80% missing, not under. `shrout1979` Table 1's Within-target row was missing the Case-2/Case-3 EMS cells the paper prints. `mcgraw1996` Table 4 was missing the Case-2A ICC(A,1) row; Table 7's df swap between limits was unrecorded.

**Both `tenhove2024` open questions resolved as source errata** — Figure 2's crossed-branch terminal is a duplicated box; Table 2's absolute-average-incomplete cell contradicts Eq. 18. `tenhove2025b`'s Table 1 (700 DPI) independently corroborates the Eq. 18 form, so **the package is correct** on two sources rather than one.

**Escalation finding (AC4) → ROADMAP candidate row.** Shrout & Fleiss Table 4 prints **two** decimals, but `ORACLES.md`'s O-OW ("published to 3 dp"), O1 ("Values (3 dp)") and `helper-shrout-fleiss.R:72–73` call the three-decimal values published. All six round to the printed figure — **no oracle value is wrong**; a prose attribution fix.

**Review.** Three findings actioned (92/87/83), including one where M69's own correction was itself wrong (`koo2016`'s "confident interval" page list); one sub-threshold (38) logged — `tenhove2020`'s three citation-hygiene "Escalate" items, outside AC4's "value" wording. The blame-history lens caught a reviewer error made *during* review (a helper's second comment block contradicts its accurate header). One history edit logged honestly: a quoted external date reformatted to ISO to clear `cairn_validate`'s date check, at the maintainer's T4-gate choice.

**Gates.** `cairn_validate` 15/15 PASS · `devtools::test()` FAIL 0 / PASS 1802 · `R CMD check` 0/0/0 · `document()` no diff · `pkgdown` clean · CI 11/11 · 12 files, +568/−147.
