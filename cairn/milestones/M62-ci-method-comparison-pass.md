<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M62: CI-method comparison pass — non-parametric bootstrap & profile-likelihood (GO/NO-GO)

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; independent of M48 (post-1.0, additive) -->
- **Principles touched:** IP1, GP5, GP6   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m62-ci-method-comparison-pass   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Decide — via an IP1 source hunt and a pre-registered coverage-and-width
comparison against the incumbent Monte-Carlo and parametric-bootstrap
intervals — whether a non-parametric (case/cluster) bootstrap and/or a
profile-likelihood CI for the two-way random ICC is "not worse" than the
incumbents, ending in a per-method GO/NO-GO with committed evidence and no
exported method.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:**
- IP1 source hunt per method (non-parametric cluster bootstrap for
  variance-component ICCs; profile-likelihood for the ICC as a *function* of
  variance components), ingesting any primary source as a `references/` source
  note; a "no primary source found" outcome is a recorded IP1-block finding.
- Non-exported prototypes under `data-raw/` for each method that clears the
  source gate: a case/cluster non-parametric bootstrap and a profile-likelihood
  interval for the two-way random ICC (glmmTMB/lme4).
- A seeded comparison harness computing empirical coverage + median interval
  width for four methods (MC, parametric bootstrap, non-parametric bootstrap,
  profile-likelihood) across anchored cells: a canonical interior two-way-random
  cell + a near-zero-boundary cell + a few-subjects cell (GP6 axis).
- A committed `references/` synthesis note: the comparison table, the
  pre-registered "not worse" criterion, and the per-method verdict.
- A GO/NO-GO D-entry per assessed method.

**Out:**
- Any exported `ci_method` value (`"npbootstrap"` / `"profile"`) → a GO-gated
  follow-on implementation milestone (candidate row now; promoted only on GO).
- Multilevel / nested / fixed-rater / lavaan / brms designs → out; the pass
  anchors on two-way random where both prototypes are defined. Extension →
  the same GO-gated candidate.
- Retuning or re-validating the incumbent MC / parametric-bootstrap methods.
- Categorical / non-Gaussian designs → the separate parked GLMM estimand
  (`cairn/legacy/ROADMAP.md`).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] **AC1 (source gate).** Per method, the IP1 source-hunt outcome is
      recorded: a primary source cited by citekey (ingested as a `references/`
      source note) or an explicit "no primary source found → IP1-blocked, not
      assessable" finding in the synthesis note.
      (RB tripwire: ip-touching)
- [ ] **AC2 (harness).** A seeded, reproducible script committed under
      `data-raw/` computes empirical coverage and median interval width for
      every non-IP1-blocked method at each specified cell; rerunning it
      reproduces the committed numbers.
- [ ] **AC3 (failure axis, GP6).** The comparison spans the known-failure axis:
      ≥1 near-zero-variance-boundary cell and ≥1 few-subjects cell, in addition
      to the canonical interior two-way-random cell.
- [ ] **AC4 (pre-registered bar, GP5).** The "not worse" criterion — coverage
      within the pre-registered tolerance of nominal AND ≥ the incumbents'
      coverage at each cell, median interval width as tiebreaker — is written in
      the synthesis note *before* the verdict, and the committed note applies it
      to give a per-method verdict.
- [ ] **AC5 (decision).** A GO/NO-GO D-entry is appended per assessed method,
      citing the synthesis evidence; the ROADMAP carries the disposition
      (GO → follow-on implementation candidate/row; NO-GO → recorded rejection).
- [ ] **AC6 (no exported change; no toolchain regression).** No new `ci_method`
      value; engine roster and public surface untouched (engine-parity matrix
      green + a grep shows no new `ci_method` literal in `R/`); the profile
      `verify` slot stays clean and new `data-raw/` scripts pass
      `air format --check`.

## Coverage
<!-- owner: plan · create/amend-via-gate; AC → task(s), positional numbers -->

- AC1 → T1, T6
- AC2 → T3, T4, T5
- AC3 → T2, T5
- AC4 → T2, T6
- AC5 → T7
- AC6 → T8

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] **T1** — IP1 source hunt: find a primary source for (a) non-parametric
      case/cluster bootstrap CIs for variance-component ICCs and (b)
      profile-likelihood CIs for the ICC as a function of variance components.
      Ingest any found source as a `references/` source note (+ INDEX line);
      record blocks. (RB tripwire: no-oracle, ip-touching)
- [ ] **T2** — Pre-register the "not worse" criterion + the anchored cell grid
      (interior + boundary + few-subjects) in a draft synthesis note, *before*
      any prototype is run (GP5).
- [ ] **T3** — Prototype the non-parametric (case/cluster) bootstrap interval
      for two-way random in a `data-raw/` script (resample subjects/clusters
      with replacement, refit via the fitted engine, percentile), glmmTMB/lme4.
- [ ] **T4** — Prototype the profile-likelihood interval for two-way random in
      a `data-raw/` script *if T1 clears IP1*: profile the variance components
      (e.g. `lme4::confint(method="profile")`) and map to the ICC; else record
      the IP1 block and skip.
- [ ] **T5** — Build the seeded comparison harness: at each anchored cell,
      simulate `n_rep` datasets, fit, record coverage + median width for MC,
      parametric bootstrap, and each cleared prototype; commit script + a
      results fixture. Heavy offline job — launch in the background from the
      start (cf. M47 brms coverage lesson).
- [ ] **T6** — Write the committed `references/` synthesis note: comparison
      table, the pre-registered criterion, per-method "not worse" verdict;
      add its `INDEX.md` line.
- [ ] **T7** — Append the GO/NO-GO D-entry per method; update ROADMAP
      dispositions (follow-on candidate/row on GO; recorded rejection on NO-GO).
- [ ] **T8** — No-export guard: engine-parity matrix green + grep `R/` for any
      stray `ci_method` literal; confirm the pass added no exported surface and
      `data-raw/` scripts are air-formatted.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-17: in-progress on m62-ci-method-comparison-pass (/milestone-implement).
- 2026-07-17: created by /milestone-plan. Absorbs the legacy candidate
  (`cairn/legacy/ROADMAP.md:81` — non-parametric bootstrap + profile-likelihood,
  "remainder unscheduled"; parametric-bootstrap half shipped M16/ADR-025).
  Shape/methods/designs/bar set at the plan gate (all recommended options):
  research pass, both methods, anchored two-way-random+GP6 axis,
  coverage-band+width criterion.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->
