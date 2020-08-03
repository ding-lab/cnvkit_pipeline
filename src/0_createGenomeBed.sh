#!/bin/bash

# Usage
# bash 0_createGenomeBed.sh config.ini /path/outDir
CONFIG=$1

source $CONFIG

## create genome bed (default -s 5000)
# make .bed
$PYTHON3 $CNVKIT access $GENOME -o $GENOME_BED

## Make splited targets bed file (default --avg-size 267)
# if target - chr start end gene
# make .split.txt
$PYTHON3 $CNVKIT target $TARGET --split -o $OUTDIR/$GENOME_TARGET
# make annotated target file
# if target - chr start end
#$PYTHON3 $CNVKIT target $TARGET --split --annotate $REFFLAT -o $GENOME_TARGET

## Make antitargets bed file
# make.antitargets.bed
$PYTHON3 $CNVKIT antitarget $OUTDIR/$GENOME_TARGET --access $GENOME_BED -o $GENOME_ANTITARGET

