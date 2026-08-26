# RR04: Exported-API last call before the first CRAN release (M48)

- **Date:** 2026-08-25
- **Brief:** `cairn/reviews/RB04-exported-api-last-call.md`
- **Reviewer:** independent expert review (Fable), advisory
- **Materials read:** `NAMESPACE`, `DESCRIPTION`, `R/icc.R`, `R/d-study.R`,
  `R/choose-icc.R`, `R/icc-methods.R`, `R/autoplot.R`, `R/zzz.R`, the seven
  `man/*.Rd` alias sets, `README.Rmd`, the vignette listing, and
  `tests/testthat/test-icc-methods.R` plus targeted greps of the engine files.
  Behavioral claims below marked "verified by running" were checked against a
  live `devtools::load_all()` session on the shipped datasets.

Summary of the verdict up front: the surface is in better shape than a
21-argument signature suggests, and most of the maintainer's "no changes"
expectation survives adversarial reading. Four things do not: a mixed
vector-default semantics inside one signature (Q3), a `glance()` schema that
silently misreports replicate fits (Q5), schema-instability in the conditional
`tidy()` columns (Q5/Q9), and an undeclared public/internal boundary on the
`icc` object (Q6). All four are cheap now and awkward later.

---

## 1. `icc()`'s argument list

**Order and grouping.** The order — data/columns (`data`, `score`, `subject`,
`rater`, `cluster`), design axes (`model`, `type`, `raters`, `unit`,
`occasions`, `level`, `design`), engine, interval control (`conf_level`,
`ci_method`, `mc_samples`, `boot_samples`, `seed`), engine-specific extras
(`brm_args`, `prior`, `posterior_summary`) — is the one a user will predict,
and the positional prefix `data, score, subject, rater` matches every shipped
example. The one positional hazard is that the fifth positional slot is
`cluster`: a user who passes a fifth argument positionally intending `model`
gets it captured by tidy-eval as a constant column. I traced this: a string
there yields a one-level cluster factor and a loud `abort_unidentified`
("needs at least 2 clusters"), so the failure is noisy, not silent. Acceptable.

**Confusable names.** Three pairs deserve scrutiny:

- `rater` (column) vs `raters` (sampling axis). One letter apart, semantically
  unrelated. I checked both misuse directions: passing a string to `rater`
  produces a one-level factor and the "needs at least 2 raters" abort; passing
  a column to `raters` fails `validate_choice`. Partial matching (`rate =`) is
  ambiguous between the two and errors. So every confusion fails loudly. The
  names are still uncomfortable, but a rename (`raters` → e.g.
  `rater_sampling`) buys little safety at real churn cost days before release.
- `model` vs `design`. Both are "design" words. Mitigated by `design` being
  multilevel-only and erroring without `cluster` (verified in the guard at
  `R/icc.R:923`). See Q4.
- `level` vs `conf_level`. The sharper collision is not with `unit` but with
  base R's `confint(..., level =)` convention: a user typing `level = 0.95`
  is following a 30-year habit. `validate_levels` rejects it loudly with a
  message naming the valid values, and `conf_level` is discoverable in the
  same signature, so the cost is one error message, not a wrong number.
  Defensible.

**Defaults.** No default silently chooses something a naive caller would not
want: `model = "twoway"`, `raters = "random"` (the recommended case, with a
warning on `"fixed"`), `ci_method = "montecarlo"`, `conf_level = 0.95` are all
the right resting points. The undefined-cell handling under the vectorized
defaults is drop-with-message, never silent. Two soft spots, neither
disqualifying: `seed = NULL` means the default interval is not reproducible
(standard R practice, and `seed` is documented prominently); and the default
call returns four coefficients (Q2).

One structural point in the package's favor: `icc()` has **no `...`**. Typo'd
argument names error instead of being swallowed, and future arguments can be
appended without breaking any existing call. That materially reduces the
release risk of the whole signature (see Q9).

## 2. Vector-valued defaults for `type` / `unit` / `level`

Is `type = c("agreement", "consistency")` (and likewise `unit`, `level`) the
right shipping choice? I tried to break it and conclude **yes, keep it** —
with one repair that belongs under Q3.

The case against: the default `print()` is a four-row table; positional
indexing of `tidy()` rows is fragile; and a package whose own principle is
"name the estimand before coding" ships a default that computes four estimands.
The case for, which I find stronger: (a) the second definition is post-fit
arithmetic on the same components — the marginal cost is zero even on a
minutes-long brms fit, so making the user refit to see the other definition
would be a genuinely worse API; (b) the side-by-side agreement/consistency
report is itself diagnostic (a large gap flags a rating-procedure problem, and
the docs teach exactly that reading); (c) `choose_icc()` exists precisely to
resolve one coefficient, and its emitted call always pins `type` explicitly
(`build_icc_call`, `R/choose-icc.R:451`) — the "name your estimand" path is
provided, not violated; (d) positional indexing of `tidy()` output is already
wrong practice the `index`/`type`/`level` columns exist to prevent, and no
default choice makes positional indexing safe (multilevel and replicate fits
change the row count anyway). The drop-vs-abort machinery (ADR-054) that makes
multi-value requests behave sensibly on undefined cells is built and tested;
reverting to scalar defaults now would ripple through print/tidy snapshots,
vignettes, README transcripts, and the emitted-call contract, at exactly the
wrong time.

## 3. Argument-shape asymmetry — the sharpest finding in the signature

The asymmetry between vectorized axes (`type`, `unit`, `level`, `occasions`)
and scalar axes (`model`, `engine`, `ci_method`) is **defensible in
substance**: the scalar axes each select a different *fit* (a different model
formula or a different engine/interval computation), while the vectorized axes
are post-fit arithmetic off one fit. One fit, many coefficients; one call, one
fit. That line is principled and worth keeping.

But the *signature syntax* currently contradicts it. Two arguments carry a
`match.arg`-style vector default — `raters = c("random", "fixed")` and
`posterior_summary = c("percentile", "hpdi")` — where the vector means "the
first one". Four others carry a vector default that means "all of them". The
same syntax, two opposite semantics, in one signature. A reader cannot tell
from the signature whether `raters = c("random", "fixed")` reports both (as
`type`'s identical-looking default does) or picks random. Worse than the
reading problem is the runtime one, which I **verified by running**: an
explicit `icc(..., raters = c("random", "fixed"))` — a perfectly natural
request from someone who just learned that `type` vectorizes — is silently
collapsed to `"random"` by `validate_choice`'s `identical(value, choices)`
branch (`R/icc.R:2594`). The user asked for both and got one, with no message.
That is a direct violation of the package's own fail-loudly principle (#5),
and it is the only silent argument mangling I found on the whole surface.

The fix is two characters of intent: default `raters = "random"` and
`posterior_summary = "percentile"`. Behavior is identical for every correct
call; the explicit-vector call flips from silent collapse to the existing loud
"must be one of" abort; and the signature convention becomes globally
consistent — *vector default = all values reported, scalar default = the
choice*. After release this change is still possible but the silent-collapse
behavior would have shipped. **Apply.**

(`occasions = "single"` as a scalar default on a vectorizable axis is fine:
`"average"` is only defined on replicated data, so "both by default" would
need drop logic for the common unreplicated case. The scalar default is the
honest resting point.)

## 4. The `design` argument

What it actually controls (from `R/icc.R:1151` and `validate_design`): with a
`cluster` column, `ml_design` is taken verbatim from `design` when non-NULL,
otherwise inferred by `detect_multilevel_design()`. Without `cluster` it must
be NULL (loud abort). So it is a *declaration override of the design
inference*, nothing else.

Is it redundant with `model`/`cluster`/`level`? No. It carries information the
data cannot: whether identical rater labels appearing in several clusters mean
the *same* rater (crossed) or label-reuse across cluster-specific raters
(nested). No inference can recover that from a complete table, and under
missing cells the pattern can be genuinely ambiguous. Can it contradict the
other three? I checked the contradiction routes: `design` without `cluster`
aborts; `design = "nested_*"` with `level = "cluster"` aborts (cluster level
undefined for nested designs); a declared `"crossed"` that the data cannot
support is caught by the bridging/connectedness identifiability gates rather
than honored. The declaration is validated, not trusted. It earns its place:
without it, the shared-labels nested case is simply unreachable. **Keep.**

The name is the weakest part — `model` and `design` are near-synonyms in this
literature — but `model` = one-way/two-way follows Shrout & Fleiss usage and
`design` is documented as multilevel-only with a self-explaining vocabulary.
A rename (`design` → `rater_design` or similar) is a judgment call I would not
spend release-week budget on.

## 5. Returned shapes vs. broom conventions

**`tidy.icc()` column names.** Against the broom glossary, `estimate`,
`std.error`, `conf.low`, `conf.high` are exactly right. The deviation is the
identifier column: broom's convention is `term`; this package uses `index`
(plus `type`, `level`, `sf_index` as honest domain columns). This is not
cosmetic: broom-consuming tools key on `term` — `modelsummary` and friends
build their row labels from it — so `tidy.icc()` output drops out of that
ecosystem silently. `index` is the better *domain* word (it is literally the
ICC index label), and the printed table uses it. Options: rename `index` →
`term`; or keep `index` and accept the interop loss. Renaming is free today
and permanent tomorrow; this is precisely a door that closes at submission.
**Consider (lean apply): rename `index` to `term` in `tidy.icc()` and
`tidy.icc_dstudy()`** (the printed-table header can stay "index"; `sf_index`
and `choose_icc()`'s `$rows` are display surfaces, not tidy contracts, and can
keep their names). If rejected, document the deviation in `@return`.

**The conditional `occasions` column.** Verified by running: a replicate fit's
`tidy()` has 11 columns with `occasions` inserted second; a plain fit has 10.
Meanwhile `level` — equally inapplicable to single-level fits — is
unconditionally present as NA. The asymmetry is the problem: the schema
already commits to "carry inapplicable identifier columns as NA" for `level`,
then breaks its own rule for `occasions`. `dplyr::bind_rows` papers over it
(NA-fill), but `rbind`, positional code, `vapply`-style column checks, and
schema-pinned databases do not, and every future extension (occasion-ragged
projection, etc.) re-raises the question. Make `occasions` unconditional in
`tidy.icc()` (NA when no replicates). Same disease in `tidy.icc_dstudy()`,
worse: there even `type` is conditional (present only when two definitions are
projected), so binding a default-fit projection to a single-type projection
gives ragged schemas. Make `type` (and `occasions`/`level` per its documented
rule) unconditional there too. **Apply** — this is a shape decision that is
free before release and a breaking change after.

**`glance.icc()`.** One row, good; design flags and components, good. Three
findings, one serious:

- **Replicate fits are misreported (verified by running).** A within-cell
  replicate fit estimates a `subject_rater` interaction component (every
  engine names it, e.g. `R/engine-glmmtmb.R:337`), and on that fit
  `var_residual` is *pure error only*. `glance()` has no `var_subject_rater`
  column, so the interaction variance is invisible and — worse —
  `var_residual` silently means a different quantity than on a
  single-rating-per-cell fit, with `n_o` nowhere in the row to flag it. A user
  summing `var_*` columns to a total variance gets the wrong total on exactly
  the fits where the decomposition was the selling point. Add
  `var_subject_rater` (NA when confounded) and `n_o` (NA when unreplicated) to
  `glance.icc()`. **Apply.**
- Broom's convention for the observation count is `nobs`; this package uses
  `n_obs` alongside `n_subjects` etc. The family-internal consistency
  (`n_*`) is worth more than glossary compliance for a non-regression model;
  and unlike `term`, little tooling keys on `nobs`. **Reject renaming**, but
  note it consciously.
- Missing-and-unrecoverable check: `ci$samples`, `seed`,
  `posterior_summary`, and the Bayesian `rhat`/`ess_bulk` diagnostics are on
  the object but not in `glance()`. If Q6 resolves to "the list is internal",
  glance is the sanctioned access path and a Bayesian user cannot reach the
  convergence diagnostics the docs say are "available to users". Adding
  columns to `glance()` later is additive and broom-tolerated, so this does
  not have to happen before the door closes — but `rhat`/`ess_bulk` are the
  two I would add now while the schema is open. **Consider.**

## 6. The `icc` object's internal structure

Once released, `fit$estimates`, `fit$components`, `fit$n$...` will be
depended on — R users read `str()` and reach in; nothing stops them, and the
`@return` docs already half-invite it ("a list with the estimate table,
variance components, ..."). Meanwhile the list holds slots that must stay free
to change (`mc`, `boot`, the engine-specific `to_components` closure). The
current position — undocumented names, no constructor, no disclaimer — is the
worst of the three options in the brief: it neither grants nor denies, so by
default it grants.

The cheap release-week fix is a documentation boundary, not a constructor:
one paragraph in `@return` naming the blessed slots — I would bless
`$estimates` (via `tidy()`), `$fit` (the engine object, already documented as
"the fitted model"), and `$call` — and stating explicitly that all other list
components are internal and subject to change without deprecation. That
sentence costs nothing now and is nearly unwritable two years post-release.
A formal constructor/accessor layer can come later without breaking anything.
**Apply (the disclaimer sentence); reject (a constructor now).**

## 7. `d_study()` and `choose_icc()`

**`d_study(x, m, n_o, conf_level, mc_samples, seed)`.** The
inherit-from-the-fit-when-NULL scheme is right and well documented (a seeded
fit projects reproducibly). Argument names:

- `m` — will a reader understand it? In context, yes: the docs define it in
  the first paragraph, every index label reads `ICC(A,m)`, and single-letter
  rater-count symbols are G-theory house style (McGraw & Wong's `k`,
  Brennan's `n'`). The real wart is cross-function: the *same concept* is
  `unit = 3` in `icc()` and `m = 3` in `d_study()`. The `@seealso` bridges it.
  Renaming either now would cost more confusion than it removes. Keep.
- `n_o` — cryptic in isolation, but the honest choice: `occasions` is taken
  (character-valued, in `icc()`), and `n_o` is the symbol every replicate
  formula in the docs uses. Keep, with the docs carrying the load as they do.
- Signature order `x, m, n_o, ...` puts the two mutually exclusive axes
  adjacent, which reads well; supplying both aborts loudly (verified in code,
  `R/d-study.R:206`).

One genuine gap, **verified by running**: `d_study()` validates `m`/`n_o`
carefully but passes `conf_level` and `mc_samples` through unvalidated —
`d_study(f, m = 1:3, conf_level = 1.5)` dies with a bare
`'probs' outside [0,1]` simpleError and `mc_samples = 0` with
`missing value where TRUE/FALSE needed`. Both violate the classed-error
contract (#8) that `icc()` honors for the same arguments. Not a
shape-of-the-interface issue, but a two-line fix reusing `icc()`'s existing
validators. **Apply (small).**

**`choose_icc(model, type, unit, raters, multilevel, level)`.** The
no-silent-default policy for coefficient-selecting axes, with loud
`intraclass_underspecified` errors non-interactively, is exactly right for a
teaching helper, and the reject-inapplicable behavior (supplying `type` to a
one-way design errors rather than being ignored) matches `icc()`'s ethos. The
axis vocabulary intentionally mirrors `icc()`'s. One asymmetry a user will
hit: `unit` and `level` accept `"both"`, but `type` does not — you cannot ask
`choose_icc()` for the side-by-side agreement/consistency report that
`icc()`'s *default* produces. Deliberate (ADR-021 resolves one coefficient),
but since `unit = "both"` already returns two rows, the principle is not
"one row" and the gap will read as an oversight. Accepting `type = "both"`
later is additive and non-breaking, so it need not gate the release.
**Consider (post-release ok).**

## 8. Should anything be withheld?

I looked for a withholding case for each export and found none strong enough:

- `summary.icc` is the closest call. It violates the base-R convention that
  `summary()` returns a summary object printed by `print.summary.*`; here it
  prints directly and returns the `icc` object invisibly. Changing that
  return type post-release is technically breaking. But the realistic blast
  radius is tiny (nobody computes on `summary()`'s return when it is
  documented as the object invisibly), the current behavior is documented
  precisely in `@return`, and withholding it would cost a genuinely useful
  interpretive report. Ship it as is.
- `choose_icc()` interactive mode: `readline`-based, `is_interactive()`-
  gated, injectable seam for tests — CRAN-safe and shaped. Ship.
- `plot`/`autoplot` methods: lazily registered against a Suggests ggplot2 via
  the vendored `s3_register()`; standard, correct pattern. The `what`
  argument on `autoplot.icc` is small and extensible. Ship.
- `d_study()`: the newest surface (the `n_o` axis landed recently), but it is
  the one export already wearing an explicit `lifecycle::badge("experimental")`
  — the honest mechanism for "shape may still settle" — so withholding would
  be redundant with the flag it already carries.
- `tidy`/`glance` re-exports: required for the methods to be usable without
  attaching broom/generics. Ship.

Nothing to withhold. The experimental badge on `d_study` is doing the work
withholding would do, at lower cost.

## 9. Extension headroom

I walked each named roadmap extension against the current signatures:

- *Cluster-level / occasion-ragged D-study projection*: today these paths
  abort or drop-with-note. Enabling them later removes errors — strictly
  non-breaking. No signature change needed (`m`/`n_o` already carry the
  vocabulary).
- *Occasion-averaged coefficients on ragged replicates*: gated behind a
  teaching abort at the `occasions` check; later support relaxes a guard.
  Non-breaking.
- *Incomplete/unbalanced fixed-rater cluster-level*: same shape — a guard
  relaxation. Non-breaking.
- *Further `ci_method` values*: additive strings on an existing argument.
  Non-breaking.

Structurally, the package is well protected: no `...` in `icc()` or
`d_study()` means new arguments append without capture risk, and the
drop-vs-abort policy generalizes to new undefined cells. The **one place
extensions would force a break** is the returned tabular shapes: each
extension that adds a disambiguating column (as replicates added `occasions`)
would, under the current conditional-column pattern, change the schema of
existing calls' output — a break in practice for schema-pinned consumers. The
cheap change that buys the headroom is the Q5 fix: commit now to "every
identifier column always present, NA when inapplicable". After that, future
extensions only ever fill in NAs, which is not a break. A second, smaller
observation: the multilevel-`unit`-numeric deferral, the 2-D `m × n_o`
surface, and `level`-subsetting in `d_study()` are all currently aborts, so
each is future-relaxable for free.

## 10. `lifecycle` in Imports

The premise of the question is slightly off: `deprecated()` is indeed never
called, but `lifecycle` is not unused — `R/d-study.R:19` uses
`lifecycle::badge("experimental")` in roxygen (evaluated at documentation
time), the badge SVGs are shipped in `man/figures/`, and
`importFrom(lifecycle, deprecated)` exists to satisfy R CMD check's
"Namespace in Imports not imported from" note — the standard
`usethis::use_lifecycle()` scaffolding, verbatim. The project has committed to
a deprecation cycle (GP2's one-way door implies one), and the first
deprecation will need `lifecycle` in Imports at exactly the moment it is most
annoying to add. The marginal cost is near zero: lifecycle's own hard
dependencies (`cli`, `glue`, `rlang`) are already in, or trivially extend,
this package's closure. Dropping it would save one small package and cost the
badge, the scaffolding, and a re-add later. **Keep as is; reject dropping.**
One adjacent item: at release, decide deliberately whether the README's
package-level "experimental" badge and `d_study()`'s badge still say what you
mean for a 0.1.0 — that is a statement to users, not a dependency question.

## 11. Undocumented methods

The premise is again half-wrong in a good way: the thirteen S3 methods have no
*own* `.Rd` pages, but none is undocumented. I verified the aliases: all seven
`icc`-object methods alias to `man/icc.Rd`, all six `icc_dstudy` methods to
`man/d_study.Rd`, both recommendation methods to `man/choose_icc.Rd`, and each
page's `@return` describes every method's return value individually (an
unusually complete treatment — most packages don't document what `print`
returns). For CRAN: R CMD check requires documentation for exported functions;
registered S3 methods are exempt, and these have aliases anyway, so `?tidy.icc`
resolves. Fully acceptable for submission. For users: the grouped-page layout
is arguably *better* than thirteen stub pages, since the methods' contracts
are only intelligible next to the object they read. No method needs its own
page before release. **No change.**

---

## Beyond the brief

1. **`d_study()` unvalidated interval arguments** (detailed under Q7):
   `conf_level` and `mc_samples` reach base R unvalidated and die with
   unclassed errors, breaking the #8 classed-error contract that is otherwise
   uniformly honored. Two lines with existing validators.
2. **`glance.icc()` on a replicate fit changes the meaning of `var_residual`
   without any flag** (detailed under Q5) — called out separately because it
   is a correctness-of-report issue, not a style one.
3. The `ratings`/`ratings_incomplete` datasets are part of the surface
   (LazyData, documented in `man/ratings*.Rd`) and were not in the brief's
   materials list; I reviewed their doc pages' existence only. Their column
   names (`score`, `subject`, `rater`) match the argument names — good
   teaching symmetry worth preserving in any future dataset.
4. `conf_level` (argument, snake_case) vs `conf.level` (output column,
   broom-dotted) is a deliberate-looking split that matches tidyverse norms
   (snake arguments, broom-glossary columns). Fine; noted so nobody
   "harmonizes" it later and breaks the broom contract.

## Recommendations

Ranked. "Apply" = worth doing before the door closes; "consider" = real but
survivable either way; "reject" = examined and declined, with reason.

1. **Apply — scalar defaults for `raters` and `posterior_summary`**
   (`raters = "random"`, `posterior_summary = "percentile"`). Removes the
   two-semantics vector-default ambiguity and the verified silent collapse of
   an explicit `raters = c("random", "fixed")` request. Behavior-identical for
   every correct call; minutes of work. (Q3)
2. **Apply — stabilize the tidy schemas.** `occasions` always present in
   `tidy.icc()` (NA when unreplicated); `type`, `level`, `occasions` always
   present in `tidy.icc_dstudy()` (NA when inapplicable). This is the one
   change that also buys the Q9 extension headroom. (Q5/Q9)
3. **Apply — fix `glance.icc()` for replicate fits**: add `var_subject_rater`
   (NA when confounded into residual) and `n_o` (NA when unreplicated), so
   `var_residual`'s meaning is never silently context-dependent. (Q5)
4. **Apply — declare the `icc` list's public/internal boundary** in
   `@return`: bless `$estimates`-via-`tidy()`, `$fit`, `$call`; disclaim the
   rest as internal and subject to change. One paragraph. (Q6)
5. **Apply (small) — validate `conf_level`/`mc_samples` in `d_study()`** with
   the existing validators so they abort classed. (Q7 / beyond-brief)
6. **Consider (lean apply) — rename `tidy()`'s `index` column to `term`** in
   both tidiers, for broom-ecosystem interop (`modelsummary` et al. key on
   `term`). Free now, permanent after. If declined, document the deviation
   explicitly in `@return`. (Q5)
7. **Consider — surface `rhat` and `ess_bulk` in `glance.icc()`** (NA for
   non-Bayesian fits); additive later, but cheap now and load-bearing if the
   list interior is declared internal per #4. (Q5/Q6)
8. **Consider (post-release ok) — accept `type = "both"` in `choose_icc()`**
   for parity with `unit`/`level`; additive. (Q7)
9. **Reject — reverting the vectorized `type`/`unit`/`level` defaults to
   scalars.** The multi-coefficient default is principled (post-fit
   arithmetic, diagnostic side-by-side reading), machined (drop-vs-abort),
   and `choose_icc()` provides the pinned-estimand path. (Q2)
10. **Reject — renaming `rater`/`raters`, `model`/`design`, or `level`.**
    Every traced confusion fails loudly through the classed validators; the
    renames would spend release-week budget on marginal gains and churn every
    doc, test, and emitted call. (Q1/Q4)
11. **Reject — dropping `lifecycle` from Imports.** It is in active use
    (badge + check-note scaffolding) and will be needed at the first
    deprecation; marginal cost ~zero. Revisit the *badges'* stage labels at
    release as a separate, deliberate statement. (Q10)
12. **Reject — withholding any current export.** `d_study()`'s experimental
    badge already does the flexibility-preserving work; everything else is
    settled enough to commit. (Q8)
13. **Reject — per-method `.Rd` pages.** All thirteen methods are documented
    and aliased on their objects' pages; CRAN-acceptable and better for
    readers than stubs. (Q11)

No `## Binding criteria` section: the brief's header slot does not say
`requested`; this report is advisory.
