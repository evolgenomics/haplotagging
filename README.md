# haplotagging
Code and barcode files related to processing haplotagging data

# Dependencies
- bcl2fastq v2.18.0 or above.
- bwa v0.6 or above.
- libgzstream 

# Strategy
Haplotagging uses a segmented combinatorial barcoding system in the standard Illumina Nextera indexing positions i5 and i7 to preserve linking information. To properly convert the data, our code expects the full set of R1, I1, I2, R2 fastq files, and assigns the barcode based on the look-up table segments A, B, C and D. It then encodes the barcode as comment fields BX, QX and RX (corresponding to barcode, quality strings, and corrected barcode tags, respectively) in a standard set of paired-end fastq files with R1 and R2. 

These comment fields can then be passed into a BAM file as BX, QX and RX tags using standard software like bwa with a -C switch.

Example bcl2fastq command:

bcl2fastq --use-bases-mask=Y150,I13,I13,Y149 --create-fastq-for-index-reads -r [INT] -w [INT] -d [INT] -p [INT] -R <run_dir, e.g. 190125_ST-J00101_0130_AHYJWTBBXX> --tiles s_[1-8] --output-dir=<output_dir> --interop-dir=<INTEROPT_DIR>  --reports-dir=<REPORT_DIR>  --stats-dir=<STATS_DIR> 

Here the options --use-bases-mask=Y150,I13,I13,Y149 allows the full use of all 13 positions in the index reads. Note that a single cycle is taken out of R2 to extend the I2 cycle to 13nt.

--create-fastq-for-index-reads is key here to allow our demultiplexing code to see the full, untrimmed barcodes.

# Best Practice Recommendations
Since around mid-2021, we and others have found concrete advantages to using barcode-first read mapppers like [EMA] (https://github.com/arshajii/ema). Specifically, EMA uses BWA's API to place reads, but does a better job of taking linked-reads (or "read clouds") into account. Please see their repo for details. 

For this reason, we recommend substituting EMA for the read mapping step. To do so, use our script `ema_prep.sh` to pre-process and sort the reads prior to mapping.

While we find EMA to be less polished than BWA and it currently involves additional overheads, we feel strongly that the improved read mapping, especially in complex regions, is well worth you trouble. Please consider adopting this recommendation in your pipeline.
