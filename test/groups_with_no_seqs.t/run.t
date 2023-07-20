Groups with no sequences don't generate sequence files.

  $ cluster_within_groups seqs.fasta groups.tsv 2> err 
  $ ../redact_log_timestamp err
  INFO [DATETIME] Getting seq IDs to group IDs
  INFO [DATETIME] Getting group info
  INFO [DATETIME] Reading seqs
  INFO [DATETIME] Generating partitions
  INFO [DATETIME] Checking partitions
  INFO [DATETIME] Writing partitions
  INFO [DATETIME] Clustering partitions
  DEBUG [DATETIME] Running basic clustering
  DEBUG [DATETIME] Clustering seqs (./split___nrdA-g1.fasta)
  DEBUG [DATETIME] Clustering seqs (./split___nrdA-g2.fasta)
  INFO [DATETIME] Writing cluster file
  INFO [DATETIME] Writing rep seqs file
  INFO [DATETIME] Done!
  $ ls
  cluster_rep_seq.fasta
  clusters.tsv
  err
  groups.tsv
  seqs.fasta
  split___nrdA-g1.clu_all_seqs.fasta
  split___nrdA-g1.clu_cluster.tsv
  split___nrdA-g1.clu_rep_seq.fasta
  split___nrdA-g1.fasta
  split___nrdA-g2.clu_all_seqs.fasta
  split___nrdA-g2.clu_cluster.tsv
  split___nrdA-g2.clu_rep_seq.fasta
  split___nrdA-g2.fasta
