Seqs missing groups

  $ if [ -d clusters ]; then rm -r clusters; fi
  $ cluster_within_groups seqs.fasta groups.tsv --threads=2 2> err
  [123]
  $ ../redact_log_timestamp err
  INFO [DATETIME] Getting seq IDs to group IDs
  INFO [DATETIME] Getting group info
  INFO [DATETIME] Reading seqs
  INFO [DATETIME] Generating partitions
  WARNING [DATETIME] s1 has no group ID and will be ignored
  WARNING [DATETIME] s2 has no group ID and will be ignored
  INFO [DATETIME] Checking partitions
  cluster_within_groups: "Partitions contained no data. Does the groups file match the seqs file?"

Non unique seq IDs

  $ if [ -d clusters ]; then rm -r clusters; fi
  $ cluster_within_groups seqs.fasta non_unique_seqs.tsv --threads=2 2> err
  [123]
  $ ../redact_log_timestamp err
  INFO [DATETIME] Getting seq IDs to group IDs
  cluster_within_groups: ("Duplicate sequence ID" s1)

Too many fields 

  $ if [ -d clusters ]; then rm -r clusters; fi
  $ cluster_within_groups seqs.fasta too_many_fields.tsv --threads=2 2> err
  [123]
  $ ../redact_log_timestamp err
  INFO [DATETIME] Getting seq IDs to group IDs
  cluster_within_groups: ("bad line in group file" (line (s2 groupA yo)))

Too few fields

  $ if [ -d clusters ]; then rm -r clusters; fi
  $ cluster_within_groups seqs.fasta too_few_fields.tsv --threads=2 2> err
  [123]
  $ ../redact_log_timestamp err
  INFO [DATETIME] Getting seq IDs to group IDs
  cluster_within_groups: ("bad line in group file" (line (s1,groupA)))

Pipe/subshell redirection won't work

  $ if [ -d clusters ]; then rm -r clusters; fi
  $ cat good_groups.tsv | cluster_within_groups seqs.fasta /dev/stdin --threads=2 2> err
  [123]
  $ ../redact_log_timestamp err
  INFO [DATETIME] Getting seq IDs to group IDs
  INFO [DATETIME] Getting group info
  cluster_within_groups: ("Expected a non-empty map. Did you try a pipe, subshell, or reading from stdin?"
                           (map group_info))

Directory already exists

  $ mkdir -p already_there
  $ cluster_within_groups good_seqs.fasta good_groups.tsv --outdir=already_there --threads=2 2> err
  [123]
  $ ../redact_log_timestamp err
  cluster_within_groups: ("outdir already exists" (outdir already_there))
