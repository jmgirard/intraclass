# M125: Bring ROADMAP.md and LESSONS.md back under their byte budgets

**Status:** done (2026-08-17, PR #134 https://github.com/jmgirard/intraclass/pull/134)

**Goal:** Bring `cairn/ROADMAP.md` and `cairn/LESSONS.md` back under their tracking-rules byte budgets without losing a live promotion condition, falsifier, or durable gotcha.

**Outcome:** ROADMAP.md 33,857 → 23,540 bytes / 52 lines; LESSONS.md 35,296 → 19,703 / 44. Five shipped struck-through candidate rows deleted, each dispositioned to its
archive (M117/M118/M120/M122) or superseding record (D-011/M78); the M122 row's digest-shape audit findings migrated into the checkpoint blind-spots row. The eight
widest live rows compressed to promotion condition + falsifier + lineage, full pre-compression text at commit 52573c0. Five LESSONS families graduated under the
maturation exit: the procedural-set family (M70/M110/M118/M124) → DESIGN.md **GP8**; the degenerate-guard / platform-arithmetic family (M84/M103/M105) → **GP9**; the
doc-claim-pin family (M115/M116/M118/M123) → `cairn/doctrine/doc-claim-pins.md`; the check-references checker family (M85/M91/M97/M104/M105/M111) →
`cairn/doctrine/data-raw-checkers.md`; the PDF-ingestion family (M66/M67) → `cairn/doctrine/source-ingestion.md`. Six extension blocks compressed in place.

**Decisions:** D-033 (`cairn/doctrine/` is a records home for graduated lesson families; GP8/GP9 join DESIGN.md). None milestone-local.

**Review:** Single [O] diff-bug lens (internal tier, docs-only diff): 20 ranked findings, none at the return floor; 17 fixed at the gate (GP9 fidelity, orphaned pages,
over-promising archive pointers, restored specifics, a false compression uniform), 3 rejected with reasons (intentional compression; accurate-at-commit figure; AC5's
enumeration reach). Checks: cairn_validate 16 PASS, four data-raw checkers green, devtools::check() 0/0/0, CI green. Hygiene: struck M125 candidate row deleted as
shipped here; terminal rows rotated M120 → out, record-claims expectation updated in the same commit.
