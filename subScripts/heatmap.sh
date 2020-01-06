#!/bin/bash

# Usage
# bash heatmap.sh config.ini name /path/outDir

CONFIG=$1
OUTDIR=$2

source $CONFIG
	

#$PYTHON3 $CNVKIT heatmap $OUTDIR/*.cns -d -o $OUTDIR/summary.cnv_heatmap.pdf
# chr 1-22 from call
$PYTHON3 $CNVKIT heatmap $OUTDIR/*.call.chr.cns -d -o $OUTDIR/summary.cnv_heatmap.chr.pdf
