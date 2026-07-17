# brms oracle script <-> fixture map guard (M52 / GP7) -------------------------
#
# The brms engine is verified OFFLINE: seeded data-raw/oracle-bayesian-*.R
# scripts generate the committed tests/testthat/fixtures/bayesian-*-oracle.rds
# references the suite pins (strategy: data-raw/README.md). The name mapping is
# IRREGULAR (three `*multilevel*` scripts map to `*ml*` fixtures while
# `multilevel-fixed` / `multilevel-replicates` stay unabbreviated), so nothing
# mechanical ties script to fixture — a new fixture could land with no
# provenance script, or a script's fixture could be renamed away, silently.
# This guard holds the authoritative map and fails when the map, the scripts on
# disk, and the committed fixtures disagree in either direction; it also pins
# the README's table to the same map so the document cannot rot (M52, GP7).
#
# Skips when data-raw/ is absent: the built package (.Rbuildignore ^data-raw$)
# has fixtures but no scripts to reconcile.

brms_oracle_map <- c(
  "oracle-bayesian.R" = "bayesian-oracle.rds",
  "oracle-bayesian-cluster-ck.R" = "bayesian-cluster-ck-oracle.rds",
  "oracle-bayesian-conflated.R" = "bayesian-conflated-oracle.rds",
  "oracle-bayesian-fixed.R" = "bayesian-fixed-oracle.rds",
  "oracle-bayesian-fixed-replicates.R" = "bayesian-fixed-replicates-oracle.rds",
  "oracle-bayesian-incomplete.R" = "bayesian-incomplete-oracle.rds",
  "oracle-bayesian-incomplete-fixed.R" = "bayesian-incomplete-fixed-oracle.rds",
  "oracle-bayesian-incomplete-fixed-multilevel.R" = "bayesian-incomplete-fixed-ml-oracle.rds",
  "oracle-bayesian-incomplete-fixed-nested.R" = "bayesian-incomplete-fixed-nested-oracle.rds",
  "oracle-bayesian-incomplete-multilevel.R" = "bayesian-incomplete-ml-oracle.rds",
  "oracle-bayesian-incomplete-nested.R" = "bayesian-incomplete-nested-oracle.rds",
  "oracle-bayesian-incomplete-nested-subjects.R" = "bayesian-incomplete-nested-subjects-oracle.rds",
  "oracle-bayesian-incomplete-oneway.R" = "bayesian-incomplete-oneway-oracle.rds",
  "oracle-bayesian-multilevel.R" = "bayesian-ml-oracle.rds",
  "oracle-bayesian-multilevel-fixed.R" = "bayesian-multilevel-fixed-oracle.rds",
  "oracle-bayesian-multilevel-replicates.R" = "bayesian-multilevel-replicates-oracle.rds",
  "oracle-bayesian-nested.R" = "bayesian-nested-oracle.rds",
  "oracle-bayesian-nested-fixed.R" = "bayesian-nested-fixed-oracle.rds",
  "oracle-bayesian-oneway.R" = "bayesian-oneway-oracle.rds",
  "oracle-bayesian-replicates.R" = "bayesian-replicates-oracle.rds"
)

data_raw_dir <- testthat::test_path("..", "..", "data-raw")

test_that("every brms oracle script maps to a committed fixture and vice versa", {
  skip_if_not(dir.exists(data_raw_dir), "data-raw/ not present (built package)")

  scripts <- list.files(data_raw_dir, pattern = "^oracle-bayesian.*\\.R$")
  fixtures <- list.files(
    testthat::test_path("fixtures"),
    pattern = "^bayesian-(.*-)?oracle\\.rds$"
  )

  # Bijective map: no fixture is claimed by two scripts.
  expect_identical(anyDuplicated(brms_oracle_map), 0L)
  # Direction 1: the scripts on disk are exactly the map's keys — an unmapped
  # new script or a stale map row fails here.
  expect_setequal(scripts, names(brms_oracle_map))
  # Direction 2: the committed fixtures are exactly the map's values — a
  # fixture with no provenance script (or a renamed-away fixture) fails here.
  expect_setequal(fixtures, unname(brms_oracle_map))
})

test_that("data-raw/README.md's map table matches the authoritative map", {
  skip_if_not(dir.exists(data_raw_dir), "data-raw/ not present (built package)")

  # The README is the document this guard locks: its absence in a source tree
  # (where data-raw/ exists) is itself a failure, never a skip -- a skip here
  # would let the strategy doc be deleted while the suite stays green.
  readme <- file.path(data_raw_dir, "README.md")
  expect_true(file.exists(readme))

  lines <- readLines(readme, encoding = "UTF-8")
  rows <- grep("^\\| oracle-bayesian", lines, value = TRUE)
  cells <- strsplit(rows, "\\|")
  doc_map <- vapply(cells, function(x) trimws(x[[3]]), character(1))
  names(doc_map) <- vapply(cells, function(x) trimws(x[[2]]), character(1))

  expect_mapequal(as.list(doc_map), as.list(brms_oracle_map))
})
