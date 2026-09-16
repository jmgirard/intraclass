#' Rater reliability example (Shrout & Fleiss, 1979)
#'
#' The six-target, four-judge worked example from Shrout and Fleiss (1979), in
#' the long, one-rating-per-row format that [icc()] consumes. Every subject is
#' rated by every rater, a complete, balanced two-way design where the subjects
#' share one set of raters. So it is the reference case on which `icc()`
#' returns the canonical coefficients `ICC(A,1)` = 0.290, `ICC(A,k)` = 0.620,
#' `ICC(C,1)` = 0.715, and `ICC(C,k)` = 0.909.
#'
#' @format A data frame with 24 rows and 3 columns:
#'
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
#' @seealso [ratings_incomplete] for a connected incomplete variant, one where
#'   raters and subjects form one linked web.
#' @examples
#' icc(ratings, score, subject, rater, seed = 2024)
"ratings"

#' Rater reliability example with missing cells
#'
#' An incomplete variant of [ratings]. Rater 2 served as a pilot and scored only
#' the first two subjects. So the four cells for subjects 3-6 by rater 2 are
#' absent (20 rows rather than 24). Missing cells are dropped rows, not `NA`s,
#' matching the long format [icc()] expects.
#'
#' @details
#' The design is deliberately **ragged**: subjects 1-2 have all four raters
#' while subjects 3-6 have three. The observed subject-by-rater graph still
#' remains a single **connected** component, because raters 1, 3, and 4 rate
#' every subject. So the two-way ICC stays identified and `icc()` does not abort
#' (see the connectedness requirement in `vignette("choosing-an-icc")`).
#'
#' Because the per-subject rating counts differ, the averaging divisor for
#' `ICC(*,k)` is not an integer. It is the effective number of ratings, the
#' harmonic mean of the per-subject rating counts, an average that leans toward
#' the smaller values. Here `k_eff` = 1 / mean(1 / n_i) = 3.273 over the counts
#' 4, 4, 3, 3, 3, 3. On the balanced [ratings], `raters = "fixed"` and
#' `raters = "random"` give the same point estimate. Here the two genuinely
#' differ. This dataset exists to demonstrate those incomplete-design behaviors
#' in the "Choosing an ICC" article.
#'
#' @format A data frame with 20 rows and 3 columns, as in [ratings]
#'   (`subject`, `rater`, `score`).
#'
#' @source Derived from [ratings]. See `data-raw/make-ratings.R`. Underlying
#'   values from Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations:
#'   Uses in assessing rater reliability. *Psychological Bulletin, 86*(2),
#'   420-428.
#'
#' @seealso [ratings] for the complete, balanced design.
#' @examples
#' summary(icc(ratings_incomplete, score, subject, rater, seed = 2024))
"ratings_incomplete"

#' Simulated multilevel ratings: pupils nested in classrooms
#'
#' Simulated data, not a real study. Sixteen classrooms hold five pupils each,
#' and the same four raters score every pupil. The classroom standard
#' deviation (1.3) is larger than the pupil one within a classroom (0.6), so the
#' cluster-level ICC comes out above the subject-level ICC. The "Multilevel
#' designs" article and the README use it.
#'
#' @format A data frame with 320 rows and 4 columns:
#'
#' \describe{
#'   \item{classroom}{Factor with 16 levels: the cluster.}
#'   \item{pupil}{Factor with 80 levels: the subject, labeled
#'     `classroom_pupil`.}
#'   \item{rater}{Factor with 4 levels: the rater.}
#'   \item{score}{Numeric rating.}
#' }
#'
#' @source Simulated by `data-raw/make-vignette-data.R` with `set.seed(2025)`.
#'   The score is 10 plus a classroom effect, a pupil effect, a rater effect,
#'   and noise (standard deviation 0.7), all normal draws.
#'
#' @seealso [school_incomplete] for the same design with a fifth of the
#'   ratings removed.
#' @examples
#' str(school)
#' \donttest{
#' icc(school, score, subject = pupil, rater = rater, cluster = classroom,
#'   type = "agreement", seed = 1)
#' }
"school"

#' Simulated multilevel ratings with missing cells
#'
#' Simulated data, not a real study. [school] with a fifth of its rows removed
#' at random, so 256 of the 320 ratings remain. Missing cells are dropped
#' rows, not `NA`s. Every rater still scores pupils in every classroom, so
#' both ICC levels stay identified. The "Multilevel designs" article uses it
#' to show a ragged multilevel design.
#'
#' @format A data frame with 256 rows and 4 columns, as in [school]
#'   (`classroom`, `pupil`, `rater`, `score`).
#'
#' @source Derived from [school] by `data-raw/make-vignette-data.R` with
#'   `set.seed(11)`, which picks the 64 rows to drop.
#'
#' @seealso [school] for the complete design.
#' @examples
#' str(school_incomplete)
"school_incomplete"

#' Simulated ratings with three ratings per subject-rater cell
#'
#' Simulated data, not a real study. Twenty subjects are each scored by the
#' same four raters, and each rater scores each subject three times. The
#' repeated ratings let `icc()` separate the subject-by-rater interaction
#' (standard deviation 0.6) from pure error (0.7). The "D-studies and
#' replicates" article
#' uses it.
#'
#' @format A data frame with 240 rows and 3 columns:
#'
#' \describe{
#'   \item{subject}{Factor with 20 levels: the target being rated.}
#'   \item{rater}{Factor with 4 levels: the rater.}
#'   \item{score}{Numeric rating. Each subject-rater pair appears three
#'     times.}
#' }
#'
#' @source Simulated by `data-raw/make-vignette-data.R` with `set.seed(2025)`.
#'   The score is 10 plus a subject effect, a rater effect, a subject-by-rater
#'   effect, and noise, with standard deviations 1.1, 0.8, 0.6, and 0.7.
#'
#' @seealso [ratings] for a design with one rating per cell.
#' @examples
#' str(ratings_replicates)
#' \donttest{
#' icc(ratings_replicates, score, subject, rater, type = "agreement",
#'   occasions = c("single", "average"), seed = 1)
#' }
"ratings_replicates"

#' Simulated balanced two-way ratings, twenty subjects by four raters
#'
#' Simulated data, not a real study. Twenty subjects are each scored once by
#' the same four raters. The variance components are 0.6 (subject), 0.1
#' (rater), and 0.2 (residual), so the population `ICC(A,1)` is 0.667. The
#' design is large enough for `ci_method = "mpl"`, which the six-subject
#' [ratings] data are not. The "Interval methods" article uses it.
#'
#' @format A data frame with 80 rows and 3 columns, as in [ratings]
#'   (`subject`, `rater`, `score`).
#'
#' @source Simulated by `data-raw/make-vignette-data.R` with `set.seed(88)`.
#'   The score is a subject effect plus a rater effect plus noise, all normal
#'   draws with the variances above.
#'
#' @seealso [ratings] for the Shrout and Fleiss worked example.
#' @examples
#' str(ratings_twoway)
#' \donttest{
#' icc(ratings_twoway, score, subject, rater, type = "agreement",
#'   ci_method = "mpl")
#' }
"ratings_twoway"
