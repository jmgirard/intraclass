# M74: Re-derive the generalizing claims over their full source tables

**Status:** done (2026-07-21, PR #80 https://github.com/jmgirard/intraclass/pull/80)

**Goal:** Re-derive every references-page claim that generalizes from cited cells to a range, count, or superlative against the full source table it summarizes.

**Outcome:** Recomputed every relied-upon generalizing claim across the references corpus over its full published table. Two corrections: `saha2005` Table I worst-acceptance ~15 % (6609) → ~13 % (7695, the max generated over all 160 cells); `ukoumunne2003` worst transformed-bootstrap-t normal cell 0.9320 (k=10) → 0.9310 (k=30), the min of 100−lower−upper over 12 cells. One narrowing: `mehta2018` Case 6 = lowest true *ICC* in the cluster (saha's φ excluded as a binary beta-binomial dispersion parameter, not a Gaussian ICC). Confirmed over their full tables: `donner2002` (the flagged M74-territory floor-of-five), `bobak2018`, `saha2012`, `xiao2009`, `bhandary2006`, `xiao2013`, `vanderark2023`, `naik2007`, `young1998`. One downstream fix: `INDEX.md` saha2005 restatement (~15 %→~13 %); no candidate/D-entry/`ORACLES.md` rested on a corrected claim. Ships `data-raw/enumerate-generalizing-claims.py` (finder + `--check` completeness/orphan gate + `--self-test`) and `data-raw/generalizing-claims-triage.tsv` (237 candidates, 43 IN-family / 194 OUT, each with a recorded reason). No package value changed.

**Decisions:** MD-1 — the enumerator `--check` is an enumeration-completeness gate (AC1), never a claim-truth checker (D-009's fence: M74 claims need full-table recomputation, not an exit code); triage scopes OUT repo synthesis notes, `ORACLES.md` pins, figure plot-reads, and verbatim/source-attributed superlatives.

**Review:** Three fresh-context lenses (diff-bug [O], blame-history [S], prior-review [S]) — no formal findings; both corrections independently re-verified against the source PDFs. Two non-blocking observations actioned at author discretion: synced `saha2005` Table I bolding to 7695; hardened `--check` with orphan-row detection.
