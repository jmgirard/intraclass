# M120 — a synthetic resume site, existing only so the two generating-block
# walks can be pinned against each other.
#
# The guard walks LIVE BINDINGS (ckpt_block_scan in checkpoint-guard.R); the
# routing checker walks PARSED SOURCE (static_block_scan in
# check-checkpoint-sites.R). Four of the five real sites need brms/Stan and hours
# of refits, so the static walk is the only one that ever reaches them, and
# nothing about the real sites can show the two walks agree. This file can:
# data-raw/m120-checkpoint-guard-demo.R sources it for the run-time walk and
# parses it for the static one, and requires an identical symbol set.
#
# It is deliberately not a declared site in checkpoint-sites.tsv — it resumes
# from nothing and writes nothing. Every name is `syn_`-prefixed so that sourcing
# it into an environment whose parent is the global environment cannot
# accidentally resolve a symbol against whatever the demonstration script has
# already defined.
#
# One instance of each class the walk must classify:
#   syn_est        a captured VALUE      — computed here, referenced by name
#                                          inside the entry point, never called
#   syn_scale      a captured FUNCTION   — handed to lapply by name, so it
#                                          appears in no call position either
#   syn_shadowed   a SHADOWED local      — a top-level binding whose name a local
#                                          reuses; not a dependency on it
#   syn_base_fit   an EXEMPTED object    — the stand-in for a compiled brms fit
#   syn_rho        a declared PARAMETER  — compared by name, not hashed

syn_make_est <- function(kind) {
  list(kind = kind, weight = if (kind == "agreement") 1 else 2)
}

syn_est <- syn_make_est("agreement")

syn_base_fit <- structure(list(stanmodel = "<compiled>"), class = "syn_fit")

syn_rho <- 0.3

syn_shadowed <- "a top-level binding the entry point never reads"

syn_scale <- function(x) {
  x * syn_est$weight
}

syn_one_rep <- function(k) {
  out <- unlist(lapply(seq_len(k), syn_scale))
  syn_shadowed <- length(syn_base_fit)
  out * syn_rho * syn_shadowed
}
