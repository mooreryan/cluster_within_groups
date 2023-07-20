Basic usage

  $ cluster_within_groups seqs.fasta groups.tsv --outdir=clusters --min-seq-id=0.5 --cov=0.5 --threads=2 2> err
  $ ../redact_log_timestamp err
  INFO [DATETIME] Getting seq IDs to group IDs
  INFO [DATETIME] Getting group info
  INFO [DATETIME] Reading seqs
  INFO [DATETIME] Generating partitions
  INFO [DATETIME] Checking partitions
  INFO [DATETIME] Writing partitions
  INFO [DATETIME] Clustering partitions
  DEBUG [DATETIME] Running basic clustering
  DEBUG [DATETIME] Clustering seqs (clusters/split___nrdA.fasta)
  DEBUG [DATETIME] Clustering seqs (clusters/split___polA.fasta)
  DEBUG [DATETIME] Clustering seqs (clusters/split___rna_pol.fasta)
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
  split___nrdA.clu_all_seqs.fasta
  split___nrdA.clu_cluster.tsv
  split___nrdA.clu_rep_seq.fasta
  split___nrdA.fasta
  split___polA.clu_all_seqs.fasta
  split___polA.clu_cluster.tsv
  split___polA.clu_rep_seq.fasta
  split___polA.fasta
  split___rna_pol.clu_all_seqs.fasta
  split___rna_pol.clu_cluster.tsv
  split___rna_pol.clu_rep_seq.fasta
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
  P00582	P00582
  C1KTT1	C1KTT1
  C1KTT1	P07659
  
  ==> clusters/split___nrdA.clu_cluster.tsv <==
  P74240	P74240
  P50620	P50620
  P00452	P00452
  P00452	P37426
  
  ==> clusters/split___polA.clu_cluster.tsv <==
  P52026	P52026
  P52026	Q04957
  P00582	P00582
  
  ==> clusters/split___rna_pol.clu_cluster.tsv <==
  C1KTT1	C1KTT1
  C1KTT1	P07659

Check the combined outfiles

  $ grep '^>' clusters/cluster_rep_seq.fasta
  >sp|P74240|RIR1_SYNY3 Ribonucleoside-diphosphate reductase subunit alpha OS=Synechocystis sp. (strain PCC 6803 / Kazusa) OX=1111708 GN=nrdA PE=3 SV=1 
  >sp|P50620|RIR1_BACSU Ribonucleoside-diphosphate reductase subunit alpha OS=Bacillus subtilis (strain 168) OX=224308 GN=nrdE PE=1 SV=1 
  >sp|P00452|RIR1_ECOLI Ribonucleoside-diphosphate reductase 1 subunit alpha OS=Escherichia coli (strain K12) OX=83333 GN=nrdA PE=1 SV=2 
  >sp|P52026|DPO1_GEOSE DNA polymerase I OS=Geobacillus stearothermophilus OX=1422 GN=polA PE=1 SV=2 
  >sp|P00582|DPO1_ECOLI DNA polymerase I OS=Escherichia coli (strain K12) OX=83333 GN=polA PE=1 SV=1 
  >C1KTT1 
