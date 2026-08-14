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

  # 3. draw_standard dispatches on the `dist` it is handed. This is a check over
  #    draw_standard's body, NOT gen_oneway's, so it is outside what AC2's
  #    clause (a) promises -- kept because it is a real catch and costs nothing,
  #    not because the criterion rests on it.
  #
  #    It replaces a `grepl("switch\\s*\\(\\s*dist", deparse(draw))` that stood
  #    here until the M118 review: a lexical match on deparsed text, in a guard
  #    whose whole point is reading the parsed body. That form false-red on a
  #    legitimate `switch(EXPR = dist, ...)` and passed a dead nested
  #    `switch(dist, ...)` beside a hard-coded dispatch. On the AST both go the
  #    right way: the EXPR spelling is the same call, and a dead one is not the
  #    call whose value is returned.
  switches <- m118_calls_to(body(eval(draw)), "switch")
  dispatches_on_dist <- any(vapply(
    switches,
    function(cl) {
      a <- as.list(cl)[-1]
      nm <- names(a)
      expr_arg <- if (!is.null(nm) && "EXPR" %in% nm) a[["EXPR"]] else a[[1]]
      is.name(expr_arg) && identical(as.character(expr_arg), "dist")
    },
    logical(1)
  ))
  if (!dispatches_on_dist) {
    stop("draw_standard() does not dispatch on dist")
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

# Leg (b) of AC2, as a callable so `data-raw/m118-dgp-fence-mutations.R` can run
# THIS definition against mutated copies rather than a second copy of it (the
# M117 technique, already used for the AST fence above).
#
# The AST fence checks WHERE the draws come from. It cannot see how they are
# COMBINED, and two mutations found at the M118 review pass it while corrupting
# the truth every coverage figure is scored against: `sd_a <- rho` and
# `rep(a, times = n)`.
#
# Per-rho tolerances, because a flat one cannot work. Measured legitimate spread
# is 0.0288 / 0.0572 / 0.0727 at rho 0.05 / 0.25 / 0.50; the nearest mutation is
# 0.0795 / 0.1997 / 0.1770. A flat 0.10 would leave the rho = 0.05 cell inert --
# both the scale error and the mis-composition sit BELOW it there -- while 0.05
# at that rho catches all three. Every figure is printed by
# data-raw/m118-composition-spread.R.
#
# Three rho and not one, because rho = 0.5 is the fixed point of rho <-> 1 - rho:
# a subject/residual scale swap is EXACTLY a no-op there at any tolerance, and
# shows only at another rho (0.3227 at 0.25, 0.5227 at 0.05). The single-rho
# version of this leg shipped blind to it.
m118_composition_tol <- c("0.05" = 0.05, "0.25" = 0.10, "0.5" = 0.10)

m118_gen_defs <- function(path) {
  env <- new.env(parent = globalenv())
  wanted <- c("draw_standard", "pe_beta", "table2_kurtosis", "gen_oneway")
  for (e in as.list(parse(path))) {
    if (m118_is_assign(e) && as.character(e[[2]]) %in% wanted) {
      eval(e, envir = env)
    }
  }
  missing <- setdiff(wanted, ls(env))
  if (length(missing)) {
    stop("not found in ", path, ": ", paste(missing, collapse = ", "))
  }
  env
}

m118_icc_hat <- function(g) {
  ss <- classical_oneway_ss(g)
  (ss$msa - ss$mse) / (ss$msa + (ss$n - 1) * ss$mse)
}

# worst |icc_hat - rho| over the seven families at one rho
m118_composition_dev <- function(env, rho) {
  max(vapply(
    names(env$table2_kurtosis),
    function(fam) {
      abs(m118_icc_hat(env$gen_oneway(400L, 5L, rho, fam, 900001L)) - rho)
    },
    numeric(1)
  ))
}

assert_composition_icc <- function(path) {
  env <- m118_gen_defs(path)
  for (rho in c(0.05, 0.25, 0.5)) {
    dev <- m118_composition_dev(env, rho)
    tol <- m118_composition_tol[[as.character(rho)]]
    if (dev >= tol) {
      stop(
        "gen_oneway does not recover the cell's ICC at rho = ",
        rho,
        ": worst deviation ",
        signif(dev, 4),
        " against tolerance ",
        tol
      )
    }
  }
  invisible(TRUE)
}

test_that("gen_oneway composes the two components so the population ICC is the cell's", {
  skip_if_not(
    file.exists(sweep_script),
    "data-raw/ not present (built package)"
  )
  expect_true(assert_composition_icc(sweep_script))
})

# The check over the SHIPPED table, which is what AC2 rests on. Everything else
# in this file reads the generator's source or re-runs it at a chosen point, and
# a corruption conditioned on rho, k, n or block is free of all of them -- the
# M118 review defeated the source fence three times and then defeated a
# one-cell re-run with four lines gated on `rho != 0.25`.
#
# This leg reads the committed fixture instead: within every (block, rho, k, n)
# group, the families' mean length ratios must be pairwise distinct. A grid
# whose cells all drew the same family collapses every group to a single value
# and reds here, whatever the generator's source looks like.
#
# It decides distinctness, NOT correctness -- it cannot tell t(5) from t(10),
# only that the seven labels are not all the same data. AC3's kurtosis tests own
# per-family identity. The pin is 0.005 against a measured worst of 0.0130
# (fig2, k = 20) and 0.0508 (m111), so the real table clears it by 2.6x at its
# tightest. Distinctness is strictly weaker than W1's sign rule, so this is not
# circular with the verdict it protects.
test_that("every shipped group's families are pairwise distinct in width ratio", {
  fixture <- testthat::test_path("fixtures", "width-reversal-by-cell.tsv")
  skip_if_not(file.exists(fixture), "fixture not present")
  f <- utils::read.delim(fixture, comment.char = "#")

  groups <- split(f, list(f$block, f$rho, f$k, f$n), drop = TRUE)
  groups <- groups[vapply(groups, nrow, integer(1)) > 1L]
  expect_gt(length(groups), 20L) # anti-vacuity: the split must actually group

  worst <- vapply(
    groups,
    function(d) min(stats::dist(d$mean_ratio)),
    numeric(1)
  )
  expect_gt(min(worst), 0.005)
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
