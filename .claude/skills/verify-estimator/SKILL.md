---
name: verify-estimator
description: Verify a statistical estimator against numerical oracles (textbook/analytic, established package, seeded simulation). Use before shipping any ICC estimator or when the maintainer asks to "verify" or "check correctness".
allowed-tools: Read, Grep, Glob, Bash
---

## Instructions
Implement PRINCIPLES.md #1 (oracle-first). Correctness is **established by
numerical agreement**, never by assertion. **Run everything on Opus** — never
route this to Fable (PRINCIPLES.md #19).

For the named estimator:

1. **Assemble the oracle set** (need ≥2 independent types):
   - (a) closed-form / textbook value (e.g. Shrout & Fleiss 1979, Brennan 2001),
   - (b) an established package on a case it supports (`psych::ICC`, `gtheory`),
   - (c) a **seeded** simulation with known population variance components.
   Pull registered values from `project/REFERENCES.md`; if a needed value is not
   registered with provenance, stop — do not invent one (PRINCIPLES.md #4).
2. **Run the comparison** and report agreement to an explicit tolerance, per oracle.
3. **Record results** in `project/REFERENCES.md` (which oracle, tolerance, pass/fail).
4. **If no oracle can pin the result:** do **not** escalate on your own. Surface the
   gap plainly, name the specific oracle that *would* settle it, and **recommend**
   the maintainer approve a Fable review (§6 checklist), then **stop and wait**
   (PRINCIPLES.md #18, #19). A more capable model can *reason* about correctness but
   cannot *establish* it — oracles remain the source of truth.
