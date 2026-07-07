#' Rater reliability example (Shrout & Fleiss, 1979)
#'
#' The six-target, four-judge worked example from Shrout and Fleiss (1979), in
#' the long, one-rating-per-row format that [icc()] consumes. Every subject is
#' rated by every rater (a complete, balanced two-way design), so it is the
#' reference case on which `icc()` returns the canonical coefficients
#' `ICC(A,1)` = 0.290, `ICC(A,k)` = 0.620, `ICC(C,1)` = 0.715, and
#' `ICC(C,k)` = 0.909.
#'
#' @format A data frame with 24 rows and 3 columns:
#' \describe{
#'   \item{subject}{Factor with 6 levels: the target being rated (the object of
#'     measurement).}
#'   \item{rater}{Factor with 4 levels: the judge providing the rating.}
#'   \item{score}{Numeric rating.}
#' }
#'
#' @source Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: Uses
#'   in assessing rater reliability. *Psychological Bulletin, 86*(2), 420-428.
#'   The example in their Table 2.
#'
#' @seealso [ratings_incomplete] for a connected incomplete variant.
#' @examples
#' icc(ratings, score, subject, rater, seed = 2024)
"ratings"

#' Rater reliability example with missing cells
#'
#' An incomplete variant of [ratings]: rater 2 served as a pilot and scored only
#' the first two subjects, so the four cells for subjects 3-6 by rater 2 are
#' absent (20 rows rather than 24). Missing cells are dropped rows, not `NA`s,
#' matching the long format [icc()] expects.
#'
#' @details
#' The design is deliberately **ragged** -- subjects 1-2 have all four raters
#' while subjects 3-6 have three -- yet the observed subject-by-rater graph
#' remains a single **connected** component (raters 1, 3, and 4 rate every
#' subject), so the two-way ICC stays identified and `icc()` does not abort
#' (see the connectedness requirement in `vignette("choosing-an-icc")`).
#'
#' Because the per-subject rating counts differ, the averaging divisor for
#' `ICC(*,k)` is the effective number of ratings `k_eff` = 1 / mean(1 / n_i) =
#' 3.273 (the harmonic mean of the counts 4, 4, 3, 3, 3, 3), not an integer.
#' And unlike the balanced [ratings] -- where `raters = "fixed"` and
#' `raters = "random"` give the same point estimate -- here the two genuinely
#' differ. This dataset exists to demonstrate those incomplete-design behaviors
#' in the "Choosing an ICC" article.
#'
#' @format A data frame with 20 rows and 3 columns, as in [ratings]
#'   (`subject`, `rater`, `score`).
#'
#' @source Derived from [ratings]; see `data-raw/make-ratings.R`. Underlying
#'   values from Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations:
#'   Uses in assessing rater reliability. *Psychological Bulletin, 86*(2),
#'   420-428.
#'
#' @seealso [ratings] for the complete, balanced design.
#' @examples
#' summary(icc(ratings_incomplete, score, subject, rater, seed = 2024))
"ratings_incomplete"
