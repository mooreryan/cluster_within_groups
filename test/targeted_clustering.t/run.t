Targeted clustering.  

  $ cluster_within_groups seqs.fa groups.tsv --outdir=clusters --target-count=50 --threads=2 2> err 
  $ ../redact_log_timestamp err
  INFO [DATETIME] Getting seq IDs to group IDs
  INFO [DATETIME] Getting group info
  INFO [DATETIME] Reading seqs
  INFO [DATETIME] Generating partitions
  INFO [DATETIME] Checking partitions
  INFO [DATETIME] Writing partitions
  INFO [DATETIME] Clustering partitions
  DEBUG [DATETIME] Running targeted clustering
  DEBUG [DATETIME] Clustering seqs (clusters/split___groupA.fa)
  DEBUG [DATETIME] Clustering at 65% identity yielded 162 seqs
  DEBUG [DATETIME] Next clustering at 48% identity
  DEBUG [DATETIME] Clustering at 48% identity yielded 93 seqs
  DEBUG [DATETIME] Next clustering at 39% identity
  DEBUG [DATETIME] Clustering at 39% identity yielded 68 seqs
  DEBUG [DATETIME] Next clustering at 35% identity
  DEBUG [DATETIME] Clustering at 35% identity yielded 59 seqs
  DEBUG [DATETIME] Clustering seqs (clusters/split___groupB.fa)
  INFO [DATETIME] Group (groupB) had fewer seqs than target threshold, running fake clustering
  INFO [DATETIME] Writing cluster file
  INFO [DATETIME] Writing rep seqs file
  INFO [DATETIME] Done!

Output files

  $ ls
  clusters
  err
  groups.tsv
  seqs.fa
  $ ls clusters
  cluster_rep_seqs.fa
  clusters.tsv
  split___groupA.clu_35_all_seqs.fasta
  split___groupA.clu_35_cluster.tsv
  split___groupA.clu_35_rep_seq.fasta
  split___groupA.fa
  split___groupB.clu_NOT_CLUSTERED_all_seqs.fasta
  split___groupB.clu_NOT_CLUSTERED_cluster.tsv
  split___groupB.clu_NOT_CLUSTERED_rep_seq.fasta
  split___groupB.fa
There should only be 20 groupB because it is less than the target.
  $ grep -c '^>' clusters/*fa clusters/*rep_seq.fasta
  clusters/cluster_rep_seqs.fa:79
  clusters/split___groupA.fa:180
  clusters/split___groupB.fa:20
  clusters/split___groupA.clu_35_rep_seq.fasta:59
  clusters/split___groupB.clu_NOT_CLUSTERED_rep_seq.fasta:20
