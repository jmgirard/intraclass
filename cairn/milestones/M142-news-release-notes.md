# M142: NEWS.md's 0.1.0 entry reads as first-release notes, not a development log

- **Status:** planned
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP8
- **Branch/PR:** —

## Goal

Rewrite the `# intraclass 0.1.0` entry of `NEWS.md` as first-release notes —
what the package does for someone meeting it — instead of the development
narrative it is now: 463 lines, 36,201 bytes, 47 bullets of which 25 run past
six lines and one runs 34; 172 sentences, 45 of them over 35 words, the longest
271 (all measured 2026-08-27 at `a59ea1c`, the bullet figures by AC1's own
`awk` rule).

## Scope

Surface tier: **user-facing** — `NEWS.md` ships in the tarball, is what
`news(package = "intraclass")` prints, and renders as the pkgdown changelog.
D-029 places a user-facing documentation deliverable outside D-021's
records-apparatus door.

**In:** the `# intraclass 0.1.0` entry; the one sentence of
`cairn/doctrine/prose-style.md` that lists the surfaces it owns, so it names
`NEWS.md`; whatever re-keying, deletion or addition the moved text forces on the
`NEWS.md` rows of `data-raw/mpl-doc-claims.tsv` and on the pins in
`tests/testthat/test-doc-skew-caveat.R`.

**Out:** a mechanical check that no claim is invented or widened — a two-sided
sentence diff over both revisions — descoped at the user's decision 2026-08-27
after three audit passes: its scaffolding was costing more than the rewrite it
guards. R6 protection here is the reviewer read-through at
`/milestone-review`, which `cairn/doctrine/prose-style.md` already treats as R6's
home, plus the two shipped guards that pin the specific claims that matter
(`check-mpl-doc-claims.py` and `test-doc-skew-caveat.R`, both gated by AC3
below) → absorbed into the standing "Two prose-apparatus deferrals" candidate
row as its (c). Extending `check-mpl-doc-claims.py`'s `news_scope()` past its one
anchor bullet → the standing "Harden `data-raw/check-mpl-doc-claims.py`"
candidate row, which D-021 still bars and D-029 explicitly declines to reopen
for apparatus dressed as documentation. Any change to what the package computes,
or to `?icc`, the vignettes or the README → unchanged here; a false claim found
in NEWS while cutting is corrected in place under D-029, never widened into new
scope. A second `#` version entry → none exists; 0.1.0 is unreleased.

## Acceptance criteria

- [ ] AC1 — `NEWS.md` holds exactly one `#` heading (`grep -c '^# '` returns 1)
      and is at most 18,100 bytes by `wc -c` (merge base 36,201). No bullet
      spans more than six lines, counted by the `awk` program committed at
      `data-raw/m142-bullet-lines.awk` in the same commit as this plan, whose
      rule is: a bullet is a line matching `^\* ` plus every following line
      until the next `^\* `, `^#`, or blank line. One bullet is exempt and named
      here: the `news_scope()` anchor bullet, opening `* The \`ci_method =
      "mpl"\` documentation`, which AC4 requires to hold its three quoted ledger
      claims inside a single bullet; it spans 11 lines at the merge base and
      spans no more than 11 on the branch. The exemption is this one bullet, not
      a class.
- [ ] AC2 — `python3 data-raw/prose-profile.py NEWS.md` reports 0 in its `dash`
      column (R1). Every sentence it counts over 35 words (R2) carries a clause
      that a shipped test pins verbatim, the carrier set derived by running
      those pins' own sweeps over the new entry rather than hand-listed (GP8) —
      so a long sentence carrying no pinned clause fails the criterion, and no
      sentence is exempted by hand. The relation is containment, not equality:
      a pinned clause short enough to sit in a sentence under 35 words SHOULD
      be split down to one, and doing so must not fail the criterion.
      `cairn/doctrine/prose-style.md`'s scope sentence names `NEWS.md`.
- [ ] AC3 — the guards keyed on NEWS text pass, run at review:
      `python3 data-raw/check-mpl-doc-claims.py` and the same script with
      `--self-test` both exit 0, its `news_scope()` anchor bullet still
      locatable, and each of the four `data-raw/mpl-doc-claims.tsv` rows whose
      file column is `NEWS.md` — the three quoted rows `87f0dfc36b75`,
      `f00273a96e77`, `c6eb48429ddb` and the `absent` refusal row whose regex
      must match nowhere in the news scope — is re-keyed, deleted or added in
      the same commit as the text change that required it (M130 lesson).
      `Rscript -e 'devtools::test(filter = "doc-skew-caveat")'` reports
      `FAIL 0`.
- [ ] AC4 — `git diff <merge-base>..HEAD --name-only` lists only `NEWS.md`,
      `data-raw/mpl-doc-claims.tsv`, `data-raw/m142-bullet-lines.awk`,
      `tests/testthat/test-doc-skew-caveat.R`,
      `cairn/doctrine/prose-style.md`, and paths under `cairn/`. Any hunk in the
      test file is a pin re-key and nothing else.
- [ ] AC5 — `Rscript -e 'devtools::test()'` reports `FAIL 0` and no warning whose
      rendered message text is absent from the set the same `devtools::test()`
      invocation reports at this milestone's merge-base, both runs made in the
      review session; `Rscript -e 'devtools::check()'` reports 0 errors and 0
      warnings on `R CMD check`'s own `Status:` line, any NOTE justified in the
      Review section; `Rscript -e 'pkgdown::build_news()'` renders the changelog
      without error.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T3, T4
- AC3 → T5
- AC4 → T5, T6
- AC5 → T6

## Tasks

- [ ] T1 — Measure the merge base and record it: `wc -c`, the ruler's four
      columns, the per-bullet counts from `data-raw/m142-bullet-lines.awk`
      (committed with this plan, already reproducing 47 bullets / 25 over six /
      an 11-line anchor bullet), the four `NEWS.md` ledger rows with their
      quoted text, and the runs the `width`/`residual` pins locate in NEWS
      today. Nothing predicted from reading.
- [ ] T2 — Cut section by section by DELETION and CROSS-REFERENCE — point at
      `?icc` or the vignette that already carries the detail — never by
      composing a shorter claim from a reading of the old one. No criterion
      gates this after the descope, so it is the read-through at review that
      catches a breach: M133, M136 and M123 each returned repeatedly on composed
      prose, and M137 passed in one round by deriving instead. Where a
      first-release orienting sentence is genuinely wanted, write it — and say
      so in the work log, so the reviewer reads it as new rather than hunting
      its source.
- [ ] T3 — Re-measure with the ruler and the `awk` rule after the LAST content
      commit, never at the task that wrote the prose (M135 lesson).
- [ ] T4 — Add `NEWS.md` to `cairn/doctrine/prose-style.md`'s scope sentence;
      re-check the module against its stated 120-line / 8,000-byte budget
      (118 / 6,941 at the merge base). Record each R2 carrier with its word
      count and the pinned clause it carries, as that module's exemption asks.
- [ ] T5 — Re-key the ledger rows and any pin the moved text broke, in the same
      commit as the move; run every `data-raw/` checker with `--self-test`.
- [ ] T6 — Gate: full suite, merge-base suite in a temporary worktree,
      `devtools::check()`, `pkgdown::build_news()`, `devtools::document()`.

## Work log

- 2026-08-27: created by /milestone-plan.
- 2026-08-27: plan-gate criteria audit ran in FULL mode (declared surface tier user-facing), pass 1 over the drafted wording, [O] fresh reader, not the author. Thirteen findings. The load-bearing one: no criterion bound the Goal — a mechanical truncation preserving the headings, the pinned sentences and the ledger quotes satisfied all five drafted criteria while reading exactly as before. Also returned: an unfilled ratio placeholder; a heading clause forbidding the section merges condensing needs; a false claim that two NEWS sentences are pinned `fixed = TRUE` byte-identical (they are located by a keyword-proximity neighbourhood sweep, with short template clauses matched verbatim inside the run — so the long sentences CAN be split); three `mpl-doc-claims.tsv` NEWS rows where there are four, the fourth an `absent` refusal row whose regex must match nowhere; ledger handling covering only re-keying, not the orphaned-row and uncovered-claim failures that deletion actually triggers; a permitted-paths list that deadlocked against the guard criterion; four criteria binding recording acts rather than the deliverable; hunk-level triage too coarse to catch a composed section rewrite; and `prose-style.md` not naming NEWS in its own scope. All disposed at the gate: nine fixed in the rewritten criteria, four routed to the question round.
- 2026-08-27: question gate, four questions. User chose: cut to at most half the merge-base bytes with a six-line bullet cap; the R2 35-word bar rather than a recorded-not-gated figure; bringing `NEWS.md` under `cairn/doctrine/prose-style.md`'s scope; and NO release window — this is ordinary documentation work, not release preparation, so the release-shaped tripwire does not fire and D-050 is not engaged.
- 2026-08-27: the 35-word bar and the doctrine-scope answer compose: `prose-style.md` already states an exemption for a clause a shipped test pins verbatim that admits no sentence break. Measured this session with the ruler — `residual_template()`'s clause needs a 72-word carrier sentence, so R2 cannot reach zero and AC2 says so rather than promising it. This corrects a pre-gate statement that the pinned clauses were short enough for a flat 35-word bar; the width clauses are, the residual one is not.
- 2026-08-27: Goal's bullet figures corrected from 46/24 to 47/25 — the first count used a looser `awk` than the rule AC1 names; the Goal now carries the figures AC1's own program produces.
- 2026-08-27: plan gate chose condensation by DELETION and CROSS-REFERENCE over rewriting each bullet into a shorter summary, because this repo's prose milestones fail by composing claims from a reading (M133 reverted its deliverable, M136 took four rounds, M123 four attempts) and the one that passed in a single round, M137, derived instead; falsified by an AC3 triage table in which the `pointer` and `narrower` verdicts cannot carry the required cut, forcing `wider` verdicts to meet AC1's byte ceiling.
- 2026-08-27: criteria audit pass 2 ran in FULL mode over the rewritten six criteria, [O] fresh reader, not the author. Fourteen findings; the four load-bearing ones verified by command before disposal. (a) Still no criterion bound the Goal — deleting half the entry and stripping the dashes passed all six. (b) AC3 triaged only NEW sentences, so widening by DELETING a bounding qualifier was invisible. (c) AC3's closed verdict set left a genuine first-release orienting sentence no legal verdict, so the criteria forbade the prose the Goal asks for. (d) AC3's "verbatim" ran over `normalize()`, which rewrites every code span to the word `code`: measured this session, `` `glance()$raters` gives the rater treatment the fit used`` and the same sentence naming `` `glance()$type` `` normalize IDENTICALLY, so a swapped identifier compared as unchanged. Also: AC1's six-line bullet cap collided with the 11-line `news_scope()` anchor bullet that AC4 requires to keep three quoted claims in one bullet (measured 11 lines at `NEWS.md:182`); the "72 words" figure in AC2 was unreproducible (the clause is 58 words standing alone; 72 was a carrier with a lead-in) and hand-pinned against GP8; the heading rule forced release notes to reuse the development log's section names; the permitted-paths list left a derivation script no legal home; five criteria still bound recording acts; and `prose-profile.py` exposes no file-to-sentence entry point.
- 2026-08-27: question gate round 2, two questions — the design was the user's call, not a wording fix. User chose to REPAIR the claim check rather than retire it to a read-through (raw-text comparison so identifiers survive, two-sided so a deleted qualifier surfaces, plus a justified `new` verdict so release-notes prose is permitted), and to EXEMPT the one anchor bullet from the six-line cap rather than raise the cap or compress that bullet.
- 2026-08-27: plan gate chose the repaired mechanical claim check over retiring R6 to a reviewer read-through, at the user's explicit selection and against `cairn/doctrine/prose-style.md`'s own treatment of R6 as uncounted judgment; falsified by the milestone returning on the diff script's edge cases rather than on the prose, which is how M134 spent four rounds. The Goal itself is NOT bound by any criterion and is not pretended to be: the criteria prevent the degenerate outcomes (blind truncation, widened or invented claim, dev-log sentence length), and whether the result reads as first-release notes is the maintainer's judgment at the merge gate.
- 2026-08-27: three measurements taken this session rather than asserted. `data-raw/m142-bullet-lines.awk`, committed with this plan, reproduces 47 bullets / 25 over six lines / an 11-line anchor bullet, so the Goal's figures and AC1's procedure agree. Dropping ONLY the code-span step from the ruler's `normalize()` leaves segmentation unchanged on the current NEWS.md — 172 sentences either way — so AC3's self-consistency assertion is satisfiable and its script buildable. The residual clause is 58 words standing alone under the ruler, so the wrong 72-word figure is gone from AC2 entirely rather than corrected in place.
- 2026-08-27: AC2 defect found by the author, not the audit: it required the over-35 set to EQUAL the pinned-carrier set, which fails the milestone for doing the right thing — splitting a width clause down under 35 words removes it from the over-35 set while it stays a carrier. Reworded to containment, with the intent stated so review cannot read it the other way.
- 2026-08-27: DESCOPED at the user's explicit decision — "descope it, gate size and sentence length only". AC3, the two-sided sentence diff against an invented or widened claim, is removed as a criterion along with the two tasks that built it; the criteria set goes from six to five and the milestone gates size, bullet shape, sentence length and dashes, plus the two shipped guards and the standard gate. The descoped check is absorbed into the standing "Three prose-apparatus deferrals" candidate row as its (c), not dropped. Rationale recorded rather than inferred: three audit passes over three criteria sets, each killing the previous attempt to mechanize "reads as first-release notes" — the scaffolding was costing more than the rewrite it guarded.
- 2026-08-27: what the descope gives up, stated plainly so review does not read the narrowed set as covering it. Nothing now mechanically stops a claim being invented or widened in NEWS. R6 protection is: the reviewer read-through at `/milestone-review`, which `cairn/doctrine/prose-style.md` already names as R6's home (R6 is uncounted there by that module's own text); `check-mpl-doc-claims.py`, which settles every universal and negative claim in the MPL bullet against the committed coverage fixture; and `test-doc-skew-caveat.R`, which pins the width and residual statements. Claims outside those two guards' reach are covered by judgment alone. T2 carries the deletion-and-cross-reference discipline and asks that any deliberately new sentence be named in the work log so the reviewer reads it as new rather than hunting a source for it.
- 2026-08-27: criteria audit pass 3 was in flight when the descope landed and is superseded for the two criteria the descope removed; its findings on the surviving AC1/AC2 wording, whose text the descope did not change, are disposed in the next work-log line if it returns any. Plan is otherwise complete: remainder ledger and durable-record preview presented this turn.

## Decisions

## Review
