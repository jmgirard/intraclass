# Oracle O-cluster-ck-cover: MC-interval coverage of the averaged cluster-level
# ICC(c,k) on incomplete/ragged crossed (Design 1) multilevel data (M46, ADR-057) ---
#
# Provenance for tests/testthat/test-icc-incomplete-multilevel.R (PRINCIPLES.md #1,
# #3, #12, #18). Reproducible, seeded, standalone (Rscript
# data-raw/oracle-cluster-ck-coverage.R); writes the committed summary fixture
# tests/testthat/fixtures/cluster-ck-coverage-oracle.rds the coverage test asserts against.
#
# A CI method's oracle is coverage (#1). The point divisor is Fable-blessed
# (data-raw/oracle-cluster-ck-incomplete.R); this checks the boundary-aware MC interval
# for ICC_c(A,k)/ICC_c(C,k) covers the population value at nominal rate. Per the Fable
# review (ADR-057 Am.1 Q4/§5) the sweep must contain: the C_n axis (the failure mode is
# invisible at few clusters -- [[coverage-oracle-cluster-count-axis]]), a C6-style
# EXTREME-imbalance cell (small k_c^eff ~ 2 -> the coefficient sits low, exercising the
# boundary-aware machinery), a C4-style HETEROGENEOUS-m_c cell (harmonic aggregation
# active), and a BOUNDARY sigma^2_c ~ 0 cell. k_c^eff is a DESIGN property, so the target
# is defined PER REALIZED DESIGN: each cell's ragged pattern is FROZEN across reps (the
# M36 pattern); only the components are resampled per rep (per-rep seeding). n_rep = 240
# ([[ragged-coverage-nrep-240]] -- the >= .88 pin false-alarms ~0.7%/cell at n_rep 80).

suppressPackageStartupMessages({
  stopifnot(requireNamespace("glmmTMB", quietly = TRUE))
})
devtools::load_all(quiet = TRUE)

n_rep <- if (nzchar(Sys.getenv("M46_NREP"))) {
  as.integer(Sys.getenv("M46_NREP"))
} else {
  240L
}
mc_n <- 2000L

# inverse-Simpson harmonic k_c^eff, independent of R/design.R
k_c_eff_ref <- function(d) {
  per <- tapply(seq_len(nrow(d)), d$cluster, function(ix) {
    w <- as.numeric(table(droplevels(d$rater[ix])))
    w <- w / sum(w)
    1 / sum(w^2)
  })
  1 / mean(1 / per)
}

# A FROZEN ragged cell pattern (cluster/subject/rater columns only); `score` is filled
# per rep. Three patterns: MCAR deletion, structured MAR (heterogeneous m_c), and extreme
# within-cluster weight imbalance (dominant rater). Each returns a droplevels()-ed frame.
pattern_mcar <- function(nc, ns, k, prop, seed) {
  set.seed(seed)
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  d <- d[-sample(nrow(d), round(prop * nrow(d))), , drop = FALSE]
  finish_pattern(d)
}
pattern_structured <- function(nc, ns, k, seed) {
  set.seed(seed)
  keep <- list()
  for (c in seq_len(nc)) {
    mc <- sample(2:k, 1)
    rk <- sample(seq_len(k), mc)
    for (r in rk) {
      subs <- sample(seq_len(ns), max(2L, floor(ns * runif(1, 0.5, 1))))
      keep[[length(keep) + 1]] <- expand.grid(
        subj = subs,
        rater = r,
        cluster = c
      )
    }
  }
  finish_pattern(do.call(rbind, keep))
}
pattern_extreme <- function(nc, ns, k, seed) {
  set.seed(seed)
  keep <- list()
  for (c in seq_len(nc)) {
    dom <- sample(seq_len(k), 1)
    for (r in seq_len(k)) {
      subs <- if (r == dom) {
        seq_len(ns)
      } else {
        sample(seq_len(ns), max(2L, floor(ns / 4)))
      }
      keep[[length(keep) + 1]] <- expand.grid(
        subj = subs,
        rater = r,
        cluster = c
      )
    }
  }
  finish_pattern(do.call(rbind, keep))
}
finish_pattern <- function(d) {
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(d$rater)
  # keep only clusters with >= 2 raters (bridging is checked by icc())
  ok <- names(which(vapply(
    split(d$rater, d$cluster),
    \(rs) length(unique(rs)) >= 2,
    logical(1)
  )))
  droplevels(d[d$cluster %in% ok, , drop = FALSE])
}

# fill `score` from known components on the frozen design
rescore <- function(d, vc, vsc, vr, vcr, vres) {
  nc <- nlevels(d$cluster)
  k <- nlevels(d$rater)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  scv <- stats::rnorm(nlevels(d$subject), 0, sqrt(vsc))
  rr <- stats::rnorm(k, 0, sqrt(vr))
  crv <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
  d$score <- 10 +
    cl[as.integer(d$cluster)] +
    scv[as.integer(d$subject)] +
    rr[as.integer(d$rater)] +
    crv[cbind(as.integer(d$cluster), as.integer(d$rater))] +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d
}

# one grid cell: coverage of the FROZEN design's population ICC_c(A,k)/ICC_c(C,k)
run_cell <- function(label, C_n, d, vc, vsc, vr, vcr, vres, seed) {
  kce <- k_c_eff_ref(d)
  pop <- c(
    A = vc / (vc + (vr + vcr) / kce),
    C = vc / (vc + vcr / kce)
  )
  hitA <- hitC <- nfit <- 0L
  biasA <- 0
  for (r in seq_len(n_rep)) {
    set.seed(seed + r)
    di <- rescore(d, vc, vsc, vr, vcr, vres)
    x <- tryCatch(
      suppressWarnings(suppressMessages(icc(
        di,
        score,
        subject,
        rater,
        cluster = cluster,
        level = "cluster",
        type = c("agreement", "consistency"),
        unit = "average",
        seed = seed + r,
        mc_samples = mc_n
      ))),
      error = function(e) NULL
    )
    if (is.null(x)) {
      next
    }
    e <- x$estimates
    ra <- e[e$index == "ICC(A,k)" & e$level == "cluster", ]
    rc <- e[e$index == "ICC(C,k)" & e$level == "cluster", ]
    if (nrow(ra) != 1L || nrow(rc) != 1L) {
      next
    }
    nfit <- nfit + 1L
    biasA <- biasA + (ra$estimate - pop[["A"]])
    if (pop[["A"]] >= ra$conf.low && pop[["A"]] <= ra$conf.high) {
      hitA <- hitA + 1L
    }
    if (pop[["C"]] >= rc$conf.low && pop[["C"]] <= rc$conf.high) {
      hitC <- hitC + 1L
    }
  }
  cat(sprintf(
    "[%-26s] C_n=%-3d k_c^eff=%.2f popA=%.3f popC=%.3f  coverA=%.3f coverC=%.3f biasA=%+.4f (n=%d)\n",
    label,
    C_n,
    kce,
    pop[["A"]],
    pop[["C"]],
    hitA / nfit,
    hitC / nfit,
    biasA / nfit,
    nfit
  ))
  data.frame(
    cell = label,
    C_n = C_n,
    k_c_eff = kce,
    pop_A = pop[["A"]],
    pop_C = pop[["C"]],
    coverage_A = hitA / nfit,
    coverage_C = hitC / nfit,
    bias_A = biasA / nfit,
    n_fit = nfit
  )
}

# interior components; boundary cell uses vc ~ 0
vc <- 0.8
vsc <- 0.8
vr <- 0.5
vcr <- 0.3
vres <- 0.6
cat(sprintf("n_rep=%d mc_n=%d\n", n_rep, mc_n))

cells <- list(
  # C_n axis (MCAR 20%) -- the incidental-parameters mode is invisible at few clusters
  list("C_n axis: small", 8, pattern_mcar(8, 8, 5, 0.20, 461), vc),
  list("C_n axis: medium", 20, pattern_mcar(20, 8, 5, 0.20, 462), vc),
  list("C_n axis: large", 60, pattern_mcar(60, 6, 5, 0.20, 463), vc),
  # heterogeneous m_c (structured MAR) -- harmonic aggregation active
  list("heterogeneous m_c", 40, pattern_structured(40, 8, 8, 464), vc),
  # extreme within-cluster weight imbalance -- small k_c^eff, low-coefficient regime
  list("extreme imbalance", 40, pattern_extreme(40, 8, 6, 465), vc),
  # boundary sigma^2_c ~ 0 (large C_n so vc is estimable near the floor)
  list("boundary vc~0", 60, pattern_mcar(60, 6, 5, 0.20, 466), 0.05)
)

out <- do.call(
  rbind,
  lapply(seq_along(cells), function(i) {
    cc <- cells[[i]]
    run_cell(
      cc[[1]],
      cc[[2]],
      cc[[3]],
      cc[[4]],
      vsc,
      vr,
      vcr,
      vres,
      seed = 46000 + 100 * i
    )
  })
)
out$n_rep <- n_rep

if (n_rep >= 240L) {
  saveRDS(out, "tests/testthat/fixtures/cluster-ck-coverage-oracle.rds")
  cat("\n[saved] tests/testthat/fixtures/cluster-ck-coverage-oracle.rds\n")
} else {
  cat(
    "\n[smoke] n_rep < 240 -> fixture NOT written (set M46_NREP=240 for the committed run)\n"
  )
}
cat(sprintf(
  "min coverage: A=%.3f C=%.3f | max |bias_A|=%.4f\n",
  min(out$coverage_A),
  min(out$coverage_C),
  max(abs(out$bias_A))
))
