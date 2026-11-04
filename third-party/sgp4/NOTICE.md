# SGP4 source and verification material

Vallado, David A., Paul Crawford, Richard Hujsak and T.S. Kelso, “Revisiting Spacetrack Report #3,” AIAA 2006-6753, 2006.

[Paper, official source archive and reference material](https://celestrak.org/publications/AIAA/2006-6753/). [Author FAQ and use permission](https://celestrak.org/publications/AIAA/2006-6753/faq.php), reviewed 4 November 2026: the authors permit personal and commercial use and request source/paper citations and a link to the main page. They do not attach a named software licence. Do not relabel these files Apache-2.0 or MIT.

Only the unmodified C++ SGP4.cpp/SGP4.h and selected upstream verification inputs/results are redistributed here. manifest.json pins each exact file and the official archive SHA. No upstream binary is executed or included. The original Yorungez ABI wrapper is independently Apache-2.0.

The mobile integration uses WGS72 gravity and AFSPC operation mode, TEME output, UTC approximating UT1 and zero polar motion for a foreground educational sky guide. This is not operational tracking or an exact optical pointing guarantee. Source elements expire after 72 hours; maneuvers/drag can degrade predictions earlier.
