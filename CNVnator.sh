#!/bin/sh
#
#$ -v PATH=/common/genomics-core/anaconda2/bin:/opt/sge/bin:/opt/sge/bin/lx-amd64:/opt/sge/bin:/opt/sge/bin/lx-amd64:/opt/sge/bin:/opt/sge/bin/lx-amd64:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/hpc/scripts:/hpc/apps/python/2.7.15/bin:/hpc/apps/root/6.20.04/bin
#$ -l mem_free=90G

source /hpc/apps/root/6.20.04/bin/thisroot.sh
module load cnvnator
module load samtools
module load root

sample=$1
Ref='/common/genomics-core/reference/BWA/GRCm38_WGS/GCA_000001635.5_GRCm38.p3_no_alt_analysis_set.fna'

#EXTRACTING READ MAPPING FROM BAM/SAM FILES
/hpc/apps/cnvnator/0.4.1/bin/cnvnator -root ${sample}"_100bp.root" -genome $Ref -chrom chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chrX chrY -tree ${sample}"_dedup_reads.bam"

#/hpc/apps/cnvnator/0.4.1/bin/cnvnator -root 2.root -genome mm9 -chrom chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chrX chrY chrM -tree 2_sorted_reads_final.bam


#GENERATING A READ DEPTH HISTOGRAM
/hpc/apps/cnvnator/0.4.1/bin/cnvnator -root ${sample}"_100bp.root" -his 100 -chrom chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chrX chrY -d /common/genomics-core/reference/CNVnator/mm10/fasta/


#CALCULATING STATISTICS
#This step must be completed before proceeding to partitioning and CNV calling
/hpc/apps/cnvnator/0.4.1/bin/cnvnator -root ${sample}"_100bp.root" -stat 100

#RD SIGNAL PARTITIONING
#Partitioning is the most time consuming step
/hpc/apps/cnvnator/0.4.1/bin/cnvnator -root ${sample}"_100bp.root" -partition 100

#CNV CALLING
/hpc/apps/cnvnator/0.4.1/bin/cnvnator -root ${sample}"_100bp.root" -call 100 > "CNV_out_"${sample}"_100bp.txt"

#REPORTING READ SUPPORT


perl ./cnvnator2VCF.pl -prefix $1 -reference mm10 "CNV_out_"${sample}"_100bp.txt" /common/genomics-core/reference/CNVnator/mm10/fasta/ > ${sample}"_100bp_CNV.vcf"

/common/genomics-core/anaconda2/bin/bedtools intersect -a "${1}_100bp_CNV.vcf" -b /common/genomics-core/reference/CNVnator/mm10/mm10_chrs_N.bed > $1"_100bp_CNV_Ns_region.vcf"

/common/genomics-core/anaconda2/bin/bedtools intersect -a $1"_100bp_CNV.vcf" -b /common/genomics-core/reference/CNVnator/mm10/mm10_chrs_N.bed  -v > $1"_100bp_CNV_wo_Ns_region.vcf"

echo "Subject: CNVnator calling is done for $1" | sendmail -v di.wu@cshs.org
