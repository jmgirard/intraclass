# print surfaces the incomplete multilevel design and effective k

    Code
      print(x)
    Message
      # Intraclass correlation: multilevel two-way random, absolute agreement
      Subjects: 30 in 6 clusters | Raters: 4 (random) | Observations: 102 (incomplete)
      Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
        level    index     estimate   95% CI
        subject  ICC(A,1)    0.465   [0.197, 0.673]
        subject  ICC(A,k)    0.738   [0.443, 0.870]
      ICC(*,k) projects to an effective 3.24 raters (harmonic mean of ratings/subject).
      Variance components: cluster 0.419, subject 0.956, rater 0.374, cluster:rater 0.100, residual 0.727

