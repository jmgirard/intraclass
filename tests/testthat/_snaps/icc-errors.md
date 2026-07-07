# error messages are stable and actionable

    Code
      icc(d, score, subject, rater, model = "nested")
    Condition
      Error in `icc()`:
      ! `model` must be one of "twoway" and "oneway".

---

    Code
      icc(d[d$rater == "J1", ], score, subject, rater)
    Condition
      Error in `icc()`:
      ! A two-way ICC needs at least 2 raters to separate the rater variance.
      i `rater` has 1 level.

