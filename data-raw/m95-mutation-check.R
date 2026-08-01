# data-raw/m95-mutation-check.R
#
# M95 T3: mutation-verify the whole-table kappa_m pin (M95 AC4/AC5) and write
# the committed record data-raw/m95-mutation-record.md.
#
# The pin under test is "the shipped kappa_m table matches its whole-table
# fixture, every cell (M95 AC2)" in tests/testthat/test-ci-mpl.R: a symmetric
# identical()/key-set comparison between the shipped kappa_m_table
# (R/sysdata.rda) and the committed fixture (tests/testthat/fixtures/
# kappa-m-table.txt). Because the comparison is symmetric, a discrepancy
# introduced on either side is the same detected event; cases 1-5 mutate the
# FIXTURE side (cheap: a text edit), and case 6 mutates the SHIPPED side
# (R/sysdata.rda rewritten, package reloaded) to show directly that a changed
# shipped table -- the scenario the pin exists for -- reds the test with the
# fixture intact. Every mutated file is restored from an in-memory copy and
# the run ends by re-asserting the pin is green on the restored state.
#
# Run (minutes -- executes tests/testthat/test-ci-mpl.R once per case + twice
# for baselines):
#   Rscript data-raw/m95-mutation-check.R

pin_desc <- "the shipped kappa_m table matches its whole-table fixture, every cell (M95 AC2)"
fixture_path <- "tests/testthat/fixtures/kappa-m-table.txt"
sysdata_path <- "R/sysdata.rda"
test_path <- "tests/testthat/test-ci-mpl.R"
record_path <- "data-raw/m95-mutation-record.md"

suppressMessages(devtools::load_all(quiet = TRUE))

fixture_lines <- readLines(fixture_path)
sysdata_bytes <- readBin(sysdata_path, "raw", file.size(sysdata_path))

restore_all <- function() {
  writeLines(fixture_lines, fixture_path)
  writeBin(sysdata_bytes, sysdata_path)
}
# on.exit() is a no-op at script top level (it binds to a function frame), so
# the abort path is covered by options(error = ...): an aborted run -- e.g.
# add_case()'s stopifnot firing because a mutation FAILED to red the pin, the
# most important abort of all -- must not leave a perturbed R/sysdata.rda or
# fixture on disk to be committed by accident (M95 review finding 1; the
# handler mechanism is verified to fire under Rscript in that finding's fix).
options(error = function() {
  restore_all()
  cat("aborted: fixture and R/sysdata.rda restored from in-memory copies\n")
  quit(save = "no", status = 1L)
})

# Run the test file and return the pin test's results: n failed expectations,
# first failure message, and any OTHER test in the file that failed (the
# mutation must red the pin, and only the pin).
run_pin <- function() {
  reporter <- testthat::ListReporter$new()
  suppressMessages(suppressWarnings(
    testthat::test_file(test_path, reporter = reporter)
  ))
  res <- reporter$get_results()
  pin <- Filter(function(r) identical(r$test, pin_desc), res)
  stopifnot(length(pin) == 1L)
  fails <- Filter(
    function(e) inherits(e, "expectation_failure"),
    pin[[1]]$results
  )
  others <- Filter(
    function(r) {
      !identical(r$test, pin_desc) &&
        any(vapply(
          r$results,
          function(e) {
            inherits(e, c("expectation_failure", "expectation_error"))
          },
          logical(1)
        ))
    },
    res
  )
  list(
    n_fail = length(fails),
    first_msg = if (length(fails)) {
      conditionMessage(fails[[1]])
    } else {
      NA_character_
    },
    other_failed = vapply(others, function(r) r$test, character(1))
  )
}

# Field 4 of a data row is the hex-float kappa_m the pin reads; field 5 the
# decimal mirror. Mutate both so the file stays self-consistent.
mutate_cell <- function(lines, n_r, n_s, conf_level, delta) {
  hit <- 0L
  for (i in seq_along(lines)) {
    if (startsWith(lines[i], "#") || startsWith(lines[i], "n_r")) {
      next
    }
    f <- strsplit(lines[i], "\t", fixed = TRUE)[[1]]
    if (
      as.integer(f[1]) == n_r &&
        as.integer(f[2]) == n_s &&
        abs(as.numeric(f[3]) - conf_level) < 1e-8
    ) {
      v <- as.numeric(f[4]) + delta
      lines[i] <- sprintf("%s\t%s\t%s\t%a\t%.17g", f[1], f[2], f[3], v, v)
      hit <- hit + 1L
    }
  }
  stopifnot(hit == 1L)
  lines
}

cases <- list()
add_case <- function(label, side, cell, perturbation, out) {
  stopifnot(out$n_fail >= 1L, length(out$other_failed) == 0L)
  cases[[length(cases) + 1L]] <<- list(
    label = label,
    side = side,
    cell = cell,
    perturbation = perturbation,
    n_fail = out$n_fail,
    first_msg = out$first_msg
  )
  cat(sprintf(
    "  %-28s -> pin red (%d failed expectation%s)\n",
    label,
    out$n_fail,
    if (out$n_fail > 1L) "s" else ""
  ))
}

cat("baseline (untouched): ")
base <- run_pin()
stopifnot(base$n_fail == 0L, length(base$other_failed) == 0L)
cat("pin green, file green\n")

data_start <- which(startsWith(fixture_lines, "n_r")) + 1L

# Case 1-3 (AC4): one perturbed cell per level slice, +0.5 (M92 P6-1's delta).
for (case in list(
  list(n_r = 2L, n_s = 10L, cl = 0.90, label = "perturb (2,10,0.90)"),
  list(n_r = 10L, n_s = 100L, cl = 0.99, label = "perturb (10,100,0.99)")
)) {
  writeLines(
    mutate_cell(fixture_lines, case$n_r, case$n_s, case$cl, 0.5),
    fixture_path
  )
  add_case(
    case$label,
    "fixture",
    sprintf("(%d, %d, %.2f)", case$n_r, case$n_s, case$cl),
    "kappa_m + 0.5",
    run_pin()
  )
}

# Case 3 (AC4 third slice + AC5): the 0.95 perturbation is placed on a cell NO
# existing literal pin covers -- (6, 15, 0.95). The pre-M95 literals pin the
# 0.95 nodes (2,10), (2,100), (4,20), (10,50) and the interpolation/endpoint
# tests touch (2,30), (2,50), (3,20), (3,30), (4,20), (4,30), (10,30), (10,50);
# (6, 15) is in the +0.5-on-unpinned-cells set M92's pass-6 mutation showed
# leaves the pre-M95 file at FAIL 0 (finding P6-1).
writeLines(mutate_cell(fixture_lines, 6L, 15L, 0.95, 0.5), fixture_path)
add_case(
  "perturb (6,15,0.95) [AC5]",
  "fixture",
  "(6, 15, 0.95) -- covered by NO pre-M95 literal pin",
  "kappa_m + 0.5",
  run_pin()
)

# Case 4 (AC4): an added row -- a node the shipped table does not have.
added <- sprintf("%d\t%d\t%.2f\t%a\t%.17g", 2L, 12L, 0.95, 1.0, 1.0)
writeLines(
  append(fixture_lines, added, after = data_start - 1L),
  fixture_path
)
add_case(
  "add row (2,12,0.95)",
  "fixture",
  "(2, 12, 0.95) -- not a shipped node",
  "row added, kappa_m = 1.0",
  run_pin()
)

# Case 5 (AC4): a dropped row.
is_dropped <- vapply(
  fixture_lines,
  function(l) {
    !startsWith(l, "#") &&
      !startsWith(l, "n_r") &&
      identical(strsplit(l, "\t", fixed = TRUE)[[1]][1:3], c("3", "20", "0.90"))
  },
  logical(1),
  USE.NAMES = FALSE
)
stopifnot(sum(is_dropped) == 1L)
writeLines(fixture_lines[!is_dropped], fixture_path)
add_case(
  "drop row (3,20,0.90)",
  "fixture",
  "(3, 20, 0.90)",
  "row removed",
  run_pin()
)

# Case 6 (AC4, shipped side): the scenario the pin exists for -- a cell of the
# SHIPPED table changes while the fixture still records the calibrated value.
writeLines(fixture_lines, fixture_path)
# The mutated table stays inside a scratch environment: a global object named
# kappa_m_table would shadow the package's own table inside testthat's test
# env and fake both this case's red and the restored baseline's green.
shipped_env <- new.env()
load(sysdata_path, envir = shipped_env)
row <- which(
  shipped_env$kappa_m_table$n_r == 6L &
    shipped_env$kappa_m_table$n_s == 15L &
    abs(shipped_env$kappa_m_table$conf_level - 0.95) < 1e-8
)
stopifnot(length(row) == 1L)
shipped_env$kappa_m_table$kappa_m[row] <-
  shipped_env$kappa_m_table$kappa_m[row] + 0.5
save(
  list = "kappa_m_table",
  envir = shipped_env,
  file = sysdata_path,
  compress = "bzip2",
  version = 2
)
suppressMessages(devtools::load_all(quiet = TRUE))
add_case(
  "perturb shipped (6,15,0.95)",
  "shipped (R/sysdata.rda)",
  "(6, 15, 0.95) in the shipped table itself",
  "kappa_m + 0.5, fixture intact",
  run_pin()
)

# Restore everything and prove the pin is green again.
restore_all()
suppressMessages(devtools::load_all(quiet = TRUE))
cat("restored: ")
final <- run_pin()
stopifnot(final$n_fail == 0L, length(final$other_failed) == 0L)
cat("pin green, file green\n")

# --- Write the committed record ------------------------------------------------
fence <- "```"
rec <- c(
  "# M95 mutation record — whole-table kappa_m pin (AC4/AC5)",
  "",
  sprintf("Generated by `data-raw/m95-mutation-check.R` on %s.", Sys.Date()),
  "",
  "Target: the M95 AC2 pin in `tests/testthat/test-ci-mpl.R`",
  sprintf("(%s\"%s\"%s).", "`", pin_desc, "`"),
  "The pin is a symmetric `identical()`/key-set comparison between the shipped",
  "`kappa_m_table` and `tests/testthat/fixtures/kappa-m-table.txt`, so a",
  "discrepancy introduced on either side is the same detected event; cases 1–5",
  "mutate the fixture side, case 6 rewrites `R/sysdata.rda` itself (the",
  "scenario the pin exists for) and reloads the package. Baseline before and",
  "restored state after both ran green, and in every mutated run the pin was",
  "the ONLY test in the file that failed (asserted by the script).",
  "",
  "| # | Side | Cell | Perturbation | Pin result |",
  "|---|---|---|---|---|"
)
for (i in seq_along(cases)) {
  cs <- cases[[i]]
  rec <- c(
    rec,
    sprintf(
      "| %d | %s | %s | %s | RED — %d failed expectation%s |",
      i,
      cs$side,
      cs$cell,
      cs$perturbation,
      cs$n_fail,
      if (cs$n_fail > 1L) "s" else ""
    )
  )
}
rec <- c(
  rec,
  "",
  "Per case, the first failed expectation as reported by testthat:",
  ""
)
for (i in seq_along(cases)) {
  cs <- cases[[i]]
  msg <- strsplit(cs$first_msg, "\n", fixed = TRUE)[[1]]
  rec <- c(
    rec,
    sprintf("**Case %d — %s.**", i, cs$label),
    "",
    fence,
    msg[seq_len(min(length(msg), 8L))],
    fence,
    ""
  )
}
rec <- c(
  rec,
  "Case 3 is the AC5 case: its cell (6, 15, 0.95) is covered by no pre-M95",
  "literal pin — it sits in the +0.5-on-unpinned-cells set that M92's pass-6",
  "mutation (finding P6-1) showed leaves the pre-M95 `test-ci-mpl.R` at",
  "FAIL 0 / PASS 172 — and the whole-table pin reds on it."
)
writeLines(rec, record_path)
cat(sprintf("wrote %s (%d cases, all red)\n", record_path, length(cases)))
