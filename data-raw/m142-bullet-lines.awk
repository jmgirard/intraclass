# M142 AC1: per-bullet sizes in NEWS.md.
#
# AC1's rule: a bullet is a line matching `^* ` plus every following line until
# the next `^* `, `^#`, or blank line. Its SIZE is those lines, each stripped of
# leading and trailing whitespace and joined with single spaces, measured in
# BYTES -- a byte cap rather than a line cap because a line cap is defeated by
# reflow alone.
#
# This program measures a strict SUPERSET of that rule, so a clean run over it
# establishes the rule as stated a fortiori. Two widenings, both found by the
# M142 amendment audit (2026-08-27):
#   * `-` and `+` markers count as bullets too. Keying on `*` alone measures
#     zero bullets on a file written with `-`, and "no bullet exceeds 500
#     bytes" is then true of a 15 kB monolith. The marker must still sit at
#     column 1 and be followed by a space, exactly as AC1's rule says: an
#     indented bullet, an ordered list, or a tab after the marker is not
#     measured by this program and is not measured by AC1's rule either.
#   * A blank line does not end a bullet; only the next bullet, the next
#     heading, or EOF does. Under AC1's literal rule an inserted blank line
#     drops everything after it from measurement, so a bullet split in two by
#     whitespace alone measures only its first paragraph.
# Both widenings can only raise a measured size or add a measured bullet, never
# lower or remove one.
#
# Prints "<bytes>\t<non-blank lines>\t<opening text>" per bullet. Column 2
# skips blank lines, so on a bullet split by whitespace it is below the
# bullet's physical line span; column 1, the byte figure AC1 caps, is not.
# Run it byte-exact:
#   LC_ALL=C awk -f data-raw/m142-bullet-lines.awk NEWS.md
# (without LC_ALL=C, some awks count characters, so a multibyte dash or quote
# reads short by two bytes apiece). For a merge-base figure, run this same
# program over a `git show <merge-base>:NEWS.md` copy.
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function flush() { if (n) print length(text) "\t" n "\t" head; n = 0 }
/^[*+-] /  { flush(); n = 1; text = trim($0); head = substr($0, 3, 60); next }
/^#/       { flush(); next }
/^[ \t]*$/ { next }
           { if (n) { n++; text = text " " trim($0) } }
END        { flush() }
