Seqs missing groups

  $ cluster_within_groups seqs.fa groups.tsv 2> err
  [123]
  $ ../redact_log_timestamp err
  WARNING [DATETIME] s1 has no group ID and will be ignored
  WARNING [DATETIME] s2 has no group ID and will be ignored
  cluster_within_groups: "Partitions contained no data. Does the groups file match the seqs file?"

Non unique seq IDs

  $ cluster_within_groups seqs.fa non_unique_seqs.tsv
  cluster_within_groups: ("Duplicate sequence ID" s1)
  [123]

Too many fields 

  $ cluster_within_groups seqs.fa too_many_fields.tsv
  cluster_within_groups: ("bad line in group file" (line (s2 groupA yo)))
  [123]

Too few fields

  $ cluster_within_groups seqs.fa too_few_fields.tsv
  cluster_within_groups: ("bad line in group file" (line (s1,groupA)))
  [123]

Pipe/subshell redirection won't work

  $ cat good_groups.tsv | cluster_within_groups seqs.fa /dev/stdin
  cluster_within_groups: ("Expected a non-empty map. Did you try a pipe, subshell, or reading from stdin?"
                           (map group_info))
  [123]

