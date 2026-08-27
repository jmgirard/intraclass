# M142: NEWS.md's 0.1.0 entry reads as first-release notes, not a development log

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP8
- **Branch/PR:** `m142-news-release-notes` / https://github.com/jmgirard/intraclass/pull/153

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

This milestone commits one new `data-raw/` instrument, `m142-bullet-lines.awk`.
It is a ruler over the deliverable's own shape, not a guard over the repo's
records — the class D-029 warns against smuggling in as documentation — and it
asserts nothing; AC1 does. D-021 is not engaged by it.

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

- [x] AC1 — `NEWS.md` holds exactly one `#` heading (`grep -c '^# '` returns 1)
      and is at most 18,100 bytes by `wc -c` (merge base 36,201). No bullet
      exceeds 500 bytes, measured by `data-raw/m142-bullet-lines.awk`, whose
      rule is: a bullet is a line matching `^\* ` plus every following line
      until the next `^\* `, `^#`, or blank line, its size being those lines,
      each stripped of leading and trailing whitespace, joined with single
      spaces. The line-counting form of that program entered the tree at
      `32454c5`; the byte-printing form this criterion needs ships on this
      branch, and it is the branch's ruler that is run over BOTH revisions:
      `LC_ALL=C awk -f data-raw/m142-bullet-lines.awk NEWS.md` for the branch
      figure, and the same command over a
      `git show <merge-base>:NEWS.md > mb-news.md` copy for the merge-base
      figure. That program measures a strict superset of the rule above — it
      also counts `-` and `+` markers as bullets, and continues a bullet across
      a blank line — so a clean run establishes the rule as stated a fortiori;
      its header records why. The cap is BYTES, not lines, because a line cap is
      defeated by reflow alone; the measurement behind that is in the work log.
      At the merge base 25 bullets exceed 500 bytes, the same 25 that exceed six
      lines. One bullet is exempt and named here: the `news_scope()`
      anchor bullet, opening `* The \`ci_method = "mpl"\` documentation`, which
      AC3 requires to hold its three quoted ledger claims inside a single
      bullet; it is 808 bytes at the merge base and must be no larger than that
      on the branch. The exemption is this one bullet, not a class.
- [x] AC2 — `python3 data-raw/prose-profile.py NEWS.md` reports 0 in its `dash`
      column (R1). Every sentence it counts over 35 words (R2) carries a clause
      that a shipped test pins verbatim AND whose own word count exceeds 35 —
      the test `prose-style.md`'s exemption actually states, "a clause … that
      admits no sentence break". Bare containment is not enough: it would pass a
      200-word sentence that happens to contain an 11-word pinned template.
      Both word counts are derived by running those pins' own sweeps and
      measuring their templates, never hand-listed (GP8). Measured 2026-08-27,
      exactly one pinned clause qualifies — `residual_template()`'s, at 58
      words; the `flat`, `parity` and `subjects` templates are 32, 17 and 11
      words and so force no long carrier, and their carriers must come under 35.
      `cairn/doctrine/prose-style.md`'s scope sentence names `NEWS.md`.
- [x] AC3 — the guards keyed on NEWS text pass, run at review:
      `python3 data-raw/check-mpl-doc-claims.py` and the same script with
      `--self-test` both exit 0, its `news_scope()` anchor bullet still
      locatable, and each of the four `data-raw/mpl-doc-claims.tsv` rows whose
      file column is `NEWS.md` — the three quoted rows `87f0dfc36b75`,
      `f00273a96e77`, `c6eb48429ddb` and the `absent` refusal row whose regex
      must match nowhere in the news scope — is re-keyed, deleted or added in
      the same commit as the text change that required it (M130 lesson).
      `Rscript -e 'devtools::test(filter = "doc-skew-caveat")'` reports
      `FAIL 0`.
- [x] AC4 — `git diff <merge-base>..HEAD --name-only` lists only `NEWS.md`,
      `data-raw/mpl-doc-claims.tsv`, `data-raw/m142-bullet-lines.awk`,
      `tests/testthat/test-doc-skew-caveat.R`,
      `cairn/doctrine/prose-style.md`, and paths under `cairn/`. Any hunk in the
      test file is a pin re-key and nothing else.
- [x] AC5 — `Rscript -e 'devtools::test()'` reports `FAIL 0` and no warning whose
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

- [x] T1 — Measure the merge base and record it: `wc -c`, the ruler's four
      columns, the per-bullet counts from `data-raw/m142-bullet-lines.awk`
      (committed with this plan, already reproducing 47 bullets / 25 over six /
      an 11-line anchor bullet), the four `NEWS.md` ledger rows with their
      quoted text, and the runs the `width`/`residual` pins locate in NEWS
      today. Nothing predicted from reading.
- [x] T2 — Cut section by section by DELETION and CROSS-REFERENCE — point at
      `?icc` or the vignette that already carries the detail — never by
      composing a shorter claim from a reading of the old one. No criterion
      gates this after the descope, so it is the read-through at review that
      catches a breach: M133, M136 and M123 each returned repeatedly on composed
      prose, and M137 passed in one round by deriving instead. Where a
      first-release orienting sentence is genuinely wanted, write it — and say
      so in the work log, so the reviewer reads it as new rather than hunting
      its source.
- [x] T3 — Re-measure with the ruler and the `awk` rule after the LAST content
      commit, never at the task that wrote the prose (M135 lesson).
- [x] T4 — Add `NEWS.md` to `cairn/doctrine/prose-style.md`'s scope sentence;
      re-check the module against its stated 120-line / 8,000-byte budget
      (118 / 6,941 at the merge base). Record each R2 carrier with its word
      count and the pinned clause it carries, as that module's exemption asks.
- [x] T5 — Re-key the ledger rows and any pin the moved text broke, in the same
      commit as the move; run every `data-raw/` checker with `--self-test`.
- [x] T6 — Gate: full suite, merge-base suite in a temporary worktree,
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
- 2026-08-27: criteria audit pass 3 disposed. Eleven findings; six concerned criteria the descope removed and are moot. Four live, all verified by command before disposal. (1) AC1's six-line bullet cap was defeated by REFLOW alone — rewrapping every bullet onto one physical line takes 25-over-six to 0 without changing a word, since the `awk` counts newlines; the cap is now 500 BYTES per bullet, which selects the same 25 bullets at the merge base, with the exempt anchor bullet held at its measured 1,008 bytes. (2) AC2's containment let a 200-word sentence pass by containing an 11-word pinned template; an over-35 sentence must now carry a pinned clause whose OWN word count exceeds 35, which is what `prose-style.md`'s "admits no sentence break" actually tests. Measured: only `residual_template()` qualifies at 58 words, against `flat` 32, `parity` 17, `subjects` 11. (3) The Scope now prices the one new `data-raw/` instrument against D-029 rather than leaving it unargued. (4) Finding 6, that `m142-bullet-lines.awk` was untracked when AC1 called it committed, was already resolved — it entered the tree at `32454c5`, which AC1 now cites.
- 2026-08-27: SUPERSEDES this session's earlier work-log line reading "so the release-shaped tripwire does not fire and D-050 is not engaged". `D-050` is a cairn-plugin id, not one this repo defines (its `DECISIONS.md` ends at D-041), and D-020 Amendment 3 requires a plugin id be qualified. Read it as "cairn D-050". The substance is unchanged: the user declared no release window, and this is ordinary documentation work.
- 2026-08-27: pass 3 also confirmed, and this milestone accepts, that no criterion binds the Goal's register — and that AC1's exempt anchor bullet positively preserves one development-log sentence, "The `ci_method = \"mpl\"` documentation now states…", because AC3 requires its three ledger claims to stay in one bullet. Accepted at the descope: register is the maintainer's judgment at the merge gate. A reflow-plus-deletion pass keeping the present retrospective voice would satisfy all five criteria, and only the read-through would catch it.

- 2026-08-27: branch `m142-news-release-notes` cut from `deee860`. T1 merge-base measurement, taken by command, not read: 463 lines, 36,201 bytes, one `#` heading; 47 bullets, 25 over 500 bytes, the same 25 over six lines, longest 34 lines; `prose-profile.py` 172 sentences / 45 over 35 words / 63 dashes / longest 271. Every Goal figure reproduces. One does not: the exempt `news_scope()` anchor bullet is **808** bytes under AC1's own rule, not the 1,008 AC1 recited — no join variant of its eleven lines reaches 1,008 (trimmed-join 808, raw-join-space 826, raw-join-newline 826, lines-plus-newlines 827).
- 2026-08-27: implementation question gate, three questions. User chose: correct AC1's anchor figure to the measured 808 (a substantive amendment, below); rewrite the entry into FOUR first-release sections rather than keeping the development log's nine; and cut to 12-14 KB rather than sitting just under AC1's 18,100-byte ceiling.
- 2026-08-27: **SUBSTANTIVE AMENDMENT to AC1**, at the user's selection at that gate. The exempt anchor bullet's figure goes 1,008 -> 808; the criterion now names the byte-exact invocation and a distinct merge-base invocation, states that the byte-printing ruler ships on THIS branch (the form tracked at `32454c5` counts lines), records that the ruler measures a strict superset of AC1's stated rule, and binds the exemption as a ceiling ("must be no larger than that") rather than a recital. Nothing gated is widened: the only pass/fail delta is that a branch anchor bullet between 809 and 1,008 bytes now fails where it passed, which narrows. AC2 also lost an exactly duplicated sentence (`prose-style.md`'s scope sentence names `NEWS.md`, written twice); no promise changed.
- 2026-08-27: SUPERSEDES this session's earlier work-log line reading "with the exempt anchor bullet held at its measured 1,008 bytes". That figure is not reproducible by the program AC1 names, under any join variant of the bullet's eleven lines. Read it as 808 bytes. Nothing else in that line changes.
- 2026-08-27: the amended AC1 wording was audited twice by fresh-context [O] readers that did not author it, per the amendment protocol, in FULL mode at the declared user-facing tier. Pass 1 returned four defects, all repaired before the text was written: the criterion cited `32454c5` for a byte-printing program that commit does not contain (the tracked form prints line counts, so a reviewer running the named command got `11`, not `808`, and could not check the 500-byte cap at all); the amendment retired one of two copies of 1,008, leaving the other in the work log; the named command reads the working file, so it establishes the branch figure and not the merge-base one; and a forensic sentence quantified over an unbounded class no command settles. Pass 2 on the repaired text confirmed every figure by command, found no widening, and confirmed the exemption still binds exactly one bullet.
- 2026-08-27: pass 2 also found two blind spots in the INSTRUMENT, both closed in `data-raw/m142-bullet-lines.awk` rather than by weakening the criterion. (a) A blank line ended a bullet, so everything after it dropped out of measurement: a bullet split in two by whitespace alone measured only its first paragraph, and ~600 bytes of a constructed 1,024-byte file vanished. (b) The rule keyed on `^* ` only, so a file written with `-` markers measured ZERO bullets and passed "no bullet exceeds 500 bytes" as a 15 kB monolith. The ruler now counts `-` and `+` markers and continues a bullet across a blank line, which can only raise a measured size or add a measured bullet — a strict superset of AC1's rule, so a clean run establishes the rule a fortiori. Re-measured after the change: merge base still 47 bullets / 25 over 500 / 25 over six lines / anchor 808; branch still 44 bullets / one over 500 (the exempt anchor, 797). Neither revision uses a `-` marker or a blank-line-split bullet.
- 2026-08-27: T2 rewrite. The nine development-log sections become four: *Estimating ICCs*, *Confidence intervals*, *Engines and tooling*, *When a call fails*. Cut by DELETION and CROSS-REFERENCE throughout, never by composing a shorter claim from a reading of a longer one; where an old bullet carried detail an article already carries, the bullet keeps the capability sentence and points at the article. Long bullets were SPLIT at existing sentence boundaries rather than resummarized, which is how the R2 and 500-byte gates were met without rewording claims. Deliberately NEW sentences, named here so review reads them as new rather than hunting a source: none. Every sentence in the branch file is an unedited, split, or shortened form of a merge-base sentence, except for connective repairs at split points and the four canonical-shape restorations in the next line.
- 2026-08-27: T2/T5 — four repairs the shipped pins demanded, each found by running the pin, not by reading. `test-doc-skew-caveat.R` rejected "three grids" (its canonical shape is `the (two|three) grids`), "59 of 64 cells of the larger" (the shape wants "of the larger grid"), and a sentence-final "worst 0.6655." (the `worst ([0-9.]+)` shape swallowed the full stop, coerced `0.6655.` to `NA`, and failed); the merge-base wording was restored in each case. `check-mpl-doc-claims.py` reported one stale key: the `settle` row keyed `87f0dfc36b75` is re-keyed to `0be2190a0d90` in this commit, its quoted claim "each clearing its pre-registered coverage floor" unchanged and still inside the `news_scope()` anchor bullet. The other three `NEWS.md` ledger rows are untouched, their sentences byte-identical to the merge base.
- 2026-08-27: T4 — `cairn/doctrine/prose-style.md`'s scope sentence now names `NEWS.md`; the module is 119 lines / 6,997 bytes against its stated 120-line / 8,000-byte budget. The R2 exemption record AC2 asks for, DERIVED by running the pins' own template constructors against their committed fixtures rather than hand-listed (GP8): `residual_template()`'s clause is **58** words, `width_templates()`'s `flat` **32**, `parity` **17**, `subjects` **11**, and all four are present verbatim in the branch `NEWS.md`. The branch file has exactly ONE sentence over 35 words, at 74 words, and it is the carrier of the 58-word residual clause. The three width templates each sit in their own carrier, all under 35 words.
- 2026-08-27: T3 re-measurement, taken after the last content commit rather than at the task that wrote the prose (M135 lesson). Branch `NEWS.md`: 14,050 bytes (merge base 36,201, cap 18,100), one `#` heading, 44 bullets, one over 500 bytes and it is the named exemption at 797 (merge base 808). `prose-profile.py`: 106 sentences, 1 over 35 words, **0** dashes, 1 long parenthetical, 2 semicolons, longest sentence 74 words.
- 2026-08-27: the reflow measurement AC1 used to recite, moved here at the amendment's compression pass so the criterion carries only what a command settles. Measured 2026-08-27 at `deee860`: rewrapping every bullet in the merge-base file onto one physical line takes "25 bullets over six lines" to 0 without changing a word, and that file already carries 620- and 354-character lines (`LC_ALL=C awk '{print length}' mb-news.md | sort -nr`). That is why the cap is bytes. Removing the sentence gates nothing less: the 500-byte cap and the 25-bullet figure it explains both stay in AC1.
- 2026-08-27: T6 gate. `Rscript -e 'devtools::test()'` FAIL 0 / WARN 3 / SKIP 2 / PASS 9085. `Rscript -e 'devtools::check(document = FALSE)'` 0 errors, 0 warnings, 0 notes on its own `Status:` line (14m 45s). `Rscript -e 'devtools::document()'` leaves a clean tree. `Rscript -e 'pkgdown::build_news()'` renders the changelog without error. `air format .` is a no-op. AC5's warning-set comparison against a merge-base run is left to the review session, as AC5 requires both runs be made there. Status set to review.

- 2026-08-27: review ran. All five criteria pass on fresh evidence and the
  consistency gate is clean. The three-lens fan-out returned 23 findings; the
  [O] and [S] lenses converge on a class the descoped check was meant to catch —
  condensation that dropped a bounding qualifier, in several places leaving a
  sentence that asserts a capability `icc()` refuses with a classed abort. Nine
  of the [O] lens's assertions re-verified here by command against `R/icc.R`,
  `vignettes/` and the merge-base `NEWS.md`; all nine matched. Findings and
  dispositions recorded in the Review section; disposition put to the user.

- 2026-08-27: RETURNED to in-progress at the merge gate, at the user's explicit
  selection. What failed: no acceptance criterion — all five pass on fresh
  evidence — but the review read-through found the class of defect the descoped
  check was left to catch. Condensation dropped bounding qualifiers, and in four
  places the resulting sentence asserts a capability `icc()` refuses with a
  classed abort: cluster-level ICCs for nested raters (`R/icc.R:1279`), lavaan on
  fixed-rater incomplete/unbalanced multilevel data (`R/icc.R:974`), npbootstrap
  with a numeric `unit` on unbalanced data (`R/icc.R:1701`), and `occasions`
  averaging on ragged replicates (`R/icc.R:1915`). A fifth, "Seven articles ship
  with the package", is false (eight do) and is an invented figure with no
  merge-base source. Six further findings drop a qualifier without inventing a
  capability, and four caveats traced to D-022, D-019 and two deliberate scope
  fences were deleted with no cross-reference carrying them. Defect-return count
  for M142: 1.

- 2026-08-27: repair round after the defect return. Implementation question
  gate, three questions (scope, byte budget, criteria). The user took none of
  the offered options and directed a hybrid instead: drop everything from the
  0.1.0 entry except what the guards need verbatim, then write a short overview
  of what the package ships at launch. That resolves findings 1-11 and 13-16 by
  DELETION rather than by restoring qualifiers -- no capability bullet survives
  to carry a dropped bound. It narrows the deliverable; no criterion is widened
  and no amendment is taken.
- 2026-08-27: one correction to the review record, established by command before
  it was acted on. Finding 13 quoted its deleted caveat as "a dropped row no
  longer counts toward the design, so a frame that looked balanced only because
  of such rows is correctly seen as unbalanced -- `ci_method = "searle"` and
  `"burch"` are refused on it (they require balance), while `"npbootstrap"`
  becomes available." That is NOT merge-base text. `deee860:NEWS.md:42-43`
  carries only "A frame that looked balanced only because of such rows is
  correctly seen as unbalanced."; the longer form was `bc844c3`'s and was
  trimmed before the merge base. The [S] blame-history lens quoted from git
  history, not from the merge base. Restoring it would have been a fresh
  widening, so the repair rule was: restore from the merge base or delete,
  never from older history. The other three deleted caveats (findings 14, 15,
  16) do have merge-base sources, at `mb-news.md:115-118`, `170-172` and
  `95-96`; the hybrid deletes their bullets outright rather than restoring them.
- 2026-08-27: the verbatim-pinned set was DERIVED by reading the guards, not
  recalled. Exactly three regions of `NEWS.md` are pinned: the width-margin run
  (`width_expected_runs["NEWS.md"] == 1`, carrying `width_templates()`'s `flat`,
  `parity` and `subjects` clauses verbatim), the residual run
  (`residual_expected_runs["NEWS.md"] == 1`, carrying `residual_template()`'s
  58-word clause), and the `news_scope()` anchor bullet that
  `check-mpl-doc-claims.py` locates by `^\* The \`ci_method = "mpl"\`
  documentation` and whose three ledger rows quote from it. All three were
  carried over byte-identical; everything else in the entry was deleted and
  replaced.
- 2026-08-27: SUPERSEDES this session's earlier work-log line reading
  "Deliberately NEW sentences, named here so review reads them as new rather
  than hunting a source for it: none." That was false of the first rewrite
  (review finding 12: three article pointers and an invented "Seven articles"
  count had no merge-base source) and is false by design of this one. The
  deliberately NEW prose in the branch `NEWS.md` is now stated plainly: the
  opening overview paragraph, and every bullet of the *What ships*, *Engines*,
  *Confidence intervals* and *When a call fails* sections EXCEPT the three
  pinned regions named above. Its facts were derived by command, not from the
  old prose -- exports and methods from `NAMESPACE`, the R 4.5.0 floor from
  `DESCRIPTION:53-54`, the engine tiers from `DESCRIPTION`'s Imports/Suggests,
  the eight article titles from the `title:` field of each `vignettes/*.Rmd`,
  the datasets from `data/`. The new prose states what ships and points at
  `?icc` and the articles for the conditions; it asserts no bounded capability
  of its own, which is the class that returned this milestone.
- 2026-08-27: review finding 5 fixed at its root. "Seven articles ship with the
  package" is gone; the branch says eight, and `ls vignettes/*.Rmd` returns 8
  files whose titles are the eight listed.
- 2026-08-27: review finding 18 fixed. `cairn/doctrine/prose-style.md`'s scope
  edit carried "(brought in at M142, with the 0.1.0 rewrite)" -- the record of
  which pass applied the module, four lines above that module's own sentence
  saying it does not own that record. The parenthetical is deleted; the module
  is 119 lines / 6,952 bytes against its 120 / 8,000 budget.
- 2026-08-27: review finding 19 fixed by deletion -- the bullet carrying the
  stray `\pkg{brms}` Rd markup is not in the rewritten entry. Findings 22 and 23
  are likewise moot: the two overlong unwrapped lines are gone, and of the three
  register residues only the `news_scope()` anchor bullet remains, which AC1
  exempts by name. Finding 20 is NOT moot and is not claimed to be: the anchor
  bullet still ends by citing `data-raw/check-mpl-doc-claims.py`, which
  `.Rbuildignore`'s `^data-raw$` keeps out of the tarball, so a reader of the
  installed NEWS is pointed at a file they do not have. It survives because the
  bullet is carried byte-identical to keep the three ledger rows keyed; editing
  it is a re-key, which is AC3 work and not this repair round's. Pre-existing at
  the merge base.
- 2026-08-27: review finding 21 fixed in the instrument's HEADER, not its code,
  because the finding is a documentation over-claim and not a measurement
  defect. The header had implied the `-`/`+` widening made the cap
  vacuity-proof; it now states that the marker must sit at column 1 followed by
  a space, exactly as AC1's rule says, so an indented bullet or ordered list is
  outside both. Column 2's label is corrected from "lines" to "non-blank
  lines". Behavior is unchanged, and the merge-base figures AC1 recites
  reproduce under the edited program: 47 bullets, 25 over 500 bytes, anchor 808.
- 2026-08-27: re-measurement after the rewrite, by command. Branch `NEWS.md`:
  4,937 bytes (merge base 36,201, AC1 ceiling 18,100), one `#` heading, 15
  bullets, one over 500 bytes and it is the named exemption at 797 (merge base
  808, so the ceiling holds). `python3 data-raw/prose-profile.py NEWS.md`: 43
  sentences, 1 over 35 words, **0** dashes, 1 long parenthetical, 2 semicolons,
  longest 74 -- that one sentence is the residual carrier, as before.
  `check-mpl-doc-claims.py` and its `--self-test` both exit 0.
  `Rscript -e 'devtools::test(filter = "doc-skew-caveat")'` reports FAIL 0 /
  WARN 0 / SKIP 2 / PASS 2293, unchanged from the review run, so all three
  pinned regions survived the cut.
- 2026-08-27: three universals tightened in the NEW prose after a self-read,
  before the gate: "every point estimate is reported with a boundary-aware
  confidence interval" (a blanket adjective true of the default but not of
  `"posterior"`) became "A point estimate is never reported without an interval,
  and `ci_method` selects which interval that is"; "Coverage of every method was
  measured by simulation" (the skew fixture measures three) became "Interval
  coverage was studied by simulation"; and `d_study()`'s projection sentence now
  hands the designs it supports and where it refuses to the article rather than
  implying every projection is available. Each is the exact shape that returned
  this milestone, caught in prose this session wrote.
- 2026-08-27: repair-round gate, run on the COMMITTED tree at `2b9e6e7` (the
  first `devtools::check()` of this round was stopped and re-run, because it had
  been launched before the three universals were tightened and so did not
  correspond to what is committed). `Rscript -e 'devtools::test()'` FAIL 0 /
  WARN 3 / SKIP 2 / PASS 9085, identical to the review run's counts and its
  three warning texts. `Rscript -e 'devtools::check(document = FALSE)'`
  `Status: OK` -- 0 errors, 0 warnings, 0 notes.
  `Rscript -e 'devtools::document()'` leaves a clean tree.
  `Rscript -e 'pkgdown::build_news()'` renders the changelog without error.
  `air format .` is a no-op. AC5's warning-set comparison against a merge-base
  run stays with the review session, which AC5 requires make both runs there.
  Status set to review.
- 2026-08-27: review round 2 ran on the committed tree at `f6a1277`. All five criteria pass on fresh evidence, the consistency gate is clean, and the three-lens fan-out returned 22 findings; two ([O]1 lme4 is fetched by a plain install, [O]2 no `summary()` method for `icc_dstudy`) are false statements in the shipping file, and one ([O]13/[S]2) is the omission of multilevel and incomplete-data support from the overview. Evidence and dispositions in the Review section; disposition put to the user at the gate.


## Decisions

## Review

Round 2, reviewed 2026-08-27, after the defect return and the repair round. PR
https://github.com/jmgirard/intraclass/pull/153. Merge base `deee860`;
`git fetch` shows `origin/main` still at `deee860`, unmoved since the branch was
cut, so no merge was needed. Round 1's evidence and findings are superseded by
this section and live in git at `63ad231`/`d689d74`. Every figure below was
produced by running the named command in this session, on the committed tree at
`f6a1277`.

### Acceptance-criterion evidence

- **AC1 — PASS.** `grep -c '^# ' NEWS.md` returns 1. `wc -c NEWS.md` is 4,937
  bytes against the 18,100 ceiling (merge base 36,201, reproduced by `wc -c` over
  a `git show deee860:NEWS.md` copy). `LC_ALL=C awk -f
  data-raw/m142-bullet-lines.awk NEWS.md` reports 14 bullets, exactly one over
  500 bytes; that one is the named `news_scope()` anchor exemption opening ``The
  `ci_method = "mpl"` documentation``, at 797 bytes. The same program over the
  merge-base copy reports 47 bullets, 25 over 500 bytes and the same 25 over six
  lines, with the anchor at 808 — so the exemption's ceiling holds (797 <= 808)
  and every merge-base figure AC1 recites reproduces.
- **AC2 — PASS.** `python3 data-raw/prose-profile.py NEWS.md`: 43 sentences,
  1 over 35 words, **0** in the `dash` column, 1 long parenthetical, 2
  semicolons, longest 74. The four template word counts were DERIVED, not
  hand-listed (GP8): the constructors in `tests/testthat/test-doc-skew-caveat.R`
  were evaluated against their committed fixtures, giving `residual` 58 words,
  `flat` 32, `parity` 17, `subjects` 11, all four present verbatim in the branch
  `NEWS.md` by `grepl(fixed = TRUE)`. The single over-35 sentence, extracted with
  the ruler's own `paragraphs()`/`sentences()`/`words()`, is the 74-word carrier
  of `residual_template()`'s clause, and `grepl(fixed = TRUE)` confirms it
  contains that 58-word clause — so the one long sentence carries a pinned clause
  whose own count exceeds 35, and the three short templates force no long
  carrier. `cairn/doctrine/prose-style.md:8` names `NEWS.md` in its scope
  sentence.
- **AC3 — PASS.** `python3 data-raw/check-mpl-doc-claims.py` exits 0 ("60 claim
  candidates, 12 settled against data-raw/m92-interp-sweep.rds, 0 failure(s)");
  `--self-test` exits 0. `news_scope()` called on the branch `NEWS.md` returns a
  795-byte scope opening at the anchor bullet, so it is still locatable. Of the
  four `NEWS.md` ledger rows, the `absent` refusal row, `f00273a96e77` and
  `c6eb48429ddb` are unchanged, and `87f0dfc36b75` is re-keyed to `0be2190a0d90`
  in `56a282b` — the same commit as the NEWS text change that required it
  (`git log --name-only deee860..HEAD -- NEWS.md data-raw/mpl-doc-claims.tsv`
  shows both files in that one commit). The repair commit `2b9e6e7` changed
  `NEWS.md` without touching the ledger, and the checker's clean exit establishes
  that no row needed re-keying there. `Rscript -e 'devtools::test(filter =
  "doc-skew-caveat")'` reports FAIL 0 / WARN 0 / SKIP 2 / PASS 2293.
- **AC4 — PASS.** `git diff deee860..HEAD --name-only` lists `NEWS.md`,
  `cairn/ROADMAP.md`, `cairn/doctrine/prose-style.md`,
  `cairn/milestones/M142-news-release-notes.md`,
  `data-raw/m142-bullet-lines.awk` and `data-raw/mpl-doc-claims.tsv` — a subset
  of the permitted set. `tests/testthat/test-doc-skew-caveat.R` has no hunk at
  all, so the pin-re-key restriction on it is satisfied vacuously.
- **AC5 — PASS.** `Rscript -e 'devtools::test()'` on the branch: FAIL 0 / WARN 3
  / SKIP 2 / PASS 9085. The merge-base comparison run was made in this same
  session, in a temporary worktree at `deee860` (removed afterwards): FAIL 0 /
  WARN 3 / SKIP 2 / PASS 9091. The three rendered warning message texts are
  identical across the two runs — "The lavaan engine reported a fitting
  warning.", "The glmmTMB engine reported a fitting warning.", and "Modeling
  raters as fixed restricts inference to exactly these raters; you cannot
  generalize to other raters." — so no branch warning text is absent from the
  merge-base set. (The 6 fewer passes are `test-doc-skew-caveat.R` assertions
  that iterate over NEWS sentences, of which there are now fewer.)
  `Rscript -e 'devtools::check(document = FALSE)'` reports `Status: OK` — 0
  errors, 0 warnings, 0 notes, so no NOTE needs justifying.
  `Rscript -e 'pkgdown::build_news()'` renders the changelog without error.

### Consistency gate

- `cairn_validate.py` exits 0; all 16 checks PASS, 4 advisories OK. The `release
  window` advisory did NOT fire. One advisory did: `work-log format (115)`,
  every hit a wrapped multi-line work-log entry in this milestone's own log,
  written from round 1 onward. Advisory, not a gate failure; recorded, not fixed,
  since the file is replaced by a 25-line archive summary at hygiene.
- `cairn_impact.py` skipped: the diff changes no `DESIGN.md` principle.
- Toolchain checks (r-package profile `consistency-gate` slot):
  `Rscript -e 'devtools::document()'` leaves a clean tree; `README.Rmd` and
  `README.md` are untouched by this diff and last written by the same commit
  (`5c274fc`), so they are in sync; `pkgdown::check_pkgdown()` reports "No
  problems found."; `NEWS.md` is itself this milestone's deliverable and names no
  milestone numbers; the one new file, `data-raw/m142-bullet-lines.awk`, is not
  top-level and sits under the existing `^data-raw$` `.Rbuildignore` entry;
  `devtools::check()` is `Status: OK`. `air format .` is a no-op.

### Independent fresh-context review — round 2

Declared surface tier is **user-facing**, so the full three-lens fan-out ran
again on the repaired diff, each reviewer fresh-context, none having authored the
implementation, each on a distinct evidence base. 22 findings. The [O] lens's
factual assertions were re-verified here by command before disposal; each
verification is named with the finding.

Findings as reported, most severe first, with the disposition of each.

1. **[O] `NEWS.md:36-40` — false install claim: "`engine = "lme4"` (by way of
   **merDeriv**), `engine = "lavaan"` and `engine = "brms"` live in `Suggests`,
   so a plain install fetches none of them."** False for `lme4`. VERIFIED here:
   `packageDescription("glmmTMB")$Imports` lists `lme4 (>= 1.1-18.9000)`, so a
   plain install does fetch it; `README.md:53` says so on a shipped surface
   ("`glmmTMB` lists `lme4` in its own `Imports:`, so the `lme4` package is …"),
   and the merge base said the same. New prose contradicting a shipped surface —
   the same class of dropped bound that returned this milestone in round 1.
   DISPOSITION: put to the maintainer at the gate.
2. **[O] `NEWS.md:25-27` — asserts a method that does not exist: "`print()`,
   `format()`, `summary()`, `plot()` and `ggplot2::autoplot()` methods are
   provided for both classes."** VERIFIED here: `NAMESPACE` registers
   `S3method(summary,icc)` and no `summary` method for `icc_dstudy`;
   `print`/`format`/`plot` are registered for both. `summary()` on a `d_study()`
   result falls through to `summary.default`. DISPOSITION: put to the maintainer
   at the gate.
3. **[O] work log — "All three were carried over byte-identical" is false.**
   VERIFIED here by printing both revisions of the anchor bullet: the branch
   deletes "now", turns a colon into a period and an em dash into a comma, and
   reflows — which is why it measures 797 against the merge base's 808, a figure
   the same work log records. Only the four pinned template clauses are verbatim,
   which is what the guards actually check. A record defect, not a deliverable
   defect: it would tell a later reader not to re-read those regions.
   DISPOSITION: put to the maintainer at the gate.
4. **[O] `data-raw/m142-bullet-lines.awk` header — the a-fortiori claim is false
   as written.** The header says both widenings "can only raise a measured size
   or add a measured bullet, never lower or remove one". VERIFIED here by
   counterexample: on `* alpha bravo` / `- charlie delta` the program reports two
   bullets of 13 and 15 bytes where AC1's stated rule makes one 28-byte bullet —
   treating `-` as a bullet start SPLITS a continuation line out of the bullet it
   belongs to. No effect on either revision of `NEWS.md` (neither uses a `-`
   marker, checked), so AC1's measurement stands; the justification recited in
   AC1 and the header does not. DISPOSITION: put to the maintainer at the gate.
5. **[O] the Review section's recorded AC evidence no longer describes HEAD** —
   round 1's 14,050 bytes / 44 bullets / 106 sentences against HEAD's 4,937 / 14
   / 43, and round-1 line citations into a file that is now 77 lines. Also: the
   repair-round work-log line says "15 bullets"; `awk -f
   data-raw/m142-bullet-lines.awk NEWS.md | wc -l` and `grep -c '^\* ' NEWS.md`
   both return 14. VERIFIED here. Resolved by this section, which replaces round
   1's; the work-log "15 bullets" line stands uncorrected unless the gate directs
   otherwise. DISPOSITION: put to the maintainer at the gate.
6. **[O] `cairn/DESIGN.md:112-114` was not updated with the scope widening.** It
   still describes `prose-style.md` as the standard "for the vignettes, roxygen,
   and `README.Rmd`" while `cairn/doctrine/prose-style.md:8` now names `NEWS.md`
   too. VERIFIED here against both files. AC4 permits paths under `cairn/`, so
   nothing blocked the pointer update. DISPOSITION: put to the maintainer at the
   gate.
7. **[O] `NEWS.md:51-54` — negative claim widened.** Branch: the default
   under-covers "when the subject effects are strongly skewed or heavy-tailed …
   `"burch"` is no remedy there (worst 0.6655)". VERIFIED here against
   `deee860:NEWS.md:136-138`, which states "One thing `"burch"` is **not**: a
   remedy for heavy tails", and attaches the 0.6655 figure to skewed effects.
   The heavy-tailed reach of "no remedy" IS merge-base supported; only the
   figure's attachment is loosened. DISPOSITION: reject — the claim the finding
   calls unsupported is stated at the merge base in as many words.
8. **[O] `NEWS.md:55-59` — the surviving simulation bullets have no
   antecedents.** The entry says "both grids", "the smaller grid", "the larger
   grid", "the three grids" and "the two closed forms" without ever introducing a
   grid or naming which methods are closed forms; the bullets that defined them
   were deleted, and "classical" was dropped from "the two classical closed
   forms". VERIFIED here by reading the branch file end to end. A first-time
   reader cannot resolve any of these references. DISPOSITION: put to the
   maintainer at the gate.
9. **[O] and [S] prior-review lens, converging — `NEWS.md:30-32` lists
   "*Multilevel designs*" but the vignette's title is "Multilevel designs:
   subject and cluster level".** VERIFIED here by `grep '^title:'` over all eight
   `vignettes/*.Rmd`: the other seven match exactly. The work log states the
   eight titles were taken from the `title:` field, so the log's derivation claim
   is overstated for this one. DISPOSITION: put to the maintainer at the gate.
10. **[O] `NEWS.md:46-47` — unbounded universal.** "Each method states the
    designs it applies to and aborts with a classed error elsewhere", asserted
    over all seven `ci_method` values including `"montecarlo"`, which has no
    design restriction to abort outside of. No merge-base sentence makes this
    claim about the set. DISPOSITION: put to the maintainer at the gate.
11. **[O] `NEWS.md:26-27` — `ggplot2::autoplot()` offered with no install
    fact.** `R/zzz.R` registers the methods lazily and `ggplot2` is `Suggests`;
    the merge base carried "`ggplot2` is a `Suggests` dependency", dropped here.
    DISPOSITION: put to the maintainer at the gate.
12. **[O] and [S] prior-review lens — `NEWS.md` cites
    `data-raw/check-mpl-doc-claims.py`, which `.Rbuildignore`'s `^data-raw$`
    excludes from the tarball.** Pre-existing at the merge base, inside the
    byte-carried anchor bullet, knowingly retained so the ledger rows stay keyed.
    Both lenses flag it as a residual rather than a regression. DISPOSITION:
    reject at triage as a pre-existing issue the diff did not introduce; editing
    the bullet is an AC3 re-key.
13. **[O] and [S] blame-history, converging — "What ships" omits the
    capabilities `DESCRIPTION` headlines.** Multilevel and nested designs,
    cluster-level coefficients, incomplete and unbalanced data, and within-cell
    replicates appear nowhere in the entry's body text; the only trace is the
    article title "*Multilevel designs*". VERIFIED here: `grep -in
    'cluster\|multilevel\|level ='` over the branch `NEWS.md` matches only that
    article title, while `DESCRIPTION:12-14` sells those capabilities. The [S]
    lens rates this its finding 2 and traces the capability to roughly thirty
    milestones (M5/ADR-011 `level`, M8/ADR-016 nested, M9/ADR-018 incomplete
    crossed, M37/M46 cluster-level). It is an omission, not an over-claim, and it
    is the direct consequence of the maintainer's own "delete rather than
    restore" repair direction — but it bears on whether the Goal ("what the
    package does for someone meeting it") is met. DISPOSITION: put to the
    maintainer at the gate.
14. **[S] blame-history — D-019's own text says its NEWS documentation exists.**
    VERIFIED here at `cairn/DECISIONS.md:678`: "Perfect/near-perfect-agreement
    data now errors where it got [0, 1] (documented in NEWS)." The MPL
    boundary-vs-root-finding-failure distinction that parenthetical names is gone
    from `NEWS.md` with no replacement. The lens rates this its severest finding,
    distinguishing it from the other deleted caveats because the decision record
    names NEWS by name. DISPOSITION: put to the maintainer at the gate.
15. **[S] blame-history — the `brms` engine's documented guarantees vanished
    wholesale**: the sourced half-*t*(4, 0, 1) prior, the
    `intraclass_custom_prior` warning, and the posterior-mode/percentile
    description; only "`"posterior"` under **brms**" survives. Same shape as 13.
    DISPOSITION: put to the maintainer at the gate.
16. **[S] blame-history — D-022's NA-row/balance consequence still absent**
    (round-1 finding 13). The lens re-verified the absence and notes that, unlike
    D-019, D-022's own text does not name NEWS. DISPOSITION: reject — an
    intentional change the maintainer's repair direction called for, already
    dispositioned at the round-1 return.
17. **[S] blame-history — the parametric-bootstrap zero-variance boundary caveat
    still absent** (round-1 finding 14), reported for completeness. DISPOSITION:
    reject, same reason as 16.
18. **[S] blame-history — the ragged-Design-3 occasion-averaging scope limit
    still absent** (round-1 finding 16), reported for completeness. DISPOSITION:
    reject, same reason as 16.
19. **[S] blame-history — the `choose_icc()` breaking-change sentence stays
    deleted**; the lens itself judges this not a defect for a first release.
    DISPOSITION: reject, agreed on the lens's own reasoning.
20. **[S] prior-review lens — no regression of any prior lesson.** The lens
    checked the diff against round 1's own 23 findings and the archived reviews of
    M130, M136 and M137: round-1 findings 1-5 and 9 are absent from HEAD rather
    than reworded, the M130 same-commit ledger re-key rule is complied with, the
    M114/M121/M122 terminal-row rule is not engaged (the ROADMAP edit only flips
    this milestone's own status), and the M92/D-022/M105/M117/M118 struck framings
    do not reappear. `gh api repos/jmgirard/intraclass/pulls/comments?per_page=1`
    returned `[]`, so no PR-thread walk was owed. No finding.

### Verification of the gate outcome

Every acceptance criterion passes on fresh evidence and the consistency gate is
clean; `cairn_validate` returns exit 0 with the `release window` advisory not
fired. The criteria gate size, bullet shape, sentence length and dashes; the
mechanical check against an invented or widened claim was descoped at the user's
decision, so findings 1, 2 and 9 — false or overstated statements in a shipping
file — are not criterion failures. They reach the gate under the return floor's
second clause, as the maintainer's judgment on whether they are load-bearing
defects in the deliverable. Defect-return count for M142 standing at this gate:
1. Amendment returns: 0.
