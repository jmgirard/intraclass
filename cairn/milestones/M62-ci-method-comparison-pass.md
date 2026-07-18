<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M62: Non-parametric bootstrap CI pass — one-way ICC (GO/NO-GO)

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; independent of M48 (post-1.0, additive) -->
- **Principles touched:** IP1, GP5, GP6   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m62-ci-method-comparison-pass   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Decide — via a pre-registered coverage-and-width comparison against the
incumbent Monte-Carlo and parametric-bootstrap intervals, cross-checked against
the published ohyama2025 comparison — whether a non-parametric (case/cluster)
bootstrap CI for the one-way random ICC (ukoumunne2003) is "not worse" than the
incumbents, ending in a GO/NO-GO with committed evidence and no exported method.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:**
- Ingest the non-parametric bootstrap procedures of **ukoumunne2003** for the
  one-way random ICC as a `references/` source note: the standard resampling
  intervals (percentile / basic / BCa) *and* the variance-stabilizing
  bootstrap-t variant the paper finds near-nominal.
- Ingest **ohyama2025** (published CI-method comparison for the one-way ICC) as
  a `references/` synthesis/oracle note — its coverage/width results validate our
  harness's incumbent + bootstrap numbers (oracle-first, `PRINCIPLES.md #1`).
- A non-exported prototype under `data-raw/`: the non-parametric bootstrap
  interval(s) for the one-way ICC (glmmTMB/lme4), incl. the variance-stabilizing
  bootstrap-t variant.
- A seeded comparison harness: empirical coverage + median interval width for
  MC, parametric bootstrap, and the non-parametric bootstrap variants across
  anchored one-way-random cells — interior + near-zero-ICC boundary + few-subjects
  (GP6; ukoumunne's cluster-count/ρ grid).
- A committed `references/` synthesis note: comparison table, the pre-registered
  "not worse" criterion, the ohyama2025 cross-check, and the GO/NO-GO verdict.
- A GO/NO-GO D-entry for the non-parametric bootstrap.

**Out:**
- **Profile-likelihood CIs → their own milestone** (modified PL of xiao2013, on
  the *two-way random* design; naive PL as a reference point). Split from M62 at
  the 2026-07-17 gate once the sources proved design-specific; candidate row.
- Any exported `ci_method` value (`"npbootstrap"`) → a GO-gated implementation
  milestone (candidate; promoted only on GO).
- Two-way / crossed / multilevel / nested / fixed-rater / lavaan / brms designs.
- Retuning or re-validating the incumbent MC / parametric-bootstrap methods.
- Categorical / non-Gaussian designs → the parked GLMM estimand
  (`cairn/legacy/ROADMAP.md`).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] **AC1 (sources).** ukoumunne2003 is ingested as a `references/` source note
      capturing the resampling variants (incl. the variance-stabilizing
      bootstrap-t) with page/section anchors; ohyama2025 is ingested as a
      `references/` synthesis/oracle note with its one-way CI-method coverage/width
      results. Both carry their `INDEX.md` lines. (RB tripwire: ip-touching)
- [ ] **AC2 (harness + oracle check).** A seeded, reproducible `data-raw/` script
      computes empirical coverage and median interval width for MC, parametric
      bootstrap, and the non-parametric bootstrap variants at each one-way cell;
      reruns reproduce the committed numbers; and the incumbent + bootstrap
      figures agree with ohyama2025's published results at a comparable cell
      within a stated tolerance (oracle-first, `PRINCIPLES.md #1`).
- [ ] **AC3 (failure axis, GP6).** The comparison spans the known-failure axis:
      ≥1 near-zero-ICC boundary cell and ≥1 few-subjects cell, plus the canonical
      interior one-way-random cell.
- [ ] **AC4 (pre-registered bar, GP5).** The "not worse" criterion — coverage
      within the pre-registered tolerance of nominal AND ≥ the incumbents'
      coverage at each cell, median interval width as tiebreaker — is written in
      the synthesis note *before* the verdict, and the committed note applies it
      to give the non-parametric bootstrap verdict.
- [ ] **AC5 (decision).** A GO/NO-GO D-entry for the non-parametric bootstrap is
      appended, citing the synthesis evidence; the ROADMAP carries the disposition
      (GO → exported-implementation candidate/row; NO-GO → recorded rejection).
- [ ] **AC6 (no exported change; no toolchain regression).** No new `ci_method`
      value; engine roster and public surface untouched (engine-parity matrix
      green + a grep shows no new `ci_method` literal in `R/`); the profile
      `verify` slot stays clean and new `data-raw/` scripts pass
      `air format --check`.

## Coverage
<!-- owner: plan · create/amend-via-gate; AC → task(s), positional numbers -->

- AC1 → T1
- AC2 → T3, T4
- AC3 → T2, T4
- AC4 → T2, T5
- AC5 → T6
- AC6 → T7

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] **T1** — Ingest ukoumunne2003 (resampling variants incl. variance-stabilizing
      bootstrap-t + coverage findings) and ohyama2025 (one-way CI-method coverage/
      width table) as `references/` notes with `INDEX.md` lines. (RB tripwire: ip-touching)
- [x] **T2** — Pre-register the "not worse" criterion + the anchored one-way cell
      grid (interior + near-zero-ICC + few-subjects, per ukoumunne's grid) in a
      draft synthesis note, *before* the prototype is run (GP5).
- [x] **T3** — Prototype the non-parametric bootstrap interval for the one-way ICC
      in a `data-raw/` script (resample subjects/clusters with replacement;
      percentile/basic/BCa + the variance-stabilizing bootstrap-t variant),
      glmmTMB/lme4.
- [x] **T4** — Build the seeded comparison harness: at each cell simulate `n_rep`
      datasets, record coverage + median width for MC, parametric bootstrap, and
      the bootstrap variants; commit script + results fixture; cross-check the
      incumbent + bootstrap numbers against ohyama2025. Heavy offline job — launch
      in the background from the start (cf. M47 brms coverage lesson).
- [ ] **T5** — Write the committed `references/` synthesis note: comparison table,
      pre-registered criterion, ohyama2025 cross-check, GO/NO-GO verdict; INDEX line.
- [ ] **T6** — Append the GO/NO-GO D-entry; update ROADMAP disposition (exported-
      impl candidate on GO; recorded rejection on NO-GO).
- [ ] **T7** — No-export guard: engine-parity matrix green + grep `R/` for any stray
      `ci_method` literal; profile `verify` clean; `data-raw/` scripts air-formatted.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: confirmatory n_rep=2000 run CUT at user request — boundary cells ran ~4.2s/rep (est. ~5-6h total, not the ~80min I quoted), disproportionate for a 1-SE C4 firm-up. Proceeding on n_rep=1000 with C4 flagged marginal-but-passing (synthesis note caveat); firming C4 deferred to the exported-impl milestone's own coverage validation. → T6 GO/NO-GO gate.
- 2026-07-18: confirmatory re-run at pre-registered n_rep=2000 RUNNING (bg, tracked; ~80 min) to firm up the marginal C4 (boott .934 was ~1 SE over the .93 bar at n_rep=1000) and drop the n_rep amendment — GP5, executing the pre-reg now that the run is cheap. Resume: read the rds, update T5 table + drop the amendment, then the T6 GO/NO-GO gate.
- 2026-07-18: T4 done + T5 results written (~40 min run). Oracle cross-check PASSES (boott U10/U30/U50 = .921/.947/.953, reproduces ukoumunne Fig.2). SURPRISE vs the ohyama prior: transformed bootstrap-t not-worse at ALL 4 cells (.934-.940) while the MC default under-covers AND defers on 28-39% of near-zero-boundary datasets (C2/C4 n_ok 716/612). Recommended verdict GO(boott) / NO-GO(perc,bca). Pending user acceptance + optional Fable (ip-touching) before the T6 D-entry.
- 2026-07-18: T4 RUNNING (background, harness-tracked) — data-raw/m62-coverage-harness.R, n_rep=1000 (prospective amendment from pre-reg 2000; SE ~0.7pp, bar unchanged), incumbent boot B=199, proto B=2000; 4 comparison + 3 oracle-check cells → data-raw/m62-coverage-results.rds (incremental per-cell checkpoint), log data-raw/m62-harness.log. ~4-5h. Resume: read the rds, verify the ohyama/ukoumunne oracle cross-check, then T5 (append results to npbootstrap-oneway-comparison.md) → T6 (GO/NO-GO D-entry) → T7 (guard).
- 2026-07-17: T3 done — data-raw/m62-npbootstrap-prototype.R (subject-resample; percentile/boott-transformed/BCa; eq.7 IJ SE). Oracle check vs ukoumunne2003 Fig.2 at k=10,n=10,ρ=0.05 (nrep=200,B=400): perc 0.79, BCa 0.835, transformed bootstrap-t 0.95 — reproduces the published under-/near-nominal split (PRINCIPLES.md #1).
- 2026-07-17: T2 done — pre-registered (GP5, frozen before results) the "not worse" criterion (coverage ≥0.93 AND ≥ incumbents−0.01, width tiebreaker; GO iff not-worse at every cell) + one-way cell grid (C1–C4 comparison + ukoumunne-matched oracle-check cells) in npbootstrap-oneway-comparison.md.
- 2026-07-17: T1 done — source notes committed: ukoumunne2003.md (subject-resample + log F transformed bootstrap-t + IJ SE eq.7) and ohyama2025.md (oracle: NBOOT≈SEARLE/slightly worse, REML best) + INDEX lines.
- 2026-07-17: gate re-cut — M62 narrowed to non-parametric bootstrap ONLY on the one-way ICC (ukoumunne2003 + ohyama2025 oracle); profile-likelihood (MPL two-way, xiao2013) split to its own milestone (candidate; MPL=candidate, naive PL=reference). Title/Goal/Scope/AC/Coverage/Tasks re-authored via the gate.
- 2026-07-17: T1 complete (7 PDFs triaged). Sources SPLIT BY DESIGN: non-param bootstrap = ukoumunne2003 (one-way, Gaussian, under-covers ≤10 clusters); profile-likelihood = xiao2013 MODIFIED PL (TWO-WAY random, Eq.1; naive PL "too narrow"/under-covers, hence MPL). Bonus oracle: ohyama2025 = published CI-method comparison for one-way ICC (incl. Ukoumunne bootstrap; concludes REML best). Off-anchor: saha2005/saha2012 (binary), bobak2018 (Bayesian), xiao2009 (common-ICC sibling).
- 2026-07-17: UNBLOCKED — PDFs received.
- 2026-07-17: BLOCKED — awaited maintainer PDFs under cairn/references/pdf/; IP1 forbids reconstructing procedures from abstracts.
- 2026-07-17: gate amendment — anchor re-set two-way → one-way random ICC; Goal/Scope/AC2/AC3 amended, purpose unchanged. Gate also set "full empirical pass then decide" + "maintainer provides PDFs".
- 2026-07-17: T1 (partial). Non-param bootstrap source = Ukoumunne et al. 2003 (one-way ICC; under-covers ≤10 clusters). Profile-likelihood: no one-way-Gaussian source (Demetrashvili 2016 = Satterthwaite/Beta).
- 2026-07-17: in-progress on m62-ci-method-comparison-pass (/milestone-implement).
- 2026-07-17: created by /milestone-plan. Absorbs legacy candidate (cairn/legacy/ROADMAP.md:81; parametric-bootstrap half shipped M16/ADR-025). Plan gate set: research pass, both methods, anchored+GP6 axis, coverage-band+width criterion.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->
