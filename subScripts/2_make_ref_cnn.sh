#!/bin/bash

# Usage
# bash 3_make_ref_cnn.sh config.ini /path/outDir

CONFIG=$1
OUTDIR=$2

source $CONFIG

if [ -e $OUTDIR/reference_normals.cnn ]; then
	echo "[ERROR] The $OUTDIR/reference_normals.cnn exists ..." >&2
	exit 1
fi


# Make reference normal cnn
$PYTHON3 $CNVKIT reference $OUTDIR/*.N.*coverage.cnn -f $GENOME -o $OUTDIR/reference_normals.cnn

