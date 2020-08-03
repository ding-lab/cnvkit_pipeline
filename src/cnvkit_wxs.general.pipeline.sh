#!/bin/bash

# Hua Sun
# v2 08/02/2020 beta


## getOptions
while getopts "C:B:O:" opt; do
  case $opt in
    C)
      CONFIG=$OPTARG
      ;;
    B)
      BAMFOLDER=$OPTARG
      ;;
    O)
      OUTDIR=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done


##
source $CONFIG

if [ ! -d $SDIR ]; then
  echo "[ERROR] No code directory $SDIR ..." >&2
  exit 1
fi


if [ ! -d $BAMFOLDER ]; then
  echo "[ERROR] No bam directory $BAMFOLDER ..." >&2
  exit 1
fi


mkdir -p $OUTDIR


##=============== Pre-call cna ===============##
$CNVKIT batch $BAMFOLDER/*.T.bam --normal $BAMFOLDER/*.N.bam \
    --method 'hybrid' \
    --targets $TARGET --fasta $GENOME \
    --access $GENOME_BED \
    --output-reference $OUTDIR/reference_normals.cnn \
    --output-dir $OUTDIR/
    


##=============== Filter ===============##
# add --min-variant-depth 20 11/8
ls $OUTDIR/*.T.cnr | while read file
do
    filename=${file##*/}
    NAME=${fileName%.T.cnr}
    
    $CNVKIT segment $OUTDIR/$NAME.T.cnr --method cbs --drop-low-coverage --min-variant-depth 20 -o $OUTDIR/$NAME.T.cns
    perl -ne '@F=split/\t/; $probe=$F[6]; $len=$F[2]-$F[1]; if($.==1){print}elsif($probe>10 && $len>1000){print}' $OUTDIR/$NAME.T.cns > $OUTDIR/$NAME.T.filtered.cns
    
    $CNVKIT call $OUTDIR/$NAME.T.filtered.cns -m threshold -t=-1.3,-0.4,0.3,0.9 -o $OUTDIR/$NAME.T.call.cns

    # chr1-22 (XY also removed because it had low accuracy)
    perl -ne 'print if (/^chr\d+/ || /^chromosome/ || /^\d+/)' $OUTDIR/$NAME.T.cnr > $OUTDIR/$NAME.T.chr.cnr
    perl -ne 'print if (/^chr\d+/ || /^chromosome/ || /^\d+/)' $OUTDIR/$NAME.T.call.cns > $OUTDIR/$NAME.T.call.chr.cns
    
    $CNVKIT genemetrics $OUTDIR/$NAME.T.chr.cnr > $OUTDIR/$NAME.T.ratio_gene.chr.tsv
    $CNVKIT genemetrics $OUTDIR/$NAME.T.chr.cnr -s $OUTDIR/$NAME.T.call.chr.cns -t 0.4 -m 5 > $OUTDIR/$NAME.T.segment_gene.chr.tsv

    
    sed '1d' $OUTDIR/$NAME.T.ratio_gene.chr.tsv | cut -f 1 | sort -u > $OUTDIR/$NAME.T.ratio-genes.txt
    sed '1d' $OUTDIR/$NAME.T.segment_gene.chr.tsv | cut -f 1 | sort -u > $OUTDIR/$NAME.T.segment-genes.txt
    comm -12 $OUTDIR/$NAME.T.ratio-genes.txt $OUTDIR/$NAME.T.segment-genes.txt > $OUTDIR/$NAME.T.trusted-genes.txt

    ${PYTHON3} ${SDIR}/extract.rows.py --list $OUTDIR/$NAME.T.trusted-genes.txt --matrix $OUTDIR/$NAME.T.ratio_gene.chr.tsv --colName gene -o $OUTDIR/$NAME.T.ratio_gene.trusted.tsv
done



##=============== summary plot ===============##
$CNVKIT heatmap $OUTDIR/*.call.chr.cns -d -o $OUTDIR/summary.cnv_heatmap.chr.pdf



# remove process files
rm -f $OUTDIR/.*target.bed $OUTDIR/*targetcoverage.cnn $OUTDIR/*.call.cns $OUTDIR/*.ratio-genes.txt $OUTDIR/*.segment-genes.txt $OUTDIR/*.trusted-genes.txt


