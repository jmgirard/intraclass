# Constructed violation fixture (M102)

This file exists to be found. `data-raw/record-claims.tsv`'s
`no-citations-in-decisions` row certifies that a history record carries no
claim citation, and a certifying command that cannot be shown to fail
certifies nothing — so that row's `falsifier_command` points the same search
at this file, which does carry one, and the self-test requires the row's
expectation to fail against it.

Nothing else reads this file. It is deliberately outside the citation scope
the convention names, so the citation below resolves to no ledger row and is
never required to.

The constructed citation: [claim:constructed-violation]
