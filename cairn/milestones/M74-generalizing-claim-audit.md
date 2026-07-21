<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M74: Re-derive the generalizing claims over their full source tables

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** low   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M73   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m74-generalizing-claim-audit   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Re-derive every references-page claim that generalizes from cited cells to a
range, count, or superlative against the full source table it summarizes.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** claims of the shape *"the four lowest cells are all at low `ρ`"*,
*"the ratio runs 1.7–4×"*, *"the narrowest ratios are extreme concave"* — a
statement about a source table stated more broadly than the cells it cites.
Each is recomputed over the **full** table and either confirmed, narrowed, or
corrected, with the derivation basis recorded so a later reader can re-run it.
Scoped to the claims the repo **relies on**: those in a page's load-bearing
sections, and any claim a ROADMAP candidate row, D-entry, or `ORACLES.md`
entry rests on. Includes M71's two known instances, if still open:
`saha2005.md`'s "both sit in the upper half" and `mehta2018.md`'s "the
narrowest ratios sit in the concave Cases 1–2".

**Out:** dated observations about the repo's own state → M73 (different
shape, different remedy — a command settles those, only a recomputation
settles these). Prose in a page's non-load-bearing commentary, where a loose
summary misleads no downstream decision. Re-reading sources for *value*
fidelity → M69/M70/M71 did that; this milestone recomputes from values
already verified, and a value found wrong here is escalated, not silently
re-transcribed.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] The claims in scope are enumerated by a recorded, re-runnable search
      rather than by reading — the enumeration itself is reproducible, so a
      later reader can confirm none was skipped.
- [ ] Every enumerated claim is recomputed over its full source table and
      confirmed, narrowed, or corrected in place.
- [ ] Each recomputed claim records the basis of its derivation — which table,
      how many cells, what was computed — so the claim can be re-checked
      without redoing the reading.
- [ ] No claim is left resting on the cells it happens to cite when the full
      table contradicts it — the specific defect this milestone exists to
      remove (M71 review attempts 2 and 3, findings F7/F8/F9 and F2/F3).
- [ ] No package value changes: a correction that would move an oracle value,
      test fixture, or documented behavior is escalated as a review finding
      with its citation, not silently applied.
- [ ] `cairn_validate` passes and the r-package `verify` slot is clean.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2, T3, T4
- AC3 → T2, T3, T4
- AC4 → T2, T3, T4, T5
- AC5 → T2, T3, T4, T5
- AC6 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: build and record the enumeration — a search over the references
      corpus for generalizing shapes (quantifiers and superlatives adjacent to
      a numeric claim), triaged into in-scope (load-bearing / relied upon) and
      out. Record the search so review can re-run it.
- [ ] T2: recompute the enumerated claims in the seven M71 notes, starting
      with the two review already found false.
- [ ] T3: recompute the enumerated claims in the M69/M70 notes.
- [ ] T4: recompute the enumerated claims in the remaining source notes and
      `INDEX.md`.
- [ ] T5: sweep the downstream consumers — for every ROADMAP candidate row,
      D-entry, or `ORACLES.md` entry resting on a claim this milestone
      narrowed or corrected, confirm the row still holds or escalate it as a
      review finding rather than editing it here.
- [ ] T6: run `cairn_validate` and the r-package `verify` slot; confirm the
      diff touches no package value.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-07-19: created by /milestone-plan alongside M73, re-cutting M71 after the thrash rule fired. Split from M73 at the plan gate on the sizing tripwire — the user asked for both interpretive-claim shapes in one milestone, but 87 dated observations plus a full-table recomputation of every generalizing claim across 30 notes exceeds the 1–3 session bar, and the two shapes take different remedies (a re-runnable command vs a recomputation). Planned now rather than deferred to a candidate row, with `Depends on: M73` so the enumeration can reuse M73's corpus tooling.
- 2026-07-20: started (in-progress), branch `m74-generalizing-claim-audit`. Question gate: enumeration recorded as a committed enumerator script; per-claim derivation basis inline in each note (both maintainer-confirmed).
- 2026-07-20: T1 done. Built `data-raw/enumerate-generalizing-claims.py` (finder + `--check` completeness gate + `--self-test`) and the committed triage ledger `data-raw/generalizing-claims-triage.tsv`. Enumerator recall net = superlative/quantifier/range shapes adjacent to a number, widened for bare decimal/table-cued ranges after it missed `xiao2013`'s "731–862/nine cells"; 234 candidates classified, `--check` green (0 un-triaged). Triage: 16 IN + 20 IN-done + 5 IN-consumer; 193 OUT across documented categories. Scope call recorded as MD-1 (repo synthesis notes + ORACLES pins + figure plot-reads + verbatim source quotes are OUT). `cairn_validate` exit 0.

## Decisions
<!-- owner: implement / review · append-only -->

### MD-1 (2026-07-20): Enumeration is a completeness-gated finder, not a claim-truth checker; and what the triage scopes out

The enumerator `data-raw/enumerate-generalizing-claims.py` re-runs the candidate
search (superlative / quantifier / range shapes adjacent to a number) and its
`--check` mode asserts every current candidate is classified in
`data-raw/generalizing-claims-triage.tsv` — an **enumeration-completeness** gate
for AC1 ("none skipped"), never a statement about a claim's correctness. Claim
truth is settled only by full-table recomputation recorded inline (D-009's
fence: M74 claims "need full-table recomputation, not an exit code").

Triage scope calls (reason recorded per ledger row). **OUT:** `ORACLES.md` pins
(claims about the repo's own committed coverage fixtures, test-enforced under
D-008; T5 still re-checks any that rest on a source claim M74 corrects); the two
repo **synthesis notes** (`npbootstrap-oneway-comparison`, `sem-multilevel-pilot`)
whose ranges are the repo's own analyses validated at M62/RR01 and the SEM pilot,
not external published source tables; **figure plot-reads** (no table to
recompute); and **verbatim / source-attributed** superlatives (the source's own
generalization, cited, not the note over-generalizing). **IN:** a note-authored
range / count / superlative over an external published source table in a
load-bearing section or relied on by a candidate / D-entry / `ORACLES.md` entry.

## Review
<!-- owner: review · exclusive -->
