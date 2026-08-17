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
  engines_omit_brms_and = "Fits run on mixed-model engines (`glmmTMB`, `lme4`) and an SEM engine.",
  install_four_marked = "The base install is light -- only `glmmTMB`, `cli`, `rlang`, and `generics`.",
  install_four_alpha = "The base install is light -- only `cli`, `generics`, `glmmTMB`, and `rlang`.",
  design_never_declare = "The design is inferred from the crossing pattern, so you never declare it.",
  design_never_declare_alt = "The design is inferred, so you never declare the design yourself."
)

# Every spelling named in the pin file must appear above. This is what stops
# the harness drifting into testing a stale subset while a newly added pin goes
# unexercised -- the failure M118 hit twice.
pin_src <- readLines(pin_file, warn = FALSE)
pin_names <- sub(
  "^\\s*([A-Za-z_][A-Za-z0-9_]*)\\s*=.*$",
  "\\1",
  grep(
    "^\\s*(bayes|engines_omit|install_four|design_never)[A-Za-z0-9_]*\\s*=",
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

# Surfaces, one per markup regime the two walks read: markdown prose that the
# installed leg also sees, roxygen that only the source leg sees, and the
# `README.Rmd` source that neither the installed leg nor a built tarball can
# see. Each plant goes at the file's end, where no syntax is disturbed.
surfaces <- list(
  "README.Rmd" = list(path = "README.Rmd", prefix = ""),
  "R/icc.R" = list(path = "R/icc.R", prefix = "#' "),
  "vignettes/multilevel-designs.Rmd" = list(
    path = "vignettes/multilevel-designs.Rmd",
    prefix = ""
  )
)
stopifnot(
  "a declared surface is missing" = all(vapply(
    surfaces,
    function(s) file.exists(s$path),
    logical(1)
  ))
)

run_pins <- function() {
  res <- testthat::test_file(pin_file, reporter = "silent", package = NULL)
  df <- as.data.frame(res)
  sum(df$failed) + sum(df$error)
}

plant_and_run <- function(path, lines) {
  original <- readLines(path, warn = FALSE)
  on.exit(writeLines(original, path), add = TRUE)
  writeLines(c(original, lines), path)
  run_pins()
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
cat("floor holds: every planted claim reds at every surface and wrap form.\n")
