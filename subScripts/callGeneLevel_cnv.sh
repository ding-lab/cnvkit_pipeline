#!/bin/bash

# 5/27/2019; 12/25/2019

# Usage
# sh run.sh <config> <name> <outdir> <flag>

# if flag=="f2" then do dir/sample/sample.remDup.call

CONFIG=$1
NAME=$2
OUTDIR=$3
FLAG=$4

source $CONFIG


if [[ $FLAG == "f2" ]]; then
	# tumor-normal
	# use *.remDup.call.chr.cns
	$PYTHON3 $CNVKIT genemetrics $OUTDIR/$NAME/$NAME.remDup.chr.cnr -s $OUTDIR/$NAME/$NAME.remDup.call.chr.cns -t 0.3 -m 5 > $OUTDIR/$NAME/$NAME.remDup.segment_gene.chr.tsv
else
	# call genelevel cnv
	# use *.T.call.chr.cns
	$PYTHON3 $CNVKIT genemetrics $OUTDIR/$NAME.T.chr.cnr -s $OUTDIR/$NAME.T.call.chr.cns -t 0.3 -m 5 > $OUTDIR/$NAME.T.segment_gene.chr.tsv
fi


# amplification(cn>=5)/deletion (cn==0)
# https://cnvkit.readthedocs.io/en/stable/pipeline.html
#awk -F['\t'] '$8>=5 || $8==0' $OUTDIR/$NAME.T.segment_gene.chr.tsv > $OUTDIR/$NAME.T.segment_gene.chr.ampdel.tsv


