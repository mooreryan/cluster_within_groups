Seqs missing groups

  $ cluster_within_groups seqs.fa groups.tsv
  cluster_within_groups: ("Sequence ID has no group ID" s1)
  [123]

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
