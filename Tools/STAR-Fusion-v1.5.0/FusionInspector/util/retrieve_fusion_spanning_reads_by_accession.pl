#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use SAM_reader;
use SAM_entry;
use Data::Dumper;
use DelimParser;

my $usage = "usage: $0 read_names.accs  fileA.bam,fileB.bam,...\n\n";

my $read_name_accs_list = $ARGV[0] or die $usage;
my $bam_file_listing = $ARGV[1] or die $usage;

main: {
    
    my %cores_want;
    {
        open(my $fh, $read_name_accs_list) or die "Error, cannot open file $read_name_accs_list";
        my $tab_reader = new DelimParser::Reader($fh, "\t");
        
        while (my $row = $tab_reader->get_row()) {
            
            my $geneA = $row->{LeftGene};
            my $geneB = $row->{RightGene};
            my $reads_list = $row->{SpanningFrags};


            $geneA =~ s/\^.*//g;
            $geneB =~ s/\^.*//g;
            
            
            my $fusion_contig = "$geneA--$geneB";
            foreach my $read_name (split(/,/, $reads_list)) {
                if ($read_name =~ /^\&[^\@]+\@/) {
                    $read_name =~ s/^\&[^\@]+\@//;
                }
                $cores_want{"$fusion_contig|$read_name"} = 1;
            }
        }
        
    }
    
    
    my %reads_seen;

    foreach my $bam_file (split(/,/, $bam_file_listing) ) {
        
        my $sam_reader = new SAM_reader($bam_file);
        while (my $sam_entry = $sam_reader->get_next()) {
            my $scaffold = $sam_entry->get_scaffold_name();
            
            my $core_read_name = $sam_entry->get_core_read_name();
            
            $core_read_name = "$scaffold|$core_read_name";
            if ($cores_want{$core_read_name}) {
                
                
                my $full_read_name = $sam_entry->reconstruct_full_read_name();
                $full_read_name = "$scaffold|$full_read_name";
                $full_read_name =~ m|/([12])$| or die "Error cannot parse read end from $full_read_name";
                my $end = $1;
                my $opposite_end = ($end == 1) ? 2 : 1;
                my $opposite_read_name = $core_read_name . "/" . $opposite_end; 
                if (! $reads_seen{$full_read_name}) {
                    $reads_seen{$full_read_name}++;
                    print $sam_entry->get_original_line() . "\n";
                
                    if ($reads_seen{$opposite_read_name}) {
                        delete $cores_want{$core_read_name};
                    }
                }
                
            }
        }

    }

    if (%cores_want) {
        print STDERR "Warning, missing spanning reads, presumably excluded by per_id, num hit, qual, or other filters earlier on: " . Dumper(\%cores_want);
    }
    
    exit(0);
}


