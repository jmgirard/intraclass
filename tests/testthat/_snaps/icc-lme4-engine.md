# lme4 print() output is stable

    Code
      print(fit)
    Message
      -- Intraclass correlation: two-way random, absolute agreement & consistency ----
      Subjects: 6 | Raters: 4 (random) | Observations: 24 of 24 cells (complete)
      Engine: lme4 (REML) | CI: 95% montecarlo (10000 draws)
      
        index     estimate   95% CI
        Absolute agreement
        ICC(A,1)     0.290   [CI]
        ICC(A,k)     0.620   [CI]
        Consistency
        ICC(C,1)     0.715   [CI]
        ICC(C,k)     0.909   [CI]
      
      Variance components: subject 2.556, rater 5.244, residual 1.019
      Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)

