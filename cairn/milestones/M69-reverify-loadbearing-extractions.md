<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M69: Re-verify the ten load-bearing source extractions

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M68   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate; no DESIGN.md IP/GP — governed by PRINCIPLES.md #1 (oracle-first), #4 (no fabricated reference values), #12 (seeded and sourced) -->
- **Branch/PR:** `m69-reverify-loadbearing-extractions`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Re-read M64's ten load-bearing sources against their shelf PDFs, correct any
mis-extracted value in place, and upgrade each note's extraction status from
unverified to a dated verified.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** the ten notes M64 authored — `fleiss1973`, `jorgensen2021`, `koo2016`,
`mcgraw1996`, `shrout1979`, `tenhove2020`, `tenhove2022`, `tenhove2024`,
`tenhove2025a`, `tenhove2025b`. For each: re-read the shelf PDF at
`cairn/references/sources/<citekey>.pdf` **to its final page** (the M65
`mehta2018` lesson — appendices can follow the reference list), confirm or
correct every extracted value against its page/table anchor, correct wrong
values in place with the correction marked, and upgrade `Extraction:` to
`verified YYYY-MM-DD against the source — observed YYYY-MM-DD`. These ten are
first because oracle values trace to them (`ORACLES.md`), so an extraction error
here is a #1/#4 problem, not a documentation one.

**Out:** the other nine notes (M65's seven, M62's `ukoumunne2003` and
`ohyama2025`) → the ROADMAP candidate row; the eleven notes M66/M67 author →
verified at authoring time by those milestones, per M68's amendment. Any change
to package **code, tests, or an `ORACLES.md` entry** that a discovered error
implies → escalated as its own milestone with the finding recorded here; this
milestone corrects notes, never the estimator surface.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: Every extracted value in the ten notes is re-read against its shelf
      PDF and its page/table anchor confirmed, or corrected in place with the
      correction marked (`(M64, corrected M69)`) per the corrections rule.
- [ ] AC2: Each of the ten PDFs is read to its final page, and no note asserts
      an absence that was not actually checked; the work log records the page
      count read per source (the M65 `mehta2018` failure mode).
- [ ] AC3: Each of the ten `Extraction:` statuses is upgraded to a dated
      verified status on one physical line, and `cairn_validate`'s
      `references staleness` advisory no longer names any of the ten.
- [ ] AC4: Any discrepancy touching a value an `ORACLES.md` entry or a test
      depends on is recorded verbatim in the work log as an escalation finding,
      with the affected oracle ID and test named — never silently changed.
- [ ] AC5: `cairn_validate` exits 0, and the profile `verify` slot is clean
      (`NOT_CRAN=true CI=true`, failed + error = 0).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3
- AC3 → T4
- AC4 → T4
- AC5 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Re-verify the classical trio — `shrout1979` (the **O1** worked
      example, Tables 2–4, two-decimal printing), `mcgraw1996` (the Case-3A
      θ²_c formula and the published correction at 1(4):390), `fleiss1973`
      (squared-weight kappa ≡ the k = 2 agreement ICC).
- [x] T2: Re-verify `jorgensen2021` (the **O-SEM** source: Eq. 6's σ²_i, the
      p. 124 SEM-vs-mixed-model gap) and `koo2016` (the interpretation bands and
      the p. 161 judge-against-the-CI guidance, whose band inclusivity the note
      records as ambiguous — confirm that reading).
- [ ] T3: Re-verify the ten Hove quartet — `tenhove2022` (Eqs. 6–7, 12–13,
      Table 3), `tenhove2024` (Figure 2 flowchart, `k̂`/`q`), `tenhove2020`
      (half-*t*(4,0,1) hyperpriors, MAP-over-EAP), `tenhove2025a`/`tenhove2025b`.
      Convert every anchor explicitly against the stated pagination basis —
      three of these are not the version of record (M64 lesson); crop figures at
      300 DPI with `pdftoppm` where a claim sits inside one.
- [ ] T4: Upgrade the ten extraction statuses; record any oracle-affecting
      discrepancy as an escalation finding (AC4); run `cairn_validate` and the
      profile `verify` slot; open the PR and drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan, split from M68 at the plan gate — the maintainer chose to re-verify the load-bearing ten rather than leave every extraction unverified; the remaining nine stay a candidate row.
- 2026-07-18: implement gate — maintainer chose main-session re-reading for all ten (no subagent delegation; a subagent blessing a subagent's extraction recycles M64's failure mode), and chose to record the shrout1979 helper-header attribution finding as an AC4 escalation rather than amend Scope to touch a test file.
- 2026-07-18: T1 done. shrout1979 read 9/9 pages (printed 420–428); 4 corrections — Table 1 Within-target row had Case-2/Case-3 EMS as `—` where the paper prints `σ²_J+σ²_I+σ²_E` and `θ²_J+fσ²_I+σ²_E` (the footnote's "last three entries" only parses with the cell filled), footnote paraphrase, inverted Spearman–Brown star notation, and a `σ²_J = θ²_J` equality the paper does not assert; Table 4 ICC(1,4) cell has an ink blot in the scan, `.44` confirmed arithmetically from Table 3.
- 2026-07-18: T1 — mcgraw1996 read 18/18 pages (printed 30–46 + the 1(4):390 correction); Case-3A θ²_c and the ICC(A,1) estimand confirmed verbatim; 3 corrections — Table 4 was missing the Case-2A ICC(A,1) row, Table 7's numerator/denominator df swap between lower and upper limits was unrecorded, and M64's "possible" Table 8 `MS_W`-vs-`MS_E` typo is now confirmed against Appendix A section A4 (uncorrected in the literature; package implements no Table 8 statistic).
- 2026-07-18: T1 — fleiss1973 read 7/7 pages (printed 613–619); clean, no value correction — Eqs. 1–15, all page anchors and quoted phrases confirmed, "no worked example in the paper" verified through the reference list; dated the previously-undated repo-grep absence claim in "Traces to" per the dated-observations rule (grep re-run, still no hits).
- 2026-07-18: T2 done. jorgensen2021 read 21/21 pages (printed 113–133); the O-SEM load-bearing items all confirmed as printed — Eq. 6's `n_i−1` divisor, no bias correction anywhere in the paper, the full Table 2 normal/observed block (G identical across MS/REML/ML in all three designs, D differing in all three), and the p. 124 discrepancy-function paragraph; 1 anchor corrected (`semTools::monteCarloCI()` is named at p. 128 §5.1, not pp. 114/124).
- 2026-07-18: AC4 escalation finding (recorded, nothing changed) — shrout1979 Table 4 prints coefficients to **two** decimals, but `ORACLES.md` **O1** and `tests/testthat/helper-shrout-fleiss.R` carry three (0.166, 0.290, 0.715, 0.443, 0.620, 0.909) under a header describing them as "the published Shrout & Fleiss numbers to three decimals". The third decimal is not in the paper; it comes from the `psych::ICC()`/`DescTools::ICC()` recomputations recorded in that same header. Values agree at the paper's precision, so **no oracle value is wrong** — the attribution is. Affected: oracle O1, `helper-shrout-fleiss.R` header comment. Out of M69 scope (tests); follow-up is a comment-only fix.
- 2026-07-18: T2 — koo2016 read 9/9 pages (printed 155–163); band inclusivity ambiguity **confirmed** as the note records it (strict `<0.5`/`>0.90`, "between" undefined at 0.5/0.75/0.9, and the 0.9-vs-0.90 asymmetry leaving exactly 0.90 in no band under the strict reading); Table 3's `(k+1)` erratum and the Fig 1 one-way dead-end both re-confirmed at 300 DPI; 2 corrections — the "confident interval" page list was wrong (pp. 155/160/161/162, not 159, which writes it correctly) and the four band statements share cut points but not wording (the Abstract restructures the sentence).
- 2026-07-18: session stop after T2 (5 of 10 notes verified, 64 PDF pages read). T3 (the ten Hove quartet: tenhove2022 17pp, tenhove2024 13pp, tenhove2020 14pp, tenhove2025a 17pp, tenhove2025b 21pp = 82pp) deferred to a fresh session at the maintainer's choice — the gate's main-session-reading decision needs a full context budget to hold. Milestone stays `in-progress`; resume with /milestone-implement M69 at T3. AC5's `cairn_validate` + profile `verify` run belongs to T4 and has not run yet.

- 2026-07-18: T3 — tenhove2022 read 17/17 AOP pages (references end p. 17, no appendix); Tables 4 and 5 confirmed digit-for-digit at 300 DPI and Eqs. 6–7/12–13 + Table 3 confirmed on AOP p. 6 (the pagination open question resolves clean); 9 corrections, none touching an oracle value — the illustrative example's rater design is per-teacher (five raters per teacher, one rating all of *that teacher's* drawings), k=3/k_c=5 are conservative/**liberal** not both conservative, "range preserving" not "parameterization-preserving", the Sim-1 coverage summary was missing two of three departures, plus Table 1's one-way consistency column, the MAP quote, the Fig. 1 page, a Sim-2 quote, and the section page range; 2 additions — Table 2's Note misglosses Design 1 as Design 2 (paper erratum, found at 300 DPI) and ten Hove's p. 14 restatement of the Koo & Li bands disambiguates every cut point (cross-ref for koo2016's ambiguity).
- 2026-07-18: T3 — tenhove2022 open question corrected, not just re-anchored: M64 recorded "the paper reports MCMC only", but the illustrative example also fit lme4 MLE estimates (p. 14), diverted to Online Supplement S4 as "resembl[ing] the MCMC estimates". Qualitative, one dataset, no numbers in the article body, S4 not on the shelf — still not an oracle and the package's REML route is still oracle-established, but the note now says so accurately.

- 2026-07-18: T3 — tenhove2024 read 13/13 AOP pages (references end p. 13, "Accepted May 23, 2022"); Eqs. 16–20, Tables 1–2 and all ten Figure 2 terminal cells re-read at 300–900 DPI; **both M64 open questions about the source's internal consistency are now resolved**, 4 prose corrections, 2 additions.
- 2026-07-18: T3 — tenhove2024 resolution 1: Figure 2's crossed·absolute·average·unbalanced box does print the nested `σ²_r:s/k̂` (M64's reading confirmed by second reader at 900 DPI) and is **glyph-identical to the ICC(k̂) box** in the same row — the nested branch's terminal was duplicated into the crossed branch. Source erratum; no repo doc quotes the box, no oracle affected.
- 2026-07-18: T3 — tenhove2024 resolution 2: Table 2's absolute-average-incomplete cell (`σ²_r + σ²_sr/k̂`, σ²_r undivided) is a **source typo**, not an open question — Eq. 18 (p. 6) and a second prose statement on p. 7 both divide σ²_r by k̂, and only that form satisfies the reduction to Eq. 14 at q=0/k̂=k that the paper itself claims. The package follows Eq. 18 and is correct; M64's "the package follows Eq. 18 / Table 2" was an impossible conjunction for this cell. Separately, the missing-slash rendering artifact is confirmed as an artifact (the relative-average cell in the same table renders `/k̂` normally). **No package change implied.**
- 2026-07-18: T3 — tenhove2024 citation trap recorded: this paper cites the multilevel paper (repo citekey `tenhove2022`) as "Ten Hove et al. (2021)" from its advance-online posting, so "Ten Hove et al. (2021)" on its pp. 10/12 is not a separate work.

- 2026-07-18: T3 — tenhove2020 (the O-Bayes source) read 14/14 manuscript pages (references end p. 14); **no extracted value changed** — the DGP table, half-*t*(4,0,1) spec, 18/72-condition design, MCMC settings (3×1000, 500 burn-in, 1500 draws, R̂<1.10, N_eff>100, 10,000 cap) and every quoted finding confirmed verbatim, and all five figure plot-reads re-checked against Figs. 1–5 and found accurate; M64's `σ²_sr`-subscript-slip reading for `σ²_s` confirmed exactly (the verbatim sentence is now in the note). All six M64 open questions re-confirmed as still standing; 2 prose corrections, 3 additions.
- 2026-07-18: T3 — tenhove2020 nuance recorded (no package change implied): the paper *simulated* half-*t*(4,0,1) on **all** random-effect SDs (p. 7) but *concluded* by recommending it "for the random-rater effect SD" alone (p. 13), matching §3.3's omitted caveat that df=4 "may … be less beneficial for the other random-effect variances" (p. 6). `R/engine-brms.R` sets `set_prior("student_t(4, 0, 1)", class = "sd")` unrestricted = the **simulated** configuration, which is what O-Bayes reproduces — package correct; recorded so a later reader comparing against the closing advice alone doesn't misread a mismatch.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
