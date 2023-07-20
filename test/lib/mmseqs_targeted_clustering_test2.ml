open Mmseqs.Size_target
module Sh = Shexp_process

let%expect_test "targeted clustering (down, up, down to get there)" =
  Logging.set_up_logging "debug" ;
  Utils.with_temp_dir (fun outdir ->
      targeted_cluster ~target_count:50 ~tolerance:1e-10 ~mmseqs_exe:"mmseqs"
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
                  DEBUG [DATETIME] Clustering at 40% identity yielded 50 seqs |}] ;
      Sh.readdir outdir |> Sh.eval |> [%sexp_of: string list] |> print_s ;
      [%expect
        {|
              (split___groupA.clu_40_cluster.tsv split___groupA.clu_40_rep_seq.fasta
               split___groupA.clu_40_all_seqs.fasta) |}] )
