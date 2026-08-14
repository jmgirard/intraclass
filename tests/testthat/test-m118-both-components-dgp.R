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

# every symbol assigned anywhere inside `expr`, at any nesting depth, by any of
# `<-`, `=` or `<<-`
m118_assign_targets <- function(expr) {
  out <- character(0)
  walk <- function(e) {
    if (is.call(e)) {
      if (
        is.name(e[[1]]) &&
          as.character(e[[1]]) %in% c("<-", "=", "<<-") &&
          length(e) >= 3L &&
          is.name(e[[2]])
      ) {
        out <<- c(out, as.character(e[[2]]))
      }
      for (i in seq_along(e)) {
        if (!is.null(e[[i]]) && !identical(e[[i]], quote(expr = ))) walk(e[[i]])
      }
    }
  }
  walk(expr)
  unique(out)
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

  # 1b. No parameter is rebound inside the body. Clause 2 below checks that the
  #     SYMBOL `dist` reaches draw_standard(); without this clause it cannot
  #     tell that symbol from a local of the same name, so a single
  #     `dist <- "gaussian"` at the top of the body satisfies every other clause
  #     while making all 125 cells gaussian (a nominal t5 cell then yields
  #     pooled excess kurtosis -0.086). Found at the M118 review; the guard was
  #     green against it. `rho`, `k` and `n` are covered too because rebinding
  #     any of them corrupts the design a cell's label claims.
  #     Walked over the WHOLE body, not just its top level: a rebinding nested
  #     in an `if` or a braced block is the same defect one indent down.
  params <- names(formals(eval(gen)))
  rebound <- intersect(m118_assign_targets(gen_body), params)
  if (length(rebound)) {
    stop(
      "gen_oneway rebinds its own parameter(s), so a cell need not use what ",
      "its label says: ",
      paste(rebound, collapse = ", ")
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

test_that("gen_oneway composes the two components so the population ICC is the cell's", {
  skip_if_not(
    file.exists(sweep_script),
    "data-raw/ not present (built package)"
  )
  # The AST fence above checks WHERE the draws come from. It cannot see how they
  # are COMBINED, and two mutations found at the M118 review pass it while
  # corrupting the truth every coverage figure is scored against:
  # `sd_a <- rho` gives icc_hat 0.346 and `rep(a, times = n)` gives 0.015, both
  # against a cell claiming 0.5. This leg pins the composition instead of the
  # source, which is the "located and scaled per burch2011 sec 3 so the
  # population ICC equals the cell's rho" property the milestone Scope asserts.
  #
  # Tolerance 0.10 against a measured legitimate spread of at most 0.073 over
  # six seeds (chisq1, the worst) and a nearest mutation at 0.154 -- it
  # separates the two without sitting on either. Seeds are fixed, so this is
  # deterministic and cannot flake.
  # Only the definitions this leg needs are evaluated -- the script calls
  # devtools::load_all() and runs a sweep at top level, so it must never be
  # sourced whole from a test. `classical_oneway_ss()` is the package's own.
  env <- new.env(parent = globalenv())
  wanted <- c("draw_standard", "pe_beta", "table2_kurtosis", "gen_oneway")
  for (e in as.list(parse(sweep_script))) {
    if (m118_is_assign(e) && as.character(e[[2]]) %in% wanted) {
      eval(e, envir = env)
    }
  }
  expect_setequal(ls(env), wanted)

  icc_hat <- function(g) {
    ss <- classical_oneway_ss(g)
    (ss$msa - ss$mse) / (ss$msa + (ss$n - 1) * ss$mse)
  }
  for (fam in names(env$table2_kurtosis)) {
    g <- env$gen_oneway(400L, 5L, 0.5, fam, 900001L)
    expect_lt(abs(icc_hat(g) - 0.5), 0.10, label = paste("icc_hat", fam))
  }
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
