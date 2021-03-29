# 8/3/2020

# merge all of cnvkit files to one file

# sh run.sh cnvkit_result


dir=$1

if [ ! -d $dir ]; then
  echo "[ERROR] No $dir !" 1>&2
  exit
fi



##------------------------- merge segment
mkdir -p $dir/tmp_dir

i=0

ls $dir/*.T.chr.call.cns | while read file
do
	
	i=$((i+1))
	
	filename=${file##*/}
	sample=${filename%%.*}
	
	# header - segment
	if [[ $i == 1 ]]; then 
	    head -n 1 $dir/${sample}.T.chr.call.cns | perl -pe 's/^/sample\t/ if $.==1' > $dir/tmp_dir/head.segment.out
	    head -n 1 $dir/${sample}.T.segment_gene.trusted.gainloss.tsv | perl -pe 's/^/sample\t/ if $.==1' > $dir/tmp_dir/head.segment_gene.out
	    #head -n 1 $dir/${sample}.T.ratio_gene.chr.tsv | perl -pe 's/^/sample\t/ if $.==1' > $dir/tmp_dir/head.ratio_gene.out
	fi 
    
	# *.T.chr.call.cns
	sed '1d' $dir/${sample}.T.chr.call.cns | perl -pe 's/^/'$sample'\t/' > $dir/tmp_dir/$sample.chr.call.cns
	
	# *.T.call.chr.segment_gene.tsv
	#sed '1d' $dir/${sample}.T.ratio_gene.trusted.gainloss.tsv | perl -pe 's/^/'$sample'\t/' > $dir/tmp_dir/$sample.ratio_gene.chr.tsv
	sed '1d' $dir/${sample}.T.segment_gene.trusted.gainloss.tsv | perl -pe 's/^/'$sample'\t/' > $dir/tmp_dir/$sample.segment_gene.trusted.gainloss.tsv


done

# merge segment
cat $dir/tmp_dir/head.segment.out $dir/tmp_dir/*.chr.call.cns > $dir/cnvkit.segment.mergedSamples.tsv

# merge gene-level
#cat $dir/tmp_dir/head.ratio_gene.out $dir/tmp_dir/*.ratio_gene.trusted.gainloss.tsv > $dir/cnvkit.ratio_gene.trusted.gainloss.mergedSamples.tsv
cat $dir/tmp_dir/head.segment_gene.out $dir/tmp_dir/*.segment_gene.trusted.gainloss.tsv > $dir/cnvkit.segment_gene.trusted.gainloss.mergedSamples.tsv



rm -rf $dir/tmp_dir


