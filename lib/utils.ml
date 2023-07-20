open! Core
open Stdio

let test_group_data_file = "test_group_data.tsv"
let fasta_suffix = ".fasta"
let fasta_suffix_re = Re.compile @@ Re.seq [Re.str fasta_suffix; Re.eos]
let has_fasta_suffix s = Re.execp fasta_suffix_re s

let%test _ = not (has_fasta_suffix "apple")
let%test _ = not (has_fasta_suffix "apple.faa")
let%test _ = not (has_fasta_suffix "apple.fasta.gz")
let%test _ = has_fasta_suffix "apple.fasta"

let strip_fasta_suffix s = Re.replace_string fasta_suffix_re ~by:"" s

let%expect_test _ =
  [ strip_fasta_suffix "apple"
  ; strip_fasta_suffix "apple.faa"
  ; strip_fasta_suffix "apple.fasta.gz"
  ; strip_fasta_suffix "apple.fasta" ]
  |> [%sexp_of: string list] |> print_s ;
  [%expect {| (apple apple.faa apple.fasta.gz apple) |}]

(* Return list of entries in [path] as [path/entry] *)
let ls_dir path =
  List.fold ~init:[]
    ~f:(fun acc entry -> Filename.concat path entry :: acc)
    (Sys_unix.ls_dir path)

(* May raise some unix errors? *)
let rec rm_rf name =
  match Core_unix.lstat name with
  | {st_kind= S_DIR; _} ->
      List.iter (ls_dir name) ~f:rm_rf ;
      Core_unix.rmdir name
  | _ ->
      Core_unix.unlink name
  | exception Core_unix.Unix_error (ENOENT, _, _) ->
      ()

let with_temp_file ?(perm = 0o600) ?in_dir ?(prefix = "tmp") ?(suffix = "tmp") f
    =
  let file = Filename_unix.temp_file ~perm ?in_dir prefix suffix in
  Exn.protectx ~f
    ~finally:(fun name ->
      if Sys_unix.file_exists_exn name then Sys_unix.remove name )
    file

let with_temp_dir ?(perm = 0o700) ?in_dir ?(prefix = "tmp") ?(suffix = "tmp") f
    =
  let dir = Filename_unix.temp_dir ~perm ?in_dir prefix suffix in
  Exn.protectx ~f
    ~finally:(fun name -> if Sys_unix.file_exists_exn name then rm_rf name)
    dir
