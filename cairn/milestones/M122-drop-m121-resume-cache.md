# M122: Remove the resume cache from the M121 npbootstrap sweep

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP7
- **Branch/PR:** `m122-drop-m121-resume-cache` / https://github.com/jmgirard/intraclass/pull/131

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

- [x] AC1 `grep -nE 'ckpt_(read|write|spec|trace_[a-z]+)\(|cell_spec|ckpt_dir|M121_CKPT_DIR' data-raw/m121-npbootstrap-skew-sweep.R`
      returns no match, while `source("data-raw/checkpoint-guard.R")` and the
      three `ckpt_read_input()` call sites remain — the fixture and anchor reads
      depend on them. `run_cell()` computes its cell from `cell_rows()` on every
      call and reads no prior result from disk.
- [x] AC2 Every site matched by
      `grep -niE 'checkpoint|resume|routing walk' data-raw/m121-npbootstrap-skew-sweep.R data-raw/checkpoint-guard.R`
      is read, and each is either removed or rewritten to what the code now
      does — including `checkpoint-guard.R`'s `ckpt_read_input()` header, whose
      "(M121)" citation names a site that is no longer declared.
- [x] AC3 `data-raw/checkpoint-sites.tsv` holds no row whose script field is
      `data-raw/m121-npbootstrap-skew-sweep.R`; `git diff` on that file shows one
      deleted line and nothing else, leaving the other five site rows and the
      `@deserializers` / `@appliers` / `@idioms` / `@mutations` directives
      untouched; `Rscript data-raw/check-checkpoint-sites.R` and
      `Rscript data-raw/check-checkpoint-sites.R --self-test` each exit 0.
- [x] AC4 `.gitignore` names no `data-raw/m121-npbootstrap-checkpoints/` path,
      that directory is absent from the working tree, and `git status --porcelain`
      is empty at the end of the branch.
- [x] AC5 One named grid cell, run end-to-end through T5's entry point on the
      changed script, reproduces its committed `npbootstrap` row in
      `data-raw/m121-npbootstrap-skew-coverage.tsv`: all fourteen committed
      columns match, compared as the strings `write_table()` formats
      (`formatC(digits = 10, format = "g")`), with `width_ratio_vs_mc` derived
      from the fixture's `mc` row for that cell as `build_table()` derives it.
      The Review records the cell id, the command, and that it matched — not the
      row's figures.
- [x] AC6 `Rscript data-raw/m121-npbootstrap-skew-sweep.R --self-test` exits 0,
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

- [x] T1 Remove the cache from `data-raw/m121-npbootstrap-skew-sweep.R`: delete
      `cell_spec()` (:540-560), the `ckpt_dir` binding (:66), `run_cell()`'s
      checkpoint read/write (:562-581), and `dir.create`/`ckpt_trace_register`
      (:974-975) plus `ckpt_trace_assert()` (:989). Keep the guard `source()`
      (:53) and `ckpt_read_input()` (:257, :684, :955).
- [x] T2 Rewrite the falsified comments — the header's trace claim (:50-52),
      `cell_rows()`'s "travels with the rows into the checkpoint" (:473-474),
      `run_sweep()`'s routing-walk note (:951-952), and
      `data-raw/checkpoint-guard.R:365-372` — then run AC2's grep.
- [x] T3 Delete the m121 row at `data-raw/checkpoint-sites.tsv:100`; run the
      checker and its `--self-test`.
- [x] T4 Drop `.gitignore:18`; move `data-raw/m121-npbootstrap-checkpoints/` out
      of the repo (see the work log — the maintainer chose to archive it rather
      than delete it, which satisfies AC4 unchanged).
- [x] T5 Add a `--one-cell=<id>` entry point: platform gate, one cell via
      `cell_rows()`, then that cell's published row from `one_group()` plus
      `width_ratio_vs_mc` derived as at :641. It skips `assert_anchors()` and
      `build_table()`, both of which are all-64-cells by construction (:628, :642).
- [x] T6 Run T5 on a named cell and diff its row against the committed TSV; run
      `--self-test`, `air format .`, and the profile verify slot.

## Work log

- 2026-08-16: created by /milestone-plan.
- 2026-08-16: criteria audit ran twice ([O], fresh context, authored none of the criteria). Round 1 audited the digest approach: 8 findings, all five criteria unclean. Round 2 audited the removal approach: 9 findings — 7 fixed into the wording above, 1 dropped a criterion (F7), 1 a no-blocker D-021 note.
- 2026-08-16: plan gate chose removing the resume cache over adding a fixture-content digest to `cell_spec()`, at the maintainer's direction under the checker-regress shape (a digest would have been the second hardening pass over M120's machinery); falsified by a need to resume this sweep after an interruption, which now costs a full ~7 CPU-hour restart.
- 2026-08-16: plan gate chose re-running one named cell over a scope fence or a full 64-cell regeneration; the fence lost because the audit showed the drafted no-change criterion was satisfied by never touching the file; falsified by the one-cell row failing to reproduce, which would indict the removal rather than the criterion.
- 2026-08-16: T1-T2 — cache removed from the sweep: `cell_spec()`, the `ckpt_dir` binding, `run_cell()`'s read/write, `dir.create`/`ckpt_trace_register` and `ckpt_trace_assert()` all gone; `run_cell(cell, fx)` now recomputes unconditionally. Guard `source()` and the three `ckpt_read_input()` sites kept. Four falsified comments rewritten, plus `checkpoint-guard.R`'s `ckpt_read_input()` header, which after delisting has no declared-site caller at all.
- 2026-08-16: T3 — m121 row deleted from `checkpoint-sites.tsv` (`git diff`: one deletion, nothing else). Checker reports 5 declared sites and exits 0; its self-test plants 130 mutations over those 5 sites and detects each, exit 0.
- 2026-08-16: T4 — implementation gate: the cache directory held the only copy of the replicate-level rows (64 files, 3.3 MB, 128,000 intervals the committed TSV only aggregates), so deleting it outright would have discarded ~7 CPU-hours of unreproduced data. At the maintainer's direction it was moved to `~/m121-npbootstrap-checkpoints-archive` instead of deleted; AC4 is unchanged and still satisfied (absent from the tree, `.gitignore` line dropped).
- 2026-08-16: T5-T6 — `--one-cell=<id>` added; cell 4 (rho=0.05, k=10, n=5, chisq1) recomputed 2000 reps and matched all 14 committed columns. Falsified before being recorded: re-run against a copy of the table with `coverage_uncond` moved 0.939 -> 0.9391, the comparison aborts naming that one column and both values, so the match is discriminating rather than vacuous.
- 2026-08-16: verify slot clean — `devtools::test()` FAIL 0 / WARN 3 / SKIP 2 / PASS 7564 (the 3 warns are asserted-warning tests, not new), `air format --check .` exit 0, `lintr::lint_package()` 0 lints, `--self-test` exit 0.
- 2026-08-16: review — three lenses, 18 findings, scored by a fresh [S] scorer; 3 actioned (>=80) and fixed on the branch (F1 id normalization, F3 strict arg parsing after the space form was found to fall through to the destructive full sweep, F2 order of the committed-row lookup), plus F7 and F10 fixed below the bar with reasons recorded. No status return: no actioned finding fails a criterion inside its procedure's domain.
- 2026-08-16: CI's `check-references` job failed on the registered `roadmap-terminal-rows` claim; verified pre-existing by running the checker against a clean archive of `origin/main`, which fails identically — M121's hygiene pass rotated the row without updating the claim, leaving main red since that merge. Fixed as a trivial tracking commit on main (ac17aee), cherry-picked here.
- 2026-08-16: F7 (the truncation probe) dropped as falsified, not deferred — the audit found no reachable input distinguishes a counted `n_compared` from an assumed one (`one_rep()` contributes exactly 2 per rep or aborts, :390-435), so the proposed real-cell probe would pass equally under the defect, and the hand-built cases it would replace cover an `n_endpoints`-short branch (:522-528) a real truncated cell cannot express; falsified by an input on which the two counts differ.

## Decisions

## Review

Verified 2026-08-16 on `m122-drop-m121-resume-cache` at 8587f2a, PR #131.
All evidence re-run at review; none carried over from implement.

**AC1.** The forbidden-call grep returns no match (exit 1). `source("data-raw/checkpoint-guard.R")` present at :59. The three `ckpt_read_input()` call sites at `origin/main` (:257 anchor, :684 self-test, :955 run_sweep) all remain, now at :261, :779, :1049; T5's entry point adds a fourth at :692, which the criterion's "remain" does not exclude. `run_cell(cell, fx)` body read in full: `cell_rows()` then `cat()`, no filesystem read.

**AC2.** The grep matches 5 sites in the sweep — 3 are M122-authored prose describing the removal, 1 is the `source()` line, 1 the section header — and 45 in the guard file, all describing the guard itself, which is unchanged. Checked separately that no m121-specific claim survives in the guard beyond the M122 note at :370-373, and that no other file in the repo (outside tracking records) still calls m121 a checkpoint site.

**AC3.** No row matches the m121 script field (grep count 0). `git diff --numstat`: 0 additions, 1 deletion. All four `#@` directives present, and the diff touches none of them (0 `+`/`-` lines matching `^#@`). `check-checkpoint-sites.R` exit 0, reporting 5 declared sites; `--self-test` exit 0, planting 130 mutations over those 5 sites and detecting each.

**AC4.** `.gitignore` grep count 0. `data-raw/m121-npbootstrap-checkpoints/` absent from the tree (moved to `~/m121-npbootstrap-checkpoints-archive` at the maintainer's direction — the directory held the only copy of the replicate-level rows; AC4 asks for absence, not deletion). `git status --porcelain` empty after the final checkpoint commit.

**AC5.** `Rscript data-raw/m121-npbootstrap-skew-sweep.R --one-cell=4` on cell 4 (rho=0.05, k=10, n=5, chisq1): 2000 reps recomputed, 4000 rows / 8000 endpoints identity-checked, all 14 committed columns match. Discriminating, not vacuous: re-run against a copy of the table with `coverage_uncond` moved 0.939 -> 0.9391, the comparison aborts naming that one column and both values, so it fails for the claim's reason.

**AC6.** `--self-test` exit 0. `devtools::test()` FAIL 0 / WARN 3 / SKIP 2 / PASS 7564 (the warns are asserted-warning tests). `air format --check .` exit 0. `lintr::lint_package()` 0 lints.

**Consistency gate.** `cairn_validate` exit 0 — 16 checks PASS, 8 advisories OK. No `DESIGN.md` change, so `cairn_impact` does not apply. Profile `consistency-gate` slot: `devtools::document()` produces no diff; no user-visible surface touched (`R/`, `man/`, `NAMESPACE`, vignettes, README all unchanged) so no NEWS entry is owed; `devtools::check()` results below.

**Independent review — three lenses, then a scorer.** 18 findings reported (16 from the [O] diff-bug lens, 2 from the [S] blame-history lens); the [S] prior-review lens reported no prior-review evidence bearing on these files and zero findings, having read M120's and M121's archived `## Review` sections and probed the GitHub inline-comment surface, which is empty. A fresh [S] scorer that generated none of them scored each against the standard rubric.

*Actioned (>= 80), all three fixed on the branch:*
- **F1 (92)** — `--one-cell` normalized the id in `one_cell_row()` (`as.integer`) but compared the raw string in `compare_one_cell()`, so `--one-cell=04` selected cell 4, spent 2000 reps, then failed to find row "04". Fixed: the id is validated and normalized once, and that integer drives both lookups. Verified by driving it — `--one-cell=04` now reproduces cell 4 end-to-end.
- **F3 (85)** — `--one-cell 4`, the space form of a flag documented in `--flag=value` style, matched neither flag pattern and fell through to `run_sweep()`, which recomputes 64 cells for ~7 CPU-hours and overwrites the committed table. Fixed: `parse_args()` parses strictly and aborts on any unrecognized argument, on a duplicated `--one-cell`, and on two mode flags together. Each of those four forms was driven and aborts with its own message.
- **F2 (82)** — the committed row was resolved after the recompute, so a missing table or an out-of-grid id burned a full cell first. Fixed: the row is resolved before `one_cell_row()` is called; `--one-cell=999` now fails in under a second.

*Also fixed though below the bar, with reasons:*
- **F7 (72)** — two comments M122 authored cited line numbers five lines stale (pre-edit offsets). This is the branch-added-claims rule: they were composed from the old file rather than derived from the new one. Replaced with stable function-name references rather than re-pinned numbers, which would strand again on the next edit.
- **F10 (65)** — `compare_one_cell()` printed `n_compared`/`n_endpoints` as evidence without asserting them. Fixed: it now aborts unless they equal `n_rep * 2L` / `n_rep * 4L`, so the one-cell path asserts what it narrates, as the full sweep does. F5 (30) and F4 (55) were fixed incidentally by F1's validation and F3's strict parsing.

*Logged, not actioned (below 80):* F6 (48) the guard `source()` still installs a global `readRDS` trace, so "spec/trace machinery is unused" is loose though inert in effect; F8 (52) `format_row()` duplicates `write_table()`'s formatting with nothing enforcing the equivalence; F9 (45) the new functions are not exercised by `--self-test`; F11 (38) an `NA` in a future table would fail the string comparison spuriously, unreachable today; F14 (25) and F17 (28) residual-risk notes that this harness is now outside both checkpoint layers and that `ckpt_read_input()` outlives its declared caller — both consistent with Scope; F18 (28) the cache directory was archived rather than deleted, self-disclosed above; F12 (15), F13 (12), F15 (22), F16 (20) judged to rest on mistaken or transient premises by the scorer.

**CI, and a red `main` found in passing.** The first CI run failed `check-references`: the registered claim `roadmap-terminal-rows` expected `M118, M117, M116, M119, M120` while the ROADMAP's table holds `M118, M117, M119, M120, M121`. Verified pre-existing rather than introduced here by running the same checker against a clean `git archive` of `origin/main`, where it fails identically — M121's post-merge hygiene rotated M116 out and added M121 without updating the claim or the retention note, so `main` had been red on that job since that merge. The ROADMAP table was correct; the record of it was not, which is what the checker's own message says to fix. Corrected as a trivial tracking commit directly on `main` (`ac17aee`) at its proper tier rather than folded into this milestone's diff, then cherry-picked onto the branch so this PR's CI could go green. `check-record-claims.py` and its `--self-test` both exit 0 afterward.

*Return floor.* No actioned finding demonstrates an acceptance criterion failing inside its named procedure's domain, and none is a >= 90 defect in what the package computes for its users — F1's 92 is against an internal `data-raw/` harness flag. All three took the fix-now triage; no status return.
