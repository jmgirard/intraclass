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
  # The ICC(*,k) divisor for the two-way REPLICATE path counts distinct raters per
  # subject, not total ratings -- replicates within a rater must not inflate it
  # (estimand-spec M17-within-cell-replicates.md §4). Identical to `k_eff` when there
  # is one rating per cell, so the classic paths are unchanged.
  raters_per_subject <- rowSums(counts > 0L)
  k_eff_raters <- 1 / mean(1 / raters_per_subject)
  # Within-cell replicate facts: `n_o` is the uniform per-cell rating count when the
  # replicated design is complete and balanced (every cell present, equal counts);
  # NA otherwise. `replicates_uniform` gates the M17 Slice 3 replicate path (ragged
  # replicates are deferred, §7).
  observed <- counts[counts > 0L]
  replicates_uniform <- has_replicates &&
    n_cells == ns * nr &&
    length(unique(as.integer(observed))) == 1L
  n_o <- if (replicates_uniform) as.integer(observed[[1L]]) else NA_integer_
  # Balanced == complete crossed design with exactly one rating per cell.
  balanced <- !has_replicates && n_cells == ns * nr

  list(
    balanced = balanced,
    has_replicates = has_replicates,
    replicates_uniform = replicates_uniform,
    n_o = n_o,
    n_cells = n_cells,
    k_eff = k_eff,
    k_eff_raters = k_eff_raters,
    connected = design_connected(counts > 0L)
  )
}

# Effective rater divisor for the averaged cluster-level ICC(c,k) under multilevel
# imbalance (M9 §3b/§9, ADR-057; Fable-blessed, ADR-057 Am.1). On complete data the
# cluster average divides by the rater count k, exactly like every other coefficient;
# on ragged data the effective raters behind a cluster mean is a PER-CLUSTER quantity,
# distinct from the per-subject k_eff of summarize_design(). The reported cluster
# coefficient describes each cluster's OBSERVED cell-pooled mean, in which rater r
# carries weight w_{c,r} = (cells of r in cluster c) / (cells in cluster c). The
# effective raters behind that mean is the inverse-Simpson count
# m_c^IS = 1 / sum_r w_{c,r}^2 (= distinct raters when weights are equal, < it
# otherwise), and the single divisor whose error/k equals the cross-cluster average
# of the per-cluster error is their harmonic mean:
#
#   k_c^eff = 1 / mean_c(1 / m_c^IS)
#
# This is EXACT for both agreement and consistency (the marginal per-cluster error
# is (sigma^2_r + sigma^2_cr)/m_c^IS and sigma^2_cr/m_c^IS respectively; cross-cluster
# rater-sharing does not enter the estimand -- ADR-057 Am.1 Q2), reduces to k on
# balanced/uniform-weight data (recovering M5), and is a deterministic design constant
# (component-free, draw-independent -- no interval interaction, Am.1 Q4). `df` has
# factor cluster/subject/rater, droplevels()-ed; used only for the crossed Design 1
# cluster level.
cluster_k_eff <- function(df) {
  per_cluster <- tapply(seq_len(nrow(df)), df$cluster, function(ix) {
    w <- as.numeric(table(droplevels(df$rater[ix])))
    w <- w / sum(w)
    1 / sum(w^2)
  })
  1 / mean(1 / per_cluster)
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
    # Every rater appears in more than one cluster, so raters are read as CROSSED
    # with clusters (Design 1) -- the same rater label in different clusters is
    # taken to be the same person. That is inferred purely from the labels: a nested
    # design carrying reused, cluster-relative rater labels ("rater 1"/"rater 2" in
    # every cluster -- a very common convention) is indistinguishable here and would
    # otherwise be treated as crossed silently, inflating or deflating the ICC.
    # Subjects get a hard cross-cluster-reuse guard in icc(); raters cannot (shared
    # raters ARE the crossed design), so surface the assumption once instead. Only
    # reached during auto-detection (an explicit `design =` skips this function).
    cli::cli_inform(
      c(
        i = "Treating raters with the same label in different clusters as the same \\
             raters (crossed with clusters, Design 1).",
        i = "If each cluster has its own raters, give them cluster-unique labels or \\
             pass {.code design = \"nested_in_clusters\"}."
      ),
      .frequency = "once",
      .frequency_id = "intraclass_crossed_ml_labels"
    )
    return("crossed")
  }
  if (any(clusters_per_rater > 1L)) {
    abort_unidentified(
      c(
        "The raters are neither fully crossed with nor fully nested in clusters.",
        i = "Some raters rate in several clusters while others rate in only one, \\
             which is not unambiguously one of the multilevel designs of ten Hove \\
             et al. (2022).",
        i = "On incomplete data this is often a ragged crossed (Design 1) design: \\
             set {.code design = \"crossed\"} to declare it (validated against the \\
             data), or each rater must rate a single cluster for a nested design."
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
           several, which is not unambiguously one of the multilevel designs.",
      i = "Design 2 has each rater rate several subjects in its cluster; Design 3 \\
           has each rater rate a single subject.",
      i = "On {.emph incomplete} data missing cells can blur this: declare the \\
           design with {.code design = \"nested_in_clusters\"} or \\
           {.code design = \"nested_in_subjects\"} (validated against the data)."
    ),
    call = call
  )
}

# Is a nested multilevel design (Design 2/3) balanced and complete? M8 shipped
# balanced/complete nested designs; M19 Slice 1 (ADR-029) lifted the balance guard,
# so this no longer gates an abort -- it REPORTS balance for print/glance, and the
# averaging divisor is the harmonic-mean k_eff either way (reducing to the pinned
# M3/M6 incomplete divisor on ragged data). Balance means different things by
# design, so `design` selects the check (within-cell replicates are caught
# separately by summarize_design()$has_replicates):
#   * Design 2 (raters nested in clusters): equal subjects and raters per cluster,
#     with every rater rating every subject within its cluster (complete crossing);
#   * Design 3 (raters nested in subjects): equal subjects per cluster and equal
#     ratings per subject (no within-cluster crossing to complete).
nested_design_balanced <- function(df, design) {
  subs <- colSums(table(df$subject, df$cluster) > 0L)
  if (length(unique(subs)) != 1L) {
    return(FALSE)
  }
  if (design == "nested_in_clusters") {
    rats <- colSums(table(df$rater, df$cluster) > 0L)
    if (length(unique(rats)) != 1L) {
      return(FALSE)
    }
    complete <- tapply(seq_len(nrow(df)), df$cluster, function(ix) {
      tb <- table(droplevels(df$subject[ix]), droplevels(df$rater[ix]))
      all(tb == 1L)
    })
    all(complete)
  } else {
    # Design 3: equal ratings per subject.
    length(unique(as.integer(table(df$subject)))) == 1L
  }
}

# Within-cell replicate facts for a MULTILEVEL design (M20 Slice 2, ADR-030).
# summarize_design() reads the flat subject x rater grid, whose completeness notion
# (`n_cells == ns * nr`) is crossed-only, so its `n_o`/`replicates_uniform` are wrong
# for a nested (block-diagonal) Design 2. This computes a design-aware `n_o` (the
# uniform rating count per OBSERVED cell) and whether the design is a balanced,
# complete, uniformly-replicated one for its type -- by de-replicating to one row per
# cell and applying the design's own balance check (crossed: full grid; nested:
# block-complete). `design` is "crossed" or "nested_in_clusters" (Design 3 replicates
# are aborted by design before this is reached).
multilevel_replicate_facts <- function(df, design) {
  counts <- table(df$subject, df$rater)
  observed <- as.integer(counts[counts > 0L])
  equal <- length(unique(observed)) == 1L
  n_o <- if (equal) observed[[1L]] else NA_integer_
  cell1 <- !duplicated(df[c("subject", "rater")])
  df1 <- droplevels(df[cell1, , drop = FALSE])
  complete <- if (design == "crossed") {
    summarize_design(df1)$balanced
  } else {
    nested_design_balanced(df1, design)
  }
  list(n_o = n_o, uniform = equal && complete)
}

# Identifiability of an INCOMPLETE crossed (Design 1) multilevel design
# (estimand-spec M9 §4b). Balance is not required for the mixed-model fit, but
# under missing cells two graph conditions gate DIFFERENT coefficients, so they
# are reported separately (not folded into one balanced/connected flag):
#
#   * within_cluster_connected -- for every cluster, the subject x rater bipartite
#     graph over that cluster's observed cells is connected. Needed to separate
#     sigma^2_{s:c} from residual, so it gates CONSISTENCY (and therefore every
#     subject-level coefficient). Reuses design_connected() per cluster.
#   * cluster_rater_connected -- the cluster x rater bipartite graph (a node per
#     cluster, a node per rater, an edge per cluster a rater rated in) is
#     connected. Needed to separate the rater main effect sigma^2_r from the
#     cluster x rater interaction sigma^2_cr. sigma^2_cr is NOT in the
#     subject-level error but sigma^2_r IS (M9 spec §3a), so this gates AGREEMENT
#     only -- when it fails the design is really nested (Design 2), not crossed.
#
# These conditions are the spec's hypothesis, pinned against lme4/glmmTMB rank
# behaviour by the M9 identifiability oracle before the guards are trusted (#1/#18;
# spec §4b/§6). `df` has factor subject/rater/cluster, droplevels()-ed.
crossed_ml_identifiability <- function(df) {
  clusters <- levels(df$cluster)
  connected_within <- vapply(
    clusters,
    function(cl) {
      sub <- df[df$cluster == cl, , drop = FALSE]
      incidence <- table(droplevels(sub$subject), droplevels(sub$rater)) > 0L
      design_connected(incidence)
    },
    logical(1)
  )
  list(
    within_cluster_connected = all(connected_within),
    disconnected_clusters = clusters[!connected_within],
    cluster_rater_connected = design_connected(table(df$cluster, df$rater) > 0L)
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
