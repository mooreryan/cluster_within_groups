Seqs in fasta file with no group are ignored.

  $ cluster_within_groups seqs.fasta groups.tsv --threads=2 2> err 
  $ ../redact_log_timestamp err
  INFO [DATETIME] Getting seq IDs to group IDs
  INFO [DATETIME] Getting group info
  INFO [DATETIME] Reading seqs
  INFO [DATETIME] Generating partitions
  WARNING [DATETIME] RIR1_BACSU has no group ID and will be ignored
  INFO [DATETIME] Checking partitions
  INFO [DATETIME] Writing partitions
  INFO [DATETIME] Clustering partitions
  DEBUG [DATETIME] Running basic clustering
  DEBUG [DATETIME] Clustering seqs (./split___nrdA-g1.fasta)
  DEBUG [DATETIME] Clustering seqs (./split___nrdA-g2.fasta)
  INFO [DATETIME] Writing cluster file
  INFO [DATETIME] Writing rep seqs file
  INFO [DATETIME] Done!
