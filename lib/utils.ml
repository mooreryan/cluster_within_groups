open! Core
open Stdio

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
