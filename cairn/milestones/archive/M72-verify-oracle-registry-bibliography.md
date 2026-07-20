# M72: Verify the oracle registry and the bibliography

- **Status:** done · **PR:** [#78](https://github.com/jmgirard/intraclass/pull/78) · **Merged:** 2026-07-19 · **Depends on:** M70, M71

**Goal.** Apply a verification bar to `ORACLES.md` (39 entries) and `BIBLIOGRAPHY.md` (38) — the last two pages carrying an unverified extraction status after M69–M71 closed the source-note backlog.

**Outcome.** Both reach a dated-verified status, every registry entry carrying a `**Kind:**` bullet (mixed / script-derived / source-traceable) naming its assurance. Corrections, none touching an oracle value: the Shrout & Fleiss three-decimal attribution (Table 4, p. 424, prints two) across seven sites; a GENOVA mis-attribution conflating Vispoel et al. (2022) with Lee & Vispoel (2024); `tenhove2024`'s truncated title; five ten Hove (2020) citation defects; O-Bayes' prose disagreeing with its own committed fixture; and `xiao2009` as a second citekey-vs-issue-year case, falsifying INDEX's "only such case" claim. Unprinted issue numbers are annotated, not deleted.

**Key decisions.** D-008 — bar split by entry kind; a script-derived "verified" is a **provenance** claim, not a reproducibility one (seeded scripts not re-run; refused as multi-hour live-Stan work); Amendment 1 corrects its Context's fixture count. Off-shelf legs marked in place, never softened; three of four closed mid-milestone as the maintainer supplied PDFs, leaving Cronbach et al. (1972).

**Review.** 7/7 ACs on fresh evidence; `check()` 0/0/0; `cairn_validate` exit 0 with the `references staleness` WARN gone. Two of three lenses found nothing; the diff lens found 4 prose defects (95/80/92/85), all fixed — two being this milestone's own cited lessons (M70 counts, M71 overgeneralization) recurring in its own new prose.

**Left behind.** Candidates: complete the registry (M46/M47 cluster-`ck`, `O-SEM-ML*`, `O-Boot-DS`, `O-IDS`, `O-invariance` ship with no entry, contradicting its stated invariant); re-run the seeded scripts for reproducibility; acquire Cronbach et al. (1972), which also has no `BIBLIOGRAPHY.md` entry.
