open! Core

(* Dealing with sequence groupings *)

(* Don't keep the out_channel here as we only want to open files that have
   sequences to write. (Ie if a group has no seqs in the fasta, we don't want
   the out_channel.create fun to create an empty file.) *)
type ids_and_oc = {seq_ids: Set.M(String).t; out_file: string}
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
        raise_s [%message "bad line in group file" ~line:(tokens : string list)]
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
           let file =
             outdir ^/ [%string "split___%{group_id}%{Utils.fasta_suffix}"]
           in
           {seq_ids; out_file= file} )
  in
  In_channel.read_lines file |> List.map ~f:parse_line
  |> parsed_lines_to_map ~outdir

let%expect_test "read_group_info" =
  let groups = read_group_info ~file:Utils.test_group_data_file ~outdir:"." in
  groups |> [%sexp_of: group_info] |> print_s ;
  [%expect
    {|
      ((groupA ((seq_ids (seq1 seq3)) (out_file ./split___groupA.fasta)))
       (groupB ((seq_ids (seq2)) (out_file ./split___groupB.fasta)))) |}]

(* Just go through the file twice...much simpler. *)
let read_seq_ids_to_group_ids file =
  let parse_line line =
    let tokens = String.split line ~on:'\t' in
    match tokens with
    | [seq_id; group_id] ->
        (seq_id, group_id)
    | _ ->
        raise_s [%message "bad line in group file" ~line:(tokens : string list)]
  in
  let parsed_lines = In_channel.read_lines file |> List.map ~f:parse_line in
  match Map.of_alist (module String) parsed_lines with
  | `Ok result ->
      result
  | `Duplicate_key seq_id ->
      raise_s [%message "Duplicate sequence ID" seq_id]

let%expect_test "read_seq_ids_to_group_ids" =
  read_seq_ids_to_group_ids Utils.test_group_data_file
  |> [%sexp_of: seq_ids_to_group_ids] |> print_s ;
  [%expect {| ((seq1 groupA) (seq2 groupB) (seq3 groupA)) |}]
