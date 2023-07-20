Targeted clustering.  

  $ cluster_within_groups seqs.fasta groups.tsv --outdir=clusters --target-count=50 --threads=2 2> err 
  $ ../redact_log_timestamp err
  INFO [DATETIME] Getting seq IDs to group IDs
  INFO [DATETIME] Getting group info
  INFO [DATETIME] Reading seqs
  INFO [DATETIME] Generating partitions
  INFO [DATETIME] Checking partitions
  INFO [DATETIME] Writing partitions
  INFO [DATETIME] Clustering partitions
  DEBUG [DATETIME] Running targeted clustering
  DEBUG [DATETIME] Clustering seqs (clusters/split___groupA.fasta)
  DEBUG [DATETIME] Clustering at 65% identity yielded 162 seqs
  DEBUG [DATETIME] Next clustering at 47% identity
  DEBUG [DATETIME] Clustering at 47% identity yielded 90 seqs
  DEBUG [DATETIME] Next clustering at 38% identity
  DEBUG [DATETIME] Clustering at 38% identity yielded 66 seqs
  DEBUG [DATETIME] Next clustering at 34% identity
  DEBUG [DATETIME] Clustering at 34% identity yielded 59 seqs
  DEBUG [DATETIME] Clustering seqs (clusters/split___groupB.fasta)
  INFO [DATETIME] Group (groupB) had fewer seqs than target threshold, running fake clustering
  INFO [DATETIME] Writing cluster file
  INFO [DATETIME] Writing rep seqs file
  INFO [DATETIME] Done!

Output files

  $ ls
  clusters
  err
  groups.tsv
  seqs.fasta
  $ ls clusters
  cluster_rep_seq.fasta
  clusters.tsv
  split___groupA.clu_34_all_seqs.fasta
  split___groupA.clu_34_cluster.tsv
  split___groupA.clu_34_rep_seq.fasta
  split___groupA.fasta
  split___groupB.clu_NOT_CLUSTERED_all_seqs.fasta
  split___groupB.clu_NOT_CLUSTERED_cluster.tsv
  split___groupB.clu_NOT_CLUSTERED_rep_seq.fasta
  split___groupB.fasta
There should only be 20 groupB because it is less than the target.
  $ grep -c '^>' clusters/*rep_seq.fasta
  clusters/cluster_rep_seq.fasta:79
  clusters/split___groupA.clu_34_rep_seq.fasta:59
  clusters/split___groupB.clu_NOT_CLUSTERED_rep_seq.fasta:20
