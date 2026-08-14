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

demo_spec <- function(
  rho = 0.3,
  k = 10,
  n = 5,
  dist = "gaussian",
  n_rep = 2,
  base_seed = 1,
  block = "gen_demo",
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

# ---- AC3: a partially stale cache -------------------------------------------
# Early entries predate a design change and later ones do not. Guarding whole
# files cannot see this, so the guard specs each ENTRY.
cat("\n== AC3: a partially stale multi-entry cache ==\n")
part <- path_of("partial")
store <- ckpt_store_new()
store <- ckpt_store_put(store, "rep-1", gen_demo(0.3, 10), demo_spec())
store <- ckpt_store_put(store, "rep-2", gen_demo(0.6, 10), demo_spec(rho = 0.6))
ckpt_write(part, payload = store, spec = demo_spec(site = "demo-store"))
loaded <- ckpt_read(part, demo_spec(site = "demo-store"))
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

ckpt_trace_reset()
invisible(readRDS(p)) # the bare call the guard is meant to replace
expect_error(
  ckpt_trace_assert(),
  "a bare readRDS of a registered checkpoint fails the run",
  must_match = "bypassed the checkpoint guard"
)

ckpt_trace_reset()
invisible(base::readRDS(p)) # the namespace-qualified spelling
expect_error(
  ckpt_trace_assert(),
  "the base:: spelling is caught too — the trace watches loads, not spellings",
  must_match = "bypassed the checkpoint guard"
)

ckpt_trace_reset()
outside <- file.path(tempdir(), "unregistered.rds")
saveRDS(1, outside)
invisible(readRDS(outside))
ckpt_trace_assert()
pass("a read outside any registered checkpoint location is not flagged")

ckpt_trace_remove()
cat("\nAll M120 guard demonstrations passed.\n")
