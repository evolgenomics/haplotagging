#!/bin/bash
#This script prepares 16BCgen.fastq bins for mapping using EMA, and then takes its output and reverts it back to a standard haplotag BX bam file.
#Copyright (c) 2021 Marek Kucka

####### usage: for i in {001..500}; do qsub ema_align.sge.sh BBHN ema-bin-$i output-dir
#$ -pe parallel 3
#$ -l h_vmem=2G
#$ -N ema_align
#$ -o ./
#$ -j y
#$ -S /bin/bash
#$ -cwd
if [ ! -e "/tmp/mkucka" ];then mkdir -p /tmp/mkucka;fi
prefix=$1;
file=$2;
outdir=$3;
fbname=$(basename $file .bam)
echo $fbname
dir=$(dirname $file)
echo $dir
/fml/chones/local/bin/ema align -t 3 -d -r /fml/chones/genome/gbdb/gasAcu1/gasAcu1.fa -R '@RG\tID:BBHN_plate3\tSM:NovaSeqS4' -p 10x -s $file |
/fml/chones/local/bin/samtools sort -@ 3 -O bam -o /tmp/mkucka/$prefix.$fbname.bam -;
/fml/chones/local/bin/samtools index /tmp/mkucka/$prefix.$fbname.bam
mv /tmp/mkucka/$prefix.$fbname.bam* $outdir/
samtools view -h $outdir/$prefix.$fbname.bam | awk 'BEGIN {split("AAAT,AAAG,AAAC,AATA,AATT,AATG,AATC,AAGA,AAGT,AAGG,AAGC,AACA,AACT,AACG,AACC,ATAA,ATAT,ATAG,ATAC,ATTA,ATTT,ATTG,ATTC,ATGA,ATGT,ATGG,ATGC,ATCA,ATCT,ATCG,ATCC,AGAA,AGAT,AGAG,AGAC,AGTA,AGTT,AGTG,AGTC,AGGA,AGGT,AGGG,AGGC,AGCA,AGCT,AGCG,AGCC,ACAA,ACAT,ACAG,ACAC,ACTA,ACTT,ACTG,ACTC,ACGA,ACGT,ACGG,ACGC,ACCA,ACCT,ACCG,ACCC,TAAA,TAAT,TAAG,TAAC,TATA,TATT,TATG,TATC,TAGA,TAGT,TAGG,TAGC,TACA,TACT,TACG,TACC,TTAA,TTAT,TTAG,TTAC,TTTA,TTTT,TTTG,TTTC,TTGA,TTGT,TTGG,TTGC,TTCA,TTCT,TTCG,TTCC,TGAA",val,","); \
for(i=1;i<=96;i++){lookup[val[i]]=sprintf("%02d",i)}};/BX:Z:/ {match($0,"BX:Z");bx=substr($0,RSTART,23);out="BX:Z:A"lookup[substr(bx,6,4)]"C"lookup[substr(bx,10,4)]"B"lookup[substr(bx,14,4)]"D"lookup[substr(bx,18,4)]substr(bx,22,2);gsub(bx,out,$0);print $0}; !/BX:Z/' | \
samtools view -@3 - -O BAM -o $outdir/$prefix.$fbname.BXnum.bam;
samtools index -@3 $outdir/$prefix.$fbname.BXnum.bam;
