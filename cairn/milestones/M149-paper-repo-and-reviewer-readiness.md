<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M149: `intraclass` is citable and reviewer-ready, with its companion paper repo open

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan -->
- **Depends on:** —   <!-- owner: plan -->
- **Driving RR:** —   <!-- owner: plan -->
- **Principles touched:** GP2   <!-- owner: plan; the paper is the citation target GP2 protects -->
- **Resolves:** —   <!-- owner: plan -->
- **Surface tier:** user-facing — `CONTRIBUTING.md`, `inst/CITATION`, `README.md` and `DESCRIPTION` are read by users and journal reviewers, and the companion repo is public   <!-- owner: plan -->
- **Branch/PR:** `m149-paper-repo-and-reviewer-readiness` · https://github.com/jmgirard/intraclass/pull/167   <!-- owner: implement (branch) / review (PR URL) -->

## Goal
<!-- owner: plan · create -->

Open `jmgirard/intraclass-paper` as the drafting home of the JOSS software paper
(D-045) and bring this repo up to JOSS's reviewer checklist: contribution,
issue and support guidelines, a citation entry, and a link to the paper repo.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** creating the public companion repo and adopting cairn there on the
`generic` profile; in this repo, `CONTRIBUTING.md`, `inst/CITATION`, a README
`## Citation` section, correcting the README's "approaching its first release"
note, the paper-repo URL in `DESCRIPTION`, a NEWS bullet.

**Out:** the paper skeleton, `paper.bib`, the draft-PDF workflow, the text
itself and the submission → the companion repo's own milestones, planned there
with `/milestone-plan` after T1; the submission-time `joss-paper` mirror branch
in this repo and the DOI back-fill on acceptance → the ROADMAP candidate row
"JOSS submission and acceptance follow-through"; a longer methods article → not
planned (D-045 chose JOSS).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [x] AC1: `gh repo view jmgirard/intraclass-paper --json visibility,defaultBranchRef`
      reports a public repository, and `git ls-tree` of its default branch lists
      `README.md`, `LICENSE.md` (CC BY 4.0 for the paper text), and the
      `cairn/` scaffold `/cairn-init` wrote on the `generic` profile; the
      companion `README.md` names the `intraclass` package and JOSS as the venue.
- [x] AC2: This repo's root `CONTRIBUTING.md` has three headings, one each for
      contributing changes, reporting a problem, and seeking support, each
      section naming a concrete channel (a pull request, the issue-tracker URL,
      an address); `README.md` links to it; `.Rbuildignore` excludes it.
- [x] AC3: `inst/CITATION` reads the version from `meta$Version` (no literal
      version string); `citation("intraclass")` on a fresh `R CMD INSTALL` of
      the working tree returns one `Manual` entry whose `year` is non-empty
      (the auto-generated default prints `????`) and whose `url` is
      `https://CRAN.R-project.org/package=intraclass`.
- [x] AC4: `DESCRIPTION`'s `URL:` field lists
      `https://github.com/jmgirard/intraclass-paper` in addition to the two
      URLs already there; `README.Rmd` gains a `## Citation` section whose body
      is a live `citation("intraclass")` chunk and no transcribed text, and its
      "approaching its first release" note is replaced by a sentence stating
      the package is on CRAN; `devtools::build_readme()` run twice leaves
      `README.md` unchanged on the second run.
- [x] AC5: `NEWS.md`'s development-version section carries one bullet for the
      new contributing guidelines and citation entry; `devtools::check()`
      reports 0 errors, 0 warnings, 0 notes, the Status line quoted in the
      Review section (M148 lesson: quote the run, never predict it).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Create `jmgirard/intraclass-paper` (`gh repo create --public`), add
      `README.md` (package, venue, the co-location rule D-045 records) and
      `LICENSE.md` (CC BY 4.0), run `/cairn-init` there on the `generic`
      profile from a session cwd inside that checkout, commit and push. Creating
      the public repo is outward-facing: confirm at the pre-implementation gate.
- [x] T2: Write `CONTRIBUTING.md` (contribute / report / support; DESIGN.md's
      "issues welcome, code contributions not solicited" stance stated
      plainly), add the `.Rbuildignore` entry, link it from `README.Rmd`.
- [x] T3: Write `inst/CITATION` with `bibentry()` reading `meta$Version` and
      the current year; verify with `citation()` after `R CMD INSTALL`.
- [x] T4: Add the paper-repo URL to `DESCRIPTION`, the `## Citation` chunk and
      the CRAN sentence to `README.Rmd`, run `devtools::build_readme()` twice.
- [x] T5: NEWS bullet; `devtools::check()`; `inst/WORDLIST` only for words
      the check flags (never padded, M127 lesson).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-09-10: created by /milestone-plan, promoting the "Companion software/methods paper" candidate row (DESIGN § Commitments; the M42 comparison article is the paper seed).
- 2026-09-10: criteria audit ran in full mode ([O] fresh reader): eight findings — JOSS co-location rule contradicts a standalone paper repo (posed at the gate); JOSS section list hand-pinned and short by two (moved out of this repo's scope); `inst/CITATION` criterion indistinguishable from R's auto-generated default (rewritten to year + CRAN URL, version from `meta`); check criterion pointed at a stale NOTE set (now 0/0/0); README citation text tautological-or-stale (now a live chunk); companion-repo criterion validator-bound (now binds the scaffold); draft-PDF criterion's command could not see the artifact (moved to the companion repo); split tripwire (resolved by moving the paper skeleton to the companion repo's own milestones).
- 2026-09-10: plan gate chose JOSS with drafting in `intraclass-paper` and a never-merged `joss-paper` mirror branch here at submission, over JOSS-in-this-repo (`paper/` dir) and over a full-length methods venue with a standalone repo, because the user wants the paper outside this repo and JOSS's 750–1750-word software-paper shape fits a v0.1.0 package; falsified by JOSS refusing the mirror-branch form at submission, or by the research-impact requirement proving unmeetable for the package at submission time (D-045).
- 2026-09-10: plan gate chose cairn adoption in the companion repo (generic profile) over a plain repo, because the paper's drafting and submission then get their own planned milestones and gates; falsified by the tracking overhead exceeding the paper's own size.
- 2026-09-10: plan gate chose the reviewer-readiness bundle (CONTRIBUTING, CITATION, README citation, stale first-release note) over link-only, because JOSS's checklist asks for each item and none exists today; falsified by JOSS's pre-review rejecting the package on a ground the bundle does not touch.
- 2026-09-10: /milestone-implement started; branch `m149-paper-repo-and-reviewer-readiness` cut from the pushed default branch.
- 2026-09-10: implement gate chose creating the public repo now, scaffolding cairn from this session (greenfield defaults: tagged public release; paper numbers script-produced against a named package version), issues plus the DESCRIPTION email as the support channel, and adding the CRAN install command beside the GitHub one (minor amendment to T4, not to a criterion).
- 2026-09-10: T1 done — `jmgirard/intraclass-paper` created public at `64c1c5c`/`d0e7bee` (README, CC BY 4.0 LICENSE.md, generic-profile cairn scaffold with three candidate rows: skeleton, text, submission); `cairn_validate` there all checks passed.
- 2026-09-10: T2 done — `CONTRIBUTING.md` (contribute / report / support; solo-maintained stance stated; CI formatting claim read against `.github/workflows/format.yaml:27`), `.Rbuildignore` entry, README.Rmd `## Contributing and support` section linking it (README.md re-knits at T4).
- 2026-09-10: T3 done — `inst/CITATION` (`bibentry` Manual; version from `meta$Version`, year from `meta$Date` else the current year); `R CMD INSTALL` of the working tree into a scratch library then `citation('intraclass')`: one Manual entry, year 2026, the CRAN URL, note `R package version 0.1.0.9000`.
- 2026-09-10: T4 done — paper-repo URL third in `DESCRIPTION` `URL:`; README.Rmd: first-release note now opens "intraclass is on CRAN", Installation shows `install.packages()` above the GitHub command (gate amendment), `## Citation` is a live `citation("intraclass")` chunk; `devtools::build_readme()` twice, the second run left README.md and both figure PNGs unchanged.
- 2026-09-10: T5 done — NEWS development-version bullet; `devtools::document()` regenerated `man/intraclass-package.Rd` (the new URL); `devtools::check()`: `0 errors ✔ | 0 warnings ✔ | 0 notes ✔` (14m 34.8s); a first check run was stopped after README edits landed mid-run and re-run on the final tree; the two claim-audit prose corrections below landed after that tarball was built (CONTRIBUTING.md is build-ignored; README.md re-passed `spelling::spell_check_package()` with no errors). No `inst/WORDLIST` change: the one flagged word (`jmgirard` as README link text) was reworded instead.
- 2026-09-10: claim audit: 30 claims read, 2 corrected — CONTRIBUTING.md (the oracle-bar sentence now states cited-source-or-seeded-script and two independent oracle types, per PRINCIPLES #1/#4), README.Rmd/README.md (the paper "will be" drafted; the companion repo holds no paper text yet). Re-read of the two corrections ran in a second fresh [O] reader, both CORRECT — deviation: the same-reader re-read was impossible because SendMessage is disabled in this session.
- 2026-09-10: all tasks checked; status → review.
- 2026-09-10: /milestone-review started; default branch unmoved since the cut; PR #167 opened as draft; AC1–AC4 verified and ticked (Review section).
- 2026-09-10: CI red at PR open on two failures already red on `main` since `d40cdcd` (record-claims ledger row not rotated; devtools undeclared for checkpoint-guard) — both fixed on this branch, diagnosis in the Review section.
- 2026-09-10: review fan-out: [S] history 0 findings, [S] prior-review 0, [O] 12 — five fixed now (README link, NEWS wording, CITATION footer and year, CONTRIBUTING oracle-bar wording; README re-knitted), one procedural (AC5 re-check on the final head), three posed at the gate, one rejected; every disposition in the Review section.
- 2026-09-10: gate questions answered: CRAN badge added, CITATION gains ORCID and key, README-version finding rejected; README re-knitted; AC5 check re-run on this head.
- 2026-09-10: check on `2cbc8bd` failed on one spelling flag (`md`, the README link text `CONTRIBUTING.md` on its own line); link text reworded to "the contributing guide", README re-knitted, `spell_check_package()` clean, no WORDLIST change; check re-run on this head.
- 2026-09-10: check on `bd24a98` clean (0/0/0); AC5 ticked; PR-conversation read empty; pre-gate checkpoint.
- 2026-09-10: step-7 approval: PR #167 approved for merge.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->

### Evidence (2026-09-10, branch head `d436c2c`, PR #167)

- AC1 — `gh repo view jmgirard/intraclass-paper --json visibility,defaultBranchRef`: `PUBLIC`, default branch `main`. Tree of `main` via `gh api .../git/trees/HEAD`: `.gitignore`, `CLAUDE.md`, `LICENSE.md`, `README.md`, `cairn/`; `cairn/` holds `DECISIONS.md`, `DESIGN.md`, `LESSONS.md`, `PROFILE.md`, `ROADMAP.md`, `milestones/`, `references/`, `reviews/`, and `PROFILE.md` opens `# Toolchain profile: generic`. `LICENSE.md` opens with the CC BY 4.0 statement for the paper text. The companion README names the `intraclass` package (lines 1, 4, 30) and JOSS as the venue (lines 13–14). PASS.
- AC2 — `CONTRIBUTING.md` headings: `## Contributing changes` (l.7), `## Reporting a problem` (l.24), `## Seeking support` (l.39); channels named per section: a pull request against `main` after an issue (l.17–18), the issue-tracker URL (l.27), the issue tracker plus the maintainer's email address (l.43, l.47). `README.Rmd:165` and `README.md:252` link `CONTRIBUTING.md`; `.Rbuildignore:21` carries `^CONTRIBUTING\.md$`. PASS.
- AC3 — `inst/CITATION` reads `meta$Version` and contains no literal version string (grep for `\d.\d.\d`: none). `R CMD INSTALL` of the working tree into a scratch library, then `citation("intraclass")`: one entry, bibtype `Manual`, year `2026`, url `https://CRAN.R-project.org/package=intraclass`, note `R package version 0.1.0.9000`. PASS.
- AC4 — `DESCRIPTION` `URL:` lists the GitHub repo, the pkgdown site, and `https://github.com/jmgirard/intraclass-paper` (l.51–53). `README.Rmd` `## Citation` (l.152) is a single `citation("intraclass")` chunk with no transcribed citation text; the first-release note now opens "intraclass is on CRAN" (l.37) and no "approaching" wording remains. `devtools::build_readme()` run twice in a scratch copy of the tree: README.md md5 `83fdacd8…` after both runs (unchanged on the second), and identical to the committed README.md and figures. PASS.

### CI at PR open (2026-09-10)

`check-references` and `checkpoint-guard` (both `lint.yaml`) were red on the draft PR. Both were already red on `main`: every `lint.yaml` run since `d40cdcd` (2026-09-10T15:12Z, four runs) failed on the same two jobs, and the last green run was `ac7252e` (2026-09-04). Neither is introduced by this diff. (a) `data-raw/record-claims.tsv` row `roadmap-terminal-rows` still expected five terminal rows after `d40cdcd` pruned the table to the retention-3 cap without rotating the row; rotated on this branch to `M148, M147, M146`, and `check-record-claims.py` plus its `--self-test` pass locally. (b) `data-raw/m111-fallback-sweep.R:35` calls `devtools::load_all()` from the checkpoint-guard demo, and devtools is declared nowhere for that job — the 2026-09-04 run had it only from a library restored under an older cache key; `any::devtools` is now in the job's `extra-packages`. Both fixes are on this branch so they reach `main` through this gate.

### Independent review (2026-09-10, three fresh-context lenses on `origin/main...HEAD`)

- [S] blame-history: no findings. Examined every modified hunk against its introducing commit (the removed first-release note is `9a7c5c9`), all D-entry headings with D-045 in full, the M148 archive, and LESSONS.
- [S] prior-review record: no findings. Archives M126–M148 read for README/NEWS/DESCRIPTION/WORDLIST/CITATION findings; the GitHub probe `pulls/comments?per_page=1` returned `[]`, so the per-PR walk was skipped.
- [O] diff-bug: 12 findings, ranked by the reviewer; dispositions:
  1. `README.md:252` links `CONTRIBUTING.md` relatively, but that file is build-ignored while README.md ships and renders on the CRAN page — fixed now: absolute GitHub URL, README re-knitted.
  2. `NEWS.md:3` said the package "now ships" a `CONTRIBUTING.md` that the build ignores — fixed now: the citation entry ships, the source repository gains the guide.
  3. The T5 check predated two README edits that are in the tarball — fixed now, procedurally: AC5 is ticked only against a check run on the final branch head.
  4. `inst/CITATION` footer said a paper "is in preparation" where the README (after the claim audit) says "will be drafted" — fixed now to match.
  5. `CONTRIBUTING.md:10-11` said "two independent oracles" where PRINCIPLES #1 requires two independent oracle *types* — fixed now: "two independent kinds of oracle".
  6. The knitted README citation shows the development version beside the CRAN install command — posed at the gate; recommended reject: the live chunk was chosen at the plan gate over transcribed text, the README is knitted from the source tree by design, and the release walk re-knits before the CRAN build so the shipped copy shows the released version.
  7. No CRAN-version badge; the lifecycle badge still reads "experimental" — posed at the gate.
  8. `inst/CITATION` author omits the ORCID that `DESCRIPTION` carries, and the BibTeX entry has no key — posed at the gate.
  9. Year read via `meta$Date`, which only partial-matches CRAN's `Date/Publication`; a GitHub install gets the install year — fixed now: explicit `Date/Publication`, then `Date`, then the current year; both branches evaluated with `readCitationFile()`.
  10. NEWS "links to both" imprecise — fixed now, folded into 2.
  11. `CONTRIBUTING.md:13-20` reads as self-contradicting — rejected: the stance is stated in the opening paragraph and again before the exceptions, which open "If you want to change something anyway".
  12. `inst/CITATION` line over 80 columns — fixed now with 9 (year block and footer wrapped).
- Gate answers (2026-09-10): finding 7 → CRAN-version badge added beside the existing badges, lifecycle badge unchanged; finding 8 → author carries the ORCID from `DESCRIPTION` and the entry has `key = "intraclass"` (BibTeX renders `@Manual{intraclass,`); finding 6 → rejected for the reason recorded above. README re-knitted after both edits.

### Evidence after fix-now work (2026-09-10, branch head `bd24a98`)

- AC3 re-verified on the final `inst/CITATION` (ORCID, key, explicit year lookup): `R CMD INSTALL` of the working tree into a scratch library, `citation("intraclass")`: one entry, bibtype `Manual`, year `2026`, url `https://CRAN.R-project.org/package=intraclass`, key `intraclass`. PASS.
- AC4 re-verified: README re-knitted after each README.Rmd edit; the committed README.md is the knit of the committed README.Rmd (the two-run md5 evidence above; the final knit passed `spell_check_package()` with no flags). PASS.
- AC5 — `NEWS.md` development-version section carries one bullet for the citation entry and contributing guide (no milestone numbers). `devtools::check()` on `bd24a98`: `0 errors ✔ | 0 warnings ✔ | 0 notes ✔` (Duration: 14m 26.1s). Two earlier runs on this branch were stopped or superseded by fix-now edits; one run on `2cbc8bd` failed on the `md` spelling flag recorded in the work log. PASS.
- Consistency gate: `cairn_validate.py` all checks passed; `devtools::document()` no diff (scratch-copy comparison of `man/` and `NAMESPACE`); README knit in sync; `pkgdown::check_pkgdown()` no problems; NEWS entry present; `.Rbuildignore` covers `CONTRIBUTING.md`; no DESIGN.md principle changed (impact report skipped).
- PR-conversation read (PR #167): no reviews, no conversation comments, no unresolved review threads.
