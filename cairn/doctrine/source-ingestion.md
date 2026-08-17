# Doctrine: verifying extractions from PDF sources

This page owns the craft of verifying what a source PDF actually says before a
`cairn/references/` extraction is stamped `verified` — the text-layer trap and
the quotation-sweep discipline. It is a doctrine module graduated from
`cairn/LESSONS.md` (the M66 line, reinforced at M67) under the maturation exit;
the ingestion workflow itself is owned by the plugin's validation doctrine, and
the source notes live under `cairn/references/` (cross-references only).

## The text layer is not the page

A string absent from a PDF's **text layer** may still be **printed** on the
page: `trevethan2017`'s `Published online:` footer is absent from `pdftotext`
in `-layout`, `-raw`, and whole-document modes, yet is plainly printed on p. 1
beside the publisher logo — an independent reviewer and the scorer both
concluded (at score 92) that the note had fabricated it. Settle any "not in the
PDF" claim with a high-DPI crop render —

    pdftoppm -r 400 -f N -l N -png -x X -y Y -W w -H h

— never the text layer alone. A grep of the text layer can **undercount**; an
absence claim built on it can be outright **false**, and the false absence is
the more dangerous of the two (M66).

## The quotation sweep is mechanical, per-note, and end-of-milestone

The converse failure, same milestone: 3 of ~40 quotations marked verbatim were
paraphrases — so re-read every quoted string against the source before stamping
an extraction `verified`. At M67 the defect recurred at **both** review
attempts: attempt 1 found two altered quotations, and after a fix-sweep whose
own work log called it done, attempt 2 found two more — one in a note the sweep
never opened. A quotation sweep must therefore enumerate every quoted string in
**every** note the milestone touches, not just the notes a prior finding named;
"I swept the surrounding quotations" is not evidence unless the sweep was
mechanical and per-note (M67; the procedural-set rule this feeds is DESIGN.md
GP8).
