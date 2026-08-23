#!/usr/bin/env python3
"""Red the built pkgdown site when a vignette printed a load-time version-skew warning.

A binary `glmmTMB` built against one `TMB` and installed beside a newer `TMB`
warns from `glmmTMB`'s `.onLoad`:

    Warning in check_dep_version(dep_pkg = "TMB"): package version mismatch:
    glmmTMB was built with TMB package version 1.9.21
    Current TMB package version is 1.9.25

Because `intraclass` imports `glmmTMB`, that warning lands in whichever vignette
chunk first loads the package, and pkgdown renders it into the published
article. It says nothing about the package or the reader's own installation --
it is an artifact of the docs runner's package set -- so it must never reach the
site. The workflow prevents it by rebuilding `glmmTMB` from source against the
installed `TMB`; this checker is the guard that the prevention held.

It is a site-artifact check, not a source check: it reads built HTML, so it runs
in the pkgdown job after `build_site_github_pages()` and before the deploy step.
Exit 0 means no built page carries such a warning.

Usage (run from the repo root):
    python3 data-raw/check-vignette-render-warnings.py            # check docs/
    python3 data-raw/check-vignette-render-warnings.py <dir>      # check elsewhere
    python3 data-raw/check-vignette-render-warnings.py --self-test
"""
import os
import sys
import tempfile

# Substrings that identify a load-time dependency version-skew warning in
# rendered chunk output. Matched case-sensitively against the HTML text; each
# is distinctive enough that prose about the warning is the only false
# positive, and prose about it does not belong on a rendered article page.
MARKERS = (
    "check_dep_version",
    "package version mismatch",
    "was built with TMB package version",
)


def scan_file(path):
    """Return (line_number, marker, line) for every marker hit in one file."""
    hits = []
    with open(path, encoding="utf-8", errors="replace") as handle:
        for lineno, line in enumerate(handle, start=1):
            for marker in MARKERS:
                if marker in line:
                    hits.append((lineno, marker, line.strip()))
    return hits


def scan_tree(root):
    """Return (path, lineno, marker, line) for every hit under `root`."""
    findings = []
    for dirpath, _dirnames, filenames in os.walk(root):
        for name in sorted(filenames):
            if not name.endswith(".html"):
                continue
            path = os.path.join(dirpath, name)
            for lineno, marker, line in scan_file(path):
                findings.append((path, lineno, marker, line))
    return findings


def check(root):
    """Check one built-site tree; return a process exit status."""
    if not os.path.isdir(root):
        print(f"FAIL  no such directory: {root}")
        return 1
    findings = scan_tree(root)
    if not findings:
        print(f"OK    no load-time version-skew warning in the built pages under {root}")
        return 0
    for path, lineno, marker, line in findings:
        excerpt = line if len(line) <= 160 else line[:157] + "..."
        print(f"FAIL  {path}:{lineno}  [{marker}]  {excerpt}")
    print(
        f"\n{len(findings)} hit(s). A built page is showing a dependency "
        "version-skew warning from the docs runner's package set. Rebuild the "
        "mismatched package from source in the pkgdown workflow rather than "
        "muting the message."
    )
    return 1


def self_test():
    """Plant each marker into a page and require the check to red on it."""
    clean = (
        "<html><body><pre><code>#&gt; icc 0.71</code></pre>"
        "<p>glmmTMB is the default engine.</p></body></html>"
    )
    failures = 0
    with tempfile.TemporaryDirectory() as tmp:
        articles = os.path.join(tmp, "articles")
        os.makedirs(articles)
        with open(os.path.join(articles, "clean.html"), "w", encoding="utf-8") as handle:
            handle.write(clean)
        if check(tmp) != 0:
            print("FAIL  self-test: the clean tree did not pass")
            failures += 1
        else:
            print("PASS  self-test: a clean tree passes")

        planted = os.path.join(articles, "planted.html")
        for marker in MARKERS:
            with open(planted, "w", encoding="utf-8") as handle:
                handle.write(f"<html><body><pre><code>#&gt; Warning: {marker}</code></pre></body></html>")
            if check(tmp) == 0:
                print(f"FAIL  self-test: planted marker not caught: {marker}")
                failures += 1
            else:
                print(f"PASS  self-test: planted marker caught: {marker}")
        os.remove(planted)

    if failures:
        print(f"\n{failures} self-test failure(s).")
        return 1
    print(f"\nself-test clean: {len(MARKERS)} planted mutation(s) each red the check.")
    return 0


def main(argv):
    if "--self-test" in argv:
        return self_test()
    root = argv[0] if argv else "docs"
    return check(root)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
