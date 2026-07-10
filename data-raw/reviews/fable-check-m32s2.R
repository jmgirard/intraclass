# fable-check-m32s2.R — Fable review verification harness (M32 Slice 2, #19).
# Independently re-runs the O-Bayes-INML-subjects ragged nested Design-3 coverage
# question at higher n_rep, across multiple incidences, with mechanism diagnostics
# (PIT, posterior sd) and a PAIRED glmmTMB read on identical data, plus a
# high-precision frequentist-only arm. Results committed as
# fable-check-m32s2-results.rds; findings in fable-review-m32-s2-response.md.
#
# Usage (from the package root; each arm is hours/minutes as noted):
#   Rscript data-raw/reviews/fable-check-m32s2.R freq      # ~25 min, no Stan
#   Rscript data-raw/reviews/fable-check-m32s2.R bayes1    # ~2.5 h, live Stan
#   Rscript data-raw/reviews/fable-check-m32s2.R bayes2    # ~2.5 h, live Stan
# RNG hygiene: every dataset is drawn under its own set.seed() immediately before
# simulation, so no fit-side RNG use can leak into the data stream, and any cell
# can be extended without disturbing earlier reps (unlike the shipped oracle
# script's single continuous stream -- see response §4).
pkgload::load_all(
  Sys.getenv("INTRACLASS_DIR", "."),
  quiet = TRUE,
  export_all = FALSE
)

n_clusters <- 20L
n_subj_per <- 5L
k <- 5L
s2_c <- 0.50
s2_sc <- 1.00
s2_r <- 0.16
s2_res <- 0.50
missing_frac <- 0.12

pop_subject <- function(kk) s2_sc / (s2_sc + (s2_r + s2_res) / kk)

full_grid <- function() {
  expand.grid(
    rr = seq_len(k),
    s = seq_len(n_subj_per),
    cluster = seq_len(n_clusters)
  )
}

# Verbatim from the oracle script (deterministic given the base seed).
make_incidence <- function(seed) {
  g <- full_grid()
  n_drop <- round(missing_frac * nrow(g))
  repeat {
    seed <- seed + 1L
    set.seed(seed)
    keep <- g[-sample(nrow(g), n_drop), ]
    sid <- paste0(keep$cluster, "_s", keep$s)
    rid <- paste0(sid, "_r", keep$rr)
    d0 <- data.frame(
      cluster = factor(keep$cluster),
      subject = factor(sid),
      rater = factor(rid),
      score = stats::rnorm(nrow(keep))
    )
    ok <- tryCatch(
      {
        intraclass::icc(
          d0,
          score,
          subject,
          rater,
          cluster = cluster,
          engine = "glmmTMB"
        )
        TRUE
      },
      error = function(e) FALSE
    )
    if (ok) {
      di <- intraclass:::summarize_design(d0)
      return(list(keep = keep, k_eff = di$k_eff, seed = seed))
    }
  }
}

# One dataset from the Design-3 DGP on an arbitrary kept grid (complete = full).
simulate_d3 <- function(grid) {
  sid <- paste0(grid$cluster, "_s", grid$s)
  rid <- paste0(sid, "_r", grid$rr)
  mu_c <- stats::rnorm(n_clusters, 0, sqrt(s2_c))
  mu_sc <- stats::rnorm(length(unique(sid)), 0, sqrt(s2_sc))
  mu_r <- stats::rnorm(length(unique(rid)), 0, sqrt(s2_r))
  data.frame(
    cluster = factor(grid$cluster),
    subject = factor(sid),
    rater = factor(rid),
    score = mu_c[grid$cluster] +
      mu_sc[as.integer(factor(sid))] +
      mu_r[as.integer(factor(rid))] +
      stats::rnorm(nrow(grid), 0, sqrt(s2_res))
  )
}

spec_d3 <- c(
  cluster = "sd_cluster__Intercept",
  subject = "sd_cluster:subject__Intercept",
  residual = "sigma"
)

est_d3 <- function(unit, keff) {
  intraclass:::icc_estimand(
    type = "agreement",
    unit = unit,
    raters = "random",
    k_eff = keff,
    multilevel = TRUE,
    level = "subject",
    oneway = TRUE
  )
}

# Paired frequentist read on the same data via the shipped public path.
freq_row <- function(d, keff) {
  ok <- tryCatch(
    {
      fit <- intraclass::icc(
        d,
        score,
        subject,
        rater,
        cluster = cluster,
        engine = "glmmTMB",
        seed = 1L
      )
      td <- generics::tidy(fit)
      i1 <- td[td$index == "ICC(1)", ]
      ik <- td[td$index == "ICC(k)", ]
      p1 <- pop_subject(1)
      pk <- pop_subject(keff)
      data.frame(
        f_est1 = i1$estimate,
        f_lo1 = i1$conf.low,
        f_hi1 = i1$conf.high,
        f_cover1 = i1$conf.low <= p1 && p1 <= i1$conf.high,
        f_estk = ik$estimate,
        f_coverk = ik$conf.low <= pk && pk <= ik$conf.high
      )
    },
    error = function(e) NULL
  )
  if (is.null(ok)) {
    data.frame(
      f_est1 = NA_real_,
      f_lo1 = NA_real_,
      f_hi1 = NA_real_,
      f_cover1 = NA,
      f_estk = NA_real_,
      f_coverk = NA
    )
  } else {
    ok
  }
}

# One brms replication with mechanism diagnostics + the paired glmmTMB row.
bayes_rep <- function(base_fit, d, keff, fit_seed, cell) {
  fit <- suppressWarnings(suppressMessages(stats::update(
    base_fit,
    newdata = d,
    seed = fit_seed,
    recompile = FALSE,
    refresh = 0
  )))
  draws <- intraclass:::brms_component_draws(fit, spec_d3)
  summ <- intraclass:::posterior_summary(
    draws,
    list(subj1 = est_d3("single", keff), subjk = est_d3("average", keff)),
    conf_level = 0.95
  )
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_d3))
  comps <- stats::setNames(
    lapply(rownames(draws), function(r) draws[r, ]),
    rownames(draws)
  )
  v1 <- intraclass:::icc_point(comps, est_d3("single", keff))
  v1 <- v1[is.finite(v1)]
  p1 <- pop_subject(1)
  pk <- pop_subject(keff)
  s1 <- summ$subj1
  sk <- summ$subjk
  out <- data.frame(
    cell = cell,
    k_eff = keff,
    map1 = s1$point,
    lo1 = s1$conf.low,
    hi1 = s1$conf.high,
    cover1 = s1$conf.low <= p1 && p1 <= s1$conf.high,
    mapk = sk$point,
    coverk = sk$conf.low <= pk && pk <= sk$conf.high,
    post_mean1 = mean(v1),
    post_sd1 = stats::sd(v1),
    pit1 = mean(v1 <= p1),
    rhat = conv$rhat,
    ess = conv$ess_bulk,
    converged = isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  )
  rm(fit)
  gc(verbose = FALSE)
  cbind(out, freq_row(d, keff))
}

arm <- commandArgs(trailingOnly = TRUE)[1]
out_dir <- "data-raw/reviews"
inc_orig <- make_incidence(32200L) # deterministic; k_eff = 30/7, accepted seed 32203
stopifnot(isTRUE(all.equal(inc_orig$k_eff, 30 / 7)))
fresh_bases <- c(55100L, 55200L, 55300L, 55400L)

if (identical(arm, "freq")) {
  fresh <- lapply(fresh_bases, make_incidence)
  cells <- c(
    list(
      complete = list(keep = full_grid(), k_eff = k),
      ragged_orig = inc_orig
    ),
    stats::setNames(fresh, paste0("ragged_f", seq_along(fresh)))
  )
  n_rep <- c(2000L, 2000L, 1000L, 1000L, 1000L, 1000L)
  rows <- list()
  for (ci in seq_along(cells)) {
    cell <- cells[[ci]]
    for (r in seq_len(n_rep[ci])) {
      set.seed(600000L + ci * 10000L + r)
      fr <- freq_row(simulate_d3(cell$keep), cell$k_eff)
      fr$cell <- names(cells)[ci]
      fr$k_eff <- cell$k_eff
      rows[[length(rows) + 1L]] <- fr
    }
    message(names(cells)[ci], " done")
  }
  saveRDS(
    do.call(rbind, rows),
    file.path(out_dir, "fable-check-m32s2-freq.rds")
  )
} else if (arm %in% c("bayes1", "bayes2")) {
  suppressMessages(library(brms))
  brm_args <- list(
    chains = 3L,
    iter = 2000L,
    warmup = 1000L,
    cores = 3L,
    refresh = 0L
  )
  cells <- if (identical(arm, "bayes1")) {
    list(
      ragged_orig = c(
        inc_orig,
        list(n_rep = 240L, dseed = 710000L, fseed = 810000L)
      ),
      complete = list(
        keep = full_grid(),
        k_eff = k,
        n_rep = 120L,
        dseed = 720000L,
        fseed = 820000L
      )
    )
  } else {
    stats::setNames(
      lapply(seq_along(fresh_bases), function(i) {
        c(
          make_incidence(fresh_bases[i]),
          list(
            n_rep = 80L,
            dseed = 730000L + i * 1000L,
            fseed = 830000L + i * 1000L
          )
        )
      }),
      paste0("ragged_f", seq_along(fresh_bases))
    )
  }
  set.seed(700000L)
  base_fit <- do.call(
    brms::brm,
    c(
      list(
        formula = score ~ 1 + (1 | cluster) + (1 | cluster:subject),
        data = simulate_d3(full_grid()),
        prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
      ),
      brm_args
    )
  )
  ckpt <- file.path(out_dir, sprintf("fable-check-m32s2-%s.rds", arm))
  rows <- list()
  for (nm in names(cells)) {
    cell <- cells[[nm]]
    for (r in seq_len(cell$n_rep)) {
      set.seed(cell$dseed + r)
      d <- simulate_d3(cell$keep)
      rows[[length(rows) + 1L]] <-
        bayes_rep(base_fit, d, cell$k_eff, fit_seed = cell$fseed + r, cell = nm)
      if (r %% 10L == 0L) {
        saveRDS(do.call(rbind, rows), ckpt)
        message(sprintf("%s rep %d/%d", nm, r, cell$n_rep))
      }
    }
  }
  saveRDS(do.call(rbind, rows), ckpt)
} else {
  stop("arm must be freq, bayes1, or bayes2")
}
