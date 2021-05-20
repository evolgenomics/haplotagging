use warnings;
use strict;

#Authors: Frank Chan and Marek Kucka

#Usage: perl 10X_spoof.pl <input_read1_with_BX.fastq.gz> [verbose] 
#For the verbose mode, an initial 3 fastq reads will be printed.
##Note: it requires a barcode listing file top5M.barcodes.GEM.list of the format
#AxxBxxCxxDxx  10X_Barcode

my $fastq=$ARGV[0];
my $verbose=$ARGV[1];
my $fastq_out=$fastq;
$fastq_out=~s/.fastq.gz/.10X_spoofed.fastq.gz/;

my %barcodes = map {chomp; my @tmp = split; $tmp[0] => $tmp[1]; } `awk '/^A..C..B..D../' top5M.barcodes.GEM.list`;
my @chars = ("A","C","T","G");
my $bx = "";
my $line = 3;
my $c= "";
my $lane = "";
my $bc_flag = 0;
my $nbc_flag = 0;

if ($verbose ne "") {
	#Dumps out the first 12 lines for checking
	open (R1, "zcat $fastq |");
	VERBOSE: while (<R1>) {
   	     $line++;
   	     #e.g., @ST-J00101:159:HF5TFBBXY:4:1101:30249:1156 BX:Z:A33C26B95D10
   	    ($lane, $bx, $c, $line) = ($1, $2, $3, 0) if (/^@.+\:\d+:\S+:(\d):\d+:\d+:\d+.+BX:Z:(A..(C..)B..D..)/ && $line==4);
   	     
			if (exists($barcodes{$bx})) {
			   if ($bc_flag < 3) {
   	            
				   if ($line == 0 || $line == 2) {
								print "\n[BARCODE MATCHED FROM LIST: $bx -> $barcodes{$bx}]\n" if ($line == 0);
   	       	            		 print;
   	    		        } elsif ($line == 1) {
   	    	                my $string;
   	   	                 $string .= $chars[rand @chars] for 1..7;
   	   	                 print "$barcodes{$bx}".$string.$_;
   	   	         } elsif ($line == 3) {
   	   	                 print "".("J" x 23)."$_";
   	   	                 $bx = "";
						 $bc_flag++;	
   	 	           }
			   }
   	    } else {
				if ($nbc_flag == 0) {
   	       	      if ($line == 0 || $line == 2) {
							print "\n[BARCODE NOT IN LIST: $bx]\n" if ($line == 0);
   	       	              print;
   	       	      } elsif ($line == 1) {
   	       	              my $string;
   	      	               print "".("N" x 23).$_;
   	      	       } elsif ($line == 3) {
   	       	              print "".("#" x 23).$_;
						  $nbc_flag++;
	    	       }
				}
	       }
	   last VERBOSE if ($bc_flag + $nbc_flag == 4);
	   }
	close (R1);

	$line = 3;
	print "NOW PROCESSING THE ENTIRE FASTQ FILE...\n";
}

open (OUT, " | gzip -c > $fastq_out");
open (R1, "zcat $fastq |");
while (<R1>) {
        $line++;
        #e.g., @ST-J00101:159:HF5TFBBXY:4:1101:30249:1156 BX:Z:A33C26B95D10
        ($lane, $bx, $c, $line) = ($1, $2, $3, 0) if (/^@.+\:\d+:\S+:(\d):\d+:\d+:\d+\s+BX:Z:(A..(C..)B..D..)/ && $line==4);
        
        if (exists($barcodes{$bx})) {
               if ($line == 0 || $line == 2) {
                       print OUT;
               } elsif ($line == 1) {
                       my $string;
                       $string .= $chars[rand @chars] for 1..7;
                       print OUT "$barcodes{$bx}".$string.$_;
               } elsif ($line == 3) {
                       print OUT "".("J" x 23)."$_";
                       $bx = "";
               }
       } else {
                if ($line == 0 || $line == 2) {
                        print OUT;
                } elsif ($line == 1) {
                        my $string;
                        print OUT "".("N" x 23).$_;
                } elsif ($line == 3) {
                        print OUT "".("#" x 23).$_;
                }
       }
}
close (R1);
close (OUT);
