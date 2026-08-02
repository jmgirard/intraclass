# M100 -- does each abort's named `ci_method` actually work on the data that
# reaches that abort?
#
# This script MEASURES and concludes nothing about what a message should say. It
# changes no message and licenses no edit: the rule for reading these results,
# and every message change they bear on, are the next milestone's work.
#
# An abort's remedy bullet ("use `ci_method = \"montecarlo\"`") is STATIC text: it
# makes the same claim to every user who reaches it, so one dataset somebody tried
# is not evidence about it. This script samples each site's trigger condition over
# several geometries, confirms the abort really fires by catching its classed
# condition from the reducer called DIRECTLY (`icc()` cannot be the instrument --
# M93's review found the glmmTMB point fit dying with a raw, unclassed error
# before the CI-stage guard is reached on some platforms), and then runs every
# candidate method on the same data.
#
# WHAT THE GRID GENERATES, AND WHAT IT DOES NOT. A sample is not a class, and the
# claim that it was one is a defect this milestone's own review found (pass 4,
# O6). So, per swept site, the disjuncts of the trigger condition this grid does
# and does not reach:
#
#   bootstrap refit convergence -- `n_ok < min_frac * boot_samples || n_ok < 2`.
#     GENERATED: refit failure driven by exact and near zero within-subject
#     variance (`gen_mse0`, 4 geometries x jitter 0 / 1e-8). NOT GENERATED: every
#     other route to a low converged-refit count -- the guard counts refits, and
#     no data fact entails that count, so refits failing on data that is not
#     MSE=0-degenerate are outside this grid entirely.
#
#   classical MSE = 0 -- `ss$mse == 0 || !is.finite(f)`, `f = msa / mse`.
#     GENERATED: the FIRST disjunct only (`gen_mse0`). NOT GENERATED: the second
#     disjunct reached with MSE finite and non-zero -- MSA overflowing to `Inf`,
#     which makes `f` non-finite on data whose within-subject variance is healthy.
#     Nothing below measures that corner.
#
#   npbootstrap observed degeneracy -- `!is.finite(obs$logf) || se_ij_logf == 0`.
#     GENERATED: both disjuncts -- `log F = -Inf` from zero between-subject
#     variance (`gen_ssa0`) and `log F = +Inf` from zero within-subject variance
#     (`gen_mse0`), both measured on a 6x3 exact cell, plus a zero jackknife SE
#     with a FINITE log F (`gen_se_zero`). NOT GENERATED: `log F` non-finite by
#     overflow or by `NaN` rather than by an exactly zero sum of squares.
#
#   npbootstrap degenerate resamples -- `n_bad > 0` over the resample statistics.
#     GENERATED: the few-varying-subjects shape (`gen_resample_degenerate`, 3
#     geometries x 3 seeds). NOT GENERATED: any other data shape whose resamples
#     go degenerate -- heavy tie structure, and the unbalanced and double-code
#     designs M97 measured, none of which this balanced grid contains.
#
# Across all four: the grid is BALANCED one-way data only. No unbalanced design,
# no two-way design, and no missing values appear anywhere in it, so no verdict
# below is evidence about those.
#
# Usability is judged by the SHIPPED `boundary_interval_usable()` (R/boundary-hint.R),
# not by a predicate written here: the question is whether a user's own retry
# would give them something they can use, and that helper is already the repo's
# answer to it (finite, ordered, inside D-010 support).
#
# The sites are the reducer-stage guards whose trigger is degenerate DATA. That
# set is fixed by the code, not by the ledger: a guard stays worth measuring after
# its message stops naming a method, so reading the site list off
# `data-raw/abort-remedy-sites.tsv` would shrink the evidence base the moment a
# bullet was de-named -- which is exactly when the evidence matters (review C7).
# What IS read from the enumeration is which sites name a method today -- the
# `named_by_remedy` column below -- so that column cannot go stale against the
# shipped text.
#
# Run from the repo root (~25 min at boot_samples = 999):
#   Rscript data-raw/sweep-abort-remedies.R
# Writes data-raw/abort-remedy-sweep.tsv (one row per site x dataset x method).

suppressMessages(devtools::load_all(quiet = TRUE))

# Site identity is read off the rendered message (see `lead_fragments()`), so the
# renderer must not hard-wrap it at the console width. Belt and braces: the match
# also normalizes whitespace, because a pin that depends on how wide the terminal
# happened to be is not evidence about anything.
options(cli.width = 10000L)

out_path <- "data-raw/abort-remedy-sweep.tsv"
# The SHIPPED default, not a reduced count. M97 measured a run that succeeded at
# 999 and aborted at a caller's 2000, and `R/boundary-hint.R` records the rule it
# settled: verification runs at the count the user's own retry would use. A sweep
# at 99 measures a different experiment from the one the message speaks to
# (review finding C3).
boot_samples_n <- 999L
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

# NEITHER variance degenerate, yet the npbootstrap observed-data guard fires:
# every subject's share of SSA equals its share of SSE, so all influence values
# are zero and `se_ij_logf == 0` while `log F` stays finite. M100's first sweep
# never generated this branch, which is how a message false on it reached review
# (finding A1). Subject means -1/0/1, within-subject ranges 1/0/1.
gen_se_zero <- function(n_s, n_r, seed = 1) {
  data.frame(
    subject = rep(1:3, each = 2),
    rater = rep(1:2, times = 3),
    score = c(-1.5, -0.5, 0, 0, 0.5, 1.5)
  )
}

# The alternatives measured at every site. Every candidate is measured, not just
# the one a site's current text happens to name, so that a later milestone
# weighing what a message may say has a verdict for each of them rather than for
# one. This script states no rule about what a remedy may name; that judgment is
# M101's.
# Five of the seven `ci_method` values. `mpl` is excluded because it is fenced to
# the balanced two-way random agreement cell and aborts `intraclass_unsupported`
# on every one-way dataset here; `posterior` because it requires the brms engine,
# which these fits do not use. Recorded rather than assumed (review F5/F10).
candidates <- c("montecarlo", "searle", "burch", "npbootstrap", "bootstrap")

# ---- confirming WHICH guard fired --------------------------------------------
# The condition class alone cannot identify a site. Both npbootstrap guards raise
# `intraclass_singular_fit` from the same reducer, so a cell aimed at the
# observed-degeneracy guard that actually tripped the resample guard would have
# been recorded as evidence about the first. Every verdict below therefore also
# requires the fired message to carry that site's own leading line.
#
# The fragments are DERIVED from the committed enumeration rather than written
# here, so the identity test cannot drift from the shipped text: the leading line
# is the same string the ledger key hashes. Glue spans (`{.val {n_ok}}`) are cut
# out and the static text between them is what must appear -- ALL of it, not the
# longest piece, because " interval is undefined for this data." alone is shared
# by the classical and npbootstrap-observed guards and only "The classical
# one-way" separates them.
enumeration_leads <- local({
  path <- "data-raw/abort-remedy-enumeration.txt"
  out <- list()
  if (file.exists(path)) {
    key <- NULL
    for (ln in readLines(path, warn = FALSE)) {
      k <- regmatches(ln, regexpr("(?<=key:\\s{7})\\S+", ln, perl = TRUE))
      if (length(k)) {
        key <- k
      }
      l <- regmatches(ln, regexpr("(?<=leading:\\s{3})\\S.*", ln, perl = TRUE))
      if (length(l) && !is.null(key)) {
        out[[key]] <- l
      }
    }
  }
  out
})

# Static text of a leading line: everything outside a `{...}` glue span, brace
# depth tracked because cli nests them (`{.val {n_ok}}`). Fragments shorter than
# 8 non-space characters are dropped -- " of " identifies nothing and would only
# make the test fragile.
lead_fragments <- function(lead) {
  chars <- strsplit(lead, "", fixed = TRUE)[[1]]
  depth <- 0L
  keep <- character(0)
  buf <- character(0)
  for (ch in chars) {
    if (ch == "{") {
      depth <- depth + 1L
      keep <- c(keep, paste(buf, collapse = ""))
      buf <- character(0)
    } else if (ch == "}") {
      depth <- max(0L, depth - 1L)
    } else if (depth == 0L) {
      buf <- c(buf, ch)
    }
  }
  keep <- c(keep, paste(buf, collapse = ""))
  keep <- trimws(keep)
  keep[nchar(gsub("\\s", "", keep)) >= 8L]
}

squash <- function(x) gsub("\\s+", " ", trimws(x))

# Does this condition carry the leading line of the site we aimed at?
is_site <- function(cnd, key) {
  lead <- enumeration_leads[[key]]
  if (is.null(lead)) {
    return(NA)
  }
  frags <- lead_fragments(lead)
  if (!length(frags)) {
    return(NA)
  }
  msg <- squash(conditionMessage(cnd))
  all(vapply(
    frags,
    function(f) grepl(squash(f), msg, fixed = TRUE),
    logical(1)
  ))
}

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
    class = "intraclass_singular_fit",
    fire = function(df, k) {
      catch(searle_ci(df, ests_oneway(k), conf_level = conf_level_n))
    }
  ),
  list(
    key = "R/ci-npbootstrap.R:bf1a802a9c",
    label = "npbootstrap observed degeneracy",
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
#
# Cells are built by a function that RETURNS one and accumulated with `c()`, not
# by a helper writing to an enclosing `grid` with `<<-`: CI runs a newer lintr
# whose `assignment_linter` rejects `<<-`, and a local `lint_package()` stays
# silent about it (the M95 lesson).
grid <- list()
cell_spec <- function(site_key, gen_name, n_s, n_r, seed, note, ...) {
  list(
    site = site_key,
    gen_name = gen_name,
    gen = get(gen_name),
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
      grid <- c(
        grid,
        list(cell_spec(
          key,
          "gen_mse0",
          geom[1],
          geom[2],
          1L,
          paste("MSE=0", note),
          jitter_sd = jit
        ))
      )
    }
    grid <- c(
      grid,
      list(cell_spec(
        "R/ci-npbootstrap.R:bf1a802a9c",
        "gen_ssa0",
        geom[1],
        geom[2],
        1L,
        paste("SSA=0", note),
        jitter_sd = jit
      ))
    )
  }
}
grid <- c(
  grid,
  list(cell_spec(
    "R/ci-npbootstrap.R:bf1a802a9c",
    "gen_se_zero",
    3L,
    2L,
    1L,
    "SE=0, both variances healthy"
  ))
)
for (geom in list(c(12, 3), c(20, 3), c(30, 2))) {
  for (sd in 1:3) {
    grid <- c(
      grid,
      list(cell_spec(
        "R/ci-npbootstrap.R:01b75d1a61",
        "gen_resample_degenerate",
        geom[1],
        geom[2],
        sd,
        "few varying subjects",
        n_varying = 2L
      ))
    )
  }
}

# ---- run ---------------------------------------------------------------------
# Which sites still name a method TODAY, read from the committed enumeration so
# the column cannot drift from the shipped text (review C7). A site absent from
# the enumeration names nothing -- which is exactly what M100 did to three of
# these four.
named_now <- local({
  path <- "data-raw/abort-remedy-enumeration.txt"
  out <- list()
  if (file.exists(path)) {
    txt <- readLines(path, warn = FALSE)
    key <- NULL
    for (ln in txt) {
      k <- regmatches(ln, regexpr("(?<=key:\\s{7})\\S+", ln, perl = TRUE))
      if (length(k)) {
        key <- k
      }
      n <- regmatches(ln, regexpr("(?<=names:\\s{5})\\S.*", ln, perl = TRUE))
      if (length(n) && !is.null(key)) {
        out[[key]] <- trimws(strsplit(n, ",")[[1]])
      }
    }
  }
  out
})

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
  # `fire` calls the reducer directly, bypassing the point fit -- necessary,
  # because on some geometries glmmTMB dies with a raw error before any CI-stage
  # guard runs. But a user only ever meets this message through `icc()`, so a
  # cell whose POINT FIT dies is not a dataset on which the message is shown:
  # counting it inflated two verdict denominators (review finding C2). Recorded
  # separately so the distinction is in the evidence rather than in a footnote.
  point_fit_ok <- !inherits(
    catch(fit_glmmtmb_oneway(df)),
    "condition"
  )
  fired <- site$fire(df, cell$n_r)
  classed_ok <- inherits(fired, "condition") && inherits(fired, site$class)
  # The site's OWN message, not merely its class -- see `is_site()`.
  site_ok <- isTRUE(classed_ok && isTRUE(is_site(fired, cell$site)))
  reached <- site_ok && point_fit_ok
  why <- if (reached) {
    ""
  } else if (!point_fit_ok) {
    "point fit failed: a user could not reach this message on this data"
  } else if (classed_ok && !site_ok) {
    paste0(
      "another guard in the same reducer raised ",
      site$class,
      ": the message is not this site's"
    )
  } else if (inherits(fired, "condition")) {
    paste("other condition:", class(fired)[[1]])
  } else {
    "reducer returned an interval"
  }
  for (method in candidates) {
    remedy <- if (reached) {
      run_remedy(df, trimws(method), cell$n_r)
    } else {
      list(outcome = "(site not reached)", detail = why, usable = NA)
    }
    rows[[length(rows) + 1]] <- data.frame(
      site = cell$site,
      label = site$label,
      named_by_remedy = trimws(method) %in%
        (if (is.null(named_now[[cell$site]])) {
          character(0)
        } else {
          named_now[[cell$site]]
        }),
      n_s = cell$n_s,
      n_r = cell$n_r,
      seed = cell$seed,
      trigger = cell$note,
      reached = reached,
      point_fit_ok = point_fit_ok,
      site_confirmed = site_ok,
      remedy = trimws(method),
      outcome = remedy$outcome,
      remedy_usable = remedy$usable,
      detail = remedy$detail,
      generator = cell$gen_name,
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
