# M67: Source notes — the ICC-equality-testing cluster (done 2026-07-19)

**Goal.** Ingest the four ICC-equality-testing papers as short source notes that
also document *why* hypothesis tests comparing ICCs sit outside the contract.

**Outcome.** Four notes shipped — `donner2002` (dependent ICCs, same subjects,
two observer panels), `konishi1989` (general `q`-population approximate LRT),
`young1998` (two populations, unequal family sizes), `naik2007` (`g` populations,
unequal sizes *and* variances). Each carries a `## Boundary (IP2)` section stating
the exclusion and that adopting such a test needs a constitutional amendment, not
a feature request. `DESIGN.md`'s IP2 gained a pointer sentence naming the cluster
as its citable record (no D-entry owed — `cairn_impact --changed` reports no
principle changed). `bhandary2006` gained a reciprocal cross-reference as a fifth
member. Nothing traces to them (by command); shelf fully ingested, 30 notes.

**Key findings.** The unequal-family-size pair **disagree** and must not be cited
as concordant: `young1998` recommends the LRT; `naik2007` (p. 6503) reports that
same Srivastava-into-LRT substitution yielding a negative `−2 log Λ` on up to 25 %
of samples, recommending the score test or `T₀`. It misprints Huang as "Haung".

**Two review attempts.** Attempt 1: AC7 failed (undated absence assertions) plus
five findings. Attempt 2 passed all seven criteria but found three more — two
further altered quotations the sweep missed, one mislabeled anchor; all fixed on
the branch. Notes ship `unverified`, still on the re-verify backlog. PR
https://github.com/jmgirard/intraclass/pull/75 (squash `8a66b60`).
