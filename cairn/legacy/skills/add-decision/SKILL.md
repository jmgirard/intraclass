---
name: add-decision
description: Record an architectural or statistical decision as an ADR. Use when a non-trivial modeling or API choice is made, or the maintainer says "record this decision".
allowed-tools: Read, Edit
---

## Instructions
Append a filled ADR to `project/DECISIONS.md` using the house format, with the
next sequential number:

```markdown
## ADR-00N: <title>
- Date: <yyyy-mm-dd>
- Status: proposed | accepted | superseded
- Context: <why this came up>
- Decision: <what we chose>
- Consequences: <tradeoffs, what it rules out>
- References: <paper + equation / issue / package>
```

Keep it factual and specific. For a **statistical** decision, cite the source
(paper + equation where possible) per PRINCIPLES.md #12, and note any oracle or
live check that backs it. If the decision changes a principle or the public API,
say so explicitly (PRINCIPLES.md #6 breaking changes require an ADR). If a Fable
review informed the decision, record that it was used (PRINCIPLES.md #19).
