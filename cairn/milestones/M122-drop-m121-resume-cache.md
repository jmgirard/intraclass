# M122: Remove the resume cache from the M121 npbootstrap sweep

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP7
- **Branch/PR:** —

## Goal

Delete the per-cell resume cache from `data-raw/m121-npbootstrap-skew-sweep.R`,
so no checkpoint can serve rows that were never verified against the current
input fixture.

## Scope

**Surface tier: internal.** The deliverable is a `data-raw/` research harness
and its site declaration; no external consumer of the package relies on either,
and nothing in `R/`, the exported API, or the shipped documentation changes.

**In:** removing the checkpoint read/write, `cell_spec()`, `ckpt_dir` and the
deserialization trace from the sweep; rewriting the comments that removal
falsifies; delisting the site from `data-raw/checkpoint-sites.tsv`; dropping the
`.gitignore` line and deleting the cache directory; a single-cell entry point,
used once to show the un-cached script still reproduces a committed row.

D-021 does not bar this: its untouched clause names "guards that pin a NUMERIC
result" and "repairs to existing checkers surfaced as ordinary work", and the
defect being closed is a silently-edited fixture endpoint served from cache as a
passing identity check.

**Out:**

- The other five declared checkpoint sites keep their caches — no change wanted;
  a removal at any of them would be its own milestone.
- The M120 guard (`data-raw/checkpoint-guard.R`), its CI demo, and
  `check-checkpoint-sites.R` are unchanged in behavior — this milestone delists
  one site, it does not modify the guard.
- Regenerating the full 64-cell coverage table → not done; AC5's single cell is
  the chosen evidence bar.
- The M120 candidate row's three known blind spots → unchanged, stay on the
  ROADMAP.
- The F7 half of the consumed candidate row (the truncation probe) → dropped as
  falsified, not deferred; see the work log.

## Acceptance criteria

- [ ] AC1 `grep -nE 'ckpt_(read|write|spec|trace_[a-z]+)\(|cell_spec|ckpt_dir|M121_CKPT_DIR' data-raw/m121-npbootstrap-skew-sweep.R`
      returns no match, while `source("data-raw/checkpoint-guard.R")` and the
      three `ckpt_read_input()` call sites remain — the fixture and anchor reads
      depend on them. `run_cell()` computes its cell from `cell_rows()` on every
      call and reads no prior result from disk.
- [ ] AC2 Every site matched by
      `grep -niE 'checkpoint|resume|routing walk' data-raw/m121-npbootstrap-skew-sweep.R data-raw/checkpoint-guard.R`
      is read, and each is either removed or rewritten to what the code now
      does — including `checkpoint-guard.R`'s `ckpt_read_input()` header, whose
      "(M121)" citation names a site that is no longer declared.
- [ ] AC3 `data-raw/checkpoint-sites.tsv` holds no row whose script field is
      `data-raw/m121-npbootstrap-skew-sweep.R`; `git diff` on that file shows one
      deleted line and nothing else, leaving the other five site rows and the
      `@deserializers` / `@appliers` / `@idioms` / `@mutations` directives
      untouched; `Rscript data-raw/check-checkpoint-sites.R` and
      `Rscript data-raw/check-checkpoint-sites.R --self-test` each exit 0.
- [ ] AC4 `.gitignore` names no `data-raw/m121-npbootstrap-checkpoints/` path,
      that directory is absent from the working tree, and `git status --porcelain`
      is empty at the end of the branch.
- [ ] AC5 One named grid cell, run end-to-end through T5's entry point on the
      changed script, reproduces its committed `npbootstrap` row in
      `data-raw/m121-npbootstrap-skew-coverage.tsv`: all fourteen committed
      columns match, compared as the strings `write_table()` formats
      (`formatC(digits = 10, format = "g")`), with `width_ratio_vs_mc` derived
      from the fixture's `mc` row for that cell as `build_table()` derives it.
      The Review records the cell id, the command, and that it matched — not the
      row's figures.
- [ ] AC6 `Rscript data-raw/m121-npbootstrap-skew-sweep.R --self-test` exits 0,
      and the profile's verify slot (`devtools::test()`, `air format --check .`,
      `lintr`) is clean. AC6 covers the self-test's probes; it does not cover the
      un-cached full-sweep path, which only AC5's cell exercises.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5, T6
- AC6 → T6

## Tasks

- [ ] T1 Remove the cache from `data-raw/m121-npbootstrap-skew-sweep.R`: delete
      `cell_spec()` (:540-560), the `ckpt_dir` binding (:66), `run_cell()`'s
      checkpoint read/write (:562-581), and `dir.create`/`ckpt_trace_register`
      (:974-975) plus `ckpt_trace_assert()` (:989). Keep the guard `source()`
      (:53) and `ckpt_read_input()` (:257, :684, :955).
- [ ] T2 Rewrite the falsified comments — the header's trace claim (:50-52),
      `cell_rows()`'s "travels with the rows into the checkpoint" (:473-474),
      `run_sweep()`'s routing-walk note (:951-952), and
      `data-raw/checkpoint-guard.R:365-372` — then run AC2's grep.
- [ ] T3 Delete the m121 row at `data-raw/checkpoint-sites.tsv:100`; run the
      checker and its `--self-test`.
- [ ] T4 Drop `.gitignore:18`; `rm -rf data-raw/m121-npbootstrap-checkpoints/`.
- [ ] T5 Add a `--one-cell=<id>` entry point: platform gate, one cell via
      `cell_rows()`, then that cell's published row from `one_group()` plus
      `width_ratio_vs_mc` derived as at :641. It skips `assert_anchors()` and
      `build_table()`, both of which are all-64-cells by construction (:628, :642).
- [ ] T6 Run T5 on a named cell and diff its row against the committed TSV; run
      `--self-test`, `air format .`, and the profile verify slot.

## Work log

- 2026-08-16: created by /milestone-plan.
- 2026-08-16: criteria audit ran twice ([O], fresh context, authored none of the criteria). Round 1 audited the digest approach: 8 findings, all five criteria unclean. Round 2 audited the removal approach: 9 findings — 7 fixed into the wording above, 1 dropped a criterion (F7), 1 a no-blocker D-021 note.
- 2026-08-16: plan gate chose removing the resume cache over adding a fixture-content digest to `cell_spec()`, at the maintainer's direction under the checker-regress shape (a digest would have been the second hardening pass over M120's machinery); falsified by a need to resume this sweep after an interruption, which now costs a full ~7 CPU-hour restart.
- 2026-08-16: plan gate chose re-running one named cell over a scope fence or a full 64-cell regeneration; the fence lost because the audit showed the drafted no-change criterion was satisfied by never touching the file; falsified by the one-cell row failing to reproduce, which would indict the removal rather than the criterion.
- 2026-08-16: F7 (the truncation probe) dropped as falsified, not deferred — the audit found no reachable input distinguishes a counted `n_compared` from an assumed one (`one_rep()` contributes exactly 2 per rep or aborts, :390-435), so the proposed real-cell probe would pass equally under the defect, and the hand-built cases it would replace cover an `n_endpoints`-short branch (:522-528) a real truncated cell cannot express; falsified by an input on which the two counts differ.

## Decisions

## Review
