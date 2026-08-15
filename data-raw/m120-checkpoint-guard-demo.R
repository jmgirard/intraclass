# M120 — demonstrations that the checkpoint staleness guard actually fires.
#
# Every case writes its own cache into a tempdir, so nothing here can reach a
# committed fixture (the AC5 fence) or a real checkpoint directory. Each planted
# defect form AC3 names gets its own case, and each is paired with a clean case
# that must pass, so a guard that has quietly stopped discriminating is visible
# here rather than in a silent fixture.
#
#   Rscript data-raw/m120-checkpoint-guard-demo.R      (seconds; no model fits)

source("data-raw/checkpoint-guard.R")

pass <- function(label) cat("PASS  ", label, "\n", sep = "")

expect_error <- function(expr, label, must_match = NULL) {
  e <- tryCatch(
    {
      force(expr)
      NULL
    },
    error = identity
  )
  if (is.null(e)) {
    stop("expected an error but none was signalled: ", label)
  }
  msg <- conditionMessage(e)
  if (!is.null(must_match) && !grepl(must_match, msg, fixed = TRUE)) {
    stop(
      "error fired but did not name the expected mismatch: ",
      label,
      "\n  wanted (fixed): ",
      must_match,
      "\n  got:            ",
      msg
    )
  }
  cat("PASS  ", label, "\n        error: ", msg, "\n", sep = "")
}

tmp <- tempfile("m120-demo-")
dir.create(tmp)
path_of <- function(nm) file.path(tmp, paste0(nm, ".rds"))

# The demo's stand-in site: a declared parameter order and a declared generating
# block, exactly the shape checkpoint-sites.tsv declares for a real site.
gen_demo <- function(rho, k) {
  rho * seq_len(k)
}
helper_outside_block <- function(x) x
# A declared VALUE in the block, not a function: seed offsets, sampler argument
# lists and model formulas all decide cached numbers without being functions.
demo_offsets <- c(a = 0L, b = 100L)

demo_spec <- function(
  rho = 0.3,
  k = 10,
  n = 5,
  dist = "gaussian",
  n_rep = 2,
  base_seed = 1,
  block = c("gen_demo", "demo_offsets"),
  site = "demo"
) {
  ckpt_spec(
    params = list(
      rho = rho,
      k = k,
      n = n,
      dist = dist,
      n_rep = n_rep,
      base_seed = base_seed
    ),
    block = block,
    site = site
  )
}

# ---- AC1: parameter mismatch, one parameter at a time -----------------------
cat("\n== AC1: each declared parameter, mismatching individually ==\n")

p <- path_of("params")
ckpt_write(p, payload = gen_demo(0.3, 10), spec = demo_spec())
stopifnot(identical(ckpt_read(p, demo_spec()), gen_demo(0.3, 10)))
pass("a cache whose spec matches resumes and returns the cached payload")

expect_error(
  ckpt_read(p, demo_spec(rho = 0.6)),
  "a changed rho is refused and named",
  must_match = "rho"
)
expect_error(
  ckpt_read(p, demo_spec(dist = "t5")),
  "a changed dist is refused and named",
  must_match = "dist"
)

# The naming rule is ORDER-sensitive, not set-sensitive: with two parameters
# differing at once the message names the earlier one in DECLARED order.
expect_error(
  ckpt_read(p, demo_spec(dist = "t5", base_seed = 99)),
  "two mismatches name the earliest in declared order (dist before base_seed)",
  must_match = "dist"
)
expect_error(
  ckpt_read(p, demo_spec(rho = 0.6, dist = "t5")),
  "two mismatches name the earliest in declared order (rho before dist)",
  must_match = "rho"
)

# ---- AC1: an empty spec is a defect, not a free pass ------------------------
cat("\n== AC1: a spec recording no parameters is refused at WRITE time ==\n")
expect_error(
  ckpt_spec(params = list(), block = "gen_demo", site = "demo"),
  "a spec with no declared parameters cannot be constructed",
  must_match = "no declared parameters"
)

# ---- AC3: a cache carrying no spec at all (every pre-existing file) ---------
cat("\n== AC3: an unspecced cache (the pre-existing on-disk case) ==\n")
bare <- path_of("bare")
saveRDS(gen_demo(0.3, 10), bare) # written the old way, before this guard existed
expect_error(
  ckpt_read(bare, demo_spec()),
  "a cache written before the guard existed is refused, not trusted",
  must_match = "no recorded spec"
)

# ---- AC3: a cache written by a DIFFERENT site at the same path --------------
cat("\n== AC3: a foreign cache at the expected path ==\n")
foreign <- path_of("foreign")
ckpt_write(
  foreign,
  payload = gen_demo(0.3, 10),
  spec = demo_spec(site = "other-site")
)
expect_error(
  ckpt_read(foreign, demo_spec()),
  "a cache written by another site is refused and the site named",
  must_match = "other-site"
)

# ---- AC3: generating-block drift with every parameter still matching --------
cat("\n== AC3: the generating block changed, parameters identical ==\n")
drift <- path_of("drift")
ckpt_write(drift, payload = gen_demo(0.3, 10), spec = demo_spec())
gen_demo <- function(rho, k) {
  rho * seq_len(k) + 1 # the generator changes
}
expect_error(
  ckpt_read(drift, demo_spec()),
  "a changed generating block is refused though every parameter matches",
  must_match = "generating block"
)

# The counterweight: the hash must not be so wide that every cache is always
# stale, which is what a whole-file fingerprint would give. Two edits that
# change no cached row leave it usable — a comment added inside a block
# function (comments are not part of the parsed body), and any change to a
# function the site did not declare.
gen_demo <- function(rho, k) {
  # a note to the next reader, changing nothing
  rho * seq_len(k)
}
helper_outside_block <- function(x) x + 1000
stopifnot(identical(ckpt_read(drift, demo_spec()), gen_demo(0.3, 10)))
pass(
  "a comment inside the block, and an edit outside it, keep the cache usable"
)

# A declared block entry that is a VALUE, not a function, is hashed the same
# way: the seed offsets and sampler arguments the oracle sites declare decide
# their cached numbers without being functions.
demo_offsets <- c(a = 0L, b = 200L)
expect_error(
  ckpt_read(drift, demo_spec()),
  "a changed declared VALUE in the block is refused like a changed function",
  must_match = "generating block"
)
demo_offsets <- c(a = 0L, b = 100L)
stopifnot(identical(ckpt_read(drift, demo_spec()), gen_demo(0.3, 10)))
pass("restoring the declared value makes the cache usable again")

# A declared block name that no longer exists is "not found", never silently
# resolved to a same-named function further up the search path. Two real sites
# declare a block function named `simulate`, which stats:: also exports: without
# this the hash would quietly track stats::simulate forever after a rename.
simulate <- function(design) design
stopifnot(is.function(stats::simulate)) # the stranger that must not be reached
stopifnot(nzchar(demo_spec(block = c("gen_demo", "simulate"))$block_hash))
pass("the site's own block function is found while it exists")
rm(simulate) # the rename: the site's own function is gone
expect_error(
  demo_spec(block = c("gen_demo", "simulate")),
  "a renamed block function is 'not found', not resolved to stats::simulate",
  must_match = "declared block entry not found: simulate"
)

# ---- AC3: a partially stale cache -------------------------------------------
# Early entries predate a design change and later ones do not. Guarding whole
# files cannot see this, so the guard specs each ENTRY.
# The file itself carries no design spec — only which site wrote it. A
# file-level design spec would have to be some entry's spec, and it would then
# fire before the per-entry check ever ran, leaving the per-entry machinery
# inert and discarding every valid sibling of the one edited entry.
cat("\n== AC3: a partially stale multi-entry cache ==\n")
part <- path_of("partial")
store <- ckpt_store_new("demo-store")
store <- ckpt_store_put(store, "rep-1", gen_demo(0.3, 10), demo_spec())
store <- ckpt_store_put(store, "rep-2", gen_demo(0.6, 10), demo_spec(rho = 0.6))
ckpt_store_save(part, store)
loaded <- ckpt_store_load(part, "demo-store")
stopifnot(identical(
  ckpt_store_get(loaded, "rep-1", demo_spec()),
  gen_demo(0.3, 10)
))
pass("the entry computed under the current design is served")
expect_error(
  ckpt_store_get(loaded, "rep-2", demo_spec()),
  "the sibling entry computed under a superseded design is refused",
  must_match = "rho"
)

# The file-level question a file-level record CAN answer: is this cache ours?
expect_error(
  ckpt_store_load(part, "another-site"),
  "a store written by another site is refused and both sites named",
  must_match = "recorded 'demo-store', current 'another-site'"
)
expect_error(
  ckpt_store_load(bare, "demo-store"),
  "a file that is not a guarded store at all is refused, not trusted",
  must_match = "not a guarded checkpoint store"
)

# ---- AC2: the run-scoped trace ----------------------------------------------
cat("\n== AC2: unguarded deserialization of a registered checkpoint ==\n")
ckpt_trace_install()
ckpt_trace_register(tmp)

ckpt_trace_reset()
invisible(ckpt_read(p, demo_spec()))
ckpt_trace_assert()
pass(
  "a run whose every checkpoint read went through the guard passes the trace"
)

# The abort lands AT THE READ, in whichever process performed it -- not only at
# the end-of-run assertion. M111 maps its cells with mclapply, and a forked
# worker's trace state never returns to the parent, so a parent-only check would
# pass vacuously over exactly the harness this guard exists for.
ckpt_trace_reset()
expect_error(
  readRDS(p), # the bare call the guard is meant to replace
  "a bare readRDS of a registered checkpoint aborts at the read",
  must_match = "bypassed the checkpoint guard"
)

ckpt_trace_reset()
expect_error(
  base::readRDS(p), # the namespace-qualified spelling
  "the base:: spelling is caught too — the trace watches loads, not spellings",
  must_match = "bypassed the checkpoint guard"
)

# And the end-of-run assertion still reports a bypass that was caught and
# swallowed by a caller's tryCatch rather than allowed to kill the run.
#
# The guarded read FIRST, with no reset between, is the point of this case: a
# real run reads each checkpoint through the guard before anything bypasses it,
# and a trace that recorded paths and subtracted the guarded ones would let that
# legitimate read cancel the bypass that follows it. Nothing is reset here.
ckpt_trace_reset()
invisible(ckpt_read(p, demo_spec()))
invisible(tryCatch(readRDS(p), error = function(e) NULL))
expect_error(
  ckpt_trace_assert(),
  "a bypass swallowed by a tryCatch is reported even after a guarded read of the same path",
  must_match = "bypassed the checkpoint guard"
)

ckpt_trace_reset()
outside <- file.path(tempdir(), "unregistered.rds")
saveRDS(1, outside)
invisible(readRDS(outside))
ckpt_trace_assert()
pass("a read outside any registered checkpoint location is not flagged")

ckpt_trace_remove()

# ---- AC3/AC4 on a REAL site --------------------------------------------------
# Everything above runs against a stand-in site. This section runs the M111
# sweep itself, at n_rep = 2 and with both its paths redirected into a tempdir,
# so the guard is exercised on the harness the defect was found in rather than
# only on a model of it. The four oracle sites share this code path but each
# needs brms/Stan and hours of refits, so they are covered by the routing check
# (data-raw/check-checkpoint-sites.py), not by a run here.
cat("\n== AC3/AC4: the M111 sweep, end to end at n_rep = 2 ==\n")

site_tmp <- tempfile("m120-m111-")
dir.create(site_tmp)
Sys.setenv(
  M111_CKPT_DIR = file.path(site_tmp, "ckpt"),
  M111_RESULTS_OUT = file.path(site_tmp, "results.rds")
)
source("data-raw/m111-fallback-sweep.R")

dir.create(ckpt_dir, recursive = TRUE, showWarnings = FALSE)
ckpt_trace_install()
ckpt_trace_register(ckpt_dir)
ckpt_trace_reset()

cells <- build_cells(n_rep = 2L)
cell <- cells[[1]]
first <- run_cell(cell) # computes and writes
again <- run_cell(cell) # resumes through the guard
stopifnot(identical(first, again))
ckpt_trace_assert()
pass("a completed cell resumes from its checkpoint and the trace stays clean")

# The candidate row's scenario: build_cells() is edited and the sweep re-run.
# The cell id is unchanged, so the old file is still found at the same path.
stale_cell <- cell
stale_cell$rho <- 0.60
expect_error(
  run_cell(stale_cell),
  "a re-run after editing build_cells() is refused, not served from the old grid",
  must_match = "rho changed"
)

# THE fork case for the trace, and the reason the trace aborts at the read
# rather than only at the end-of-run assertion: M111 maps its cells with
# parallel::mclapply, and a forked worker's trace state dies with the worker, so
# a parent-side assertion cannot see a worker's reads at all. The read here is a
# bare readRDS of a VALID registered checkpoint -- the spec check would accept
# this file, so nothing but the trace can refuse it, and it must do so inside
# the worker.
cat("\n== AC2: a bare readRDS inside an mclapply worker ==\n")
valid_cell <- file.path(ckpt_dir, "cell-01.rds")
stopifnot(file.exists(valid_cell))
stopifnot(!is.null(ckpt_read(valid_cell, cell_spec(cell)))) # the spec accepts it
forked <- parallel::mclapply(
  1:2,
  function(i) if (i == 2L) readRDS(valid_cell) else "no read",
  mc.cores = 2L
)
fork_msgs <- vapply(
  forked,
  function(r) {
    if (inherits(r, "try-error")) conditionMessage(attr(r, "condition")) else ""
  },
  character(1)
)
stopifnot(any(grepl("bypassed the checkpoint guard", fork_msgs, fixed = TRUE)))
stopifnot(!nzchar(fork_msgs[1])) # the worker that read nothing is untouched
pass(
  "a bare readRDS inside a forked worker aborts in that worker, on a checkpoint the spec check would have accepted"
)

# And the spec check reaches inside a worker too: a stale checkpoint must be
# refused there and surface to the parent as that cell's failure.
cat("\n== AC2: a stale checkpoint refused inside an mclapply worker ==\n")
saveRDS(list(nonsense = TRUE), file.path(ckpt_dir, "cell-02.rds"))
worker_results <- parallel::mclapply(cells[1:2], run_cell, mc.cores = 2L)
worker_msgs <- vapply(
  worker_results,
  function(r) {
    if (inherits(r, "try-error")) conditionMessage(attr(r, "condition")) else ""
  },
  character(1)
)
stopifnot(any(grepl("stale-checkpoint guard", worker_msgs, fixed = TRUE)))
pass("a forked worker refuses the stale cell rather than returning its rows")
expect_error(
  assert_sweep_results(worker_results, cells[1:2]),
  "the refusal surfaces to the parent as a failed cell, before any fixture write",
  must_match = "cells errored"
)

ckpt_trace_remove()
cat("\nAll M120 guard demonstrations passed.\n")
