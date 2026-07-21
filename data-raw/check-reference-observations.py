#!/usr/bin/env python3
"""Re-settle every dated observation in the references corpus (M73, D-009).

A committed `cairn/references/` page makes two kinds of claim: standing facts
about a *source*, and dated observations about the *repo's own state* ("nothing
reads this page", "not a dependency"). D-009 requires every repo-state
observation to carry, on the same line as its `— observed YYYY-MM-DD` stamp, an
exit-coded settling directive:

    <!-- check: <shell command> -->

written so that **exit status 0 means the claim holds** and any nonzero exit
means it is falsified (grep-negation idiom: `! git grep -qlF 'citekey' -- <paths>`).
A claim no command can settle carries `<!-- check: none — <reason> -->`.
Provenance extraction-statuses (any line containing `Extraction:`) are exempt
and excluded from the parse — they are settled by a human re-read, governed by
the re-verification convention and `cairn_validate`'s `references staleness`
advisory, not by a command.

This script parses the corpus, requires each in-scope observation to carry a
directive, runs every runnable directive, and exits non-zero if any observation
is unmarked or any claim is falsified.

Usage (run from the repo root):
    python3 data-raw/check-reference-observations.py              # check the corpus
    python3 data-raw/check-reference-observations.py --list-unmarked
    python3 data-raw/check-reference-observations.py --self-test  # harness bite
"""
import bisect
import os
import re
import subprocess
import sys

# In-scope: every cairn/references/*.md EXCEPT the three below.
#   ORACLES.md, BIBLIOGRAPHY.md -> M72 owns those pages (D-009 scope fence).
#   REFERENCES.md               -> a 6-line pointer stub (D-007).
REF_DIR = "cairn/references"
EXCLUDED = {"ORACLES.md", "BIBLIOGRAPHY.md", "REFERENCES.md"}

# A dated observation is a line carrying an `observed YYYY-MM-DD` stamp ...
STAMP = re.compile(r"observed\s+\d{4}-\d{2}-\d{2}")
# ... unless the stamp sits in a provenance paragraph (exempt, D-009). A
# provenance paragraph is a maximal run of non-blank lines containing an
# `Extraction:` sentence or a `**Provenance.**` heading; the extraction status
# is soft-wrapped, so its `— observed` stamp often lands on a continuation line
# that does not itself carry the keyword.
PROVENANCE_MARKS = ("Extraction:", "**Provenance.**")
# The settling directive: <!-- check: <cmd-or-none> -->
DIRECTIVE = re.compile(r"<!--\s*check:\s*(.*?)\s*-->")
# A directive whose command is the literal `none` (optionally `none — reason`).
NONE_CMD = re.compile(r"^none\b")


def repo_root():
    """Directory holding cairn/ — allow running from anywhere in the tree."""
    out = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True, check=True,
    )
    return out.stdout.strip()


def in_scope_files(root):
    d = os.path.join(root, REF_DIR)
    return sorted(
        os.path.join(REF_DIR, f)
        for f in os.listdir(d)
        if f.endswith(".md") and f not in EXCLUDED
    )


def provenance_linenos(lines):
    """1-indexed line numbers belonging to a provenance paragraph (exempt)."""
    prov = set()
    n = len(lines)
    i = 0
    while i < n:
        if lines[i].strip() == "":
            i += 1
            continue
        j = i
        while j < n and lines[j].strip() != "":
            j += 1
        if any(mark in lines[k] for k in range(i, j) for mark in PROVENANCE_MARKS):
            prov.update(range(i + 1, j + 1))
        i = j
    return prov


def _lineno(offsets, idx):
    """1-indexed line number of character offset idx."""
    return bisect.bisect_right(offsets, idx)


def observations(root):
    """Yield (relpath, lineno, line, directive_body_or_None) for each in-scope
    dated observation. directive_body is the text after `check:` when present.

    Parsing is position-based, not line-based: a stamp's `observed` keyword and
    its date can straddle a soft line break (e.g. `... — observed\\n2026-07-19`),
    and STAMP's `\\s+` spans the newline. Each stamp's directive is the first
    `<!-- check: -->` that follows it within the same paragraph (no blank line
    between the stamp and the directive, and before the next stamp). Stamps
    whose keyword sits in a provenance paragraph are exempt (D-009)."""
    for rel in in_scope_files(root):
        with open(os.path.join(root, rel), encoding="utf-8") as fh:
            text = fh.read()
        lines = text.splitlines(keepends=True)
        prov = provenance_linenos(lines)
        offsets = []
        pos = 0
        for ln in lines:
            offsets.append(pos)
            pos += len(ln)
        stamps = list(STAMP.finditer(text))
        directives = list(DIRECTIVE.finditer(text))
        for i, m in enumerate(stamps):
            lineno = _lineno(offsets, m.start())
            if lineno in prov:
                continue
            nxt = stamps[i + 1].start() if i + 1 < len(stamps) else len(text)
            body = None
            for d in directives:
                if m.end() <= d.start() < nxt:
                    if "\n\n" in text[m.end():d.start()]:
                        break  # directive is past the paragraph — not this stamp's
                    body = d.group(1)
                    break
            line_text = lines[lineno - 1].rstrip("\n") if lineno <= len(lines) else ""
            yield rel, lineno, line_text, body


def evaluate(cmd, root):
    """Run a settling command; return (holds, combined_output).

    holds is True iff the command exits 0 (D-009: exit 0 == claim holds).
    bash is used so `!` negation and pipelines behave as written.
    """
    proc = subprocess.run(
        cmd, shell=True, executable="/bin/bash", cwd=root,
        capture_output=True, text=True,
    )
    out = (proc.stdout + proc.stderr).strip()
    return proc.returncode == 0, out


def self_test(root):
    """Register the harness bite: a known-true directive must read as holding and
    a known-false directive must read as falsified. If evaluate() ever stops
    distinguishing them (a refactor making the checker vacuous), this fails.

    `icc` is referenced throughout R/; a nonsense token is not. The grep-negation
    idiom `! git grep -qlF <token> -- R` therefore holds for the nonsense token
    (absent) and is falsified for `icc` (present)."""
    true_cmd = "! git grep -qlF 'zzz-no-such-token-zzz' -- R"
    false_cmd = "! git grep -qlF 'icc' -- R"
    ok, _ = evaluate(true_cmd, root)
    bad, _ = evaluate(false_cmd, root)
    problems = []
    if not ok:
        problems.append("known-TRUE directive read as falsified: %r" % true_cmd)
    if bad:
        problems.append("known-FALSE directive read as holding: %r" % false_cmd)
    if problems:
        print("SELF-TEST FAILED:")
        for p in problems:
            print("  " + p)
        return 1
    print("self-test OK: checker distinguishes a holding claim from a falsified one")
    return 0


def main(argv):
    root = repo_root()

    if "--self-test" in argv:
        return self_test(root)

    obs = list(observations(root))

    if "--list-unmarked" in argv:
        unmarked = [(f, n, ln) for f, n, ln, body in obs if body is None]
        for f, n, ln in unmarked:
            print("%s:%d  %s" % (f, n, ln.strip()[:120]))
        print("\n%d unmarked of %d in-scope observations" % (len(unmarked), len(obs)))
        return 0

    unmarked = []
    none_marked = []
    falsified = []
    checked = 0
    for f, n, ln, body in obs:
        if body is None:
            unmarked.append((f, n, ln))
            continue
        if NONE_CMD.match(body):
            none_marked.append((f, n, body))
            continue
        checked += 1
        holds, out = evaluate(body, root)
        if not holds:
            falsified.append((f, n, body, out))

    print("in-scope dated observations: %d" % len(obs))
    print("  runnable directives:       %d" % checked)
    print("  declared un-settleable:    %d (check: none)" % len(none_marked))
    print("  unmarked:                  %d" % len(unmarked))
    print("  falsified:                 %d" % len(falsified))

    if unmarked:
        print("\nUNMARKED (no `check:` directive — D-009 requires one):")
        for f, n, ln in unmarked:
            print("  %s:%d  %s" % (f, n, ln.strip()[:110]))
    if falsified:
        print("\nFALSIFIED (settling command returned nonzero — claim does not hold):")
        for f, n, body, out in falsified:
            print("  %s:%d" % (f, n))
            print("    check: %s" % body)
            if out:
                print("    -> %s" % out.replace("\n", "\n       "))

    return 0 if not (unmarked or falsified) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
