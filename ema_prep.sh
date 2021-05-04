#!/bin/bash
read1=$1
read2=${read1/_R1/_R2}
echo "Adding 16 base barcode to $read1..."
echo "zcat $read1 | 16BaseBCGen ${read1/.fastq.gz} | bgzip -@ 16 > ${read1/.fastq/.16BCgen.fastq}"
zcat $read1 | 16BaseBCGen ${read1/.fastq.gz} | bgzip -@ 16 > ${read1/.fastq/.16BCgen.fastq}
echo "Making symlink for $read2.";
echo "ln -s `pwd`/${read2/.fastq/.16BCgen.fastq}"
ln -s `pwd`/${read2/.fastq/.16BCgen.fastq}
