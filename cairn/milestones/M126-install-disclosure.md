<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M126: Disclose what an installation actually retrieves

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP8   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m126-install-disclosure`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Restore, across the three shipped surfaces that discuss dependencies, the
disclosure that `lme4` arrives with any installation while `merDeriv` does not.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**Surface tier: user-facing** — every edited surface ships (`README.md` is in the
tarball and is the pkgdown home page; `NEWS.md` and the vignettes install).

**In:** the Installation section of `README.Rmd` and its regenerated `README.md`;
`NEWS.md`'s "so the base install stays light" clause (:502, inside the unreleased
`# intraclass 0.1.0` section) plus a development-version bullet recording the
README change; the mixed-model passage of `vignettes/engines.Rmd` (:30–58).
Extending `claim_patterns` in `tests/testthat/test-doc-skew-caveat.R` with the
spellings this milestone withdraws — the extension form D-029 requires, not a
second instrument.

**Out:** any NEW doc-claim checker, ledger or audit → barred by D-021, which
D-029 confirms this scope does not otherwise meet; per-class reachability probes
for the pin → the standing `Per-class reachability proof` candidate row, still
barred. `\value`/example nits on `man/*.Rd` → M48. Explicit `design=` and
numeric-`unit` demonstrations → their own candidate row.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: `README.Rmd`'s Installation section discloses that `lme4` arrives with
      an installation regardless of its `Suggests` placement, attributing that to
      `glmmTMB`'s own `Imports:` declaration rather than asserting it as a bare
      fact about the install. Evidence: the section quoted verbatim in the work log.
- [ ] AC2: The same section discloses that `merDeriv` — which the lme4 engine
      requires to form an interval (`R/engine-lme4.R:52`, documented at
      `R/icc.R:310`) — does not arrive, attributed to its `Suggests` placement in
      this package's `DESCRIPTION`. Evidence: the quoted section, plus a
      work-logged measurement recording (a) `tools::package_dependencies()` over
      the non-base entries of the `Imports:` field read from `DESCRIPTION`, with
      `which = c("Depends","Imports","LinkingTo")`, recursive, showing `lme4`
      present and `merDeriv` absent; (b) `pak::pkg_deps("jmgirard/intraclass")` at
      its default, showing the same, since `pak::pak()` is the installer the
      section recommends; (c) `packageDescription("glmmTMB")$Imports` naming
      `lme4`; each stamped with the R version and the date.
- [ ] AC3: None of the four edited files states a count of retrieved packages,
      and the README's declared-set sentence states its members without a
      numeral. Both counts AC2 measures move with CRAN and nothing in this repo
      re-derives either, and the `:2334` rule checks set membership, never a
      numeral (GP8). Evidence: the edited passages quoted whole in the work log;
      reading those quotations settles it.
- [ ] AC4: `README.md` is regenerated from `README.Rmd` in the same commit and
      carries the same disclosure; a second render leaves `git status` clean.
      Evidence: the rendered section quoted beside `README.Rmd`'s, and the
      `git status` output.
- [ ] AC5: `claim_patterns` in `tests/testthat/test-doc-skew-caveat.R` gains the
      spellings this milestone withdraws — `README.Rmd`'s "so intraclass does not
      require them", `NEWS.md:502`'s "so the base install stays light", and
      `vignettes/engines.Rmd:53`'s "it is the one required dependency" — each in a
      backticked and a backtick-free form, and each mutation-verified by
      reintroducing it into a shipped surface and requiring red across the
      doctrine's matrix of 2 markup regimes × 4 wrap forms, the blockquote form
      included (`cairn/doctrine/doc-claim-pins.md`, "Always"). Evidence: the
      committed mutation matrix and its red/green record.
- [ ] AC6: `NEWS.md:502`'s clause no longer characterizes the install's footprint
      from the `Suggests` placement alone, and a development-version bullet
      records the README change — the GitHub README being a surface users read
      today, where the unreleased `0.1.0` section is corrected in place with no
      bullet of its own. Evidence: both passages quoted before and after.
- [ ] AC7: `vignettes/engines.Rmd`'s mixed-model section discloses that `lme4`
      arrives with `glmmTMB` and that `merDeriv` is the dependency an installation
      may lack, and its "it is the one required dependency" clause (`:53`) no
      longer reads as a claim about what an installation retrieves. Evidence: the
      section quoted before and after; the vignette knits.
- [ ] AC8: The milestone's Decisions section records why membership claims
      (`lme4` arrives, `merDeriv` does not) are shippable on a user-facing surface
      where a cardinality claim is not — the gate's answer, which would otherwise
      go unrecorded. Evidence: the entry.
- [ ] AC9: `cairn/PROFILE.md`'s verify slot is clean, and the full suite is green
      against the **installed** package via `testthat::test_dir(load_package =
      "installed")` with **0 skips** across that run (`doc-claim-pins.md`, M116).
      Evidence: both outputs.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T2, T5
- AC2 → T1, T2
- AC3 → T2, T3, T4, T5
- AC4 → T5
- AC5 → T6
- AC6 → T3
- AC7 → T4
- AC8 → T8
- AC9 → T7

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Measure — `tools::package_dependencies()` over the `Imports:` field read
      from `DESCRIPTION`, `pak::pkg_deps("jmgirard/intraclass")`, and
      `packageDescription("glmmTMB")$Imports`. Set `repos` explicitly; a bare
      `Rscript` with no mirror errors. Record `lme4` present / `merDeriv` absent,
      the R version and the date in the work log.
- [x] T2: Rewrite `README.Rmd`'s Installation paragraph (:55–63). Three
      constraints: no count of retrieved packages, and no numeral on the declared
      set; the paragraph MUST retain a sentence naming exactly `cli`, `generics`,
      `glmmTMB`, `lifecycle`, `rlang`, `tibble` and carrying `Imports` or
      `non-base`, because `test-doc-skew-caveat.R:2401`'s anti-vacuity floor
      (`expect_gt(length(hits), 0L)`) has that sentence as its only supplier
      across `NEWS.md`, both READMEs and all nine vignettes; and the draft is
      checked against `claim_patterns` on whitespace-collapsed, blockquote-
      stripped text, never a raw grep (`doc-claim-pins.md`).
- [ ] T3: Rewrite `NEWS.md:501–502`'s clause in place; write the
      development-version bullet.
- [ ] T4: Rewrite the `vignettes/engines.Rmd` mixed-model passage (:30–58),
      including the `:53` clause; leave the `:39` chunk gate correct for
      `merDeriv`.
- [ ] T5: `devtools::build_readme()`; verify a second render is a no-op.
- [ ] T6: Append the three withdrawn spellings to `claim_patterns` (backticked +
      bare per claim) and commit the mutation matrix — each spelling reintroduced
      across 2 markup regimes × 4 wrap forms, red required, then removed.
- [ ] T7: `devtools::spell_check()` (any new word → `inst/WORDLIST`); knit the
      vignettes; profile verify; `test_dir(load_package = "installed")` at 0 skips.
- [ ] T8: Record the membership-vs-cardinality asymmetry in the Decisions section.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-17: created by /milestone-plan; promotes the standing `README no longer discloses that lme4 arrives` candidate row (lineage: M123 review attempt 3 F24 → descope gate 2026-08-17), scope widened at the gate to NEWS.md:502 and vignettes/engines.Rmd.
- 2026-08-17: criteria audit ran in FULL mode (user-facing tier), two passes, fresh-context [O] reader both times. Pass 1 returned 8 findings: AC5 self-scoping ("the legs its own walk reaches" cannot fail; source leg early-returns list() at test-doc-skew-caveat.R:395 under .Rcheck/covr), AC5 evidence not producible (the pin prints no counts on a pass), AC5 inferring a deliverable property from an instrument one, AC1's attribution half having no procedure, AC6 sequenced after the only run citing it, AC6 binding instrument properties (D-118), AC2's pak modeling unverified, and the unnamed :2334 constraint. Pass 2 on the revised draft returned 7 more: AC3 hand-pinning "63 vs 60" in the very criterion banning hand-pinned counts (GP8), AC3's domain three passages against four edited files, AC5 near-vacuous (24 of 28 claim_patterns entries unreachable by any M126 rewrite) and pinning none of the spellings this milestone withdraws, AC5's raw-file grep reproducing the blockquote false negative doc-claim-pins.md exists to defeat, T6's zero-skip scoped to two blocks where M116 doctrine scopes it to the whole installed run, AC7 citing :56 for a clause at :53, and T8 mapping to no criterion. All disposed here: AC5 replaced with the pin-extension + mutation-matrix criterion, AC3 de-numeralized and widened to four files, AC8 added for T8, AC9 widened to the whole installed run, AC7's line corrected, T2 given the :2401 anti-vacuity constraint explicitly.
- 2026-08-17: plan gate chose extending `claim_patterns` in the existing test over authoring a second doc-claim instrument, because D-029 (2026-08-09) settles that a user-facing doc correction plans normally while apparatus still needs D-021's trigger, and names extension as the form M116 used; falsified by a measurement showing the extension cannot pin one of the three withdrawn spellings without a new instrument.
- 2026-08-17: plan gate chose a qualitative footprint clause over naming a figure, because `tools::package_dependencies()` and `pak::pkg_deps()` disagree on this package today (63 vs 60) and nothing in the repo re-derives either; falsified by a procedure landing in the repo that re-derives a closure count on every run.
- 2026-08-17: `cairn_validate` sizing advisory (9 acceptance criteria > 7) accepted, not split. The only natural cut line is AC5 — the `claim_patterns` extension and its mutation matrix — and a milestone whose sole deliverable is a doc-claim pin is apparatus D-021 bars outright, which D-029 confirms by requiring the extension to ride along in the milestone that withdraws the spellings. The remaining criteria are one per shipped surface plus the record and the gate, none of which stands alone. Merging the audited criteria to clear an advisory was refused as shrink-to-fit.
- 2026-08-17: plan gate chose correcting `NEWS.md`'s 0.1.0 clause in place with no bullet of its own, over a correction bullet for it, because 0.1.0 is unreleased (DESCRIPTION 0.0.0.9000, M48 blocked, no tags) so no user ever read it; falsified by 0.1.0 shipping before this milestone lands.
- 2026-08-17: T1 measured on R 4.6.1 against the CRAN cloud mirror — `tools::package_dependencies()` over the six non-base `Imports:` read from `DESCRIPTION` gives a 63-package recursive closure with `lme4` present and `merDeriv` absent; `pak::pkg_deps("jmgirard/intraclass")` at its default gives 60 with the same two verdicts, and `brms`/`lavaan` absent too; `packageDescription("glmmTMB")$Imports` names `lme4 (>= 1.1-18.9000)`. The two procedures disagree on size, agree on membership — the AC3 rationale, measured rather than assumed.
- 2026-08-17: T2 rewrote README.Rmd's Installation paragraph — the declared set now states its members with no numeral, `glmmTMB`'s own `Imports:` carries the lme4 disclosure, and `merDeriv` is named beside the `Suggests:` engines as the piece the lme4 interval needs. Checked against all 28 `claim_patterns` spellings parsed from the test file and matched on squashed, blockquote-stripped text: 0 hits. `test-doc-skew-caveat.R` green under `load_all` (2 vignette-install skips, covered at T7); the `:2334` dependency-list rule and its `:2401` anti-vacuity floor both pass on the new sentence.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
