#!/bin/bash

# 11/9/2019

# Usage
# bash call_cnv.sh <config.ini> <name> <outDir>

CONFIG=$1
REFCNN=$2
NAME=$3
OUTDIR=$4

source $CONFIG

# check reference file
# reference_normals.cnn or reference_flat.cnn
if [ ! -e $REFCNN ]; then 
	echo "[Error] No reference cnn file!" >&2
	exit 1
fi

# reference has pool normal
# correct for biases https://cnvkit.readthedocs.io/en/stable/pipeline.html 
$PYTHON3 $CNVKIT fix $OUTDIR/$NAME.T.targetcoverage.cnn $OUTDIR/$NAME.T.antitargetcoverage.cnn $REFCNN -o $OUTDIR/$NAME.T.cnr


# add --min-variant-depth 20 11/8
$PYTHON3 $CNVKIT segment $OUTDIR/$NAME.T.cnr --method cbs --drop-low-coverage --min-variant-depth 20 -o $OUTDIR/$NAME.T.cns

# large bin >15kb 
# Copy number variation detection in whole-genome sequencing data using the Bayesian information criterion
# cutoff probe >=10
# chromosome      start   end     gene    log2    depth   probes  weight
perl -i -ne '@F=split/\t/; $probe=$F[6]; $len=$F[2]-$F[1]; if($.==1){print}elsif($probe>=10 && $len>15000){print}' $OUTDIR/$NAME.T.cns


$PYTHON3 $CNVKIT call $OUTDIR/$NAME.T.cns -m threshold -t=-1.1,-0.4,0.3,0.7 -o $OUTDIR/$NAME.T.call.cns


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

