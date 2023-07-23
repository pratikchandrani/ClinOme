#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Basename;
use Cwd;

use Carp;
use Getopt::Long qw(:config no_ignore_case bundling pass_through);


my $usage = <<__EOUSAGE__;

######################################################################
#
#  Required:
#  --genome <string>           target genome to align to
#  --reads  <string>           fastq files. If pairs, indicate both in quotes, ie. "left.fq right.fq"
#
#  Optional:
#  -N <int>                    number of top hits (default: 1)
#  -I <int>                    max intron length (default: 1000000)
#  -G <string>                 GTF file for incorporating reference splice site info.
#  --CPU <int>                 number of threads (default: 2)
#  --out_prefix <string>       output prefix (default: gsnap)
#  --no_sarray                 skip the sarray in the gmap-build 
#  --proper_pairs_only         require proper pairing of reads
#
#######################################################################


__EOUSAGE__

    ;


my ($genome, $reads);

my $max_intron = 1000000;
my $CPU = 2;

my $help_flag;

my $num_top_hits = 1;
my $out_prefix = "gsnap";
my $gtf_file;
my $no_sarray = "";
my $proper_pairs_only_flag = 0;

&GetOptions( 'h' => \$help_flag,
             'genome=s' => \$genome,
             'reads=s' => \$reads,
             'I=i' => \$max_intron,
             'CPU=i' => \$CPU,
             'N=i' => \$num_top_hits,
             'out_prefix=s' => \$out_prefix,
             'G=s' => \$gtf_file,
             'no_sarray' => \$no_sarray,
             'proper_pairs_only' => \$proper_pairs_only_flag,
    );


unless ($genome && $reads) {
    die $usage;
}

if ($no_sarray) {
    $no_sarray = "--no-sarray";
}

main: {
	
	my $genomeName = basename($genome);
	my $genomeDir = $genomeName . ".gmap";

	my $genomeBaseDir = dirname($genome);

	my $cwd = cwd();
	
	unless (-d "$genomeBaseDir/$genomeDir") {
		
        

        my $cmd = "gmap_build -D $genomeBaseDir -d $genomeDir -T $genomeBaseDir -k 13 $no_sarray $genome >&2";
		&process_cmd($cmd);
	}

    my $splice_file;
    my $splice_param = "";
    
    if ($gtf_file) {
        $splice_file = "$gtf_file.gsnap.splice";
        if (! -s $splice_file) {
            # create one.
            my $cmd = "gtf_splicesites < $gtf_file > $splice_file";
            &process_cmd($cmd);

            $cmd = "iit_store -o $splice_file.iit < $splice_file";
            &process_cmd($cmd);
        }
    
        $splice_param = "--use-splicing=$splice_file.iit";
    }
    
    
    ## run GMAP
    
    my $gsnap_use_sarray = ($no_sarray) ? "--use-sarray=0" : "";

    my $gunzip_param = "";
    if ($reads =~ /\.gz\b/) {
        $gunzip_param = "--gunzip";
    }

    my $require_proper_pairs = "";
    if ($proper_pairs_only_flag) {
        $require_proper_pairs = " -f 2 ";
    }

    my $cmd = "bash -c \"set -o pipefail && gsnap -D $genomeBaseDir -d $genomeDir -A sam -N 1 -w $max_intron $gsnap_use_sarray -n $num_top_hits -t $CPU $gunzip_param $reads $splice_param @ARGV | samtools view -bS -F 4 $require_proper_pairs - > $out_prefix.gsnap.bam \"";
        
    &process_cmd($cmd) unless (-s "$out_prefix.gsnap.bam");
    
    $cmd = "samtools sort -@ $CPU $out_prefix.gsnap.bam -o $out_prefix.cSorted.bam";
    &process_cmd($cmd) unless (-s "$out_prefix.cSorted.bam");
    
    unlink("$out_prefix.gsnap.bam"); # no longer needed now that we have the sorted version.
    
    if (-s "$out_prefix.cSorted.bam") {
        $cmd = "samtools index $out_prefix.cSorted.bam";
        &process_cmd($cmd);
    }
    
	exit(0);
}


####
sub add_zcat_fifo {
    my ($reads) = @_;

    my @adj_reads_list;

    foreach my $reads_file (split(/\s+/, $reads) ) {
        if ($reads_file =~ /\.gz$/) {
            $reads_file = "<(zcat $reads_file)";
        }
        push (@adj_reads_list, $reads_file);
    }
    
    my $adj_reads = join(" ", @adj_reads_list);

    return($adj_reads);
}
                            
    



####
sub process_cmd {
	my ($cmd) = @_;
	
	print STDERR "CMD: $cmd\n";
	#return;

	my $ret = system($cmd);
	if ($ret) {
		die "Error, cmd: $cmd died with ret ($ret)";
	}

	return;
}



