open! Core

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
      (* Check if this sequence has an associated group ID. *)
      match Map.find seq_ids_to_group_ids seq_id with
      | None ->
          (* Ignore any sequence that doesn't have a group ID. But log that. *)
          Logs.warn (fun m ->
              m "%s has no group ID and will be ignored" seq_id ) ;
          grouped_seqs
      | Some group_id ->
          let group_info =
            (* If it has an associated group ID, then that group SHOULD have
               info. *)
            match Map.find group_info group_id with
            | Some result ->
                result
            | None ->
                failwith
                  [%string
                    "Group ID has no group info: %{group_id} (seq_id %{seq_id})"]
          in
          Map.update grouped_seqs group_id ~f:(function
            | None ->
                ([record], group_info)
            | Some (records, group_info) ->
                (record :: records, group_info) ) )

(* Fail unless each partition has at least one sequence. (Of course, clustering
   a 1 seq file is probably not what you want but it should at least not
   fail.) *)
let check_partitions : partitions -> unit =
 fun partitions ->
  if Map.is_empty partitions then
    raise_s
      [%message
        "Partitions contained no data. Does the groups file match the seqs \
         file?"] ;
  let errors =
    Map.fold partitions ~init:[]
      ~f:(fun
           ~key:group_id
           ~data:(records, (ids_and_oc : Groups.ids_and_oc))
           errors
         ->
        match records with
        | [] ->
            (group_id, ids_and_oc.out_file) :: errors
        | _ :: _ ->
            errors )
  in
  match errors with
  | [] ->
      ()
  | errors ->
      raise_s
        [%message
          "Some groups had no sequences" (errors : (string * string) list)]

let write_partitions : partitions -> unit =
 fun partitions ->
  Map.iter partitions ~f:(fun (records, (ids_and_oc : Groups.ids_and_oc)) ->
      Out_channel.with_file ids_and_oc.out_file ~f:(fun oc ->
          let record_lines =
            List.map records ~f:Bio_io.Fasta.Record.to_string
          in
          Out_channel.output_lines oc record_lines ) )
