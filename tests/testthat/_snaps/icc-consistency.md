# consistency print output is stable

    Code
      print(fit)
    Message
      -- Intraclass correlation: two-way mixed, consistency --------------------------
      Subjects: 6 | Raters: 4 (fixed) | Observations: 24 of 24 cells (complete)
      Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
      
        index     estimate   95% CI
        ICC(C,1)     0.715   [CI]
        ICC(C,k)     0.909   [CI]
      
      Variance components: subject 2.556, rater 5.244, residual 1.019
      Shrout & Fleiss equivalent: ICC(C,1) = ICC(3,1), ICC(C,k) = ICC(3,k)

