# print surfaces incomplete design and the effective k

    Code
      print(fit)
    Message
      # Intraclass correlation: two-way random, absolute agreement
      Subjects: 6 | Raters: 4 (random) | Observations: 22 of 24 cells (incomplete)
      Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
        index     estimate   95% CI
        ICC(A,1)    0.300   [CI]
        ICC(A,k)    0.606   [CI]
      ICC(*,k) projects to an effective 3.60 raters (harmonic mean of ratings/subject).
      Variance components: subject 2.671, rater 5.181, residual 1.067
      Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)

# incomplete-design error messages are stable

    Code
      icc(disconnected_design(), score, subject, rater)
    Condition
      Error in `icc()`:
      ! The subject-by-rater design is disconnected, so the subject and rater variances cannot be separated.
      i Every subject and rater must be linked through shared ratings (one connected design).
      i For unlinked rater groups, a one-way ICC (`model = "oneway"`) or additional linking ratings are needed.

