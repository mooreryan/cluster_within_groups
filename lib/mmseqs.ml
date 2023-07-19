open! Core
module Sh = Shexp_process

let run ~mmseqs_exe ~seqs ~out_basename ~cov_percent ~min_seq_id ~threads =
  let cluster_prefix = out_basename in
  Sh.with_temp_dir ~prefix:"" ~suffix:"" (fun tmpdir ->
      let cov_percent = Float.to_string cov_percent in
      let min_seq_id = Float.to_string min_seq_id in
      let threads = Int.to_string threads in
      Sh.run mmseqs_exe
        [ "easy-cluster"
        ; seqs
        ; cluster_prefix
        ; tmpdir
        ; "-c"
        ; cov_percent
        ; "--min-seq-id"
        ; min_seq_id
        ; "--threads"
        ; threads
        ; "-v"
        ; "1" ] )
  |> Sh.eval

(* Partitions only include groups with sequences, (if you run the assert
   first.) *)
let cluster_partitions : Seqs.partitions -> Opts.t -> unit =
 fun partitions opts ->
  Map.iter partitions ~f:(fun (_records, (ids_and_oc : Groups.ids_and_oc)) ->
      let seqs = ids_and_oc.out_file in
      let out_basename = Utils.strip_fa_suffix seqs ^ ".clu" in
      Logs.debug (fun m -> m "Clustering seqs (%s)" seqs) ;
      run ~mmseqs_exe:opts.mmseqs_exe ~seqs ~out_basename
        ~cov_percent:opts.cov_percent ~min_seq_id:opts.min_seq_id
        ~threads:opts.threads ;
      () )

let glob path =
  (* Should have wordexp on this platform. *)
  let wordexp = Core_unix.wordexp |> Or_error.ok_exn in
  wordexp path |> Array.to_list

let cat_rep_seqs outdir =
  let outfile = outdir ^/ [%string "cluster_rep_seqs%{Utils.fa_suffix}"] in
  Sh.run "cat" (glob (outdir ^ "/*rep_seq.fasta"))
  |> Sh.stdout_to outfile |> Sh.eval

let cat_clu_tsv outdir =
  let outfile = outdir ^/ [%string "clusters.tsv"] in
  Sh.run "cat" (glob (outdir ^ "/*.tsv")) |> Sh.stdout_to outfile |> Sh.eval
