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
