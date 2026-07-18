# References index

One line per source summary in this directory. Cite `citekey (p. N)` from tests
and milestones; never restate a value here.

- [REFERENCES.md](REFERENCES.md) — the repo's bibliography **and oracle
  registry** (migrated from `project/REFERENCES.md`): every oracle value in the
  test suite traces to an entry here with provenance (a citation or a committed,
  seeded script). Primary sources include ten Hove, Jorgensen & van der Ark (2022)
  <doi:10.1037/met0000391>, Brennan (2001), and Shrout & Fleiss (1979).

- [sem-multilevel-pilot.md](sem-multilevel-pilot.md) — synthesis note (M53): the
  two-level lavaan mapping of the ten Hove (2022) Design-1 components, its
  sourcing status (none — D-005 parameterization), and the pilot ledger.

- [ukoumunne2003.md](ukoumunne2003.md) — source note (M62): the non-parametric
  bootstrap CI for the one-way ICC (subject-resample + `log F` variance-stabilizing
  transformed bootstrap-t + infinitesimal-jackknife SE); under-covers at k=10.

- [ohyama2025.md](ohyama2025.md) — synthesis/oracle note (M62): published coverage/
  width comparison of one-way-ICC CI methods (SEARLE/SMITH/NBOOT/REML/BETA);
  REML best, NBOOT slightly worse than SEARLE — the M62 NBOOT-prototype oracle.

<!-- pdf/ is gitignored; add <citekey>.md summaries here as sources are ingested -->
