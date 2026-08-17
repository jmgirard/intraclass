# Mutation harness for M123's capability-claim pins in
# tests/testthat/test-doc-skew-caveat.R.
#
# A withdrawal pin is worthless until a restored sentence has been shown to
# trip it, and "I planted a phrase and it reddened" is only evidence about the
# phrase that was planted, in the wrap form it was planted in. M123's first
# pass ran exactly such a matrix -- 27 plants, all red -- and still shipped a
# pin that returned FALSE against the real pre-correction sentence, because
# that sentence lives inside a `> [!NOTE]` markdown callout and no plant wore a
# blockquote marker. This harness is committed so the matrix is re-runnable and
# auditable, per the m95/m117/m118 precedent.
#
# Run: Rscript data-raw/m123-capability-claim-mutations.R
# It writes nothing outside stdout. Each plant edits a tracked file in place,
# runs the pin file, then restores the file from the bytes read before the
# edit; the restore also runs on error and on interrupt.
#
# The control is the unmutated tree: it must trip NOTHING. A harness whose
# control reds is measuring its own breakage, not the pins.

pin_file <- "tests/testthat/test-doc-skew-caveat.R"
stopifnot("run me from the package root" = file.exists(pin_file))

# The four claims M123 withdrew, each with the spellings the pin vector names.
# Kept in sync by the two-way `stopifnot` below, which reads the spelling names
# out of the pin file rather than trusting this list.
spellings <- list(
  bayes_roadmap = "A Bayesian engine is on the roadmap; see the roadmap file.",
  bayes_planned = "A Bayesian engine is planned for a later release.",
  bayes_not_yet = "A Bayesian engine is not yet available.",
  engines_omit_brms = "Fits run on mixed-model engines (`glmmTMB`, `lme4`) or an SEM engine.",
  engines_omit_brms_bare = "Fits run on mixed-model engines (glmmTMB, lme4) or an SEM engine.",
  install_four_marked = "The base install is light -- only `glmmTMB`, `cli`, `rlang`, and `generics`.",
  install_four_bare = "The base install is light -- only glmmTMB, cli, rlang, and generics.",
  design_never_declare = "The layout is inferred from the data \u2014 you never declare it, ever.",
  design_never_declare_alt = "The design is inferred, so you never declare the design yourself.",
  install_pulls_news = "It now names every non-base package the install pulls, at last.",
  install_arrives_readme = "Note that glmmTMB imports lme4, so that one arrives with the default engine anyway."
)

# Every spelling named in the pin file must appear above. This is what stops
# the harness drifting into testing a stale subset while a newly added pin goes
# unexercised -- the failure M118 hit twice.
pin_src <- readLines(pin_file, warn = FALSE)
pin_names <- sub(
  "^\\s*([A-Za-z_][A-Za-z0-9_]*)\\s*=.*$",
  "\\1",
  grep(
    "^\\s*(bayes|engines_omit|install_|design_never)[A-Za-z0-9_]*\\s*=",
    pin_src,
    value = TRUE
  )
)
stopifnot(
  "pin file names a spelling this harness does not plant" = all(
    pin_names %in% names(spellings)
  ),
  "this harness plants a spelling the pin file does not name" = all(
    names(spellings) %in% pin_names
  )
)

# Wrap forms. `flat` is the trivial case; the other three are the shapes a
# `fixed = TRUE` match over un-squashed text misses, and that `squash()` plus
# the line-prefix strips must reconstruct.
#
# `blockquote` is the form that got past the first pass: the marker repeats on
# the continuation line, landing mid-sentence after the join unless it is
# stripped per line BEFORE the join.
wrap_forms <- list(
  flat = function(sentence, prefix) paste0(prefix, sentence),
  wrapped = function(sentence, prefix) {
    at <- split_point(sentence)
    c(
      paste0(prefix, substr(sentence, 1L, at - 1L)),
      paste0(prefix, substr(sentence, at + 1L, nchar(sentence)))
    )
  },
  blockquote = function(sentence, prefix) {
    at <- split_point(sentence)
    c(
      paste0(prefix, "> [!NOTE]"),
      paste0(prefix, "> ", substr(sentence, 1L, at - 1L)),
      paste0(prefix, "> ", substr(sentence, at + 1L, nchar(sentence)))
    )
  },
  blockquote_indented = function(sentence, prefix) {
    at <- split_point(sentence)
    c(
      paste0(prefix, ">  ", substr(sentence, 1L, at - 1L)),
      paste0(prefix, ">> ", substr(sentence, at + 1L, nchar(sentence)))
    )
  }
)

# Break at a space near the middle, so the wrap lands INSIDE the matched
# phrase rather than beside it. A split at the sentence edge would leave the
# pattern whole on one line and prove nothing about the join.
split_point <- function(sentence) {
  spaces <- gregexpr(" ", sentence, fixed = TRUE)[[1]]
  spaces <- spaces[spaces > 0L]
  stopifnot("no space to wrap at" = length(spaces) > 0L)
  spaces[which.min(abs(spaces - nchar(sentence) / 2))]
}

# Source-leg surfaces: two markup regimes the source walk reads differently --
# markdown prose, and roxygen, whose `#'` prefix is stripped per line before the
# join. Two is AC6's floor; adding the vignette and `README.md` here would
# double the matrix without varying the regime, and `README.md` is planted on
# the installed leg below, where it is the surface that actually matters.
# Each plant goes at the file's end, where no syntax is disturbed.
surfaces <- list(
  "README.Rmd" = list(path = "README.Rmd", prefix = ""),
  "R/icc.R" = list(path = "R/icc.R", prefix = "#' ")
)
stopifnot(
  "a declared surface is missing" = all(vapply(
    surfaces,
    function(s) file.exists(s$path),
    logical(1)
  ))
)

# Installed-leg surfaces: the plain-text files a real install carries. These are
# planted in the LIBRARY TREE, not in the source -- planting a source file and
# running against the installed package would leave every installed-leg cell
# green, since the installed copy is untouched. `Rd:*` is not here: the
# installed help database is a binary lazy-load `.rdb`, so exercising it needs
# document() + reinstall per plant, which is deferred with the rest of the
# per-class reachability work (ROADMAP candidate row).
#
# `load_all` is deliberately NOT used for these cells. Its `system.file()` shim
# falls back to the package root, which is exactly how M123's first two rounds
# reported installed-leg coverage they did not have.
installed_targets <- function() {
  # The library path is resolved in a SUBPROCESS for the same reason the cells
  # are run in one: this process has called `load_all()`, under which
  # `system.file()` answers with the checkout. Asking in-process reports the
  # source tree, the guard below then refuses it, and the whole installed leg
  # silently skips -- which is what happened on this harness's first run.
  out <- suppressWarnings(system2(
    "Rscript",
    c("-e", shQuote('cat(system.file(package = "intraclass"))')),
    stdout = TRUE,
    stderr = FALSE
  ))
  lib <- utils::tail(out, 1)
  if (!nzchar(lib) || identical(normalizePath(lib), normalizePath("."))) {
    return(list())
  }
  out <- list()
  readme <- file.path(lib, "README.md")
  if (file.exists(readme)) {
    out[["README.md"]] <- readme
  }
  news <- file.path(lib, "NEWS.md")
  if (file.exists(news)) {
    out[["NEWS.md"]] <- news
  }
  vig <- list.files(
    file.path(lib, "doc"),
    pattern = "[.]Rmd$",
    full.names = TRUE
  )
  if (length(vig)) {
    out[[paste0("vignette:", basename(vig[1]))]] <- vig[1]
  }
  out
}

run_pins <- function() {
  res <- testthat::test_file(pin_file, reporter = "silent", package = NULL)
  df <- as.data.frame(res)
  sum(df$failed) + sum(df$error)
}

# The installed leg runs the pin file against the INSTALLED build, in a FRESH
# SUBPROCESS. That is not fastidiousness: this process has already called
# `pkgload::load_all()` for the source cells, and under a dev-loaded namespace
# `system.file()` keeps resolving to the checkout no matter what
# `load_package = "installed"` asks for -- so an in-process installed cell
# would re-read the source file and report coverage it does not have, which is
# the exact defect (M116's shadowing) this leg exists to rule out.
run_pins_installed <- function() {
  code <- paste(
    'r <- as.data.frame(testthat::test_dir("tests/testthat",',
    'package = "intraclass", load_package = "installed",',
    'filter = "doc-skew-caveat", reporter = "silent",',
    "stop_on_failure = FALSE));",
    "cat(sum(r$failed) + sum(r$error))"
  )
  out <- suppressWarnings(system2(
    "Rscript",
    c("-e", shQuote(code)),
    stdout = TRUE,
    stderr = FALSE
  ))
  n <- suppressWarnings(as.integer(utils::tail(out, 1)))
  stopifnot("installed-leg subprocess produced no count" = !is.na(n))
  n
}

# And prove the subprocess really reads the library tree before trusting any
# cell it reports. A harness that cannot tell the two apart is the thing that
# shipped twice here already.
assert_installed_leg_is_real <- function() {
  out <- suppressWarnings(system2(
    "Rscript",
    c("-e", shQuote('cat(system.file("README.md", package = "intraclass"))')),
    stdout = TRUE,
    stderr = FALSE
  ))
  path <- utils::tail(out, 1)
  stopifnot(
    "installed leg resolves to the source tree, not the library" = nzchar(
      path
    ) &&
      !identical(normalizePath(dirname(path)), normalizePath("."))
  )
  path
}

plant_and_run <- function(path, lines, runner = run_pins) {
  original <- readBin(path, "raw", file.size(path))
  on.exit(writeBin(original, path), add = TRUE)
  con <- file(path, open = "ab")
  writeLines(c("", lines), con)
  close(con)
  runner()
}

suppressMessages(pkgload::load_all(".", quiet = TRUE))

baseline <- run_pins()
cat(sprintf("control (unmutated tree): %d failure(s)\n\n", baseline))
stopifnot(
  "control reds -- the harness is measuring its own breakage" = baseline == 0L
)

rows <- list()
for (sp in names(spellings)) {
  for (sf in names(surfaces)) {
    for (wf in names(wrap_forms)) {
      lines <- wrap_forms[[wf]](spellings[[sp]], surfaces[[sf]]$prefix)
      n <- plant_and_run(surfaces[[sf]]$path, lines)
      rows[[length(rows) + 1L]] <- data.frame(
        spelling = sp,
        surface = sf,
        wrap = wf,
        failures = n,
        verdict = if (n > baseline) "RED" else "GREEN",
        stringsAsFactors = FALSE
      )
      cat(sprintf(
        "%-26s %-32s %-20s %2d %s\n",
        sp,
        sf,
        wf,
        n,
        if (n > baseline) "RED" else "GREEN <-- UNGUARDED"
      ))
    }
  }
}
matrix_rows <- do.call(rbind, rows)

cat(sprintf(
  "\n%d plants, %d RED, %d GREEN\n",
  nrow(matrix_rows),
  sum(matrix_rows$verdict == "RED"),
  sum(matrix_rows$verdict == "GREEN")
))

# The floor: every plant reds. A GREEN cell is a sentence a maintainer can
# restore to a swept surface without the suite noticing -- exactly the defect
# this milestone's review returned on.
stopifnot(
  "a planted claim did not red -- that surface/wrap is unguarded" = all(
    matrix_rows$verdict == "RED"
  )
)
stopifnot(
  "a planted claim did not red -- that surface/wrap is unguarded" = all(
    matrix_rows$verdict == "RED"
  )
)
cat("source leg: every planted claim reds at every surface and wrap form.\n\n")

# ---- installed leg -------------------------------------------------------
# One wrap form per cell (the blockquote, the shape that defeated round 1),
# across every plain-text surface a real install carries.
targets <- installed_targets()
if (!length(targets)) {
  cat("installed leg SKIPPED: package not installed, or system.file resolves\n")
  cat("to the source tree (run devtools::install() first).\n")
} else {
  assert_installed_leg_is_real()
  ibase <- run_pins_installed()
  cat(sprintf("installed control: %d failure(s)\n", ibase))
  stopifnot("installed control reds" = ibase == 0L)
  irows <- list()
  for (sp in names(spellings)) {
    for (tg in names(targets)) {
      lines <- wrap_forms$blockquote(spellings[[sp]], "")
      n <- plant_and_run(targets[[tg]], lines, runner = run_pins_installed)
      irows[[length(irows) + 1L]] <- data.frame(
        spelling = sp,
        surface = tg,
        failures = n,
        verdict = if (n > ibase) "RED" else "GREEN",
        stringsAsFactors = FALSE
      )
      cat(sprintf(
        "%-26s %-28s %2d %s\n",
        sp,
        tg,
        n,
        if (n > ibase) "RED" else "GREEN <-- UNGUARDED"
      ))
    }
  }
  irows <- do.call(rbind, irows)
  cat(sprintf(
    "\ninstalled leg: %d plants, %d RED, %d GREEN\n",
    nrow(irows),
    sum(irows$verdict == "RED"),
    sum(irows$verdict == "GREEN")
  ))
  stopifnot(
    "a planted claim did not red on the installed leg" = all(
      irows$verdict == "RED"
    )
  )
  cat("installed leg: every planted claim reds at every plain-text surface.\n")
}
