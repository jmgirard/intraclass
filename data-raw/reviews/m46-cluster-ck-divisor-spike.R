# M46 T1 feasibility spike: the averaged cluster-level ICC(c,k) divisor under
# incomplete/ragged CROSSED Design-1 multilevel data (M9 §3b/§9, ADR-057).
#
# Question (the ship-vs-abort decision point): the averaged cluster-level ICC(c,k)
# is  sigma^2_c / (sigma^2_c + error / k_c^eff),  error = {sigma^2_r, sigma^2_cr}
# (agreement) or {sigma^2_cr} (consistency). On COMPLETE data k_c^eff = k. On
# RAGGED data the effective raters behind a cluster mean is a PER-CLUSTER quantity
# and several definitions are defensible. Which candidate divisor recovers the
# population reliability of realized ragged cluster means -- and is agreement exact
# or only an effective-k approximation (M9 §5's open hedge)?
#
# Two independent oracle legs (#1):
#   (L1) ANALYTIC. A cluster's observed mean is the mean over its observed
#        subject x rater CELLS, so rater r enters with weight w_{c,r} =
#        (cells by r in c) / (cells in c). The crv[c,r] contribution has variance
#        sigma^2_cr * sum_r w_{c,r}^2 = sigma^2_cr / m_c^IS, with the inverse-Simpson
#        effective count  m_c^IS = 1 / sum_r w_{c,r}^2 . Likewise the global rater
#        effect rr[r] contributes sigma^2_r / m_c^IS (marginally, rr iid). So the
#        per-cluster ABSOLUTE (agreement) error is (sigma^2_r + sigma^2_cr)/m_c^IS
#        and the RELATIVE (consistency) error is sigma^2_cr/m_c^IS -- EXACT, no fit.
#        A single reported divisor must satisfy error / k_c^eff = mean_c(error/m_c^IS)
#        => k_c^eff = 1 / mean_c(1/m_c^IS)  (harmonic mean of the inverse-Simpson
#        per-cluster counts). Candidate (2). Predicts consistency EXACT with (2).
#   (L2) MONTE-CARLO. Fix a ragged design; over R reps redraw all components from
#        KNOWN values (large n_s so subject/residual leakage into the cluster mean
#        is negligible -- the cluster estimand averages them out, M5 §3). Measure
#        the reliability of the realized cluster means DIRECTLY (variance
#        decomposition, not the formula) and compare each candidate's plug-in
#        Phi(k_c^eff) / rho(k_c^eff). Non-circular: the truth is measured, the
#        candidates are formulas. Swept over imbalance patterns x cluster count C_n
#        (the incidental-parameters mode is invisible at few clusters).
#
# Candidates: (1) harmonic mean of DISTINCT raters/cluster m_c; (2) harmonic mean
# of inverse-Simpson counts m_c^IS; (3) arithmetic mean of m_c; (4) the
# subject-level k_eff (M9 §5 -- included to refute/confirm it coincidentally works).

suppressPackageStartupMessages({
  stopifnot(requireNamespace("glmmTMB", quietly = TRUE))
  stopifnot(requireNamespace("lme4", quietly = TRUE))
})

# ---- candidate per-cluster effective-rater divisors ----
# d: ragged Design-1 data with columns cluster, subject, rater (one row per cell).
cell_counts <- function(d) {
  # per cluster: named vector of cells-per-rater
  split(d$rater, d$cluster) |> lapply(\(rs) table(droplevels(rs)))
}
m_distinct <- function(d) vapply(cell_counts(d), \(tc) length(tc), numeric(1))
m_invsimpson <- function(d) {
  vapply(
    cell_counts(d),
    \(tc) {
      w <- as.numeric(tc) / sum(tc)
      1 / sum(w^2)
    },
    numeric(1)
  )
}
harm <- function(x) 1 / mean(1 / x)
k_eff_subject <- function(d) {
  n_i <- as.integer(table(d$subject))
  1 / mean(1 / n_i)
}
candidates <- function(d) {
  mc <- m_distinct(d)
  mis <- m_invsimpson(d)
  c(
    harm_distinct = harm(mc), # (1)
    harm_invsimpson = harm(mis), # (2)  <- L1 predicts EXACT
    arith_distinct = mean(mc), # (3)
    k_eff_subject = k_eff_subject(d) # (4)
  )
}

# ---- DGP: crossed Design 1, GLOBAL raters, five components ----
# score = 10 + c_cluster + sc_{s:c} + r_rater + cr_{c,r} + resid  (M5 fit).
sim_design1 <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  rr <- stats::rnorm(k, 0, sqrt(vr))
  crv <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    rr[d$rater] +
    crv[cbind(d$cluster, d$rater)] +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(d$rater)
  attr(d, "cl") <- cl
  d
}

# MCAR ragged: drop a proportion of cells at random (keep >=2 raters/cluster).
ragged_mcar <- function(d, prop, seed) {
  set.seed(seed)
  keep <- d[-sample(nrow(d), round(prop * nrow(d))), , drop = FALSE]
  ok <- names(which(vapply(
    split(keep$rater, keep$cluster),
    \(rs) length(unique(rs)) >= 2,
    logical(1)
  )))
  keep[keep$cluster %in% ok, , drop = FALSE]
}
# MAR ragged: raters drop out of clusters structurally (uneven m_c across clusters),
# so m_c^IS and m_c diverge and clusters carry very different rater counts.
ragged_structured <- function(d, seed) {
  set.seed(seed)
  k <- nlevels(d$rater)
  nc <- nlevels(d$cluster)
  keep_idx <- logical(nrow(d))
  for (c in seq_len(nc)) {
    # cluster c keeps a random size-m_c rater subset, m_c in 2..k, uneven
    mc <- sample(2:k, 1)
    rk <- sample(seq_len(k), mc)
    # within the kept raters, also drop some cells unevenly (weights uneven)
    in_c <- d$cluster == levels(d$cluster)[c] & as.integer(d$rater) %in% rk
    idx <- which(in_c)
    drop_frac <- runif(1, 0, 0.35)
    dropped <- sample(idx, floor(drop_frac * length(idx)))
    keep_idx[setdiff(idx, dropped)] <- TRUE
  }
  keep <- d[keep_idx, , drop = FALSE]
  ok <- names(which(vapply(
    split(keep$rater, keep$cluster),
    \(rs) length(unique(rs)) >= 2,
    logical(1)
  )))
  keep[keep$cluster %in% ok, , drop = FALSE]
}

# ---- L2: direct Monte-Carlo reliability of realized ragged cluster means ----
# On a FIXED design `d` (its cell pattern), redraw components R times from known
# values, form each cluster's observed cell-mean, and measure reliability by
# variance decomposition (NOT the candidate formula):
#   observed cluster mean  mhat_c = c_c + a_c + b_c + leak_c   (leak -> 0, large n_s)
#     a_c = sum_r w_{c,r} rr[r]   (global rater, absolute-error source: AGREEMENT)
#     b_c = sum_r w_{c,r} crv[c,r] (cluster x rater: consistency + agreement)
#   consistency (relative): remove the per-rep grand rater shift; error = var of
#     (b_c - centering); rho = vc / (vc + mean_rep var_c(b_c-part))
#   agreement (absolute):   error = mean_rep mean_c (a_c + b_c)^2 (deviation from
#     the cluster's TRUE absolute level); Phi = vc / (vc + that)
# We measure the ERROR terms directly from simulated a_c, b_c (known components),
# so the truth is independent of any divisor formula.
mc_truth <- function(d, vc, vr, vcr, R = 4000, seed = 101) {
  set.seed(seed)
  cl <- split(seq_len(nrow(d)), d$cluster)
  cl <- cl[vapply(cl, length, numeric(1)) > 0]
  nc <- length(cl)
  raters_of <- lapply(cl, \(ix) as.integer(d$rater[ix]))
  k <- nlevels(d$rater)
  abs_err <- numeric(R) # mean_c (a_c + b_c)^2
  rel_err <- numeric(R) # var_c of consistency part (crv), absolute (crv indep across c)
  for (g in seq_len(R)) {
    rr <- stats::rnorm(k, 0, sqrt(vr))
    a <- numeric(nc)
    b <- numeric(nc)
    for (j in seq_len(nc)) {
      rj <- raters_of[[j]] # one entry per CELL -> cell weighting is automatic
      a[j] <- mean(rr[rj])
      crc <- stats::rnorm(k, 0, sqrt(vcr)) # crv[c,] independent across clusters
      b[j] <- mean(crc[rj])
    }
    abs_err[g] <- mean((a + b)^2) # absolute error of cluster means
    rel_err[g] <- mean(b^2) # consistency error (b indep across clusters, mean 0)
  }
  phi <- vc / (vc + mean(abs_err))
  rho <- vc / (vc + mean(rel_err))
  c(Phi = phi, rho = rho, abs_err = mean(abs_err), rel_err = mean(rel_err))
}

plug_in <- function(vc, vr, vcr, keff) {
  c(
    Phi = vc / (vc + (vr + vcr) / keff),
    rho = vc / (vc + vcr / keff)
  )
}

# ---- battery ----
run_cell <- function(label, d, vc, vr, vcr, R = 4000) {
  kk <- candidates(d)
  tru <- mc_truth(d, vc, vr, vcr, R = R)
  cat(sprintf("\n== %s ==\n", label))
  cat(sprintf(
    "  clusters kept=%d  cells=%d  m_c distinct: %s  m_c^IS: %s\n",
    nlevels(droplevels(d$cluster)),
    nrow(d),
    paste(round(m_distinct(d), 1), collapse = ","),
    paste(round(m_invsimpson(d), 2), collapse = ",")
  ))
  cat(sprintf(
    "  divisors: harm_distinct=%.3f harm_IS=%.3f arith=%.3f k_eff_subj=%.3f\n",
    kk["harm_distinct"],
    kk["harm_invsimpson"],
    kk["arith_distinct"],
    kk["k_eff_subject"]
  ))
  cat(sprintf(
    "  MC truth : Phi(agree)=%.4f  rho(consist)=%.4f  [abs_err=%.4f rel_err=%.4f]\n",
    tru["Phi"],
    tru["rho"],
    tru["abs_err"],
    tru["rel_err"]
  ))
  for (nm in names(kk)) {
    pi <- plug_in(vc, vr, vcr, kk[[nm]])
    cat(sprintf(
      "    %-16s Phi=%.4f (d=%+.4f)  rho=%.4f (d=%+.4f)\n",
      nm,
      pi["Phi"],
      pi["Phi"] - tru["Phi"],
      pi["rho"],
      pi["rho"] - tru["rho"]
    ))
  }
  invisible(list(truth = tru, cand = kk))
}

# Known components (moderate cluster signal + rater disagreement).
vc <- 1.0
vsc <- 0.8
vr <- 0.5
vcr <- 0.3
vres <- 0.6
cat("Known components: vc=1.0 vsc=0.8 vr=0.5 vcr=0.3 vres=0.6\n")
cat(sprintf(
  "Complete-data cluster ICC(c,k=6): Phi=%.4f rho=%.4f (k_c^eff should -> 6)\n",
  vc / (vc + (vr + vcr) / 6),
  vc / (vc + vcr / 6)
))

# large n_s so subject/residual average out of the cluster mean (cluster estimand)
NS <- 40

# C1: small C_n, MCAR 15% (weights near-equal -> IS ~ distinct)
run_cell(
  "C1 small C_n=6, MCAR 15%",
  ragged_mcar(
    sim_design1(6, NS, 6, vc, vsc, vr, vcr, vres, 2026071201),
    0.15,
    11
  ),
  vc,
  vr,
  vcr
)
# C2: medium C_n, MCAR 30%
run_cell(
  "C2 medium C_n=20, MCAR 30%",
  ragged_mcar(
    sim_design1(20, NS, 6, vc, vsc, vr, vcr, vres, 2026071202),
    0.30,
    12
  ),
  vc,
  vr,
  vcr
)
# C3: large C_n, MCAR 30% (cluster-count sweep)
run_cell(
  "C3 large C_n=60, MCAR 30%",
  ragged_mcar(
    sim_design1(60, NS, 6, vc, vsc, vr, vcr, vres, 2026071203),
    0.30,
    13
  ),
  vc,
  vr,
  vcr
)
# C4: structured MAR -- uneven m_c and uneven cell weights (IS != distinct)
run_cell(
  "C4 large C_n=60, structured MAR (uneven weights)",
  ragged_structured(
    sim_design1(60, NS, 8, vc, vsc, vr, vcr, vres, 2026071204),
    21
  ),
  vc,
  vr,
  vcr
)
# C5: structured MAR, higher rater ceiling (bigger IS-vs-distinct gap)
run_cell(
  "C5 large C_n=80, structured MAR, k=10",
  ragged_structured(
    sim_design1(80, NS, 10, vc, vsc, vr, vcr, vres, 2026071205),
    22
  ),
  vc,
  vr,
  vcr
)

# C6: EXTREME within-cluster weight imbalance -- one dominant rater rates every
# subject, the rest rate only a few. Here m_c^IS << m_c distinct, so it separates
# inverse-Simpson (L1-exact) from distinct-count. The MC truth must follow IS.
extreme_imbalance <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
  d <- sim_design1(nc, ns, k, vc, vsc, vr, vcr, vres, seed)
  set.seed(seed + 1)
  keep <- logical(nrow(d))
  for (c in levels(d$cluster)) {
    in_c <- which(d$cluster == c)
    dom <- sample(seq_len(k), 1) # dominant rater: keep all its cells
    for (i in in_c) {
      r <- as.integer(d$rater[i])
      if (r == dom) {
        keep[i] <- TRUE
      } else {
        # non-dominant raters keep only ~3 subjects each (tiny weight)
        keep[i] <- (d$subj[i] %% ceiling(ns / 3)) == (r %% ceiling(ns / 3))
      }
    }
  }
  kept <- d[keep, , drop = FALSE]
  ok <- names(which(vapply(
    split(kept$rater, kept$cluster),
    \(rs) length(unique(rs)) >= 2,
    logical(1)
  )))
  kept[kept$cluster %in% ok, , drop = FALSE]
}
run_cell(
  "C6 C_n=60, EXTREME weight imbalance (IS << distinct)",
  extreme_imbalance(60, 30, 6, vc, vsc, vr, vcr, vres, 2026071206),
  vc,
  vr,
  vcr
)

# C7: component-invariance -- SAME extreme-imbalance design, different components
# (low cluster signal, high rater disagreement). k_c^eff is a design-only quantity
# (L1 proof is component-free), so inverse-Simpson must stay exact.
d_ext <- extreme_imbalance(60, 30, 6, 0.4, 0.8, 1.2, 0.9, 0.6, 2026071207)
run_cell(
  "C7 component-invariance (vc=0.4 vr=1.2 vcr=0.9, extreme design)",
  d_ext,
  vc = 0.4,
  vr = 1.2,
  vcr = 0.9
)

cat(
  "\n[done] Read the (d=...) columns: the candidate whose Phi/rho deltas are ~0\n"
)
cat(
  "across ALL cells is the divisor; a candidate exact for rho but not Phi means\n"
)
cat("agreement is an effective-k approximation (M9 §5 hedge holds).\n")
