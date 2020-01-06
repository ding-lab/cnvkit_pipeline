#!/bin/bash

# Usage
# bash 2_call_cnn.sh config.ini name /path/1.bam /path/outDir

CONFIG=$1
NAME=$2
BAM=$3
OUTDIR=$4

source $CONFIG

if [ -e $OUTDIR/$NAME.targetcoverage.cnn ]; then
	echo "[ERROR] The $OUTDIR/$NAME.targetcoverage.cnn exists ..." >&2
	exit 1
fi

# target	
$PYTHON3 $CNVKIT coverage $BAM $GENOME_TARGET -o $OUTDIR/$NAME.targetcoverage.cnn

# antitarget
$PYTHON3 $CNVKIT coverage $BAM $GENOME_ANTITARGET -o $OUTDIR/$NAME.antitargetcoverage.cnn


