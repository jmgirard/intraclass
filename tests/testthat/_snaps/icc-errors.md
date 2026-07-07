# error messages are stable and actionable

    Code
      icc(d, score, subject, rater, type = "consistency")
    Condition
      Error in `icc()`:
      ! `type` must be "agreement" in this release.
      i Support for consistency ICCs is planned for a later milestone.
      x You supplied "consistency".

---

    Code
      icc(d[d$rater == "J1", ], score, subject, rater)
    Condition
      Error in `icc()`:
      ! A two-way ICC needs at least 2 raters to separate the rater variance.
      i `rater` has 1 level.

