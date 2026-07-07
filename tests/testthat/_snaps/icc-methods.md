# summary() prints the report plus interpretive notes

    Code
      summary(fit)
    Message
      # Intraclass correlation: two-way random, absolute agreement
      Subjects: 6 | Raters: 4 (random) | Observations: 24 of 24 cells (complete)
      Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
        index     estimate   95% CI
        ICC(A,1)    0.290   [CI]
        ICC(A,k)    0.620   [CI]
      Variance components: subject 2.556, rater 5.244, residual 1.019
      Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)
      Absolute agreement counts the rater main effect (systematic differences in rater level) as error.
      A single rating per cell confounds the subject-by-rater interaction with
      residual error.

