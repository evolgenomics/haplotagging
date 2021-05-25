#!/bin/bash
read1=$1
read2=${read1/_R1/_R2}
echo "Adding 16 base barcode to $read1..."
echo "zcat $read1 | 16BaseBCGen ${read1/.fastq.gz} | bgzip -@ 16 > ${read1/.fastq/.16BCgen.fastq}"
zcat $read1 | 16BaseBCGen ${read1/.fastq.gz} | bgzip -@ 16 > ${read1/.fastq/.16BCgen.fastq}
echo "Making symlink for $read2.";
echo "ln -s `pwd`/${read2/.fastq/.16BCgen.fastq}"
ln -s `pwd`/${read2/.fastq/.16BCgen.fastq}

cut -f 2 ${read1/.fastq.gz}_HaploTag_to_16BaseBCs | tail +2 > ${read1/.fastq.gz}_HaploTag_to_16BaseBCs.ema
stem=${read1/.fastq.gz/}

#Generate first command for ema count and preproc
echo "Run: 
paste <(pigz -c -d ${read1/.fastq/.16BCgen.fastq} | paste - - - - | awk '{print \$1\"\\t\"\$5\"\\t\"\$6\"\\t\"\$7}') <(pigz -c -d ${read2/.fastq/.16BCgen.fastq} | paste - - - - | awk '{print \$1\"\\t\"\$5\"\\t\"\$6\"\\t\"\$7}' ) | tr \"\\t\" \"\\n\" | ema count -w ${stem}_HaploTag_to_16BaseBCs.ema -o $stem.16BCgen 2> $stem.16BCgen.log; paste <(pigz -c -d ${read1/.fastq/.16BCgen.fastq} | paste - - - - | awk '{print \$1\"\\t\"\$5\"\\t\"\$6\"\\t\"\$7}') <(pigz -c -d ${read2/.fastq/.16BCgen.fastq} | paste - - - - | awk '{print \$1\"\\t\"\$5\"\\t\"\$6\"\\t\"\$7}' ) | tr \"\\t\" \"\\n\" | ema preproc -w ${stem}_HaploTag_to_16BaseBCs.ema -n 500 -t 40 -o ${stem}_outdir ${stem}_HaploTag_to_16BaseBCs.ema-ncnt 2>&1 | tee ${stem}_preproc.log "

#Then generate the command for ema align
echo "Then run:
parallel --bar -j10 \"ema align -t 4 -d -r /fml/chones/data/Marek/Run177_L3-BloomS_GM_19-plex_HAPLOv3/GRCh38_ref-genome/GRCh38_full_analysis_set_plus_decoy_hla.fa -p 10x -s {} | samtools sort -@ 4 -O bam -l 0 -m 4G -o {}.bam -\" ::: ${stem}_outdir/ema-bin-???"
