# the interactive walkthrough renders a styled tree with a breadcrumb

    Code
      invisible(collect_answers_interactively(list(model = NULL, type = NULL, unit = NULL,
        raters = NULL, multilevel = NULL, level = NULL)))
    Message
      -- Choosing an ICC -------------------------------------------------------------
      > Are the raters crossed, or interchangeable across subjects?
      1. Crossed -- the same raters judge every subject (two-way)
      2. Interchangeable -- a different set per subject (one-way)
      So far: Model = twoway
      > Does the actual value need to match, or only the rank order?
      1. Absolute agreement -- the value itself must match
      2. Consistency -- only the rank order must match
      So far: Model = twoway > Type = agreement
      > Will you act on one rater's score, the mean of several, or both?
      1. A single rater's score
      2. The average of your raters
      3. Both
      So far: Model = twoway > Type = agreement > Unit = average
      > Are your raters a sample you generalize beyond, or the only raters of
      interest?
      1. Random -- a sample; generalize to the rater universe
      2. Fixed -- exactly these raters, no generalization
      So far: Model = twoway > Type = agreement > Unit = average > Raters = random
      > Are subjects nested in higher-level clusters (e.g. pupils in classrooms)?
      1. No
      2. Yes -- subjects are nested in clusters

# the recommendation prints with a rule header and sections

    Code
      print(rec)
    Message
      -- Recommended ICC -------------------------------------------------------------
      Design: multilevel, two-way random, absolute agreement
      
      Recommendation:
        subject: ICC(A,1), ICC(A,k)
        cluster: ICC(A,1), ICC(A,k)
      
      Why:
        - Crossed (two-way): the same raters judge every subject.
        - Absolute agreement: the value itself must match; a systematic difference between raters counts as error.
        - Single and average: report the single-rater and averaged reliability side by side.
        - Random raters: a sample you generalize beyond, to the rater universe they were drawn from.
        - Both levels: within-cluster (subject) and between-cluster (cluster) reliability side by side.
      
      Run this on your data:
        icc(data, score, subject, rater, cluster, type = "agreement")
      
      Notes:
        - Complete vs. incomplete is automatic: icc() uses whatever ratings are present and projects ICC(*,k) to the effective number of ratings (k_eff). The design must stay connected, or icc() fails loudly.
        - See vignette("multilevel-designs") for a worked multilevel example.

