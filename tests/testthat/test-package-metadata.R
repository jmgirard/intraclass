# The maintainer address the package ships ------------------------------------
#
# `Authors@R`'s `cre` entry is where CRAN, and any user running `maintainer()`
# or reading `?intraclass-package`, is told to send correspondence. It was set
# from the scaffold default at the package's first commit and carried an
# address that is not the maintainer's, so this pins the correct one and
# refuses the scaffold default's return. Both read the DESCRIPTION via the
# `read.dcf` idiom `test-autoplot.R` uses for the dependency fields. `R CMD
# check` resolves it to the INSTALLED file, which carries the generated
# `Maintainer:` field; `devtools::test()` resolves it to the source file, which
# does not -- hence the same presence guard `test-autoplot.R` puts on `Imports`.

test_that("the shipped maintainer address is the maintainer's", {
  desc <- read.dcf(system.file("DESCRIPTION", package = "intraclass"))
  expect_match(desc[, "Authors@R"], "me@jmgirard.com", fixed = TRUE)
  if ("Maintainer" %in% colnames(desc)) {
    expect_match(desc[, "Maintainer"], "me@jmgirard.com", fixed = TRUE)
  }
})

test_that("the scaffold-default address is absent from every DESCRIPTION field", {
  desc <- read.dcf(system.file("DESCRIPTION", package = "intraclass"))
  expect_false(any(grepl("jeffgirard@gmail.com", desc, fixed = TRUE)))
})
