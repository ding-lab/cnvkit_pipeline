=head1
    
    Hua Sun
    11/9/2019;3/5/2020;2020-10-15
    
    1.Remove duplicated genes from cnvkit gene-level file
        keep gene from dup.
            - take long length one & high segment_weight

    2.Remove cn==2 genes (it happened due to different cutoff in cnvkit e.g. -t 1.1,-0.25,0.2,0.7)

    
    //input
        gene    chromosome      start   end     log2    depth   weight  cn      n_bins  segment_weight  segment_probes

    perl filter.cnvkit-geneLevel.pl cnvkit.gene-level.tsv > output

=cut


use strict;

my $file = shift;

my $head = `head -n 1 $file`;
my @data = `sed '1d' $file | sort -k1,1 -k2,2`;

my ($sample, $gene, $length, $cn);
my %hash;
foreach (@data) {
    my @arr = split/\t/;

    $gene = $arr[0];
    $length = $arr[3] - $arr[2];  # end - start


    # filter cn==2 genes
    $cn = $arr[7];
    next if ($cn==2);

            
    my $key = "$gene";
        
    if (exists $hash{$key}){
        my $str = $hash{$key};
                
        my $flag = &compareDup($head, $_, $str);
        if ($flag == 1){
            $hash{$key} = $_;
        }
                                
    } else {
        $hash{$key} = $_;
    }
        
}



# output
print $head;
foreach (sort keys %hash){
    print $hash{$_};
}

exit;



######################################################

sub compareDup
{
        my ($head, $newLine, $oldLine) = @_;
        
        my @arrNew = split("\t", $newLine);
        my @arrOld = split("\t", $oldLine);
        
        my ($newLen, $oldLen);
        my ($newSegWeight, $oldSegWeight);
        
        $newLen = $arrNew[4] - $arrNew[3];
        $oldLen = $arrOld[4] - $arrOld[3];
        $newSegWeight = $arrNew[10];
        $oldSegWeight = $arrOld[10];
        
        if ($newLen > $oldLen){
            return 1
        } elsif ($newLen == $oldLen) {
            if ($newSegWeight > $oldSegWeight){
                return 1
            } else {
                return 0
            }
        } else {
            return 0
        }
        
}

