# Measure the condition text against the house prose rules (M156).
#
# `cairn/doctrine/prose-style.md` governs what users read. This ruler covers the
# text of the conditions the package raises, which `prose-profile.py` cannot
# reach: that ruler reads roxygen and markdown, and a message is an R string
# assembled at run time. Like `prose-profile.py`, it is run by hand and never by
# CI (cairn D-021 bars standing apparatus over the repo's own records).
#
# WHAT IT READS. Two sources, reported separately.
#
# 1. Call sites. `utils::getParseData()` over every `R/*.R` file finds each call
#    to one of the condition functions in `COND_FUNS` below, and to
#    `rlang::check_installed()`. The message argument (the first argument, or
#    `message`; `reason` for `check_installed()`) is assembled statically:
#    a string literal is itself, `c()` makes one line per element, `paste0()`
#    and `paste()` join their parts, `if`/`else` yields each branch as a
#    variant, a call to a no-argument helper defined in `R/` is evaluated, and
#    a symbol is resolved through its assignments in the same function. Any
#    other expression becomes the one-word placeholder `{expr}`. So does a
#    symbol with no assignment found, and that site is listed as unresolved.
# 2. Hint bullets. The builders in `R/boundary-hint.R` take the `usable`
#    predicate as an argument, so every branch they can take is reached by
#    calling them over every subset of the candidate methods, both `contrast`
#    phrases, and a seeded and an unseeded call. The interpolated seed and
#    `boot_samples` stay as the numbers the builder writes.
#
# WHAT IT COUNTS. Each assembled line is one paragraph. A `{...}` glue or markup
# span counts as one word, and a `\` line continuation with its following
# whitespace becomes one space. A sentence ends at `.`, `!` or `?` plus
# whitespace, with the abbreviations `prose-profile.py` holds back. A word is a
# whitespace token with an alphanumeric character. R1 counts an em or en dash,
# or a `--`/`---` that is not flanked by digits; R2 counts sentences over the
# limit; R8 counts the doctrine's seven markers.
#
# Usage, from the repo root:
#   Rscript data-raw/condition-text-profile.R            # totals, exit 1 on a hit
#   Rscript data-raw/condition-text-profile.R --verbose  # every offending line
#   Rscript data-raw/condition-text-profile.R --dump     # every assembled line
#   Rscript data-raw/condition-text-profile.R --self-test
#   Rscript data-raw/condition-text-profile.R --compare-tokens main
#
# `--compare-tokens <ref>` reads each `R/*.R` file at `<ref>` with `git show`
# (never a checkout) and compares its `getParseData()` terminal tokens with the
# working tree's. Comments are dropped. Every string literal becomes `S`, then
# the joins M156 AC4 allows are folded until nothing changes: a bullet name
# (`name = S`, `"name" = S`) and a `c()`, `paste0()` or `paste()` call whose
# every argument is `S` each become `S`. What remains must be identical. It also
# compares, per file, the multiset of glue expressions inside the literals
# (a `{...}` span whose content does not open with `.` or `?`).

suppressMessages(devtools::load_all(quiet = TRUE))

COND_FUNS <- c(
  "abort_intraclass",
  "abort_unsupported",
  "abort_unidentified",
  "abort_inapplicable",
  "abort_fixed_agr_projection",
  "warn_intraclass",
  "warn_fixed_raters",
  "warn_dropped_rows",
  "cli_abort",
  "cli_warn",
  "cli_inform"
)
ALL_FUNS <- c(COND_FUNS, "check_installed")
LIMIT <- 25L

ABBREVIATIONS <- c(
  "e.g.",
  "i.e.",
  "cf.",
  "vs.",
  "etc.",
  "al.",
  "eq.",
  "fig.",
  "no.",
  "p.",
  "pp.",
  "ch.",
  "sec.",
  "dr.",
  "prof.",
  "st.",
  "mr.",
  "ms.",
  "mrs."
)
R8_MARKERS <- c(
  "which is why",
  "[Tt]hat is why",
  "\\bprecisely\\b",
  "the whole rule",
  "\\bIn short\\b",
  "half the job",
  "\\bnot (just|only|merely|simply) [^.]*\\bbut\\b"
)

# --- static assembly ----------------------------------------------------------

# Every expression is assembled to a list of variants; a variant is a character
# vector of lines.
cross <- function(parts) {
  out <- list(character(0))
  for (p in parts) {
    nxt <- list()
    for (a in out) {
      for (b in p) {
        nxt[[length(nxt) + 1L]] <- if (length(a)) paste0(a, b) else b
      }
    }
    out <- utils::head(nxt, 64L)
  }
  out
}

assemble <- function(e, env) {
  if (is.character(e)) {
    return(list(e))
  }
  if (is.numeric(e) || is.logical(e)) {
    return(list(as.character(e)))
  }
  if (is.symbol(e)) {
    nm <- as.character(e)
    vals <- env$assign[[nm]]
    if (is.null(vals)) {
      env$unresolved <- c(env$unresolved, nm)
      return(list(paste0("{", nm, "}")))
    }
    return(unlist(lapply(vals, assemble, env = env), recursive = FALSE))
  }
  if (is.call(e)) {
    fn <- e[[1]]
    fname <- if (is.symbol(fn)) as.character(fn) else deparse(fn)
    args <- as.list(e)[-1]
    if (fname == "c") {
      # Each element is a line; the variants of each element cross.
      per <- lapply(args, assemble, env = env)
      out <- list(character(0))
      for (p in per) {
        nxt <- list()
        for (a in out) {
          for (b in p) {
            nxt[[length(nxt) + 1L]] <- c(a, b)
          }
        }
        out <- utils::head(nxt, 64L)
      }
      return(out)
    }
    if (fname %in% c("paste0", "paste")) {
      nms <- names(args) %||% rep("", length(args))
      sep <- if (fname == "paste") " " else ""
      if ("sep" %in% nms) {
        sep <- eval(args[["sep"]])
      }
      parts <- args[!nms %in% c("sep", "collapse")]
      pieces <- lapply(parts, function(a) {
        v <- assemble(a, env)
        lapply(v, paste, collapse = " ")
      })
      joined <- list()
      for (i in seq_along(pieces)) {
        joined[[length(joined) + 1L]] <- pieces[[i]]
        if (i < length(pieces) && nzchar(sep)) {
          joined[[length(joined) + 1L]] <- list(sep)
        }
      }
      return(lapply(cross(joined), function(x) x))
    }
    if (fname == "if") {
      yes <- assemble(e[[3]], env)
      no <- if (length(e) > 3) assemble(e[[4]], env) else list(character(0))
      return(c(yes, no))
    }
    if (fname == "{") {
      return(assemble(e[[length(e)]], env))
    }
    if (fname == "(") {
      return(assemble(e[[2]], env))
    }
    ns <- asNamespace("intraclass")
    if (!length(args) && exists(fname, envir = ns, inherits = FALSE)) {
      val <- tryCatch(get(fname, envir = ns)(), error = function(err) NULL)
      if (is.character(val)) {
        return(list(val))
      }
    }
  }
  list(paste0("{", paste(deparse(e), collapse = " "), "}"))
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# Assignments `x <- value` anywhere inside a function body, by symbol.
collect_assign <- function(body) {
  out <- list()
  walk <- function(e) {
    if (is.call(e)) {
      if (identical(e[[1]], as.symbol("<-")) && is.symbol(e[[2]])) {
        nm <- as.character(e[[2]])
        out[[nm]] <<- c(out[[nm]], list(e[[3]]))
      }
      for (x in as.list(e)[-1]) {
        if (!missing(x)) walk(x)
      }
    }
  }
  walk(body)
  out
}

message_arg <- function(call, fname) {
  args <- as.list(call)[-1]
  nms <- names(args) %||% rep("", length(args))
  key <- if (fname == "check_installed") "reason" else "message"
  if (key %in% nms) {
    return(args[[key]])
  }
  if (fname == "check_installed") {
    return(NULL)
  }
  pos <- which(nms == "")
  if (length(pos)) args[[pos[1]]] else NULL
}

call_sites <- function(files) {
  rows <- list()
  for (f in files) {
    exprs <- parse(f, keep.source = TRUE)
    pd <- utils::getParseData(exprs)
    top <- pd[pd$parent == 0 & pd$token == "expr", ]
    hits <- pd[pd$token == "SYMBOL_FUNCTION_CALL" & pd$text %in% ALL_FUNS, ]
    for (i in seq_len(nrow(hits))) {
      call_id <- pd$parent[pd$id == hits$parent[i]]
      txt <- utils::getParseText(pd, call_id)
      call <- str2lang(txt)
      fname <- hits$text[i]
      # A helper's own definition forwards `message`; its callers are the sites.
      arg <- message_arg(call, fname)
      if (is.null(arg)) {
        next
      }
      line <- hits$line1[i]
      host <- top[top$line1 <= line & top$line2 >= line, ]
      env <- new.env()
      env$unresolved <- character(0)
      env$assign <- if (nrow(host)) {
        collect_assign(str2lang(utils::getParseText(pd, host$id[1])))
      } else {
        list()
      }
      if (identical(arg, as.symbol("message"))) {
        next
      }
      variants <- assemble(arg, env)
      rows[[length(rows) + 1L]] <- list(
        file = f,
        line = line,
        fun = fname,
        variants = variants,
        unresolved = unique(env$unresolved)
      )
    }
  }
  rows
}

# --- hint bullets --------------------------------------------------------------

hint_bullets <- function() {
  methods <- c(
    "searle",
    "burch",
    "mpl",
    "npbootstrap",
    "bootstrap",
    "montecarlo"
  )
  subsets <- unlist(
    lapply(0:length(methods), function(k) {
      utils::combn(methods, k, simplify = FALSE)
    }),
    recursive = FALSE
  )
  contrasts <- c("the default", "the method you requested")
  out <- character(0)
  for (s in subsets) {
    usable <- function(m) m %in% s
    for (ct in contrasts) {
      for (seed in list(NULL, 42L)) {
        for (oneway in c(TRUE, FALSE)) {
          for (balanced in c(TRUE, FALSE)) {
            out <- c(
              out,
              boundary_fenced_hint(
                usable = usable,
                contrast = ct,
                oneway = oneway,
                multilevel = FALSE,
                replicates = FALSE,
                raters = "random",
                balanced = balanced,
                type = "agreement",
                type_supplied = FALSE,
                unit = list("single"),
                seed = seed
              )
            )
          }
        }
        out <- c(
          out,
          boundary_engine_hint(
            usable = usable,
            contrast = ct,
            seed = seed,
            boot_samples = 999L
          )
        )
      }
    }
  }
  unique(unname(out))
}

# --- counting -------------------------------------------------------------------

normalize <- function(x) {
  x <- gsub("\\\\\\s*\n\\s*", " ", x)
  x <- gsub("\\s+", " ", x)
  # Collapse balanced `{...}` spans, innermost first, to one word each.
  repeat {
    y <- gsub("\\{[^{}]*\\}", "§", x)
    if (identical(y, x)) {
      break
    }
    x <- y
  }
  trimws(gsub("§", "X", x))
}

split_sentences <- function(p) {
  pieces <- strsplit(p, "(?<=[.!?])[\"')\\]]*\\s+", perl = TRUE)[[1]]
  out <- character(0)
  pending <- ""
  for (piece in pieces) {
    cand <- if (nzchar(pending)) paste(pending, piece) else piece
    last <- tolower(sub(".*\\s", "", cand))
    held <- last %in% ABBREVIATIONS || grepl("(^|\\s)[A-Z]\\.$", cand)
    if (held) {
      pending <- cand
    } else {
      out <- c(out, cand)
      pending <- ""
    }
  }
  if (nzchar(pending)) {
    out <- c(out, pending)
  }
  out[vapply(out, n_words, integer(1)) > 0]
}

n_words <- function(s) {
  w <- strsplit(trimws(s), "\\s+")[[1]]
  sum(grepl("[[:alnum:]]", w))
}

count_dashes <- function(p) {
  m <- gregexpr("—|–|-{2,3}", p)[[1]]
  if (m[1] < 0) {
    return(0L)
  }
  n <- 0L
  for (k in seq_along(m)) {
    s <- m[k]
    e <- s + attr(m, "match.length")[k] - 1L
    before <- if (s > 1) substr(p, s - 1, s - 1) else ""
    after <- if (e < nchar(p)) substr(p, e + 1, e + 1) else ""
    if (grepl("[0-9]", before) && grepl("[0-9]", after)) {
      next
    }
    if (grepl("[A-Za-z]", before) && grepl("[A-Z]", after)) {
      next
    }
    n <- n + 1L
  }
  n
}

measure <- function(label, raw) {
  p <- normalize(raw)
  sents <- split_sentences(p)
  long <- sents[vapply(sents, n_words, integer(1)) > LIMIT]
  r8 <- R8_MARKERS[vapply(R8_MARKERS, grepl, logical(1), x = p, perl = TRUE)]
  list(
    label = label,
    text = p,
    n_sent = length(sents),
    dashes = count_dashes(p),
    long = long,
    r8 = r8
  )
}

profile <- function(files = Sys.glob("R/*.R"), bullets = hint_bullets()) {
  sites <- call_sites(files)
  res <- list()
  for (s in sites) {
    lines <- unique(unlist(s$variants))
    lines <- lines[nzchar(trimws(lines))]
    for (l in lines) {
      res[[length(res) + 1L]] <- measure(sprintf("%s:%d", s$file, s$line), l)
    }
  }
  for (b in bullets) {
    res[[length(res) + 1L]] <- measure("R/boundary-hint.R (bullet)", b)
  }
  list(sites = sites, res = res)
}

report <- function(prof, verbose = FALSE, dump = FALSE) {
  res <- prof$res
  n_dash <- sum(vapply(res, `[[`, integer(1), "dashes"))
  n_long <- sum(vapply(res, function(r) length(r$long), integer(1)))
  n_r8 <- sum(vapply(res, function(r) length(r$r8), integer(1)))
  n_sent <- sum(vapply(res, `[[`, integer(1), "n_sent"))
  unres <- Filter(function(s) length(s$unresolved), prof$sites)
  for (r in res) {
    bad <- r$dashes > 0 || length(r$long) || length(r$r8)
    if (dump || (verbose && bad)) {
      cat(sprintf(
        "%s  [dash %d, long %d, R8 %d]\n  %s\n",
        r$label,
        r$dashes,
        length(r$long),
        length(r$r8),
        r$text
      ))
      for (l in r$long) {
        cat(sprintf("    %d words: %s\n", n_words(l), l))
      }
      for (m in r$r8) {
        cat(sprintf("    R8 marker: %s\n", m))
      }
    }
  }
  if (verbose && length(unres)) {
    for (s in unres) {
      cat(sprintf(
        "unresolved %s:%d  %s\n",
        s$file,
        s$line,
        paste(s$unresolved, collapse = ", ")
      ))
    }
  }
  cat(sprintf(
    "sites %d, lines %d, sentences %d | R1 dashes %d | R2 over %d words %d | R8 %d | unresolved sites %d\n",
    length(prof$sites),
    length(res),
    n_sent,
    n_dash,
    LIMIT,
    n_long,
    n_r8,
    length(unres)
  ))
  n_dash + n_long + n_r8
}

# --- token comparison --------------------------------------------------------------

token_stream <- function(text) {
  pd <- utils::getParseData(parse(text = text, keep.source = TRUE))
  pd <- pd[pd$terminal & pd$token != "COMMENT", ]
  pd <- pd[order(pd$line1, pd$col1), ]
  ifelse(pd$token == "STR_CONST", "S", pd$text)
}

fold_tokens <- function(tok) {
  s <- paste(tok, collapse = " ")
  repeat {
    t <- s
    t <- gsub("(^| )[A-Za-z_.][A-Za-z0-9_.]* = S( |$)", "\\1S\\2", t)
    t <- gsub("(^| )S = S( |$)", "\\1S\\2", t)
    t <- gsub("(^| )(c|paste0|paste) \\( S( , S)* \\)( |$)", "\\1S\\4", t)
    if (identical(t, s)) {
      break
    }
    s <- t
  }
  s
}

glue_exprs <- function(text) {
  pd <- utils::getParseData(parse(text = text, keep.source = TRUE))
  strs <- vapply(
    pd$text[pd$token == "STR_CONST"],
    function(x) {
      eval(str2lang(x))
    },
    character(1)
  )
  m <- unlist(regmatches(strs, gregexpr("\\{[^{}]*\\}", strs)))
  m <- m[!grepl("^\\{[.?]", m)]
  sort(m)
}

compare_tokens <- function(ref, files = Sys.glob("R/*.R")) {
  bad <- 0L
  for (f in files) {
    old <- tryCatch(
      system2(
        "git",
        c("show", paste0(ref, ":", f)),
        stdout = TRUE,
        stderr = FALSE
      ),
      warning = function(w) NULL
    )
    if (is.null(old)) {
      cat(sprintf("%s: not at %s\n", f, ref))
      bad <- bad + 1L
      next
    }
    new <- readLines(f)
    a <- fold_tokens(token_stream(old))
    b <- fold_tokens(token_stream(new))
    if (!identical(a, b)) {
      bad <- bad + 1L
      aa <- strsplit(a, " ")[[1]]
      bb <- strsplit(b, " ")[[1]]
      k <- which(
        aa[seq_len(min(length(aa), length(bb)))] !=
          bb[seq_len(min(length(aa), length(bb)))]
      )[1]
      if (is.na(k)) {
        k <- min(length(aa), length(bb)) + 1L
      }
      ctx <- function(x) {
        paste(x[max(1, k - 8):min(length(x), k + 8)], collapse = " ")
      }
      cat(sprintf(
        "%s: token streams differ\n  %s: ...%s...\n  work: ...%s...\n",
        f,
        ref,
        ctx(aa),
        ctx(bb)
      ))
    }
    ga <- glue_exprs(old)
    gb <- glue_exprs(new)
    if (!identical(ga, gb)) {
      bad <- bad + 1L
      cat(sprintf(
        "%s: glue expressions differ\n  only at %s: %s\n  only here: %s\n",
        f,
        ref,
        paste(setdiff(ga, gb), collapse = " "),
        paste(setdiff(gb, ga), collapse = " ")
      ))
    }
  }
  cat(sprintf(
    "compare-tokens against %s: %d file(s), %d difference(s)\n",
    ref,
    length(files),
    bad
  ))
  bad
}

# --- self-test --------------------------------------------------------------------

self_test <- function() {
  ok <- TRUE
  check <- function(cond, what) {
    if (!isTRUE(cond)) {
      cat("FAIL:", what, "\n")
      ok <<- FALSE
    }
  }
  tmp <- tempfile(fileext = ".R")
  on.exit(unlink(tmp))
  long <- paste(rep("word", 26), collapse = " ")
  writeLines(
    c(
      "f <- function(x) {",
      "  msg <- \"Assigned text — with a dash.\"",
      sprintf("  abort_intraclass(c(\"%s.\", i = \"Fine {.arg x}.\"))", long),
      "  if (x) cli::cli_warn(msg)",
      "  rlang::check_installed(\"pkg\", reason = paste0(\"to do \", \"it -- now.\"))",
      "  abort_unsupported(\"Short {x} text, which is why it fails.\")",
      "}"
    ),
    tmp
  )
  prof <- profile(tmp, bullets = character(0))
  res <- prof$res
  check(length(prof$sites) == 4L, "four planted sites found")
  check(
    sum(vapply(res, function(r) length(r$long), integer(1))) == 1L,
    "the 26-word sentence is over the limit"
  )
  check(
    sum(vapply(res, `[[`, integer(1), "dashes")) == 2L,
    "the em dash (via an assignment) and the spaced -- (via paste0) are counted"
  )
  check(
    sum(vapply(res, function(r) length(r$r8), integer(1))) == 1L,
    "the R8 marker is found"
  )
  check(
    !any(vapply(prof$sites, function(s) length(s$unresolved) > 0, logical(1))),
    "the assigned symbol resolves"
  )
  check(
    n_words(normalize("{.code ci_method = \"searle\"} runs.")) == 2L,
    "a markup span is one word"
  )
  check(
    count_dashes("Spearman--Brown and 1--2") == 0L,
    "joined names and digit ranges are not dashes"
  )
  # Token comparison: a split into bullets passes, a changed class does not.
  a <- "f <- function() abort_intraclass(\"One. Two.\", class = \"k\")"
  b <- "f <- function() abort_intraclass(c(\"One.\", i = \"Two.\"), class = \"k\")"
  d <- "f <- function() abort_intraclass(\"One. Two.\", class = k2)"
  check(
    identical(fold_tokens(token_stream(a)), fold_tokens(token_stream(b))),
    "a split into bullets folds to the same stream"
  )
  check(
    !identical(fold_tokens(token_stream(a)), fold_tokens(token_stream(d))),
    "a changed class argument differs"
  )
  check(
    !identical(
      glue_exprs("x <- \"{n} rows\""),
      glue_exprs("x <- \"{m} rows\"")
    ),
    "a changed glue expression differs"
  )
  check(length(hint_bullets()) > 0L, "the hint builders emit bullets")
  cat(if (ok) "self-test: OK\n" else "self-test: FAILED\n")
  ok
}

# --- main -------------------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
if ("--self-test" %in% args) {
  quit(status = if (self_test()) 0L else 1L)
}
if ("--compare-tokens" %in% args) {
  ref <- args[which(args == "--compare-tokens") + 1L]
  quit(status = if (compare_tokens(ref) == 0L) 0L else 1L)
}
hits <- report(
  profile(),
  verbose = "--verbose" %in% args,
  dump = "--dump" %in% args
)
quit(status = if (hits == 0L) 0L else 1L)
