#bin/bash
GZSTREAMDIR = /usr/local/include/gzstream
GZSTREAM_CPPFLAGS = -I$(GZSTREAMDIR)
g++ -O3 -o tag_f.o tag_fastq.cpp -lgzstream -I$(GZSTREAM_CPPFLAGS) -I/usr/include -std=gnu++11 -lz -Wall
