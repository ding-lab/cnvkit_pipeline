=head1
    
    Hua Sun    
    # 4/28/2020

    Extract gene copy number from segment cn result
    Only extract the first sample gene and remove duplicated sample genes


    perl cnvkit_seg2gene.pl cnvkit_segment.cnv -o cnvkit_seg.gene.out

    // cnvkit_segment.cnv
    sample  chromosome  start   end gene    log2    cn  depth   probes  weight
    
    // output
    sample gene segment_log2 segment_cn chr start end segment_width segment_depth segment_probes segment_weight

=cut


use strict;
use Getopt::Long;

my $outfile;
GetOptions(
    "o|outfile:s" => \$outfile
);

my $file = shift;


my $header = "sample\tgene\tsegment_log2\tsegment_cn\tchr\tsegment_start\tsegment_end\tsegment_width\tsegment_depth\tsegment_probes\tsegment_weight\n";

my @data = `sed '1d' $file`;


# general output
open my $OUT, '>', $outfile;
print $OUT $header;


my ($sample, $chr, $start, $end, $geneSet, $log2, $cn, $depth, $probes, $weight);
my $segment_width;
my %hash_sampleGene;

foreach my $str (@data){

    chomp($str);
    
    ($sample, $chr, $start, $end, $geneSet, $log2, $cn, $depth, $probes, $weight) = split("\t", $str);

    $segment_width = $end - $start + 1;

    my @arrGeneSet = split(',', $geneSet);
    my $row;
    foreach my $gene (@arrGeneSet){

        next if ($gene eq '-'); # remvoe, if no gene name 

        my $key = "$sample $gene";

        $row = "$sample\t$gene\t$log2\t$cn\t$chr\t$start\t$end\t$segment_width\t$depth\t$probes\t$weight\n";

        # record duplicated genes for checking
        if (exists $hash_sampleGene{$key}){
            #print $LOG $row;
            next;
        } else {
            $hash_sampleGene{$key} = 1;
        }

        print $OUT $row;
    }

}


