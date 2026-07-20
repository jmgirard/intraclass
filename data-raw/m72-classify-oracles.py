#!/usr/bin/env python3
"""Insert a per-entry **Kind:** bullet into ORACLES.md (M72 T2, bar per D-008).

Keyed by the entry's heading line number in the pre-edit file; inserted
immediately after the heading so a reader meets the kind at the entry.
"""
import io

PATH = "cairn/references/ORACLES.md"

# heading line number -> (kind, leg note)
KIND = {
    26:   ("source-traceable", "values are the Shrout & Fleiss (1979) published figures; no generating script"),
    61:   ("script-derived", "in-suite: mean squares recomputed with `stats::aov()` in the test file; derivation in `estimand-specs/M1-twoway-random-agreement.md` §6"),
    78:   ("script-derived", "in-suite: seeded simulation in the test file"),
    84:   ("script-derived", "`data-raw/oracle-fixed-vs-random.R`; no committed fixture and no `stopifnot` — see its status note"),
    100:  ("script-derived", "`data-raw/oracle-incomplete.R`; tolerance targets are computed, not literal"),
    124:  ("script-derived", "`data-raw/oracle-fixed-incomplete.R`, which carries hardcoded expected constants"),
    146:  ("mixed", "source leg: ten Hove Eqs. 12/13; script leg: `data-raw/oracle-d-study.R`"),
    200:  ("mixed", "source leg: ten Hove Table 3 (Design 1), transcribed verbatim; script leg: `data-raw/oracle-multilevel.R`"),
    229:  ("mixed", "source leg: ten Hove et al. (2022) Eq. 14; script leg: in-suite closed-form and seeded recovery"),
    243:  ("script-derived", "in-suite: `sim_replicates()` in the test file plus ANOVA MoM via `stats::aov`"),
    260:  ("mixed", "source leg: McGraw & Wong Case 3A and the SF labels; script leg: the four in-suite `sim_*()` generators"),
    292:  ("mixed", "source leg: the Shrout & Fleiss published ICC(1)/ICC(1,k); script leg: in-suite ANOVA, cross-engine, and seeded simulation"),
    314:  ("mixed", "source leg: Jorgensen (2021) Eq. 6, Lee & Vispoel (2024) Eqs. 8/25, Vispoel et al. (2022); script leg: `data-raw/oracle-sem.R`"),
    369:  ("script-derived", "in-suite: a direct `lme4::lmer` fit in the test file"),
    375:  ("mixed", "source leg: ten Hove et al. (2020) §4/§4.2 DGP and reproduced findings; script leg: `data-raw/oracle-bayesian.R` + committed fixture"),
    423:  ("mixed", "source leg: ten Hove et al. (2020) recipe and McGraw & Wong Case 3A; script leg: `data-raw/oracle-bayesian-fixed.R` + committed fixture"),
    460:  ("mixed", "source leg: ten Hove et al. (2022) Eqs. 12-13 / Table 3 and the (2020) recipe; script leg: `data-raw/oracle-bayesian-multilevel.R` + committed fixture"),
    494:  ("mixed", "source leg: ten Hove et al. (2022) Eqs. 8-11 / Table 3 and the (2020) recipe; script leg: `data-raw/oracle-bayesian-nested.R` + committed fixture"),
    531:  ("mixed", "source leg: SF / McGraw & Wong Case 1 and the ten Hove (2020) recipe; script leg: `data-raw/oracle-bayesian-oneway.R` + committed fixture"),
    569:  ("mixed", "source leg: ten Hove (2020) recipe + (2022) Design-1 estimands, McGraw & Wong Case 3A; script leg: `data-raw/oracle-bayesian-multilevel-fixed.R` + committed fixture"),
    592:  ("mixed", "source leg: ten Hove (2020) recipe + (2022) Design-2 estimands, McGraw & Wong Case 3A; script leg: `data-raw/oracle-bayesian-nested-fixed.R` + committed fixture"),
    626:  ("script-derived", "`data-raw/oracle-nested-fixed-interval.R` + committed fixture; the sources named are internal ADRs and a Fable review, not a published origin for the values"),
    660:  ("script-derived", "`data-raw/oracle-incomplete-fixed-nested.R` + committed fixture; McGraw-Wong appears only as a reduction tie-back, not the origin of a value here"),
    700:  ("script-derived", "`data-raw/oracle-fixed-cluster-level.R` + committed fixture; the cited specs are internal"),
    738:  ("mixed", "source leg: ten Hove et al. (2022) Eq. 14 and the (2020) recipe; script leg: `data-raw/oracle-bayesian-conflated.R` + committed fixture"),
    767:  ("mixed", "source leg: ten Hove (2020) recipe and the GT two-facet decomposition (Cronbach et al. 1972; Brennan 2001); script leg: `data-raw/oracle-bayesian-replicates.R` + committed fixture"),
    797:  ("mixed", "source leg: ten Hove et al. (2020) recipe/DGP - the entry states the ragged extension is **not** in the source; script leg: `data-raw/oracle-bayesian-incomplete.R` + committed fixture"),
    835:  ("mixed", "source leg: ten Hove (2022) Design-1 decomposition + (2020) recipe, ragged extension **not** in the source; script leg: `data-raw/oracle-bayesian-incomplete-multilevel.R` + committed fixture"),
    877:  ("mixed", "source leg: McGraw & Wong Case 3A and the ten Hove (2020) recipe, ragged extension **not** in the source; script leg: `data-raw/oracle-bayesian-incomplete-fixed.R` + committed fixture"),
    921:  ("mixed", "source leg: ten Hove (2022) Design-1 decomposition, McGraw & Wong Case 3A, (2020) recipe, ragged extension **not** in the source; script leg: `data-raw/oracle-bayesian-incomplete-fixed-multilevel.R` + committed fixture"),
    966:  ("mixed", "source leg: ten Hove (2022) Eqs. 8-11 / Table 3 middle + (2020) recipe, ragged extension **not** in the source; script leg: `data-raw/oracle-bayesian-incomplete-nested.R` + committed fixture"),
    1009: ("mixed", "source leg: ten Hove (2022) Eq. 11 / Table 3 right + (2020) recipe, ragged extension **not** in the source; script leg: `data-raw/oracle-bayesian-incomplete-nested-subjects.R` + committed fixture"),
    1062: ("mixed", "source leg: SF Case 1 / McGraw & Wong one-way + (2020) recipe, ragged extension **not** in the source; script leg: `data-raw/oracle-bayesian-incomplete-oneway.R` + committed fixture"),
    1099: ("mixed", "source leg: McGraw & Wong Case 3A theta-squared formula + the GT replicate decomposition + (2020) recipe; script leg: `data-raw/oracle-bayesian-fixed-replicates.R` + committed fixture"),
    1134: ("mixed", "source leg: ten Hove (2022) Table 3 + the GT replicate split + (2020) recipe; script leg: `data-raw/oracle-bayesian-multilevel-replicates.R` + committed fixture"),
    1175: ("source-traceable", "ten Hove et al. (2020) §3.3/§4.1/§4.2; the entry records no committed fixture and names no script"),
    1203: ("source-traceable", "ten Hove et al. (2020) §4.2, with `coda::HPDinterval` as an in-suite reference implementation; the entry records no committed fixture"),
    1229: ("source-traceable", "ten Hove et al. (2022) Eq. 13 / Table 3 and McGraw & Wong Case 3/3A; the entry records no committed fixture (reduction and containment run live under `skip_on_ci`)"),
    1253: ("mixed", "source leg: ten Hove et al. (2022) p. 6 and McGraw & Wong Case 3A; script leg: `data-raw/oracle-bayesian-incomplete-fixed-nested.R` + committed fixture"),
}

with io.open(PATH, encoding="utf-8") as fh:
    lines = fh.readlines()

# sanity: every keyed line must actually be a '### ' heading
bad = [n for n in KIND if not lines[n - 1].startswith("### ")]
if bad:
    raise SystemExit("not a heading line: %s" % bad)
headings = [i + 1 for i, ln in enumerate(lines) if ln.startswith("### ")]
if sorted(KIND) != headings:
    raise SystemExit(
        "heading set mismatch\n missing: %s\n extra: %s"
        % (sorted(set(headings) - set(KIND)), sorted(set(KIND) - set(headings)))
    )

out = []
for i, ln in enumerate(lines, start=1):
    out.append(ln)
    if i in KIND:
        kind, note = KIND[i]
        out.append("- **Kind:** %s (D-008) — %s.\n" % (kind, note))

with io.open(PATH, "w", encoding="utf-8") as fh:
    fh.writelines(out)

from collections import Counter
print("inserted %d Kind lines" % len(KIND))
print(Counter(k for k, _ in KIND.values()))
