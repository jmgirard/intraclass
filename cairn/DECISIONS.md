# Decisions

Append-only. Never renumber; supersede with a new entry. D-entries record
choices with rationale — never deferrals ("not now" is a ROADMAP fact).

**Pre-migration decisions:** the full architecture-decision log (ADR-001..058,
~5000 lines) is entombed verbatim at
[`cairn/legacy/DECISIONS.md`](legacy/DECISIONS.md) and stays valid as a citation
target — source comments, tests, and tracking cite `ADR-0nn` into it. cairn's
`DECISIONS.md` starts fresh at D-001; still-governing legacy decisions are cited
by their `ADR-0nn` id rather than re-recorded (per the `/cairn-init` migration
pointer-only choice, 2026-07-12). New cross-cutting decisions are appended here.

### D-001 (2026-07-12): IP/GP formalization — strength tags in place, new principles in DESIGN.md

**Context:** cairn's IP/GP taxonomy had been deferred at migration; ~70 in-code
`PRINCIPLES.md #N` citations (concentrated on #1×26, #5×20, #8×8) must not strand.
**Decision:** `PRINCIPLES.md` stays the authoritative home for `#1`–`#19`, each
strength-tagged in place — IP: #1–#5, #12, #19; GP: #6–#10, #11 (as amended,
D-002), #13, #18 — with two fences: #3's *default interval method* is tradeable
via D-entry (the IP core is "always an interval, boundary-aware, method
reported"), and #8's essence is *classed, actionable conditions* (`cli` is the
idiom, not the commitment). Interview-derived principles live in `DESIGN.md` as
IP1–IP3 / GP1–GP7.
**Consequences:** two homes, one taxonomy; in-code citations untouched; new
principles are cited as `DESIGN.md IPn/GPn`.

### D-002 (2026-07-12): Amend #11 — coverage is a diagnostic, never a gate

**Context:** #11 claimed a ≥90% target with CI failing on coverage regression;
actual practice is a deliberate ~88% baseline (untestable defensive abort
branches) and CI enforces no threshold — the constitution and CI disagreed.
**Decision:** #11 rewritten to honest practice: oracle coverage of statistical
paths is the real bar; `covr` is a diagnostic with no numeric target or CI gate.
Tagged GP.
**Consequences:** the constitution matches what CI demonstrably does; coverage
regressions surface via review judgment, not a mechanical gate.

### D-003 (2026-07-12): Retire #14–#17 — process absorbed by cairn

**Context:** plan-before-code (#14), thin slices (#15), tracking currency (#16),
and scope discipline (#17) are now owned and mechanically enforced by the cairn
rulebook; none has in-code citations.
**Decision:** #14–#17 retired with a tombstone note in `PRINCIPLES.md`; numbers
stay retired, never reused. #18 stays GP; #19 stays IP.
**Consequences:** single owner for process rules (cairn); the constitution keeps
statistical, software, and conduct principles only.

### D-004 (2026-07-12): Consolidated boundary-fit policy — one policy, existing behavior pinned

**Context:** Near-zero / singular variance components — the boundary of the
parameter space, and the common applied case for interrater data — were handled
by accumulated per-milestone case law scattered across the four engines and three
CI methods, governed by ADR-002, ADR-003, ADR-012, ADR-014, ADR-023, ADR-024,
ADR-025, ADR-031, ADR-033, ADR-037, ADR-038, and ADR-044 (the lme4 singular-fit
guard is introduced by ADR-012 and reused per shape via ADR-023/024), with no
single statement of the policy (the `DESIGN.md § Known issues` wart, confirmed
2026-07-12; M50).
**Decision:** the consolidated policy lives in one home,
`DESIGN.md § Boundary-fit policy`, as **three behaviors** — *smooth*
(boundary-aware by construction: log-SD for glmmTMB/lme4/lavaan, natural-scale
positive draws for brms), *classed deferral* (the `intraclass_singular_fit`
condition), and *reach-zero* (a boundary draw is kept, or the fixed-rater θ²_r
average is floored at 0) — mapped per engine (fit-time) and per CI method
(interval-time), each cell citing its governing ADR. This entry supersedes the
"case law" status of those ADRs by summarizing them under one policy; the ADRs
stay valid citation targets. It changes **no behavior**: the M50 audit surfaced
no behavior that contradicts its governing ADR, so no gate escalation was
warranted; review (2026-07-12) additionally corrected two documentation gaps in
the first draft — the omitted ADR-023/024 lme4 citations, and the bootstrap
row's under-documented non-convergent-refit warning path — without any code
change. Guard tests in `tests/testthat/test-boundary-policy.R` pin each
documented behavior, each naming its ADR/D-entry (GP7).
**Consequences:** the boundary policy has one authoritative home (DESIGN.md), a
decision record (this entry), and a standing guard-test asset. Any future change
to a documented cell touches the boundary-aware-interval contract
(`PRINCIPLES.md #3`) and requires a new, superseding D-entry — never a silent edit.

### D-005 (2026-07-16): Two-level SEM route to the multilevel estimand is an IP1-fenced parameterization

**Context:** M53's source hunt found no primary source composing two-level SEM
with GT interrater reliability for clustered subjects (Design 1). The published
pieces: the estimand and decomposition (ten Hove et al. 2022, Eqs. 6–7/12–13,
Table 3 — MCMC-estimated); the single-level SEM-GT mean-structure device for
σ²_r (Jorgensen 2021); two-level ML-SEM estimation as generic methodology
(Muthén 1994; Rosseel's lavaan). One-way SEM stays blocked (ADR-014) because
its unsourced approximation targeted a *different* (inexact-in-principle)
quantity.
**Decision (maintainer, M53 gate):** estimating the published Design-1
decomposition via a two-level CFA is an estimation-route parameterization under
IP1's implementation-detail fence — the M5 posture (the lme4 formula was "our
translation of Eq. 7, to be established by oracle, not assumed") — NOT a novel
method. Faithfulness is established numerically: the M53 pilot must show
glmmTMB parity up to documented ML-vs-REML small-sample deltas; systematic
disagreement is a no-go finding, not a tolerance to widen (GP5).
**Consequences:** M53 proceeds to the pilot; the implementation milestone (if
go) inherits this disposition and cites it; the composition ships only with
the oracle evidence attached. A future primary source, if one appears, is
ingested and supersedes the engineering framing.

### D-006 (2026-07-18): M62 GO/NO-GO — transformed bootstrap-t GO, percentile/BCa NO-GO (one-way ICC)

**Context:** M62 assessed whether a non-parametric bootstrap CI for the one-way
random ICC is "not worse" than the package incumbents (Monte-Carlo default,
parametric bootstrap), against a pre-registered coverage-band + width criterion
(GP5), sourced to `ukoumunne2003` and cross-checked against `ohyama2025`. Evidence:
`cairn/references/npbootstrap-oneway-comparison.md`; independent Fable review RR01
(archived) concurs.
**Decision:** **GO** for the `log F` variance-stabilized **transformed
bootstrap-t** — the only method near-nominal (≥ 0.93) at all four cells, faithful
to ukoumunne2003 (RR01 verified eq. 6/7 and reproduced the fixture to 4 dp) and
oracle-validated, and boundary-robust where the glmmTMB MC default aborts
(`intraclass_singular_fit`) on 28–39 % of near-zero-ICC datasets. **NO-GO** for
percentile and BCa (under-cover at C3/C4, as ukoumunne found). M62 ships **no
code**; a future `ci_method = "npbootstrap"` traces to ukoumunne2003 (IP1).
**Framing (RR01 Q3):** the GO does *not* claim to fix the MC default's one-way
boundary defect; a boundary-robust *classical* default (SEARLE exact-F / Burch
REML) is a separate tracked candidate. The bootstrap-t's residual value is
non-normality robustness (ukoumunne Fig. 3) + an interval that exists where the
default aborts.
**Conditions on the implementation milestone (RR01 Q4 / rec 2):** a C4-type corner
cell at n_rep ≥ 2000, lower/upper tail-error tracking, and a pre-specified
below-floor fallback (GP5); balanced-only (unbalanced `n_i`/`n₀` is design work
there).
**Consequences:** percentile/BCa recorded as rejected for this estimand; the
transformed bootstrap-t is cleared to be planned as an exported one-way
`ci_method` (candidate updated with the conditions); the SEARLE-F / Burch-REML
boundary-robust classical CI is added as a candidate.

### D-007 (2026-07-18): `ORACLES.md` is the declared oracle-registry home; references split

**Context:** `cairn/references/REFERENCES.md` was the pre-migration single page —
1346 lines carrying two different things: a 39-entry oracle→provenance registry
(~94 % of it) and a 16-item bibliography. The validation doctrine requires a repo
with numeric work to *declare* where its oracle records live, in one line of
`DESIGN.md` Conventions; this repo had no such line, and `DESIGN.md § Known
issues` recorded the absence as a standing wart pending the upstream cairn
`ORACLES.md` question (cairn D-024/M42). Meanwhile the cairn source-note
convention (`<citekey>.md` + `INDEX.md`) had already started arriving alongside
it (M62: `ukoumunne2003`, `ohyama2025`), so one directory ran two conventions.
**Decision:** split by *kind*, not by source — the registry becomes
`cairn/references/ORACLES.md` (the **declared registry home**, now named in
`DESIGN.md` Conventions), the bibliography becomes
`cairn/references/BIBLIOGRAPHY.md`, and per-source extractions migrate
progressively into `<citekey>.md` source notes (M64–M67). Explicitly **not** a
file-per-paper shred of the registry: oracle entries are keyed by oracle ID
(`O1`, `O-SEM`, `O-Bayes-IFNML`), tests cite those IDs, and many entries span
several sources — sharding them by citekey would break the ≥2-oracle-types audit
this registry exists to make possible. `REFERENCES.md` is retained as a 6-line
pointer stub, because `cairn/legacy/**`, `CLAUDE_CODE_KICKOFF.md`, and
`data-raw/reviews/` link to it and are entombed documents kept verbatim by
design. The split moved **no numeric value, `Status` line, or citation text** —
verified by byte-identical diffs of both bodies against the original.
**Scope fence:** this settles the *repo* side. Whether cairn itself mandates an
`ORACLES.md` shape stays the upstream open question (cairn D-024); the doctrine
leaves registry *shape* free and requires only that the location be declared, so
this choice is compatible with either upstream outcome and does not pre-empt it.
**Consequences:** the oracle registry has a declared, greppable home and the
`DESIGN.md` known-issue is struck. New oracles register in `ORACLES.md`; new
sources get a `BIBLIOGRAPHY.md` entry plus a `<citekey>.md` note with an
`INDEX.md` line. Citekeys disambiguate same-author-same-year with letter
suffixes ordered by issue (`tenhove2025a` = MBR 60(3) network data,
`tenhove2025b` = MBR 60(5) planned incomplete).
**Also covers `PRINCIPLES.md` #12** (M63 review, 2026-07-18): the split made #12's
`REFERENCES.md` citation path stale, so it now names `BIBLIOGRAPHY.md` — #12 is a
*citation* obligation, and bibliographic detail lives there, not in the oracle
registry (which D-007 keys by oracle ID and reserves for the ≥2-types audit). The
principle's substance is unchanged; only the path moved. `PRINCIPLES.md`'s header
exception list records it as `(#12, D-007)`, per that file's change-control rule.

### D-008 (2026-07-19): Verification bar for the index pages — three entry kinds, and what a script-derived "verified" does not assert

**Context:** `ORACLES.md` (39 entries) and `BIBLIOGRAPHY.md` (38) are the two
`cairn/references/` pages the D-007 split moved as text without reading, and the
last two carrying an unverified extraction status after M69–M71 dated-verified all
30 source notes. They cannot take the source-note bar unchanged: a source note owns
one primary source and is re-read against it, whereas most `ORACLES.md` entries
trace to a committed seeded script under `data-raw/` rather than to a page of a PDF.
M72's implement gate established that no script *output* is committed — `data-raw/`
holds zero `.csv`/`.txt` and one `.rds`, `data-raw/.oracle-*-checkpoint.rds` is
gitignored, 35 of the 41 scripts assert relationships via `stopifnot` rather than
recording values, and only 4 write a committed fixture under
`tests/testthat/fixtures/`.
**Decision:** the bar splits by **entry kind**, three of them.
*Source-traceable* — values trace to a page of a cited source: re-read against the
source itself at the cited page, never against a `<citekey>.md` note, and corrected
in place with the correction cited.
*Script-derived* — values produced by a committed seeded script: confirm the named
script exists, and that the entry's values match an inline expected value in the
script source (hardcoded constant, tolerance target, trailing comment) or a
committed fixture. Where the script commits neither, the entry is recorded as
**script-attested, values not independently confirmed** — the honest status, never
a bare "verified".
*Mixed* — both legs (O1, O-OW, O-SEM and their like): each leg verified by its own
rule, because classifying a mixed entry as a single kind necessarily leaves half its
values unchecked.
**What a script-derived "verified" asserts:** that the registry agrees with what the
repo commits — the script exists, is seeded, and its committed expected values match
the entry. **What it does not assert:** that the script, re-run today, still produces
those values. That is a *reproducibility* claim and requires execution; engine
versions (glmmTMB, brms/Stan), BLAS, and RNG streams may all have drifted since the
entry was written. A script-derived verified status is a **provenance** claim, not a
reproducibility claim, and must not be read as the latter.
**Why re-running was refused (plan gate, 2026-07-19):** the Bayesian sweeps are
multi-hour background jobs (LESSONS 2026-07-19/M47: a live-Stan coverage sweep is
~2 h, roughly doubling under concurrent-R contention), and re-running them is a
different milestone's work with a different risk profile. A discrepancy found by the
confirmation pass is **escalated**, not silently re-run: re-running the implicated
script becomes its own milestone.
**Consequences:** both index pages can reach a dated-verified extraction status that
states what was actually done, closing the last two `references staleness` advisory
survivors. The provenance-vs-reproducibility distinction is now on the record, so a
later reader cannot mistake a script-derived verified entry for a re-executed one.
Reproducibility of the seeded scripts remains a standing, separately-plannable gap
(PRINCIPLES.md #12) — this entry scopes it out, it does not declare it closed.

### D-008 Amendment 1 (2026-07-19): correcting D-008's Context — 25 committed fixtures exist, not 4

**Context:** D-008's Context asserted that "only 4 write a committed fixture under
`tests/testthat/fixtures/`". That is **false**, and D-008 is append-only history, so
it is corrected here rather than edited. The true figure is **25 committed,
git-tracked `.rds` fixtures** under `tests/testthat/fixtures/`, written by 27 of the
41 `data-raw/` scripts. The error was methodological: the implement-gate survey
grepped for `saveRDS(x, "literal-path")` and so missed the dominant form in this
repo, `saveRDS(out, fixture)`, where the destination is a variable bound earlier in
the script. The related claims in D-008's Context stand as written and were
re-checked: `data-raw/` holds zero `.csv`/`.txt` and one `.rds`, and
`data-raw/.oracle-*-checkpoint.rds` is gitignored (`.gitignore:11`).
**Effect on the decision:** none. D-008's three-kind bar already names "a committed
fixture under `tests/testthat/fixtures/`" as a verification target, so the correction
*widens* what can be verified at the stronger fixture bar rather than changing the
rule. The **script-attested, values not independently confirmed** status remains
necessary but applies to a smaller residual than D-008's Context implied — the
non-Bayes scripts that write no fixture (`oracle-fixed-vs-random.R`,
`oracle-d-study.R`, `oracle-incomplete.R`, `oracle-multilevel.R`,
`oracle-fixed-incomplete.R`, `oracle-sem.R`), whose entries are instead confirmed
against inline expected values where they carry them.
**Also unchanged:** the provenance-vs-reproducibility distinction. A fixture records
what the script produced *when it was last run*; confirming an entry against it is
still a provenance claim, not evidence that a re-run today reproduces it.
**Consequences:** the count is not restated anywhere else in the record
(LESSONS 2026-07-19/M70 — a count is a form that breaks when a fact is added); the
per-entry classification in `ORACLES.md` carries the per-entry truth.

### D-009 (2026-07-20): The dated-observation convention — every repo-state claim on a references page carries an exit-coded settling directive

**Context:** A committed `cairn/references/` page makes two kinds of claim
(tracking-rules "Standing facts vs. dated observations"): standing facts about a
*source*, and dated observations about the *repo's own state* ("nothing reads this
page", "not a dependency", "the only hit is a work log"). M71 returned from review
three times because its interpretive repo-state claims could not be re-settled except
by a reader re-deriving them by hand — measured at M73 plan time as only 2 of 87 dated
observations carrying the command that would settle them. This entry defines the
convention M73 brings the corpus to and commits a checker that enforces it.
**Decision — four rules:**
1. **Every dated observation about repo state carries an exit-coded settling
   directive.** Immediately after its `— observed YYYY-MM-DD` stamp, on the same line,
   the claim carries `<!-- check: <shell command> -->`. The command runs from the repo
   root, reads state only (never writes), and is written so that **exit status 0 means
   the claim holds** and any nonzero exit means it is falsified. The grep-negation idiom
   is `! git grep -qlF 'citekey' -- <paths>` (exit 0 when the token is absent, i.e.
   "nothing reads this page" holds). The command encodes the claim's *specific* asserted
   scope — the exact paths and tokens the sentence names — so each directive is
   per-claim, never boilerplate.
2. **What counts as a settling command:** a deterministic, side-effect-free shell
   command whose exit code decides the claim — `git grep`, `grep`, `test`, a
   `python3 -c` / `Rscript -e` predicate. Determinism and read-only are the bar.
3. **Claims no command can settle, three dispositions:**
   - **Provenance extraction-statuses are exempt and out of scope.** The
     `Extraction: … — observed` line in a page's `**Provenance.**` block asserts a human
     re-read the page against its source; it is settled by the re-verification convention
     (tracking-rules "Re-verification") and read by `cairn_validate`'s `references
     staleness` advisory, not by a command. It carries no `check:` directive. The checker
     excludes any line containing `Extraction:`.
   - **A source-fact mis-stamped as an observation is restated as a standing fact** —
     the `— observed` stamp is dropped and it becomes a plain claim about the source.
   - **A genuinely-dated but un-command-settleable repo-state claim** ("recorded as
     printed and left open", "flagged for the maintainer") carries an explicit
     `<!-- check: none — <reason> -->`, the honest record that it was considered and no
     command settles it.
4. **Completeness is mechanized.** The committed checker
   `data-raw/check-reference-observations.py` parses every dated observation in the 30
   source notes and `INDEX.md` (excluding `Extraction:` lines), requires each to carry a
   runnable `check:` directive or a `check: none — reason`, runs every runnable
   directive, and **exits non-zero if any observation is unmarked or any claim is
   falsified.** A `--self-test` mode injects a known-false directive and asserts the run
   goes red, registered so a refactor cannot make the checker vacuous.
**Scope fence:** `ORACLES.md` and `BIBLIOGRAPHY.md` are M72's (they adopt this
convention rather than M73 revisiting them). Generalizing claims about a *source's*
table are M74's — they need full-table recomputation, not an exit code. A
`cairn_validate` check enforcing this convention plugin-side is the cairn repo's, not
this one's.
**Consequences:** a false repo-state claim on a references page now fails a re-runnable
command instead of resting on a reader's care; plan-time harvests can trust a dated
observation because the checker re-settles it. Supersedes nothing; complements D-008
(the index-page verification bar) and the tracking-rules standing-fact/dated-observation
split.

### D-010 (2026-07-21): npbootstrap exported-API scope — string confirmed, ICC(k) via monotone map, engine REML point (RR02)

**Context:** M75 exports the ukoumunne2003 transformed bootstrap-t as
`ci_method = "npbootstrap"` (balanced one-way random). Three implementation-gate
decisions hit the RB tripwire categories (irreversible-api, no-oracle) and were
escalated to an independent Fable review (RB02 → RR02, archived): the public
string, whether to serve `ICC(k)`/`unit = "average"`, and which point estimate to
report. RR02 answered all three; this entry records the durable outcomes.
**Decision (Q1 — string, confirms D-006):** ship `"npbootstrap"`. It disambiguates
against the incumbent *parametric* `"bootstrap"` on the axis that matters (data
resampled vs simulated-from-fit), and the percentile/BCa reading can never
materialize because D-006 permanently rejects those variants — the string names a
family with one member here. `ci_method` strings name families, not algorithms
(`"montecarlo"` is equally underspecified); the precision duty lives in `@param`
(RR02 BC1). Renaming to `"bootstrap-t"`/`"npbootstrap-t"`/`"transformed-bootstrap"`
rejected.
**Decision (Q2 — ICC(k)):** ship the `unit = "average"` interval via the monotone
Spearman-Brown endpoint map `g(ρ) = kρ/(1+(k−1)ρ)` applied to the two final ρ
endpoints. Coverage is an **exact event identity** with the ICC(1) interval
tail-by-tail (strictly increasing composition; the SB pole sits exactly at the
excluded support boundary `−1/(k−1)`), so it inherits the Table I anchor exactly.
The composed map is `h(logf) = 1 − e^(−logf)` (equivalently `g(ρ̂_MoM) = 1 − 1/F`,
the classical ANOVA ICC(k) estimator, own support `(−∞, 1)`), so the untruncated
doctrine (RR01 §5) carries over verbatim. IP1 is met by the exact proof **plus two
committed numeric checks** — an algebraic identity cross-check (BC2, doubling as a
`k_eff = n` design-consistency guard) and a rep-by-rep inherited-coverage assertion
in the sweep (BC3) — never the argument alone; ORACLES records the basis as
inheritance, not an independent anchor (BC4). Withholding (abort on the default
call) rejected: exact identity, no statistical risk, real ergonomic cost.
**Decision (Q3 — point):** report the engine (glmmTMB REML) point via the shared
`icc_point()` path for **both** estimands, identical to every other frequentist
`ci_method`; the ANOVA-MoM ρ̂ is interval machinery and is never surfaced as a point
(BC5). `ci_method` selects the interval, not the estimand; a negative MoM point
would leak a second estimator into the API, flip sign against `montecarlo`, and
violate the population support. Bounded cost: at the boundary the REML point can lie
outside an all-negative interval, an event ⊆ the tracked upper-tail misses where
ρ > 0 (BC6).
**Consequences:** RR02's six binding criteria (BC1–BC6) are ingested verbatim into
M75's acceptance criteria (`Driving RR: RR02`); ICC(k) is now in M75 scope. The
unbalanced candidate must warn that the SB pole/support alignment is balanced-only
and needs re-derivation under `n₀` (RR02 beyond-brief 2). Confirms and does not
supersede D-006; extends it with the ICC(k) and point-source rulings.

### D-011 (2026-07-21): CI wall-clock is the testthat suite, not the dependency install — M77 lesson corrected

**Context:** The M77-lineage ROADMAP candidate proposed caching CI R
dependencies, on the M77 LESSONS claim that "CI wall-clock here is dominated by
the `needs: check` dep install (~17 min ubuntu, ~23 min Windows)". Planning M78
measured the R-CMD-check run at step granularity (PR run 29844778408):
`setup-r-dependencies@v2` restores in 33s (ubuntu) / 52s (Windows) — it already
caches by default — while `check-r-package` runs 16m/21m, of which
`Running 'testthat.R'` is 13m elapsed (24m CPU, ~1.85× parallel) on ubuntu and
18m on Windows (one time, no CPU/elapsed split → parallelism not engaging).
Examples ~1s; vignette rebuild ~70s; 1896 tests run, 25 skip_on_ci (brms).
**Decision:** The premise is falsified. Dependency caching and `needs:`-narrowing
win ≈nothing; the CI wall-clock lever is the testthat suite runtime. The
dep-caching candidate is retired (superseded by M78); the M77 LESSONS line is
corrected in place. M78 targets the suite via parallelism (worker-count) and
residual structural `boot_samples` right-sizing, under the GP5/GP6 constraint
that no coverage/agreement oracle count is weakened.
**Consequences:** Any future "speed up CI" work sizes from the check/test step,
not the install (which is solved). GP3 (platform honesty) governs — the
parallelism change alters how CI runs, so its stability is verified on the PR's
own matrix, never asserted.

### D-012 (2026-07-21): M76 GO/NO-GO — classical one-way ICC CIs: NO-GO default-replace, GO opt-in (SEARLE exact-F + Burch REML)

**Context:** M76 assessed whether a classical boundary-robust one-way random-ICC CI
— SEARLE exact-F and/or Burch (2011) REML — should replace or supplement the
glmmTMB Monte-Carlo default, against a pre-registered coverage/width/tail/abort
criterion (C1–C6) frozen before any run (GP5;
`cairn/references/classical-oneway-comparison.md`). Motivation (D-006): the MC
default aborts (`intraclass_singular_fit`) on a large fraction of near-zero-ICC
datasets, where a classical closed-form interval always exists. Both prototypes
were oracle-validated (IP1) against ≥2 independent published worked examples each
(ohyama2025 §4 + burch2011 §4; O-Classical-OW). Sweep: 16 cells (ρ∈{.05,.10} ×
(k,n)∈{(10,5),(30,5),(50,5),(10,2)} × {gaussian, t5 leptokurtic cluster effect}),
n_rep=2000 for classical/MC/npbootstrap, reduced parametric-bootstrap baseline at
the two near-zero corners.

**Decision — NO-GO for default replacement; GO for opt-in `ci_method` (both methods):**
- **Abort defect solved (C1):** SEARLE and Burch each returned a finite interval on
  100% of 32,000 datasets (0 aborts) where the MC default aborted on 4–44% of
  near-zero cells (confirms + extends D-006's 28–39%).
- **SEARLE exact-F:** near-nominal (0.94–0.96) and tail-symmetric across almost the
  whole grid; NO-GO for replacement on its single leptokurtic high-`k` under-coverage
  (0.10,50,5,t5 = 0.924, C2/C4) and the n=2 width (C3, measured against a 0.70-covering
  MC). Best-calibrated + narrowest when data are ≈ normal.
- **Burch REML:** never under-covers (0.937–0.991), best on the non-normal cells
  (passes C4 everywhere), but over-covers/wide at small `k` and is tail-asymmetric at
  n=2 (C5). The robust / guaranteed-coverage choice, bought with width.
- Neither passes the frozen every-cell bar for replacement, so **the default stays
  glmmTMB MC — no `#3`/ADR-003 contract change.** Both are cleared to be planned as
  **opt-in `ci_method`** values (SEARLE for near-normal data, Burch for non-normality
  robustness), whose primary value is a finite, well-calibrated interval where the MC
  default aborts — parallel to D-006 → M75 (npbootstrap opt-in).

**Scope fence:** the non-normal axis was one leptokurtic shape (t5), ρ≤0.10, k≤50; a
replacement verdict would need Burch's wider battery (platykurtic + skewed, Table 2)
and larger ρ. The opt-in recommendation does not, since it adds an option rather than
changing the contract. A classical **fallback-on-abort** default behaviour is a
distinct, later `#3` question, not decided here.

**Consequences:** M76 ships no code. The classical SEARLE and Burch REML one-way CIs
are recorded GO-for-opt-in / NO-GO-for-replacement; a follow-on implementation
milestone (ROADMAP candidate) may export one or both as `ci_method`, tracing to
burch2011/ohyama2025/mcgraw1996 (IP1). O-Classical-OW registers the prototype oracles
for that milestone to assert. Confirms D-006's framing (a boundary-robust classical
default is a separate track from the npbootstrap GO) and answers its open question: on
this evidence the classical route does not clear replacement.

### D-013 (2026-07-22): Classical one-way `ci_method` exported-API scope — `"searle"`/`"burch"` strings, ICC(k) via the SB map, deterministic (no SE/draws)

**Context:** M82 exports the two M76-validated classical one-way random-ICC
intervals (D-012 GO-for-opt-in) as `ci_method = "searle"` (exact-F) and `"burch"`
(REML). Three API decisions were settled at the plan/implement gate, parallel to
the npbootstrap sibling (D-010).
**Decision (strings):** ship `"searle"` and `"burch"` — author-family names under
D-010's doctrine that `ci_method` strings name families, precision duty in
`@param` (RR02 BC1). Two genuinely distinct methods (normal-exact vs
kurtosis-robust) cannot collapse to one `"classical"` string; per-algorithm
descriptive names rejected (they re-open the naming debate RR02 closed). No fresh
Fable RB — D-010 already set the governing doctrine.
**Decision (ICC(k)):** the `unit = "average"` interval is the monotone
Spearman-Brown image of the ICC(1) endpoints via the shared `npb_sb()`, identical
to D-010. For BOTH methods this SB image is algebraically identical,
endpoint-by-endpoint, to the direct classical ICC(k) F-form — SEARLE:
`npb_sb(ρ(g), n) = 1 − 1/g` (the mcgraw1996 Table 7 ICC(1,k) limit); Burch:
`npb_sb(θ/(1+θ), n) = nθ/(1+nθ) = 1 − 1/(1+nθ)`. IP1 is met by that proof plus a
committed per-method identity cross-check (`test-ci-classical.R`), so ICC(k)
coverage is inherited as an exact event identity and needs no separate anchor
(ORACLES basis = inheritance). No separate mcgraw Table 7 ICC(k) oracle shipped.
**Decision (point + metadata):** the reported point for both estimands and both
methods is the engine (glmmTMB REML) point via `icc_point()`, identical to every
other frequentist `ci_method` (D-010 BC5). Being deterministic closed forms they
consume no `mc_samples`/`boot_samples`/`seed`, `ci$samples` is `NA`, and
`std.error` is `NA` — no sampling distribution exists, so a fabricated SE is
refused (#4); `print()` names the interval "closed form".
**Consequences:** `"searle"`/`"burch"` join the `ci_method` vocabulary, balanced
one-way only (guarded with `"npbootstrap"`; aborts otherwise — the unbalanced
`n₀`/`n_i` derivation stays a candidate). O-Classical-OW flips prototype-validated
→ suite-asserted (M82). A classical fallback-on-abort DEFAULT stays out (a
`#3`/ADR-003 change; candidate row). Confirms D-012 (GO-for-opt-in) and mirrors
D-010's exported-API rulings for the classical family.

### D-014 (2026-07-23): M87 GO/NO-GO — modified-profile-likelihood two-way random ICC(A,1) CI: GO for opt-in (extends D-006 to the two-way design)

**Context:** M87 assessed whether the modified profile-likelihood (MPL) interval of
xiao2013 — with the correction constant κ_m **recalibrated over the extended range
ρ ∈ [0.05, 0.9]** (the published κ_m are maxima over ρ ≥ 0.6 only, xiao2013's
ρ_L = 0.6 fence, and are not transferable to the near-zero boundary) — is "not
worse" than the package incumbents (Monte-Carlo default; parametric bootstrap) for
the balanced two-way random `ICC(A,1)`, against a pre-registered coverage-band +
width criterion frozen before any run (GP5;
`cairn/references/mpl-twoway-random-comparison.md`). The naive- and modified-PL
machinery was implemented from scratch (no author code exists) and oracle-validated
against xiao2013's Tables 3/4/6/7 at M86 (IP1). Recalibration continuity at the
fence was checked against M86's validated κ_m (AC2, within ±0.01). Sweep: 5 cells
(C1 interior; C2/C3 near-zero-ρ boundary + few-subjects corner, GP6, decisive; C4
xiao's worst naive-PL geometry; C5 breadth), n_rep = 1000 (parametric bootstrap
B = 199 on the first 500 paired reps/cell), nominal 95 %.

**Decision — GO for an opt-in `ci_method`; NOT a default replacement:**
- **MPL is "not worse" at every cell**, and is the **only** method of four clearing
  the frozen 0.93 floor at all five: MC fails C4 (0.904), the parametric bootstrap
  fails C1 (0.926) and C4 (0.800), naive PL fails C4 (0.880). The absolute floor
  (not the incumbent-relative clause) carries the verdict, keeping it non-circular
  (as in D-006).
- **Boundary abort recurs (AC4):** the two-way random MC default aborts
  (`intraclass_singular_fit`) on **25.9 %** (C2) / **31.2 %** (C3) of near-zero-ρ
  datasets — the M62/RR01 one-way 28–39 % finding **carries over to the two-way
  random design**. MPL returns an interval on 100 % of datasets, covering
  0.995 / 0.994 at a median width narrower than MC's conditional width.
- **C4 breaks both incumbents:** at (3,50,δ4,ρ.60) naive PL under-covers (0.880,
  reproducing xiao2013) and so do both incumbents (MC 0.904, parametric bootstrap
  0.800); MPL (0.963, κ_m = 0.826) is the sole survivor.
- **Cost:** MPL over-covers everywhere (0.963–0.995 vs nominal 0.95) and is ~24 %
  wider than MC at interior cells — deliberately conservative (xiao2013 p. 2257),
  more so under the extended-range κ_m (~40–80 % above the published-region value).
  So it is an **opt-in** option, not a default (parallel to D-006/D-010/D-012/D-013).

**Framing (mirrors D-006):** the GO does not claim MPL fixes the MC default's
two-way boundary defect for the default path; its residual value is (a) near-nominal
coverage everywhere, including the S↑ regime where the package incumbents themselves
under-cover, and (b) an interval that *exists* where the MC default aborts. A
boundary-robust *classical* two-way default remains a separate, undecided `#3`
question (not opened here).

**Conditions on the implementation milestone (should the sibling be planned):**
(i) the sub-ρ = 0.6 κ_m has **no external oracle** (xiao2013's fence) — it is an
extrapolation of the M86-validated machinery, established only by its own simulated
coverage, and an exported method must document this; (ii) κ_m is **per-(R,S)
geometry** and each value costs an MC calibration (~minutes), so the sibling must
decide precomputed tables vs on-the-fly calibration; (iii) **balanced-complete and
Gaussian only** (xiao2013's likelihood assumes every R×S cell observed; non-normality
untested here). M87 ships **no exported code**.

**Consequences:** the ROADMAP "exported profile-likelihood `ci_method`" candidate —
GO-gated on this verdict — flips to GO-for-opt-in and inherits conditions (i)–(iii).
Extends D-006 (the one-way bootstrap sibling GO) to the two-way random design and
mirrors its opt-in-not-default framing; supersedes nothing. The M86-validated MPL
machinery (`data-raw/m86-mpl-lib.R`) and the M87 recalibration/sweep/verdict scripts
remain the from-scratch reference implementation a future export would trace to (IP1).

### D-015 (2026-07-23): M88 exported MPL `ci_method = "mpl"` scope — precomputed κ_m table, ICC(A,k) via SB inheritance, two-way-random-agreement fence

**Context:** M87/D-014 rendered GO-for-opt-in on the modified-profile-likelihood (MPL)
interval (xiao2013) for the balanced-complete two-way random ICC(A,1), inheriting
conditions (i)–(iii). M88 exports it; three API decisions were settled at the plan
gate, parallel to the classical (D-013) and npbootstrap (D-010) siblings.
**Decision (name):** ship `ci_method = "mpl"` — a method-family name under D-010's
doctrine that `ci_method` strings name families (as with `"npbootstrap"`); the
per-`@param` precision duty carries the "modified profile likelihood, xiao2013" detail.
No fresh Fable RB — D-010/D-013 already set the exported-API doctrine, and D-014
settled the statistics.
**Decision (κ_m provisioning):** ship a **precomputed κ_m table** (`R/sysdata.rda`)
generated by a seeded `data-raw/` background job (extended-range ρ∈[0.05,0.9],
argmax-corner unbiased estimator — M86 lesson, not the grid max), with lookup +
bilinear interpolation within an (R,S) grid. The exported method stays a deterministic
closed form like `"searle"`/`"burch"` (no `seed`/draws, `ci$samples = NA`). An off-grid
(R,S) aborts loudly (#5) rather than extrapolating an uncalibrated κ_m. On-the-fly
calibration (chosen against: slow, stochastic, breaks the deterministic-sibling
character) becomes a candidate.
**Decision (ICC(A,k)):** admitted via the shared `npb_sb()` Spearman-Brown image of the
ICC(A,1) MPL endpoints. For two-way **random** absolute agreement the averaged
coefficient is ICC(A,k) = σ²_s/(σ²_s+(σ²_r+σ²_e)/k) = kρ/(1+(k−1)ρ) with ρ = ICC(A,1)
(McGraw & Wong 1996 Table 4) — the exact SB form, so coverage is inherited as an exact
event identity, no new oracle (ORACLES basis = inheritance, as D-010/D-013). A committed
identity + mutation cross-check guards the divisor (M82 anti-tautology lesson). Numeric
`unit` (D-study projection to m≠R raters) stays a candidate.
**Decision (point + fence):** reported point is the engine (glmmTMB REML) point via
`icc_point()` (D-010 BC5); balanced-complete two-way random absolute-agreement Gaussian
only — consistency, fixed raters, other designs, unbalanced/incomplete all abort (#5/#8).
**Consequences:** `"mpl"` joins the `ci_method` vocabulary. Implements the D-014
GO-for-opt-in candidate; mirrors D-010/D-013's exported-API rulings; supersedes nothing.
A classical two-way boundary-robust *default* stays the separate `#3` candidate.

### D-016 (2026-07-24): Numeric `unit` (ICC(A,m)) for `ci_method = "mpl"` — pole-safe Spearman-Brown projection, no new oracle

**Context:** D-015 exported the MPL interval (xiao2013) as `ci_method = "mpl"` for the
balanced-complete two-way random ICC(A,1)/ICC(A,k), and parked a numeric `unit` (D-study
projection to m≠R raters) as a candidate. M89 promotes it.

**Decision:** admit any numeric `unit = m` (m ≥ 1, matching `validate_unit` and the
montecarlo path) under `ci_method = "mpl"` for the same balanced-complete two-way random
absolute-agreement cell. ICC(A,m) is the exact Spearman-Brown image `m·ρ/(1+(m−1)ρ)` of the
ICC(A,1) MPL endpoints (McGraw & Wong 1996 Table 4), computed by the shared `npb_sb()` — the
same inheritance leg as ICC(A,k), which `mpl_ci()` already applied to any `est$divisor`.
**Pole-safe unconditionally:** the SB pole ρ = −1/(m−1) is negative for every m ≥ 1 while the
MPL endpoints are clamped to [0, 1], so the denominator 1+(m−1)ρ ≥ 1 > 0 and the map stays
monotone in [0, 1] — no fence, unlike the unbalanced one-way npbootstrap case (D-010) where a
user-chosen m > n0 pushes the pole interior and numeric unit stays deferred.

**Oracle basis:** inheritance, no new external oracle (as D-010/D-013/D-015 for the averaged
coefficient). O-MPL's inheritance leg extends to ICC(A,m); verified by the exact SB-identity +
wrong-divisor mutation check (M82 anti-tautology). The reported point is the engine (glmmTMB
REML) ICC(A,m) point via `icc_point()` (D-010 BC5), already produced for the montecarlo path.

**Consequences:** implements the D-015 parked candidate; the fences are unchanged (conf_level
≠ 0.95, consistency, fixed raters, one-way/multilevel/replicate, unbalanced/incomplete all
still abort). Mirrors D-015's exported-API ruling; supersedes nothing. The classical two-way
boundary-robust default and on-the-fly κ_m calibration stay separate candidates.

### D-017 (2026-07-24): RB03/RR03 (Fable) — MPL `conf_level` ∈ {0.90, 0.99}: conditional GO for 0.99, GO for 0.90, no level deeper than 0.99

**Context:** M90 extends the MPL interval (`ci_method = "mpl"`, D-015) from the shipped
conf_level 0.95 to 0.90 and 0.99. conf_level 0.90 (α=0.10) recovers xiao2013's *published*
two-sided κ_m table (Table 3/6, ρ∈[0.6,0.9]) as a direct external oracle; 0.99 (α=0.01) is a
deeper-tail extrapolation than the already-shipped 0.95, with no external oracle. The plan
gate escalated the no-oracle 0.99 + sub-0.6 ρ extrapolation to a Fable review (RB tripwire:
no-oracle) before freezing the coverage criterion or running the multi-hour sweeps.

**Decision (RR03, independent statistical review with fresh seeded simulations):**
- **conf_level 0.90 — GO** on its external oracle (BC1) + coverage validation. Proceeds
  independently of 0.99's outcome; there is no coupling in that direction.
- **conf_level 0.99 — conditional GO**, exportable on simulated-coverage evidence alone
  (as the shipped 0.95 already is), gated on **BC1–BC7** (ingested verbatim into M90's ACs,
  Driving RR = RR03). The rationale: nothing *numeric* is extrapolated in α — the machinery
  recalibrates κ_m *at* the 0.99 deviance quantile — and the two structural risks that could
  make 0.99 different in kind (tail shape-dependence of the correction; a boundary failure
  invisible above ρ=0.6) both measured out **bounded and conservative-direction** (worst
  −0.21 pp coverage from *not* recalibrating; near-zero ρ=0.05 is interior, no deviance atom).
  What remains is the 0.95-precedent posture plus a priced deeper-tail MC-noise burden.
- **Binding conditions (summary; verbatim BC1–BC7 in M90):** re-earn the published α=0.10
  oracle through the α-parametrized pipeline first, incl. the off-`s_grid` S=25 geometries
  (BC1); size the α=0.01 calibration MC (scan≥3000, top_k≥5, final≥12000; recorded SE≤0.05,
  BC2); tighten the 0.99 coverage floor to **0.98** (not the proposed c−0.02=0.97) at n_rep≥2000
  with exact binomial CIs (BC3/BC4); sweep C1–C5 **plus** C6=(3,100,δ4,ρ.60), C7=(2,15,δ1,ρ.05),
  C8=(3,20,δ1,ρ.02 — the sub-grid-floor cell) (BC5); record miss-side/width/clamp diagnostics
  (BC6); export gating per BC7 (a BC failure routes that level to a candidate, NO-GO, without
  blocking the other).
- **Rejected:** (a) holding 0.99 back categorically while 0.90 ships — no failure mode
  different in kind from the shipped 0.95; the BCs price the difference in degree. (b) a
  tail-model (GPD/scaled-χ²) κ_corr estimator — the deep tail is demonstrably non-χ²-shaped
  where the grid max lives, so a model biases κ̂ low (anti-conservative); the raw empirical
  0.99 quantile stays the estimator, tail-model only as a diagnostic.
- **Boundary on the claim:** this authorizes conf_level 0.99 *specifically*; κ_corr is still
  rising at α=0.005 in the boundary cells, so no level deeper than 0.99 (0.995, 0.999) is
  authorized by analogy — each needs its own tail-estimability review.

**Consequences:** M90 sets Driving RR = RR03 and ingests BC1–BC7; the coverage criterion is
BC3/BC4/BC5, not the plan's proposed c−0.02. M91's 0.99 export is gated on M90's BC7 verdict.
Beyond-the-brief items: M91 documents the two-sided interval's non-equal-tailed character (all
levels, incl. 0.95) and the small-geometry near-vacuous 0.99 width (BC6), and softens the
`R/ci-mpl.R` interpolation comment ("increasing and roughly concave"), already falsified at
R≥8 by the shipped table. Extends D-014/D-015 to conf_level 0.90/0.99; supersedes nothing.

### D-018 (2026-07-26): Running a candidate method inside an abort path to decide whether to name it is not the fallback-on-abort default D-012 fenced out

**Context:** M93's boundary hint names an applicable opt-in `ci_method` inside the classed
`intraclass_singular_fit` abort the Monte-Carlo default raises near the σ²→0 boundary.
Five review passes each closed one mechanism by which a *design predicate* named a method
that then aborted or returned an unusable interval, and each patch shipped a new one: the
κ_m calibration grid, a raw subject count, an effective subject count, a missing score /
numeric `unit` / MSA = 0, and a verdict validating one of two endpoints. The M93 plan gate
(2026-07-26) adopted verification instead — run the candidate's own shipped reducer on the
data in hand and name it only if the interval is usable — which computes an interval inside
a path whose whole purpose is to raise an error. That approaches the fence D-012 drew and
D-013 re-stated: "A classical **fallback-on-abort** default behaviour is a distinct, later
`#3` question, not decided here."

**Decision:** computing a candidate interval to decide whether to NAME its method, then
discarding it, is not the fenced behaviour. The line is what the user receives: the call
still aborts `intraclass_singular_fit`, still returns no interval, and no computed endpoint
reaches the message text or any returned object. D-012/D-013's actual question — whether
the default should return a classical interval instead of aborting — stays open, stays a
`#3`/ADR-003 contract change, and stays a ROADMAP candidate needing its own every-cell
replacement-grade assessment. What this entry licenses is the diagnostic use alone.

**Consequences:** M93 names a method only after running it, and its AC5 asserts the
discard rather than assuming it. M97 inherits the same line for `npbootstrap`, where the
run additionally consumes randomness and so must be RNG-neutral (#9). The cost is bounded
by construction: verification is forced only inside an abort message, so a successful call
never pays for it. Confirms and does not supersede D-012 or D-013.

### D-019 (2026-08-01): MPL boundary endpoints are evidence-based; a genuine root-finding failure aborts classed — narrows the D-014/D-015 "interval on every dataset" framing

**Context:** `mpl_interval()` (`R/ci-mpl.R`) returned endpoint `0`/`1` from
`tryCatch(stats::uniroot(...), error = ...)`, so a genuine root-finding failure was
indistinguishable from a confidence limit truly at the boundary (ROADMAP candidate
since the M95/M96 plan gate, 2026-07-25; lineage M86 lib → M88 port). Low severity
by construction: `f(rho_hat) = -crit < 0` always, so `uniroot` errors precisely when
the deviance never crosses the critical value on that side, and the boundary answer
is correct in that dominant case. But D-014/D-015 framed the shipped method as
returning "an interval on **every** dataset", and the M99 plan-gate audit found that
introducing any abort path narrows that exported contract — a change the
Boundary-fit policy (DESIGN.md) says takes a D-entry.

**Decision (M99 plan gate 2026-08-01; refined at the M99 review return, same
date):** each side of the interval decides boundary-vs-failure by an explicit sign
test: the boundary endpoint is returned only when the profile deviance at that
side's outer bracket edge is finite and does not exceed the critical value (no
crossing — the confidence set provably reaches the boundary); a
crossing-indicated root-finding failure raises a classed
`intraclass_engine_error` via `abort_intraclass()`, its message naming MPL
root-finding (first non-engine use of the class; reuse chosen over minting a new
class). The review's diff-bug lens falsified the plan's premise that the abort is
unreachable with real data: on a **degenerate fit** (near-zero error MS — perfect
or near-perfect rater agreement, still failing at jitter SD 1e-6) `mpl_fit()`'s
joint minimum and the profile disagree, f(rho_hat) > 0, and the pre-M99 code
returned the vacuous fabricated interval [0, 1]. The maintainer chose (review
gate) to abort there too, via a sanity guard on the deviance reference whose
message names the degenerate fit, not root-finding; and the abort names **no
alternative method** — the methods the draft named also fail on the triggering
data, and D-018 forbids naming a method inside an abort without running it. A
warning-plus-boundary-value alternative was rejected: a wrong endpoint would
still reach downstream code (#5 fail-loudly). The offline reference
implementation (`data-raw/m86-mpl-lib.R`) carries the same decision logic in
lockstep (plain `stop()` — the classed layer governs package code only).

**Consequences:** narrows the D-014/D-015 framing prospectively — neither entry is
edited; D-014's measured "interval on 100 % of datasets" stays true as a sweep
result, and the residual value D-014 ships mpl for (an interval where the MC default
aborts) is unchanged: a review-time 240-rep sweep across four near-zero-ρ
geometries produced 0 aborts and 179 legitimate lower clamps, so the near-zero-ρ
boundary regime is entirely the no-crossing branch. Committed calibration
fixtures need no regeneration on that same evidence; a **future** sweep re-run
that did hit the abort would be caught by the M96 failure accounting and
`mpl_assert_no_failures()` would hard-stop the sweep rather than clamp a rep —
intended under #5. Perfect/near-perfect-agreement data now errors where it got
[0, 1] (documented in NEWS). DESIGN.md's interval-time boundary table gains an
MPL row citing this entry. Doc surfaces updated in M99 (roxygen, NEWS, comments,
the boundary-hint sentence, `data-raw/mpl-doc-claims.tsv` re-triage).

### D-020 (2026-08-02): Registered record claims — a load-bearing figure in tracking prose cites the ledger row that re-derives it, and CI re-runs every row

**Context:** A figure transcribed out of an artifact and into tracking prose — a
count, a worst-case step, an inventory — is read on every later pass and
re-derived on none. M100 returned from review five times over records asserting
more than their evidence established, and its fifth failure was this shape
exactly: a criterion certified by a hand-written `grep` whose pattern could not
match the violation it was certifying, green because it was vacuous. D-009
already closed the same gap for `cairn/references/` pages, where every dated
repo-state claim carries an inline exit-coded settling directive. This entry
closes it for the tracking records, whose claims are figures rather than dated
observations and which every milestone edits.
**Decision — the convention, as numbered rules.** The committed ledger
`data-raw/record-claims.tsv` and the checker `data-raw/check-record-claims.py`
implement it. Each rule names the checker's failure route that probes it, or
records that no input drives one and why.
1. A ledger row is tab-separated under a header naming exactly `id`, `record`, `kind`, `shape`, `claim`, `command`, `expected_rc`, `expected_match`, `falsifier_command`, `disposition`, `reason`; the checker's module docstring states that grammar and the checker parses its own column list back out of the statement, so the two cannot drift. probe: grammar
2. A record states a load-bearing figure by citing, inline, the ledger row that settles it — the marker `[claim:<id>]`. A citation naming no row is an error. probe: unresolved-citation
3. A row whose `disposition` is `cited` must be cited by some record in scope; a row deliberately registered without a citation declares `uncited` and gives its reason. probe: uncited-row
4. Citation scope: `cairn/ROADMAP.md`, `cairn/LESSONS.md`, `cairn/DESIGN.md`, `data-raw/README.md` — the four records that are current knowledge and so correctable in place. History (this file, work logs, `milestones/archive/`) is excluded because IP4 forbids editing it: a citation could not be added to it later, nor a figure proven wrong repaired where it sits. The checker asserts its own scope list equals the one this rule states, so the artifact under test cannot choose its own scope. probe: scope-parity
5. Registration, not detection: the checker's only inputs are ledger rows and citations, and it never scans prose for unregistered figures — an unregistered figure is unchecked and this tool will never say one exists. probe: none — a limit on what the checker reads rather than a condition it can meet, so no constructed input drives it to a failure; it is stated here so the limit is on the record instead of being discovered by a reader who trusted a green check
6. A `kind = absence` row carries a `falsifier_command`: the row's own command against a committed constructed input, under which the row must not pass. A certifying command that cannot be shown to fail certifies nothing. probe: absence-no-falsifier
7. That falsifier is run, and must fail the row's own expectation. probe: falsifier-passes
8. `kind` is author-declared and never inferred; declaring `presence` over an absence-shaped expectation (a non-zero exit status, a zero count, an empty result) is a mis-registration and an error. An output-shape classifier is a trap for mis-registration only, never the source of `kind` — it would miss the `^0 problems$` and `test !` forms and so rebuild the vacuity it exists to catch. probe: kind-misregistered
9. A command is one of the shapes the docstring states, tokenized and run without a shell — a pipeline, a redirection, a substitution or a chained second command is inexpressible rather than merely discouraged. probe: unknown-shape
10. A `git` command naming a history-dependent form — a `log`/`blame`/`rev-list`/`show`, a revision range, or a ref other than `HEAD` — is refused with its reason, the CI checkout being depth-1 with no `main` ref, so such a command would pass locally and fail there for reasons unrelated to the claim. probe: refused-form
11. A row's command must exit with its `expected_rc`. probe: rc-mismatch
12. Its stdout must fullmatch its `expected_match`; when the two disagree it is the record that is at fault, not the run. probe: match-mismatch
13. Every command runs under a bounded per-row timeout. probe: timeout
14. Every failure route the docstring states has a probe and every probe has a stated route, compared as sets rather than counts; and each probe is shown load-bearing by excising its route's sentinel-delimited block and confirming exactly that probe goes quiet. probe: route-parity
15. The shapes the docstring states equal the shapes the code dispatches on. probe: shape-parity
16. The refused forms the docstring states equal the forms the detectors fire on, one constructed sample apiece — a stated form no sample triggers is a dead rule. probe: refused-parity
17. A rule in this list naming a route the checker does not implement is an error. probe: rule-probe-unknown
**Relation to D-009:** the two conventions divide by surface and by claim type,
not by strength. D-009 governs `cairn/references/` pages and their *dated
observations* about repo state, settled by a directive written inline beside the
claim, enforced by `check-reference-observations.py`. This entry governs the four
correctable *tracking* records and their *figures*, settled by a row in a
separate registry that the prose cites, enforced by `check-record-claims.py`.
The registry is separate here because a figure's settling command is often
longer than the sentence and is reused across records, where a dated
observation's directive is per-claim by construction (D-009 rule 1). Neither
supersedes the other, and a `references/` page stays D-009's.
**Consequences:** a registered figure that drifts from its artifact reds the
`check-references` job instead of surviving review passes; the ledger is the
place a milestone registers a figure it wants held. The honest limit is rule 5's:
coverage is exactly what authors register, so a green run asserts nothing about
figures nobody registered. The standing ROADMAP candidate row for an
abort-remedy-truthfulness ledger builds on this row schema and checker idiom
rather than designing a second.

### D-020 Amendment 1 (2026-08-02): the refusal rule is one test, not a parse — no ledger command may run `git`

**Context:** D-020 rule 10 refused "a `git` command naming a history-dependent
form ... a revision range, or a ref other than `HEAD`". Meeting that required
deciding which token of a git command line was a revision, and two review passes
of M102 each defeated an implementation of it. The first enumerated ref
spellings and missed `HEAD~1`, `HEAD^`, a raw SHA, a tag and a bare branch name.
The second stated the rule positively over git's revision slot — pattern behind
`-e`, pathspec behind `--`, every operand between them must be `HEAD` — and was
defeated by `git grep -c -e -- main -- <path>`, where the `--` is `-e`'s own
argument, so the scan took it for the separator and never saw `main` behind it.
That command is accepted, resolves the ref locally, and on the depth-1 CI
checkout exits 128 — reported to its reader as the record being wrong.
**Decision:** the rule is decided by one test, `argv[0] == "git"`, and by nothing
after it. Every `git` command is refused; the `git-grep` shape is removed, so no
shape maps to git at all; and a row that wanted `git grep` writes `grep -r`,
which reads the working tree — the only tree a claim is ever about.
1. No registered command may run `git`, whatever its flags spell. probe: refused-form
2. The recognised forms — a history subcommand, a revision range, a ref spelling other than `HEAD` — no longer decide refusal and only name its reason, with `git-command` covering every command they do not recognise. Being wrong about which applies costs a vaguer sentence and never an acceptance. probe: refused-form
3. No command shape maps to `git`; a row naming one fails on the shape as well as the refusal. probe: unknown-shape
**What this does not claim:** it is a syntactic rule over the ledger cell, not a
sandbox. A `python3` row can still shell out to git, and D-020's rule 5 limit
applies here too — this is stated rather than papered over.
**Supersedes:** D-020 rule 10 only. Rules 1–9 and 11–17 stand unchanged, as do
the citation scope, the registration-not-detection limit, and the relation to
D-009. The reason an amendment rather than an edit: rule 4 of the entry it
amends says this file is history and IP4 forbids editing it, and a convention
that exempted its own record would not be one.

### D-020 Amendment 2 (2026-08-03): rule 9's "inexpressible" is false — the no-shell claim is narrowed to the checker's own layer

**Context:** Rule 9 states that a command "is one of the shapes the docstring
states, tokenized and run without a shell — a pipeline, a redirection, a
substitution or a chained second command is inexpressible rather than merely
discouraged." M102's third review pass falsified it. An `awk` row running
`awk 'BEGIN{ "git rev-list --count main..HEAD" | getline x; print x }'`
validates, is not refused, and passes, printing `commits:11` — awk's `| getline`
and `system()` spawn a shell from inside a shape the checker allows, and a
`grep`/`ls`/`awk` row can read `.git/` directly beside it. The claim was true of
the checker's own tokenizer and false of the system. Amendment 1 had already
conceded exactly this for one shape ("a `python3` row can still shell out to
git"); rule 9 kept asserting the general form.

**Decision:** rule 9 is narrowed to the layer it is true of. The checker
tokenizes with `shlex.split` and executes directly, so it interprets no shell
metacharacter — a pipeline or redirection written in a ledger cell is argument
text, not a shell construct. It does not follow, and is no longer claimed, that
a shell is unreachable: an accepted shape's own program may spawn one. The rule
is over the cell, never over what an accepted command does at runtime. Three
consequences are stated rather than papered over: `awk` and `ls` shapes can read
`.git/`; a `python3` row can `subprocess`; and rule 1's "no registered command
may run `git`" is therefore a syntactic guarantee about `argv[0]`, not a
behavioural one about history access.

**What this does not do:** it does not close the capability channels, which
would need an allowlist over what a shape may DO — dropping `awk` and `ls`,
restricting `python3` to committed helpers, refusing `.git/` paths — re-cutting
the shape set M102's AC1 and AC3 rest on. That was weighed at the M102 gate
(2026-08-03) and declined in favour of narrowing the promise, per the plan-gate
rule that a counterexample defeating an enumeration is not answered by a wider
enumeration. Promote the allowlist if a ledger row is ever found reaching
history in a way that makes a shipped figure wrong — the falsifier — never on a
further count of channels.

**Supersedes:** D-020 rule 9 only. Rules 1–8 and 11–17 stand, as does
Amendment 1 in full.

### D-021 (2026-08-03): Records-verification work needs a trigger in what the package computes — cairn's D-090 door, adopted here

**Context:** Eight of the last nine milestones — M94, M95, M96, M97, M98, M100,
M101, M102 — have as their subject whether this repo's own prose, messages and
records tell the truth; only M99 is about what the package computes. D-020
(2026-08-02) is the first decision entry whose subject is tracking prose. The
thrash concentrates in exactly that class: M92 ran seven passes where 1–6 each
failed on prose authored about the work and never on the code; M93 ran eight,
its last three with shipped code byte-identical; M100 ran three returns, passes
2 and 3 each finding a fresh false claim inside the previous pass's own fix;
M102 ran three and parked. The class is self-feeding — a repair to prose is new
prose, which is a new claim that can be false — and it never runs out of
subject matter, so it fills any gap in the queue. It is not worthless: M97 found
a hint naming a method that then failed, and M98's plan gate falsified a claim
that the pole hotfix had removed the endpoint test's anti-clamp coverage. What
it lacks is a door. cairn closed the same program on itself at its D-090 after
four consecutive apparatus milestones.

**Decision:** No milestone is planned whose deliverable is verification of this
repo's own records, prose or messages — a ledger over tracking figures, a guard
over doc claims, a truthfulness audit — unless its trigger is a defect in what
the package computes for its users: a wrong number, a wrong interval, a wrong
abort, a wrong exported behaviour. A false or unbacked claim in a record is
corrected in place, in the milestone that finds it, and never promoted into a
milestone of its own. Untouched: guards that pin a NUMERIC result or an exported
behaviour, which are ordinary verification of what the package does; the oracle
discipline under PRINCIPLES.md #1; and repairs to existing checkers surfaced as
ordinary work.

**In-flight disposition, taken at this entry rather than grandfathered.** M102
finishes on the narrowed AC2 above — its checker and ledger are built, eight of
nine criteria are green, and withdrawing an over-claim costs less than dropping
working machinery. M100 and M101 are re-judged against this door before either
resumes: each must name the wrong user-facing behaviour that motivates it, or it
is dropped and its content becomes a note in the milestone that next touches
those abort paths.

**Consequences:** the plan-time collision check surfaces this on any
records-verification scope, and the standing-rejection discipline applies —
supersede, don't ignore. If a wrong shipped number is ever traced to a record
defect this door turned away, this is the entry to supersede.

### D-020 Amendment 3 (2026-08-03): the checker's `D-045` and `IP4` citations name ids this repo does not define — the rule is restated in its own words

**Context:** M102's fourth review pass found two dangling references behind the
citation scope. Rule 4 of the base entry justifies excluding history from the
scope with "IP4 forbids editing it", and `check-record-claims.py` carried the
same citation beside a second one, "current knowledge under D-045". Neither id
exists in this repo: `cairn/DECISIONS.md` holds D-001…D-021 and `cairn/DESIGN.md`
defines IP1–IP3. Both are the cairn plugin's own numbering — its D-045 splits
tracking files into current knowledge and history, and its IP4 is the rule that
history is never edited. A reader of this repo resolving either id against this
repo's records finds nothing, and the sole stated ground for the scope's shape
therefore reads as unbacked. A repo-wide dangling-id check at the pass-5 fix
found no other live case: `D-024`, `D-025` and `D-090` are already written as
cairn's, and `D-050` and `D-055` appear only in a work log and an archive
summary.

**Decision:** the rule stands unchanged and its justification is restated
without the borrowed ids. History — decision entries, work logs,
`milestones/archive/` — is excluded from the citation scope because it records
what was decided at a time and is never edited, so a citation could not be added
to it later and a figure proven wrong in it could never be repaired where it
sits. The four scope files are current knowledge: they record what is true now,
so a wrong figure is corrected in place. That is the cairn tracking rulebook's
split, and where this repo's records name it they qualify it as the plugin's —
"cairn D-045", "cairn IP4" — matching the existing `cairn D-024` convention,
rather than writing a bare id that collides with this repo's own numbering.
`check-record-claims.py`'s SCOPE comment is corrected in place, being current
knowledge; rule 4 and Amendment 1 are history and stand as written, corrected by
this entry.

**Supersedes:** nothing operative. It annotates rule 4's and Amendment 1's
justifying citations; the scope list, the parity assertion and every probe are
untouched.

### D-021 Amendment 1 (2026-08-03): three figures in the motivating census are wrong — corrected against the committed records

**Context:** M102's fourth review pass found D-021's motivating paragraph
contradicting the committed record and, on one quantity, itself. Three
corrections, each re-derived at the pass-5 fix:

1. "M93 ran eight" — `cairn/milestones/archive/M93-boundary-abort-hint.md:19`
   records "Ten passes, three re-cuts". The figure is ten.
2. "M100 ran three returns" — M100 reached a fifth review pass
   (`a10d64e` "M100 review pass 5: gate failed (fifth return)"), and D-020,
   added by the same milestone as this entry, already says M100 "returned from
   review five times", as does `check-record-claims.py`'s "M100 passes 1-5".
   The figure is five, and D-021 was the only record disagreeing.
3. The census "Eight of the last nine milestones — M94, M95, M96, M97, M98,
   M100, M101, M102" counts M95 and M98, which this entry's own Untouched clause
   exempts: M95 pins a numeric result (all 162 cells of the shipped κ_m table)
   and M98 pins a behavioural one (the endpoint-parity test's clamp-detection
   classes). Both are ordinary verification of what the package does. The census
   is six of the last nine — M94, M96, M97, M100, M101, M102.

**Decision:** the three figures are corrected as above. The decision itself is
unchanged and none of the three disturbs it: six of nine consecutive milestones
taking the repo's own records as their subject, with M93 at ten passes and M100
at five returns, states the concentration the door exists to stop at least as
strongly as the wrong figures did. The correction is recorded here rather than
edited into the entry, that file being history.

**Supersedes:** D-021's Context paragraph figures only. The Decision, the
Untouched clause, the in-flight disposition for M100/M101/M102 and the
Consequences stand in full.

### D-020 Amendment 4 (2026-08-03): Amendment 3's own count of the qualified ids is wrong — corrected against every site

**Context:** Amendment 3 states "`D-024`, `D-025` and `D-090` are already
written as cairn's". M102's fifth review pass falsified it, and re-measuring
every site shows it wrong on two of the three. `D-090` is qualified at all three
of its sites (`cairn/ROADMAP.md:4`, and D-021's heading and body). `D-024` is
qualified at every site this repo authored — `cairn/DESIGN.md:217`,
`cairn/DECISIONS.md:138` and `:155`,
`cairn/milestones/archive/M63-references-migration.md:13` — but NOT at
`cairn/PROFILE.md:7`, which reads a bare `(D-024/D-025)`. `D-025` occurs exactly
once in this repo, at that same bare site. So the sentence is true of `D-090`,
true of `D-024` only where this repo wrote it, and false of `D-025` outright.

**Decision:** the sentence is corrected to read: `D-090` is written as cairn's
everywhere it appears; `D-024` is written as cairn's at every site this repo
authored; and both `D-024` and `D-025` appear bare exactly once, in
`cairn/PROFILE.md`'s scaffold comment. That comment is `cairn-init` template
output describing the plugin's own doctrine, not a record this repo authored or
this milestone owns, so it is left alone rather than repaired here. Amendment 3's
conclusion is unchanged and does not rest on the miscount: the only live,
unqualified ids in records this repo wrote were the checker's `D-045` and `IP4`,
and both are corrected there.

**Supersedes:** one sentence of Amendment 3. Its decision, its correction to the
checker's SCOPE comment, and its annotation of rule 4 and Amendment 1 stand in
full.

### D-022 (2026-08-05): Degenerate input and the zero-between-variance Burch interval are refused classed, and a missing score is a rating that did not happen

**Context:** three measured paths through `icc()` returned something other than a
classed condition or a usable interval (M105 plan gate, 2026-08-05). A
non-finite `score` reached whichever engine was selected and surfaced that
engine's own error — `negative log-likelihood is NaN at starting parameter
values` (glmmTMB), `NA/NaN/Inf in 'y'` (lme4) — on all four `model` × `engine`
combinations, so a caller could not `tryCatch()` the family by class as
PRINCIPLES.md #8 promises. `ci_method = "burch"` on data with no between-subject
variance divided by `sqrt(MSA) = 0` inside `burch_kappa_hat()` (eq. 13's kurtosis
standardization), producing NaN endpoints that raised a bare `simpleError` out of
`npb_guard_sb_pole()`'s non-NaN-safe `!any(denom < 0)` at `unit = "average"` and
shipped as a silently reported NaN interval at `unit = "single"`. And an `NA`
score reached the engine as well, where it counted as an observed cell — so an
incomplete design read as balanced to every design fence while no reducer could
use it.

**Decision (three parts).**
*Non-finite scores are refused at input validation*, before any fit, with a
classed condition naming the column and the offending rows. Input-side rather
than a classed wrapper around the engine error: the raw message differs per
engine, so a wrapper would have to match on text, and one check serves all four
engines.
*Burch at MSA exactly 0 aborts classed* (`intraclass_singular_fit`), where it
previously reported NaN. The guard is Burch-only and must not move into the
shared `classical_guard_observed()`: SEARLE reads MSA only through F = MSA/MSE
and returns its ordinary attained minimum on the same data, so a shared guard
would abort a sibling that has a correct answer. The test is `identical(., 0)`
and not a tolerance — the committed fixture has a cell at MSA = 3.5e-33 that
returns an ordinary interval, so any tolerance wide enough to catch it would
refuse a case Burch answers. Returning the attained floor instead was rejected
under IP1 and #4: that number comes from SEARLE's formula, not Burch's.
Warn-plus-NaN was rejected on D-019's ground — a wrong endpoint still reaches
downstream code (#5).
*An `NA` score is a rating that did not happen*: the row is dropped and the
remainder analysed as the incomplete design this package already fits, with a
classed `intraclass_dropped_rows` warning naming the count, suppressible by class
on the `intraclass_fixed_raters` precedent. Scope is `score` only — a row missing
its subject or rater identity cannot be placed in the design at all, so dropping
it would hide a data-preparation error rather than accommodate a missing rating.

**Consequences:** the exported contract refuses exactly two things it previously
reported — a fit on non-finite scores, and a Burch interval at MSA = 0 — and
accepts one thing it previously rejected, an `NA`-containing frame. The last of
those changes which `ci_method` values are reachable on such data, because the
phantom observed cell is gone: measured on a one-way frame with one `NA`,
`searle` and `burch` are now refused up front by their existing balance fence
(`intraclass_unsupported`) instead of aborting inside their extractors, and
`npbootstrap`, which supports unbalanced one-way data, returns an interval. That
is a truer answer in every case — the design really is unbalanced — but it is a
behavioural change and is what the amended M105 AC2 pins.
`DESIGN.md § Boundary-fit policy` gains a classical-family interval-time row
citing this entry as classed deferral (D-004 requires a superseding entry for any
change to a documented cell). **Untouched:** `searle` reporting `-Inf` at the
Spearman-Brown pole on the same data, and `npb_guard_sb_pole()` tolerating the
pole itself — both recorded as correct in place at `R/ci-npbootstrap.R:126` and
in-support for the projected form under D-010; reopening either supersedes D-010
and reaches all three methods sharing that guard (ROADMAP candidate).

### D-023 (2026-08-06): The dangling-id advisory's pre-migration hits are accepted noise, pending a plugin-side tolerance

**Context:** the 2026-08-06 /milestone audit reported `cairn_validate`'s
`dangling id tokens` advisory at 321 WARNs. Tallied by file, the hits are
citations of pre-migration ids (M1–M47), whose records are entombed in
`cairn/legacy/` (migration, 2026-07-12): `references/ORACLES.md` (145) cites
the milestone that established each oracle; the `estimand-specs/` files are
themselves named after pre-migration ids; `COVERAGE.md` (33) maps tests to the
milestones that added them. The check excludes the `legacy/` directory but
resolves ids only against live ROADMAP rows, milestone files, and D-entries,
so a migrated repo warns forever.
**Decision:** the pre-migration hits are accepted as expected noise. The
citing files are not rewritten — the citations are correct history, and
qualifying or stripping bare id tokens would damage the records they anchor.
The fix belongs in the plugin (a legacy-id tolerance in `check_dangling_ids`),
filed the same day as a candidate row in the cairn repo's ROADMAP. Until it
ships, an audit reading this advisory checks only for hits on post-migration
ids (M48+); this triage found none.
**Rejected:** editing the ~19 citing files to satisfy the advisory (damages
correct records); a repo-local suppression list (a second tracking surface and
a divergence vector).

### D-024 (2026-08-06): Oracle re-run divergence policy — pins are the bar; escalate, never re-baseline

*(This is this repo's own D-024, next in its local sequence after D-023. It is
distinct from the cairn plugin's D-024 — the upstream ORACLES.md-shape question
— which every repo-authored site cites qualified as "cairn D-024" (D-020
Amendments 3–4); PROFILE.md's one bare cross-reference was qualified in this
same milestone.)*

**Context:** D-008 fixed the M72 verification bar at *provenance* and left
reproducibility a standing, separately-plannable gap (PRINCIPLES.md #12). M107
re-runs seeded oracle scripts through a compare-don't-overwrite harness, and its
candidate row required deciding what a divergence from committed values means
*before* running, not after. M72 T4 is the cautionary instance: O-Bayes' prose
and fixture disagreed on every statistic, and a fresh run yields a third set of
numbers, not an adjudication.
**Decision:** For every harness re-run of a `data-raw/oracle-*.R` script,
current and future: (1) the script's qualitative pins — its `stopifnot`
published-findings blocks — are the reproducibility bar; a fresh run on which
every pin holds and whose compared values match the committed fixture to
roundoff is `reproduced` (fixture-writing scripts) or, with no fixture to
compare, `pins-pass`. (2) Numeric drift in a fixture-writing script's
statistics with all pins holding is recorded as `drift-within-noise` beside the run's
engine/package versions — a delta, never a failure. (3) A pin failure escalates
to the maintainer (`diverged-escalated` / `pins-fail-escalated`) and its
adjudication is sized as its own follow-on work; the re-run is never silently
repeated until green (GP5 — fix the evidence, never the bar). (4) A committed
fixture is never overwritten by a re-run; re-baselining — replacing committed
values with a fresh run's — happens only as the outcome of an escalation the
maintainer decides, recorded with its rationale.
**Consequences:** the M107 ledger's verdict vocabulary is this policy's
rendering; the 19 remaining `oracle-bayesian-*.R` re-runs (ROADMAP candidate)
inherit it; a maintainer-decided re-baseline supersedes nothing here — it is
the escalation path this entry itself provides. Decided at the M107 plan gate
(2026-08-06), the maintainer choosing escalate-never-re-baseline over
re-baseline-on-drift.

### D-025 (2026-08-07): oracle-bayesian.R k=2 divergence adjudicated — fixed warmup and an unseeded template were the causes; adaptive doubling + seeded template, fixture re-baselined (executes D-024 clauses 3–4)

*(This is this repo's own D-025, next in its local sequence after D-024. It is
distinct from the cairn plugin's D-025 — an upstream validation-doctrine id —
which every repo-authored site cites qualified as "cairn D-025" (D-020
Amendments 3–4); PROFILE.md's one such cross-reference is already qualified.
Bare `D-025` in this repo's files refers to this entry.)*

**Context:** The first M107 harness re-run of `data-raw/oracle-bayesian.R`
(2026-08-06) came back `diverged-escalated`: k=2 `converged_frac` .864 against
the pinned ≥ .90 floor (committed fixture .904), the three published-findings
pins holding. D-024 clause 3 sizes such an adjudication as its own work; M108
is that work, and its plan gate (2026-08-07) made the escalation decision.
**Decision:** Two measured attributions, two remedies, one re-baseline. (1) The
convergence shortfall is the script's fixed warmup budget, which had replaced
the source's adaptive protocol (ten Hove et al. 2020 §4.1.3): with per-rep
bounded adaptive warmup doubling (≤ 3 doublings, `iter = warmup + 1000`, refit
while R̂ ≥ 1.10 or bulk ESS ≤ 100), k=2 `converged_frac` is 1.000 on the same
seed stream (fixed-warmup: .864). Rejected: a larger fixed budget (re-fails at
the next engine upgrade) and lowering the .90 floor (moves the bar to fit the
evidence — GP5). (2) Mid-milestone, the post-remedy harness re-run diverged on
a different pin (the k=2 < k=5 coverage ordering), which probes attributed to
the script's unseeded base-template stage: `update()` refit draws depend on
the template fit, so every prior run — the committed fixture included — was an
unreproducible realization (the .864/.904/.924 historical spread). Remedy,
chosen at the 2026-08-07 amendment gate: seed the template stage
(`set.seed(base_seed)` before the template draw, Stan `seed` on the template
fit) and raise `n_rep` to 500. (3) The fixture is re-baselined to the
deterministic run under D-024 clause 4 (maintainer-decided): 4/4 pins, and the
harness re-run reproduces it at `max_abs_delta` 0 (`reproduced`, 4/4).
**Consequences:** the ≥ .90 convergence pin and every published-findings pin
stand unchanged; the 19 sibling `oracle-bayesian-*.R` scripts share the
unseeded-template pattern, so M109 inherits both remedies as precedent — a
sibling divergence is adjudicated, never batch-fixed, but the attribution here
is where its adjudication starts; the M107 ledger's `diverged-escalated` rows
for this script are closed by the 2026-08-07 `reproduced` row.

### D-026 (2026-08-08): M111 GO/NO-GO — fallback-on-abort default: NO-GO for both arms; the abort event is informative and the status-quo abort stands

**Context:** M111 assessed, against a pre-registered frozen criterion (GP5;
`cairn/references/fallback-on-abort-comparison.md`, F1–F6), whether the one-way
default should return a classical fallback interval — SEARLE exact-F or Burch
(2011) REML, the D-012 opt-in methods — where the MC default aborts classed
`intraclass_singular_fit`. This is the `#3`/ADR-003 contract question D-012
fenced out, D-013 restated, and D-018 licensed diagnostics for but not the
return. Evidence: a 64-cell sweep (ρ ∈ {0.05, 0.10, 0.30, 0.60} × 4 designs ×
{gaussian, t5, uniform, chisq1} per burch2011 Table 2; n_rep = 2000;
`data-raw/m111-fallback-results.rds`, rules ledger
`data-raw/m111-fallback-rules.rds`).

**Decision — NO-GO for both composite arms**, per the frozen aggregation rule
(neither passes every binding rule at every applicable cell; the decisive F3
failures are structural — conditional coverage 0.00–0.49 against the 0.93
floor — while F2 has 4 SEARLE / 5 Burch within-0.005 marginal fails among its
45/30):

- **The abort event is informative (the decisive finding, F3).** Aborts are not
  confined to the near-zero boundary (16–23% of reps at ρ = 0.30 in the 10×2
  design; 6–12% at ρ = 0.30 in 10×5 under t5/chisq1). An abort at an
  *informative* design — one whose classical interval is narrow — selects
  exactly the samples whose between-subject variance collapsed, and the
  fallback interval sits below the truth (every conditional miss upper-tail):
  conditional-on-abort coverage 0.00–0.49 at those cells (both arms). Burch
  covers 1.000 at the low-information abort cells — 28/29 at ρ ≤ 0.10 plus
  all four (0.30, 10, 2, ·) — but no shipped diagnostic can tell a user which
  case their abort is. A fixed fallback would hand users a confident interval
  precisely where the data are least representative.
- **F2/F5 corroborate:** unconditional composite coverage fails 45/64 (SEARLE)
  and 30/64 (Burch) cells, largely inherited from the MC leg the composite
  keeps.
- **The status-quo abort is vindicated off-boundary** (no assessed method
  covers conditionally there), and the boundary case is already served: the
  abort message names the applicable opt-in `ci_method` (M93/D-018), keeping
  the choice with the user.
- **Reopening evidence class (all-NO-GO clause):** a fallback construction
  that models the selection event itself (conditional-likelihood /
  post-selection inference) with demonstrated conditional coverage across this
  grid's ≥100-abort cells; or a user-facing need restricted to the
  low-information abort cells where Burch measured 1.000 (28/29 at ρ ≤ 0.10
  plus the four (0.30, 10, 2, ·) cells — the (0.10, 50, 5, chisq1) exception
  shows the boundary is informational, not a ρ threshold). Preference for "an
  interval instead of an error" alone does not reopen it.

**Fences unchanged:** the default stays the glmmTMB MC method (`#3`'s D-001
fence untouched — no default-method supersession); D-018's diagnostic-only
licence stands. Confirms D-012/D-013 and closes the question they fenced open.

**Consequences:** M111 ships no code. The MC default's own unconditional
under-coverage on skewed high-ρ data (0.67 at (0.60, k≥30, 5, chisq1), 0
aborts — an incumbent defect this sweep surfaced, not part of this verdict)
becomes a ROADMAP candidate row. O-Classical-OW is unchanged (the M76
prototypes were reused as-is).

### D-027 (2026-08-08): M113 S1/S2 verdict — no classical replacement (both arms no-GO on the wider battery); the MC incumbent's disposition is warn

**Context:** M113 read the committed M111 per-rep fixture
(`data-raw/m111-fallback-results.rds`) against the pre-registered S1/S2
disposition rules (GP5; `cairn/references/mc-skew-response-comparison.md`,
frozen 2026-08-08 before the derivation artifact; derived table
`data-raw/m113-skew-response-coverage.tsv`, 64 cells × 3 legs, n_rep = 2000).
This executes the response question D-026 spun out: whether the one-way MC
default's measured skew under-coverage should be met by replacement, a
runtime warning, documentation, or nothing.

**Decision:**

- **S1 `searle`: no-GO.** 21/64 cells below the 0.93 unconditional floor,
  worst 0.674 at (ρ = 0.60, k = 50, n = 5, chisq1).
- **S1 `burch`: no-GO.** 16/64 cells below, worst 0.6655 at
  (0.60, 30, 5, chisq1), including one gaussian cell (0.9285 at
  (0.60, 10, 2)). M76's "never under-covers" verdict does not extend to the
  wider battery the D-012 scope fence named — that fence was warranted.
- **S2 `mc`: warn.** 36/64 cells below the floor among non-aborted reps.
  By abort rate the failing set partitions into: skew/kurtosis
  under-coverage at low-abort cells (10 cells, abort rate ≤ 0.1, all
  t5/chisq1, five zero-abort; worst 0.6725/0.676 at ρ = 0.60 chisq1) — the
  defect that motivated M113 — and selection-conditioned under-coverage at
  high-abort cells (26 cells, abort rate > 0.1), consistent with D-026's
  abort-is-informative finding. Every failing gaussian/uniform cell is in
  the high-abort bucket; the warn fires on the ≥ 2-families limb via the
  low-abort t5 + chisq1 cells.
- The warn commissions a follow-on milestone to design the runtime trigger
  (ROADMAP candidate row added by M113); per the frozen rule it degrades to
  `document` there, recorded in its own D-entry, if no reliable trigger
  exists. No shipped skew diagnostic exists today; Burch's kurtosis
  `burch_kappa_hat()` is the nearest precedent.
- **No default-method change:** nothing cleared S1, so the D-001 fence is
  untouched and no supersession arises.

**Consequences:** M113 ships no code. Reopening evidence class: S1 replacement
reopens only on a method demonstrating every-cell floor coverage over this
grid (or a superseding frozen assessment); the abort-side selection
phenomenon belongs to D-026's reopening class, not this one.

### D-028 (2026-08-08): M114 warn-trigger verdict — degrade to `document`; no candidate in the frozen family met the frozen floors

**Context:** M113's S2 `warn` disposition (D-027) commissioned runtime-trigger
design, degrading to `document` — with its own D-entry — if no reliable
trigger exists. M114 froze (GP5; `cairn/references/mc-skew-warn-trigger.md`,
committed before any derivation artifact) a closed 48-candidate family —
κ̂_bc (the shipped `burch_kappa_hat()`/`burch_kappa_bc()`) and the skewness
analog γ̂ on the same z-decomposition, forms K(c_k) / S(c_g) / K∨S —
severity-tiered binding floors (W1: fire ≥ 0.90 at targeted cells with
non-abort coverage < 0.80; W2: ≥ 0.50 at 0.80–0.93; W3: ≤ 0.10 at protected
gaussian cells; implement gate 2026-08-08), a mechanical selection ordering,
and a 10-cell held-out battery (lognormal/laplace/gaussian, ids 65–74,
n_rep = 1000, (20, 3) off the M111 geometry set — GP6). Evidence: per-rep
statistics over the seed-regenerated M111 fixture (identity proof:
128000/128000 regenerated SEARLE endpoints matched the stored ones within
1e-12) plus the held-out sweep — `data-raw/m114-warn-trigger-stats.tsv`,
ledgers `m114-warn-trigger-candidates.tsv` / `m114-warn-trigger-verdict.tsv`.

**Decision — degrade.** The bounded finding: no candidate in the frozen
family met the frozen floors/ceilings on the derived tables. 0/48 candidates
pass W1, 0/48 pass W2 (28/48 pass W3 alone); the best minimum targeted-cell
fire rate is 0.1625 against the 0.90/0.50 floors — not a near-miss anywhere
in the ledger. Measured cause: the Burch z-decomposition pools all k·n
values, so at n = 5 the cluster effect carries ~20% of z's variance and its
kurtosis enters at weight² ≈ 0.04 — at the worst cell (chisq1 cluster
kurtosis 12, non-abort coverage 0.6725) κ̂_bc's distribution (median 0.11,
spread ≈ 0.35) barely separates from gaussian's (median −0.03). The failure
is dilution, not threshold placement.

**The MC default's skew response is therefore `document`:** a documentation
caveat naming the measured failure surface — heavy-tailed or skewed subject
(cluster) effects at moderate-to-high ρ under-cover, and both classical
opt-ins fail the same cells (D-027 S1) — shipped by the response milestone
(candidate row added by M114). No runtime warning ships; no default-method
change arises (D-001 fence untouched).

**Reopening evidence class:** a frozen assessment of a statistic family that
measures the cluster effect *directly* (moments of subject means or
predicted cluster effects, standardized within-design) meeting these floors
— promote on such a design, never on re-thresholding this family.

**Consequences:** M114 ships no code. D-027's warn → document transition is
executed by its own frozen rule; the S2 disposition chain closes here.

### D-012 Amendment 1 (2026-08-09): two of D-012's width clauses are wrong against its own sweep — corrected, verdict untouched

**Context:** D-012's ledger states, of SEARLE, "Best-calibrated + narrowest when
data are ≈ normal", and of Burch, "The robust / guaranteed-coverage choice,
bought with width". M116 recomputed widths from the very fixture D-012 was
decided on, `data-raw/m76-sweep-results.rds`, and both clauses fail on it:
Burch's median width is **below** SEARLE's in **16 of 16 cells, 8 of 8 gaussian
among them**, by 2–10%. Neither method aborts anywhere in that grid, so the two
legs' medians are computed over the same replicates and compare directly. The
wider M113 grid agrees — Burch narrower in 59 of 64 cells, and in every
distribution family separately (gaussian 14/16, uniform 16/16, t5 15/16,
chisq1 14/16), with no family reversing. Nor does any source support the
withdrawn wording: Searle (1971) makes no interval-length claim about the
Table 9.14 intervals, McGraw & Wong (1996) uses no length vocabulary at all, and
Burch (2011) eq. 18 compares against **this same exact-F interval** and reports
the opposite direction for platykurtic data.

The error is a misread of D-012's own C3 criterion, which compares each
classical method **to the MC default**, not to each other. Both classical
methods are wider than MC at the n=2 cells; "bought with width" is true of that
comparison and was carried across to a searle-vs-burch comparison the sweep
never made. The shipped documentation inherited it and stated it for three
milestones.

**Decision:** both clauses are corrected as follows, and **only** those clauses.
SEARLE reads "Best-calibrated when data are ≈ normal", with no width claim.
Burch reads "The robust / guaranteed-coverage choice; wider than the MC default
at n=2, and — measured at M116 — narrower than SEARLE in every cell of this
grid". D-012's GO/NO-GO verdict, its scope fence and its opt-in recommendation
are untouched: they rest on coverage, tail symmetry and abort behaviour, none of
which this amendment disturbs. The coverage-based preference for `"searle"`
(D-027/M115) likewise stands.

**Consequences:** `cairn/references/classical-oneway-comparison.md` is corrected
wherever the direction appears — the C3 narrative, the ledger table and the
Disposition — under a dated observation. Reopening needs a measurement, not a
re-reading: a grid on which Burch's median width exceeds SEARLE's. Burch's own
leptokurtic reversal is the likeliest place to find one, and it is untested here
because both repo grids draw only the subject effect from the non-normal family
(ROADMAP candidate).

### D-029 (2026-08-09): D-021's door is about records apparatus, not about correcting what the package tells its users

**Context:** D-021 bars planning a milestone "whose deliverable is verification
of this repo's own records, prose or messages … unless its trigger is a defect
in what the package computes", and adds that "a false or unbacked claim in a
record is corrected in place, in the milestone that finds it, and never promoted
into a milestone of its own". Read at its widest, that bars M116, whose
deliverable is a correction to `?icc`, two vignettes, NEWS and a runtime
message. Read at its narrowest it does not reach M116 at all. The question has
now come up twice — M115 shipped this same class on 2026-08-08, five days after
D-021, without the tension being recorded — so it is settled here rather than
re-litigated at the next plan gate.

**Decision:** D-021 governs **records-verification apparatus** — a ledger over
tracking figures, a guard over doc claims, a truthfulness audit, the M94–M102
class it was written against. It does **not** govern correcting a false
statement the package makes to its users in shipped documentation or a runtime
message. Three reasons. The subject differs: tracking prose is read by us, `?icc`
and a `cli` hint are read by users, and D-021's own carve-out names "a wrong
exported behaviour", which a hint recommending a method on a false basis is.
The self-feeding property D-021 was written to stop does not apply: user-facing
surfaces are a bounded, enumerable set, where the apparatus class "never runs
out of subject matter". And the correct-in-place clause presumes the finding is
cheap to action in the milestone that found it; where it is not — M115 found
this one and deferred it precisely because the provenance question needed three
sources read, one of them a book not then on the shelf — a milestone is the
honest vehicle.

**Consequences:** a scope whose deliverable is a user-facing documentation or
message correction plans normally, and D-021 is not quoted at it. A scope whose
deliverable is a checker, ledger or audit over the repo's own records still
needs D-021's trigger; M116 accordingly ships **no** new doc-claim checker, and
extends M115's existing test rather than authoring a second instrument. If this
distinction is ever used to smuggle apparatus in as "documentation", this is the
entry to supersede.

### D-030 (2026-08-13): M118 verdict — Burch's leptokurtic width reversal reproduces on a both-components grid; `D-012 Amendment 1`'s reopening condition is met, and its own wording stands

**Context:** `D-012 Amendment 1` corrected three milestones' worth of shipped
documentation that called `"burch"` the wider of the two classical one-way
intervals — on both committed grids it is the narrower one, in 16 of 16 and 59
of 64 cells — and set its reopening condition as "a grid on which Burch's median
width exceeds SEARLE's", naming Burch's own symmetric-leptokurtic reversal as the
likeliest place to find one. That reversal was untested here because both grids
draw only the subject effect from the non-Gaussian family and always draw the
residual from a normal. M118 built the missing grid: both `A_i` and `e_ij` drawn
from the cell's family, located and scaled per burch2011 §3 (p. 1022), at Burch's
own Fig. 2 geometry (`n = 5`, `k = 10(10)100`, `rho = 0.5`) over the six
symmetric Table 2 families, `n_rep = 2000`. Rules W1–W3 were frozen before any
derivation artifact (GP5; `cairn/references/classical-width-reversal-comparison.md`,
committed ahead of every derivation artifact -- one commit ahead of the sweep
script, three ahead of the results).

**Decision — W1, `reproduced`.** Both limbs hold at 10 of 10 subject counts, so
the ≥ 7-of-10 bar was never close and W2/W3 do not arise. Median
`"burch"`/`"searle"` length ratio, per symmetric family, at `k = 10` / `k = 100`:

- **Heavy-tailed limb (ratio > 1 required).** t(10) 1.004 / 1.080; Laplace(0,1)
  1.096 / 1.300; t(5) 1.065 / 1.296. Above 1 at every subject count in all three.
- **Light-tailed limb (ratio < 1 required).** Uniform(0,1) 0.917 / 0.898; Power
  exponential(0,1,2.78) 0.947 / 0.951. Below 1 at every subject count in both.
- **Normal(0,1)**, descriptive and binding neither limb: 0.973 / 0.996, below 1
  throughout. So the sign change falls between excess kurtosis 0.0 and 1.0 — the
  crossing the frozen priors flagged in advance as the demanding part of the
  rule, since the repo's existing grids put the gaussian ratio below 1.

Both validation preconditions cleared first. Against burch2011 (p. 1027) the
anchor cell returned a mean length ratio of 0.8807 against the printed 0.88, with
coverages 0.9600 and 0.9790 against 0.95 and 0.97. Against the committed
`data-raw/m111-fallback-results.rds`, the 16 gaussian cells agree to within 1.68
two-sample bootstrap SEs, which is also the only test of the plan gate's choice
of the shipped reducers over the M76/M111 prototypes.

**What this does and does not disturb.** `D-012 Amendment 1`'s reopening
condition is **met**, but its corrected wording is scoped to the M76 grid
("narrower than SEARLE in every cell of this grid") and stays true of it —
that ledger clause is not falsified and it is not superseded. Its closing
sentence is a different matter: "it is untested here because both repo grids
draw only the subject effect from the non-normal family" is a repo-state claim,
and this grid is what answers it -- so that clause is spent, and this entry is
where a reader is told so. What this grid also falsifies is the *bound* the
shipped documentation puts on the finding: the sites matched by a
whitespace-collapsed search of `R/`, `vignettes/`, `NEWS.md` and `man/` for the
residual-invariance claim still tell users that no measured grid varies the
residual. M119 restates them, and decides that set by a walk rather than by any
list -- including this one.

Per the frozen consequence clause, identical under all three tags, no method
recommendation, default or `ci_method` behaviour changes on this evidence, and
the coverage-based preference for `"searle"` is untouched -- that preference
rests on coverage, which this milestone measured but did not put under any rule.
(That preference is M115's, recorded in its archive summary; D-012 Amendment 1's
parenthetical "(D-027/M115)" has been read here before as though D-027 carried
it, and it does not -- D-027 records both classical arms no-GO and states no
preference between them.)
Coverage does corroborate Burch's stated rationale rather than undercut it: at
Laplace and t(5) `"searle"` falls to 0.831–0.883 and 0.825–0.893 while `"burch"`
holds 0.907–0.941 and 0.906–0.932, so the extra width buys coverage where the
tails are heavy enough to cost `"searle"` any. At t(10) the two are comparable
(0.904–0.940 against 0.924–0.947), so this is a gradient, not a cliff.

**Scope fence.** Symmetric families only. The five asymmetric burch2011 Table 2
families were dropped at the M118 plan gate rather than deferred, and no
skewed-family claim is made here; `chisq1` appears in the comparison block only.
The crossing point in excess kurtosis is bracketed between 0.0 and 1.0 and not
resolved. Reopening either needs a superseding frozen assessment.

**Consequences:** M118 ships no package code. `cairn/references/burch2011.md`
and `data-raw/m116-classical-width-comparison.R` are corrected in place where
they said this condition was untested in the repo; `cairn/references/INDEX.md`
likewise. M119 carries the user-facing correction. It answers the question
`D-012 Amendment 1` left open. It does **not** discharge D-012's original scope
fence, which named a different gap -- "platykurtic + skewed, Table 2" families
and larger rho. This grid does add platykurtic families (uniform, power
exponential) and does reach rho = 0.60, so it is not the grid's design that
leaves that fence standing: it is that M118 makes no replacement verdict at all
and no skewed-family disposition, which is what discharging the fence would
require. The both-components condition was first named by Amendment 1, not by
D-012.

### D-031 (2026-08-15): M121 N1 verdict — `npbootstrap` no-GO on the skew grid; its failures are shallow and abort-free, and D-027's S1 reopening condition is not met

**Context:** M121 measured `ci_method = "npbootstrap"` on the same 64-cell
one-way skew grid D-027 judged the `mc`, `searle` and `burch` legs on, against
rule N1 (GP5; `cairn/references/npbootstrap-skew-response-comparison.md`, frozen
2026-08-15 before the harness existed). The M111 fixture holds no npbootstrap
leg, so `data-raw/m121-npbootstrap-skew-sweep.R` regenerated every replicate from
M111's recorded seeds — 512,000 endpoints reproduced exactly — and added the
fourth leg. Derived table `data-raw/m121-npbootstrap-skew-coverage.tsv` (64 cells
× 4 legs, n_rep = 2000, boot_samples = 999). The run is gated on reproducing the
ukoumunne2003 Table I anchors: 0.9375 / 0.9355 / 0.9425 at k = 10 / 30 / 50
against 0.938 / 0.944 / 0.9395, worst |delta| 0.0085 of the pre-registered
±0.03, and exactly 0 against the committed oracle fixture.

**Decision:**

- **N1 `npbootstrap`: no-GO.** 26/64 cells below the 0.93 `coverage_uncond`
  floor, worst 0.8730 at (ρ = 0.60, k = 10, n = 5, chisq1); grid range
  0.8730–0.9555.
- **The abort-rate partition is empty on one side.** No classed `intraclass_*`
  condition was signalled on any of the 128,000 replicates, so every cell's
  abort rate is 0: all 26 failing cells sit in the ≤ 0.1 part, the > 0.1 part is
  empty, and `coverage_nonabort` equals `coverage_uncond` everywhere. D-026's
  selection effect explains none of these: on this same `coverage_uncond`
  column the `mc` leg has 31 of its 49 failures above that 0.1 abort boundary
  (D-027 states the phenomenon on its own column, as 26 of the 36 cells failing
  `coverage_nonabort`).
- **Failures span every generator family**: chisq1 11/16, t5 8/16, uniform 4/16,
  gaussian 3/16; 16 of the 26 at k = 10. Within chisq1 the failure deepens with
  ρ (0.9260–0.9425 at ρ = 0.05 down to 0.8730–0.9040 at ρ = 0.60).
- **Shallowest failures of the four legs, not the fewest.** On the same grid and
  column: `mc` 49/64 (worst 0.3935), `searle` 21/64 (0.674), `burch` 16/64
  (0.6655), `npbootstrap` 26/64 (0.873). It fails more cells than either
  classical leg while its worst cell still covers 0.873. Width, descriptive:
  median ratio 1.047 vs the `mc` leg (range 0.718–1.720), running widest on
  chisq1 (1.355) where the incumbent fails worst.
- **D-027's S1 reopening condition is NOT met.** That condition is a method
  demonstrating every-cell floor coverage over this grid; 26 cells sit below the
  floor, so the classical-replacement question stays closed on D-027's evidence.
- **No default-method change:** nothing cleared N1, so the D-001 fence is
  untouched and no supersession arises.

**Consequences:** M121 ships no exported code. Whether a leg that fails 26 cells
at a worst of 0.873 with no aborts warrants any user-facing wording is
deliberately not decided here — that is the M113 → M115 shape and needs its own
milestone. Reopening evidence class: this verdict reopens only on a method
demonstrating every-cell floor coverage over this grid, or on a superseding
frozen assessment of it; the zero-abort finding belongs to no reopening class of
D-026's, which concerns the abort event this leg does not produce.

### D-032 (2026-08-17): D-021's door does not reach cap-driven hygiene compression of the tracking files themselves

**Context:** the 2026-08-17 audit pass measured `cairn/ROADMAP.md` at 33,752
bytes against a 24,000-byte budget and `cairn/LESSONS.md` at 35,296 against
20,000. The remedies the tracking rulebook names for an over-budget file —
compress the widest rows, then graduate or prune candidates; retire or prune
lessons by the three exits — are edits to the repo's own records, so the
question is whether D-021 bars a milestone that performs them. D-021 bars
planning a milestone "whose deliverable is verification of this repo's own
records, prose or messages — a ledger over tracking figures, a guard over doc
claims, a truthfulness audit — unless its trigger is a defect in what the
package computes for its users". D-029 already narrowed that door once, holding
it governs "records-verification apparatus" and not the correction of what the
package tells its users. This is a third shape neither entry addressed, and it
will recur at every hygiene pass, so it is settled here rather than
re-litigated.

**Decision:** D-021 does not reach a scope whose deliverable is bringing a
tracking file back under a budget the rulebook itself imposes. Three reasons.
The deliverable is deletion and compression, not verification: such a milestone
builds no checker, no ledger and no audit, which is the apparatus class D-029
says D-021 governs. The self-feeding property D-021 was written to stop does not
apply, because the trigger is a measured byte count against a fixed cap — it
goes away when the file is under budget and cannot generate fresh subject matter
the way a prose repair generates a new claim. And the alternative is worse than
the disease: the caps exist because these files are read at every plan gate, so
a door that forbids ever enforcing them makes the rulebook's own weight caps
unenforceable.

**Consequences:** M125 plans normally under this entry. A hygiene scope that
also proposes a checker over the records it compresses is outside this entry and
still needs D-021's trigger. If this distinction is ever used to smuggle
apparatus in as "hygiene", this is the entry to supersede.

### D-033 (2026-08-17): `cairn/doctrine/` is a records home for graduated lesson families; GP8/GP9 join DESIGN.md

**Context.** M125 graduated five stabilized `cairn/LESSONS.md` families under
the maturation exit: two as DESIGN.md principles (GP8 — state a verified set
procedurally; GP9 — exercise a degenerate guard at the reducer, assert the rule
not the platform's arithmetic), three as pages under a new `cairn/doctrine/`
directory.

**Decision.** `cairn/doctrine/` is the home for doctrine modules — transferable
craft graduated whole from `cairn/LESSONS.md` — distinct from `references/`
(source and synthesis notes about external sources) and claiming no other
file's ownership; each page opens by naming its own scope and is current
knowledge, corrected in place. GP8/GP9 join the DESIGN.md guiding-principle
set. D-001's enumeration (IP1–IP3 / GP1–GP7) records the interview-derived set
as of 2026-07-12 and is not falsified by later graduations.

**Consequences.** Future maturation exits may graduate a family into
`cairn/doctrine/`; the DESIGN.md § Design Principles preamble names both
lineages.

### D-034 (2026-08-23): `cairn/doctrine/` also admits a standard authored directly

**Context.** D-033 defined `cairn/doctrine/` as the home for transferable craft
*graduated whole from `cairn/LESSONS.md`*. M134 authored `prose-style.md`
fresh — no LESSONS family graduated into it; the closest lineage (the M72/M128
prose-widening family, covering R6 alone) is still live in `LESSONS.md`. Adding
`prose-style.md` to `DESIGN.md`'s registry under D-033's graduation clause
therefore asserted a lineage that does not exist (M134 third-pass finding 4).

**Decision.** A doctrine module may enter `cairn/doctrine/` either by
graduation from `cairn/LESSONS.md` or by being authored directly as a standard
the repo will hold work to. The rest of D-033 stands: doctrine modules are
transferable craft, distinct from `references/`, claiming no other file's
ownership, each page naming its own scope and corrected in place.

**Consequences.** `DESIGN.md`'s registry line names the directory without
asserting graduation. A directly-authored module carries no `LESSONS.md`
lineage to retire, so no maturation exit is owed for it.

### D-035 (2026-08-25): the v0.1.0 exported contract — what of the `icc` object is public, and vector-valued arguments are report-all only

**Context.** M48's last-call audit of the exported surface went to an
independent review (RB04/RR04) because GP2's one-way door closes at
submission. The review found the surface sound but named two ambiguities the
release would freeze: `icc()` carried two *kinds* of vector-valued default in
one signature — `type`/`unit`/`level` meaning "report every value", and
`raters`/`posterior_summary` being match.arg-style choice lists — so an
explicit `raters = c("random", "fixed")` was accepted and silently reduced to
`"random"`; and the fitted `icc` object's list interior was never declared
public or internal, so releasing it would make every element a de facto
contract.

**Decision.** (1) A vector-valued argument default in the exported signature
means report-all, and nothing else: `raters` and `posterior_summary` take
scalar defaults, and a choice argument given more than one value aborts
classed rather than selecting the first. (2) The `icc` object's public surface
is what `tidy()`, `glance()`, `summary()` and `print()` return, plus `$fit`
and `$call`; the rest of the list is internal and may change without a
deprecation cycle. Both are stated in the exported documentation before
submission.

**Consequences.** `validate_choice()`'s accept-the-full-choice-list shortcut
is removed, so an explicit multi-value choice argument now fails loudly (#5)
instead of collapsing. Identifier columns in `tidy()` output are always
present, NA where inapplicable, which is what lets the roadmap's deferred
extensions fill cells rather than change the schema. Reopening either clause
after v0.1.0 is a breaking change under the deprecation cycle, not an
amendment.

### D-036 (2026-08-25): D-035 clause 1 annotated — a scalar default does not make an argument a choice argument; `occasions` is the fourth report-all axis

**Context.** D-035 clause 1 states the rule as a property of the *default*: a
vector-valued default in the exported signature means report-all, and a choice
argument given more than one value aborts classed. Its context paragraph names
`type`/`unit`/`level` as the report-all set. M48's review found a fourth
argument the rule does not classify: `occasions` defaults to a single value but
accepts both of its values and reports a curve for each, so reading clause 1
off the default alone puts it on the wrong side. The release documentation and
the `validate_choice()` comment had both inherited the three-item enumeration
and told users that passing two occasions aborts, which it does not.

**Decision.** The discriminator in D-035 clause 1 is whether the argument is
routed through `validate_choice()`, not what shape its default has. The
report-all axes at v0.1.0 are `type`, `unit`, `level` and `occasions`; the
choice arguments are `raters`, `posterior_summary`, `model`, `engine`,
`ci_method` and `autoplot()`'s `what`. D-035 clause 1 stands unchanged as a
rule; this entry fixes which arguments it puts on each side, and the
enumeration in D-035's context paragraph is superseded by the one here.

**Consequences.** `occasions` keeps its scalar default and its acceptance of
both values, so no exported behaviour changes. What changes is the record and
the user-facing text: NEWS and the `validate_choice()` comment now name four
report-all axes. A future argument joins the report-all set by not being routed
through `validate_choice()`, whatever its default looks like, and adding one
after v0.1.0 is additive rather than breaking.

### D-037 (2026-08-25): D-036's argument classification is per function x argument, not per argument name

**Context.** D-036 fixed which arguments D-035 clause 1 puts on each side by
enumerating them by name: `type`, `unit`, `level` and `occasions` report all,
`raters`, `posterior_summary`, `model`, `engine` and `autoplot()`'s `what` are
choice arguments. `choose_icc()` breaks that enumeration. It routes all five of
its answer arguments — `model`, `unit`, `type`, `raters`, `level`
(`R/choose-icc.R:277,306,313,320,325`) — through `validate_choice()`, so three
names land on both sides of D-036's own discriminator. M48's review found the
consequence in the release text: NEWS tells users `type`, `unit` and `level` are
"unaffected", which is false of the chooser, where
`choose_icc(type = c("agreement", "consistency"))` returned the agreement
recommendation before v0.1.0 and aborts classed now.

**Decision.** The unit of classification is the (function, argument) pair, not
the argument name. D-036's discriminator — routed through `validate_choice()` or
not — stands unchanged and settles every pair on its own. At v0.1.0: in `icc()`
and `d_study()` the report-all axes are `type`, `unit`, `level` and `occasions`;
in `choose_icc()` every answer argument is a choice argument, the chooser asking
one question at a time by design; the remaining choice arguments are `raters`,
`posterior_summary`, `model`, `engine`, `ci_method` and `autoplot()`'s `what`.
D-036's enumeration is superseded by this one; its rule is not.

**Consequences.** One shipped behaviour change is now on the record rather than
silent: `choose_icc()` given the exact full choice list for `model`, `unit`,
`type`, `raters` or `level` aborts `intraclass_error` where `origin/main`
returned the first value. The blast radius is exactly that — `origin/main`'s
shortcut was `identical(value, choices)`, so a partial multi-value already
aborted. NEWS names the chooser in the covered set and scopes the "unaffected"
sentence to `icc()`/`d_study()`, and a test pins the abort on all five
arguments. A future argument is classified by asking whether its own function
routes it through `validate_choice()`.

### D-038 (2026-08-26): `glance()`'s v0.1.0 column set — the rater treatment and the replicate flag are columns, `type` is not, column order is not contract, and `tidy()$occasions` is double everywhere

**Context.** GP2 makes the v0.1.0 exported surface a one-way door: after the
CRAN submission, adding, removing or retyping a `tidy()`/`glance()` column costs
a deprecation cycle. M48 descoped three schema corrections for want of room.
M138 lands them while the door is open. D-035 fixed what of the `icc` object is
public and required every identifier column to be present on every fit, `NA`
where the design does not define it; D-037 fixed the report-all/choice
classification per (function, argument) pair.

**Decision.** `glance.icc()` gains exactly two columns.

1. `raters` — the fit's rater treatment as a character scalar, `NA_character_`
   on a `model = "oneway"` fit, whose raters are interchangeable and carry no
   facet. `glance()` on a `d_study()` projection reads the same way, so the
   column name means one thing across both exported tables. A multilevel
   Design 3 fit (`ml_design = "nested_in_subjects"`) has no rater component
   either but keeps its nominal `"random"`: the sibling `type` column reports
   `"agreement"` on that same row, where the agreement/consistency distinction
   is likewise undefined, so giving `raters` alone the `NA` treatment would
   split one column's convention from the other's. What the pair should report
   on Design 3 is a ROADMAP candidate row, promoted on a user reading either
   cell as a facet that exists.
2. `replicates` — a logical saying whether the design holds more than one rating
   per subject-by-rater cell. It is not recoverable from `n_o` beside it, which
   is `NA` on a ragged replicate design as well as on an unreplicated one.

**Refused: a `type` column on `glance()`.** `type` is a per-coefficient
report-all axis in `icc()` (D-037) and `tidy()` already carries it per row. A
one-row `glance()` would have to collapse a vector into one cell.
`glance.icc_dstudy()` does exactly that, and can only because a projection
carries one design.

**Column order is deliberately not contract.** `glance()`'s promise is the set
of names, not their positions; a consumer indexing it positionally is reading
something this package does not promise. Freezing order would make any later
reordering a deprecation-cycle item for no user-visible gain.

**`tidy()$occasions` is double on every fit and every projection.** It was
`integer` on an unreplicated fit and `double` on a replicated one, so its type
shifted with the design. Unifying on `integer` was rejected because `d_study()`
admits a non-integer occasion count on purpose, for symmetry with `m`
(`validate_n_o()`), and an integer column would report a projected 1.5 as 1.
Unifying on `double` costs nothing a caller can observe except that a
whole-number occasion count is stored as a double.

**Consequences.** Two new `glance()` columns, one retyped `tidy()` column, and
one changed `glance()` cell on a one-way projection — all inside the v0.1.0
window, so none is a deprecation-cycle item. `?icc`'s claim that `tidy()` and
`glance()` "return the same information" as the object is withdrawn: they are
the stable tables, not a re-export of the list. The probe set behind each of
these, and the two amendment audits that fixed the criteria stating them, are in
`cairn/milestones/M138-glance-schema-remainder.md`.

### D-039 (2026-08-26): the declared R floor is measured, not inferred — `R (>= 4.5.0)`, superseding the M48 review gate's decision to leave 4.0.0 untested

**Context.** GP3 says support commitments are exactly what CI verifies, and that
no declared floor goes untested. v0.1.0 declared `R (>= 4.0.0)`, inferred from
`rlang`'s own `Depends`, while CI's oldest job was `oldrel-1`. The M48 review
gate recorded that tension under DESIGN.md's Known issues rather than resolving
it, for this stated reason: "raising the declared floor to what CI tests would
turn away users whose R would in fact run the package, and pinning a CI job to
4.0.0 is new infrastructure inside a release round."

**What changed it.** M139 measured the floor instead of inferring it: the
package's `Depends`/`Imports`/`LinkingTo` chain and `R CMD check` were run on
each candidate R version on one fixed CI runner, with provisioning, install and
check recorded separately so a runner fact could not be read as a package fact.
The chain does not install on any release below 4.5.0 — `pbkrtest` declares
`R >= 4.2.0`, and below 4.5.0 `Deriv` fails to compile against an R internal it
uses. The per-version outcomes are recorded in
`cairn/milestones/M139-r-floor-ci-tested.md`.

That falsifies the premise the M48 gate reasoned from. Below 4.5.0 there are no
users whose R would in fact run the package: the install fails outright. The old
floor was not a generous promise, it was a false one.

**Decision.** `DESCRIPTION` declares `R (>= 4.5.0)` — a literal three-part
version, never a moving label — and `.github/workflows/check-standard.yaml` runs
`R CMD check` at exactly 4.5.0 on both the `push` and the `pull_request` event.
GP3's parenthetical states the matrix per event, and the Known-issues entry is
resolved.

**What this floor tracks.** 4.5.0 is set by the dependency chain
`glmmTMB` -> `pbkrtest` -> `doBy` -> `Deriv`, not by anything in this package's
own code. If those packages regain support for older R the floor can be
re-measured and lowered — by a fresh measurement and a new decision, never by
inference from a `Depends` field. A floor is only ever declared at a version CI
runs.

### D-040 (2026-08-26): D-037's report-all enumeration is corrected for `d_study()` — its vector-valued arguments are the projection axes `m` and `n_o`

**Context.** D-037 settled which arguments report every value and which take
exactly one, per (function, argument) pair, and named the report-all axes in
`icc()` and `d_study()` together as `type`, `unit`, `level` and `occasions`.
`d_study()`'s signature is `(x, m, n_o, conf_level, mc_samples, seed)`; it has
none of those four. The pairing reached the release text, which told users
those four arguments are "unaffected" in `d_study()` as well as in `icc()`.

**Decision.** D-037's rule — classification is per (function, argument) pair,
decided by whether that function routes the argument through
`validate_choice()` — stands unchanged, as does D-036's discriminator behind
it. Only D-037's `d_study()` enumeration is superseded: `d_study()` has no
report-all axis. Its vector-valued arguments are the two projection axes `m`
and `n_o` — numeric vectors that sweep a curve, not choice arguments selecting
one of a fixed set. They are mutually exclusive, and supplying both aborts
(`R/d-study.R:214-222`). D-037's `icc()` and `choose_icc()` clauses are
untouched; nothing has shown either wrong.

**Consequences.** `NEWS.md`'s "unaffected" sentence is scoped per function:
`icc()` keeps its four axes, `d_study()` names `m` and `n_o`. No shipped
behaviour changes — the abort on both axes and the numeric-vector validation
of `n_o` both predate this entry and are pinned in
`tests/testthat/test-d-study.R`. A future `d_study()` argument is classified
the way D-037 says: by asking whether `d_study()` itself routes it through
`validate_choice()`.

### D-041 (2026-08-27): `glance()$n_o` is `NA` on a replicated design missing a cell it defines, not only on a ragged one — superseding D-038 clause 2's enumeration

**Context.** D-038 clause 2 justified the new `replicates` column by saying
`n_o` "is `NA` on a ragged replicate design as well as on an unreplicated one".
That names two of the three shapes it is `NA` on, and reads — and has been read
— as the full list.

**Decision.** The condition under which `n_o` reports a number is *uniform and
complete*, not merely *unragged*. On the single-level path `replicates_uniform`
(`R/design.R:48-50`) requires all three of: some cell holds more than one
rating; every cell of the subject-by-rater grid is present
(`n_cells == ns * nr`); and every observed cell holds the same count. `n_o` is
that shared count when all three hold and `NA_integer_` otherwise
(`R/design.R:51`). On the multilevel path `multilevel_replicate_facts()`
(`R/design.R:215-228`) pairs equal counts across observed cells with the
design's own completeness notion — a full grid for a crossed design,
block-completeness for a nested one — applied to the de-replicated data. So
`n_o` is `NA` on a design whose observed cells all hold the same count but
which omits a cell it defines. D-038 clause 2's conclusion — that `replicates`
is not recoverable from `n_o` — is unaffected and stands; only its enumeration
of when `n_o` is `NA` is superseded. D-038 is not edited (IP4).

**Consequences.** Nothing in the shipped computation changes; this entry
corrects the record of what it already does. Every disposition of the
within-cell-replicate dispatch — the value `n_o` reports, the abort raised
instead, and the conditions signalled ahead of either — now lives as a
generated grid in `tests/testthat/test-n-o-disposition-grid.R`, which is where
a future change to the condition has to go to stay green. The case set, the
measurement behind it, and the planted defects that show the grid able to fail
are in `cairn/milestones/M141-n-o-disposition-grid.md`.

### D-042 (2026-08-27): Design 3's `glance()$raters` is `NA_character_` — superseding D-038 clause 1's Design 3 sentence

**Context.** D-038 clause 1 gave `glance()` a `raters` column, `NA` on a
one-way fit, and kept the nominal `"random"` on a multilevel Design 3 fit
(raters nested in subjects), which has no separable rater main effect either.
Its stated reason was symmetry with a sibling `type` cell reporting
`"agreement"` on that same row: giving `raters` alone the `NA` treatment would
split one column's convention from the other's. The remainder was left as a
ROADMAP candidate row, promoted on a user reading either cell as a facet that
exists.

**Decision.** `glance()$raters` is `NA_character_` on a fit whose
`design$ml_design` is `"nested_in_subjects"`, and on a `d_study()` projection
of such a fit. D-038 clause 1's Design 3 sentence is superseded; the rest of
D-038 stands.

**Why the deferral no longer holds.** The pair D-038 balanced does not exist.
D-038 itself refuses a `type` column on `glance()`, and `tidy()$type` already
reports `NA` on a Design 3 fit, so the split D-038 feared is the shipped state
and `raters` is severable from a sibling that is not there. The trigger is
GP2's one-way door closing at submission, in place of the candidate row's unmet
promotion condition: after v0.1.0 this cell costs a deprecation cycle to
change, while the row's condition can only be met once a user has already been
misled. The measurement behind the `tidy()$type` claim is in
`cairn/milestones/M143-design3-rater-facet.md`.

**Consequences.** One changed `glance()` cell on Design 3 fits and on their
`d_study()` projections, inside the v0.1.0 window, so not a deprecation-cycle
item; `tests/testthat/test-exported-contract.R` re-pins the projection cell.
The same milestone drops the treatment word from the Design 3 header
`format()` renders and replaces the absolute-agreement note `summary()` prints
there. Design 3's internal `design$type` and `design$model`, and its
`n_raters` count, are untouched and stay a candidate row: internal under D-035
clause 2, so changeable without a deprecation cycle.
