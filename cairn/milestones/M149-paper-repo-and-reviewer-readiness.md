<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M149: `intraclass` is citable and reviewer-ready, with its companion paper repo open

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan -->
- **Depends on:** —   <!-- owner: plan -->
- **Driving RR:** —   <!-- owner: plan -->
- **Principles touched:** GP2   <!-- owner: plan; the paper is the citation target GP2 protects -->
- **Resolves:** —   <!-- owner: plan -->
- **Surface tier:** user-facing — `CONTRIBUTING.md`, `inst/CITATION`, `README.md` and `DESCRIPTION` are read by users and journal reviewers, and the companion repo is public   <!-- owner: plan -->
- **Branch/PR:** `m149-paper-repo-and-reviewer-readiness`   <!-- owner: implement (branch) / review (PR URL) -->

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

- [ ] AC1: `gh repo view jmgirard/intraclass-paper --json visibility,defaultBranchRef`
      reports a public repository, and `git ls-tree` of its default branch lists
      `README.md`, `LICENSE.md` (CC BY 4.0 for the paper text), and the
      `cairn/` scaffold `/cairn-init` wrote on the `generic` profile; the
      companion `README.md` names the `intraclass` package and JOSS as the venue.
- [ ] AC2: This repo's root `CONTRIBUTING.md` has three headings, one each for
      contributing changes, reporting a problem, and seeking support, each
      section naming a concrete channel (a pull request, the issue-tracker URL,
      an address); `README.md` links to it; `.Rbuildignore` excludes it.
- [ ] AC3: `inst/CITATION` reads the version from `meta$Version` (no literal
      version string); `citation("intraclass")` on a fresh `R CMD INSTALL` of
      the working tree returns one `Manual` entry whose `year` is non-empty
      (the auto-generated default prints `????`) and whose `url` is
      `https://CRAN.R-project.org/package=intraclass`.
- [ ] AC4: `DESCRIPTION`'s `URL:` field lists
      `https://github.com/jmgirard/intraclass-paper` in addition to the two
      URLs already there; `README.Rmd` gains a `## Citation` section whose body
      is a live `citation("intraclass")` chunk and no transcribed text, and its
      "approaching its first release" note is replaced by a sentence stating
      the package is on CRAN; `devtools::build_readme()` run twice leaves
      `README.md` unchanged on the second run.
- [ ] AC5: `NEWS.md`'s development-version section carries one bullet for the
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
- [ ] T5: NEWS bullet; `devtools::check()`; `inst/WORDLIST` only for words
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

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->
