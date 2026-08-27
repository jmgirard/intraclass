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

**Out:** extending `check-mpl-doc-claims.py`'s `news_scope()` past its one
anchor bullet → the standing "Harden `data-raw/check-mpl-doc-claims.py`"
candidate row, which D-021 still bars and D-029 explicitly declines to reopen
for apparatus dressed as documentation. Any change to what the package computes,
or to `?icc`, the vignettes or the README → unchanged here; a false claim found
in NEWS while cutting is corrected in place under D-029, never widened into new
scope. A second `#` version entry → none exists; 0.1.0 is unreleased.

## Acceptance criteria

- [ ] AC1 — `NEWS.md` holds exactly one `#` heading (`grep -c '^# ' NEWS.md`
      returns 1), is at most 18,100 bytes by `wc -c` (merge base 36,201), and
      carries no bullet spanning more than six lines. A bullet is the line
      matching `^\* ` plus every following line until the next `^\* `, `^#`, or
      blank line; the count is produced by that rule stated as one `awk` program
      in the milestone file and re-run at review. Every `^## ` heading the entry
      carries also appears in the merge-base entry's `^## ` set — the entry may
      carry fewer sections, never a new one.
- [ ] AC2 — `python3 data-raw/prose-profile.py NEWS.md` reports 0 in its `dash`
      column (R1). Every sentence it counts over 35 words (R2) is a carrier for
      a clause that a shipped test pins verbatim and that admits no sentence
      break — `cairn/doctrine/prose-style.md`'s own stated exemption — and the
      exempt set is derived by running those pins' own sweep over the new entry,
      never by a hand list; each carrier is recorded with the clause's word
      count and the sentence's, as that exemption requires. The one such clause
      known at plan time is `residual_template()`'s, measured this session at 72
      words in its shortest viable carrier, so the R2 count is not zero and the
      criterion does not ask it to be. `cairn/doctrine/prose-style.md`'s scope
      sentence names `NEWS.md` among the surfaces it owns.
- [ ] AC3 — no claim is widened and none is invented (R6). Both revisions of the
      entry are segmented into sentences by `prose-profile.py`'s own
      segmentation, imported rather than reimplemented, and every sentence of
      the new entry either appears verbatim among the merge-base entry's
      sentences or is listed in a triage table in this milestone file against
      the merge-base sentence or sentences it replaces, carrying a verdict of
      `narrower`, `split`, or `pointer`. No verdict is `wider`, and the table
      leaves no new sentence unlisted — the two sentence sets, not a hand list,
      enumerate the domain, and the file asserts that every unmatched new
      sentence has a table row.
- [ ] AC4 — the guards keyed on NEWS text pass, run in the review session:
      `python3 data-raw/check-mpl-doc-claims.py` and the same script with
      `--self-test` both exit 0, its `news_scope()` anchor bullet still
      locatable, and each of the four `data-raw/mpl-doc-claims.tsv` rows whose
      file column is `NEWS.md` — the three quoted rows `87f0dfc36b75`,
      `f00273a96e77`, `c6eb48429ddb` and the `absent` refusal row whose regex
      must match nowhere in the news scope — is re-keyed, deleted or added in
      the same commit as the text change that required it (M130 lesson);
      `Rscript -e 'devtools::test(filter = "doc-skew-caveat")'` reports
      `FAIL 0`, with the NEWS legs of `width_expected_runs` and
      `residual_expected_runs` still satisfied.
- [ ] AC5 — `git diff <merge-base>..HEAD --name-only` lists only `NEWS.md`,
      `data-raw/mpl-doc-claims.tsv`, `tests/testthat/test-doc-skew-caveat.R`,
      `cairn/doctrine/prose-style.md`, and paths under `cairn/`. Any hunk in the
      test file is a pin re-key and nothing else, each named in the Review
      section with the NEWS text whose move forced it.
- [ ] AC6 — `Rscript -e 'devtools::test()'` reports `FAIL 0` and no warning whose
      rendered message text is absent from the set the same `devtools::test()`
      invocation reports at this milestone's merge-base, both runs made in the
      review session and both sets recorded in the work log; `Rscript -e
      'devtools::check()'` reports 0 errors and 0 warnings on `R CMD check`'s own
      `Status:` line, and any NOTE it reports is justified in the Review section;
      `Rscript -e 'pkgdown::build_news()'` renders the changelog without error.

## Coverage

- AC1 → T2, T3
- AC2 → T3, T4
- AC3 → T3, T5
- AC4 → T6
- AC5 → T6, T7
- AC6 → T7

## Tasks

- [ ] T1 — Measure the merge base and record it: `wc -c`, the `^## ` heading set
      in order, the per-bullet line counts under AC1's `awk` rule, the ruler's
      four columns, the four `NEWS.md` ledger rows with their quoted text, and
      the exact runs the `width`/`residual` pins locate in NEWS today. Commit
      the `awk` program with the measurement. Nothing is predicted from reading.
- [ ] T2 — Cut section by section by DELETION and CROSS-REFERENCE — point at
      `?icc` or the vignette that already carries the detail — never by
      composing a shorter claim from a reading of the old one. This is the
      milestone's whole risk: M133, M136 and M123 each returned repeatedly on
      composed prose, and M137 passed in one round by deriving instead.
- [ ] T3 — Re-measure with the ruler and the `awk` rule after the LAST content
      commit, never at the task that wrote the prose (M135 lesson).
- [ ] T4 — Add `NEWS.md` to `cairn/doctrine/prose-style.md`'s scope sentence;
      re-check the module against its stated 120-line / 8,000-byte budget.
- [ ] T5 — Build the AC3 triage table by importing `prose-profile.py`'s
      segmentation and differencing the two sentence sets; triage each unmatched
      new sentence against what it replaces.
- [ ] T6 — Re-key the ledger rows and any pin the moved text broke, in the same
      commit as the move; run every `data-raw/` checker with `--self-test`.
- [ ] T7 — Gate: full suite, merge-base suite in a temporary worktree,
      `devtools::check()`, `pkgdown::build_news()`, `devtools::document()`.

## Work log

- 2026-08-27: created by /milestone-plan.
- 2026-08-27: plan-gate criteria audit ran in FULL mode (declared surface tier user-facing), pass 1 over the drafted wording, [O] fresh reader, not the author. Thirteen findings. The load-bearing one: no criterion bound the Goal — a mechanical truncation preserving the headings, the pinned sentences and the ledger quotes satisfied all five drafted criteria while reading exactly as before. Also returned: an unfilled ratio placeholder; a heading clause forbidding the section merges condensing needs; a false claim that two NEWS sentences are pinned `fixed = TRUE` byte-identical (they are located by a keyword-proximity neighbourhood sweep, with short template clauses matched verbatim inside the run — so the long sentences CAN be split); three `mpl-doc-claims.tsv` NEWS rows where there are four, the fourth an `absent` refusal row whose regex must match nowhere; ledger handling covering only re-keying, not the orphaned-row and uncovered-claim failures that deletion actually triggers; a permitted-paths list that deadlocked against the guard criterion; four criteria binding recording acts rather than the deliverable; hunk-level triage too coarse to catch a composed section rewrite; and `prose-style.md` not naming NEWS in its own scope. All disposed at the gate: nine fixed in the rewritten criteria, four routed to the question round.
- 2026-08-27: question gate, four questions. User chose: cut to at most half the merge-base bytes with a six-line bullet cap; the R2 35-word bar rather than a recorded-not-gated figure; bringing `NEWS.md` under `cairn/doctrine/prose-style.md`'s scope; and NO release window — this is ordinary documentation work, not release preparation, so the release-shaped tripwire does not fire and D-050 is not engaged.
- 2026-08-27: the 35-word bar and the doctrine-scope answer compose: `prose-style.md` already states an exemption for a clause a shipped test pins verbatim that admits no sentence break. Measured this session with the ruler — `residual_template()`'s clause needs a 72-word carrier sentence, so R2 cannot reach zero and AC2 says so rather than promising it. This corrects a pre-gate statement that the pinned clauses were short enough for a flat 35-word bar; the width clauses are, the residual one is not.
- 2026-08-27: Goal's bullet figures corrected from 46/24 to 47/25 — the first count used a looser `awk` than the rule AC1 names; the Goal now carries the figures AC1's own program produces.
- 2026-08-27: plan gate chose condensation by DELETION and CROSS-REFERENCE over rewriting each bullet into a shorter summary, because this repo's prose milestones fail by composing claims from a reading (M133 reverted its deliverable, M136 took four rounds, M123 four attempts) and the one that passed in a single round, M137, derived instead; falsified by an AC3 triage table in which the `pointer` and `narrower` verdicts cannot carry the required cut, forcing `wider` verdicts to meet AC1's byte ceiling.
- 2026-08-27: CHECKPOINT, plan not yet complete. Criteria audit pass 2 over the rewritten six criteria was in flight when this was committed; its findings are not yet disposed, and the remainder ledger and durable-record preview are not yet presented. Do not start implementation until pass 2 is disposed with a work-log line.

## Decisions

## Review
