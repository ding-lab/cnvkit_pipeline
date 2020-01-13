#!/bin/bash

# 11/9/2019 v1.8; 1/13/2020
# Hua Sun

# Call single tumor sample CNV using existing reference_normals.cnn
#
# Usage
# bash cnvkit_wxs.sh -N sampleName -C config.ini -B /path/tumor.bam -R /path/reference_normals.cnn -O /path/outputDir
# the output - sampleName.T.*
# the bam only need tumor bam & bam.bai
# sample.N.bam (normal), sample.T.bam (tumor)
# the best sample name as no '.'


# set default
CONFIG=~/scripts/pipeline/cnvkit/mgi.config.gencode_grch38.ini

## getOptions
while getopts "N:C:B:R:O:" opt; do
  case $opt in
    N)
      NAME=$OPTARG
      ;;
    C)
      CONFIG=$OPTARG
      ;;
    B)
      BAM=$OPTARG
      ;;
    R)
    	POOLS_REF_CNN=$OPTARG
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
  echo "[ERROR] No $SDIR directory ..." >&2
  exit 1
fi

if [ -e $OUTDIR/$NAME.T.targetcoverage.cnn ]; then
  echo "[ERROR] The $OUTDIR/$NAME.T.targetcoverage.cnn exists ..." >&2
  exit 1
fi

if [[ $NAME == "" ]]; then
  echo "[ERROR] The name (-N ) is empty ..." >&2
  exit 1
fi


mkdir -p $OUTDIR


# target	
$PYTHON3 $CNVKIT coverage $BAM $GENOME_TARGET -o $OUTDIR/$NAME.T.targetcoverage.cnn
# antitarget
$PYTHON3 $CNVKIT coverage $BAM $GENOME_ANTITARGET -o $OUTDIR/$NAME.T.antitargetcoverage.cnn

$PYTHON3 $CNVKIT fix $OUTDIR/$NAME.T.targetcoverage.cnn $OUTDIR/$NAME.T.antitargetcoverage.cnn $POOLS_REF_CNN -o $OUTDIR/$NAME.T.cnr


# add --min-variant-depth 20 11/8
$PYTHON3 $CNVKIT segment $OUTDIR/$NAME.T.cnr --method cbs --drop-low-coverage --min-variant-depth 20 -o $OUTDIR/$NAME.T.cns


# default bin >5kb
# cutoff probe >10
# chromosome      start   end     gene    log2    depth   probes  weight
perl -ne '@F=split/\t/; $probe=$F[6]; $len=$F[2]-$F[1]; if($.==1){print}elsif($probe>10 && $len>5000){print}' $OUTDIR/$NAME.T.cns > $OUTDIR/$NAME.T.filtered.cns


# the -t=-1.1,-0.25,0.2,0.7 is too low-cutoff
# best practise (since compared tumor vs pdx in different cutoff.)
$PYTHON3 $CNVKIT call $OUTDIR/$NAME.T.filtered.cns -m threshold -t=-1.3,-0.4,0.3,0.9 -o $OUTDIR/$NAME.T.call.cns


# chr1-22 (XY also removed because it had low accuracy)
perl -ne 'print if (/^chr\d+/ || /^chromosome/ || /^\d+/)' $OUTDIR/$NAME.T.cnr > $OUTDIR/$NAME.T.chr.cnr
perl -ne 'print if (/^chr\d+/ || /^chromosome/ || /^\d+/)' $OUTDIR/$NAME.T.call.cns > $OUTDIR/$NAME.T.call.chr.cns




# draw plot DO NOT use *.noNeutral due to understand the neutral pattern
$PYTHON3 $CNVKIT scatter $OUTDIR/$NAME.T.chr.cnr -s $OUTDIR/$NAME.T.call.chr.cns --y-min -4 --y-max 4 -w 1000000 -o $OUTDIR/$NAME.T.call.chr.cns.pdf


# call genelevel cnv
# use *.T.call.chr.cns
$PYTHON3 $CNVKIT genemetrics $OUTDIR/$NAME.T.chr.cnr -s $OUTDIR/$NAME.T.call.chr.cns -t 0.3 -m 5 > $OUTDIR/$NAME.T.segment_gene.chr.tsv
# amplification(cn>=5)/deletion (cn==0)
# https://cnvkit.readthedocs.io/en/stable/pipeline.html
#awk -F['\t'] '$8>=5 || $8==0' $OUTDIR/$NAME.T.segment_gene.chr.tsv > $OUTDIR/$NAME.T.segment_gene.chr.ampdel.tsv



