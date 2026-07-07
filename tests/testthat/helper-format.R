# Snapshot helper: mask the Monte-Carlo confidence interval in printed output.
#
# The point estimates and variance components are deterministic, but the MC-CI
# digits vary at the ~1e-3 level across platforms/LAPACK builds even with a fixed
# seed (eigen-decomposition sign ambiguity). Snapshotting them verbatim is flaky,
# so we mask the bracketed interval and let the dedicated CI tests (bracketing,
# coverage, same-platform reproducibility) carry the numeric checks.
mask_ci <- function(lines) {
  gsub("\\[[0-9.]+, [0-9.]+\\]", "[CI]", lines)
}
