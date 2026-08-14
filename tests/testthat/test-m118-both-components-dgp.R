# M118's DGP fence -- the mirror image of M116's.
#
# M116 asserts that the two OLDER sweep scripts draw the residual from a normal
# and nothing else, which is what bounds the width claims those grids support.
# This file asserts the opposite property of the NEW script: that both the
# subject effect and the residual come from the cell's family. The whole point of
# M118 is that condition, so a generator that quietly reverted to a normal
# residual would produce a fourth subject-effect-only grid while every figure it
# wrote claimed otherwise.
#
# Checked on the PARSED body, never on line text -- M116 recorded two weaker
# guards that were defeated, and both failure modes apply here unchanged: a
# lexical search for `rt(` matches inside `sqrt(`, and a positional rule is
# beaten by hoisting the offending draw one line up. `data-raw/m118-dgp-fence-mutations.R`
# runs THIS file's definition against mutated copies (it sys.source()s the file
# with `test_that` stubbed), so the harness and the guard can never drift apart.

sweep_script <- testthat::test_path(
  "..",
  "..",
  "data-raw",
  "m118-width-reversal-sweep.R"
)

# every random-generator function called anywhere inside `expr`, namespace-
# qualified calls included (`stats::rnorm` resolves to "rnorm")
m118_rng_calls <- function(expr) {
  out <- character(0)
  walk <- function(e) {
    if (is.call(e)) {
      fn <- e[[1]]
      nm <- if (is.name(fn)) {
        as.character(fn)
      } else if (is.call(fn) && identical(as.character(fn[[1]]), "::")) {
        as.character(fn[[3]])
      } else {
        ""
      }
      if (
        grepl("^r[a-z]+$", nm) && !nm %in% c("rep", "return", "round", "rev")
      ) {
        out <<- c(out, nm)
      }
      for (i in seq_along(e)) {
        if (!is.null(e[[i]]) && !identical(e[[i]], quote(expr = ))) walk(e[[i]])
      }
    }
  }
  walk(expr)
  out
}

# calls to `fname` anywhere inside `expr`, returned as a list of call objects
m118_calls_to <- function(expr, fname) {
  out <- list()
  walk <- function(e) {
    if (is.call(e)) {
      fn <- e[[1]]
      if (is.name(fn) && identical(as.character(fn), fname)) {
        out[[length(out) + 1L]] <<- e
      }
      for (i in seq_along(e)) {
        if (!is.null(e[[i]]) && !identical(e[[i]], quote(expr = ))) walk(e[[i]])
      }
    }
  }
  walk(expr)
  out
}

# `e[[1]]` is not always a symbol at top level -- a `pkg::fn(...)` call has a
# call there, and as.character() on it returns length 3, so the operator test
# must check for a name first.
m118_is_assign <- function(e) {
  is.call(e) &&
    is.name(e[[1]]) &&
    as.character(e[[1]]) %in% c("<-", "=") &&
    is.name(e[[2]])
}

m118_top_assign <- function(exprs, nm) {
  hit <- NULL
  for (e in exprs) {
    if (m118_is_assign(e) && identical(as.character(e[[2]]), nm)) {
      hit <- e[[3]]
    }
  }
  hit
}

assert_both_components_dgp <- function(path) {
  exprs <- as.list(parse(path))

  gen <- m118_top_assign(exprs, "gen_oneway")
  if (is.null(gen)) {
    stop("gen_oneway() not found in ", path)
  }
  draw <- m118_top_assign(exprs, "draw_standard")
  if (is.null(draw)) {
    stop("draw_standard() not found in ", path)
  }

  gen_body <- body(eval(gen))
  body_exprs <- as.list(gen_body)
  assigns <- Filter(m118_is_assign, body_exprs)
  named <- function(nm) {
    hit <- Filter(function(e) identical(as.character(e[[2]]), nm), assigns)
    if (length(hit) != 1L) {
      stop("expected exactly one `", nm, " <- ...` in gen_oneway of ", path)
    }
    hit[[1]][[3]]
  }

  # 1. gen_oneway draws NOTHING itself. This is the clause that survives the two
  #    break forms a per-component check misses: a draw hoisted into its own
  #    variable above the component, and a namespace-qualified `stats::rnorm`.
  direct <- m118_rng_calls(gen_body)
  if (length(direct)) {
    stop(
      "gen_oneway draws directly instead of delegating to draw_standard(): ",
      paste(unique(direct), collapse = ", ")
    )
  }

  # 2. BOTH components are drawn by draw_standard(), each passing the cell's
  #    `dist` through. Checking only one of them is what would let the residual
  #    silently revert to a fixed family.
  for (nm in c("a", "e")) {
    rhs <- named(nm)
    calls <- m118_calls_to(rhs, "draw_standard")
    if (length(calls) != 1L) {
      stop("component `", nm, "` does not call draw_standard() exactly once")
    }
    args <- as.list(calls[[1]])[-1]
    passes_dist <- any(vapply(
      args,
      function(x) is.name(x) && identical(as.character(x), "dist"),
      logical(1)
    ))
    if (!passes_dist) {
      stop("component `", nm, "` calls draw_standard() without passing dist")
    }
  }

  # 3. draw_standard actually branches on dist, so passing it through means
  #    something.
  draw_txt <- paste(deparse(draw), collapse = " ")
  if (!grepl("switch\\s*\\(\\s*dist", draw_txt)) {
    stop("draw_standard() does not switch on dist")
  }
  invisible(TRUE)
}

test_that("the M118 generator draws both components from the cell's family", {
  skip_if_not(
    file.exists(sweep_script),
    "data-raw/ not present (built package)"
  )
  expect_true(assert_both_components_dgp(sweep_script))
})

test_that("the M118 sweep script is not in M116's subject-only fence list", {
  skip_if_not(
    file.exists(sweep_script),
    "data-raw/ not present (built package)"
  )
  m116 <- testthat::test_path(
    "..",
    "..",
    "data-raw",
    "m116-classical-width-comparison.R"
  )
  skip_if_not(file.exists(m116), "data-raw/ not present (built package)")
  txt <- paste(readLines(m116, warn = FALSE), collapse = "\n")
  # M116's fence asserts the OPPOSITE property; adding this script to its list
  # would assert that M118's residual is normal, which is the defect this
  # milestone exists to avoid.
  expect_false(grepl("m118-width-reversal-sweep", txt, fixed = TRUE))
})
