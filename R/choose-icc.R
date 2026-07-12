# choose_icc(): the decision helper -------------------------------------------
#
# M12 (ADR-021): a teaching/API companion to the "Choosing an ICC" vignette. It
# turns that article's decision tree into code -- a prior crossed-vs-one-way
# `model` question, then agreement/consistency (`type`), single/average (`unit`),
# random/fixed (`raters`), and the multilevel subject/cluster fifth choice
# (`multilevel`/`level`) -- and returns a recommendation: the coefficient
# label(s), a per-axis rationale, and the exact `icc()` call to run. It does NOT
# fit (no `data` argument); the user copies the emitted call.
#
# There is no new estimand (PRINCIPLES.md #1 is numerically N/A). Correctness is
# established by two facts, both reusing the shared estimand layer so the helper
# cannot drift from `icc()`: (a) every recommended label comes from the same
# `icc_estimand()` that labels a fitted object; (b) the emitted call, run on data,
# reproduces a direct `icc()` call with those arguments (the round-trip oracle in
# the tests). Ill-posed / underspecified selections fail loudly (#5/#8).

#' Recommend an ICC and the call that computes it
#'
#' `choose_icc()` walks the decision tree of the *Choosing an ICC* vignette and
#' returns a recommendation object naming the coefficient(s) to report and the
#' exact [icc()] call that computes them. It does **not** fit a model: there is no
#' `data` argument. Copy the emitted call and run it on your data.
#'
#' Supply the decisions as arguments to get advice programmatically; call
#' `choose_icc()` with the relevant answers omitted in an interactive session to
#' be asked the outstanding questions one at a time.
#'
#' The two structural facts about your design -- whether the raters are crossed
#' (`model`) and whether subjects are nested in clusters (`multilevel`) -- default
#' to the common case (a crossed, non-multilevel two-way design), matching
#' [icc()]. The choices that actually select the coefficient (`type`, `unit`,
#' `raters`, and `level` when multilevel) have no silent default: in a
#' non-interactive session, leaving one unanswered is an error naming the
#' unanswered decision (rather than quietly picking one for you).
#'
#' @param model `"twoway"` (crossed: the same raters judge every subject) or
#'   `"oneway"` (raters are interchangeable across subjects). Defaults to
#'   `"twoway"`. Under `"oneway"` the `type` and `raters` choices do not exist
#'   (there is no rater term), and supplying them is an error.
#' @param type `"agreement"` (the value itself must match; systematic rater
#'   offsets count as error) or `"consistency"` (only rank order matters; a
#'   constant per-rater offset is forgiven). Required for a two-way design.
#' @param unit `"single"` (you will act on one rater's score), `"average"` (the
#'   mean of your raters), or `"both"`. Required.
#' @param raters `"random"` (a sample you generalize beyond -- the recommended
#'   default for interrater reliability) or `"fixed"` (exactly these judges, no
#'   generalization). Required for a two-way design.
#' @param multilevel `TRUE` if subjects are nested in higher-level clusters
#'   (pupils in classrooms, patients in clinics), else `FALSE` (the default).
#' @param level For a multilevel design, `"subject"` (within-cluster reliability),
#'   `"cluster"` (between-cluster reliability), or `"both"`. Required when
#'   `multilevel = TRUE`.
#'
#' @return An `icc_recommendation` object (a list) with a [print()] method. It
#'   carries the recommended coefficient rows (`$rows`), the exact `icc()` call as
#'   a string (`$call`), the per-decision rationale (`$rationale`), and any notes
#'   (`$notes`).
#'
#' @seealso [icc()], and `vignette("choosing-an-icc")` for the full decision tree.
#'
#' @examples
#' # Two-way absolute agreement, single rater, random raters (Shrout & Fleiss
#' # ICC(2,1)): the two structural defaults (crossed, non-multilevel) are implied.
#' choose_icc(type = "agreement", unit = "single", raters = "random")
#'
#' # Consistency of the average of fixed raters -- McGraw & Wong ICC(C,k):
#' choose_icc(type = "consistency", unit = "average", raters = "fixed")
#'
#' # A one-way design (interchangeable raters): type/raters do not apply.
#' choose_icc(model = "oneway", unit = "single")
#'
#' # A multilevel design, both levels:
#' choose_icc(type = "agreement", unit = "single", raters = "random",
#'   multilevel = TRUE, level = "both")
#' @export
choose_icc <- function(
  model = NULL,
  type = NULL,
  unit = NULL,
  raters = NULL,
  multilevel = NULL,
  level = NULL
) {
  answers <- list(
    model = model,
    type = type,
    unit = unit,
    raters = raters,
    multilevel = multilevel,
    level = level
  )
  # If a coefficient-selecting decision is unanswered and the session is
  # interactive, walk the outstanding questions before resolving; otherwise
  # resolve the supplied answers directly (a missing one then aborts loudly).
  if (rlang::is_interactive() && required_missing(answers)) {
    answers <- collect_answers_interactively(answers)
  }
  resolve_icc_recommendation(answers)
}

# Is a coefficient-selecting decision still unanswered? The two structural axes
# default to the common case (crossed, non-multilevel), so a call that supplies
# only the coefficient axes is complete and skips the interactive walkthrough
# (matching the programmatic path); the walkthrough is entered only when a
# genuine coefficient decision is missing.
required_missing <- function(answers) {
  oneway <- identical(answers$model, "oneway")
  if (oneway) {
    return(is.null(answers$unit))
  }
  multilevel <- isTRUE(answers$multilevel)
  is.null(answers$unit) ||
    is.null(answers$type) ||
    is.null(answers$raters) ||
    (multilevel && is.null(answers$level))
}

# Ask the outstanding decisions one at a time, in the vignette's order, asking
# only those that apply given the answers gathered so far. `ask` is injected so
# tests drive the walkthrough without live console input (no `readline` in CI).
#
# M43/ADR-053: the walkthrough opens with a rule and shows a running breadcrumb of
# the choices made so far before each question, so it reads as a guided decision
# tree. This is presentation only -- the answer set built and returned, the axis
# order, and the injectable `ask` seam are all unchanged (ADR-021).
collect_answers_interactively <- function(answers, ask = ask_choice) {
  cli::cli_rule(left = cli::style_bold("Choosing an ICC"))
  # A stepping wrapper: render the path so far (muted), then ask via the seam.
  step <- function(arg, question, choices, labels) {
    choose_icc_breadcrumb(answers)
    ask(arg, question, choices, labels)
  }
  if (is.null(answers$model)) {
    answers$model <- step(
      "model",
      "Are the raters crossed, or interchangeable across subjects?",
      c("twoway", "oneway"),
      c(
        "Crossed -- the same raters judge every subject (two-way)",
        "Interchangeable -- a different set per subject (one-way)"
      )
    )
  }
  oneway <- identical(answers$model, "oneway")
  if (!oneway && is.null(answers$type)) {
    answers$type <- step(
      "type",
      "Does the actual value need to match, or only the rank order?",
      c("agreement", "consistency"),
      c(
        "Absolute agreement -- the value itself must match",
        "Consistency -- only the rank order must match"
      )
    )
  }
  if (is.null(answers$unit)) {
    answers$unit <- step(
      "unit",
      "Will you act on one rater's score, the mean of several, or both?",
      c("single", "average", "both"),
      c(
        "A single rater's score",
        "The average of your raters",
        "Both"
      )
    )
  }
  if (!oneway && is.null(answers$raters)) {
    answers$raters <- step(
      "raters",
      "Are your raters a sample you generalize beyond, or the only raters of interest?",
      c("random", "fixed"),
      c(
        "Random -- a sample; generalize to the rater universe",
        "Fixed -- exactly these raters, no generalization"
      )
    )
  }
  if (!oneway && is.null(answers$multilevel)) {
    answers$multilevel <- step(
      "multilevel",
      "Are subjects nested in higher-level clusters (e.g. pupils in classrooms)?",
      c(FALSE, TRUE),
      c("No", "Yes -- subjects are nested in clusters")
    )
  }
  if (isTRUE(answers$multilevel) && is.null(answers$level)) {
    answers$level <- step(
      "level",
      "Which reliability: within-cluster, between-cluster, or both?",
      c("subject", "cluster", "both"),
      c(
        "Subject level -- rating a subject within its cluster",
        "Cluster level -- the cluster mean",
        "Both"
      )
    )
  }
  answers
}

# The running "decision path" line shown before each outstanding question: the
# axes answered so far, in the tree's order, muted. Nothing is shown before the
# first choice. Presentation only (M43).
choose_icc_breadcrumb <- function(answers) {
  labs <- c(
    model = "Model",
    type = "Type",
    unit = "Unit",
    raters = "Raters",
    multilevel = "Multilevel",
    level = "Level"
  )
  chosen <- answers[names(labs)]
  keep <- !vapply(chosen, is.null, logical(1))
  if (!any(keep)) {
    return(invisible(NULL))
  }
  vals <- vapply(chosen[keep], choose_icc_choice_label, character(1))
  crumb <- paste(
    sprintf("%s = %s", labs[names(chosen)[keep]], vals),
    collapse = " > "
  )
  cli::cli_text(cli::col_grey(paste0("So far: ", crumb)))
  invisible(NULL)
}

# Render a chosen axis value for the breadcrumb (logical multilevel -> yes/no).
choose_icc_choice_label <- function(v) {
  if (is.logical(v)) {
    if (isTRUE(v)) "yes" else "no"
  } else {
    as.character(v)
  }
}

# Pose one multiple-choice question via cli and return the chosen value. All
# prompt text goes through cli (#8); the numeric selection is read through
# `prompt_line()` (an injection seam so the read loop is testable without a live
# console). Re-asks until the input names a listed choice. `arg` is unused by the
# real asker but lets an injected test responder key on the axis.
ask_choice <- function(arg, question, choices, labels = as.character(choices)) {
  # A pointer + bold question, then the numbered options (M43/ADR-053). All via
  # cli, degrading to plain text with no colour; the numeric read is unchanged.
  cli::cli_text("{cli::symbol$pointer} {.strong {question}}")
  cli::cli_ol(labels)
  repeat {
    input <- prompt_line("Selection (number): ")
    n <- suppressWarnings(as.integer(input))
    if (!is.na(n) && n >= 1L && n <= length(choices)) {
      return(choices[[n]])
    }
    cli::cli_inform("Please enter a number between 1 and {length(choices)}.")
  }
}

# Thin wrapper over `readline()` -- an injection seam so `ask_choice()`'s read
# loop can be tested by mocking this binding rather than the console.
prompt_line <- function(prompt) {
  readline(prompt)
}

# Resolve a (possibly partial) answer set into an `icc_recommendation`, or abort.
# The two structural axes default to the common case; the coefficient-selecting
# axes are required (a NULL there is a loud underspecification error, #5), and
# axes that do not exist for the chosen design are rejected (an applicability
# error, #5) -- never silently ignored.
resolve_icc_recommendation <- function(answers, call = rlang::caller_env()) {
  model <- if (is.null(answers$model)) "twoway" else answers$model
  model <- validate_choice(model, c("twoway", "oneway"), "model", call = call)
  oneway <- model == "oneway"

  multilevel <- if (is.null(answers$multilevel)) FALSE else answers$multilevel
  if (!rlang::is_bool(multilevel)) {
    abort_intraclass(
      "{.arg multilevel} must be {.code TRUE} or {.code FALSE}.",
      call = call
    )
  }

  # Applicability: one-way has no rater term (no agreement/consistency, no
  # random/fixed) and no cluster structure (M6 spec; mirrors icc()).
  if (oneway) {
    reject_inapplicable(answers, c("type", "raters"), "a one-way design", call)
    if (isTRUE(multilevel)) {
      abort_inapplicable(
        c(
          "A one-way ICC has no cluster structure.",
          i = "Use {.code model = \"twoway\"} for a multilevel ICC, or drop \\
               {.arg multilevel}."
        ),
        call = call
      )
    }
  }

  # Coefficient-selecting axes: required, no silent default.
  unit <- require_answer(answers$unit, "unit", call)
  unit <- validate_choice(unit, c("single", "average", "both"), "unit", call)

  if (oneway) {
    type <- NA_character_
    raters <- "random"
  } else {
    type <- require_answer(answers$type, "type", call)
    type <- validate_choice(
      type,
      c("agreement", "consistency"),
      "type",
      call
    )
    raters <- require_answer(answers$raters, "raters", call)
    raters <- validate_choice(raters, c("random", "fixed"), "raters", call)
  }

  if (multilevel) {
    level <- require_answer(answers$level, "level", call)
    level <- validate_choice(
      level,
      c("subject", "cluster", "both"),
      "level",
      call
    )
  } else {
    reject_inapplicable(answers, "level", "a non-multilevel design", call)
    level <- "subject"
  }

  rows <- recommendation_rows(type, unit, raters, level, multilevel, oneway)
  icc_call <- build_icc_call(type, raters, unit, level, multilevel, oneway)
  rationale <- recommendation_rationale(
    model,
    type,
    unit,
    raters,
    level,
    multilevel,
    oneway
  )
  notes <- recommendation_notes(raters, multilevel, oneway)

  new_icc_recommendation(
    model = model,
    type = type,
    raters = raters,
    unit = unit,
    multilevel = multilevel,
    level = level,
    oneway = oneway,
    rows = rows,
    call = icc_call,
    rationale = rationale,
    notes = notes
  )
}

# A required decision is unanswered: a loud, actionable underspecification error
# (PRINCIPLES.md #5) -- never a silent default for a choice that changes the
# coefficient. Classed `intraclass_underspecified` so callers can catch it.
require_answer <- function(value, arg, call) {
  if (is.null(value)) {
    abort_intraclass(
      c(
        "The {.arg {arg}} decision is unanswered.",
        i = "Supply {.arg {arg}}, or call {.fun choose_icc} interactively to be \\
             asked."
      ),
      class = "intraclass_underspecified",
      call = call
    )
  }
  value
}

# An axis that does not exist for the chosen design was supplied: reject it loudly
# rather than ignore it (PRINCIPLES.md #5).
reject_inapplicable <- function(answers, args, design_phrase, call) {
  supplied <- args[!vapply(answers[args], is.null, logical(1))]
  if (length(supplied) > 0L) {
    abort_inapplicable(
      c(
        "{.arg {supplied}} does not apply to {design_phrase}.",
        i = "Drop {.arg {supplied}}."
      ),
      call = call
    )
  }
}

# The recommended coefficient rows. Reuses `icc_estimand()` -- the same label
# source a fitted `icc` object uses -- so the recommended McGraw-Wong and
# Shrout-Fleiss labels cannot drift from what `icc()` prints. One row per
# requested (level x unit); `k_eff` is irrelevant to the label.
recommendation_rows <- function(type, unit, raters, level, multilevel, oneway) {
  units <- switch(unit, both = c("single", "average"), unit)
  levels <- if (multilevel) {
    switch(level, both = c("subject", "cluster"), level)
  } else {
    "subject"
  }
  type_arg <- if (oneway) "agreement" else type
  rows <- list()
  for (lv in levels) {
    for (u in units) {
      est <- icc_estimand(
        type = type_arg,
        unit = u,
        raters = raters,
        level = lv,
        multilevel = multilevel,
        oneway = oneway
      )
      rows[[length(rows) + 1L]] <- list(
        level = lv,
        index = est$label,
        sf_index = est$sf_label
      )
    }
  }
  data.frame(
    level = vapply(rows, `[[`, character(1), "level"),
    index = vapply(rows, `[[`, character(1), "index"),
    sf_index = vapply(rows, `[[`, character(1), "sf_index"),
    stringsAsFactors = FALSE
  )
}

# The exact `icc()` call that computes the recommendation, as a copy-pasteable
# string. Only non-default arguments are shown (matching how the vignette writes
# minimal calls), so the emitted call is exactly what a user would type.
build_icc_call <- function(type, raters, unit, level, multilevel, oneway) {
  positional <- c("data", "score", "subject", "rater")
  if (multilevel) {
    positional <- c(positional, "cluster")
  }
  opt <- character()
  if (oneway) {
    opt <- c(opt, 'model = "oneway"')
  }
  if (!oneway && identical(type, "consistency")) {
    opt <- c(opt, 'type = "consistency"')
  }
  if (!oneway && identical(raters, "fixed")) {
    opt <- c(opt, 'raters = "fixed"')
  }
  if (!identical(unit, "both")) {
    opt <- c(opt, sprintf('unit = "%s"', unit))
  }
  if (multilevel && !identical(level, "both")) {
    opt <- c(opt, sprintf('level = "%s"', level))
  }
  sprintf("icc(%s)", paste(c(positional, opt), collapse = ", "))
}

# One plain-language sentence per decision the user made, drawn from the vignette.
recommendation_rationale <- function(
  model,
  type,
  unit,
  raters,
  level,
  multilevel,
  oneway
) {
  out <- c(
    model = if (oneway) {
      "One-way: raters are interchangeable across subjects, so systematic rater differences are absorbed into error -- the most conservative ICC."
    } else {
      "Crossed (two-way): the same raters judge every subject."
    }
  )
  if (!oneway) {
    out <- c(
      out,
      type = switch(
        type,
        agreement = "Absolute agreement: the value itself must match; a systematic difference between raters counts as error.",
        consistency = "Consistency: only the rank order must match; a constant per-rater offset is forgiven."
      )
    )
  }
  out <- c(
    out,
    unit = switch(
      unit,
      single = "Single rater: you will act on one rater's score.",
      average = "Average: you will act on the mean of your raters.",
      both = "Single and average: report the single-rater and averaged reliability side by side."
    )
  )
  if (!oneway) {
    out <- c(
      out,
      raters = switch(
        raters,
        random = "Random raters: a sample you generalize beyond, to the rater universe they were drawn from.",
        fixed = "Fixed raters: exactly these judges; the coefficient does not generalize past them."
      )
    )
  }
  if (multilevel) {
    out <- c(
      out,
      level = switch(
        level,
        subject = "Subject level: reliability of rating a subject within its cluster.",
        cluster = "Cluster level: reliability of the cluster mean.",
        both = "Both levels: within-cluster (subject) and between-cluster (cluster) reliability side by side."
      )
    )
  }
  out
}

# Caveats and automatic behaviours worth surfacing (from the vignette).
recommendation_notes <- function(raters, multilevel, oneway) {
  notes <- character()
  if (identical(raters, "fixed")) {
    notes <- c(
      notes,
      "Random raters is the recommended default for interrater reliability; use fixed only when these are the entire population of raters you will ever use."
    )
  }
  notes <- c(
    notes,
    "Complete vs. incomplete is automatic: icc() uses whatever ratings are present and projects ICC(*,k) to the effective number of ratings (k_eff). The design must stay connected, or icc() fails loudly."
  )
  if (multilevel) {
    notes <- c(
      notes,
      "See vignette(\"multilevel-designs\") for a worked multilevel example."
    )
  }
  notes
}

# Constructor for the recommendation object.
new_icc_recommendation <- function(
  model,
  type,
  raters,
  unit,
  multilevel,
  level,
  oneway,
  rows,
  call,
  rationale,
  notes
) {
  structure(
    list(
      model = model,
      type = type,
      raters = raters,
      unit = unit,
      multilevel = multilevel,
      level = level,
      oneway = oneway,
      rows = rows,
      call = call,
      rationale = rationale,
      notes = notes
    ),
    class = "icc_recommendation"
  )
}

#' @rdname choose_icc
#' @param x An `icc_recommendation` object.
#' @param ... Unused, for method consistency.
#' @export
format.icc_recommendation <- function(x, ...) {
  design <- if (x$oneway) {
    "one-way random"
  } else {
    icc_design_phrase(x$type, x$raters)
  }
  if (isTRUE(x$multilevel)) {
    design <- paste0("multilevel, ", design)
  }

  # A rule header + bold section labels + a bold recommendation + muted supporting
  # prose, all via the shared cli helpers (M43/ADR-053); the run-this call is kept
  # unstyled so it copy-pastes cleanly. Degrades to plain text with no colour.
  header <- icc_rule("Recommended ICC")

  # The coefficient label(s), grouped by level for a multilevel recommendation.
  if (isTRUE(x$multilevel)) {
    rec_lines <- vapply(
      split(x$rows$index, x$rows$level)[unique(x$rows$level)],
      function(idx) paste(idx, collapse = ", "),
      character(1)
    )
    rec <- c(
      icc_emph("Recommendation:"),
      icc_emph(sprintf("  %-8s %s", paste0(names(rec_lines), ":"), rec_lines))
    )
  } else {
    rec <- icc_emph(
      sprintf("Recommendation: %s", paste(x$rows$index, collapse = ", "))
    )
  }

  # Shrout & Fleiss equivalents where the crosswalk names one (never for
  # multilevel; NA for the two off-diagonal two-way forms).
  has_sf <- !is.na(x$rows$sf_index)
  sf_note <- if (any(has_sf)) {
    icc_mute(sprintf(
      "Shrout & Fleiss equivalent: %s",
      paste(
        x$rows$index[has_sf],
        x$rows$sf_index[has_sf],
        sep = " = ",
        collapse = ", "
      )
    ))
  }

  why <- c(icc_emph("Why:"), icc_mute(paste0("  - ", unname(x$rationale))))
  run <- c(icc_emph("Run this on your data:"), sprintf("  %s", x$call))
  notes <- if (length(x$notes) > 0L) {
    c(icc_emph("Notes:"), icc_mute(paste0("  - ", x$notes)))
  }

  c(
    header,
    icc_mute(sprintf("Design: %s", design)),
    "",
    rec,
    sf_note,
    "",
    why,
    "",
    run,
    if (!is.null(notes)) "",
    notes
  )
}

#' @rdname choose_icc
#' @export
print.icc_recommendation <- function(x, ...) {
  # Join to one string so blank-line separators survive cli_verbatim (see
  # print.icc); section spacing is part of the restyle (M43).
  cli::cli_verbatim(paste(format(x, ...), collapse = "\n"))
  invisible(x)
}
