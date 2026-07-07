# Re-export the tidy/glance generics so users can call them with only
# `intraclass` attached (broom-style), without also attaching `generics`.

#' @importFrom generics tidy
#' @export
generics::tidy

#' @importFrom generics glance
#' @export
generics::glance
