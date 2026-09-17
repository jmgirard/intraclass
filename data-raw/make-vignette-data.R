# make-vignette-data.R --- build the four simulated teaching datasets the
# articles and the README use: `school`, `school_incomplete`,
# `ratings_replicates` and `ratings_twoway`. Every builder is seeded, so a
# re-run reproduces the shipped objects exactly (PRINCIPLES.md #4/#12).
#
# The four builders are the simulation chunks the articles carried until
# M154 (commit a400774), moved here without a change to the draw order:
#   school              <- vignettes/multilevel-designs.Rmd, chunk `ml-data`
#   school_incomplete   <- vignettes/multilevel-designs.Rmd, chunk `ml-incomplete-data`
#   ratings_replicates  <- vignettes/d-studies-and-replicates.Rmd, chunk `replicates-data`
#   ratings_twoway      <- vignettes/interval-methods.Rmd, chunk `ci-mpl`
# The values are simulated and stand for no real study.

# --- `school`: pupils nested in classrooms, one crossed rater panel --------
# 16 classrooms x 5 pupils x 4 raters = 320 rows, complete. Most of the true
# variation lives between classrooms (sd 1.3) rather than between pupils
# within a classroom (sd 0.6), so the cluster-level ICC exceeds the
# subject-level one.
set.seed(2025)
n_class <- 16
n_pupil <- 5
n_rater <- 4
grid <- expand.grid(
  pupil = seq_len(n_pupil),
  classroom = seq_len(n_class),
  rater = seq_len(n_rater)
)
class_effect <- rnorm(n_class, sd = 1.3)[grid$classroom]
pupil_effect <- rnorm(n_class * n_pupil, sd = 0.6)[
  (grid$classroom - 1) * n_pupil + grid$pupil
]
rater_effect <- rnorm(n_rater, sd = 0.4)[grid$rater]
school <- data.frame(
  classroom = factor(grid$classroom),
  # Explicit levels in build order: `factor()` alone would sort the labels
  # under the session's collation, so "10_1" lands before or after "1_1"
  # depending on the locale and the rebuild would not reproduce the file.
  pupil = factor(
    paste(grid$classroom, grid$pupil, sep = "_"),
    levels = unique(paste(grid$classroom, grid$pupil, sep = "_"))
  ),
  rater = factor(grid$rater),
  score = 10 +
    class_effect +
    pupil_effect +
    rater_effect +
    rnorm(nrow(grid), sd = 0.7)
)

# --- `school_incomplete`: a fifth of the `school` ratings dropped at random -
# 256 rows. Missing cells are absent rows, not NA. The crossed design stays
# connected, so both levels remain identified.
set.seed(11)
school_incomplete <- school[-sample(nrow(school), round(0.2 * nrow(school))), ]

# --- `ratings_replicates`: each rater rates each subject three times -------
# 20 subjects x 4 raters x 3 occasions = 240 rows. The subject-by-rater
# interaction (sd 0.6) and the pure error (sd 0.7) are separate draws, so
# `icc()` can split them.
set.seed(2025)
ns <- 20
nr <- 4
no <- 3
grid <- expand.grid(
  subject = seq_len(ns),
  rater = seq_len(nr),
  occ = seq_len(no)
)
subj <- rnorm(ns, sd = 1.1)[grid$subject]
rater <- rnorm(nr, sd = 0.8)[grid$rater]
sr <- rnorm(ns * nr, sd = 0.6)[(grid$rater - 1) * ns + grid$subject]
ratings_replicates <- data.frame(
  subject = factor(grid$subject),
  rater = factor(grid$rater),
  score = 10 + subj + rater + sr + rnorm(nrow(grid), sd = 0.7)
)

# --- `ratings_twoway`: a balanced two-way design large enough for "mpl" ----
# 20 subjects x 4 raters = 80 rows, complete. Variance components 0.6
# (subject), 0.1 (rater), 0.2 (residual), so the population ICC(A,1) is
# 0.6 / 0.9 = 0.667. The shipped `ratings` (six subjects) sit outside the
# "mpl" calibration grid; this design sits inside it.
set.seed(88)
n_s <- 20
n_r <- 4
subj_eff <- rnorm(n_s, sd = sqrt(0.6))
rater_eff <- rnorm(n_r, sd = sqrt(0.1))
noise <- matrix(rnorm(n_s * n_r, sd = sqrt(0.2)), n_s, n_r)
ratings_twoway <- data.frame(
  subject = factor(rep(seq_len(n_s), times = n_r)),
  rater = factor(rep(seq_len(n_r), each = n_s)),
  score = as.numeric(
    outer(subj_eff, rep(1, n_r)) +
      outer(rep(1, n_s), rater_eff) +
      noise
  )
)

usethis::use_data(
  school,
  school_incomplete,
  ratings_replicates,
  ratings_twoway,
  overwrite = TRUE
)
