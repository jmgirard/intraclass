# make-ratings.R --- build the `ratings` and `ratings_incomplete` teaching
# datasets (M4, ADR-009). Deterministic: a fixed missing-cell pattern, no RNG,
# so re-running reproduces the shipped objects exactly (PRINCIPLES.md #12).
#
# Source: Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: Uses
# in assessing rater reliability. Psychological Bulletin, 86(2), 420-428. The
# six-target, four-judge worked example (their Table 2). This is the same
# example used throughout the package; on it `icc()` returns the canonical
# ICC(A,1)=0.290, ICC(A,k)=0.620, ICC(C,1)=0.715, ICC(C,k)=0.909.

# --- `ratings`: the complete, balanced 6x4 design ---------------------------
# The published table, rows = subjects, columns = raters, then reshaped to the
# long, one-rating-per-row format `icc()` consumes. `subject` and `rater` are
# factors, `score` numeric.
# Each row is one subject; the four columns are raters 1-4.
wide <- rbind(
  c(9, 2, 5, 8),
  c(6, 1, 3, 2),
  c(8, 4, 6, 8),
  c(7, 1, 2, 6),
  c(10, 5, 6, 9),
  c(6, 2, 4, 7)
)
ratings <- data.frame(
  subject = factor(as.vector(row(wide))),
  rater = factor(as.vector(col(wide))),
  score = as.vector(wide)
)

# --- `ratings_incomplete`: a connected incomplete variant -------------------
# Narrative: rater 2 served as a pilot and scored only the first two subjects,
# so cells (subject 3-6, rater 2) are missing. Incomplete cells are simply
# absent rows (not NA), matching the long format. The result is deliberately
# ragged (subjects 1-2 have all four raters; subjects 3-6 have three) yet the
# observed subject x rater graph stays a single connected component -- raters
# 1, 3, and 4 rate every subject -- so the two-way ICC remains identified
# (ADR-008). This makes the averaging divisor `k_eff` a genuine harmonic mean
# (= 3.273, not an integer) and lets `raters = "fixed"` differ from `"random"`,
# which are identical on the balanced `ratings`.
missing_cells <- with(
  ratings,
  rater == "2" & subject %in% c("3", "4", "5", "6")
)
ratings_incomplete <- droplevels(ratings[!missing_cells, ])
row.names(ratings_incomplete) <- NULL

usethis::use_data(ratings, ratings_incomplete, overwrite = TRUE)
