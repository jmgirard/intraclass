# multilevel lavaan print output is stable

    Code
      print(x)
    Message
      -- Intraclass correlation: multilevel two-way random, absolute agreement & consi
      Subjects: 400 in 40 clusters | Raters: 5 (random) | Observations: 2000 (complete)
      Engine: lavaan (ML) | CI: 95% montecarlo (10000 draws)
      
        level      index     estimate   95% CI
        Absolute agreement
        subject    ICC(A,1)     0.612   [CI]
        subject    ICC(A,k)     0.888   [CI]
        cluster    ICC(A,1)     0.526   [CI]
        cluster    ICC(A,k)     0.847   [CI]
        Consistency
        subject    ICC(C,1)     0.676   [CI]
        subject    ICC(C,k)     0.912   [CI]
        cluster    ICC(C,1)     0.664   [CI]
        cluster    ICC(C,k)     0.908   [CI]
      
      Variance components: cluster 0.405, subject 1.036, rater 0.160, cluster:rater 0.205, residual 0.497

