# Design summary for (possibly) incomplete two-way layouts -----------------------
#
# M3 drops M1/M2's balanced-complete assumption: subjects may be rated by
# different, overlapping subsets of raters (missing subject x rater cells). Two
# design facts then stop being free and must be computed
# (estimand-spec M3 §3, §5, ADR-008):
#
#   * connectedness -- separating the subject and rater variances requires the
#     observed-cell bipartite graph (a node per subject, a node per rater, an
#     edge per observed cell) to be a single connected component. A disconnected
#     design aliases sigma^2_s with sigma^2_r and is not identified
#     (PRINCIPLES.md #5); `icc()` aborts on it.
#   * k_eff -- the averaging divisor for `ICC(*,k)`. With unequal ratings per
#     subject the "number of raters averaged" is the harmonic mean of the
#     per-subject rating counts, k_eff = 1 / mean(1 / n_i): the effective sample
#     size at which error / k_eff equals the average per-subject error variance
#     (ADR-008). On balanced data every n_i = k, so k_eff = k and the M1/M2
#     numbers are reproduced exactly.
#
# The estimand is one rating per observed cell; within-cell replicates (which
# would split the subject x rater interaction from pure error) are out of scope
# for M3 and reported as unsupported rather than silently folded into residual.

# Summarize the observed subject x rater design. `df` is the canonicalized frame
# (factor `subject`, factor `rater`, numeric `score`), already `droplevels()`-ed
# so every factor level is observed. Pure: returns facts; `icc()` decides which
# aborts to raise.
summarize_design <- function(df) {
  counts <- table(df$subject, df$rater)
  ns <- nrow(counts)
  nr <- ncol(counts)

  has_replicates <- any(counts > 1L)
  n_cells <- sum(counts > 0L)
  per_subject <- rowSums(counts) # ratings per subject (n_i)
  k_eff <- 1 / mean(1 / per_subject)
  # Balanced == complete crossed design with exactly one rating per cell.
  balanced <- !has_replicates && n_cells == ns * nr

  list(
    balanced = balanced,
    has_replicates = has_replicates,
    n_cells = n_cells,
    k_eff = k_eff,
    connected = design_connected(counts > 0L)
  )
}

# Is the subject x rater bipartite design connected? `incidence` is the ns x nr
# logical matrix of observed cells. Union-find over the ns subject nodes and nr
# rater nodes: each observed cell unions its subject with its rater; the design
# is connected iff all nodes share one root. Every node is observed (droplevels),
# so counting roots over all nodes is exact.
design_connected <- function(incidence) {
  ns <- nrow(incidence)
  nr <- ncol(incidence)
  parent <- seq_len(ns + nr)
  find <- function(x) {
    while (parent[x] != x) {
      x <- parent[x]
    }
    x
  }
  edges <- which(incidence, arr.ind = TRUE)
  for (e in seq_len(nrow(edges))) {
    a <- find(edges[e, 1L])
    b <- find(ns + edges[e, 2L])
    if (a != b) {
      parent[b] <- a
    }
  }
  roots <- vapply(seq_len(ns + nr), find, integer(1))
  length(unique(roots)) == 1L
}
