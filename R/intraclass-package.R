#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom lifecycle deprecated
## usethis namespace: end
NULL

# Declared Imports whose first use lands in Milestone 1 (the two-way random
# absolute-agreement estimator): the glmmTMB fitting engine, the parameter
# covariance for Monte-Carlo CIs, and the generics we provide tidy methods for.
# Importing them here keeps the dependency graph honest at M0 (no "unused
# Imports" note) and documents intent.
#' @importFrom glmmTMB glmmTMB
#' @importFrom stats vcov
#' @importFrom generics tidy
NULL
