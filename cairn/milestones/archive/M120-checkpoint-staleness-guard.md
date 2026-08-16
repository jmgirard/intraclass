# M120: Refuse a stale resume cache in the data-raw harnesses

**Status:** done (2026-08-15, PR #129 https://github.com/jmgirard/intraclass/pull/129)

**Goal:** Make every declared `data-raw/` resume harness refuse a checkpoint not
computed under the current design.

**Outcome:** `checkpoint-guard.R` writes a spec beside each cache — compared
parameters in declared order, plus a hash of the call closure of the declared
entry points and of declared non-function values — and refuses a mismatch naming
the earliest differing entry; `ckpt_store_save/get` compares per entry, so one
stale entry no longer discards ~720 valid Stan refits. A run-scoped `readRDS`
trace installed at `source()` aborts an unguarded read of a registered
checkpoint in whichever process performs it, recording bypasses as on-disk
markers that survive an `mclapply` fork. `check-checkpoint-sites.R` parses each
site in `checkpoint-sites.tsv`, reports a guard call nothing reaches, and plants
130 self-test mutations over the five — m111 and four never-run `oracle-bayesian-*`.

**Decisions:** two milestone-local — a multi-entry store file records only its
site, not a design spec; the block hash covers declared values, not only bodies.

**Review:** five passes, four defect returns. At return 4 the criteria narrowed
to what a stated procedure settles, the walk's unparked shapes and the watcher's
blind spots rowed as candidates rather than promised; pass five actioned A-F1
(97, `lintr` failing AC6's own gate), A-F3 (85) and A-F5 (82).
