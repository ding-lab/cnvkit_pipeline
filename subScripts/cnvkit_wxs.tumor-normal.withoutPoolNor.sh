#!/bin/bash

# Hua Sun
# 11/9/2019; 1/13/2020

#cnvkit v0.9.6

# run tumor-normal without pool normal

# Usage
# bash 1_run.cnvkit_wxs.sh -C config.ini -S sampleName -N normal.bam -T tumor.bamr -O results

# getOptions
CONFIG=/gscuser/hua.sun/scripts/pipeline/cnvkit/mgi.config.gencode_grch38.ini

while getopts "C:S:T:N:O:" opt; do
  case $opt in
    C)
      CONFIG=$OPTARG
      ;;  
    S)
      SAMPLE=$OPTARG
      ;;
    T)
      TUMOR_BAM=$OPTARG
      ;;
    N)
      NORMAL_BAM=$OPTARG
      ;;    
    O)
      OUTDIR=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done


## 
source $CONFIG

mkdir -p $OUTDIR

OUT=$OUTDIR/${SAMPLE}
mkdir -p $OUT


## full pipeline for calling CNV for WXS
$PYTHON3 $CNVKIT batch ${TUMOR_BAM} --normal ${NORMAL_BAM} \
    --method 'hybrid' \
    --targets $TARGET --fasta $GENOME \
    --access $GENOME_BED \
    --drop-low-coverage \
    --output-reference $OUT/reference_normals.cnn \
    --output-dir $OUT/




# for tumor-sample
# it is different poolNor approach and no .N. or .T. name
filename=${TUMOR_BAM##*/}
NAME=${filename%%.bam}


# add --min-variant-depth 20 11/8
$PYTHON3 $CNVKIT segment $OUT/$NAME.cnr --method cbs --drop-low-coverage --min-variant-depth 20 -o $OUT/$NAME.cns

# default bin >5kb
# cutoff probe >10
# chromosome      start   end     gene    log2    depth   probes  weight
perl -ne '@F=split/\t/; $probe=$F[6]; $len=$F[2]-$F[1]; if($.==1){print}elsif($probe>10 && $len>5000){print}' $OUT/$NAME.cns > $OUT/$NAME.filtered.cns


# the -t=-1.1,-0.25,0.2,0.7 is too low-cutoff
# best practise (since compared tumor vs pdx in different cutoff.)
$PYTHON3 $CNVKIT call $OUT/$NAME.filtered.cns -m threshold -t=-1.3,-0.4,0.3,0.9 -o $OUT/$NAME.call.cns


# chr1-22 (XY also removed because it had low accuracy)
perl -ne 'print if (/^chr\d+/ || /^chromosome/ || /^\d+/)' $OUT/$NAME.cnr > $OUT/$NAME.chr.cnr
perl -ne 'print if (/^chr\d+/ || /^chromosome/ || /^\d+/)' $OUT/$NAME.call.cns > $OUT/$NAME.call.chr.cns



# draw plot DO NOT use *.noNeutral due to understand the neutral pattern
$PYTHON3 $CNVKIT scatter $OUT/$NAME.chr.cnr -s $OUT/$NAME.call.chr.cns --y-min -4 --y-max 4 -w 1000000 -o $OUT/$NAME.call.chr.cns.pdf


# call genelevel cnv
# use *.call.chr.cns
$PYTHON3 $CNVKIT genemetrics $OUT/$NAME.chr.cnr -s $OUT/$NAME.call.chr.cns -t 0.3 -m 5 > $OUT/$NAME.segment_gene.chr.tsv
# amplification(cn>=5)/deletion (cn==0)
# https://cnvkit.readthedocs.io/en/stable/pipeline.html
#awk -F['\t'] '$8>=5 || $8==0' $OUT/$NAME.segment_gene.chr.tsv > $OUT/$NAME.segment_gene.chr.ampdel.tsv

