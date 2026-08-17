# Doctrine: pinning documentation claims

This page owns the craft of **doc-claim pins** — tests that make a withdrawn or
bounded documentation claim red if it returns to a shipped surface. It is a
doctrine module graduated from `cairn/LESSONS.md` (the M115 family, extended at
M116, M118, and M123) under the maturation exit; the underlying measurements
live in those milestones' files (`cairn/milestones/archive/`, cross-references
only — this page owns none of their status or history).

## Searching for a claim

- A **line-based search cannot see a claim that wraps.** `git grep -c "never
  under-cover"` returned 0 and `grepl(..., fixed = TRUE)` over a flattened Rd
  returned FALSE against a sentence plainly present as `never\n#'
  under-covering`; a site survived a whole implementation pass on that false
  negative. Search **whitespace-collapsed** text.
- A join-time `squash()` that strips `#`/`#'` does **not** strip a markdown
  blockquote `>` — a claim inside a `> [!NOTE]` callout joins with the marker
  mid-sentence and every `fixed = TRUE` pattern returns FALSE against the real
  shipped sentence. Strip `^\s*>+\s?` per line **before** the join, and put a
  blockquote form in the mutation matrix, or the pin is untested exactly where
  it matters (M123).
- `rd_flat()`-style flattening (`rapply(as.character)` over parsed Rd) discards
  `\code{}` markup — the flattened help database carried 0 backticks against
  846 in `R/icc.R` — so a backticked-only pattern is **inert on `Rd:*`**. Pin a
  backtick-free spelling per claim (M123).

## Pinning attribution, not membership

- Pinning figures by **membership in a fixture's value pool does not pin
  attribution.** Assert against the specific row the fixture computes as worst,
  match numerals on numeric boundaries (`(?<![0-9.])0.6(?![0-9])` — a bare
  `0.6` matches inside `0.6725`, `5` inside `0.95`/`50`), and check the
  label/distribution name too (M115).

## Reading the installed surface, not the source

- A test reading **source paths** (`R/*.R`, `data-raw/*`) skips under `R CMD
  check` — `.Rbuildignore` excludes `data-raw`; the tarball has no `R/`
  sources. Read the installed package: `tools::Rd_db()` (falling back to
  `tools::parse_Rd("man/*.Rd")` under `load_all`, where `Rd_db()` errors),
  `system.file("doc", "<vig>.Rmd")`, `system.file("NEWS.md")` (M115).
- Installing with `build_vignettes = TRUE` is **not enough** —
  `testthat::test_local()`/`load_all` resolve `system.file("doc", ...)` to the
  SOURCE tree, so installed-surface legs still skip silently. Run
  `testthat::test_dir("tests/testthat", package = "<pkg>", load_package =
  "installed")` and confirm 0 skips there (M116).
- `pkgload`'s `system.file()` falls back to the package **root**, so an
  installed-leg block gated on `system.file("README.md")` does not skip under
  `load_all` — it re-reads the source file the source leg already swept and
  reports coverage it does not have. Only `test_dir(load_package =
  "installed")` and a harness resolving the library path in a **subprocess**
  exercise the installed copy (M123).
- `<pkg>.Rcheck` carries neither `R/` nor `vignettes/`, so a floor whose
  expected file list is derived from a **source glob** goes vacuous in the one
  layout CI runs — while reading as a widening. Derive such a floor from the
  installed side or hard-code it (M123).

## Loop and vacuity mechanics

- `skip_if()` inside a `for` loop aborts the **whole** `test_that`, not the
  iteration — a per-file loop guarded that way drops every file after the first
  missing one. Resolve all paths first, skip only when none is present, and add
  an anti-vacuity assertion, since every `expect_false(grepl(...))` passes on
  an empty string (M116).

## Guarding source vs guarding the shipped artifact

- A guard asserting a property of **another script's code** must walk the
  parsed body — a lexical search for `rt(` matches inside `sqrt(`, and a
  positional rule is defeated by hoisting the call one line up (M116).
- Walking the parsed body is necessary and **still not sufficient**: an AST
  fence over a sweep's generator was defeated in four successive review rounds,
  each by a new spelling of one edit (`dist <- "gaussian"` first in the body; a
  `rho`-gated local shadow of the draw helper; `dist[1] <- "gaussian"`, whose
  LHS is not a bare symbol; `assign("dist", "gaussian")`). Every repair widened
  a recall-fixed list of forms and the next round beat the wider list. The
  escape is to stop guarding the source: a check over the **shipped artifact**
  (e.g. pairwise family distinctness within every parameter group of the
  committed table) cannot be hidden from by an edit conditioned on the cell
  parameters. Where a source guard is kept, promise nothing of it — state each
  check's domain, and never let a criterion quantify over edits no named
  procedure runs (M118).

## Always

- **Mutation-verify every pin**: reintroduce the exact defect and require red
  (M115), with a blockquote form included in the mutation matrix (M123 — its
  committed matrix covered 2 markup regimes × 4 wrap forms).
