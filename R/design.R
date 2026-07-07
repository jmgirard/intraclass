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

# Classify a multilevel design from the observed crossing pattern -----------------
#
# ten Hove et al. (2022, Table 2) distinguish three multilevel designs by how
# raters relate to clusters and subjects. M8 (estimand-spec §4) INFERS the design
# from the data rather than taking a declared argument (maintainer-approved): the
# data is the ground truth, and this keeps the API surface small (#6). `df` has
# factor subject/rater/cluster, droplevels()-ed, with subjects already verified
# nested in a single cluster.
#
#   * a rater spanning > 1 cluster            -> raters CROSSED with clusters (Design 1)
#   * every rater in one cluster, > 1 subject -> raters nested in clusters (Design 2)
#   * every rater in one subject              -> raters nested in subjects  (Design 3)
#
# A mixed pattern (some raters crossed, some nested) is none of the three clean
# designs and aborts loudly (PRINCIPLES.md #5), never guesses.
detect_multilevel_design <- function(df, call = rlang::caller_env()) {
  clusters_per_rater <- rowSums(table(df$rater, df$cluster) > 0L)
  if (all(clusters_per_rater > 1L)) {
    return("crossed")
  }
  if (any(clusters_per_rater > 1L)) {
    abort_unidentified(
      c(
        "The raters are neither fully crossed with nor fully nested in clusters.",
        i = "Some raters rate in several clusters while others rate in only one, \\
             which is not one of the multilevel designs of ten Hove et al. (2022).",
        i = "A supported design has raters crossed with every cluster (Design 1) \\
             or each rating a single cluster (Designs 2/3)."
      ),
      call = call
    )
  }
  # Every rater is confined to one cluster: nested. Distinguish Design 2 (raters
  # cross subjects within their cluster) from Design 3 (one subject per rater).
  subjects_per_rater <- rowSums(table(df$rater, df$subject) > 0L)
  if (all(subjects_per_rater == 1L)) {
    return("nested_in_subjects")
  }
  if (all(subjects_per_rater > 1L)) {
    return("nested_in_clusters")
  }
  abort_unidentified(
    c(
      "The raters are neither fully crossed with nor fully nested in subjects.",
      i = "Within a cluster some raters rate a single subject while others rate \\
           several, which is not one of the supported multilevel designs.",
      i = "Design 2 has each rater rate every subject in its cluster; Design 3 has \\
           each rater rate a single subject."
    ),
    call = call
  )
}

# Is a nested multilevel design (Design 2/3) balanced and complete? Every cluster
# must hold the same number of subjects and raters, with one rating per rater-by-
# subject cell within each cluster. M8 covers balanced/complete nested designs;
# incomplete nested multilevel is deferred (estimand-spec M8 §8), so `icc()` aborts
# on an unbalanced one rather than silently using an unvalidated k_eff divisor.
nested_design_balanced <- function(df) {
  subs <- colSums(table(df$subject, df$cluster) > 0L)
  rats <- colSums(table(df$rater, df$cluster) > 0L)
  if (length(unique(subs)) != 1L || length(unique(rats)) != 1L) {
    return(FALSE)
  }
  complete <- tapply(seq_len(nrow(df)), df$cluster, function(ix) {
    tb <- table(droplevels(df$subject[ix]), droplevels(df$rater[ix]))
    all(tb == 1L)
  })
  all(complete)
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
