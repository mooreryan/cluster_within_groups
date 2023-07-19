open! Core

module Sh = Shexp_process

(* Make opts available to Main *)
module Opts = Opts

let%expect_test _ =
  let seq_ids_to_group_ids =
    Groups.read_seq_ids_to_group_ids Utils.test_group_data_file
  in
  let group_info =
    Groups.read_group_info ~file:Utils.test_group_data_file ~outdir:"."
  in
  let records = Seqs.read "test_seqs.fa" in
  let partitions = Seqs.partition ~records ~seq_ids_to_group_ids ~group_info in
  partitions |> [%sexp_of: Seqs.partitions] |> Stdio.print_s ;
  [%expect
    {|
  ((groupA
    ((((id seq3) (desc ()) (seq GGGGG)) ((id seq1) (desc ()) (seq AAAAA)))
     ((seq_ids (seq1 seq3)) (out_file ./split___groupA.fa))))
   (groupB
    ((((id seq2) (desc ()) (seq CCCCC)))
     ((seq_ids (seq2)) (out_file ./split___groupB.fa))))) |}]

let assert_map_not_empty m name =
  if Map.length m = 0 then
    raise_s
      [%message
        "Expected a non-empty map. Did you try a pipe, subshell, or reading \
         from stdin?"
        ~map:name]

let run : Opts.t -> unit =
 fun opts ->
  Logging.set_up_logging "debug" ;
  if not (Sys_unix.file_exists_exn opts.outdir) then
    Core_unix.mkdir_p opts.outdir ;
  Logs.info (fun m -> m "Getting seq IDs to group IDs") ;
  let seq_ids_to_group_ids =
    Groups.read_seq_ids_to_group_ids opts.groups_file
  in
  assert_map_not_empty seq_ids_to_group_ids "seq_ids_to_group_ids" ;
  Logs.info (fun m -> m "Getting group info") ;
  let group_info =
    Groups.read_group_info ~file:opts.groups_file ~outdir:opts.outdir
  in
  assert_map_not_empty group_info "group_info" ;
  Logs.info (fun m -> m "Reading seqs") ;
  let records = Seqs.read opts.seqs_file in
  Logs.info (fun m -> m "Generating partitions") ;
  let partitions = Seqs.partition ~records ~seq_ids_to_group_ids ~group_info in
  Logs.info (fun m -> m "Checking partitions") ;
  Seqs.check_partitions partitions ;
  Logs.info (fun m -> m "Writing partitions") ;
  Seqs.write_partitions partitions ;
  Logs.info (fun m -> m "Clustering partitions") ;
  Mmseqs.cluster_partitions partitions opts ;
  Logs.info (fun m -> m "Writing cluster file") ;
  Mmseqs.cat_clu_tsv opts.outdir ;
  Logs.info (fun m -> m "Writing rep seqs file") ;
  Mmseqs.cat_rep_seqs opts.outdir ;
  Logs.info (fun m -> m "Done!") ;
  ()

let run opts = try Ok (run opts) with exn -> Error (Exn.to_string exn)

(* find test -name '*.fasta' -type f -print0 | xargs -0 *)
