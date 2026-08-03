# M102: A registered claims ledger, and the CI checker that re-derives it

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP7
- **Branch/PR:** `m102-record-claims-ledger` · https://github.com/jmgirard/intraclass/pull/109

## Goal

Commit a registered ledger of (claim, command, expected output) rows over tracking
prose and a CI checker that re-derives every row, so a transcribed figure that
drifts from its artifact reds a check instead of surviving review passes.

## Scope

**In:** `data-raw/record-claims.tsv`, `data-raw/check-record-claims.py` and its
`--self-test`, the `check-references` CI wiring, and a `cairn/DECISIONS.md` entry
recording the convention. Registration only: a claim is checked because a row
registers it, never because prose was scanned for it (RR04 §3, rec 9).

**Out:** wiring `enumerate-ci-method-remedies.py` into CI (RR04 BC6's first half) →
M100's resumed pass, that script existing only on M100's branch. Registering M100's
own figures (RR04 BC2's list) → M100's resumed pass, its artifacts likewise being
branch-only. Retrofitting row citations into existing records → the milestone that
owns each record. A ledger over abort-remedy message text → the standing ROADMAP
candidate row, whose subject is M101's messages.

## Acceptance criteria

- [x] AC1 A committed stdlib-only `data-raw/check-record-claims.py` reads
      `data-raw/record-claims.tsv`. The row grammar — named columns, at minimum
      `id`, `record`, `kind` (`presence`|`absence`), `claim`, `command`,
      `expected_rc`, `expected_match`, `falsifier_command`, `disposition`,
      `reason` — is stated in the module docstring, and a row violating it exits
      non-zero. Each row's command runs from the repo root under a bounded
      per-row timeout; a differing exit status, an output not matching
      `expected_match`, or a timeout exits non-zero. Every command shape the
      checker supports is listed in the docstring and runs with `python3`, POSIX
      shell and working-tree `git` alone — the `check-references` job has no R and
      no network; `--self-test` PARSES that list and asserts SET equality with the
      shape ids the code dispatches on, so a docstring shape with no code and a
      code shape with no docstring line each exit non-zero.
- [ ] AC2 Refusal is decided by one test — `argv[0] == "git"` — so every `git`
      command is refused whatever its flags spell (D-020 Amendment 1 rule 1), the
      enumerated history-dependent forms (a `log`/`blame`/`rev-list`/`show`
      subcommand, a `<rev>..<rev>` range, a ref other than `HEAD`) only naming the
      reason and `git-command` covering the rest; that checkout is depth-1 with no
      `main` ref. The set is stated in the docstring, each form carrying a
      `--self-test` probe constructing it and showing the refusal. The docstring
      and D-020 Amendment 2 state what this does NOT claim: a syntactic rule over
      the ledger cell, not a sandbox — an accepted shape's own program can still
      reach a shell or `.git/`, and no criterion here promises otherwise.
- [x] AC3 The committed ledger carries a passing row for each of these four
      figures, every one settled from an artifact committed on the default branch:
      the `data-raw` checker inventory by name; the count of `data-raw` checker
      invocations in `.github/workflows/lint.yaml`; the three κ_m worst-downward-step
      figures (−0.046, −0.068, −0.162) the ROADMAP's MPL-envelope candidate row
      states; and the ROADMAP's terminal-row retention count. Plus at least one
      passing row per docstring-listed command shape. Tolerance: exact figures.
- [x] AC4 Registration is symmetric over a file set the `cairn/DECISIONS.md`
      convention entry names: `--self-test` PARSES that scope list out of the entry
      and asserts set equality with the checker's own list, so the artifact under
      test cannot choose its own scope. Within that scope every `[claim:<id>]`
      citation resolves to a ledger row, and every row id is cited at least once
      there or carries `disposition = uncited` with a reason; either direction
      failing exits non-zero. The checker's only inputs are ledger rows and
      `[claim:<id>]` citations — it never scans prose for unregistered figures —
      and the docstring states that limit with its ground.
- [x] AC5 A row's `kind` is author-declared, never inferred. Every `kind = absence`
      row carries a `falsifier_command` — the row's command against a committed
      constructed input under which it must produce a non-passing result — which
      `--self-test` runs and requires to fail the row's expectation; an `absence`
      row with no falsifier exits non-zero. A row whose `expected_rc`/`expected_match`
      is absence-shaped (zero count, empty result, non-match) while `kind = presence`
      exits non-zero as a mis-registration. Ground: a certifying pattern that cannot
      match the violation it certifies passes vacuously (M100 review pass 5, F1).
- [x] AC6 `--self-test` drives every route the checker has to a non-zero exit on
      constructed input against a passing control. Each route carries an id;
      `--self-test` PARSES the docstring's route ids and asserts SET equality with
      the probe registry's ids, so a stated route with no probe and a probe with no
      stated route each exit non-zero (labels as a set, not counts). Each probe is
      shown load-bearing by excising its route's sentinel-delimited block from a
      temp copy of the script and confirming exactly its own probe reds. The route
      set includes at minimum: grammar violation, wrong `expected_rc`, wrong
      `expected_match`, timeout, refused history-dependent form, unresolved
      `[claim:<id>]`, uncited-and-undispositioned row, `absence` row with no
      falsifier, and mis-registered `kind`.
- [x] AC7 `cairn/DECISIONS.md` carries an entry recording the convention as an
      explicitly numbered rule list, each line ending `probe: <route-id>` or
      `probe: none — <ground>`; `--self-test` parses that list and asserts each
      named route id exists in the probe registry. The list states at minimum: the
      row grammar; that a record states a load-bearing figure by citing a row id;
      the registration-not-detection limit; the absence-falsifier rule; the AC4
      scope list; and the relation to D-009's inline settling directives for
      `cairn/references/` pages.
- [x] AC8 `.github/workflows/lint.yaml`'s `check-references` job runs
      `python3 data-raw/check-record-claims.py` then the same with `--self-test`,
      in that order, preceded by a comment naming this milestone and the ledger
      path; the job is green on a CI run of this milestone's PR with both steps in
      that run's log.
- [x] AC9 Gate clean: suite at `NOT_CRAN=true CI=true`;
      `devtools::check(env_vars = c(NOT_CRAN = "false"))`; `lintr::lint_package()`;
      `air format --check .`; `devtools::document()` no diff; and every `data-raw`
      checker — enumerated by `ls data-raw/check-*.py data-raw/enumerate-*.py` —
      run locally, all clean.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T6
- AC7 → T7
- AC8 → T8
- AC9 → T9

## Tasks

- [x] T1 Checker skeleton: row-grammar reader and validation, bash runner
      (`cwd` = repo root, bounded timeout), `expected_rc`/`expected_match`
      comparison, the docstring shape list and its parsed set-equality assertion.
      Every input injectable as a parameter so each branch can be probed
      (`check-mpl-doc-claims.py` idiom).
- [x] T2 The refused-form set: enumerate the history-dependent forms, refuse with
      the reason, and construct each in `--self-test`.
- [x] T3 Seed the ledger with the four named figures plus one row per shape; run
      every row. The κ_m row reads `data-raw/m88-kappa-table.rds` via M94's stdlib
      RDS reader (`sys.path.insert(0, 'data-raw')`) — no R in that job. Fault the
      record, not the run, if a figure disagrees.
- [x] T4 Citation gate: parse the scope list from the D-entry, extract
      `[claim:<id>]` over that scope, symmetric missing/orphan diff, `uncited`
      disposition.
- [x] T5 `kind` column, `falsifier_command` execution, and the mis-registration
      trap; author a falsifier for every `absence` seed row.
- [x] T6 `--self-test`: one probe per route against a passing control; the route-id
      set-equality assertion; excise each sentinel-delimited route block from a temp
      copy and confirm exactly its own probe reds.
- [x] T7 Append the D-entry: numbered rule list, each line naming its probe id or
      `none — <ground>`; state the D-009 relation and the scope list.
- [x] T8 Wire both steps into `check-references` with the milestone comment; push
      and confirm the job green on the PR.
- [x] T9 Gate per AC9. Run `check-reference-observations.py` specifically — a new
      `data-raw` file naming a citekey trips that source note's `git grep`
      directives (M80/M86); add a `':(exclude)…'` pathspec if the ledger quotes one.

## Work log

- 2026-08-02: start — branch `m102-record-claims-ledger` cut from `main` at 53dde1c, status -> in-progress.
- 2026-08-02: created by /milestone-plan; promotes the ROADMAP candidate row "Claims ledger + checker for tracking prose" (lineage M100 passes 1–4 → RB04/RR04 → M100 ingest audit → M100 pass-5 disposition).
- 2026-08-02: plan gate chose seeding the ledger with four main-resident figures over registering RR04 BC2's figure set, because `abort-remedy-sweep.tsv` and the enumerator exist only on M100's branch and a branch cut from main cannot settle a row against them; falsified by M100's evidence artifacts reaching the default branch before this milestone is implemented.
- 2026-08-02: plan gate chose requiring a committed falsifier for absence-shaped rows only over requiring one for every row and over requiring none, because M100's pass-5 F1 was a certifying grep whose pattern could not match its own violation while a positive-figure row's falsifier is near-trivial; falsified by a presence-shaped row that passes while proving nothing.
- 2026-08-02: plan gate chose refusing history-dependent commands from an enumerated form set over deepening the CI checkout to `fetch-depth: 0`, because a pull-request checkout is a synthetic merge commit so those commands would behave differently in CI than locally; falsified by a load-bearing claim class that only a branch-diff command can settle.
- 2026-08-02: plan gate chose leaving the abort-remedy-truthfulness ledger candidate row separate and cross-referenced over absorbing it, because its subject is M101's message text and it needs those messages to exist; falsified by the two ledgers converging on one schema in practice.
- 2026-08-02: plan gate chose registration over detection for a row's absence-shape (`kind` is author-declared, the classifier is only a mis-registration trap), because an output-shape classifier misses `^0 problems$` and `test !` forms and would rebuild F1's failure mode inside the new tool; falsified by authors mis-declaring `kind` more often than the classifier misclassifies.
- 2026-08-02: the criteria-count split tripwire fires at 9 and the plan-owned body lands at 144/149. Kept whole deliberately: the only natural cut separates the citation gate and the convention entry from the checker they gate, which would ship a checker with no convention behind it and a successor amending a just-shipped script. Revisit if implement finds the tasks shippable independently.
- 2026-08-02: criteria audit ([O], fresh context, authored none of the draft) returned eleven single-answer findings and five either-way calls; all eleven fixed before the gate — docstring↔code shape parity, the enumerated refused-form set replacing an undecidable "depends on git history", a stated row grammar behind "malformed", an `expected_rc` column (without which `grep -c 'D-020' … ` = 0 exiting 1 makes every absence row unrepresentable), route parity by label-set rather than count (M100 pass-5 F13), the route list covering timeout and absence-falsifier, author-declared `kind`, a named `falsifier_command` mechanism, the AC2×AC6 joint unsatisfiability broken by D-009 rule 3's `probe: none — <ground>` idiom, the self-declared scope closed by parsing it out of the D-entry, and concrete gate checks plus the command enumerating them. The audit's headline finding — "the whole set is satisfiable by a green ledger that registers nothing load-bearing" — became AC3's four named figures and the gate's first question. Either-way calls: route excision over a `--disable-route` flag (decided here, AC6), and the seed set (to the gate).

- 2026-08-02: T1/T2 — `data-raw/check-record-claims.py` lands whole (both tasks are the same file, committed together): stdlib-only, no shell (commands are `shlex.split` + `subprocess.run` argv, so a pipeline/redirection/chained command is inexpressible), 11-column grammar parsed OUT of the docstring so columns cannot drift from their statement, five dispatched shapes, three refused history-dependent forms each with a constructing sample, and 16 sentinel-delimited failure routes with a probe apiece. Measured at this commit: `--probes` reports all 16 DETECTED, and excising each route's block from a temp copy silences exactly that route (0 problems over 16 excisions).
- 2026-08-02: implement question gate — citation scope set to the four correctable records (`cairn/ROADMAP.md`, `cairn/LESSONS.md`, `cairn/DESIGN.md`, `data-raw/README.md`) over adding the live milestone file or ROADMAP alone, because history files cannot take a citation later nor have a drifted figure corrected (IP4); command shapes set to the five the AC3 figures need (`ls`, `grep`, `awk`, `python3`, `git-grep`) over dropping `git-grep`, which would leave the refused-history-form rule guarding a shape no row can use; and the checker-inventory + CI-invocation-count figures homed in a new `data-raw/README.md` section over a lessons line or the decision entry, the last rejected because a decision entry can never be edited when a sixth checker lands.

- 2026-08-02: T3 — `data-raw/record-claims.tsv` seeded with five rows, one per shape and covering all four named figures; all five pass at this commit (`python3 data-raw/check-record-claims.py` → `OK: 5 registered claim(s) re-derived, 0 failure(s)`). Two plan refinements, both minor: the κ_m row reads BOTH `m88-kappa-table.rds` (the shipped 0.95 table) and `m90-kappa-tables.rds` (0.90 and 0.99) via the new helper `data-raw/record-claims-kappa-steps.py`, T3's naming of the M88 fixture alone having missed that the three figures span three levels, only one of which M88 calibrated; and T8's `lint.yaml` wiring landed here rather than after, so the invocation-count figure was true at the moment it was written rather than written false and fixed later. T8 remains open for its green-CI evidence.
- 2026-08-02: T4/T5/T6 — citation gate, falsifier mechanism and self-test verified together on the seeded ledger. Citations: the two ROADMAP figures cite their rows inline, `data-raw/README.md` gains a Record-claim checkers section carrying the other three, and both directions red on constructed input. Falsifier: the one absence row certifies that `cairn/DECISIONS.md` carries no claim citation, and its falsifier points the same `git grep` at the committed `data-raw/record-claims-fixtures/citation-present.md`, which does carry one — measured to fail the row's expectation (rc 0 against an expected 1). Self-test: `--self-test` green, 16/16 probes drive their own route, and 16/16 route excisions silence exactly their own probe.
- 2026-08-02: T7 — `cairn/DECISIONS.md` gains D-020: 17 numbered rules, each naming the route that probes it except rule 5 (registration-not-detection), which records `none` with its ground, a limit on what the checker reads rather than a condition any input can drive. Two parser corrections found by running the entry through the checker rather than by reading it: a rule's probe token is read immediately after `probe:` and not at end of line (a `none` rule ends with its ground), and the scope list is read only up to the rule's em dash (the sentence arguing for the scope names the EXCLUDED paths in backticks too, and the first draft parsed `milestones/archive/` into the scope).

- 2026-08-02: T8 — both steps run in `check-references` on PR #109, in the stated order and behind a comment naming this milestone and the ledger path. Job green in 24s with both steps `success` in that run's own log; recompute: `gh api repos/jmgirard/intraclass/actions/jobs/91544700240 --jq '.steps[] | "\(.number) \(.conclusion) \(.name)"'` — step 9 "Re-derive the registered record claims (M102)", step 10 "Self-test the record-claims checker (route excision)". The self-test, route excision included, therefore passes on the depth-1 CI checkout and not only locally.
- 2026-08-02: T9 gate clean — suite `NOT_CRAN=true CI=true` FAIL 0 / ERROR 0 / SKIP 23 / PASS 5435 (identical to `main`'s baseline; this branch changes no R code and adds no R test); `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors / 0 warnings / 0 notes in 2m54s; `lintr::lint_package()` 0 lints; `air format --check .` clean; `devtools::document()` no diff; all five `data-raw` checkers pass locally in both their check and self-test modes (ten invocations, enumerated by `ls data-raw/check-*.py data-raw/enumerate-*.py`); `cairn_validate` all checks passed, WARNs only `sizing (split tripwires)` (1 — nine criteria, kept whole at the plan gate) and `dangling id tokens` (321, pre-existing). CI green on PR #109: all nine checks pass. `check-reference-observations.py` specifically re-run per T9's note — no new `data-raw` file names a citekey, so no `':(exclude)...'` pathspec was needed. Status -> review.

- 2026-08-02: review pass 1 FAILED the gate — FIRST return. [O] diff-bug 24 findings, [S] blame-history 2, [S] prior-PR-comments 0 (GitHub inline-comment probe returned `[]`; no archived `## Review` finding is regressed); an [S] scorer scored all 26, two at >= 80. AC2 fails as written: `refused_hits()` implements "a ref other than `HEAD`" as a four-item blacklist, so `HEAD~1`, `HEAD^`, a raw SHA, a tag, `upstream/main` and a bare branch name are each accepted (re-measured independently at this commit) and would break only on the depth-1 CI checkout. Also actioned: `check_falsifiers()` runs ungated on grammar-failed rows and raises instead of reporting (82). AC2's tick withdrawn. 24 sub-80 findings logged in the Review section; O13/O11/O12 sit closest to the bar and bear on this milestone's own subject. Status -> in-progress.

- 2026-08-02: pass 2 — the two actioned findings fixed, with the three sub-80 findings nearest the bar taken alongside at the maintainer's direction. O1 (AC2): "a ref other than `HEAD`" is now stated POSITIVELY over the revision slot instead of as a blacklist of ref spellings — a `git grep` must name its pattern with `-e` and delimit its pathspec with `--`, and every operand left between them must be `HEAD`. Re-measured at this commit: `HEAD~1`, `HEAD^`, a raw SHA `53dde1c`, the tag `v0.1.0`, `upstream/main` and a bare `some-branch` are each refused `non-head-ref`, `main..HEAD` is refused `rev-range`, plain `HEAD` is allowed, and a `git grep` lacking either delimiter is refused by a fourth stated form, `ambiguous-operands`, with its own sample. `git grep -c -e main -- f` is no longer refused, so the flag-argument false positive (O20) went with it. O2: `check_falsifiers()` now runs over validated rows only — `execute_row` trusts the grammar, so a malformed row reached it and raised instead of reporting; the grammar failure is now printed. O13: `read_ledger` carries each row's TRUE file line, measured 3 and 4 for the first two rows against a previously reported 2 and 3. O11: the absence row now searches `cairn/milestones/archive/` as well as `cairn/DECISIONS.md`, and the `data-raw/README.md` sentence states exactly that pair rather than "History ... at all". O12: the terminal-row row now settles the five milestone IDs in order (`M99 M98 M97 M96 M95`), not just the count, so rotating a row without renaming it reds. Gate: all five `data-raw` checkers pass in both modes, route/probe parity 16/16 and refused-form parity 4/4, `air format --check .` clean, `lintr::lint_package()` 0 lints, `cairn_validate` all checks passed.

- 2026-08-02: pass 2 CI green on `8ee0131` — all nine checks pass, `check-references` in 25s with both M102 steps `success` in that run's log. The R suite and `R CMD check` results recorded at the T9 gate stand unchanged: `git diff main..HEAD --name-only` lists nine paths and not one is under `R/`, `tests/`, `man/`, `NAMESPACE` or `DESCRIPTION`, so no R-visible content changed in this pass. Status -> review.

- 2026-08-02: review pass 2 FAILED the gate — SECOND return, and thrash trigger (b) fires. [O] diff-bug 30 findings, [S] blame-history 1 substantive, [S] prior-review 4 (GitHub inline-comment probe `[]` again); an [S] scorer scored 31 and exactly one reached 80. AC2 fails a second time by a NEW mechanism of the same shape: in `rev_operands()` the `--` test precedes the flag-value test, so `git grep -c -e -- main -- data-raw/README.md` is accepted and really does resolve the ref (`main:data-raw/README.md:2`, rc 0) — reproduced independently at this commit. Four further parsing defects share the cause (`-m 5` read as a ref, bundled `-ce` refused as lacking `-e`, `-e` after `--` accepted, `git --no-pager log` misclassified). Pass-1's other four fixes (O2, O11, O12, O13) verified holding by all three lenses. 30 sub-80 findings logged; the heaviest is D-020 rule 10's prose falling out of sync with the fourth refused form the fix pass added, repairable only by a superseding entry since IP4 forbids editing the entry. AC2's tick withdrawn. Status -> in-progress.

- 2026-08-02: pass 3 — at the maintainer's direction the refusal rule stops parsing git's command line. It is now decided by one test, `argv[0] == "git"`, and by nothing after it: EVERY git command is refused, the `git-grep` shape is removed so no shape maps to git, and the one row that used it writes `grep -r`, which reads the working tree — the only tree a claim is ever about. The recognised forms no longer decide refusal and only name its reason, with a fourth form `git-command` covering what they do not recognise, so being wrong about which applies costs a vaguer sentence and never an acceptance. Re-measured at this commit over the whole pass-2 defect family: pass-2's escape `git grep -c -e -- main -- data-raw/README.md` is refused `non-head-ref`; `-m 5`, bundled `-ce`, `-e` after `--`, `git -C dir grep` and `git describe` are all refused `git-command`; `git --no-pager log` is refused `git-history-subcommand`; plain `HEAD`, previously allowed, is refused too; and a non-git command is untouched. P1 through P7 close by construction rather than by another patch. `rev_operands()` and `VALUE_FLAGS` are deleted with the parse they served.
- 2026-08-02: pass 3 — `cairn/DECISIONS.md` gains `D-020 Amendment 1`, superseding rule 10 only and recording why the parse was abandoned; an amendment rather than an edit because rule 4 of the entry it amends says this file is history and IP4 forbids editing it, and a convention that exempted its own record would not be one. This answers the pass-2 sub-80 finding (75) that rule 10's prose had drifted from the code, which two lenses reached independently. `read_d_entry()` now reads the entry AND every `### D-0NN Amendment N`, so the parity checks read what the log actually says rather than text the log has superseded; measured at this commit, the amendment is included, the citation scope still parses from the base entry, and all 16 route ids the rules name exist. Gate: five `data-raw` checkers pass in both modes, routes/probes 16/16, shapes 4/4, refused forms 4/4, `air format --check .` clean, `lintr::lint_package()` 0 lints, `cairn_validate` all checks passed.

- 2026-08-02: review pass 3 FAILED the gate — THIRD return; thrash triggers (a) and (b) both fire. AC2 fails a third time, by a channel that is not a git command: an `awk` row running `awk 'BEGIN{ "git rev-list --count main..HEAD" | getline x; print x }'` validates, is not refused, and passes, printing `commits:11` — awk's `| getline` and `system()` spawn a shell, so the docstring's "there is no shell ... inexpressible" and D-020 rule 9 are both false as shipped. A second channel is open beside it: a `grep`/`ls`/`awk` row reads `.git/` directly. Pass 3 did close the entire pass-1/pass-2 git-parsing family by construction, verified independently by all three lenses, and repaired the D-020 drift legally via Amendment 1. The three failures are three different channels, not variations: AC2 asks for a guarantee about what a command DOES and every implementation has delivered a rule about what a command NAMES. Closing it needs an allowlist over capability — dropping `awk`/`ls`, restricting `python3` to committed helpers, refusing `.git/` paths — which changes the shape set AC1 and AC3 rest on and is not implement's to decide. No scorer pass was run (the gate stops at criterion verification, before triage); all findings are logged in the Review section instead. AC2's tick withdrawn. Status -> in-progress.

- 2026-08-02: pass-3 gate disposition, maintainer's choice: PARKED as `blocked` rather than re-planned, escalated, or re-scoped. The blocker is a maintainer decision on how the history-reading guarantee should be met — the three passes established that a blocklist over what a command NAMES cannot deliver it, and the candidate answer is an allowlist over what a command may DO (drop the `awk` and `ls` shapes, restrict `python3` to committed helpers under `data-raw/`, refuse any path under `.git/`), which re-cuts the shape set AC1 and AC3 rest on and so is a plan-level call. Nothing proceeds on this branch meanwhile. What is done and green: the ledger, the checker with 16 probed and excision-verified routes, five registered rows over four figures, the citation gate, D-020 and its Amendment 1, the CI wiring, and all nine CI checks on `87181a0`/`b1e4090` — eight of nine criteria carry fresh evidence. What is open: AC2 (unticked), the `awk`/`.git` capability channels, and the pass-3 finding list in the Review section. M100 stays blocked behind this milestone.
- 2026-08-03: amendment return: AC2 — "Refusal is decided by one test — `argv[0] == \"git\"` — so every `git` command is refused whatever its flags spell (D-020 Amendment 1 rule 1), and the enumerated history-dependent forms ... only name the reason, `git-command` covering the rest ... The docstring and D-020 Amendment 2 state what this does NOT claim — it is a syntactic rule over the ledger cell, not a sandbox". Maintainer decision at the 2026-08-03 gate unparks the milestone: the blocker was which of two routes met the history-reading guarantee, and the answer is neither — the guarantee is withdrawn rather than met. What failed at pass 3 was not AC2's enumeration but a claim asserted BESIDE it (D-020 rule 9 and the docstring: a shell is "inexpressible"), which `awk`'s `| getline` falsifies. Narrowing the promise to what a stated procedure settles is the repair cairn's plan gate now prescribes; the capability allowlist is declined and recorded as a falsifiable candidate in D-020 Amendment 2. Status blocked -> in-progress.

- 2026-08-03: review pass 4 FAILED the gate — FOURTH defect return; thrash trigger (a) holds from the third. Status read `in-progress` on entry (the amendment return set it there and `a946df1` landed the amendment without flipping the mirror); this pass treated the maintainer's invocation as that transition. AC2 fails as amended on its docstring half: `grep -n "\.git" data-raw/check-record-claims.py` returns no match, so the docstring never states the `.git/` channel AC2 requires it and D-020 Amendment 2 to state jointly — the refusal machinery itself passed over nineteen git spellings including every pass-1/2/3 escape. [O] diff-bug 25 findings, [S] blame-history 2, [S] prior-review 3 (GitHub inline-comment probe `[]` a fourth time); an [S] scorer scored all 27 and six reached 80: O4 (the gate failure), O1/B2 `lint.yaml` still asserting the withdrawn history-free guarantee, O25/B1 AC1's text describing the deleted `git` shape, O3 D-021's M93/M100 pass counts contradicting the archive and D-020, O7/R1 the dangling `D-045` reference in the checker, O6 the dangling `IP4` reference behind the citation scope. 21 sub-80 findings logged in the Review section. AC9 re-run clean at this head (suite FAIL 0 / PASS 5435; check 0/0/0; lintr 0; air clean; five checkers green both modes; `cairn_validate` all checks passed, new `record density` advisory on the ROADMAP stamp at 418 chars). No fixes applied this pass — the floor return stops at criterion verification. Disposition to the maintainer.

## Decisions

## Review

**Review pass 1 — 2026-08-02.** PR #109, head `5eac8d1`, branch
`m102-record-claims-ledger` cut from `main` at `53dde1c`; `main` has not moved
since (`git rev-list --count HEAD..origin/main` = 0), so no merge-in was needed
and this evidence is not stale. All figures below come from commands run at this
commit, never from recall.

**AC1 — checker, grammar, execution, shape parity.** `data-raw/check-record-claims.py`
imports `glob`, `os`, `re`, `shlex`, `subprocess`, `sys`, `tempfile` and nothing
else: stdlib only. `COLUMNS` is PARSED out of the module docstring's `column:`
lines rather than declared beside it, so the stated grammar and the enforced one
cannot differ; it parses to the eleven columns AC1 names, in order. Grammar
violations exit non-zero, measured one route at a time: a non-slug `id`, an
`expected_rc` of 999, an `uncited` row with no reason, and a header not matching
the stated columns each return a `grammar` failure. Execution: a command exiting
1 against `expected_rc = 0` returns `rc-mismatch`; stdout not fullmatching
returns `match-mismatch`; a `python3 -c "import time; time.sleep(9)"` row under a
1s timeout returns `timeout`. Commands are tokenized with `shlex.split` and run
with `subprocess.run(argv)` — no shell, so a pipeline, redirection, substitution
or chained second command is inexpressible rather than merely discouraged. Shape
parity was driven in BOTH directions AC1 names: a docstring listing a sixth
`ghost` shape and a docstring omitting `git-grep` each return `shape-parity`.

**AC2 — refused history-dependent forms.** Three forms are stated in the
docstring, and each is constructed by its own committed sample and shown refused:
`git log --oneline` → `git-history-subcommand`; `git grep -c token main..HEAD` →
`rev-range`; `git grep -c token origin/main` → `non-head-ref`. Each sample
triggers exactly its own form and no other. `--self-test` runs all three, both as
bare commands and as ledger rows carrying them, and a stated form that no sample
triggers is itself a failure (`refused-parity`), so a dead rule cannot sit in the
docstring unnoticed.

**AC3 — the four named figures, and one row per shape.**
`python3 data-raw/check-record-claims.py` → `OK: 5 registered claim(s)
re-derived, 0 failure(s)`. The five rows cover the five dispatched shapes
one-for-one (`ls`, `grep`, `python3`, `awk`, `git-grep`) and carry all four named
figures: the `data-raw` checker inventory by name (`ls`, exact five paths); the
count of `data-raw` checker invocations in `.github/workflows/lint.yaml` (`grep -c`,
exactly 8); the three κ_m worst-downward-step figures (`python3`, exactly
`-0.046`/`-0.068`/`-0.162`); and the ROADMAP terminal-row count (`awk`, exactly
5). Every expected value is an exact figure, never a range or a bare `.*`. Each
row settles against an artifact committed on the default branch — verified per
row with `git cat-file -e origin/main:<path>`: `data-raw`,
`.github/workflows/lint.yaml`, `m88-kappa-table.rds`, `m90-kappa-tables.rds` and
`cairn/ROADMAP.md` are all present there. The two rows whose figures this
milestone itself changes (the inventory and the invocation count) settle against
main-resident artifacts whose CONTENT this merge updates — the case AC3's clause
excludes is M100's, where the artifact itself exists only on a branch and no
merge would bring it.

**AC4 — symmetric registration over a parsed scope.**
`parse_scope(read_d_entry())` returns exactly `cairn/ROADMAP.md`,
`cairn/LESSONS.md`, `cairn/DESIGN.md`, `data-raw/README.md` — read out of D-020's
rule 4, not declared by the checker, so the artifact under test cannot choose its
own scope; a D-entry listing fewer and a D-entry listing an extra path each
return `scope-parity`. Both citation directions fail as required: a
`[claim:<id>]` naming no row returns `unresolved-citation`, and a row whose
`disposition` is `cited` that no scope file cites returns `uncited-row`. Live
state: five citations across the scope, one per row, each resolving. The
registration-not-detection limit is stated in the docstring under its own heading
WITH its ground (a prose detector either misses unanticipated claim classes or
floods the author, and both end with it switched off) and again as D-020 rule 5,
including the honest consequence that an unregistered figure is unchecked and the
tool will never say one exists.

**AC5 — author-declared `kind`, and a falsifier that must fail.** `kind` is read
from the row and never inferred; the shape classifier is a mis-registration trap
only, and D-020 rule 8 records why (an output-shape classifier misses the
`^0 problems$` and `test !` forms and would rebuild the vacuity it exists to
catch). Measured: an `absence` row with no `falsifier_command` returns
`absence-no-falsifier`; a `presence` row whose `expected_rc` is 1 returns
`kind-misregistered`, as does one whose `expected_match` is `^0$`; a falsifier
that MEETS its row's expectation returns `falsifier-passes`. The one shipped
`absence` row certifies that `cairn/DECISIONS.md` carries no claim citation, and
its falsifier points that same `git grep` at the committed
`data-raw/record-claims-fixtures/citation-present.md`, which does carry one —
run at this commit, it exits 0 against the row's expected 1 and so fails the
row's expectation, which is the property AC5 requires and the direct answer to
M100 pass-5 F1.

**AC6 — every route probed, every probe load-bearing.** The docstring states 16
routes and the probe registry holds 16, asserted as SETS and not counts: a
docstring naming a 17th `ghost` route and a docstring naming only `grammar` each
return `route-parity`. `--self-test` drives all 16 probes against a passing
control row (the control returns no failure) and then excises each route's
sentinel-delimited block from a temp copy of the script, running that copy's
`--probes`: across all 16 excisions, exactly the excised route's own probe goes
MISSED and no other — 0 problems, so no probe is passing for a reason other than
the route it claims. The route set covers all nine AC6 names — grammar,
rc-mismatch, match-mismatch, timeout, refused-form, unresolved-citation,
uncited-row, absence-no-falsifier, kind-misregistered — plus seven more.

**AC7 — the convention entry.** `cairn/DECISIONS.md` gains D-020 with 17
explicitly numbered rules, each carrying a probe token: 16 name a route id and
one (rule 5, registration-not-detection) records `probe: none` with its ground,
that it is a limit on what the checker reads rather than a condition any input
can drive. `--self-test` parses that list and asserts every named route id exists
in the probe registry — all 16 do — and a rule naming a route the checker does
not implement returns `rule-probe-unknown`. The list states each minimum AC7
requires: the row grammar (rule 1), that a record states a load-bearing figure by
citing a row id (rule 2), the registration-not-detection limit (rule 5), the
absence-falsifier rule (rules 6–7), the citation scope list (rule 4), and the
relation to D-009 in its own paragraph — the two divide by surface and claim
type, `references/` pages and dated observations against tracking records and
figures, with neither superseding the other.

**AC8 — CI.** The `check-references` job runs `python3 data-raw/check-record-claims.py`
then the same with `--self-test`, in that order, behind a comment naming M102 and
the ledger path. Green on the PR with both steps in that run's own log: `gh api
repos/jmgirard/intraclass/actions/jobs/91544700240` lists step 9 "Re-derive the
registered record claims (M102)" and step 10 "Self-test the record-claims checker
(route excision)", both `success`, job green in 24s; re-confirmed green on head
`5eac8d1` (job 91546936198, 24s). The route-excision self-test therefore passes on
the depth-1 CI checkout, not only locally.

**AC9 — gate.** Re-run at this commit: all five `data-raw` checkers pass in both
check and self-test modes (ten invocations, enumerated by
`ls data-raw/check-*.py data-raw/enumerate-*.py`); `air format --check .` clean;
`devtools::document()` no diff; `cairn_validate` all checks passed with two WARNs
(`sizing (split tripwires)` 1 — nine criteria, kept whole at the plan gate; and
`dangling id tokens` 321, pre-existing). Suite `NOT_CRAN=true CI=true` FAIL 0 /
ERROR 0 / SKIP 23 / PASS 5435, identical to `main`'s baseline, and
`devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors / 0 warnings /
0 notes in 2m54s; both ran before the final tracking-only commit, and nothing
outside `cairn/` (which is `.Rbuildignore`d) changed after them, so neither is
stale. `lintr::lint_package()` 0 lints.

**Findings — three fresh-context lenses, then a scorer.** [O] diff-bug returned
24 findings, [S] blame-history 2 (plus 5 checked-and-clear), [S] prior-PR-comments
0 — its GitHub probe returned `[]` (no inline review comments exist in this repo
at all), and the archived `## Review` sections of M73, M74, M79, M80, M81, M85,
M91 and M94 show nothing this diff regresses. An [S] scorer that generated none
of them scored all 26 against the rubric; 2 scored ≥ 80.

**ACTIONED (≥ 80).**

- **O1 (85) — AC2 FAILS as written.** `refused_hits()` implements "a ref other
  than `HEAD`" as a four-item blacklist (`origin/`, `refs/`, exactly
  `main`/`master`, `@{`) rather than as the rule AC2 states. Re-measured
  independently at this commit: `git grep -c token HEAD~1`, `HEAD^`, `53dde1c`,
  `v0.1.0`, `upstream/main` and `some-branch` are each a ref other than `HEAD`
  and each returns NOT REFUSED; only `origin/main` and `main..HEAD` are caught.
  A ledger row registering `git grep -c pattern HEAD~1` is therefore accepted,
  passes locally on a full clone, and fails on the depth-1 CI checkout — the exact
  divergence the refusal mechanism exists to prevent. AC2's tick is withdrawn:
  the pass-1 evidence recorded above measured only the three committed samples,
  which is what made a blacklist look like the rule.
- **O2 (82) — a grammar-failed row crashes the run.** `check_falsifiers()` is
  called unconditionally in `run_check()`, unlike the row loop above it which
  gates execution behind `if not row_fails:`. Re-measured: an `absence` row with
  `expected_rc = abc` is correctly detected by `validate_row` as a `grammar`
  failure, and `check_falsifiers` then raises an uncaught
  `ValueError: invalid literal for int()`. The process still exits non-zero, so
  AC1's letter holds, but the grammar failure that was correctly detected is never
  printed and the operator sees a traceback instead of a report.

**LOGGED, sub-80 (24).** Excluded from the actioned list, surfaced here, none
silently dropped. Three are close to the bar and bear on this milestone's own
subject, so they are named first:
- O13 (78) the ledger's `_line` numbers are off by the count of comment/blank
  lines, so today every diagnostic names the wrong TSV line.
- O11 (75) `data-raw/README.md` says "History carries no claim citation at all"
  while the certifying row searches only `cairn/DECISIONS.md`; D-020 rule 4 also
  counts work logs and `milestones/archive/` as history.
- O12 (72) the ROADMAP comment the terminal-row citation sits on asserts both a
  count and five specific milestone ids; the row re-derives only the count.
- O3 (68) `reason = -` satisfies the uncited-row reason gate, `-` being the file's
  own null sentinel. O5 (60) a falsifier need only fail the expectation, not be
  the row's own command against a constructed input. O8 (60) D-020 states the
  D-009 relation in a paragraph after the numbered list rather than in it.
- O6 (55) the `record` column is never bound to which scope file cites the row.
  O7 (55) two route emissions sit outside their sentinels and survive excision.
  O15 (55) `--probes` always exits 0 and an unknown flag falls through to the
  default check. O20 (50) `git grep -e main` false-positives as a ref.
- O10 (45) the invocation-count command is not scoped to the job its claim names.
  O19 (45) the absence row's regex misses D-020's literal `[claim:<id>]` only
  because `<` is not `[a-z]`. O21 (45) a missing scope file crashes rather than
  fails. O24 (45) the κ_m helper uses another checker's underscore-private API.
- O4 (40) nothing forbids a tautological `expected_match`. O14 (40) the checker is
  not repo-root-safe and honours `root=` inconsistently. O9 (35) the inventory and
  invocation-count figures are self-referential. O16 (35) `parse_scope` keys on an
  em dash. O18 (35) refused-parity derives its coded set from the samples, not the
  detector. O22 (35) the `python3` shape can reach history internally. O17 (32)
  `check_rule_probes` checks one direction only. O23 (30) the self-test replays the
  timeout probe 16 times. B1 (30) D-020 takes the id M101's committed plan names —
  judged sequencing for a different milestone, not a defect here. B2 (20)
  `cairn_validate` does not check decision-id uniqueness — a pre-existing gap.

**Gate: FAILED — first return.** O1 demonstrates AC2 failing, which is a return
under the M130 floor. Status -> `in-progress`; the fix and re-review are the
resumed pass's work. O2 rides along as an actioned fix. The thrash count stands
at one return, well below the third-return threshold.

**Review pass 2 — 2026-08-02 (after the pass-1 fix).** PR #109, head `8ee0131`;
`main` still unmoved (`git rev-list --count HEAD..origin/main` = 0). All nine CI
checks pass on this head, `check-references` in 25s with both M102 steps
`success` in that run's log (steps 9 and 10 of job 91549891345).

**AC2 — RE-VERIFIED, now met as written.** The pass-1 failure was that "a ref
other than `HEAD`" was implemented as a four-item blacklist. It is now stated
positively over git's revision slot: a `git grep` must carry `-e <pattern>` and a
`--` separator, and every operand between them must be `HEAD`. Re-measured at
this commit over eleven distinct ref spellings — `HEAD~1`, `HEAD^`, `HEAD@{1}`,
the raw SHA `53dde1c`, the tag `v0.1.0`, `origin/main`, `upstream/main`,
`some-branch`, `refs/heads/main`, `main`, `master` — every one is refused
`non-head-ref`, and bare `HEAD` alone is allowed. `main..HEAD` is refused
`rev-range`; `git log --oneline` `git-history-subcommand`. The two delimiters
this requires are enforced by a fourth stated form, `ambiguous-operands`, because
without them a bare token could be the search pattern or a revision and nothing
here can tell. Four forms are stated in the docstring, four samples construct
them, `--self-test` runs each both bare and as a ledger row, and refused-parity
holds at 4/4 so a stated form no sample triggers would itself fail.

**AC1, AC3, AC4, AC5, AC6, AC7 — re-verified against the changed tree.** The
ledger's row numbering now reports `[3, 4, 5, 6, 7]` against true data lines
`[3, 4, 5, 6, 7]` (pass 1 measured 2–6 for the same rows). `run_check()` passes
only grammar-validated rows to `check_falsifiers()`, so a malformed row is
reported rather than raising. Five rows still cover the five dispatched shapes
one-for-one and `python3 data-raw/check-record-claims.py` returns `OK: 5
registered claim(s) re-derived, 0 failure(s)`. The one `absence` row's falsifier
still fails that row's own expectation, on both counts (`rc-mismatch` and
`match-mismatch`), now against a search widened to `cairn/milestones/archive/`
as well as `cairn/DECISIONS.md` — with `data-raw/README.md`'s sentence narrowed
to state exactly that pair rather than "History ... at all", which was the pass-1
overclaim. The terminal-row row now settles the five milestone ids in order
rather than only their count. Routes and probes remain 16/16, and the excision
harness still shows each probe load-bearing for exactly its own route. D-020 is
unchanged; its rule 10 states the refusal principle rather than the form list, so
the new mechanism satisfies it without an edit — which matters, the entry being
append-only history.

**AC8, AC9 — re-verified.** All nine CI checks green on `8ee0131`. All five
`data-raw` checkers pass locally in both modes; `air format --check .` clean;
`lintr::lint_package()` 0 lints; `cairn_validate` all checks passed. The R suite
(FAIL 0 / ERROR 0 / SKIP 23 / PASS 5435) and `devtools::check` (0/0/0) results
recorded at the first gate stand unchanged: `git diff main..HEAD --name-only`
lists nine paths, none under `R/`, `tests/`, `man/`, `NAMESPACE` or `DESCRIPTION`,
so no R-visible content changed in the fix pass.

**Findings — pass 2.** [O] diff-bug returned 30, [S] blame-history 1 substantive
(plus 3 checked-and-clear), [S] prior-review 4 (one substantive, reached
independently; the GitHub inline-comment probe returned `[]` again). An [S]
scorer that generated none of them scored 31; exactly one reached 80.

**ACTIONED (>= 80).**

- **P1 (93) — AC2 FAILS again, by a new mechanism.** In `rev_operands()` the
  `if tok == "--"` test precedes the `expect_value` test, so a `--` that is a
  FLAG'S VALUE is consumed as the pathspec separator and the scan breaks before
  reaching the real revision operand. Reproduced end to end at this commit:
  `git grep -c -e -- main -- data-raw/README.md` returns no failure from
  `validate_row` or `execute_row`, and run for real it resolves the ref —
  `main:data-raw/README.md:2`, rc 0. On the depth-1 CI checkout `main` does not
  exist, so it exits 128 and the row reds as `rc-mismatch` carrying "fault the
  record, not the run" — the exact local/CI divergence AC2 exists to prevent,
  under the exact misleading diagnosis. AC2's tick is withdrawn a second time.

**Four more parsing defects, confirmed but sub-80, that share P1's cause.** They
matter here less individually than as evidence about the approach: `-m 5`,
`-A 2` and `-C 3` have their values read as refs, so a legitimate row is refused
and the operator is told their `5` is a git ref (P2, 65); a bundled `-ce` is
refused as lacking `-e`, which it carries (P4, 68); a `-e` appearing after `--`
satisfies the delimiter test, so classification depends on a filename (P5, 45);
and `argv[1]` is read as the subcommand, so `git --no-pager log` is refused as a
non-HEAD ref rather than as a history subcommand and `git -C dir grep` draws two
spurious hits (P6, 72). Each is a distinct hole in the same hand-written parse of
git's command line.

**Verified fixed, and holding (pass-1 O2, O11, O12, O13).** Both [S] lenses and
the [O] lens independently re-ran the pass-1 counterexamples: a malformed row now
prints its grammar failure instead of raising; row line numbers report 3-7
against true file lines 3-7; the absence row's widened search passes live against
every archived milestone; the terminal-row row settles the five ids in order. No
fix reintroduced its defect.

**LOGGED, sub-80 (30).** Beyond the four above: Q1/R1 (75) D-020 rule 10 names
three refused forms and the fix pass added a fourth, `ambiguous-operands`, so the
entry's prose no longer describes the code — and `cairn/DECISIONS.md` being
append-only under IP4, the only legal repair is a superseding entry, which pass 2
did not add; nothing diffs that prose against the code, which is pass-1 finding
O17's blind spot made concrete. Then P16 (58) `reason = -` satisfies the reason
gate; P9 (55) the absence row covers two of D-020 rule 4's three history
surfaces; P3 (52) `ambiguous-operands` returns early and masks a co-present form;
P14 (50) an `OSError` `rc-mismatch` emission sits outside its sentinel; P17 (50)
the inventory row's claim says "stdlib-only", which `ls` cannot settle; P13 (48)
a missing scope file raises instead of failing with a route id; P11 (45) the
D-009 relation sits outside D-020's numbered list; P22 (45) the κ_m helper seeds
its worst step at 0.0 and would print a monotone level as `0.000`; P18 (45)
the README's "stdlib-only" is itself unregistered; P5 (45); P15 (42) `--probes`
always exits 0 and a mistyped flag runs the ordinary check; P20 (42), P25 (42),
P26 (40), P24 (40), P23 (38), P30 (38), P8 (35) the widened absence row as a
future tripwire over immutable archive text, P21 (33), P27 (30), P28 (30), P10
(30) AC3's two self-referential figures, P29 (28), P12 (25) the D-020 id M101's
plan names, P19 (22), plus R3's note that the refused-form samples are tuned to
the implementation's control flow.

**Gate: FAILED — second return, thrash trigger (b) fires.** AC2 has now failed
twice, each time by a different mechanism of the same shape: a way of naming a
non-HEAD ref that the hand-written parse of git's command line does not reach.
The thrash rule reads that as a wrong approach rather than a mis-sized one, and
its remedy is to reconsider the alternative the plan gate recorded against
(2026-08-02: deepening the CI checkout to `fetch-depth: 0`, refused because a
pull-request checkout is a synthetic merge commit). Trigger (a) does not fire —
this is the second defect return, not the third. Status -> `in-progress`; the
disposition goes to the maintainer.

**Review pass 3 — 2026-08-02.** PR #109, head `87181a0`, `main` unmoved. All
nine CI checks green on this head. [O] diff-bug returned 18 findings, [S]
blame-history 1 substantive, [S] prior-review 2 aggravated + 7 verified-fixed;
the GitHub inline-comment probe returned `[]` a third time. No scorer pass was
run: the gate fails at criterion verification, which is a stop before triage,
and the findings below are recorded in full for the re-plan to consume rather
than filtered by a confidence bar. That is a deviation from the review
procedure's scorer step and is stated rather than glossed.

**AC2 — FAILS a third time, by a channel that is not a git command at all.**
Reproduced independently at this commit: a row with `shape = awk` and command
`awk 'BEGIN{ "git rev-list --count main..HEAD" | getline x; print "commits:" x }'`
returns NO FAILURES from `validate_row`, is not refused, and passes
`execute_row`; run for real it prints `commits:11`. awk's `| getline` and
`system()` spawn a shell. Two shipped records are therefore false: the module
docstring's "there is no shell, so a pipeline, a redirection, a substitution or a
chained second command is not merely discouraged but inexpressible", and D-020
rule 9, which states the same. The command names two of the three forms AC2
enumerates — a `rev-list` subcommand and a `main..HEAD` range — and is not
refused, so AC2 fails as written. A second channel is open beside it: a `grep`,
`ls` or `awk` row can read `.git/` directly (`grep -c refs/remotes/origin/main
.git/packed-refs` validates and passes here, and returns different output on a
depth-1 clone), which no rule mentions.

**What three passes have established about the approach.** AC2 has now failed
three times, and the three mechanisms are not variations — they are different
channels: ref spellings the blacklist did not enumerate; a `--` that git's own
CLI treats as an argument; and a non-git program that spawns a shell. Each fix
closed its channel completely and the next pass found another. The pattern is
that AC2 asks for a guarantee about what a command DOES ("does not read
history") and every implementation has delivered a rule about what a command
NAMES. A blocklist over names cannot reach a channel nobody has thought of yet,
and that is a plan-level property of the criterion, not a coding defect in any
one pass. What would close it is an allowlist over capability — for instance
dropping `awk` and `ls`, restricting `python3` to committed helper scripts under
`data-raw/`, and refusing any path under `.git/` — which changes the shape set
AC1 and AC3 both rest on and is therefore not implement's to decide.

**What pass 3 did close, verified by all three lenses independently.** The
entire pass-1 and pass-2 defect family is gone by construction: `git grep -c -e
-- main -- <path>` is refused `non-head-ref`, and `-m 5`, bundled `-ce`, `-e`
after `--`, `git -C dir grep`, `git describe` and bare `HEAD` are all refused.
`rev_operands()` and `VALUE_FLAGS` are deleted with the parse they served. The
pass-2 finding that D-020 rule 10 had drifted from the code is repaired the
legal way, by `D-020 Amendment 1` rather than an edit, matching this file's
existing `D-008 Amendment 1` precedent; `read_d_entry()` now reads the entry and
its amendments, so the parity checks read what the log says rather than text it
has superseded.

**Findings, recorded in full.** From [O]: the awk shell escape and the `.git/`
path channel (above); AC2's refusal is now redundant with the four-program shape
whitelist, so deleting `refused_hits()` would change no reachable ledger outcome
and its probes demonstrate a rule that cannot alter one; `parse_scope` takes the
FIRST `Citation scope:` line and the base entry always precedes its amendments,
so an amendment can never amend the scope — the checker would enforce the
superseded list while reporting green; `read_d_entry`'s prefix match absorbs a
future `### D-0200` or `### D-020-bis`; its correctness depends on document
order rather than on knowing which chunk is the base; the docstring's and
`lint.yaml`'s "history-free by construction" claims are falsified by the two
channels above; `refused_hits` silently returns nothing on an unbalanced quote,
masked only by a separate `unknown-shape` path; refusal keys on the literal
token `git`, so `/usr/bin/git`, `./git`, `env git` and a shlex-empty `argv[0]`
bypass it (all currently caught by the shape whitelist instead);
`git-history-subcommand` now scans every token, so `git grep -e log` is named a
history subcommand and `git show HEAD~1` emits two failures for one command;
`REF_SHAPED` covers only some ref spellings, so `git ls-tree v0.1.0` and
`git ls-tree some-branch` are refused as `git-command` rather than with the
reason AC2 names; `grep -r` widens the absence row to untracked and ignored
files where `git grep` walked the index (also reached by [S] blame-history —
currently zero such files exist under either searched path, so it is latent);
`refused-parity` still derives its coded set from the samples rather than the
detector; `read_scope`, `read_d_entry` and a mistyped flag still reach non-zero
or misleading exits with no route id; `data-raw/README.md`'s new prose carries
four unregistered figures ("all stdlib-only", "four of the five are wired",
"each wired checker twice", "run locally only") beside its two registered ones;
the κ_m helper conflates a monotone level with a zero step and reaches another
checker's underscore-private API; and the docstring's stated refused set is no
longer AC2's set verbatim, `non-head-ref` having been narrowed to "a recognised
ref spelling" with a fourth non-history form added. From [S] prior-review, two
previously-logged findings are aggravated rather than fixed: the D-020 id
collision M101's committed plan sets up is no longer inert, because
`read_d_entry` now merges a colliding entry's rules and scope instead of
ignoring them; and the archive tripwire changed character with the `grep -r`
swap.

**Record repair.** The pass-2 log recorded several sub-80 findings as an id and
a score with no description, which does not surface them. Their content is
carried above where pass 3 touched it, and the full text of every pass-2 finding
is in this session's transcript and the commit record; the re-plan should
re-derive rather than rely on the abbreviated list.

**Gate: FAILED — third return. Thrash triggers (a) and (b) both fire.** (a) at
the third return: no further retry under the current plan; the milestone routes
through `/milestone-plan`. (b) because the same criterion has failed three
times, each by a new mechanism of the same shape; its diagnosis — a blocklist
over what a command names cannot deliver a guarantee about what a command does —
carries into that routing, as does the option of escalating the design question.
No re-plan or split has been spent on M102, so (a)'s standard remedy applies.
Status -> `in-progress`; the disposition goes to the maintainer.

**Review pass 4 — 2026-08-03 (after the AC2 amendment return).** PR #109, head
`a946df1`; `main` unmoved (`git rev-list --count HEAD..origin/main` = 0), so no
merge-in was needed and this evidence is not stale. The milestone file read
`in-progress` on entry: the amendment return set it there, `a946df1` landed the
only work that return convened, and nothing flipped the mirror back to `review`.
This pass treats the maintainer's `/milestone-review` invocation as that
transition rather than as an override of a criterion. All figures below are from
commands run at this commit.

**AC2 — FAILS as amended, on the docstring half of its own disclaimer clause.**
The refusal machinery itself is met and was re-measured over nineteen `git`
command spellings, including every one that defeated passes 1–3: `git log`,
`git blame`, `git show HEAD`, `git rev-list --count main..HEAD`, pass-2's escape
`git grep -c -e -- main -- f`, `HEAD~1`, `HEAD^`, the raw SHA `53dde1c`, the tag
`v0.1.0`, `upstream/main`, a bare `some-branch`, plain `HEAD`, `git -C dir grep`,
`git --no-pager log`, `git describe`, `git ls-tree v0.1.0`, `git status` and bare
`git` — all nineteen refused, and a non-git command untouched. Four forms are
stated in the docstring, four samples construct them, `refused-parity` holds 4/4,
and `--self-test` runs each sample both bare and as a ledger row. What fails is
the last sentence: AC2 requires that "the docstring AND D-020 Amendment 2 state
what this does NOT claim … an accepted shape's own program can still reach a
shell or `.git/`". Measured: `grep -n "\.git" data-raw/check-record-claims.py`
returns NO match. The docstring states the shell channel twice and states the
general form ("nothing here constrains what an accepted command DOES"), but never
the `.git/` channel that AC2 enumerates; D-020 Amendment 2 states both. Reading
the general clause as covering the enumerated one is the charitable reading the
never-reinterpret rule forbids, so AC2 is unmet and its tick is not taken. The
repair is one sentence in the docstring, not a redesign.

**AC1 — operative requirement re-verified; its descriptive clause is stale.**
`COLUMNS` still parses out of the docstring to the eleven named columns in order;
`SHAPES` is `{ls, grep, awk, python3}` and shape parity is driven in both
directions (`shape-parity` on a docstring-only sixth shape and on an omitted one);
grammar, `rc-mismatch`, `match-mismatch` and `timeout` each fire on constructed
input; the checker imports `glob`, `os`, `re`, `shlex`, `subprocess`, `sys`,
`tempfile` and nothing else. The tick stands on that operative clause. It does not
stand on AC1's descriptive aside "runs with `python3`, POSIX shell and
working-tree `git` alone": pass 3 deleted the `git-grep` shape and the docstring
now reads "There is deliberately no `git` shape", so no shape runs `git` at all.
That is criterion text falsified outside its named procedure's domain — an
amendment matter for the plan, recorded here and not patched review-side.

**AC3–AC7 — re-verified at this head.** `python3 data-raw/check-record-claims.py`
→ `OK: 5 registered claim(s) re-derived, 0 failure(s)`; the five rows cover the
four dispatched shapes and carry all four named figures (inventory by name;
invocation count 8; the three κ_m steps −0.046/−0.068/−0.162; the five terminal
milestone ids in order), every expected value an exact figure. `parse_scope`
returns exactly the four correctable records, read out of D-020 rule 4, and
`scope-parity` fires on both a short and a long list. Five citations across the
scope, one per row, each resolving; both citation directions red on constructed
input. The one `absence` row's falsifier still fails that row's own expectation.
Routes and probes hold at 16/16 as SETS, `--self-test` is green, and each of the
16 route excisions silences exactly its own probe. D-020's rule list parses to 17
rules, every named route id present; `read_d_entry` reads the base entry plus both
amendments.

**AC8 — CI green on the amendment head.** `check-references` passed in 25s on
`a946df1`; job 91699794725 lists step 9 "Re-derive the registered record claims
(M102)" and step 10 "Self-test the record-claims checker (route excision)", both
`success`, in that run's own log. Route excision therefore passes on the depth-1
CI checkout.

**AC9 — gate clean, run fresh at this head.** Suite `NOT_CRAN=true CI=true`
FAIL 0 / WARN 2 / SKIP 23 / PASS 5435, identical to `main`'s baseline;
`devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors / 0 warnings /
0 notes in 2m24s; `lintr::lint_package()` 0 lints; `air format --check .` clean;
`devtools::document()` no diff; `pkgdown::check_pkgdown()` no problems; all five
`data-raw` checkers pass in both check and self-test modes (ten invocations,
enumerated by `ls data-raw/check-*.py data-raw/enumerate-*.py`). `cairn_validate`
all checks passed, with a NEW advisory this pass: `record density` on
`cairn/ROADMAP.md:4`, the hygiene stamp at 418 characters against the <400 cap.
No NEWS entry is owed — the diff touches no `R/`, `tests/`, `man/`, `NAMESPACE`
or `DESCRIPTION` path, so nothing user-visible changed.

**Findings — three fresh-context lenses, then a scorer.** [O] diff-bug returned
25, [S] blame-history 2 substantive (plus 5 checked-and-clear), [S] prior-review 3
substantive; the GitHub inline-comment probe returned `[]` a fourth time, and the
archived `## Review` sections show nothing this diff regresses. An [S] scorer that
generated none of them scored all 27; six reached 80.

**ACTIONED (≥ 80).**

- **O4 (85) — AC2 fails as amended.** The docstring does not state the `.git/`
  half of the disclaimer AC2 requires it and D-020 Amendment 2 to state jointly;
  `grep -n "\.git" data-raw/check-record-claims.py` returns nothing. Reached by
  the [O] lens, re-measured independently at this commit. This is the gate
  failure.
- **O1/B2 (88) — `lint.yaml` still asserts the guarantee the amendment withdrew.**
  `.github/workflows/lint.yaml:73-75` reads "Stdlib-only, R-free, and history-free
  by construction (this checkout is depth-1, so the checker refuses commands that
  read repository history)". Pass 3 named `lint.yaml` beside the docstring as
  carrying this claim; `a946df1` repaired the docstring and D-020 and left this
  comment untouched. Reached independently by the [O] and [S] blame lenses.
- **O25/B1 (82) — AC1's committed text describes a shape set that no longer
  exists.** "runs with `python3`, POSIX shell and working-tree `git` alone",
  against a docstring that now says "There is deliberately no `git` shape". The
  T3 work-log note at line 163 likewise still lists five shapes including
  `git-grep`. Reached independently by the [O] and [S] blame lenses.
- **O3 (82) — D-021's motivating figures contradict the committed record and each
  other.** D-021 says "M93 ran eight" where
  `cairn/milestones/archive/M93-boundary-abort-hint.md:19` records "Ten passes,
  three re-cuts"; D-021 says "M100 ran three returns" where D-020, added by this
  same milestone, says M100 "returned from review five times" and the checker
  docstring says "M100 passes 1-5" — three figures for one quantity, two of them
  in one file. Its census also names M95 and M98 as prose-verification milestones
  while its own Untouched clause exempts numeric and behavioural pins, which is
  what both are.
- **O7/R1 (82) — `D-045` is a dangling decision reference** in the checker's own
  SCOPE comment (`data-raw/check-record-claims.py:141`). This repo's
  `cairn/DECISIONS.md` holds D-001…D-021; `grep -rn "D-045" cairn/` returns
  nothing. The rule it means is D-020 rule 4. Reached independently by the [O] and
  [S] prior-review lenses.
- **O6 (80) — `IP4` is a dangling principle reference**, and it is the sole stated
  justification for excluding history from the citation scope. `cairn/DESIGN.md`
  defines IP1–IP3 only and `cairn/PRINCIPLES.md` names no IP4; IP4 is cited in
  D-020 rule 4, in Amendment 1, in the checker, and in three work-log lines.

**Triage.** All six are recorded for the disposition rather than fixed in this
pass: the gate stops at criterion verification under the return floor, and O4 is
the criterion failure itself. O1, O3, O7 and O6 are prose-drift and dangling-
reference defects of exactly the class this milestone exists to catch, each a
one-line or one-sentence repair. O25 is criterion text falsified outside its
procedure's domain and is an amendment matter for the plan, not a review-side
patch.

**LOGGED, sub-80 (21).** Excluded from the actioned list, surfaced here, none
silently dropped. O10 (72) a mistyped flag falls through to the ordinary check and
exits 0, so a renamed CI flag would silently void AC8's self-test step. O8 (70)
D-021 does not supersede the abort-remedy-ledger candidate row it now bars, though
its own Consequences clause says supersede rather than ignore. O2 (65) a falsifier
is accepted on ANY failure, so a deleted fixture or a typo'd path keeps certifying
— the AC5 vacuity one layer up, latent because the shipped falsifier is genuine.
O12 (55) a missing scope file raises instead of failing with a route id. O22 (55)
D-021's "the narrowed AC2 above" is a cross-document dangling deictic, and its
"first decision entry whose subject is tracking prose" is contested by D-009.
O23 (55) the amendment's own work-log line misquotes the AC2 it records, closing
before the `.git/` clause. O5 (55) Amendment 2 supersedes rule 9 whole, dropping
the shape-membership half, and carries no `probe:` token, so the superseded text
still supplies `probe: unknown-shape` to the parser. O24 (50) a duplicate-id row
is reported and still executed, its citation state satisfied by its twin. O13 (50)
`refused_hits()` cannot change a reachable outcome now that no shape maps to git,
and `/usr/bin/git`, `./git` and `env git` bypass the literal-token test. O11 (45)
`--probes` always exits 0. O14 (45) `parse_scope` takes the first `Citation
scope:` line, so no amendment can ever amend the scope. O15 (40) `read_d_entry`'s
prefix match would absorb a colliding `D-020`, which M101's committed plan
reserves. O9 (35) the M100/M101 re-judgement gate is stated in the ROADMAP hygiene
stamp but not on the rows. O16 (35) an `OSError` `rc-mismatch` emission sits
outside its sentinel. O18 (35) the invocation-count row is scoped to the whole
file, not the job its claim names. O20 (35) the `record` column is never bound to
the citing file. O19 (30) the README section adds four unregistered figures beside
its two registered ones. B3 (25) `grep -r` widens the absence row to untracked
files, latent at zero. O21 (15) `check_rule_probes` checks one direction, which is
what AC7 asks for. O17 (15) moot, self-resolved by this pass. B4 (15) the
`record density` advisory above.

**Gate: FAILED — fourth defect return.** O4 demonstrates AC2 failing as amended,
which is a return under the M130 floor. Status stays `in-progress`. Thrash trigger
(a) holds — it was reached at the third return and is a threshold, not a moment —
so no further retry is queued under the current plan and the milestone routes
through `/milestone-plan`. Trigger (b) does not fire fresh: this failure is a
missing sentence in a record, not another channel defeating the refusal rule,
which passes 1–3 were. The composition rule leaves (a)'s standard remedy in force,
no re-plan or split having been spent on M102 — the pass-3 disposition was a park,
and the 2026-08-03 return was an amendment. The disposition goes to the
maintainer.
