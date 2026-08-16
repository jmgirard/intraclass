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

# Bound HERE, AFTER the guard is sourced: trace() rebinds the name, so an alias
# takes a copy of whatever readRDS was at BIND time. Bound after the source(),
# the copy is the traced function and the alias is caught. An alias bound BEFORE
# the source() copies the untraced original and is never caught -- that form is
# outside AC3's enumeration, and the subprocess case near the end of this script
# demonstrates it escaping rather than leaving the boundary asserted. It is not
# hypothetical: m111-fallback-sweep.R sources the m76 prototype before the
# guard, and every oracle site runs pkgload::load_all() and library(brms) first.
aliased_read <- readRDS

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
  roots = "gen_demo",
  values = "demo_offsets",
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
    roots = roots,
    values = values,
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
  ckpt_spec(params = list(), roots = "gen_demo", site = "demo"),
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

# The hashed block is DERIVED, not hand-listed: a helper the entry point calls
# is covered without anyone declaring it. This is the failure the hand-listed
# form actually produced — one site's list was missing two functions that decide
# its cached numbers, and nothing could notice.
cat("\n== AC3: a helper nobody declared is still covered ==\n")
undeclared_helper <- function(x) x * 1
gen_via_helper <- function(rho, k) undeclared_helper(rho * seq_len(k))
helper_spec <- function() {
  ckpt_spec(
    params = list(rho = 0.3, k = 10),
    roots = "gen_via_helper", # the helper is NOT declared anywhere
    site = "demo-closure"
  )
}
closure_path <- path_of("closure")
ckpt_write(
  closure_path,
  payload = gen_via_helper(0.3, 10),
  spec = helper_spec()
)
stopifnot(identical(
  ckpt_read(closure_path, helper_spec()),
  gen_via_helper(0.3, 10)
))
pass("a cache written under the current helper resumes")
undeclared_helper <- function(x) x * 2 # the helper changes; nothing declares it
expect_error(
  ckpt_read(closure_path, helper_spec()),
  "editing an undeclared helper the entry point calls still invalidates the cache",
  must_match = "generating block"
)
undeclared_helper <- function(x) x * 1

# A determinant reached by VARIABLE CAPTURE, not by a call: the value is
# computed at top level from a site function and then referenced inside the
# entry point. This is the form that shipped uncovered — editing the estimand
# helper left the hash byte-identical on two oracle sites — because the walk
# collected call heads only.
cat("\n== AC1: a determinant reached by variable capture ==\n")
capture_helper <- function(kind) list(kind = kind, weight = 1)
captured_est <- capture_helper("agreement")
gen_via_capture <- function(rho, k) rho * seq_len(k) * captured_est$weight
capture_spec <- function() {
  ckpt_spec(
    params = list(rho = 0.3, k = 10),
    roots = "gen_via_capture",
    values = "captured_est",
    site = "demo-capture"
  )
}
cap_path <- path_of("capture")
ckpt_write(cap_path, payload = gen_via_capture(0.3, 10), spec = capture_spec())
stopifnot(identical(
  ckpt_read(cap_path, capture_spec()),
  gen_via_capture(0.3, 10)
))
pass("a cache written under the current captured value resumes")
captured_est <- capture_helper("consistency") # the estimand changes
expect_error(
  ckpt_read(cap_path, capture_spec()),
  "editing a determinant reached by variable capture invalidates the cache",
  must_match = "generating block"
)
captured_est <- capture_helper("agreement")

# And an uncovered one is refused at construction, by name, rather than hashed
# silently or skipped silently.
cat("\n== AC1: an uncovered determinant is named, not skipped ==\n")
expect_error(
  ckpt_spec(
    params = list(rho = 0.3, k = 10),
    roots = "gen_via_capture",
    site = "demo-capture"
  ),
  "a determinant that is neither hashed nor declared aborts naming itself",
  must_match = "captured_est"
)

# A local shadowing a top-level name is not a dependency on it.
cat("\n== AC1: a local shadowing a top-level binding ==\n")
shadowed <- "top-level value nobody reads"
gen_with_shadow <- function(rho, k) {
  shadowed <- rho * seq_len(k)
  shadowed
}
stopifnot(nzchar(
  ckpt_spec(
    params = list(rho = 0.3, k = 10),
    roots = "gen_with_shadow",
    site = "demo-shadow"
  )$block_hash
))
pass("a local shadowing a top-level binding is not reported as a determinant")

# ---- AC1: the run-time and the static walk, pinned against each other -------
# ckpt_spec() walks LIVE BINDINGS; the routing checker walks PARSED SOURCE. Four
# of the five real sites need brms/Stan and hours of refits, so the static walk
# is the only one that ever reaches them -- which means nothing about the real
# sites can show the two walks answer alike. This synthetic site can, and it
# carries one instance of each class the walk must classify: a captured value, a
# captured function, a shadowed local, an exempted object and a declared
# parameter.
cat("\n== AC1: the run-time and static generating walks agree ==\n")

syn_path <- "data-raw/m120-synthetic-site.R"
syn_roots <- "syn_one_rep"
syn_values <- "syn_est"
syn_params <- "syn_rho"
syn_exempt <- "syn_base_fit"

checker <- new.env(parent = globalenv())
sys.source("data-raw/check-checkpoint-sites.R", envir = checker)

syn_source <- function(path) {
  e <- new.env(parent = globalenv())
  sys.source(path, envir = e)
  e
}
syn_env <- syn_source(syn_path)

runtime_scan <- ckpt_block_scan(
  syn_roots,
  syn_values,
  syn_params,
  syn_exempt,
  envir = syn_env
)
static_scan <- checker$static_scan_file(
  syn_path,
  syn_roots,
  syn_values,
  syn_params,
  syn_exempt
)
stopifnot(identical(runtime_scan$fns, static_scan$fns))
stopifnot(identical(runtime_scan$uncovered, static_scan$uncovered))
# Not vacuous: the walk reached the entry point AND the function captured by
# name rather than called, and left nothing uncovered.
stopifnot(identical(runtime_scan$fns, c("syn_one_rep", "syn_scale")))
stopifnot(!length(runtime_scan$uncovered))
pass("both walks hash the same functions and report nothing uncovered")

# Withdraw the declarations and both walks name the same two determinants -- the
# captured value and the exempted object -- and neither names the shadowed
# local, whose top-level namesake the entry point never reads.
runtime_bare <- ckpt_block_scan(
  syn_roots,
  character(0),
  syn_params,
  character(0),
  envir = syn_env
)
static_bare <- checker$static_scan_file(
  syn_path,
  syn_roots,
  character(0),
  syn_params,
  character(0)
)
stopifnot(identical(runtime_bare$uncovered, static_bare$uncovered))
stopifnot(identical(runtime_bare$uncovered, c("syn_base_fit", "syn_est")))
stopifnot(!("syn_shadowed" %in% runtime_bare$uncovered))
pass(
  "both walks name the same undeclared determinants, and neither names the shadowed local"
)

expect_error(
  ckpt_spec(
    params = list(syn_rho = syn_env$syn_rho),
    roots = syn_roots,
    site = "synthetic",
    envir = syn_env
  ),
  "removing a determinant's declaration refuses the spec, naming it",
  must_match = "syn_est"
)

# And the determinant reached by capture really does decide the hash. The edit
# is made to the SOURCE and re-sourced, because that is the edit the shipped
# hole survived: `est_occ` sits outside the hashed closure on two oracle sites,
# and editing it left the block hash byte-identical.
syn_hash <- function(env) {
  ckpt_block_hash(syn_roots, syn_values, syn_params, syn_exempt, envir = env)
}
syn_edit <- function(from, to) {
  path <- file.path(tmp, paste0("syn-", nchar(to), ".R"))
  src <- readLines(syn_path)
  edited <- sub(from, to, src, fixed = TRUE)
  stopifnot(!identical(edited, src)) # the edit landed
  writeLines(edited, path)
  syn_source(path)
}
base_hash <- syn_hash(syn_env)
stopifnot(
  !identical(
    base_hash,
    syn_hash(syn_edit(
      'syn_make_est("agreement")',
      'syn_make_est("consistency")'
    ))
  )
)
pass("editing the captured determinant's argument changes the block hash")
stopifnot(
  !identical(
    base_hash,
    syn_hash(syn_edit('if (kind == "agreement") 1 else 2', "1.5"))
  )
)
pass(
  "editing the generator of the captured determinant changes the block hash too"
)
# The counterweight, so the hash is not simply always different: a comment added
# inside the entry point changes no cached number and leaves it alone.
stopifnot(identical(
  base_hash,
  syn_hash(syn_edit(
    "  out <- unlist(lapply(seq_len(k), syn_scale))",
    "  # a note to the next reader\n  out <- unlist(lapply(seq_len(k), syn_scale))"
  ))
))
pass("a comment added inside the entry point leaves the block hash unchanged")

# A declared block name that no longer exists is "not found", never silently
# resolved to a same-named function further up the search path. Two real sites
# declare a block function named `simulate`, which stats:: also exports: without
# this the hash would quietly track stats::simulate forever after a rename.
simulate <- function(design) design
stopifnot(is.function(stats::simulate)) # the stranger that must not be reached
stopifnot(nzchar(demo_spec(roots = c("gen_demo", "simulate"))$block_hash))
pass("the site's own block function is found while it exists")
rm(simulate) # the rename: the site's own function is gone
expect_error(
  demo_spec(roots = c("gen_demo", "simulate")),
  "a renamed block function is 'not found', not resolved to stats::simulate",
  must_match = "declared entry point not found: simulate"
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

# ---- AC3: the run-scoped trace, one registered path per form ----------------
# Each form below reads a checkpoint registered for THAT FORM ALONE, under a
# basename naming the form. An earlier design ran every form against one shared
# path with ckpt_trace_reset() between them: ckpt_trace_bypassed() returns
# unique PATHS, so one marker satisfied every form's reporting clause and
# attribution rested entirely on the resets -- which no real site calls. With a
# path per form the marker can only have come from the form that reads it, and
# nothing between the forms is reset.
cat("\n== AC3: unguarded deserialization of a registered checkpoint ==\n")
ckpt_trace_install()
ckpt_trace_register(tmp)

ckpt_trace_reset()
invisible(ckpt_read(p, demo_spec()))
ckpt_trace_assert()
pass(
  "a run whose every checkpoint read went through the guard passes the trace"
)

# A valid guarded checkpoint at a path of its own, registered for one form.
form_ckpt <- function(tag) {
  d <- tempfile(paste0("m120-form-", tag, "-"))
  dir.create(d)
  fp <- file.path(d, paste0(tag, ".rds"))
  ckpt_write(fp, payload = gen_demo(0.3, 10), spec = demo_spec())
  ckpt_trace_register(fp)
  fp
}

# The abort lands AT THE READ, in whichever process performed it -- not only at
# the end-of-run assertion. Swallowed here so the run continues, and then the
# bypass is required to be recorded against this form's own path.
demo_form <- function(tag, label, read) {
  fp <- form_ckpt(tag)
  e <- tryCatch(
    {
      force(read(fp))
      NULL
    },
    error = identity
  )
  if (is.null(e)) {
    stop("expected an abort at the read, none was signalled: ", label)
  }
  msg <- conditionMessage(e)
  if (!grepl("bypassed the checkpoint guard", msg, fixed = TRUE)) {
    stop(
      "aborted, but not as a guard bypass: ",
      label,
      "\n  got: ",
      msg
    )
  }
  if (!(ckpt_norm(fp) %in% ckpt_trace_bypassed())) {
    stop("the bypass was not recorded against this form's own path: ", label)
  }
  cat("PASS  ", label, "\n        error: ", msg, "\n", sep = "")
  invisible(fp)
}

demo_form(
  "bare",
  "a bare readRDS aborts at the read, recorded against its own path",
  function(fp) readRDS(fp)
)
demo_form(
  "namespaced",
  "the base:: spelling is caught too — the trace watches loads, not spellings",
  function(fp) base::readRDS(fp)
)
demo_form(
  "alias-after",
  "an alias bound after the guard was sourced is caught",
  function(fp) aliased_read(fp)
)
demo_form(
  "do-call",
  "do.call on the name is caught — the callee is the traced function",
  function(fp) do.call("readRDS", list(fp))
)

# And the end-of-run assertion still reports a bypass that was caught and
# swallowed by a caller's tryCatch rather than allowed to kill the run.
#
# The guarded read FIRST, with no reset between, is the point of this case: a
# real run reads each checkpoint through the guard before anything bypasses it,
# and a trace that recorded paths and subtracted the guarded ones would let that
# legitimate read cancel the bypass that follows it. The assertion must name
# THIS form's file, not one an earlier form left behind.
after_guarded <- form_ckpt("after-guarded")
invisible(ckpt_read(after_guarded, demo_spec()))
invisible(tryCatch(readRDS(after_guarded), error = function(e) NULL))
expect_error(
  ckpt_trace_assert(),
  "a bypass swallowed by a tryCatch is reported even after a guarded read of the same path",
  must_match = "after-guarded.rds"
)

# A checkpoint registered BEFORE it exists is still watched. Every oracle site
# registers its store path at startup, on the first run of a fresh clone that
# file does not exist yet, and a path identity that only resolves for existing
# files compared unequal to the very same path read back later -- so the trace
# was inert for exactly the first run.
# The path must be RELATIVE for this to be the real case: the oracle sites
# register `data-raw/.oracle-*-checkpoint.rds`, and a relative path that does not
# exist yet is the one a naive resolver leaves relative while the same path,
# once created, resolves absolute — so the two never compare equal and the trace
# is inert for precisely the first run.
# Deliberately rooted OUTSIDE `tmp`: `tmp` is already registered as a directory,
# and a read under it would abort on that registration whatever the relative
# path resolved to — the case would pass without testing anything.
cat("\n== AC3: a relative checkpoint path registered before it exists ==\n")
early_root <- tempfile("m120-early-")
dir.create(early_root)
owd <- setwd(early_root)
ckpt_trace_register("not-yet/later.rds")
dir.create("not-yet", showWarnings = FALSE)
saveRDS(1, "not-yet/later.rds") # the harness creates it mid-run
ckpt_trace_reset()
expect_error(
  readRDS("not-yet/later.rds"),
  "a relative path registered before the file existed is still watched",
  must_match = "bypassed the checkpoint guard"
)
setwd(owd)

# The alias bound at the top of this script, before any install call it makes.
# Sourcing the guard a SECOND time in one process must leave the trace's
# registrations and its recorded bypasses where they are. This is not a
# hypothetical: this script sources the guard, then sources m111-fallback-sweep.R
# below, which sources the guard again; and rerun-oracle.R runs several guarded
# scripts in one process. A re-source that rebuilt the state would leave the
# trace watching nothing at all, and the run that follows would be unguarded
# while every routing check still passed.
cat("\n== AC3: the guard sourced a second time in one process ==\n")
pre_resource <- form_ckpt("pre-resource")
invisible(tryCatch(readRDS(pre_resource), error = function(e) NULL))
registered_before <- ckpt_trace_state$registered
bypassed_before <- ckpt_trace_bypassed()
stopifnot(
  length(registered_before) > 0L,
  ckpt_norm(pre_resource) %in% bypassed_before
)
source("data-raw/checkpoint-guard.R") # the second source
stopifnot(identical(ckpt_trace_state$registered, registered_before))
stopifnot(identical(ckpt_trace_bypassed(), bypassed_before))
pass("re-sourcing the guard leaves registrations and recorded bypasses intact")
demo_form(
  "post-resource",
  "a bare read after the guard was sourced a second time still aborts",
  function(fp) readRDS(fp)
)
# Named against the path bypassed BEFORE the re-source, so what is shown to
# survive it is that bypass and not one recorded since.
expect_error(
  ckpt_trace_assert(),
  "the bypass recorded before the re-source is still reported after it",
  must_match = "pre-resource.rds"
)

# An unset environment variable is the realistic way a site hands the trace a
# non-path, and recording it made the registry match EVERY later read: one unset
# variable turned the guard into a run-wide abort on any readRDS at all. It is
# refused at the registration now, where the defect is.
cat("\n== AC3: a checkpoint location that cannot be resolved ==\n")
expect_error(
  ckpt_trace_register(Sys.getenv("M120_DELIBERATELY_UNSET_CKPT")),
  "an unresolvable checkpoint location is refused at registration",
  must_match = "cannot register a checkpoint location"
)
unrelated <- file.path(tempdir(), "m120-unrelated.rds")
saveRDS(1, unrelated)
invisible(readRDS(unrelated))
pass("and an unrelated read afterwards is still not flagged")

# A clean control: reset first, because every form above deliberately leaves its
# marker standing. What this case must show is that a read outside every
# registered location records nothing of its own.
ckpt_trace_reset()
outside <- file.path(tempdir(), "unregistered.rds")
saveRDS(1, outside)
invisible(readRDS(outside))
ckpt_trace_assert()
pass("a read outside any registered checkpoint location is not flagged")

# ---- AC3: the excluded form, demonstrated escaping ---------------------------
# AC3 promises the forms it enumerates and disclaims the rest. One excluded form
# is shown escaping rather than left asserted: an alias bound BEFORE the guard
# is sourced holds a copy of the untraced original, because trace() rebinds the
# name and a copy taken earlier is a different object. It runs in its own
# process -- this one already sourced the guard on line 11, and an uninstall /
# reinstall here would assign a fresh marker directory and orphan every bypass
# recorded above.
#
# The escape is paired with a positive control in the same subprocess: a
# swallowed BARE read of the same path IS recorded. Without it, "not reported"
# would be satisfied by a case that never ran at all.
cat("\n== AC3: an alias bound BEFORE the guard is sourced (excluded) ==\n")
pre_alias_script <- tempfile("m120-pre-alias-", fileext = ".R")
# A raw string, so the generated script keeps its own double quotes without
# escaping and this file needs no single-quoted strings of its own.
writeLines(
  r"(pre_alias <- readRDS # bound while readRDS is still untraced
source("data-raw/checkpoint-guard.R")
gen <- function(x) x
d <- tempfile("m120-pre-alias-")
dir.create(d)
fp <- file.path(d, "pre-alias.rds")
spec <- ckpt_spec(params = list(a = 1), roots = "gen", site = "pre-alias")
ckpt_write(fp, payload = gen(1), spec = spec)
ckpt_trace_register(fp)

# The excluded form: no abort, and the object comes back with no design
# comparison -- the whole file, spec envelope and all, not the payload.
got <- pre_alias(fp)
stopifnot(is.list(got), !is.null(got$ckpt_spec), !is.null(got$payload))
stopifnot(length(ckpt_trace_bypassed()) == 0L)
cat("ESCAPED-UNREPORTED\n")

# The control, same path, same process: a bare read IS recorded.
invisible(tryCatch(readRDS(fp), error = function(e) NULL))
stopifnot(ckpt_norm(fp) %in% ckpt_trace_bypassed())
cat("CONTROL-REPORTED\n")
)",
  pre_alias_script
)
pre_alias_out <- system2(
  file.path(R.home("bin"), "Rscript"),
  pre_alias_script,
  stdout = TRUE,
  stderr = TRUE
)
if (!all(c("ESCAPED-UNREPORTED", "CONTROL-REPORTED") %in% pre_alias_out)) {
  stop(
    "the pre-source alias case did not run as written:\n",
    paste(pre_alias_out, collapse = "\n")
  )
}
pass(
  "an alias bound before the guard was sourced reads unaborted and unreported"
)
pass(
  "  ...while a swallowed bare read of the same path in that process IS reported"
)

ckpt_trace_remove()

# ---- AC3/AC4 on a REAL site --------------------------------------------------
# Everything above runs against a stand-in site. This section runs the M111
# sweep itself, at n_rep = 2 and with both its paths redirected into a tempdir,
# so the guard is exercised on the harness the defect was found in rather than
# only on a model of it. The four oracle sites share this code path but each
# needs brms/Stan and hours of refits, so they are covered by the routing check
# (data-raw/check-checkpoint-sites.R), not by a run here.
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
cat("\n== unpromised: a bare readRDS inside an mclapply worker ==\n")
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

# And the harder case: the worker SWALLOWS its own abort, so the parent sees a
# perfectly ordinary return value. The worker's memory dies with it, so the
# bypass is recorded to disk and the parent's assertion reads it there.
cat("\n== unpromised: a forked worker that swallows its own bypass ==\n")
ckpt_trace_reset()
swallowed <- parallel::mclapply(
  1:2,
  function(i) {
    if (i == 2L) {
      tryCatch(readRDS(valid_cell), error = function(e) NULL)
    }
    "looks fine"
  },
  mc.cores = 2L
)
stopifnot(identical(unlist(swallowed), c("looks fine", "looks fine")))
pass("the worker swallowed its abort and returned an ordinary value")
expect_error(
  ckpt_trace_assert(),
  "the parent's assertion still reports a bypass its forked worker swallowed",
  must_match = "bypassed the checkpoint guard"
)
ckpt_trace_reset()

# And the spec check reaches inside a worker too: a stale checkpoint must be
# refused there and surface to the parent as that cell's failure.
cat(
  "\n== unpromised: a stale checkpoint refused inside an mclapply worker ==\n"
)
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
