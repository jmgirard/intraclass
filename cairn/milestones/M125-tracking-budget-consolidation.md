<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M125: Bring ROADMAP.md and LESSONS.md back under their byte budgets

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate; GP8/GP9 are CREATED by T3/T4, so the slot cannot cite them until they exist in DESIGN.md (cairn_validate FAILs on a forward reference); implement fills it once they land -->
- **Branch/PR:** `m125-tracking-budget-consolidation`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Bring `cairn/ROADMAP.md` and `cairn/LESSONS.md` back under their tracking-rules
byte budgets without losing a live promotion condition, falsifier, or durable
gotcha.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**Surface tier: internal.** The deliverable is this repo's own `cairn/` tracking
records and two `DESIGN.md` principles; no external consumer of the package
relies on any of it, and no shipped behaviour, message or number changes.

**In:** deleting the five struck-through candidate rows whose work already
shipped, per-row, after confirming each row's live remainder is carried by the
`milestones/archive/` file that absorbed it; compressing the widest live
candidate rows to promotion condition + falsifier + lineage, citing the
milestone file that holds the measurement narrative rather than restating it;
graduating five stabilized `LESSONS.md` families under the maturation exit —
two into `cairn/DESIGN.md` as **GP8** (state a verified set procedurally) and
**GP9** (exercise a degenerate guard at the reducer; assert the rule, not the
platform's arithmetic), three into small pages under `cairn/doctrine/`;
compressing the leftover in-place extension blocks; keeping every `data-raw`
checker green across the ROADMAP edits.

**Out:** any new checker, ledger or audit over the repo's own records — barred
by D-021, which D-032 confirms this milestone does not reach. Retiring a
`LESSONS.md` line that clears none of the three exits → stays in the file, with
the measured shortfall reported at review rather than forced. Rewriting
`cairn/DECISIONS.md`, the archives or `legacy/` → barred as history (IP4).
Raising or lowering either budget → a tracking-rules change, not this repo's.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] **AC1.** At the merge commit `wc -c cairn/ROADMAP.md` reports fewer than
      24,000 bytes and `wc -c cairn/LESSONS.md` fewer than 20,000 bytes, and
      `python3 "$CAIRN/scripts/cairn_validate.py"`'s `weight caps` check still
      PASSes, so the 60- and 50-line caps are not traded away to buy bytes.
- [ ] **AC2.** On the merge commit `python3 "$CAIRN/scripts/cairn_validate.py"`
      exits 0 with every check PASS, and all four checkers pass:
      `data-raw/check-record-claims.py`,
      `data-raw/check-reference-observations.py`,
      `data-raw/enumerate-generalizing-claims.py --check`,
      `data-raw/check-mpl-doc-claims.py`.
- [ ] **AC3.** Every candidate row the merge diff removes — enumerated by
      `git diff <base>..HEAD -- cairn/ROADMAP.md`, removed lines beginning
      `- ` below the `## Candidates` heading — is dispositioned in the work log
      as promoted-and-shipped (naming the `milestones/archive/` file that holds
      it), superseded (naming the superseding record), or dropped at the user's
      explicit direction.
- [ ] **AC4.** Every candidate row the merge diff modifies — paired between
      sides by its leading bolded title, or by its first eight words where a row
      carries no bolded title — still states a promotion condition and a
      lineage clause on the head side.
- [ ] **AC5.** Every `cairn/LESSONS.md` line the merge diff removes —
      enumerated by `git diff <base>..HEAD -- cairn/LESSONS.md` restricted to
      removed lines whose leading `YYYY-MM-DD (M<NN>` token appears nowhere in
      the head-side file — is named in the work log with the exit it took:
      enforcement, ownership, or maturation.
- [ ] **AC6.** For every line AC5 enumerates, the work log carries one
      retired-line → destination row naming the `DESIGN.md` principle id or the
      `cairn/doctrine/` page section that received it, and each row cites the
      diff hunk that removed the line.
- [ ] **AC7.** Each page the milestone adds under `cairn/doctrine/` opens with a
      header sentence naming its own scope, and every other `cairn/` file its
      prose names is named as a cross-reference rather than as content it owns.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3, T8
- AC2 → T9
- AC3 → T1
- AC4 → T2
- AC5 → T3, T4, T5, T6, T7
- AC6 → T3, T4, T5, T6, T7
- AC7 → T5, T6, T7

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] **T1.** Delete the five struck-through candidate rows
      (`cairn/ROADMAP.md:30,32,33,37,55`), one at a time: read the
      `milestones/archive/` file each names, confirm the row's live remainder is
      carried there — row 30's two standing audit findings against the digest
      shape are the known case — and migrate any remainder into a surviving row
      before deleting. One work-log disposition line per row.
- [ ] **T2.** Compress the widest live candidate rows to promotion condition +
      falsifier + lineage, heaviest first: `:46` (3,729 B), `:45`, `:42`, `:43`,
      `:34`, `:27`, `:29`, `:44`. Cite the milestone file holding each
      measurement narrative; never restate it.
- [ ] **T3.** Graduate `LESSONS.md:17` (state a set procedurally) into
      `cairn/DESIGN.md` as **GP8**; delete the line; record the mapping.
- [ ] **T4.** Graduate `LESSONS.md:30` (degenerate guards unreachable via
      `icc()`; platform-dependent arithmetic) into `cairn/DESIGN.md` as **GP9**;
      delete the line; record the mapping.
- [ ] **T5.** Author `cairn/doctrine/doc-claim-pins.md` from `LESSONS.md:47`
      (wrapped-claim search, installed-vs-source surfaces, `rd_flat()`,
      blockquote stripping); delete the line; record the mapping.
- [ ] **T6.** Author `cairn/doctrine/data-raw-checkers.md` from `LESSONS.md:31`
      (the four checkers, what stales each, the `check-references` CI job) and
      add one `DESIGN.md` Conventions bullet pointing at it; delete the line.
- [ ] **T7.** Author `cairn/doctrine/source-ingestion.md` from `LESSONS.md:16`
      (PDF text layer vs printed page; per-note quotation sweeps); delete the
      line; record the mapping.
- [ ] **T8.** Compress the leftover in-place extension blocks until
      `wc -c cairn/LESSONS.md` is under 20,000; measure after each family and
      record the running figure, so a shortfall surfaces before review.
- [ ] **T9.** Re-check `data-raw/record-claims.tsv` against the edited ROADMAP —
      the `[claim:roadmap-terminal-rows]` expectation is the known trap
      (`LESSONS.md:45`, three prior recurrences) — and run `cairn_validate` plus
      all four `data-raw` checkers.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-17: created by /milestone-plan.
- 2026-08-17: Principles-touched left `—` because GP8/GP9 do not yet exist; `cairn_validate`'s `principles slot valid` check FAILs on a forward reference, so implement fills the slot once T3/T4 land them.
- 2026-08-17: criteria audit ran in **reduced** mode ([O], fresh context, internal tier) and returned four findings, all unenumerated universals; all four fixed before writing — AC5 gained a token-absence diff procedure and lost an undefined "no stub line" clause, AC7 narrowed to header-scope + cross-reference form, AC6 moved "derived from" to T3–T7, AC4 gained a row-identity rule.
- 2026-08-17: plan gate chose one milestone over a two-way split because both halves share a cause, a remedy doctrine and a tracking-only diff; falsified by the review needing separate evidence sets per half.
- 2026-08-17: plan gate chose graduating five families over the candidate row's two because measurement showed two reach only 28,257 bytes against a 20,000 budget; falsified by a family failing all three retirement exits at implement time, which returns here for a gated amendment rather than a forced retirement.
- 2026-08-17: plan gate chose `cairn/doctrine/` pages over `cairn/references/` for the three craft families because `references/` is defined as owning source and synthesis notes about external sources; falsified by a maintainer ruling the extra-file boundary too thin to carry them.
- 2026-08-17: plan gate chose per-row deletion checks over a blanket prune of the five struck rows because row 30 carries live audit findings its archive may not hold; falsified by the per-row check finding every remainder already archived.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->
