#!/bin/bash

# 2018/6/28 updated
# Hua Sun

# Usage
# bash 1_run.cnvkit_wxs.sh -C config.ini -B /gscmnt/gc2737/ding/hsun/mm_target_capture/cnv/cnvkit/bamFolder -O /gscmnt/gc2737/ding/hsun/mm_target_capture/cnv/cnvkit/result

# getOptions
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
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done


## 
source $CONFIG

mkdir -p $OUTDIR

## full pipeline for calling CNV for WXS
$PYTHON3 $CNVKIT batch $BAMFOLDER/*.T.bam --normal $BAMFOLDER/*.N.bam \
		--method 'hybrid' \
    --targets $TARGET --fasta $GENOME \
    --access $GENOME_BED \
    --output-reference $OUTDIR/reference_normals.cnn \
    --output-dir $OUTDIR/

