# Mutation harness for M118's DGP fence.
#
# A guard that has never been seen to fail is not evidence. This file plants a
# family of defects in a scratch copy of the sweep script and requires the fence
# to reject every one -- and to accept the unmutated file, so a fence that
# rejected everything could not pass either.
#
# The mutations vary FORM as well as SITE, which is the point. M116 recorded two
# guards defeated by form alone (a lexical `rt(` match inside `sqrt(`; a
# positional rule beaten by hoisting the draw one line up), and reverting one
# component to `rnorm` has at least three spellings that a single-form probe
# would miss.
#
# The fence definition is NOT copied here. This sources the test file with
# `test_that` stubbed to a no-op, so there is exactly one definition of the
# guard and the harness cannot drift from what the suite runs (the M117
# technique).
#
# Run: Rscript data-raw/m118-dgp-fence-mutations.R

stopifnot("run this from the repo root" = file.exists("DESCRIPTION"))

test_file_path <- "tests/testthat/test-m118-both-components-dgp.R"
sweep_path <- "data-raw/m118-width-reversal-sweep.R"

# --- load the fence, without running the suite --------------------------------
env <- new.env(parent = globalenv())
env$test_that <- function(...) invisible(NULL)
env$testthat <- list()
local(
  {
    testthat <- asNamespace("testthat")
  },
  envir = env
)
sys.source(test_file_path, envir = env, keep.source = FALSE)
fence <- get("assert_both_components_dgp", envir = env)

src <- readLines(sweep_path, warn = FALSE)

# --- the mutation family ------------------------------------------------------
# `from` must occur exactly once in the script, or the mutation silently lands
# somewhere unintended and a green result means nothing (tracking-rules:
# verify a batched edit landed).
mutations <- list(
  list(
    name = "residual: direct rnorm substitution",
    from = "  e <- sd_e * draw_standard(k * n, dist)",
    to = "  e <- sd_e * stats::rnorm(k * n)"
  ),
  list(
    name = "residual: draw hoisted above its use",
    from = "  e <- sd_e * draw_standard(k * n, dist)",
    to = "  e_raw <- rnorm(k * n)\n  e <- sd_e * e_raw"
  ),
  list(
    name = "residual: namespace-qualified, unscaled",
    from = "  e <- sd_e * draw_standard(k * n, dist)",
    to = "  e <- stats::rnorm(k * n, 0, sd_e)"
  ),
  list(
    name = "residual: family hard-coded, dist not passed",
    from = "  e <- sd_e * draw_standard(k * n, dist)",
    to = "  e <- sd_e * draw_standard(k * n, \"gaussian\")"
  ),
  list(
    name = "subject effect: direct rnorm substitution",
    from = "  a <- sd_a * draw_standard(k, dist)",
    to = "  a <- sd_a * rnorm(k)"
  ),
  list(
    name = "subject effect: draw hoisted above its use",
    from = "  a <- sd_a * draw_standard(k, dist)",
    to = "  a_raw <- stats::rt(k, df = 5)\n  a <- sd_a * a_raw"
  ),
  list(
    name = "dispatcher: draw_standard stops branching on dist",
    from = "    dist,",
    to = "    \"gaussian\","
  )
)

apply_mutation <- function(src, mut) {
  hits <- which(src == mut$from)
  if (length(hits) != 1L) {
    stop(
      "mutation `",
      mut$name,
      "` anchors on ",
      length(hits),
      " lines; expected exactly 1 -- re-anchor it"
    )
  }
  out <- append(
    src[-hits],
    strsplit(mut$to, "\n", fixed = TRUE)[[1]],
    after = hits - 1L
  )
  out
}

# --- run ----------------------------------------------------------------------
cat("M118 DGP fence -- mutation harness\n\n")

baseline <- tryCatch(
  {
    fence(sweep_path)
    "accepted"
  },
  error = function(e) paste0("REJECTED: ", conditionMessage(e))
)
cat(sprintf("  %-52s %s\n", "unmutated script (must be accepted)", baseline))
if (!identical(baseline, "accepted")) {
  stop(
    "the fence rejects the real script; every mutation result below is meaningless"
  )
}

failures <- character(0)
for (mut in mutations) {
  tmp <- tempfile(fileext = ".R")
  writeLines(apply_mutation(src, mut), tmp)
  reds <- tryCatch(
    {
      fence(tmp)
      FALSE
    },
    error = function(e) TRUE
  )
  unlink(tmp)
  cat(sprintf(
    "  %-52s %s\n",
    mut$name,
    if (reds) "red (good)" else "GREEN -- MISSED"
  ))
  if (!reds) failures <- c(failures, mut$name)
}

cat("\n")
if (length(failures)) {
  stop(
    length(failures),
    " of ",
    length(mutations),
    " mutations survived the fence: ",
    paste(failures, collapse = "; ")
  )
}
cat("all ", length(mutations), " mutations rejected by the fence\n", sep = "")
