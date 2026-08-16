# M122: Remove the resume cache from the M121 npbootstrap sweep

**Status:** done (2026-08-16, PR #131 https://github.com/jmgirard/intraclass/pull/131)

**Goal:** Delete the per-cell resume cache from
`data-raw/m121-npbootstrap-skew-sweep.R`, so no checkpoint can serve rows never
verified against the current input fixture.

**Outcome:** `cell_spec()`, `ckpt_dir`, `run_cell()`'s checkpoint read/write and
the `ckpt_trace_register`/`ckpt_trace_assert` calls are gone; `run_cell()`
recomputes unconditionally. The site is delisted from `checkpoint-sites.tsv` (5
remain) and its `.gitignore` entry dropped. New `--one-cell=<id>` recomputes one
cell and compares its published row via `one_group()` plus a `width_ratio_vs_mc`
from the fixture's `mc` row, behind a strict `parse_args()` so no near-miss flag
reaches the destructive full sweep. `ckpt_read_input()` stays, callerless.

**Decisions:** none milestone-local; D-021 cleared at the plan gate under its
untouched clause.

**Review:** Three lenses, 18 findings; three actioned, all fixed and each fix
driven — F1 (92) id normalized in one place but compared raw in the other, F3
(85) `--one-cell 4` fell through to the sweep and would have overwritten the
committed table, F2 (82) the row resolved after the recompute. F7/F10 fixed
below the bar, 11 logged. CI surfaced a `check-references` failure proven
pre-existing on `main` (M121 rotated a terminal row, not its claim).
