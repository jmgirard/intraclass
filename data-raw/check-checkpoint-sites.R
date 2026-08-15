# M120 — every declared resume site still routes through the checkpoint guard.
#
# This replaces a text-matching checker that asked only whether a token appeared
# somewhere in the file. Three reversions walked past it: an assertion moved to
# after the fixture write, a registration handed a literal NULL, and a live
# per-entry read replaced by direct payload access while a dead copy of the call
# survived in an `if (FALSE)` block. None of those is visible to a search for
# text, so this reads the parsed source instead.
#
# What it checks, and what it deliberately does not:
#
#   * IT CHECKS the sites declared in data-raw/checkpoint-sites.tsv. That file is
#     an enumeration, not a discovery procedure, and this checker inherits
#     exactly that bound. It cannot tell you a sixth harness has started resuming
#     from a cache, and it does not claim to.
#   * WHAT DOES cover the open-ended case is the run-time trace in
#     checkpoint-guard.R, which installs itself when that file is sourced and
#     watches deserialization as it happens. This checker exists because that
#     trace only fires when a harness actually runs, and the four oracle
#     harnesses need brms/Stan and hours of refits.
#
# So: the trace is the guard, this is the regression net over the sites we know
# about.
#
#   Rscript data-raw/check-checkpoint-sites.R
#   Rscript data-raw/check-checkpoint-sites.R --self-test

guard_path <- "data-raw/checkpoint-guard.R"
sites_tsv <- "data-raw/checkpoint-sites.tsv"

# ---- reading the declaration -------------------------------------------------

read_sites <- function(path = sites_tsv) {
  lines <- readLines(path, warn = FALSE)
  lines <- lines[nzchar(trimws(lines)) & !startsWith(lines, "#")]
  parts <- strsplit(lines, "\t", fixed = TRUE)
  header <- parts[[1]]
  lapply(parts[-1], function(row) stats::setNames(as.list(row), header))
}

split_decl <- function(x) {
  out <- trimws(strsplit(x %||% "", ",", fixed = TRUE)[[1]])
  out[nzchar(out)]
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# ---- walking the parsed source ----------------------------------------------
# Every check below is asked of the LIVE code. `if (FALSE) { ... }` is the
# cheapest way to keep a call's text while removing the call, so those branches
# are dropped before anything is counted; a dead call is not a call.

drop_dead <- function(e) {
  if (!is.call(e)) {
    return(e)
  }
  if (identical(e[[1]], as.name("if")) && identical(e[[2]], FALSE)) {
    return(if (length(e) >= 4L) drop_dead(e[[4]]) else NULL)
  }
  if (identical(e[[1]], as.name("if")) && identical(e[[2]], TRUE)) {
    return(drop_dead(e[[3]]))
  }
  as.call(lapply(as.list(e), function(x) if (is.null(x)) x else drop_dead(x)))
}

# Every call to `name` in the live source, as call objects.
calls_to <- function(exprs, name) {
  found <- list()
  walk <- function(e) {
    if (is.call(e)) {
      head <- e[[1]]
      # bare f(), pkg::f(), and pkg:::f() all count as a call to f
      nm <- if (is.name(head)) {
        as.character(head)
      } else if (
        is.call(head) &&
          is.name(head[[1]]) &&
          as.character(head[[1]]) %in% c("::", ":::")
      ) {
        as.character(head[[3]])
      } else {
        ""
      }
      if (identical(nm, name)) {
        found[[length(found) + 1L]] <<- e
      }
      # BY INDEX: an empty argument (the blank in `d[keep, , drop = FALSE]`)
      # binds a loop variable to the missing marker, and every later touch of
      # that variable raises "argument is missing". Indexing reads the same
      # object without binding it.
      args <- as.list(e)[-1]
      for (i in seq_along(args)) {
        if (!is.null(args[[i]]) && !identical(args[[i]], quote(expr = ))) {
          walk(args[[i]])
        }
      }
    }
  }
  for (e in exprs) {
    walk(e)
  }
  found
}

# The source line a call sits on, for the ordering check. Top-level scripts run
# in source order, so a line number is an execution order.
line_of <- function(exprs, name) {
  refs <- attr(exprs, "srcref")
  hits <- integer(0)
  for (i in seq_along(exprs)) {
    if (length(calls_to(exprs[i], name))) {
      hits <- c(hits, if (is.null(refs)) NA_integer_ else refs[[i]][1L])
    }
  }
  hits
}

parse_live <- function(path) {
  exprs <- parse(path, keep.source = TRUE)
  refs <- attr(exprs, "srcref")
  live <- lapply(exprs, drop_dead)
  live <- Filter(Negate(is.null), live)
  attr(live, "srcref") <- refs
  live
}

# ---- the checks --------------------------------------------------------------

check_site <- function(site, root = ".") {
  out <- character(0)
  path <- file.path(root, site$script)
  if (!file.exists(path)) {
    return(paste0(site$script, ": declared in ", sites_tsv, " but absent"))
  }
  exprs <- tryCatch(parse_live(path), error = function(e) NULL)
  if (is.null(exprs)) {
    return(paste0(site$script, ": does not parse"))
  }

  # 1. The guard is sourced, by a live call naming the guard file.
  sourced <- calls_to(exprs, "source")
  if (
    !any(vapply(
      sourced,
      function(e) {
        any(vapply(as.list(e)[-1], identical, logical(1), guard_path))
      },
      logical(1)
    ))
  ) {
    out <- c(out, paste0(site$script, ": no live source() of ", guard_path))
  }

  # 2. Every declared guard call is made, live. ALL of them: a site that keeps
  #    its file-level load and drops its per-entry read has stopped checking the
  #    thing that goes stale, and no single call stands in for the set.
  required <- split_decl(site$api)
  if (!length(required)) {
    out <- c(out, paste0(site$script, ": declares no guard calls"))
  }
  for (call_name in required) {
    if (!length(calls_to(exprs, call_name))) {
      out <- c(out, paste0(site$script, ": never calls ", call_name, "()"))
    }
  }

  # 3. The checkpoint is registered with the trace, with a real argument. A
  #    literal NULL registers nothing and leaves every later read unwatched.
  reg <- calls_to(exprs, "ckpt_trace_register")
  if (!length(reg)) {
    out <- c(out, paste0(site$script, ": never registers its checkpoint"))
  } else if (
    !any(vapply(
      reg,
      function(e) {
        length(e) >= 2L && !is.null(e[[2]]) && !identical(e[[2]], NULL)
      },
      logical(1)
    ))
  ) {
    out <- c(
      out,
      paste0(site$script, ": ckpt_trace_register() is given no real path")
    )
  }

  # 4. The pre-write assertion runs BEFORE the site's output write. Asserting
  #    after the fixture has been written is not a guard, it is a postmortem.
  assert_lines <- line_of(exprs, "ckpt_trace_assert")
  write_lines <- line_of(exprs, "saveRDS")
  if (!length(assert_lines)) {
    out <- c(out, paste0(site$script, ": never calls ckpt_trace_assert()"))
  } else if (length(write_lines) && min(assert_lines) > min(write_lines)) {
    out <- c(
      out,
      paste0(
        site$script,
        ": ckpt_trace_assert() (line ",
        min(assert_lines),
        ") comes after the first output write (line ",
        min(write_lines),
        ")"
      )
    )
  }

  # 5. The declared parameters appear in a ckpt_spec() call, in the declared
  #    ORDER — the mismatch message names the earliest differing one, so the
  #    order is part of the contract, not a formatting detail.
  specs <- calls_to(exprs, "ckpt_spec")
  if (!length(specs)) {
    out <- c(out, paste0(site$script, ": never builds a ckpt_spec()"))
  } else {
    declared <- split_decl(site$params)
    seen_any <- FALSE
    for (e in specs) {
      params <- e[["params"]]
      if (is.null(params) || !is.call(params)) {
        next
      }
      nms <- names(as.list(params))[-1]
      if (is.null(nms)) {
        next
      }
      seen_any <- TRUE
      if (!identical(nms, declared)) {
        out <- c(
          out,
          paste0(
            site$script,
            ": ckpt_spec() parameters (",
            paste(nms, collapse = ", "),
            ") do not match the declared set in declared order (",
            paste(declared, collapse = ", "),
            ")"
          )
        )
      }
    }
    if (!seen_any) {
      out <- c(out, paste0(site$script, ": no ckpt_spec() declares params"))
    }
  }

  # 6. The declared block roots and values are the ones the site passes.
  for (nm in c(split_decl(site$roots), split_decl(site$values))) {
    if (
      !any(vapply(
        specs,
        function(e) nm %in% all_strings(e),
        logical(1)
      ))
    ) {
      out <- c(
        out,
        paste0(
          site$script,
          ": declared block entry '",
          nm,
          "' is in no ckpt_spec()"
        )
      )
    }
  }
  out
}

all_strings <- function(e) {
  out <- character(0)
  walk <- function(x) {
    if (is.character(x)) {
      out <<- c(out, x)
    } else if (is.call(x) || is.list(x)) {
      ys <- as.list(x)
      for (i in seq_along(ys)) {
        if (!is.null(ys[[i]]) && !identical(ys[[i]], quote(expr = ))) {
          walk(ys[[i]])
        }
      }
    }
  }
  walk(e)
  out
}

run_check <- function(root = ".") {
  sites <- read_sites(file.path(root, sites_tsv))
  failures <- unlist(lapply(sites, check_site, root = root))
  list(sites = sites, failures = failures %||% character(0))
}

# ---- mutation self-test ------------------------------------------------------
# A checker that passes on a reverted guard is false coverage, which is the trap
# this repo keeps re-finding — and which this checker's predecessor fell into
# three more times. Every declared site is probed, not a representative one.

mutations_for <- function(site, src) {
  muts <- list(
    list(
      label = "commented out the source() of the guard",
      text = sub(
        paste0('source("', guard_path, '")'),
        paste0('# source("', guard_path, '")'),
        src,
        fixed = TRUE
      )
    ),
    list(
      label = "moved ckpt_trace_assert() after the output write",
      text = paste0(
        sub("ckpt_trace_assert()", "invisible(TRUE)", src, fixed = TRUE),
        "\nckpt_trace_assert()\n"
      )
    ),
    list(
      label = "registered a literal NULL instead of the checkpoint path",
      text = sub(
        "ckpt_trace_register(",
        "ckpt_trace_register(NULL) # ",
        src,
        fixed = TRUE
      )
    )
  )
  for (call_name in split_decl(site$api)) {
    # Drop every live call, but keep a DEAD copy: this is the reversion that
    # walked past a text search, and the one a debugging edit actually leaves.
    muts[[length(muts) + 1L]] <- list(
      label = paste0("replaced every live ", call_name, "() with a dead copy"),
      text = paste0(
        gsub(
          paste0("(?<![\\w.$])", call_name, "\\s*\\("),
          "bypassed_(",
          src,
          perl = TRUE
        ),
        "\nif (FALSE) {\n  ",
        call_name,
        "(a, b, c)\n}\n"
      )
    )
  }
  muts
}

self_test <- function() {
  ok <- TRUE
  for (site in read_sites()) {
    src <- paste(readLines(site$script, warn = FALSE), collapse = "\n")
    for (m in mutations_for(site, src)) {
      if (identical(m$text, src)) {
        cat(
          "FAIL self-test [",
          site$script,
          "]: cannot plant '",
          m$label,
          "' -- the mutation changed nothing\n",
          sep = ""
        )
        ok <- FALSE
        next
      }
      td <- tempfile("ckpt-selftest-")
      dir.create(file.path(td, dirname(site$script)), recursive = TRUE)
      writeLines(m$text, file.path(td, site$script))
      file.copy(sites_tsv, file.path(td, sites_tsv))
      found <- check_site(site, root = td)
      unlink(td, recursive = TRUE)
      if (length(found)) {
        cat(
          "PASS self-test [",
          site$script,
          "]: ",
          m$label,
          " -> detected\n",
          sep = ""
        )
      } else {
        cat(
          "FAIL self-test [",
          site$script,
          "]: ",
          m$label,
          " was NOT detected\n",
          sep = ""
        )
        ok <- FALSE
      }
    }
    if (length(check_site(site))) {
      cat(
        "FAIL self-test [",
        site$script,
        "]: the unmutated site does not pass\n",
        sep = ""
      )
      ok <- FALSE
    } else {
      cat(
        "PASS self-test [",
        site$script,
        "]: the unmutated site passes\n",
        sep = ""
      )
    }
  }
  ok
}

# ---- entry point -------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--self-test" %in% args) {
    quit(status = if (self_test()) 0L else 1L)
  }
  res <- run_check()
  if (length(res$failures)) {
    cat(
      "FAIL: ",
      length(res$failures),
      " checkpoint-routing failure(s):\n",
      sep = ""
    )
    for (f in res$failures) {
      cat("  - ", f, "\n", sep = "")
    }
    quit(status = 1L)
  }
  cat(
    "OK: ",
    length(res$sites),
    " declared resume site(s) route through the checkpoint guard.\n",
    sep = ""
  )
  cat(
    "(Declared sites only -- the run-time trace in checkpoint-guard.R is what",
    " covers a site nobody declared.)\n",
    sep = ""
  )
}
