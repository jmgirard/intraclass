# Decisions

Append-only. Never renumber; supersede with a new entry. D-entries record
choices with rationale — never deferrals ("not now" is a ROADMAP fact).

**Pre-migration decisions:** the full architecture-decision log (ADR-001..058,
~5000 lines) is entombed verbatim at
[`cairn/legacy/DECISIONS.md`](legacy/DECISIONS.md) and stays valid as a citation
target — source comments, tests, and tracking cite `ADR-0nn` into it. cairn's
`DECISIONS.md` starts fresh at D-001; still-governing legacy decisions are cited
by their `ADR-0nn` id rather than re-recorded (per the `/cairn-init` migration
pointer-only choice, 2026-07-12). New cross-cutting decisions are appended here.

<!-- New D-entries begin at D-001 (see decision.md template). -->
