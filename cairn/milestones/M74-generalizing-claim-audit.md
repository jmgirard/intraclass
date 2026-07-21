<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M74: Re-derive the generalizing claims over their full source tables

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** low   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M73   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m74-generalizing-claim-audit · https://github.com/jmgirard/intraclass/pull/80   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] The claims in scope are enumerated by a recorded, re-runnable search
      rather than by reading — the enumeration itself is reproducible, so a
      later reader can confirm none was skipped.
- [x] Every enumerated claim is recomputed over its full source table and
      confirmed, narrowed, or corrected in place.
- [x] Each recomputed claim records the basis of its derivation — which table,
      how many cells, what was computed — so the claim can be re-checked
      without redoing the reading.
- [x] No claim is left resting on the cells it happens to cite when the full
      table contradicts it — the specific defect this milestone exists to
      remove (M71 review attempts 2 and 3, findings F7/F8/F9 and F2/F3).
- [x] No package value changes: a correction that would move an oracle value,
      test fixture, or documented behavior is escalated as a review finding
      with its citation, not silently applied.
- [x] `cairn_validate` passes and the r-package `verify` slot is clean.

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
- [x] T2: recompute the enumerated claims in the seven M71 notes, starting
      with the two review already found false.
- [x] T3: recompute the enumerated claims in the M69/M70 notes.
- [x] T4: recompute the enumerated claims in the remaining source notes and
      `INDEX.md`.
- [x] T5: sweep the downstream consumers — for every ROADMAP candidate row,
      D-entry, or `ORACLES.md` entry resting on a claim this milestone
      narrowed or corrected, confirm the row still holds or escalate it as a
      review finding rather than editing it here.
- [x] T6: run `cairn_validate` and the r-package `verify` slot; confirm the
      diff touches no package value.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-07-19: created by /milestone-plan alongside M73, re-cutting M71 after the thrash rule fired. Split from M73 at the plan gate on the sizing tripwire — the user asked for both interpretive-claim shapes in one milestone, but 87 dated observations plus a full-table recomputation of every generalizing claim across 30 notes exceeds the 1–3 session bar, and the two shapes take different remedies (a re-runnable command vs a recomputation). Planned now rather than deferred to a candidate row, with `Depends on: M73` so the enumeration can reuse M73's corpus tooling.
- 2026-07-20: started (in-progress), branch `m74-generalizing-claim-audit`. Question gate: enumeration recorded as a committed enumerator script; per-claim derivation basis inline in each note (both maintainer-confirmed).
- 2026-07-20: T1 done. Built `data-raw/enumerate-generalizing-claims.py` (finder + `--check` completeness gate + `--self-test`) and the committed triage ledger `data-raw/generalizing-claims-triage.tsv`. Enumerator recall net = superlative/quantifier/range shapes adjacent to a number, widened for bare decimal/table-cued ranges after it missed `xiao2013`'s "731–862/nine cells"; 234 candidates classified, `--check` green (0 un-triaged). Triage: 16 IN + 20 IN-done + 5 IN-consumer; 193 OUT across documented categories. Scope call recorded as MD-1 (repo synthesis notes + ORACLES pins + figure plot-reads + verbatim source quotes are OUT). `cairn_validate` exit 0.
- 2026-07-20: T2 done (7 M71 notes). One CORRECTION: `saha2005` Table I worst-acceptance cell — recomputed over all 160 cells the max generated is 7695 (PNB/TNBD,m10,π.1,φ.2) → ~13 %, not 6609 → ~15 % (the small-φ boundary cells 6600/6609/6903 sit behind at ~14-15 %). One NARROWING: `mehta2018` Case 6 ICC 0.08 is the lowest true *ICC* in the M65 cluster (basis: cluster design-minima ranked; saha's φ 0.05 excluded as a binary dispersion parameter). CONFIRMED from full tables: `bobak2018` min 0.295 & pooled/homogenized ⊂ [0.609,0.706]; `saha2012` cross-note near-zero (φ .05 / xiao2009 ρ .1 / xiao2013 ρ .6, none hits boundary); `xiao2009` (36 PL cells ⊂ [.931,.950], GP range .913-.947, five lowest in K3/25 block); `bhandary2006` F_max ⊂ [.0165,.0414] over 27 cells; `xiao2013` Table 2 731-862 over 9 cells; `mehta2018` σ²_a Table-5 ordering. Ledger refreshed (236 candidates, +2 IN-basis derivation lines), `--check` green, `cairn_validate` exit 0. No package value changed. INDEX consumer of saha2005 worst-cell (~15 %) flagged for T5 update.

- 2026-07-20: T3+T4 done (non-M71 source notes + INDEX). One CORRECTION: `ukoumunne2003` worst transformed-bootstrap-t normal cell — recomputed `coverage = 100 − lower − upper` over all 12 Table I normal cells (`k ∈ {10,30,50}` × `ρ ∈ {.001,.01,.05,.3}`, p. 3815), the minimum is **0.9310 at k=30, ρ=0.001**, not 0.9320 at k=10 (which sits just above it); the paper's own p. 3814 sentence names "10 or 30 clusters". Not a package value (grep of R/tests/data-raw/man/vignettes for 0.932 is clean → AC5). CONFIRMED: `donner2002` ρ-floor 0.4 across all 3 tables (T3 pairs (.4,.6)/(.4,.7)/(.6,.8)) and highest of the five cluster papers (konishi/young/naik/bhandary all reach 0.1) — the line explicitly flagged "M74 territory"; `vanderark2023` coverage [0.934,0.956] over 24 cells; `naik2007`/`young1998` grids 0.1–0.9.
- 2026-07-20: T5 done (downstream sweep). No package value moved. Corrected saha2005 worst-cell (~13 %) restated once in `INDEX.md:81` (~15 %→~13 %). ukoumunne 0.9310, mehta 0.08, and saha2005 worst-cell have **no** ROADMAP-candidate / D-entry / `ORACLES.md` consumer (grep clean) — no escalation. Other INDEX consumers (trevethan 0.51–0.87, vanderark [0.934,0.956], xiao2009 0.931–0.950, saha2005 U-shape) are consistent with the confirmed notes. Ledger refreshed to 237 candidates (incl. IN-basis derivation lines + the reclassified donner2002 M74-territory line, previously auto-OUT by the check:none rule); `--check` green; `cairn_validate` exit 0.

- 2026-07-20: T6 done → status `review`. `cairn_validate` exit 0; r-package `verify` slot (`devtools::test()`, `CI=true` to skip the live-Stan brms fits an untouched-code change can't affect) clean — 0 failures, 0 errors, 2 pre-existing warnings. Branch diff touches only `cairn/`, the enumerator, the ledger, and `.gitignore` — no R/tests/man/data/vignettes (AC5). All six tasks complete.

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

**Fresh evidence — 2026-07-20 · PR #80 · branch `m74-generalizing-claim-audit`.**

- **AC1** (enumeration recorded, re-runnable, none skipped): `enumerate-generalizing-claims.py --self-test` → OK; `--check` → 237 candidates / 237 ledger rows / **0 un-triaged**. The finder regex + committed `generalizing-claims-triage.tsv` are the recorded search a reviewer re-runs. ✓
- **AC2** (every enumerated claim recomputed, confirmed/narrowed/corrected in place): all **45 IN-family** ledger rows carry a recorded M74 result — 2 CORRECTED (`saha2005`, `ukoumunne2003`), 1 NARROWED (`mehta2018`), the remainder CONFIRMED / M71-re-derived; 194 OUT rows each carry a category reason. ✓
- **AC3** (derivation basis recorded): each recompute records its basis inline — `saha2005` max over all 160 Table I cells; `ukoumunne2003` `coverage = 100 − lower − upper` over 12 cells; `mehta2018` cluster design-minima ranked — and in the ledger reason column. ✓
- **AC4** (no claim resting on cited cells when the full table contradicts): the two defects removed — `saha2005` worst-acceptance 6609/~15 % → **7695/~13 %** (the φ=0.2 cell was already in the transcribed table, ignored); `ukoumunne2003` worst cell 0.9320/k=10 → **0.9310/k=30**. ✓
- **AC5** (no package value changes; corrections cited, not silently applied): branch diff touches **0 package files** (only `cairn/`, enumerator, ledger, `.gitignore`); grep for `0.932` across `R/ tests/ man/` = 0 hits; each correction is recorded in-note with its table/page citation and a superseded-value note. ✓
- **AC6** (`cairn_validate` + `verify` slot): `cairn_validate` exit 0; `devtools::test()` **0 failures / 0 errors**; `devtools::document()` no diff; `.Rbuildignore` covers `^data-raw$`; authoritative full `R CMD check` runs on PR #80 CI (merge-gated green). ✓

**Consistency gate:** `cairn_validate` exit 0 (297 pre-existing dangling-id advisories, unchanged); r-package `consistency-gate` — `document()` no diff, new `data-raw/` files build-ignored, `devtools::test()` clean; full `R CMD check` deferred to PR CI (the merge gate). No `DESIGN.md` principle changed → `cairn_impact` skipped.
