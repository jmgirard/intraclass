# M100 T2 -- does each abort's named `ci_method` actually work on the data that
# reaches that abort?
#
# An abort's remedy bullet ("use `ci_method = \"montecarlo\"`") is STATIC text: it
# makes the same claim to every user who reaches it. So it must hold across the
# whole class of data that triggers the abort, not on one dataset somebody tried.
# This script measures that class per site: it generates several geometries
# satisfying each site's trigger condition, confirms the abort really fires by
# catching its classed condition from the reducer called DIRECTLY (`icc()` cannot
# be the instrument -- M93's review found the glmmTMB point fit dying with a raw,
# unclassed error before the CI-stage guard is reached on some platforms), and
# then runs every method that site's remedy names on the same data.
#
# Usability is judged by the SHIPPED `boundary_interval_usable()` (R/boundary-hint.R),
# not by a predicate written here: the question is whether a user's own retry
# would give them something they can use, and that helper is already the repo's
# answer to it (finite, ordered, inside D-010 support).
#
# The sites are the `sweep`-dispositioned rows of data-raw/abort-remedy-sites.tsv,
# enumerated by data-raw/enumerate-ci-method-remedies.py. This script MEASURES
# only; the message rewrites it licenses are a separate task.
#
# Run from the repo root (~1 min):
#   Rscript data-raw/sweep-abort-remedies.R
# Writes data-raw/abort-remedy-sweep.tsv (one row per site x dataset x method).

suppressMessages(devtools::load_all(quiet = TRUE))

out_path <- "data-raw/abort-remedy-sweep.tsv"
boot_samples_n <- 99L
conf_level_n <- 0.95

# ---- data generators ---------------------------------------------------------
# Each returns balanced one-way long data. `jitter_sd = 0` gives the exact
# degeneracy; a tiny positive value gives the near-degenerate neighbourhood, which
# is where a guard that tests exact equality can be missed while the fit is still
# hopeless (the M99 degenerate-corner lesson).

# Zero WITHIN-subject variance: every rater gives a subject the same score.
# MSE = 0, so the classical F pivot and the npbootstrap IJ SE are undefined.
gen_mse0 <- function(n_s, n_r, jitter_sd = 0, seed = 1) {
  set.seed(seed)
  mu <- stats::rnorm(n_s, 0, 3)
  score <- rep(mu, each = n_r) + stats::rnorm(n_s * n_r, 0, jitter_sd)
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = score
  )
}

# Zero BETWEEN-subject variance: every subject has the same score profile, so all
# subject means are equal. SSA = 0 and log F = -Inf, while MSE stays positive.
gen_ssa0 <- function(n_s, n_r, jitter_sd = 0, seed = 1) {
  set.seed(seed)
  profile <- stats::rnorm(n_r, 0, 3)
  score <- rep(profile, times = n_s) + stats::rnorm(n_s * n_r, 0, jitter_sd)
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = score
  )
}

# Healthy between-subject variance, but so few subjects carry within-subject
# variance that a whole-subject RESAMPLE routinely draws a degenerate one. The
# observed-data guard passes; the resample guard fires. This is M97's "double
# code" shape -- most subjects rated identically, a few genuinely disagreed on.
gen_resample_degenerate <- function(n_s, n_r, n_varying = 2L, seed = 1) {
  set.seed(seed)
  mu <- stats::rnorm(n_s, 0, 3)
  score <- rep(mu, each = n_r)
  varying <- seq_len(min(n_varying, n_s))
  for (i in varying) {
    idx <- ((i - 1) * n_r + 1):(i * n_r)
    score[idx] <- score[idx] + stats::rnorm(n_r, 0, 1)
  }
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = score
  )
}

# The alternatives measured at every site. A remedy may only name a method the
# sweep found usable across the WHOLE trigger class, so the rewrite needs each
# candidate measured, not just the one the current text happens to name.
candidates <- c("montecarlo", "searle", "burch", "npbootstrap", "bootstrap")

# ---- the site register -------------------------------------------------------
# `fire` calls the reducer that owns the site DIRECTLY and returns the condition
# it raises (or NULL when it returns cleanly). `class` is the condition class the
# site is supposed to signal; a fire that returns a different class means the
# dataset reached some OTHER guard and the row is not evidence about this site.
ests_oneway <- function(k_eff) {
  list(
    icc_estimand(unit = "single", k_eff = k_eff, oneway = TRUE),
    icc_estimand(unit = "average", k_eff = k_eff, oneway = TRUE)
  )
}

catch <- function(expr) {
  withCallingHandlers(
    tryCatch(expr, error = function(e) e),
    warning = function(w) invokeRestart("muffleWarning")
  )
}

sites <- list(
  list(
    key = "R/ci-bootstrap.R:f3b08ac552",
    label = "bootstrap refit convergence",
    names = "montecarlo",
    class = "intraclass_singular_fit",
    fire = function(df, k) {
      # The point fit is inside the catch on purpose: on degenerate data glmmTMB
      # can die with a RAW, unclassed error before any CI-stage guard runs (M93's
      # review saw this on Linux and Windows; it is reachable on macOS too). That
      # is a site NOT reached, not a sweep failure.
      catch({
        fit <- fit_glmmtmb_oneway(df)
        bootstrap_ci(
          fit,
          ests_oneway(k),
          conf_level = conf_level_n,
          boot_samples = boot_samples_n,
          seed = 1L
        )
      })
    }
  ),
  list(
    key = "R/ci-classical.R:990cd66e44",
    label = "classical MSE = 0",
    names = "montecarlo",
    class = "intraclass_singular_fit",
    fire = function(df, k) {
      catch(searle_ci(df, ests_oneway(k), conf_level = conf_level_n))
    }
  ),
  list(
    key = "R/ci-npbootstrap.R:bf1a802a9c",
    label = "npbootstrap observed degeneracy",
    names = "montecarlo",
    class = "intraclass_singular_fit",
    fire = function(df, k) {
      catch(npbootstrap_ci(
        df,
        ests_oneway(k),
        conf_level = conf_level_n,
        boot_samples = boot_samples_n,
        seed = 1L
      ))
    }
  ),
  list(
    key = "R/ci-npbootstrap.R:01b75d1a61",
    label = "npbootstrap degenerate resamples",
    names = "montecarlo",
    class = "intraclass_singular_fit",
    fire = function(df, k) {
      catch(npbootstrap_ci(
        df,
        ests_oneway(k),
        conf_level = conf_level_n,
        boot_samples = boot_samples_n,
        seed = 1L
      ))
    }
  )
)

# ---- running a named remedy --------------------------------------------------
# The user's retry is an `icc()` call, so that is what is measured -- including
# the point fit, which on degenerate data can fail before any CI-stage guard.
# Three outcomes are distinguished, and only the first makes the remedy true.
run_remedy <- function(df, method, k) {
  res <- catch(icc(
    df,
    score,
    subject,
    rater,
    model = "oneway",
    ci_method = method,
    conf_level = conf_level_n,
    boot_samples = boot_samples_n,
    seed = 1L
  ))
  if (inherits(res, "condition")) {
    classed <- intersect(
      class(res),
      c(
        "intraclass_singular_fit",
        "intraclass_unsupported",
        "intraclass_unidentified",
        "intraclass_engine_error"
      )
    )
    return(list(
      outcome = if (length(classed)) "classed abort" else "raw error",
      detail = if (length(classed)) classed[[1]] else "unclassed",
      usable = FALSE
    ))
  }
  est <- res$estimates
  ok <- all(vapply(
    seq_len(nrow(est)),
    function(i) {
      divisor <- if (est$index[i] == "ICC(1)") 1 else 2
      boundary_interval_usable(
        list(conf.low = est$conf.low[i], conf.high = est$conf.high[i]),
        divisor = divisor,
        n0 = k
      )
    },
    logical(1)
  ))
  list(
    outcome = if (ok) "usable interval" else "unusable interval",
    detail = paste(
      sprintf("%.4g", c(est$conf.low, est$conf.high)),
      collapse = ","
    ),
    usable = ok
  )
}

# ---- the grid ----------------------------------------------------------------
# Several geometries per trigger, exact and near-degenerate, plus seed variation
# where the site is stochastic (the resample guard: a run is evidence about ONE
# seed, so a static bullet needs more than one).
grid <- list()
add <- function(site_key, gen, n_s, n_r, seed, note, ...) {
  grid[[length(grid) + 1]] <<- list(
    site = site_key,
    gen = gen,
    n_s = n_s,
    n_r = n_r,
    seed = seed,
    note = note,
    args = list(...)
  )
}

for (geom in list(c(6, 3), c(10, 2), c(15, 4), c(30, 3))) {
  for (jit in c(0, 1e-8)) {
    note <- if (jit == 0) "exact" else "near"
    for (key in c(
      "R/ci-bootstrap.R:f3b08ac552",
      "R/ci-classical.R:990cd66e44",
      "R/ci-npbootstrap.R:bf1a802a9c"
    )) {
      add(
        key,
        gen_mse0,
        geom[1],
        geom[2],
        1L,
        paste("MSE=0", note),
        jitter_sd = jit
      )
    }
    add(
      "R/ci-npbootstrap.R:bf1a802a9c",
      gen_ssa0,
      geom[1],
      geom[2],
      1L,
      paste("SSA=0", note),
      jitter_sd = jit
    )
  }
}
for (geom in list(c(12, 3), c(20, 3), c(30, 2))) {
  for (sd in 1:3) {
    add(
      "R/ci-npbootstrap.R:01b75d1a61",
      gen_resample_degenerate,
      geom[1],
      geom[2],
      sd,
      "few varying subjects",
      n_varying = 2L
    )
  }
}

# ---- run ---------------------------------------------------------------------
sites_by_key <- stats::setNames(sites, vapply(sites, `[[`, character(1), "key"))
rows <- list()
for (cell in grid) {
  site <- sites_by_key[[cell$site]]
  df <- do.call(
    cell$gen,
    c(
      list(n_s = cell$n_s, n_r = cell$n_r, seed = cell$seed),
      cell$args
    )
  )
  fired <- site$fire(df, cell$n_r)
  reached <- inherits(fired, "condition") && inherits(fired, site$class)
  why <- if (reached) {
    ""
  } else if (inherits(fired, "condition")) {
    paste("other condition:", class(fired)[[1]])
  } else {
    "reducer returned an interval"
  }
  for (method in union(strsplit(site$names, ",")[[1]], candidates)) {
    remedy <- if (reached) {
      run_remedy(df, trimws(method), cell$n_r)
    } else {
      list(outcome = "(site not reached)", detail = why, usable = NA)
    }
    rows[[length(rows) + 1]] <- data.frame(
      site = cell$site,
      label = site$label,
      named_by_remedy = trimws(method) %in% strsplit(site$names, ",")[[1]],
      n_s = cell$n_s,
      n_r = cell$n_r,
      seed = cell$seed,
      trigger = cell$note,
      reached = reached,
      remedy = trimws(method),
      outcome = remedy$outcome,
      remedy_usable = remedy$usable,
      detail = remedy$detail,
      generator = deparse(substitute(cell$gen)),
      boot_samples = boot_samples_n,
      conf_level = conf_level_n,
      r_version = as.character(getRversion()),
      glmmtmb_version = as.character(utils::packageVersion("glmmTMB")),
      platform = R.version$platform,
      stringsAsFactors = FALSE
    )
  }
  cat(sprintf(
    "%-34s %2dx%-2d seed %d %-16s reached=%-5s remedy=%s\n",
    site$label,
    cell$n_s,
    cell$n_r,
    cell$seed,
    cell$note,
    reached,
    rows[[length(rows)]]$outcome
  ))
}

res <- do.call(rbind, rows)
utils::write.table(res, out_path, sep = "\t", row.names = FALSE, quote = FALSE)

cat("\n---- per site: is each candidate method usable on EVERY dataset that\n")
cat(
  "     reached this abort? Only a method usable on all of them may be named\n"
)
cat("     in static remedy text. ----\n")
hit <- res[res$reached, ]
for (key in unique(hit$site)) {
  sub <- hit[hit$site == key, ]
  n_data <- nrow(sub) / length(unique(sub$remedy))
  cat(sprintf("\n%s (%d datasets reached)\n", sub$label[1], n_data))
  for (m in unique(sub$remedy)) {
    s_m <- sub[sub$remedy == m, ]
    n_ok <- sum(s_m$remedy_usable %in% TRUE)
    verdict <- if (n_ok == nrow(s_m)) {
      "NAMEABLE"
    } else if (n_ok == 0) {
      "never usable"
    } else {
      "partial -- not nameable"
    }
    cat(sprintf(
      "   %-12s %2d/%2d usable  %-24s %s%s\n",
      m,
      n_ok,
      nrow(s_m),
      verdict,
      paste(unique(s_m$outcome), collapse = "; "),
      if (s_m$named_by_remedy[1]) "   <- named by the shipped remedy" else ""
    ))
  }
}
unreached <- res[!res$reached, ]
if (nrow(unreached)) {
  cat(sprintf(
    "\n%d grid cells did not reach their site (not evidence either way):\n",
    nrow(unreached) / length(unique(res$remedy))
  ))
  print(
    unique(unreached[, c("label", "n_s", "n_r", "trigger", "detail")]),
    row.names = FALSE
  )
}
cat(sprintf("\nwrote %s (%d rows)\n", out_path, nrow(res)))
cat(sprintf(
  "R %s, glmmTMB %s, platform %s\n",
  getRversion(),
  utils::packageVersion("glmmTMB"),
  R.version$platform
))
