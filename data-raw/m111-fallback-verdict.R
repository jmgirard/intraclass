# M111 T5 — apply the frozen F1–F5 rules to the sweep fixture.
#
# Reads data-raw/m111-fallback-results.rds and evaluates each binding rule of
# cairn/references/fallback-on-abort-comparison.md (frozen 2026-08-08, before
# the run) per cell x arm. Mechanical application only: the thresholds are the
# page's, and the durable verdict (F6) is recorded in DECISIONS.md, not here.
#
#   Rscript data-raw/m111-fallback-verdict.R

res <- readRDS("data-raw/m111-fallback-results.rds")
agg <- res$summary
wide <- res$wide

# F1 — interval always: no classical leg ever failed to produce a finite
# interval. Asserted on the raw per-leg abort indicator (a failed leg records
# aborted=TRUE on its own row), NOT on comp_*_covered, which is FALSE — never
# NA — for a failed leg and so cannot carry this evidence (M111 review D3).
n_leg_aborts <- sum(res$raw$aborted[res$raw$method != "mc"])
stopifnot(n_leg_aborts == 0L)
f1_pass <- TRUE

# F3 helper — one-sided 95% upper Clopper-Pearson bound for a proportion.
cp_upper <- function(x, n) {
  if (x >= n) 1 else stats::qbeta(0.95, x + 1, n - x)
}

rules <- do.call(
  rbind,
  lapply(split(agg, agg$cell), function(g) {
    n_ab <- g$n_abort
    out <- lapply(c("searle", "burch"), function(arm) {
      cov_u <- g[[paste0("comp_", arm, "_coverage")]]
      lo <- g[[paste0("comp_", arm, "_lo_miss")]]
      hi <- g[[paste0("comp_", arm, "_hi_miss")]]
      cond_cov <- g[[paste0("cond_", arm, "_coverage")]]
      ab <- wide[wide$cell == g$cell & wide$mc_aborted, ]
      cond_lo <- if (nrow(ab)) mean(ab[[paste0(arm, "_lo_miss")]]) else NA_real_
      cond_hi <- if (nrow(ab)) mean(ab[[paste0(arm, "_hi_miss")]]) else NA_real_
      f3_applicable <- n_ab >= 100
      f3_ucb <- if (f3_applicable) {
        cp_upper(round(cond_cov * n_ab), n_ab)
      } else {
        NA_real_
      }
      data.frame(
        cell = g$cell,
        rho = g$rho,
        k = g$k,
        n = g$n,
        dist = g$dist,
        arm = arm,
        n_abort = n_ab,
        coverage = cov_u,
        f2_pass = cov_u >= 0.93,
        f2_near_miss = cov_u >= 0.93 & cov_u < 0.935,
        cond_coverage = cond_cov,
        cond_lo_miss = cond_lo,
        cond_hi_miss = cond_hi,
        f3_applicable = f3_applicable,
        f3_ucb = f3_ucb,
        f3_pass = !f3_applicable | (f3_ucb >= 0.93),
        lo_miss = lo,
        hi_miss = hi,
        f5_pass = lo <= 0.045 & hi <= 0.045 & abs(lo - hi) <= 0.03,
        stringsAsFactors = FALSE
      )
    })
    do.call(rbind, out)
  })
)
rownames(rules) <- NULL

cat(
  "== F1 (interval always):",
  if (f1_pass) "PASS (0 aborted classical-leg rows)" else "FAIL",
  "\n\n"
)

for (arm in c("searle", "burch")) {
  r <- rules[rules$arm == arm, ]
  cat(sprintf(
    "== arm %-6s  F2 fails: %d/64   F3 fails: %d (of %d applicable)   F5 fails: %d/64\n",
    arm,
    sum(!r$f2_pass),
    sum(!r$f3_pass),
    sum(r$f3_applicable),
    sum(!r$f5_pass)
  ))
  bad <- r[!r$f2_pass | !r$f3_pass | !r$f5_pass, ]
  if (nrow(bad)) {
    print(
      bad[, c(
        "rho",
        "k",
        "n",
        "dist",
        "n_abort",
        "coverage",
        "cond_coverage",
        "f3_ucb",
        "lo_miss",
        "hi_miss",
        "f2_pass",
        "f3_pass",
        "f5_pass"
      )],
      row.names = FALSE
    )
  }
  cat(sprintf(
    "   near-misses (binding stat within 0.005 of threshold): %d\n\n",
    sum(r$f2_near_miss)
  ))
}

cat("== abort landscape (cells with n_abort >= 100):\n")
ab <- unique(rules[
  rules$n_abort >= 100,
  c(
    "rho",
    "k",
    "n",
    "dist",
    "n_abort"
  )
])
print(ab[order(-ab$n_abort), ], row.names = FALSE)

cat("\n== conditional-on-abort coverage + tails at applicable cells:\n")
cc <- rules[
  rules$f3_applicable,
  c(
    "rho",
    "k",
    "n",
    "dist",
    "arm",
    "n_abort",
    "cond_coverage",
    "cond_lo_miss",
    "cond_hi_miss",
    "f3_ucb",
    "f3_pass"
  )
]
print(cc[order(cc$rho, cc$k, cc$n, cc$dist, cc$arm), ], row.names = FALSE)

cat(
  "\n== tie-break inputs (median fallback width among abort reps, summed over >=100-abort cells):\n"
)
tb <- agg[agg$n_abort >= 100, ]
cat(sprintf(
  "   searle: %.4f   burch: %.4f\n",
  sum(tb$cond_searle_med_width),
  sum(tb$cond_burch_med_width)
))

saveRDS(rules, "data-raw/m111-fallback-rules.rds")
cat("\nrules table written to data-raw/m111-fallback-rules.rds\n")
