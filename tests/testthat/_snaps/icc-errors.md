# error messages are stable and actionable

    Code
      icc(d, score, subject, rater, model = "oneway")
    Condition
      Error in `icc()`:
      ! `model` must be "twoway" in this release.
      i Support for designs beyond two-way is planned for a later milestone.
      x You supplied "oneway".

---

    Code
      icc(d[d$rater == "J1", ], score, subject, rater)
    Condition
      Error in `icc()`:
      ! A two-way ICC needs at least 2 raters to separate the rater variance.
      i `rater` has 1 level.

