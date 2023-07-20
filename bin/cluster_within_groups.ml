open Lib

module Cli = struct
  open Cmdliner

  let ( let+ ) v f = Term.(const f $ v)

  let ( and+ ) v1 v2 = Term.(const (fun x y -> (x, y)) $ v1 $ v2)

  let version = "1"

  let seqs_file =
    let docv = "SEQS" in
    let doc = "FASTA file with seqs to cluster" in
    Arg.(required & pos 0 (some non_dir_file) None & info [] ~docv ~doc)

  let groups_file =
    let docv = "GROUPS" in
    let doc = "TSV file with sequence groups (seq_id [tab] group_id)" in
    Arg.(required & pos 1 (some non_dir_file) None & info [] ~docv ~doc)

  let outdir =
    let docv = "OUTDIR" in
    let doc = "Out directory" in
    Arg.(value & opt string "." & info ["outdir"] ~docv ~doc)

  let mmseqs_exe =
    let docv = "MMSEQS_EXE" in
    let doc = "mmseqs executable" in
    Arg.(value & opt string "mmseqs" & info ["mmseqs"] ~docv ~doc)

  let threads =
    let docv = "THREADS" in
    let doc = "No. threads for clustering" in
    Arg.(value & opt int 1 & info ["threads"] ~docv ~doc)

  let min_seq_id =
    let docv = "MIN_SEQ_ID" in
    let doc =
      "List matches above this sequence identity (for clustering) (range \
       0.0-1.0) (ignored in targeted clustering)"
    in
    Arg.(value & opt float 0.8 & info ["min-seq-id"] ~docv ~doc)

  let cov_percent =
    let docv = "COV_PROPORTION" in
    let doc =
      "List matches above this fraction of aligned (covered) residues (range \
       0.0-1.0)"
    in
    Arg.(value & opt float 0.8 & info ["cov"] ~docv ~doc)

  let target_cluster_count =
    let docv = "TARGET_COUNT" in
    let doc = "Try to cluster each group down to this number of seqs" in
    Arg.(value & opt (some int) None & info ["target-count"] ~docv ~doc)

  let opts =
    let+ groups_file
    and+ seqs_file
    and+ outdir
    and+ threads
    and+ min_seq_id
    and+ cov_percent
    and+ mmseqs_exe
    and+ target_cluster_count in
    Opts.v ~groups_file ~seqs_file ~outdir ~threads ~min_seq_id ~cov_percent
      ~mmseqs_exe ~target_cluster_count

  let program = Term.(const run $ opts)

  let cmd =
    let doc = "cluster sequences within groups" in
    let info =
      let man =
        [ `S Manpage.s_description
        ; `P
            "The groups file should be a TSV with two columns: sequence ID \
             [tab] group ID."
        ; `P
            "Sequence IDs should be unique, and should correspond with the \
             sequence IDs present in the fasta file.  Note: the fasta ID is \
             treated as all characters between the `>` and the first space in \
             the fasta header."
        ; `P
            "Sequences within each group defined in the groups file are \
             clustered with MMseqs2.  At the end, each of the output files \
             will be merged into a representative sequence fasta file and a \
             cluster file defining the clusters." ]
      in
      Cmd.info "cluster_within_groups" ~doc ~version ~man
    in
    Cmd.v info program
end

let () = exit (Cmdliner.Cmd.eval_result Cli.cmd)
