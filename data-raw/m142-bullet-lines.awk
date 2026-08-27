# M142 AC1: per-bullet line counts in NEWS.md.
# A bullet is a line matching `^* ` plus every following line until the next
# `^* `, `^#`, or blank line. Prints "<lines>\t<opening text>" per bullet.
/^\* /     { if (n) print n "\t" head; n = 1; head = substr($0, 3, 60); next }
/^#/       { if (n) { print n "\t" head; n = 0 } ; next }
/^[ \t]*$/ { if (n) { print n "\t" head; n = 0 } ; next }
           { if (n) n++ }
END        { if (n) print n "\t" head }
