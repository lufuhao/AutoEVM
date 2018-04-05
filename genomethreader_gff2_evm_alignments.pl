#!/usr/bin/perl
use strict;
use warnings;
use constant USAGE =><<EOH;
# 
# usage: $0 INFILE col2name > OUTFILE
#
# (also reads from standard input)
#
# what it does:
#   * prints out the 'exon' lines in GFF3, ID=geneXXXXXXXXX;Target=source_ID
#
# INPUT FILE:   genomethreader output
#
# it is OK to have other output formats in the genomethreader output
#
# end
#
EOH

die USAGE if (scalar(@ARGV) != 2 or $ARGV[0] eq '-h' or $ARGV[0] eq '--help');
my $gthout=$ARGV[0];
my $col2name=$ARGV[1];
my $est_acc;
my $target;
my $id = "gene000000000";
my $exon_id = "exon000000000";
open (EXONERATE, "< $gthout") || die "Error: can not open exonerate out\n";
# my $alignment_serial_number = 0;

while (<EXONERATE>) {
	chomp;
	if (/\tgth\tgene\t/ && /ID=(\S+)/) {
		$est_acc = $1;
		$id++;
		my @cols = split /\t/, $_;
#		$cols[1] =~ s/chromosome:AgamP3:(\w+):.+/$1/; # if needed
#		$cols[8] = "ID=$id;Name=$est_acc";

#		print join "\t", @cols;
#		print "\n";
	}
	elsif (/\tgth\tmRNA\t/ && /Target=(.*)$/) {
		$target=$1;
	}
	elsif (/\tgth\texon\t/) {
		$exon_id++;
		my @cols = split /\t/, $_;
#		$cols[1] =~ s/chromosome:AgamP3:(\w+):.+/$1/; # if needed
		$cols[1] = $col2name;
		$cols[8] = "ID=$id;Target=$target";

		print join "\t", @cols;
		print "\n";
  }
}
close EXONERATE;
