#!/usr/bin/env python3
"""Re-derive which data-raw checkers carry a `--self-test` (M120).

Registered as the ledger row `checker-self-test-status`. The row states, and
this script settles, which checkers probe themselves by planting mutations and
which do not.

WHY A SCRIPT AND NOT A SENTENCE
-------------------------------
"Every checker self-tests" was believed here and was false:
`check-abort-remedy-verdicts.R` parses no arguments at all, so it ACCEPTS
`--self-test` and exits 0 having planted nothing. A reader running it sees a
zero exit and a full ledger of output, which is indistinguishable from a
self-test that passed. Pinning the per-checker verdict makes that difference a
committed claim rather than an impression.

WHAT THIS TEST IS, AND WHAT IT IS NOT
-------------------------------------
It is a source-text test: a checker is credited with a self-test when its own
source contains the literal `--self-test`, which is the flag it would have to
name in order to branch on it. That discriminates every checker here today --
the five that self-test all name the flag, the one that does not names nothing.

It is NOT a test that the self-test works, or that it plants anything. A file
could name the flag and do nothing with it, and this script would credit it.
What backs the stronger claim is running each self-test: each prints one PASS
line per planted mutation, so its coverage is counted rather than asserted.
"""

import pathlib
import sys

FLAG = "--self-test"


def verdicts(root=pathlib.Path(".")):
    paths = sorted(
        set(root.glob("data-raw/check-*.R")) | set(root.glob("data-raw/check-*.py")),
        key=lambda p: p.name,
    )
    out = []
    for p in paths:
        has = FLAG in p.read_text(encoding="utf-8", errors="replace")
        out.append(f"{p.name} {'has-self-test' if has else 'no-self-test'}")
    return out


def main():
    lines = verdicts()
    if not lines:
        print("no data-raw checkers found", file=sys.stderr)
        return 1
    for line in lines:
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
