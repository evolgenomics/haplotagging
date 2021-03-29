#!/bin/bash

clearBC_log=$1
echo "Using clearBC_log: $clearBC_log"; 
tail +2 $clearBC_log | awk '{print $0"\t"$2+$3}' | sort -k 4,4nr | cut -f 1 | paste - 4M-with-alts-february-2016.txt | awk 'NF == 2' > top5M.barcodes.GEM.list
