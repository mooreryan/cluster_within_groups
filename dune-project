(lang dune 3.9)

(cram enable)

(name cluster_within_groups)

(generate_opam_files true)

(source
 (github mooreryan/cluster_within_groups))

(authors "Ryan M. Moore")

(maintainers "Ryan M. Moore")

(license MIT)

(documentation https://github.com/mooreryan/cluster_within_groups)

(package
 (name cluster_within_groups)
 (synopsis "Cluster sequences within groups")
 (description "Cluster sequences within groups using MMseqs2")
 (depends
  ocaml
  dune
  cmdliner
  bio_io
  (core
   (and
    (>= "v0.16.0")
    (< "v0.17.0")))
  core_unix
  shexp
  re)
 (tags
  (bioinformatics clustering)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
