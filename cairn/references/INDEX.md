# References index

One line per committed page in this directory. Cite `citekey (p. N)` from tests
and milestones; never restate a value here.

## Registry and bibliography

- [ORACLES.md](ORACLES.md) — the repo's **declared oracle-registry home**
  (D-007): 39 entries, each naming its oracle ID, type, asserting test, source,
  and provenance. Every oracle value in the test suite traces to an entry here.
- [BIBLIOGRAPHY.md](BIBLIOGRAPHY.md) — the bibliography (16 entries). Primary
  sources include ten Hove, Jorgensen & van der Ark (2022)
  <doi:10.1037/met0000391>, Brennan (2001), and Shrout & Fleiss (1979).
- [REFERENCES.md](REFERENCES.md) — 6-line pointer stub only; the pre-migration
  single page, kept so links from the entombed `cairn/legacy/`,
  `CLAUDE_CODE_KICKOFF.md`, and `data-raw/reviews/` documents still resolve.

## Source notes (`<citekey>.md`)

- [ukoumunne2003.md](ukoumunne2003.md) — source note (M62): the non-parametric
  bootstrap CI for the one-way ICC (subject-resample + `log F` variance-stabilizing
  transformed bootstrap-t + infinitesimal-jackknife SE); under-covers at k=10.

## Synthesis notes

- [sem-multilevel-pilot.md](sem-multilevel-pilot.md) — synthesis note (M53): the
  two-level lavaan mapping of the ten Hove (2022) Design-1 components, its
  sourcing status (none — D-005 parameterization), and the pilot ledger.

- [ohyama2025.md](ohyama2025.md) — synthesis/oracle note (M62): published coverage/
  width comparison of one-way-ICC CI methods (SEARLE/SMITH/NBOOT/REML/BETA);
  REML best, NBOOT slightly worse than SEARLE — the M62 NBOOT-prototype oracle.

- [npbootstrap-oneway-comparison.md](npbootstrap-oneway-comparison.md) — synthesis
  note (M62): the pre-registered "not worse" criterion + one-way cell grid, and
  the coverage/width results + GO/NO-GO verdict for the non-parametric
  bootstrap vs the incumbent MC / parametric-bootstrap intervals.

<!-- pdf/ is gitignored; add <citekey>.md source notes here as sources are
     ingested (M64: load-bearing; M65: interval methods; M66/M67: the shelf).
     Citekey convention: same-author-same-year takes a letter suffix ordered by
     issue — tenhove2025a (MBR 60(3)), tenhove2025b (MBR 60(5)). -->
