# Fable M28 review check — frequentist nested-fixed theta^2_{r:c} MC-interval
# constructions (conjugate-normal, no model fitting; PRINCIPLES #1/#4/#18).
#
# On balanced nested Design 2 the k per-cluster rater cell means satisfy EXACTLY
#   beta_hat_c ~ N(mu_c, V),  V = (s2sc/n_s) J + (s2res/n_s) I
# and the MC interval draws beta* ~ N(beta_hat, V). Both identities the brief's
# derivation rests on (push-forward + plug-in inflation, each = b = tr(CV)/(k-1)
# = s2res/n_s since C annihilates J) are exact here, so the interval arithmetic
# can be verified directly, at high replication, without glmmTMB. Coverage is at
# the theta^2 level (ranks identically to the ICC level; M27 response §3).
#
# Constructions compared per replication (2000 draws each):
#   shipped   : per cluster pmax(0, q(beta*) - b), then average      (1b, cluster floor)
#   proposed  : per cluster q(beta*) - 2b, average, pmax(0, average) (2b, average floor)
#   reflected : basic/pivotal bootstrap of the estimator: draws
#               t* = mean_c(q(beta*_c) - b); CI = [2*point - q.975(t*),
#               2*point - q.025(t*)], clipped at 0  (the "recompute the
#               estimator per draw" alternative used the pivotal way)
# point = mean_c pmax(0, q(beta_hat_c) - b)  (the SHIPPED point, untouched).
#
# Run: Rscript data-raw/reviews/fable-check-nfi.R   (~1 min)

set.seed(20280)
S2SC <- 1.0
S2RES <- 0.5
N_REP <- 500L
N_DRAW <- 2000L

qform <- function(m, C, k) colSums(m * (C %*% m)) / (k - 1)

one_cell <- function(k, ns, cn, theta2) {
  C <- diag(k) - matrix(1 / k, k, k)
  b <- S2RES / ns # = tr(C V)/(k-1) exactly (C annihilates the J block)
  V <- (S2SC / ns) * matrix(1, k, k) + (S2RES / ns) * diag(k)
  L <- chol(V)
  base <- seq_len(k) - (k + 1) / 2
  mu <- if (theta2 == 0) {
    rep(0, k)
  } else {
    base * sqrt(theta2 / (sum(base^2) / (k - 1)))
  }

  hit <- matrix(
    0L,
    N_REP,
    3,
    dimnames = list(NULL, c("shipped", "proposed", "reflected"))
  )
  contain <- 0L # point inside the proposed interval
  for (r in seq_len(N_REP)) {
    beta_hat <- mu + t(L) %*% matrix(rnorm(k * cn), k, cn) # k x cn, per-cluster estimates
    q_hat <- qform(beta_hat, C, k)
    point <- mean(pmax(0, q_hat - b))

    # draws: k x cn x N_DRAW collapsed as k x (cn*N_DRAW)
    eps <- t(L) %*% matrix(rnorm(k * cn * N_DRAW), k, cn * N_DRAW)
    bstar <- as.vector(beta_hat)[rep(seq_len(k * cn), N_DRAW)] + eps
    qs <- matrix(qform(matrix(bstar, k), C, k), cn, N_DRAW) # cn x N_DRAW

    shipped <- colMeans(pmax(qs - b, 0)) # pmax(m, 0) keeps dim; pmax(0, m) drops it
    proposed <- pmax(0, colMeans(qs) - 2 * b)
    tstar <- colMeans(qs) - b # estimator recomputed per draw (centered q_hat-bar)

    ci_s <- quantile(shipped, c(.025, .975), names = FALSE)
    ci_p <- quantile(proposed, c(.025, .975), names = FALSE)
    ci_r <- pmax(0, 2 * point - quantile(tstar, c(.975, .025), names = FALSE))

    hit[r, ] <- c(
      theta2 >= ci_s[1] && theta2 <= ci_s[2],
      theta2 >= ci_p[1] && theta2 <= ci_p[2],
      theta2 >= ci_r[1] && theta2 <= ci_r[2]
    )
    contain <- contain + (point >= ci_p[1] && point <= ci_p[2])
  }
  data.frame(
    k = k,
    n_s = ns,
    C_n = cn,
    theta2 = theta2,
    cell = if (theta2 == 0) "boundary" else "interior",
    shipped = mean(hit[, 1]),
    proposed = mean(hit[, 2]),
    reflected = mean(hit[, 3]),
    point_in_proposed = contain / N_REP
  )
}

grid <- expand.grid(
  k = c(2L, 4L),
  n_s = c(3L, 20L),
  C_n = c(5L, 80L),
  KEEP.OUT.ATTRS = FALSE
)
out <- do.call(
  rbind,
  lapply(seq_len(nrow(grid)), function(g) {
    do.call(
      rbind,
      lapply(c(0, S2RES / grid$n_s[g], 0.66), function(t2) {
        one_cell(grid$k[g], grid$n_s[g], grid$C_n[g], t2)
      })
    )
  })
)
out[, c("shipped", "proposed", "reflected", "point_in_proposed")] <-
  round(out[, c("shipped", "proposed", "reflected", "point_in_proposed")], 3)
print(out, row.names = FALSE)

cat("\nsummary (mean coverage by cell type):\n")
print(aggregate(cbind(shipped, proposed, reflected) ~ cell, out, function(z) {
  round(mean(z), 3)
}))
