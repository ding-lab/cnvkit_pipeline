=head1
    
    Hua Sun
    11/9/2019;3/5/2020
    
    remove duplicated genes from cnvkit gene-level file
        keep gene from dup.
            - take long length one & high segment_weight
    remove too short length genes (<100bp)
    
    //input
        gene    chromosome  start   end log2 ...

    perl filter.cnvkit-geneLevel.pl cnvkit.gene-level.tsv > output

=cut


use strict;

my $file = shift;

my $head = `head -n 1 $file`;
my @data = `sed '1d' $file | sort -k1,1 -k2,2`;

my ($sample, $gene, $length);
my %hash;
foreach (@data) {
    my @arr = split/\t/;

    $gene = $arr[0];

    $length = $arr[3] - $arr[2];

    # filter short length genes
    #next if ($length < 100);
            
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

