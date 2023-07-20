open! Core

include Expect_test_config

(* This is the same regex copied from the redact_log_timestamp file. *)
let timestamp =
  Re.compile
  @@ Re.Perl.re "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"

let redact_timestamp s = Re.replace_string timestamp ~by:"DATETIME" s

let sanitize s = redact_timestamp s
