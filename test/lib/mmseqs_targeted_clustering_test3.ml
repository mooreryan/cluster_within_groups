open Mmseqs.Size_target
module Sh = Shexp_process

(* But it should give back the closest clustering. *)
let%expect_test "targeted clustering (should fail)" =
  Logging.set_up_logging "debug" ;
  Utils.with_temp_dir (fun outdir ->
      targeted_cluster ~target_count:51 ~tolerance:1e-10 ~mmseqs_exe:"mmseqs"
        ~seqs:"rnr_100.fasta" ~cov_percent:0.8 ~threads:2 ~outdir
        ~group_id:"groupA" ;
      [%expect
        {|
            DEBUG [DATETIME] Clustering at 65% identity yielded 93 seqs
            DEBUG [DATETIME] Next clustering at 47% identity
            DEBUG [DATETIME] Clustering at 47% identity yielded 62 seqs
            DEBUG [DATETIME] Next clustering at 38% identity
            DEBUG [DATETIME] Clustering at 38% identity yielded 43 seqs
            DEBUG [DATETIME] Next clustering at 42% identity
            DEBUG [DATETIME] Clustering at 42% identity yielded 52 seqs
            DEBUG [DATETIME] Next clustering at 40% identity
            DEBUG [DATETIME] Clustering at 40% identity yielded 50 seqs
            DEBUG [DATETIME] Next clustering at 41% identity
            DEBUG [DATETIME] Clustering at 41% identity yielded 52 seqs
            WARNING [DATETIME] Could not get within the targeted count range
            WARNING [DATETIME] The closest was 41% identity with 52 seqs |}] ;
      Sh.readdir outdir |> Sh.eval |> [%sexp_of: string list] |> print_s ;
      [%expect
        {|
              (split___groupA.clu_41_all_seqs.fasta split___groupA.clu_41_rep_seq.fasta
               split___groupA.clu_41_cluster.tsv) |}] )
