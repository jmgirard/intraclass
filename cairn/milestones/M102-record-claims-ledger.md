# M102: A registered claims ledger, and the CI checker that re-derives it

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP7
- **Branch/PR:** `m102-record-claims-ledger`

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

- [ ] AC1 A committed stdlib-only `data-raw/check-record-claims.py` reads
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
- [ ] AC2 A command naming any of an enumerated set of history-dependent forms —
      a `git log`/`blame`/`rev-list`/`show` subcommand, a `<rev>..<rev>` range, or
      a ref other than `HEAD` — is refused with its reason, that checkout being
      depth-1 with no `main` ref. The set is stated in the docstring and each form
      carries a `--self-test` probe constructing it and showing the refusal.
- [ ] AC3 The committed ledger carries a passing row for each of these four
      figures, every one settled from an artifact committed on the default branch:
      the `data-raw` checker inventory by name; the count of `data-raw` checker
      invocations in `.github/workflows/lint.yaml`; the three κ_m worst-downward-step
      figures (−0.046, −0.068, −0.162) the ROADMAP's MPL-envelope candidate row
      states; and the ROADMAP's terminal-row retention count. Plus at least one
      passing row per docstring-listed command shape. Tolerance: exact figures.
- [ ] AC4 Registration is symmetric over a file set the `cairn/DECISIONS.md`
      convention entry names: `--self-test` PARSES that scope list out of the entry
      and asserts set equality with the checker's own list, so the artifact under
      test cannot choose its own scope. Within that scope every `[claim:<id>]`
      citation resolves to a ledger row, and every row id is cited at least once
      there or carries `disposition = uncited` with a reason; either direction
      failing exits non-zero. The checker's only inputs are ledger rows and
      `[claim:<id>]` citations — it never scans prose for unregistered figures —
      and the docstring states that limit with its ground.
- [ ] AC5 A row's `kind` is author-declared, never inferred. Every `kind = absence`
      row carries a `falsifier_command` — the row's command against a committed
      constructed input under which it must produce a non-passing result — which
      `--self-test` runs and requires to fail the row's expectation; an `absence`
      row with no falsifier exits non-zero. A row whose `expected_rc`/`expected_match`
      is absence-shaped (zero count, empty result, non-match) while `kind = presence`
      exits non-zero as a mis-registration. Ground: a certifying pattern that cannot
      match the violation it certifies passes vacuously (M100 review pass 5, F1).
- [ ] AC6 `--self-test` drives every route the checker has to a non-zero exit on
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
- [ ] AC7 `cairn/DECISIONS.md` carries an entry recording the convention as an
      explicitly numbered rule list, each line ending `probe: <route-id>` or
      `probe: none — <ground>`; `--self-test` parses that list and asserts each
      named route id exists in the probe registry. The list states at minimum: the
      row grammar; that a record states a load-bearing figure by citing a row id;
      the registration-not-detection limit; the absence-falsifier rule; the AC4
      scope list; and the relation to D-009's inline settling directives for
      `cairn/references/` pages.
- [ ] AC8 `.github/workflows/lint.yaml`'s `check-references` job runs
      `python3 data-raw/check-record-claims.py` then the same with `--self-test`,
      in that order, preceded by a comment naming this milestone and the ledger
      path; the job is green on a CI run of this milestone's PR with both steps in
      that run's log.
- [ ] AC9 Gate clean: suite at `NOT_CRAN=true CI=true`;
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
- [ ] T3 Seed the ledger with the four named figures plus one row per shape; run
      every row. The κ_m row reads `data-raw/m88-kappa-table.rds` via M94's stdlib
      RDS reader (`sys.path.insert(0, 'data-raw')`) — no R in that job. Fault the
      record, not the run, if a figure disagrees.
- [ ] T4 Citation gate: parse the scope list from the D-entry, extract
      `[claim:<id>]` over that scope, symmetric missing/orphan diff, `uncited`
      disposition.
- [ ] T5 `kind` column, `falsifier_command` execution, and the mis-registration
      trap; author a falsifier for every `absence` seed row.
- [ ] T6 `--self-test`: one probe per route against a passing control; the route-id
      set-equality assertion; excise each sentinel-delimited route block from a temp
      copy and confirm exactly its own probe reds.
- [ ] T7 Append the D-entry: numbered rule list, each line naming its probe id or
      `none — <ground>`; state the D-009 relation and the scope list.
- [ ] T8 Wire both steps into `check-references` with the milestone comment; push
      and confirm the job green on the PR.
- [ ] T9 Gate per AC9. Run `check-reference-observations.py` specifically — a new
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

## Decisions

## Review
