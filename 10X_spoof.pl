use warnings;
use strict;

#Authors: Frank Chan and Marek Kucka

#Usage: perl 10X_spoof.pl <input_read1_with_BX.fastq.gz> 
#Note: it requires that there are barcode listing of the format
#AxxBxxCxxDxx  10X_Barcode

my $fastq=$ARGV[0];
my $fastq_out=$fastq;
$fastq_out=~s/.fastq.gz/.10X_spoofed.fastq.gz/;

my %barcodes = map {chomp; my @tmp = split; $tmp[0] => $tmp[1]; } `awk '/^A..C..B..D../' top5M.barcodes.GEM.list`;
my @chars = ("A","C","T","G");
my $bx = "";
my $line = -1;
my $c= "";
my $lane = "";

open (OUT, " | gzip -c > $fastq_out");
open (R1, "zcat $fastq |");
while (<R1>) {
        $line++;
        #e.g., @ST-J00101:159:HF5TFBBXY:4:1101:30249:1156 BX:Z:A33C26B95D10
        ($lane, $bx, $c, $line) = ($1, $2, $3, 0) if (/ST-J00101\:\d+:\S+:(\d):\d+:\d+:\d+\s+BX:Z:(A..(C..)B..D..)/);
        
        if (exists($barcodes{$bx})) {
               if ($line == 0 || $line == 2) {
                       print;
               } elsif ($line == 1) {
                       my $string;
                       $string .= $chars[rand @chars] for 1..7;
                       print "$barcodes{$bx}".$string.$_;
               } elsif ($line == 3) {
                       print "".("J" x 23)."$_";
                       $bx = "";
               }
       } else {
                if ($line == 0 || $line == 2) {
                        print;
                } elsif ($line == 1) {
                        my $string;
                        print "".("N" x 23).$_;
                } elsif ($line == 3) {
                        print "".("#" x 23).$_;
                }
       }
}
close (R1);
close (OUT);
