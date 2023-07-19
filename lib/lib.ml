open! Core

module Sh = Shexp_process

let test_group_data_file = "test_group_data.tsv"
let fa_suffix = ".fa"
let fa_suffix_re = Re.compile @@ Re.seq [Re.str fa_suffix; Re.eos]
let has_fa_suffix s = Re.execp fa_suffix_re s

let%test _ = not (has_fa_suffix "apple")
let%test _ = not (has_fa_suffix "apple.faa")
let%test _ = not (has_fa_suffix "apple.fa.gz")
let%test _ = has_fa_suffix "apple.fa"

let strip_fa_suffix s = Re.replace_string fa_suffix_re ~by:"" s

let%expect_test _ =
  [ strip_fa_suffix "apple"
  ; strip_fa_suffix "apple.faa"
  ; strip_fa_suffix "apple.fa.gz"
  ; strip_fa_suffix "apple.fa" ]
  |> [%sexp_of: string list] |> print_s ;
  [%expect {| (apple apple.faa apple.fa.gz apple) |}]

module Opts = struct
  type t =
    { groups_file: string
    ; seqs_file: string
    ; outdir: string
    ; threads: int
    ; min_seq_id: float
    ; cov_percent: float
    ; mmseqs_exe: string }

  (* For cmdliner *)
  let v ~groups_file ~seqs_file ~outdir ~threads ~min_seq_id ~cov_percent
      ~mmseqs_exe =
    { groups_file
    ; seqs_file
    ; outdir
    ; threads
    ; min_seq_id
    ; cov_percent
    ; mmseqs_exe }
end

(* Dealing with sequence groupings *)
module Groups = struct
  type ids_and_oc =
    {seq_ids: Set.M(String).t; oc: Out_channel.t; out_file: string}
  [@@deriving sexp_of]

  (** This is the group_id => seqs_ids, oc, and out_file name. *)
  type group_info = ids_and_oc Map.M(String).t [@@deriving sexp_of]

  type seq_ids_to_group_ids = string Map.M(String).t [@@deriving sexp_of]

  let read_group_info : file:string -> outdir:string -> group_info =
   fun ~file ~outdir ->
    let parse_line line =
      let tokens = String.split line ~on:'\t' in
      match tokens with
      | [seq_id; group_id] ->
          (group_id, seq_id)
      | _ ->
          raise_s
            [%message "bad line in group file" ~line:(tokens : string list)]
    in
    let parsed_lines_to_map :
        (string * string) list -> outdir:string -> group_info =
     fun parsed_lines ~outdir ->
      Map.of_alist_fold
        (module String)
        parsed_lines
        ~init:(Set.empty (module String))
        ~f:Set.add
      |> Map.mapi ~f:(fun ~key:group_id ~data:seq_ids ->
             let file = outdir ^/ [%string "split___%{group_id}%{fa_suffix}"] in
             {seq_ids; oc= Out_channel.create file; out_file= file} )
    in
    In_channel.read_lines file |> List.map ~f:parse_line
    |> parsed_lines_to_map ~outdir

  let close_out_channels ids_and_oc =
    Map.iter ids_and_oc ~f:(fun {oc; _} -> Out_channel.close oc)

  let%expect_test "read_group_info" =
    let groups = read_group_info ~file:test_group_data_file ~outdir:"." in
    groups |> [%sexp_of: group_info] |> print_s ;
    [%expect
      {|
      ((groupA
        ((seq_ids (seq1 seq3)) (oc <Out_channel.t>) (out_file ./split___groupA.fa)))
       (groupB
        ((seq_ids (seq2)) (oc <Out_channel.t>) (out_file ./split___groupB.fa)))) |}] ;
    close_out_channels groups

  (* Just go through the file twice...much simpler. *)
  let read_seq_ids_to_group_ids file =
    let parse_line line =
      let tokens = String.split line ~on:'\t' in
      match tokens with
      | [seq_id; group_id] ->
          (seq_id, group_id)
      | _ ->
          raise_s
            [%message "bad line in group file" ~line:(tokens : string list)]
    in
    let parsed_lines = In_channel.read_lines file |> List.map ~f:parse_line in
    match Map.of_alist (module String) parsed_lines with
    | `Ok result ->
        result
    | `Duplicate_key seq_id ->
        raise_s [%message "Duplicate sequence ID" seq_id]

  let%expect_test "read_seq_ids_to_group_ids" =
    read_seq_ids_to_group_ids test_group_data_file
    |> [%sexp_of: seq_ids_to_group_ids] |> print_s ;
    [%expect {| ((seq1 groupA) (seq2 groupB) (seq3 groupA)) |}]
end

module Seqs = struct
  (* Maps the group_id to the sequences in the group as well as the outchannel
     they will be written to. *)
  type partitions =
    (Bio_io.Fasta.Record.t list * Groups.ids_and_oc) Map.M(String).t
  [@@deriving sexp_of]

  let read file = Bio_io.Fasta.In_channel.with_file_records file

  let partition :
         records:Bio_io.Fasta.Record.t list
      -> seq_ids_to_group_ids:Groups.seq_ids_to_group_ids
      -> group_info:Groups.group_info
      -> partitions =
   fun ~records ~seq_ids_to_group_ids ~group_info ->
    List.fold records
      ~init:(Map.empty (module String))
      ~f:(fun grouped_seqs record ->
        let open Bio_io.Fasta in
        let seq_id = Record.id record in
        let group_id =
          match Map.find seq_ids_to_group_ids seq_id with
          | Some result ->
              result
          | None ->
              raise_s [%message "Sequence ID has no group ID" seq_id]
        in
        let group_info =
          Map.find group_info group_id
          (* This one really should be a bug. *)
          |> Option.value_exn ~here:[%here]
               ~message:[%string "Group ID has no group info: %{group_id}"]
        in
        Map.update grouped_seqs group_id ~f:(function
          | None ->
              ([record], group_info)
          | Some (records, group_info) ->
              (record :: records, group_info) ) )

  let write_partitions : partitions -> unit =
   fun partitions ->
    Map.iter partitions ~f:(fun (records, (ids_and_oc : Groups.ids_and_oc)) ->
        let oc = ids_and_oc.oc in
        let record_lines = List.map records ~f:Bio_io.Fasta.Record.to_string in
        Out_channel.output_lines oc record_lines ;
        Out_channel.close oc )
end

let%expect_test _ =
  let seq_ids_to_group_ids =
    Groups.read_seq_ids_to_group_ids test_group_data_file
  in
  let group_info =
    Groups.read_group_info ~file:test_group_data_file ~outdir:"."
  in
  let records = Seqs.read "test_seqs.fa" in
  let partitions = Seqs.partition ~records ~seq_ids_to_group_ids ~group_info in
  partitions |> [%sexp_of: Seqs.partitions] |> Stdio.print_s ;
  [%expect
    {|
  ((groupA
    ((((id seq3) (desc ()) (seq GGGGG)) ((id seq1) (desc ()) (seq AAAAA)))
     ((seq_ids (seq1 seq3)) (oc <Out_channel.t>)
      (out_file ./split___groupA.fa))))
   (groupB
    ((((id seq2) (desc ()) (seq CCCCC)))
     ((seq_ids (seq2)) (oc <Out_channel.t>) (out_file ./split___groupB.fa))))) |}]

module Mmseqs = struct
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

  let cluster_partitions : Groups.group_info -> Opts.t -> unit =
   fun group_info opts ->
    Map.iter group_info ~f:(fun (ids_and_oc : Groups.ids_and_oc) ->
        let seqs = ids_and_oc.out_file in
        let out_basename = strip_fa_suffix seqs ^ ".clu" in
        run ~mmseqs_exe:opts.mmseqs_exe ~seqs ~out_basename
          ~cov_percent:opts.cov_percent ~min_seq_id:opts.min_seq_id
          ~threads:opts.threads ;
        () )

  let glob path =
    (* Should have wordexp on this platform. *)
    let wordexp = Core_unix.wordexp |> Or_error.ok_exn in
    wordexp path |> Array.to_list

  let cat_rep_seqs outdir =
    let outfile = outdir ^/ [%string "cluster_rep_seqs%{fa_suffix}"] in
    Sh.run "cat" (glob (outdir ^ "/*rep_seq.fasta"))
    |> Sh.stdout_to outfile |> Sh.eval

  let cat_clu_tsv outdir =
    let outfile = outdir ^/ [%string "clusters.tsv"] in
    Sh.run "cat" (glob (outdir ^ "/*.tsv")) |> Sh.stdout_to outfile |> Sh.eval
end

let run : Opts.t -> unit =
 fun opts ->
  if not (Sys_unix.file_exists_exn opts.outdir) then
    Core_unix.mkdir_p opts.outdir ;
  let seq_ids_to_group_ids =
    Groups.read_seq_ids_to_group_ids opts.groups_file
  in
  let group_info =
    Groups.read_group_info ~file:opts.groups_file ~outdir:opts.outdir
  in
  let records = Seqs.read opts.seqs_file in
  let partitions = Seqs.partition ~records ~seq_ids_to_group_ids ~group_info in
  Seqs.write_partitions partitions ;
  Mmseqs.cluster_partitions group_info opts ;
  Mmseqs.cat_clu_tsv opts.outdir ;
  Mmseqs.cat_rep_seqs opts.outdir ;
  ()

let run opts = try Ok (run opts) with exn -> Error (Exn.to_string exn)

(* find test -name '*.fasta' -type f -print0 | xargs -0 *)
