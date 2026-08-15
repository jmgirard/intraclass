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

# A `#@name<TAB>value` line in the declaration file: file-level declarations that
# are not per-site. read_sites() drops every comment line, so these are read
# separately rather than smuggled into the table.
read_directive <- function(name, path = sites_tsv) {
  lines <- readLines(path, warn = FALSE)
  hit <- lines[startsWith(lines, paste0("#@", name, "\t"))]
  if (!length(hit)) {
    stop("no #@", name, " directive in ", path, call. = FALSE)
  }
  split_decl(sub("^#@[^\t]*\t", "", hit[[length(hit)]]))
}

# The four names AC2 requires the list to contain. A list that may be shortened
# at will is not an enumeration, it is whatever the sites happened not to use --
# and the recall it would then rest on is what this milestone exists to stop
# relying on.
required_deserializers <- c("readRDS", "load", "unserialize", "readr::read_rds")

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

  # 7. Every determinant the generating walk reaches is accounted for. The walk
  #    starts at the declared roots and follows the site's own definitions; a
  #    symbol resolving to a top-level binding that is neither hashed nor
  #    declared is reported BY NAME. Four sites can never be run here, so this
  #    static walk is the only one that ever reaches them.
  scan <- static_block_scan(
    static_bindings(exprs),
    split_decl(site$roots),
    split_decl(site$values),
    split_decl(site$params),
    split_decl(site$exemptions)
  )
  for (nm in scan$unresolved) {
    out <- c(
      out,
      paste0(
        site$script,
        ": declared entry point '",
        nm,
        "' is not a top-level function of this site"
      )
    )
  }
  # 8. Neither the site nor anything it sources deserializes for itself.
  deser <- read_directive("deserializers", file.path(root, sites_tsv))
  if (!all(required_deserializers %in% deser)) {
    out <- c(
      out,
      paste0(
        site$script,
        ": the declared deserialization list is missing ",
        paste(setdiff(required_deserializers, deser), collapse = ", ")
      )
    )
  }
  deser_bad <- deserialization_failures(site$script, root, deser)$out
  for (msg in deser_bad) {
    out <- c(out, paste0(site$script, ": ", msg))
  }

  for (nm in scan$uncovered) {
    out <- c(
      out,
      paste0(
        site$script,
        ": the generating walk reaches '",
        nm,
        "', which is neither hashed nor declared (declare it as a value, or as",
        " an exemption with a stated reason in ",
        sites_tsv,
        ")"
      )
    )
  }
  out
}

# ---- the static generating-block walk ---------------------------------------
# A mirror of ckpt_block_scan() in data-raw/checkpoint-guard.R, run over PARSED
# SOURCE rather than over live bindings. Four of the five sites need brms/Stan
# and hours of refits, so their run-time walk cannot be executed here at all --
# this is the only walk that ever reaches them. The two are pinned against each
# other on a synthetic site in data-raw/m120-checkpoint-guard-demo.R; that pin,
# not inspection, is what keeps the two implementations answering alike.
#
# One deliberate difference: the run-time walk resolves a name up the
# environment chain as far as globalenv(), so a function the site does not
# define -- the guard's own, say -- is reached and hashed there. Here only the
# site's own top-level bindings resolve, and anything else stops the walk. The
# difference cannot produce a false report: a symbol that does not resolve is
# skipped, never called uncovered.

is_fn_expr <- function(e) {
  is.call(e) && is.name(e[[1]]) && identical(as.character(e[[1]]), "function")
}

# name -> the expression last assigned to it at top level. Last assignment wins,
# which is what the run-time walk sees: it reads the binding as it stands when
# the spec is built.
static_bindings <- function(exprs) {
  out <- list()
  for (e in exprs) {
    if (
      is.call(e) &&
        is.name(e[[1]]) &&
        as.character(e[[1]]) %in% c("<-", "=") &&
        length(e) >= 3L &&
        is.name(e[[2]])
    ) {
      out[[as.character(e[[2]])]] <- e[[3]]
    }
  }
  out
}

# Follow `f <- g` chains, so a function reached through an alias is a function
# here exactly as is.function() finds it at run time.
static_resolve <- function(nm, bindings, depth = 0L) {
  if (!nm %in% names(bindings)) {
    return(list(found = FALSE, expr = NULL, is_fn = FALSE))
  }
  e <- bindings[[nm]]
  if (is_fn_expr(e)) {
    return(list(found = TRUE, expr = e, is_fn = TRUE))
  }
  if (is.name(e) && depth < 10L) {
    onward <- static_resolve(as.character(e), bindings, depth + 1L)
    if (onward$found) {
      return(onward)
    }
  }
  list(found = TRUE, expr = e, is_fn = FALSE)
}

# EVERY bare name in an expression, not only those in call position -- the
# counterpart of ckpt_symbols(). `pkg::f`, `x$y` and `x@y` contribute only their
# left operand, and walking is BY INDEX so an empty argument (the blank in
# `d[keep, , drop = FALSE]`) is never bound to a variable.
expr_symbols <- function(e, acc = character(0)) {
  if (is.name(e)) {
    nm <- as.character(e)
    return(if (nzchar(nm)) c(acc, nm) else acc)
  }
  if (!is.call(e)) {
    return(acc)
  }
  if (is.name(e[[1]]) && as.character(e[[1]]) %in% c("::", ":::", "$", "@")) {
    return(expr_symbols(e[[2]], acc))
  }
  parts <- as.list(e)
  for (i in seq_along(parts)) {
    if (!is.null(parts[[i]]) && !identical(parts[[i]], quote(expr = ))) {
      acc <- expr_symbols(parts[[i]], acc)
    }
  }
  acc
}

# The names a function literal binds for itself -- the counterpart of
# ckpt_local_names(). Subtracted from the walked symbols so a local that shares
# a name with a top-level binding is not read as a dependency on it.
expr_locals <- function(fn) {
  acc <- names(as.list(fn[[2]]))
  walk <- function(e) {
    if (!is.call(e)) {
      return(invisible(NULL))
    }
    if (is.name(e[[1]])) {
      op <- as.character(e[[1]])
      if (op %in% c("<-", "=", "<<-") && length(e) >= 3L && is.name(e[[2]])) {
        acc <<- c(acc, as.character(e[[2]]))
      }
      if (op == "for" && length(e) >= 3L && is.name(e[[2]])) {
        acc <<- c(acc, as.character(e[[2]]))
      }
      if (op == "function") {
        acc <<- c(acc, names(as.list(e[[2]])))
      }
    }
    parts <- as.list(e)
    for (i in seq_along(parts)) {
      if (!is.null(parts[[i]]) && !identical(parts[[i]], quote(expr = ))) {
        walk(parts[[i]])
      }
    }
  }
  walk(fn[[3]])
  unique(acc)
}

static_block_scan <- function(
  bindings,
  roots,
  values = character(0),
  params = character(0),
  exemptions = character(0)
) {
  seen <- character(0)
  queue <- roots
  uncovered <- character(0)
  unresolved <- character(0)
  declared <- c(values, params, exemptions)
  while (length(queue)) {
    nm <- queue[[1]]
    queue <- queue[-1]
    if (nm %in% seen) {
      next
    }
    r <- static_resolve(nm, bindings)
    if (!r$found || !r$is_fn) {
      unresolved <- c(unresolved, nm)
      next
    }
    seen <- c(seen, nm)
    locals <- expr_locals(r$expr)
    for (s in setdiff(unique(expr_symbols(r$expr[[3]])), locals)) {
      if (s %in% seen || s %in% queue) {
        next
      }
      h <- static_resolve(s, bindings)
      if (!h$found) {
        next # not this site's own: a local, a formal, or a package object
      }
      if (h$is_fn) {
        queue <- c(queue, s)
      } else if (!(s %in% declared)) {
        uncovered <- c(uncovered, s)
      }
    }
  }
  list(
    fns = sort(seen),
    uncovered = sort(unique(uncovered)),
    unresolved = sort(unique(unresolved))
  )
}

# The walk over one file, given that file's declaration. Used by check_site()
# and by the run-time/static pin in the demonstration script.
static_scan_file <- function(
  path,
  roots,
  values = character(0),
  params = character(0),
  exemptions = character(0)
) {
  static_block_scan(
    static_bindings(parse_live(path)),
    roots,
    values,
    params,
    exemptions
  )
}

# ---- the deserialization check ----------------------------------------------
# A site that deserializes for itself has left the guard behind: the bytes on
# disk become an R object without anything asking what design produced them. The
# guard file is the one place allowed to do it, so it is excluded; every other
# file a site source()s is scanned exactly as the site is, transitively.
#
# The list is an enumeration and claims nothing about a name outside it. A read
# through a connection is likewise outside it, and outside AC3's watcher too — a
# candidate row carries both.

# The literal paths a file source()s, from live code only.
sourced_paths <- function(exprs) {
  out <- character(0)
  for (e in calls_to(exprs, "source")) {
    for (a in as.list(e)[-1]) {
      if (is.character(a) && length(a) == 1L) {
        out <- c(out, a)
      }
    }
  }
  unique(out)
}

# `readr::read_rds` and a bare `read_rds` are the same call to this check, so a
# declared name is matched on its last component.
bare_name <- function(x) sub("^.*::+", "", x)

deserialization_failures <- function(path, root, deser, seen = character(0)) {
  if (path %in% seen) {
    return(list(out = character(0), seen = seen))
  }
  seen <- c(seen, path)
  full <- file.path(root, path)
  if (!file.exists(full)) {
    return(list(out = character(0), seen = seen))
  }
  exprs <- tryCatch(parse_live(full), error = function(e) NULL)
  if (is.null(exprs)) {
    return(list(
      out = paste0(path, ": does not parse, so it cannot be checked"),
      seen = seen
    ))
  }
  out <- character(0)
  for (nm in deser) {
    if (length(calls_to(exprs, bare_name(nm)))) {
      out <- c(
        out,
        paste0(
          path,
          " calls ",
          nm,
          "(), which deserializes without going through the checkpoint guard"
        )
      )
    }
  }
  for (child in setdiff(sourced_paths(exprs), guard_path)) {
    res <- deserialization_failures(child, root, deser, seen)
    out <- c(out, res$out)
    seen <- res$seen
  }
  list(out = out, seen = seen)
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
  # Withdraw one declared determinant. Nothing about the SCRIPT changes; what
  # changes is the declaration, and the generating walk must then name the
  # determinant it reaches and can no longer account for. A site with no
  # declared values has nothing to withdraw and gets no such mutation.
  #
  # It must be a determinant the walk REACHES, which is not every declared one:
  # `base_formula`, `base_prior` and `brm_args` are referenced only at top level,
  # where the base fit is compiled from them, and never inside a walked body.
  # They are hashed all the same, but no walk can see them go undeclared, and
  # AC1 claims nothing about a determinant reached other than as a symbol in a
  # walked body. So the mutation is aimed at one the walk does reach.
  reached <- static_block_scan(
    static_bindings(parse_live(site$script)),
    split_decl(site$roots),
    character(0),
    split_decl(site$params),
    split_decl(site$exemptions)
  )$uncovered
  droppable <- intersect(split_decl(site$values), reached)
  if (length(droppable)) {
    dropped <- site
    dropped$values <- paste(
      setdiff(split_decl(site$values), droppable[[1]]),
      collapse = ","
    )
    muts[[length(muts) + 1L]] <- list(
      label = paste0(
        "withdrew the declaration of the determinant '",
        droppable[[1]],
        "'"
      ),
      text = src,
      site = dropped
    )
  }
  # One call to each declared deserialization name, planted live at top level.
  # This is AC2's own procedure, run on every site rather than on a
  # representative one.
  for (nm in read_directive("deserializers")) {
    muts[[length(muts) + 1L]] <- list(
      label = paste0("planted a live ", nm, "() call"),
      text = paste0(src, "\n", nm, '("planted.rds")\n')
    )
  }

  # And one planted in a file the site SOURCES rather than in the site itself:
  # the check follows source() transitively, and a harness that moved its read
  # into a helper file would otherwise be invisible.
  sourced <- setdiff(
    sourced_paths(parse_live(site$script)),
    guard_path
  )
  sourced <- sourced[file.exists(sourced)]
  if (length(sourced)) {
    muts[[length(muts) + 1L]] <- list(
      label = paste0("planted a live readRDS() call in ", sourced[[1]]),
      target = sourced[[1]],
      text = paste0(
        paste(readLines(sourced[[1]], warn = FALSE), collapse = "\n"),
        '\nreadRDS("planted.rds")\n'
      )
    )
  }

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
      # A mutation plants either an edited SCRIPT or an edited DECLARATION; the
      # declaration ones leave the script alone by design.
      mutated_site <- m$site %||% site
      if (identical(m$text, src) && is.null(m$site)) {
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
      # The whole data-raw R tree is copied, not just the one script: the
      # deserialization check follows source() transitively, and a tree holding
      # only the mutated file would make every sourced file silently absent.
      td <- tempfile("ckpt-selftest-")
      dir.create(file.path(td, "data-raw"), recursive = TRUE)
      file.copy(
        c(
          list.files("data-raw", pattern = "[.]R$", full.names = TRUE),
          sites_tsv
        ),
        file.path(td, "data-raw")
      )
      writeLines(m$text, file.path(td, m$target %||% site$script))
      found <- check_site(mutated_site, root = td)
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
