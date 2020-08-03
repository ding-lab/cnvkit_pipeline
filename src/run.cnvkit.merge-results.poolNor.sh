# 10/16/2019 v3

# merge all of cnvkit_gene-level files to one file

# sh run.sh -C config.ini -D cnvkit_result


dir=$1

if [ ! -d $dir ]; then
  echo "[ERROR] No $dir !" 1>&2
  exit
fi



##------------------------- merge segment
mkdir -p $dir/tmp_dir

i=0

ls $dir/*.T.call.chr.cns | while read file
do
	
	i=$((i+1))
	
	filename=${file##*/}
	sample=${filename%%.*}
	
	# header - segment
	if [[ $i == 1 ]]; then head -n 1 $dir/${sample}.T.call.chr.cns | perl -pe 's/^/sample\t/ if $.==1' > $dir/tmp_dir/head.segment.out; fi 
	# header - geneLevel
	if [[ $i == 1 ]]; then head -n 1 $dir/${sample}.T.segment_gene.chr.tsv | perl -pe 's/^/sample\t/ if $.==1' > $dir/tmp_dir/head.gene-level.out; fi 

	# *.T.call.chr.cns
	sed '1d' $dir/${sample}.T.call.chr.cns | perl -pe 's/^/'$sample'\t/' > $dir/tmp_dir/$sample.call.chr.cns
	
	# *.T.call.chr.segment_gene.tsv
	sed '1d' $dir/${sample}.T.segment_gene.chr.tsv | perl -pe 's/^/'$sample'\t/' > $dir/tmp_dir/$sample.segment_gene.chr.tsv

done

# merge segment
cat $dir/tmp_dir/head.segment.out $dir/tmp_dir/*.call.chr.cns > $dir/cnvkit_segment.all.merged.tsv

# merge gene-level
cat $dir/tmp_dir/head.gene-level.out $dir/tmp_dir/*.segment_gene.chr.tsv > $dir/cnvkit_gene-level.all.merged.tsv


rm -rf $dir/tmp_dir


