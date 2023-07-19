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
  {groups_file; seqs_file; outdir; threads; min_seq_id; cov_percent; mmseqs_exe}
