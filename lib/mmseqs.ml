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

let run_fake_clustering
    ~(* time mmseqs easy-cluster ../../lib/rnr_100.fa OUT_clu tmp_clu -c 1.0
        --min-seq-id 1.0 --min-aln-len 9999999 --single-step-clustering
        --kmer-per-seq 1 -s 1 --max-seqs 1 --min-ungapped-score 9999999 *)
     mmseqs_exe ~seqs ~out_basename ~threads =
  let cluster_prefix = out_basename in
  Sh.with_temp_dir ~prefix:"" ~suffix:"" (fun tmpdir ->
      let threads = Int.to_string threads in
      Sh.run mmseqs_exe
        [ "easy-cluster"
        ; seqs
        ; cluster_prefix
        ; tmpdir
        ; "--threads"
        ; threads
        ; "-c"
        ; "1.0"
        ; "--min-seq-id"
        ; "1.0"
        ; "--min-aln-len"
        ; "9999999"
        ; "--single-step-clustering"
        ; "--kmer-per-seq"
        ; "1"
        ; "-s"
        ; "1"
        ; "--max-seqs"
        ; "1"
        ; "--min-ungapped-score"
        ; "9999999"
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

(* Dealing with "size-targeted" clustering. I.e., user want's a given target
   size for all clusters, so any sequence file with greater than that many
   sequences will be clustered at multiple levels until that size is
   acheived. *)
module Size_target = struct
  let run_mmseqs = run

  (* Use ripgrep to count the number of sequences in the file. *)
  let count_seqs file =
    Sh.run "rg" ["^>"; "-c"; file]
    |> Sh.capture_unit [Sh.Std_io.Stdout]
    |> Sh.map ~f:(fun s -> s |> String.strip |> Int.of_string)
    |> Sh.eval

  let tolerance = 0.25

  let acceptable_range target_count tolerance =
    let tol = Float.(of_int target_count *. tolerance) in
    let upper =
      Float.(of_int target_count +. tol) |> Float.round |> Float.to_int
    in
    let lower =
      Float.(of_int target_count -. tol) |> Float.round |> Float.to_int
    in
    (lower, upper)

  let is_in_range count (min, max) = min <= count && count <= max

  let midpoint a b =
    Float.((of_int a + of_int b) / 2.0) |> Float.round |> Float.to_int

  (* This will be passed to MMseqs2 min-seq-id parameter. *)
  let new_cluster_percent ~min_clustering_percent ~max_clustering_percent
      ~current_percent ~result =
    match result with
    | `Count_too_low ->
        (* Then raise the clustering percentage *)
        (* There are too few sequences so we must never get below the current
           percentage. *)
        let new_min = current_percent in
        let new_max = max_clustering_percent in
        (new_min, new_max, midpoint current_percent max_clustering_percent)
    | `Count_too_high ->
        (* Then lower the clustering percentage *)
        let new_min = min_clustering_percent in
        (* There are too many sequences so we must never exceed the current
           percentage. *)
        let new_max = current_percent in
        (new_min, new_max, midpoint current_percent min_clustering_percent)

  let dist a b = Int.abs (a - b)

  (* Ie which clustering percentage gets you closest to the target number (min
     distance to target)? *)

  module Cluster_result = struct
    type t = {cluster_percent: int; seq_count: int; dist_to_target_count: int}
    [@@deriving fields, sexp]

    let default () =
      {cluster_percent= -1; seq_count= -1; dist_to_target_count= Int.max_value}

    let v ~cluster_percent ~seq_count ~dist_to_target_count =
      {cluster_percent; seq_count; dist_to_target_count}

    (* Ties will be the first seen in iteration order. The iteration order is
       unspecified. *)
    let pick_best ht target_seq_count =
      (* We're dealing with counts as values so starting value should be 0. *)
      Hashtbl.fold ht ~init:(default ())
        ~f:(fun ~key:cluster_percent ~data:seq_count current_best_cluster ->
          let d = dist seq_count target_seq_count in
          if d < current_best_cluster.dist_to_target_count then
            v ~cluster_percent ~seq_count ~dist_to_target_count:d
          else current_best_cluster )

    let%expect_test "pick_best" =
      let ht =
        Hashtbl.of_alist_exn
          (module Int)
          [(60, 550); (50, 500); (40, 450); (30, 400)]
      in
      pick_best ht 499 |> [%sexp_of: t] |> print_s ;
      [%expect
        {| ((cluster_percent 50) (seq_count 500) (dist_to_target_count 1)) |}] ;
      pick_best ht 500 |> [%sexp_of: t] |> print_s ;
      [%expect
        {| ((cluster_percent 50) (seq_count 500) (dist_to_target_count 0)) |}] ;
      pick_best ht 501 |> [%sexp_of: t] |> print_s ;
      [%expect
        {| ((cluster_percent 50) (seq_count 500) (dist_to_target_count 1)) |}] ;
      (* Will be the first one it sees in iteration order. And that is
         unspecified. *)
      pick_best ht 475 |> [%sexp_of: t] |> print_s ;
      [%expect
        {| ((cluster_percent 50) (seq_count 500) (dist_to_target_count 25)) |}]
  end

  (* TODO: clean this up. *)
  (* [target_count] we want to get as close to this number as possible without
     going over...like the price is right. *)
  let targeted_cluster ~target_count ~tolerance ~mmseqs_exe ~seqs ~cov_percent
      ~threads ~outdir ~group_id =
    (* Tracked the already tried...I could probably just get the end criteria
       fixed and avoid this, but w/e, it works. *)
    let already_tried = Hashtbl.create (module Int) in
    let min_clustering_percent = 30 in
    let max_clustering_percent = 100 in
    let starting_percent =
      midpoint min_clustering_percent max_clustering_percent
    in
    let range = acceptable_range target_count tolerance in
    if count_seqs seqs <= target_count then (
      Logs.info (fun m ->
          (* TODO: get group name *)
          m
            "Group (%s) had fewer seqs than target threshold, running fake \
             clustering"
            group_id ) ;
      let basename_with_dir =
        outdir ^/ [%string "split___%{group_id}.clu_NOT_CLUSTERED"]
      in
      (* This is where it is tricky because mmseqs will change the header names,
         but the normal fasta parser will not. *)
      (* Run a fast-as-possible "fake" clustering that should leave each
         sequence separate. *)
      run_fake_clustering ~mmseqs_exe ~seqs ~out_basename:basename_with_dir
        ~threads ;
      (* Move the files *)
      let files_to_move = glob (basename_with_dir ^ "*") in
      List.iter files_to_move ~f:(fun file ->
          let _dir, name = Filename.split file in
          let dst = outdir ^/ name in
          Core_unix.rename ~src:file ~dst ) ;
      (* And we're done! *)
      () )
    else
      Utils.with_temp_dir (fun dir ->
          let rec loop ?(don't_check = false) ~min:min_clustering_percent
              ~max:max_clustering_percent ~cur:cluster_percent () =
            let basename_no_dir =
              [%string "split___%{group_id}.clu_%{cluster_percent#Int}"]
            in
            let basename_with_dir = dir ^/ basename_no_dir in
            run_mmseqs ~mmseqs_exe ~seqs ~out_basename:basename_with_dir
              ~cov_percent
              ~min_seq_id:Float.(of_int cluster_percent / 100.0)
              ~threads ;
            let outfile = basename_with_dir ^ "_rep_seq.fasta" in
            let seq_count = count_seqs outfile in
            (* Don't check mode should skip this. *)
            if not don't_check then
              Hashtbl.add_exn already_tried ~key:cluster_percent ~data:seq_count ;
            Logs.debug (fun m ->
                m "Clustering at %d%% identity yielded %d seqs" cluster_percent
                  seq_count ) ;
            if is_in_range seq_count range || don't_check then
              let files_to_move = glob (basename_with_dir ^ "*") in
              List.iter files_to_move ~f:(fun file ->
                  let _dir, name = Filename.split file in
                  let dst = outdir ^/ name in
                  Core_unix.rename ~src:file ~dst )
            else
              let new_min_percent, new_max_percent, next_cluster_percent =
                new_cluster_percent ~min_clustering_percent
                  ~max_clustering_percent ~current_percent:cluster_percent
                  ~result:
                    ( if seq_count < target_count then `Count_too_low
                      else `Count_too_high )
              in
              if
                Hashtbl.mem already_tried next_cluster_percent
                || next_cluster_percent = cluster_percent
              then
                let () =
                  Logs.warn (fun m ->
                      m "Could not get within the targeted count range" )
                in
                let best_cluster_result =
                  Cluster_result.pick_best already_tried target_count
                in
                let () =
                  Logs.warn (fun m ->
                      m "The closest was %d%% identity with %d seqs"
                        (Cluster_result.cluster_percent best_cluster_result)
                        (Cluster_result.seq_count best_cluster_result) )
                in
                if
                  Cluster_result.cluster_percent best_cluster_result
                  = cluster_percent
                then
                  (* TODO This is directly copied from above. *)
                  let files_to_move = glob (basename_with_dir ^ "*") in
                  List.iter files_to_move ~f:(fun file ->
                      let _dir, name = Filename.split file in
                      let dst = outdir ^/ name in
                      Core_unix.rename ~src:file ~dst )
                else
                  (* Do the clustering and return those files without checking
                     them. *)
                  loop ~don't_check:true ~min:new_min_percent
                    ~max:new_max_percent
                    ~cur:(Cluster_result.cluster_percent best_cluster_result)
                    ()
              else
                let () =
                  Logs.debug (fun m ->
                      m "Next clustering at %d%% identity" next_cluster_percent )
                in
                loop ~min:new_min_percent ~max:new_max_percent
                  ~cur:next_cluster_percent ()
          in
          loop ~min:min_clustering_percent ~max:max_clustering_percent
            ~cur:starting_percent () )

  (* TODO: These tests are long...move them! *)
  module Test = struct
    module Expect_test_config = struct
      include Expect_test_config

      (* This is the same regex copied from the redact_log_timestamp file. *)
      let timestamp =
        Re.compile
        @@ Re.Perl.re "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"

      let redact_timestamp s = Re.replace_string timestamp ~by:"DATETIME" s

      let sanitize s = redact_timestamp s
    end

    (* Note: I'm not entirely sure how stable the percentages and counts will be
       across mmseqs runs...I guess we will find out though! *)
    let%expect_test "targeted clustering all good" =
      Logging.set_up_logging "debug" ;
      Utils.with_temp_dir (fun outdir ->
          targeted_cluster ~target_count:50 ~tolerance:0.1 ~mmseqs_exe:"mmseqs"
            ~seqs:"rnr_100.fa" ~cov_percent:0.8 ~threads:4 ~outdir
            ~group_id:"groupA" ;
          [%expect
            {|
            DEBUG [DATETIME] Clustering at 65% identity yielded 93 seqs
            DEBUG [DATETIME] Next clustering at 48% identity
            DEBUG [DATETIME] Clustering at 48% identity yielded 64 seqs
            DEBUG [DATETIME] Next clustering at 39% identity
            DEBUG [DATETIME] Clustering at 39% identity yielded 45 seqs |}] ;
          Sh.readdir outdir |> Sh.eval |> [%sexp_of: string list] |> print_s ;
          [%expect
            {|
              (split___groupA.clu_39_rep_seq.fasta split___groupA.clu_39_cluster.tsv
               split___groupA.clu_39_all_seqs.fasta) |}] )

    let%expect_test "targeted clustering (down, up, down to get there)" =
      Logging.set_up_logging "debug" ;
      Utils.with_temp_dir (fun outdir ->
          targeted_cluster ~target_count:50 ~tolerance:1e-10
            ~mmseqs_exe:"mmseqs" ~seqs:"rnr_100.fa" ~cov_percent:0.8 ~threads:4
            ~outdir ~group_id:"groupA" ;
          [%expect
            {|
                  DEBUG [DATETIME] Clustering at 65% identity yielded 93 seqs
                  DEBUG [DATETIME] Next clustering at 48% identity
                  DEBUG [DATETIME] Clustering at 48% identity yielded 64 seqs
                  DEBUG [DATETIME] Next clustering at 39% identity
                  DEBUG [DATETIME] Clustering at 39% identity yielded 45 seqs
                  DEBUG [DATETIME] Next clustering at 44% identity
                  DEBUG [DATETIME] Clustering at 44% identity yielded 57 seqs
                  DEBUG [DATETIME] Next clustering at 42% identity
                  DEBUG [DATETIME] Clustering at 42% identity yielded 52 seqs
                  DEBUG [DATETIME] Next clustering at 41% identity
                  DEBUG [DATETIME] Clustering at 41% identity yielded 52 seqs
                  DEBUG [DATETIME] Next clustering at 40% identity
                  DEBUG [DATETIME] Clustering at 40% identity yielded 50 seqs |}] ;
          Sh.readdir outdir |> Sh.eval |> [%sexp_of: string list] |> print_s ;
          [%expect
            {|
              (split___groupA.clu_40_cluster.tsv split___groupA.clu_40_rep_seq.fasta
               split___groupA.clu_40_all_seqs.fasta) |}] )

    (* But it should give back the closest clustering. *)
    let%expect_test "targeted clustering (should fail)" =
      Logging.set_up_logging "debug" ;
      Utils.with_temp_dir (fun outdir ->
          targeted_cluster ~target_count:51 ~tolerance:1e-10
            ~mmseqs_exe:"mmseqs" ~seqs:"rnr_100.fa" ~cov_percent:0.8 ~threads:4
            ~outdir ~group_id:"groupA" ;
          [%expect
            {|
            DEBUG [DATETIME] Clustering at 65% identity yielded 93 seqs
            DEBUG [DATETIME] Next clustering at 48% identity
            DEBUG [DATETIME] Clustering at 48% identity yielded 64 seqs
            DEBUG [DATETIME] Next clustering at 39% identity
            DEBUG [DATETIME] Clustering at 39% identity yielded 45 seqs
            DEBUG [DATETIME] Next clustering at 44% identity
            DEBUG [DATETIME] Clustering at 44% identity yielded 57 seqs
            DEBUG [DATETIME] Next clustering at 42% identity
            DEBUG [DATETIME] Clustering at 42% identity yielded 52 seqs
            DEBUG [DATETIME] Next clustering at 41% identity
            DEBUG [DATETIME] Clustering at 41% identity yielded 52 seqs
            DEBUG [DATETIME] Next clustering at 40% identity
            DEBUG [DATETIME] Clustering at 40% identity yielded 50 seqs
            WARNING [DATETIME] Could not get within the targeted count range
            WARNING [DATETIME] The closest was 41% identity with 52 seqs
            DEBUG [DATETIME] Clustering at 41% identity yielded 52 seqs |}] ;
          Sh.readdir outdir |> Sh.eval |> [%sexp_of: string list] |> print_s ;
          [%expect
            {|
              (split___groupA.clu_41_all_seqs.fasta split___groupA.clu_41_rep_seq.fasta
               split___groupA.clu_41_cluster.tsv) |}] )
  end

  (* Partitions only include groups with sequences, (if you run the assert
     first.) *)
  let cluster_partitions : Seqs.partitions -> Opts.t -> unit =
   fun partitions opts ->
    Map.iteri partitions
      ~f:(fun ~key:group_id ~data:(_records, (ids_and_oc : Groups.ids_and_oc))
         ->
        let seqs = ids_and_oc.out_file in
        Logs.debug (fun m -> m "Clustering seqs (%s)" seqs) ;
        (* TODO: tolerance from opts? *)
        targeted_cluster (* The caller should ensure this won't fail. *)
          ~target_count:(Option.value_exn opts.target_cluster_count)
          ~tolerance:0.25 ~mmseqs_exe:opts.mmseqs_exe ~seqs
          ~cov_percent:opts.cov_percent ~threads:opts.threads
          ~outdir:opts.outdir ~group_id ;
        () )
end

let run_clustering partitions opts =
  match opts.Opts.target_cluster_count with
  | Some _ ->
      Logs.debug (fun m -> m "Running targeted clustering") ;
      Size_target.cluster_partitions partitions opts
  | None ->
      Logs.debug (fun m -> m "Running basic clustering") ;
      cluster_partitions partitions opts
