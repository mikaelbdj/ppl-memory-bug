(lang dune 3.19)

(name ppl-memory-bug)
(generate_opam_files true)

(source
 (github mikaelbdj/ppl-memory-bug))

(authors "Mikael Dahlsen-Jensen <mikael@cs.au.dk>")
(maintainers "Mikael Dahlsen-Jensen <mikael@cs.au.dk>")

(license GPL-3.0-only)

(package
 (name ppl-memory-bug)
 (synopsis "Minimal reproducer for suspected PPL OCaml binding memory issues")
 (description
  "A standalone OCaml program demonstrating potential memory corruption and \
   ownership issues in the Parma Polyhedra Library (PPL) OCaml bindings, \
   specifically related to iterator-based disjunct access and copying.")
 (depends
  (ocaml (>= 5.0))
  dune
  gmp
  ppl))

; Documentation: https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
