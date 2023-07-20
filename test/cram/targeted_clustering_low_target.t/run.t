This target count is too low...it is impossible to get, so it should cluster at 30%.

  $ cluster_within_groups seqs.fasta groups.tsv --outdir=clusters --target-count=1 --threads=2 2> err 
  $ ../redact_log_timestamp err
  INFO [DATETIME] Getting seq IDs to group IDs
  INFO [DATETIME] Getting group info
  INFO [DATETIME] Reading seqs
  INFO [DATETIME] Generating partitions
  INFO [DATETIME] Checking partitions
  INFO [DATETIME] Writing partitions
  INFO [DATETIME] Clustering partitions
  DEBUG [DATETIME] Running targeted clustering
  DEBUG [DATETIME] Clustering seqs (clusters/split___nrdA.fasta)
  DEBUG [DATETIME] Clustering at 65% identity yielded 3 seqs
  DEBUG [DATETIME] Next clustering at 47% identity
  DEBUG [DATETIME] Clustering at 47% identity yielded 3 seqs
  DEBUG [DATETIME] Next clustering at 38% identity
  DEBUG [DATETIME] Clustering at 38% identity yielded 3 seqs
  DEBUG [DATETIME] Next clustering at 34% identity
  DEBUG [DATETIME] Clustering at 34% identity yielded 3 seqs
  DEBUG [DATETIME] Next clustering at 32% identity
  DEBUG [DATETIME] Clustering at 32% identity yielded 3 seqs
  DEBUG [DATETIME] Next clustering at 31% identity
  DEBUG [DATETIME] Clustering at 31% identity yielded 3 seqs
  DEBUG [DATETIME] Next clustering at 30% identity
  DEBUG [DATETIME] Clustering at 30% identity yielded 3 seqs
  WARNING [DATETIME] Could not get within the targeted count range
  WARNING [DATETIME] The closest was 32% identity with 3 seqs
  DEBUG [DATETIME] Clustering at 32% identity yielded 3 seqs
  DEBUG [DATETIME] Clustering seqs (clusters/split___polA.fasta)
  DEBUG [DATETIME] Clustering at 65% identity yielded 2 seqs
  DEBUG [DATETIME] Next clustering at 47% identity
  DEBUG [DATETIME] Clustering at 47% identity yielded 2 seqs
  DEBUG [DATETIME] Next clustering at 38% identity
  DEBUG [DATETIME] Clustering at 38% identity yielded 1 seqs
  DEBUG [DATETIME] Clustering seqs (clusters/split___rna_pol.fasta)
  DEBUG [DATETIME] Clustering at 65% identity yielded 1 seqs
  INFO [DATETIME] Writing cluster file
  INFO [DATETIME] Writing rep seqs file
  INFO [DATETIME] Done!

Check the files

  $ ls
  clusters
  err
  groups.tsv
  seqs.fasta
  $ ls clusters
  cluster_rep_seq.fasta
  clusters.tsv
  split___nrdA.clu_32_all_seqs.fasta
  split___nrdA.clu_32_cluster.tsv
  split___nrdA.clu_32_rep_seq.fasta
  split___nrdA.fasta
  split___polA.clu_38_all_seqs.fasta
  split___polA.clu_38_cluster.tsv
  split___polA.clu_38_rep_seq.fasta
  split___polA.fasta
  split___rna_pol.clu_65_all_seqs.fasta
  split___rna_pol.clu_65_cluster.tsv
  split___rna_pol.clu_65_rep_seq.fasta
  split___rna_pol.fasta

Check the seqs

  $ head -n100 clusters/*.tsv
  ==> clusters/clusters.tsv <==
  P74240	P74240
  P50620	P50620
  P00452	P00452
  P00452	P37426
  P52026	P52026
  P52026	Q04957
  P52026	P00582
  C1KTT1	C1KTT1
  C1KTT1	P07659
  
  ==> clusters/split___nrdA.clu_32_cluster.tsv <==
  P74240	P74240
  P50620	P50620
  P00452	P00452
  P00452	P37426
  
  ==> clusters/split___polA.clu_38_cluster.tsv <==
  P52026	P52026
  P52026	Q04957
  P52026	P00582
  
  ==> clusters/split___rna_pol.clu_65_cluster.tsv <==
  C1KTT1	C1KTT1
  C1KTT1	P07659

Check the combined outfiles

  $ grep '^>' clusters/cluster_rep_seq.fasta
  >sp|P74240|RIR1_SYNY3 Ribonucleoside-diphosphate reductase subunit alpha OS=Synechocystis sp. (strain PCC 6803 / Kazusa) OX=1111708 GN=nrdA PE=3 SV=1 
  >sp|P50620|RIR1_BACSU Ribonucleoside-diphosphate reductase subunit alpha OS=Bacillus subtilis (strain 168) OX=224308 GN=nrdE PE=1 SV=1 
  >sp|P00452|RIR1_ECOLI Ribonucleoside-diphosphate reductase 1 subunit alpha OS=Escherichia coli (strain K12) OX=83333 GN=nrdA PE=1 SV=2 
  >sp|P52026|DPO1_GEOSE DNA polymerase I OS=Geobacillus stearothermophilus OX=1422 GN=polA PE=1 SV=2 
  >C1KTT1 
