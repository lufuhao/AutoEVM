#!/usr/bin/perl
use strict;
use warnings;
use constant USAGE =><<EOH;
# 
# usage: $0 INFILE col2name > OUTFILE
#
# Version: 20150714
#
# Description
#  * convert exonerate to Evidence Modeler alignment
#  * modify ID= and Target=
#  * prints out the 'exon' lines in GFF3, link to parent gene
#
# INPUT FILE:   exonerate should have been run with (at least) the following options:
#               --model coding2genome  OR  --model est2genome
#               --showtargetgff yes
#
EOH

die USAGE if (scalar(@ARGV) != 2 or $ARGV[0] eq '-h' or $ARGV[0] eq '--help');
my $exonerateout=$ARGV[0];
my $col2name=$ARGV[1];
my $est_acc;

my $id = "gene000000000";
my $exon_id = "exon000000000";
open (EXONERATE, "< $exonerateout") || die "Error: can not open exonerate out\n";
# my $alignment_serial_number = 0;

while (<EXONERATE>) {
	chomp;
	if (/\texonerate:\w+2genome\t/ && /\tgene\t/ && /sequence (\S+)/) {
		$est_acc = $1;
		$id++;
		my @cols = split /\t/, $_;
#		$cols[1] =~ s/chromosome:AgamP3:(\w+):.+/$1/; # if needed
#		$cols[8] = "ID=$id;Name=$est_acc";

#		print join "\t", @cols;
#		print "\n";
	}
	elsif (/\texonerate:\w+2genome\t/ && /\texon\t/) {
		$exon_id++;

		my @cols = split /\t/, $_;
#		$cols[1] =~ s/chromosome:AgamP3:(\w+):.+/$1/; # if needed
		$cols[1] = $col2name;
		$cols[8] = "ID=$id;Target=$est_acc";

		print join "\t", @cols;
		print "\n";
  }
}
close EXONERATE;
