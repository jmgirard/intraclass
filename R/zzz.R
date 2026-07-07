# Package hooks + delayed S3 registration --------------------------------------
#
# `autoplot()` is the generic that draws the D-study reliability curve, but its
# home is ggplot2 -- a Suggests dependency (light-install path; see ADR-002 and
# the install notes). We therefore register `autoplot.icc_dstudy()` LAZILY: only
# once ggplot2 is loaded, via `s3_register()`, so `intraclass` still installs and
# attaches without ggplot2 present. `s3_register()` is the canonical, dependency-
# free helper vendored from vctrs (https://vctrs.r-lib.org/reference/s3_register.html);
# copied here rather than adding vctrs to Imports.

.onLoad <- function(libname, pkgname) {
  s3_register("ggplot2::autoplot", "icc_dstudy")
  s3_register("ggplot2::autoplot", "icc")
  invisible()
}

# Register a method for a generic that lives in a Suggested package, taking
# effect when (and only when) that package is loaded. Verbatim vctrs copy.
s3_register <- function(generic, class, method = NULL) {
  stopifnot(is.character(generic), length(generic) == 1L)
  stopifnot(is.character(class), length(class) == 1L)

  pieces <- strsplit(generic, "::")[[1L]]
  stopifnot(length(pieces) == 2L)
  package <- pieces[[1L]]
  generic <- pieces[[2L]]

  caller <- parent.frame()

  get_method_env <- function() {
    top <- topenv(caller)
    if (isNamespace(top)) {
      asNamespace(environmentName(top))
    } else {
      caller
    }
  }
  get_method <- function(method) {
    if (is.null(method)) {
      get(paste0(generic, ".", class), envir = get_method_env())
    } else {
      method
    }
  }

  register <- function(...) {
    envir <- asNamespace(package)

    # Refresh the method each time, in case the generic has been reassigned by,
    # for example, `devtools::load_all()`.
    method_fn <- get_method(method)
    stopifnot(is.function(method_fn))

    # S3 registration:
    if (exists(generic, envir)) {
      registerS3method(generic, class, method_fn, envir = envir)
    }
  }

  # Always register hook in case package is later unloaded & reloaded.
  setHook(packageEvent(package, "onLoad"), function(...) register())

  # Avoid registration failures during loading (pkgload or regular).
  if (isNamespaceLoaded(package)) {
    register()
  }

  invisible()
}
