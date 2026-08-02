# RR04: Why M100's records keep overclaiming, and what would stop it

- **Date:** 2026-08-02
- **Brief:** `cairn/reviews/RB04-record-overclaim-pattern.md`
- **Reviewed at:** branch `m100-abort-remedy-truthfulness`, commit `c01fbb2`
  (RB04 committed on top of `ae478a6`; all artifacts under review identical).
- **Independence:** this review re-ran the enumerator's `--self-test` and
  `--check` (both green, 9 sites, 4 sweep + 5 fence), recomputed the sweep row
  census and both ROADMAP `awk` commands from the committed TSV, ran three
  fresh `BULLET_RE` mutations and one glob mutation against scratch copies of
  the enumerator (repo tree untouched, `git status --porcelain` clean), and
  read every listed material in the brief's order.

## 1. Criteria defect, enforcement defect, or authoring defect?

**Primarily (b) — satisfiable criteria with zero mechanical enforcement — with
one criterion (AC5) partially (a) as written, and with a specific, nameable
authoring failure mode that (b) leaves unguarded.** Answer (c) is a real
contributing condition but is downstream of the same cause.

The evidence, from the taxonomy of the eight findings themselves:

- **Figure-transcription drift** — O5 ("reds 7"; my three plausible `BULLET_RE`
  mutations red 8, 8 and 8; the *same work-log line's* "narrowing the file glob
  to `R/ci-n*.R` reds 5" reproduces exactly, 5 of 5), O10 ("five" checkers
  where `ls data-raw/` shows four besides this milestone's own, and
  `lint.yaml` wires three), O14 (30/50 are row counts — I recomputed exactly
  30 point-fit-failed and 50 reducer-returned-interval rows among the 80
  unreached — stated as "cells", which are 6 and 10). These are all the same
  mechanism: a number observed once at a terminal, transcribed into prose from
  memory or notes, never re-derived. Nothing in the toolchain distinguishes a
  transcribed figure from a recomputed one.
- **Cross-artifact count mismatch** — O1: the ledger header enumerates seven
  shapes and claims all are probe-constructed; `_limit_shapes()` returns six
  (verified). The script docstring is careful ("Scope is a limit of the same
  kind", no probe claim), so three records describing one code fact drifted
  independently and only one is right. Nothing checks the three against the
  code or each other.
- **Re-cut staleness in append-only sections** — O2 (`grep -c 'D-020'
  cairn/DECISIONS.md` = 0, verified) and O11: dated `## Decisions` entries,
  true of the branch when written, made false of the tree by the T1 revert,
  and untouchable under IP4. This is not an authoring error at all — it is a
  *missing rule* for what a re-cut owes the live record sections it falsifies
  (question 4).
- **Scope overstatement in a summary sentence** — O6: the sweep header's
  "across the whole class of data that triggers the abort" against a grid that
  feeds the classical guard `gen_mse0` only (verified in the grid loop,
  `data-raw/sweep-abort-remedies.R:362-396`), so the `!is.finite(f)` disjunct
  is never generated. A summary compressed a per-site fact into a universal.
- **Unrecomputable citation** — O9: claims whose evidence was a run never
  committed. AC5 forbids these but nothing flags them at writing time.

Why this rules the options in and out:

- **(a) is false for AC2.** A state satisfying AC2 exactly exists and was
  nearly reached: the script docstring already satisfies it. Only the ledger
  header and the Decisions entry overshoot, each by one word-count. See Q2.
- **(a) is partially true for AC5** — as written it quantifies over an
  append-only, growing surface including pre-re-cut history it may not edit,
  and it demands reproduction of figures (mutation red counts) whose cited
  command (`--self-test` on the *unmutated* tree) cannot reproduce them even
  in principle. The implement gate privately re-scoped it ("records written
  from the re-cut forward", work log 2026-08-01) but the criterion text does
  not carry that scoping, so the pass-4 gate read it broadly and it failed.
  A criterion whose real scope lives in a work-log line, not in its own text,
  will fail on any strict reading.
- **(b) is the dominant factor.** All four passes were CI-green and
  `cairn_validate`-green throughout; the review section itself says so
  ("nothing mechanical has ever caught this class"). The repo's own pattern —
  four `data-raw` checkers wired into `lint.yaml` — exists precisely because
  human gate-reading does not hold claims to artifacts at this density, and
  this milestone's checker is the only one of the five *not* wired in
  (verified: `lint.yaml` runs `check-reference-observations.py`,
  `enumerate-generalizing-claims.py`, `check-mpl-doc-claims.py`; not
  `enumerate-ci-method-remedies.py`).
- **(c) is real but derivative.** The milestone file is 678 lines carrying
  hundreds of discrete factual claims. At any plausible per-claim authoring
  error rate — and four passes of data suggest roughly 1–3% for figures
  transcribed into prose — several errors per pass is the *expected value*,
  not bad luck. But claim density is a choice: it is high because the
  tracking culture rewards rich narrative work logs while the criteria demand
  machine-grade precision from every sentence of them. The mismatch between
  those two pressures, with no mechanical bridge, is the structural answer.
  Reducing the density (fewer prose figures, more artifact citations) and
  adding the bridge (a claims checker) attack the same root from both ends.

**Summary judgment:** the recurrence is over-determined — (b) plus the
transcription failure mode explains the count/figure findings; the missing
re-cut rule explains O2/O11; AC5's unscoped text explains why even a careful
pass would have failed it. No single fifth pass of "be more careful" fixes
any of these, which is what four passes demonstrated.

## 2. Are AC2 and AC5 achievable as written?

**AC2 — achievable as written, in a single pass.** The satisfying state: every
durable record that claims probe-demonstrated coverage claims it for exactly
the shapes that have probes (the six of `_limit_shapes()` plus the five of
`_unreported_splices()`), and states the file-scope limit as a limit *without*
claiming a probe — which is precisely what the script docstring already does
("Scope is a limit of the same kind", L56-57, no probe claim). The ledger
header and the milestone `## Decisions` entry need a one-clause edit each (the
header's "Each of those shapes" → "Each of the six shapes"; the entry's
seventh-inclusive "Each shape is CONSTRUCTED" likewise), or a seventh probe.
A seventh probe is also cheap and honest: assert in `--self-test` that
`glob.glob(R_GLOB)` excludes a constructed path outside `R/ci-*.R` while
`sites_in()` on that file's lines *would* match — demonstrating the limit is
the glob, not the predicate. Either route closes O1 in one pass.

But AC2 as written has a fragility the pass-4 failure exposed: it is satisfied
or violated by the *agreement of three prose copies with one code list*, and
nothing holds them together. The achievable-and-durable form adds the
mechanical tie. Replacement (binding, see BC1): the records state the limits
*by count and label matching the probe list*, and `--self-test` asserts that
parity — so a limit added to the code without its record, or a record claim
without its probe, reds the same gate everything else runs.

**AC5 — not achievable as written.** What would satisfy it literally: every
factual claim in the milestone's records — including four passes of
append-only history written before the criterion existed, and claims about
uncommitted prior runs — carries a command reproducing it. Three independent
impossibilities: (i) IP4 forbids retrofitting commands into historical lines;
(ii) O9's class ("identical to the pre-confirmation run") is unrecomputable
in principle because the referent was never committed — no command can exist;
(iii) mutation red-counts are properties of a *mutation*, not of the tree, so
the only command that reproduces "reds N" is a committed mutation script,
which the criterion does not ask for and the work log does not have. An
author in a single pass cannot reach the satisfying state because it does not
exist for the surface the criterion governs.

Replacement capturing the intent as an achievable binding criterion (BC2/BC3
below, in one sentence): *the load-bearing figures live in a committed claims
ledger of (claim, command, expected output) rows checked mechanically; records
written from the re-cut forward state no figure except by citing a ledger row
or quoting a committed artifact named inline; claims about uncommitted runs
are not made.* This is checkable in one pass, bounded (the ledger is a closed
enumerated set, not "every claim"), and it converts the criterion from
"prose is accurate" (unbounded, human-audited) to "prose defers to artifacts"
(bounded, machine-audited).

## 3. Should this be mechanically enforced, and can it be?

**Yes, and mostly cheaply — but scoped to what a checker can actually decide.**

Feasible and worth the cost:

1. **Wire the existing checker into CI.** `enumerate-ci-method-remedies.py
   --check` and `--self-test` belong in `lint.yaml`'s check-references job
   beside the other three. This is a two-line workflow edit, it is the repo's
   established pattern, and its absence is itself an overclaim (the docstring's
   "cannot reach a release without someone classifying it", O4 — see Q7). No
   argument against exists.
2. **A claims checker in the `check-mpl-doc-claims.py` idiom.** A committed
   TSV — say `data-raw/record-claims.tsv` — with columns (id, stated figure or
   string, command, expected-output regex). The checker runs each command
   (cheap ones only: `awk`/`grep` over committed TSVs, the enumerator, `git
   diff --name-only`) and fails on a mismatch, with a self-test probing that a
   wrong expected value reds and that an id cited in the milestone file but
   absent from the ledger reds. Milestone records then *cite ids* (or quote
   the artifact) instead of free-standing figures. Every figure among
   O5/O10/O14/O1/O2 either becomes checkable this way or — the equally
   valuable outcome — turns out to be uncheckable and is therefore not written.
   Estimated cost: one sitting; it is the fifth instance of an established
   pattern, and this brief's own verification section is effectively its row
   set.

What the checker must **not** attempt:

- **Free-prose claim extraction.** Parsing the work log to *find* claims is
  NLP, will false-negative exactly the novel phrasings that matter, and would
  reproduce the failure mode (a gate believed broader than it is). Claims are
  checked because they are *registered*, never because they were detected.
  The residue — an author writing an unregistered figure — is handled by the
  authoring rule in BC2, enforced at the gate as a *narrow, decidable* check
  ("does this record line state a figure without a ledger id or an inline
  artifact quote?"), not by the script.
- **History.** Pre-re-cut lines, superseded entries, and the `## Review`
  sections record what was believed at a time; they may be false of the tree
  by design. The checker governs live, post-re-cut, registered claims only.
- **Expensive recomputation.** Never re-run the 25-minute sweep in CI; check
  the committed TSV's internal consistency (row counts, per-site verdicts)
  with `awk` instead. Never require mutation red-counts to be reproduced in
  CI; a mutation claim is legal only if the mutation is itself a committed
  probe (which `--self-test` already is for the ones that matter).

What replaces the checker where it cannot reach: the re-cut supersession rule
(Q4) for history, and claim-density reduction (write the figure once, in the
artifact; let prose point).

## 4. How should a re-cut handle history its new scope contradicts?

**Append a dated supersession note beside every live record the re-cut
falsifies, in the same commit as the re-cut — and scope record-governing
criteria to unsuperseded statements.** No history is edited; this is the
cairn idiom the work log already uses (its CORRECTION lines) applied to the
one section the re-cut missed.

Concretely for M100: the `## Decisions` section gains one dated entry stating
that (i) the "promoted to `cairn/DECISIONS.md`" clause describes a state T1
reverted — `grep -c 'D-020' cairn/DECISIONS.md` = 0 on this branch, and D-020
never reached `main` — and D-020 is re-authored by M101; (ii) the two rule
statements above it ("static remedy text may name...", "these guards
REPORT...") are M101's rules, bind nothing on this branch, and are recorded
here as history of how the re-cut was reached. That resolves O2 and O11
without touching a dated line.

The generalization has two halves, both worth adopting as tracking practice:

- **Re-cut sweep duty:** a re-cut that reverts files or moves scope MUST
  enumerate the live record surfaces (milestone `## Decisions`, ROADMAP rows,
  file headers of surviving artifacts) and append a supersession note to each
  entry the reversion falsifies, in the re-cut commit. M100's re-cut did this
  for the work log (the CORRECTION line) and the ROADMAP (both rows were
  corrected) but not for `## Decisions` — the gap is the omission of one
  surface from the sweep, not a defect in the append-only rule.
- **Criteria bind live assertions:** any criterion quantifying over "this
  milestone's records" (AC4's "states no rule", AC5's "every factual claim")
  is evaluated over the latest dated statement on each topic; a statement
  followed by an appended supersession note is history, not an assertion.
  Without this scoping, AC4 is *unsatisfiable* on any re-cut branch whose
  history ever stated a rule — the conflict question 5 asks about.

This does not require editing anything history-protected and does not weaken
IP4: supersession is already how `cairn/DECISIONS.md` amendments work
(D-020 Amendment 1 was exactly this move, before both were reverted).

## 5. Is the criteria set jointly satisfiable?

As written, **no** — two pairs conflict, both resolvable by rescoping rather
than by dropping intent:

- **AC4 vs the append-only `## Decisions` section (via O11).** AC4's "states
  no rule" is a property of the whole milestone file; the file carries dated
  entries stating two rules; IP4 forbids removing them. Unsatisfiable as
  written. **AC4 gives way** — its git-diff half stands verbatim; its
  "states no rule" clause is rescoped to *live* (unsuperseded) statements per
  Q4. The intent (no rule lands on `main` while the code breaks it) is fully
  preserved: a rule statement carrying an appended "deferred to M101, binds
  nothing here" note does not put a live rule on `main`.
- **AC5 vs the append-only work log.** AC5's universal quantifier reaches
  lines IP4 freezes and claims no command can reproduce. Unsatisfiable as
  written. **AC5 gives way** — replaced by the ledger form (Q2/BC2), scoped
  post-re-cut and to registered claims.
- **AC2 vs AC4 — no genuine conflict, but state the boundary.** Stating the
  predicate's limits (AC2) is describing an artifact; "stating a rule" (AC4)
  is binding future conduct. The `## Decisions` limits entry currently mixes
  the two ("An honest narrow gate is citable..." is description; D-020's
  sentence above it is a rule). One sentence in AC4 defining "rule" as a
  statement purporting to bind conduct beyond this milestone prevents a
  fifth-pass dispute over the boundary.
- AC1, AC3, AC6 are jointly consistent with everything above and with each
  other; AC3's "several geometries" is literally met (four), and O6 is
  correctly an overstatement in the *header*, not an AC3 failure.

## 6. What should happen to M100 now?

**Recommendation: a scoped fifth fix pass, under the revised criteria in
`## Binding criteria` below — records and wiring only, tooling and
measurement frozen.**

Reasoning:

- **The expensive, hard part is done and independently verified.** The
  enumerator self-tests green (re-run here), the sweep byte-reproduced at the
  pass-4 gate, and this review recomputed the row census and both ROADMAP
  commands from the committed TSV with full agreement. Dropping or
  re-planning the measurement would discard verified evidence to punish its
  description — and the brief's own constraint says the measurement stands.
- **Every finding is a record edit or a workflow line.** O1, O5, O10, O14:
  appended CORRECTION lines with recomputed figures (the fix pattern the work
  log already uses). O2, O11: one appended supersession entry (Q4). O6: a
  header sentence (code comment, not history — freely editable). O9: an
  appended line stating what is and is not recomputable. Plus the two-line CI
  wiring and the claims ledger. This is one sitting of bounded, enumerable
  work — nothing like the open-ended "make the prose true" instruction that
  failed four times.
- **The alternatives are strictly worse.** *Parking* leaves M101 blocked on a
  branch whose evidence it needs, rotting against `main`. *Splitting evidence
  from records* does not address the cause — the records exist in either
  piece, and cairn requires the milestone file to travel with its branch.
  *Dropping* violates the measurement-stands constraint and re-spends ~25
  minutes of sweep plus four passes of review for no new information.
- **What is different about pass five** — the honest question, since passes
  2–4 each also believed they were different: (i) the failing criteria are
  replaced by achievable ones whose scope is in their own text; (ii) the
  dominant failure mode (figure transcription) is closed mechanically, not by
  vigilance — the figures move into a checker-verified ledger and CI runs it;
  (iii) the history conflict is dissolved by rule, not re-litigated; and
  (iv) the pass's surface is a closed list (the eight findings + Q7's
  additions + the BCs), not "all records".

**Falsifiers for this recommendation:** if the fifth pass, with the claims
checker green and the BCs met, still fails its gate on a *new* overclaim in a
governed (live, registered) claim, the authoring process itself is the defect
beyond what structure can absorb — then park M100 with an evidence-only merge
(the five `data-raw` files plus a minimal factual stub) and let M101 re-derive
its inputs from the TSVs directly. Likewise if building the claims ledger
turns out to require more than roughly a day, the cost-benefit judgment in Q3
was wrong and only the CI wiring (item 1) should ship with hand-fixed records.

## 7. Beyond the eight findings — further overclaims in the shipped tooling

Examined: the enumerator docstring, the ledger header, the sweep header, both
ROADMAP candidate rows in the diff. Four further claims the artifacts do not
support, plus two confirmations:

- **N1 (elevates logged O4, and it deserves elevation).** Docstring L27-28:
  "That is the completeness gate: a new `ci_method`-naming abort cannot reach
  a release without someone classifying it." Nothing runs `--check`
  automatically: `lint.yaml` runs three other `data-raw` checkers and not this
  one (verified by grep), and no release step names it. "Cannot reach a
  release" asserts an enforcement the toolchain lacks — the exact AC2 shape,
  in the docstring the pass-4 review called "careful". Fix by wiring (BC6),
  which makes the sentence true, rather than by weakening it.
- **N2 (elevates logged O3).** Docstring L31-33: "the milestone that rewrites
  these remedies is required to leave every leading line unchanged."
  `cairn/milestones/M101-degeneracy-message-claims.md` imposes no such
  requirement — no criterion or task mentions leading lines (verified by
  grep), and its T4 message edits could change one, silently re-keying the
  ledger. Either M101 gains the requirement or the docstring drops
  "is required to" for what is actually true (a changed leading line re-keys
  the site and `--check` reds until the ledger row is renewed — which is the
  real, mechanical protection).
- **N3 (extends O6).** The sweep header's whole-class claim fails for the
  *bootstrap* guard too, not only the classical one. Its trigger class is "too
  few refits converged", which the ledger row itself says "is not entailed by
  any single data fact" — yet the grid feeds it `gen_mse0` alone. Any header
  correction under O6 should state the generated-vs-ungenerated disjuncts for
  both sites, not one.
- **N4 (elevates logged O8 one notch, same shape as AC2).** `check()`'s
  docstring: "Three failure modes, each probed in `--self-test`." `check()`
  has four failure routes — the splice report also returns 1 — and the splice
  route is *not* probed via `_check_probes()` (the probes pass `spliced=[]`).
  The splice behaviour is probed elsewhere (`_unreported_splices` + control),
  but "each probed" over "three" miscounts the routes and misattributes the
  probe. One-line docstring fix.
- **Confirmations.** Both ROADMAP recompute commands reproduce against the
  committed TSV (burch: four rows `raw error unclassed`; `gen_se_zero`: four
  methods usable, `npbootstrap` classed abort). The `gen_se_zero` row's
  additional clause "all nine resample-guard datasets do likewise" is TRUE
  (recomputed: 9 of 9 `montecarlo` rows `usable interval`) but carries no
  reproducing command of its own — its cited `awk` covers only `gen_se_zero`.
  An AC5-shape gap in an otherwise sound row; add the second command (BC10).
- **One half-exoneration worth recording.** O5's work-log line is half right:
  "narrowing the file glob to `R/ci-n*.R` reds 5" reproduces exactly (5
  failures, naming the two dropped swept guards and three fence guards). Only
  the "reds 7" clause fails (three plausible `BULLET_RE` mutations red 8, 8,
  8 here). The correction should preserve the true half.

## Beyond the brief

- **The self-test's probe design is genuinely good and is the thing to build
  on.** The "a limit closed reds its own probe" inversion (docstring L797-798)
  is the only mechanism in this milestone that has *never* produced an
  overclaim, because it makes the record's claim and the code's behaviour fail
  together. BC1 extends that mechanism to the record *count*; the claims
  ledger extends it to figures. The pattern deserves a line in the tracking
  rulebook: a durable record may describe a gate only in terms the gate's own
  self-test asserts.
- **`gen_se_zero()` ignores its `n_s`, `n_r`, `seed` parameters** (returns a
  hardcoded 3×2 frame). The grid happens to call it with matching 3L/2L so
  every committed row is truthful (logged as O15, 52). Harmless today; a
  future grid edit would silently record wrong geometry columns. A
  `stopifnot(n_s == 3L, n_r == 2L)` makes it honest at zero cost.
- **The claims ledger has a natural first row set:** this review's own
  verification commands (row census, unreached split, per-site verdicts, the
  two ROADMAP awks, checker inventory, `grep -c 'D-020'`, AC4's
  `git diff --name-only`) all ran clean and are exactly the commands BC2's
  ledger should commit.

## Recommendations

1. **Apply** — wire `enumerate-ci-method-remedies.py --check` and
   `--self-test` into `lint.yaml`'s check-references job (Q3 item 1; makes N1
   true instead of weaker).
2. **Apply** — replace AC2 and AC5 with BC1 and BC2/BC3 below; rescope AC4 per
   BC5. The originals are retired as superseded criteria, not edited away.
3. **Apply** — the re-cut supersession sweep (Q4): one appended dated entry in
   `## Decisions` resolving O2 and O11; adopt the general rule for future
   re-cuts in the tracking rulebook.
4. **Apply** — the committed claims ledger + checker (BC2), seeded with this
   review's verified command set; appended CORRECTION lines for O5, O10, O14,
   O9 citing ledger rows.
5. **Apply** — record fixes for O1 (six-not-seven, or the seventh probe),
   O6/N3 (header disjunct statement), N2 and N4 (docstring), BC10 (ROADMAP
   second command).
6. **Apply** — proceed with the scoped fifth fix pass per Q6, surface limited
   to items 1–5 plus the BCs; tooling and the committed sweep frozen.
7. **Consider** — the `gen_se_zero()` parameter guard (Beyond the brief); and
   promoting the "records describe gates only in self-test terms" pattern into
   the tracking rulebook, since it generalizes past this package.
8. **Consider** — for M101: mirror the leading-line requirement the enumerator
   docstring assumes (N2) as an explicit M101 criterion, or accept re-keying
   and require `--emit` + ledger renewal in M101's T4.
9. **Reject — prose claim-extraction in the checker** (any NLP over the work
   log): it rebuilds the "gate believed broader than it is" failure inside the
   tool meant to end it. Registration, not detection.
10. **Reject — dropping or re-planning the measurement**: the sweep is
    verified, byte-reproduced, and constraint-protected; every defect found in
    four passes lives in prose, not in a TSV.
11. **Reject — a sweep re-run to close O6/N3**: the finding is that the
    *header* overclaims coverage, not that the covered cells are wrong. The
    missing disjuncts (classical MSA-overflow, bootstrap non-MSE0 triggers)
    are M101's fixture territory (its AC3 already names the overflow corner);
    stating the gap truthfully is M100's whole job. This is the one place a
    re-run could be argued unavoidable under question 1; it is not — no
    conclusion M100 records depends on the ungenerated disjuncts once the
    header states them as ungenerated.

## Binding criteria

- BC1: The ledger header, the enumerator docstring, and the milestone's live
  limits record each state exactly the probe-demonstrated limit set: six
  predicate shapes (L1–L6) and five unreported splice shapes, with the
  `R/ci-*.R` file scope stated as a limit explicitly not demonstrated by a
  probe — or a seventh self-test probe demonstrating the file-scope limit
  exists. `--self-test` contains an assertion tying the stated count to
  `len(_limit_shapes())`, so a divergence between record and probe list exits
  non-zero. Tolerance: exact counts.
- BC2: A committed claims ledger lists every figure the post-re-cut records
  state about the sweep, the enumeration, the ledger, or the diff — at
  minimum: 210 rows; 130 reached rows; 30 point-fit-failed and 50
  reducer-returned-interval unreached rows (units: rows; as cells 6 and 10);
  per-site verdicts 0/6, 0/3, 1/8 (`montecarlo`) with `bootstrap` 5/8, and
  9/9; 9 sites = 4 sweep + 5 fence; the `data-raw` checker inventory by name —
  each row carrying a command over committed artifacts whose output contains
  the stated figure; a committed checker runs every row, exits non-zero on any
  mismatch, and its self-test reds on a deliberately wrong expected value.
  Tolerance: exact figures, no projection.
- BC3: Post-re-cut records state no claim whose only evidence is an
  uncommitted run: the two O9 sentences are each superseded by an appended
  line stating what is recomputable from committed artifacts, and mutation
  red-counts appear only where the mutation is a committed self-test probe or
  the claim names the exact mutation beside a command that reproduces the
  count. Tolerance: zero unregistered figures in post-re-cut record lines
  outside verbatim quotes of named committed artifacts.
- BC4: The milestone `## Decisions` section carries an appended, dated
  supersession entry stating that D-020 and its amendment exist nowhere in
  `cairn/DECISIONS.md` on this branch (`grep -c 'D-020' cairn/DECISIONS.md`
  = 0), never reached `main`, and are re-authored by M101; and that the two
  rule statements in prior entries bind nothing on this branch. No existing
  line in that section is modified: `git diff` for the fix commit shows only
  additions within it.
- BC5: AC4 is evaluated as: `git diff main..HEAD --name-only` lists no path
  under `R/` and neither `NEWS.md` nor `cairn/DECISIONS.md`; and no *live*
  record statement — one not followed by a dated supersession note — purports
  to bind conduct beyond this milestone. With BC4's entry appended, both
  clauses hold.
- BC6: `.github/workflows/lint.yaml` runs
  `python3 data-raw/enumerate-ci-method-remedies.py --check`,
  `... --self-test`, and BC2's claims checker; the docstring's release-gate
  sentence is true of the wired toolchain at merge.
- BC7: The sweep script header states, per swept site, which disjuncts of the
  trigger condition the grid generates and which it does not — at minimum
  that the classical guard's `!is.finite(f)` disjunct (MSA overflow, MSE
  finite non-zero) and bootstrap refit-failure triggers other than
  MSE=0-degenerate data are not generated — and no header sentence claims
  coverage of a whole trigger class. The committed sweep TSV is unchanged:
  `git diff <fix-base>..HEAD -- data-raw/abort-remedy-sweep.tsv` is empty.
- BC8: Each work-log figure a review proved wrong (the "reds 7" clause; "all
  five `data-raw` checkers"; the 80/30/50 unit slips) is superseded by an
  appended CORRECTION line citing a BC2 ledger row or a committed probe; the
  reproducing half of O5's line ("narrowing the glob reds 5") is preserved as
  stated. Original lines unedited.
- BC9: The enumerator docstring makes no requirement claim about M101 that
  M101's milestone file does not contain: either M101 gains the
  leading-line-stability criterion or the docstring's "is required to" clause
  is replaced by the mechanical fact (a changed leading line re-keys the site
  and `--check` fails until the ledger row is renewed). `check()`'s docstring
  states four failure routes and attributes the splice route's probes to
  `_unreported_splices()`.
- BC10: The ROADMAP runtime-hint row's "all nine resample-guard datasets"
  clause carries its own reproducing command (e.g.
  `awk -F'\t' '$1=="R/ci-npbootstrap.R:01b75d1a61" && $8=="TRUE" && $11=="montecarlo" {print $12}' data-raw/abort-remedy-sweep.tsv`
  yielding nine `usable interval` lines). Tolerance: exact.
