# helper-shrout-fleiss.R
# ===========================================================================
# Shared fixture: the Shrout & Fleiss (1979) worked example, plus the
# published intraclass-correlation values it is famous for. This is the
# PRIMARY EXTERNAL ORACLE for the two-way ICC estimators (Milestone 1) and,
# via `sf_oracle_all`, the seed oracle for the wider ICC family in later
# milestones.
#
# PROVENANCE  (required by PRINCIPLES.md #4 — no unsourced reference values)
# ---------------------------------------------------------------------------
#   Source of data + coefficients:
#     Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in
#     assessing rater reliability. Psychological Bulletin, 86(2), 420-428.
#
#   The identical data matrix and coefficients are reproduced, to the printed
#   precision, by two independent implementations we cross-check against:
#       psych::ICC()      (Revelle)
#       DescTools::ICC()  (Signorell et al.)
#   Both print, for this matrix (n = 6 subjects, k = 4 raters):
#       type                     label   value   Shrout-Fleiss form
#       Single_raters_absolute   ICC1    0.166   one-way random, single
#       Single_random_raters     ICC2    0.290   two-way random, ABS, single
#       Single_fixed_raters      ICC3    0.715   two-way, consistency, single
#       Average_raters_absolute  ICC1k   0.443   one-way random, average
#       Average_random_raters    ICC2k   0.620   two-way random, ABS, average
#       Average_fixed_raters     ICC3k   0.909   two-way, consistency, average
#
# NOTATION BRIDGE
# ---------------------------------------------------------------------------
#   McGraw & Wong (1996) ICC(A,1) / ICC(A,k) for a two-way RANDOM design are
#   algebraically the Shrout & Fleiss ICC(2,1) / ICC(2,k). This package reports
#   the McGraw-Wong ICC(A,1)/ICC(A,k) labels; the published oracle is
#   ICC2/ICC2k.
#
# WHY THIS DATASET IS A GOOD ORACLE FOR A MIXED-MODEL ENGINE
# ---------------------------------------------------------------------------
#   The data are BALANCED and complete. For balanced data the REML variance
#   components equal the ANOVA/method-of-moments components, so `intraclass`'s
#   mixed-model estimates should match the classical published values to well
#   within rounding. A material disagreement on this dataset is a red flag,
#   not a tolerance to be loosened.
# ===========================================================================

# --- The data (integer ratings: 6 subjects x 4 raters) ---------------------
sf_ratings_wide <- function() {
  matrix(
    c(
      9, 2, 5, 8,
      6, 1, 3, 2,
      8, 4, 6, 8,
      7, 1, 2, 6,
      10, 5, 6, 9,
      6, 2, 4, 7
    ),
    ncol = 4, byrow = TRUE,
    dimnames = list(paste0("S", 1:6), paste0("J", 1:4))
  )
}

# Long format is what the mixed-model engine consumes: one rating per row.
sf_ratings_long <- function() {
  w <- sf_ratings_wide()
  data.frame(
    subject = factor(rep(rownames(w), times = ncol(w))),
    rater   = factor(rep(colnames(w), each  = nrow(w))),
    score   = as.numeric(w),
    stringsAsFactors = FALSE
  )
}

# --- Published oracle values -----------------------------------------------
# Milestone 1 targets (two-way random, ABSOLUTE agreement). Values are the
# published Shrout & Fleiss numbers to three decimals.
sf_oracle <- list(
  "ICC(A,1)" = 0.290,   # Shrout-Fleiss ICC(2,1)
  "ICC(A,k)" = 0.620    # Shrout-Fleiss ICC(2,k)
)

# Full six-form reference table, for later milestones to grow into. Keeping
# the whole family's oracle in one sourced place avoids re-deriving it later.
sf_oracle_all <- list(
  "ICC(1)"   = 0.166,   # one-way random, single            (SF ICC1)
  "ICC(A,1)" = 0.290,   # two-way random, absolute, single  (SF ICC2)
  "ICC(C,1)" = 0.715,   # two-way, consistency, single      (SF ICC3)
  "ICC(k)"   = 0.443,   # one-way random, average           (SF ICC1k)
  "ICC(A,k)" = 0.620,   # two-way random, absolute, average (SF ICC2k)
  "ICC(C,k)" = 0.909    # two-way, consistency, average     (SF ICC3k)
)

# A THIRD, more independent oracle to add in a later milestone: hand-compute
# the coefficients from the ANOVA mean squares (MS_subject, MS_rater, MS_error)
# using the McGraw & Wong (1996) formulae, rather than trusting another R
# package. Do not hardcode those mean squares until they are computed and
# checked in R; leave this as a documented TODO rather than an unsourced value.

# --- PROVISIONAL API ADAPTER ------------------------------------------------
# The public API is designed during Milestone 1. Until it settles, THIS is the
# single place that binds the tests to the estimator's return shape. If M1
# chooses different names/accessors, edit ONLY this function — never adjust the
# oracle values above to make code pass (PRINCIPLES.md #1, tdd-workflow rule:
# fix the implementation, not the test).
#
# Expected contract: generics::tidy(fit) returns a tibble with at least the
# columns `index` (chr, e.g. "ICC(A,1)") and `estimate` (dbl).
icc_estimate <- function(fit, index) {
  td  <- generics::tidy(fit)
  val <- td$estimate[td$index == index]
  if (length(val) != 1L) {
    stop(sprintf("Expected exactly one row for index '%s'; got %d.",
                 index, length(val)))
  }
  val
}
