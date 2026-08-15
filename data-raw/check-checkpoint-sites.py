#!/usr/bin/env python3
"""M120 — every declared resume site still routes through the checkpoint guard.

What this checks, and what it deliberately does not:

  * IT CHECKS the sites declared in data-raw/checkpoint-sites.tsv. That file is
    an enumeration, not a discovery procedure, and this checker inherits exactly
    that bound. It cannot tell you a sixth harness has started resuming from a
    cache, and it does not claim to.
  * WHAT DOES cover the open-ended case is the run-time trace in
    checkpoint-guard.R: it watches deserialization as it happens, so a
    checkpoint read fails the run whatever spelling it was written in. This
    checker exists because that trace only fires when a harness actually runs,
    and the oracle harnesses need brms/Stan and hours of refits.

So: the trace is the guard, this is the regression net over the sites we know
about. Stdlib-only and R-free, to stay in the existing check-references job.

Usage:
  python3 data-raw/check-checkpoint-sites.py
  python3 data-raw/check-checkpoint-sites.py --self-test
"""

import re
import sys
import pathlib
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
SITES = ROOT / "data-raw" / "checkpoint-sites.tsv"
GUARD = "data-raw/checkpoint-guard.R"


def read_sites(path=SITES):
    rows = []
    header = None
    for line in path.read_text().splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        parts = line.split("\t")
        if header is None:
            header = parts
            continue
        rows.append(dict(zip(header, parts)))
    return rows


def strip_comments(text):
    """Drop R comments, leaving everything else (including line structure) put.

    Without this the checker reads commented-out code as live code, and
    `# source("data-raw/checkpoint-guard.R")` passes every routing check while
    the guard is switched off — which is exactly how a guard gets disabled
    during debugging and left that way. A `#` inside a string literal is not a
    comment, so quoting state is tracked rather than the line simply split on
    the first hash.
    """
    out = []
    for line in text.splitlines():
        quote = None
        i = 0
        while i < len(line):
            ch = line[i]
            if quote:
                if ch == "\\":
                    i += 2
                    continue
                if ch == quote:
                    quote = None
            elif ch in "\"'":
                quote = ch
            elif ch == "#":
                break
            i += 1
        out.append(line[:i] if i < len(line) else line)
    return "\n".join(out)


def check_site(site, root=ROOT):
    """Return a list of failure strings for one declared site."""
    out = []
    path = root / site["script"]
    if not path.exists():
        return [f"{site['script']}: declared in checkpoint-sites.tsv but absent"]
    text = strip_comments(path.read_text())

    if f'source("{GUARD}")' not in text:
        out.append(f"{site['script']}: does not source {GUARD}")

    # The resume read must go through the guard. A bare readRDS of the
    # checkpoint variable is the exact call this milestone replaced.
    if re.search(r"(?<![\w.$])readRDS\s*\(\s*ckpt\b", text):
        out.append(
            f"{site['script']}: reads its checkpoint with a bare readRDS(ckpt) "
            f"— route it through ckpt_read()"
        )

    # EVERY declared guard call, not any one of them. A store site that keeps
    # its file-level load and drops the per-entry ckpt_store_get() has stopped
    # checking the thing that actually goes stale, and an "any of these" test
    # stays silent through exactly that edit.
    required = [c for c in site.get("api", "").split(",") if c]
    if not required:
        out.append(f"{site['script']}: declares no guard calls")
    for call in required:
        if not re.search(rf"(?<![\w.$]){re.escape(call)}\s*\(", text):
            out.append(f"{site['script']}: never calls {call}()")
    if "ckpt_trace_assert()" not in text:
        out.append(
            f"{site['script']}: never calls ckpt_trace_assert() before writing output"
        )
    if "ckpt_trace_register(" not in text:
        out.append(f"{site['script']}: never registers its checkpoint with the trace")

    # Every declared parameter must actually appear in a spec call, or the
    # declaration and the code have drifted apart.
    declared = [p for p in site["params"].split(",") if p]
    if not declared:
        out.append(f"{site['script']}: declares no parameters")
    spec_blocks = re.findall(r"ckpt_spec\s*\((.*?)\n  \)", text, flags=re.S)
    spec_text = "\n".join(spec_blocks)
    for p in declared:
        if not re.search(rf"(?<![\w.]){re.escape(p)}\s*=", spec_text):
            out.append(
                f"{site['script']}: declared parameter '{p}' appears in no ckpt_spec() call"
            )
    for fn in (f for f in site["block"].split(",") if f):
        if f'"{fn}"' not in spec_text:
            out.append(
                f"{site['script']}: declared block function '{fn}' is in no ckpt_spec() call"
            )
    return out


def run_check(root=ROOT, sites=None):
    sites = sites if sites is not None else read_sites()
    failures = []
    for site in sites:
        failures.extend(check_site(site, root=root))
    return sites, failures


def mutations_for(site, src):
    """(label, mutated source) pairs for one site.

    Every declared guard call gets its own reversion, because dropping one of
    them is a real edit that leaves the others in place: on the store sites the
    per-entry check is the one that can vanish while the file-level load still
    looks like routing.
    """
    yield (
        "commented out the source() of the guard",
        src.replace(f'source("{GUARD}")', f'# source("{GUARD}")', 1),
    )
    yield (
        "commented out the pre-write trace assertion",
        src.replace("ckpt_trace_assert()", "# ckpt_trace_assert()", 1),
    )
    for call in (c for c in site.get("api", "").split(",") if c):
        yield (
            f"dropped every {call}() call",
            re.sub(rf"(?<![\w.$]){re.escape(call)}\s*\(", "bypassed_(", src),
        )


def self_test():
    """Mutation harness: revert a guard call in a copy of a real site and
    require this checker to notice. A checker that passes on a reverted guard
    is false coverage, which is the trap this repo keeps re-finding.

    Every declared site is probed, not a representative one: the sites do not
    share a guard API, so a harness that only ever mutates the first site says
    nothing about the four that route their reads a different way."""
    ok = True
    for site in read_sites():
        src = (ROOT / site["script"]).read_text()
        for label, mutated in mutations_for(site, src):
            if mutated == src:
                print(
                    f"FAIL self-test [{site['script']}]: cannot plant '{label}'"
                    " — the mutation changed nothing"
                )
                ok = False
                continue
            with tempfile.TemporaryDirectory() as td:
                fake_root = pathlib.Path(td)
                dest = fake_root / site["script"]
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_text(mutated)
                found = check_site(site, root=fake_root)
            if found:
                print(f"PASS self-test [{site['script']}]: {label} -> detected")
            else:
                print(f"FAIL self-test [{site['script']}]: {label} was NOT detected")
                ok = False

        # And the unmutated file must pass, or the checker reports on everything.
        if check_site(site):
            print(f"FAIL self-test [{site['script']}]: the unmutated site does not pass")
            ok = False
        else:
            print(f"PASS self-test [{site['script']}]: the unmutated site passes")
    return ok


def main(argv):
    if "--self-test" in argv:
        return 0 if self_test() else 1
    sites, failures = run_check()
    if failures:
        print(f"FAIL: {len(failures)} checkpoint-routing failure(s):")
        for f in failures:
            print("  -", f)
        return 1
    print(
        f"OK: {len(sites)} declared resume site(s) route through the checkpoint guard."
    )
    print(
        "(Declared sites only — the run-time trace in checkpoint-guard.R is what "
        "covers a site nobody declared.)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
