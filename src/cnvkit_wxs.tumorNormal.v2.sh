#!/bin/bash

# Hua Sun
# v2 08/02/2020 beta; 2020-10-15; 2020-11-04

#cnvkit v0.9.6

# run tumor-normal (not pool-normal)

# Usage
# bash 1_run.cnvkit_wxs.sh -C config.ini -S sampleName -N normal.bam -T tumor.bamr -O results

# getOptions
#CONFIG=/gscuser/hua.sun/scripts/pipeline/cnvkit/mgi.config.gencode_grch38.ini

parameter='-1.3,-0.4,0.3,0.9'
ratio=0.4

while getopts "C:S:T:N:p:r:O:" opt; do
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
    p)
      parameter=$OPTARG
      ;;
    r)
      ratio=$OPTARG
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


##=============== Pre-call cna ===============##

## full pipeline for calling CNV for WXS
$CNVKIT batch ${TUMOR_BAM} --normal ${NORMAL_BAM} \
    --method 'hybrid' \
    --targets $TARGET --fasta $GENOME \
    --access $GENOME_BED \
    --drop-low-coverage \
    --output-reference $OUT/reference_normals.cnn \
    --output-dir $OUT/



##=============== Filter ===============##

# for tumor-sample
# it is different poolNor approach and no .N. or .T. name
filename=${TUMOR_BAM##*/}
NAME=${filename%%.bam}


# add --min-variant-depth 20 11/8
$CNVKIT segment $OUT/$NAME.cnr --method cbs --drop-low-coverage --min-variant-depth 20 -o $OUT/$NAME.cns

# default bin >10kb
# cutoff probe >10
# chromosome      start   end     gene    log2    depth   probes  weight
perl -ne '@F=split/\t/; $probe=$F[6]; $len=$F[2]-$F[1]; if($.==1){print}elsif($probe>10 && $len>10000){print}' $OUT/$NAME.cns > $OUT/$NAME.filtered.cns


# chr1-22 (XY also removed because it had low accuracy)
perl -ne 'print if (/^chr\d+/ || /^chromosome/ || /^\d+/)' $OUT/$NAME.cnr > $OUT/$NAME.chr.cnr
perl -ne 'print if (/^chr\d+/ || /^chromosome/ || /^\d+/)' $OUT/$NAME.filtered.cns > $OUT/$NAME.chr.cns



##=============== Add absolute CN ===============##
# the -t=-1.1,-0.25,0.2,0.7 is too low-cutoff
# (DO NOT use cnvkit call cnr in v0.9.6)
$CNVKIT call $OUT/$NAME.chr.cns -m threshold -t=${parameter} -o $OUT/$NAME.chr.call.cns



##=============== Plot cn pattern ===============##
# *.chr.cns      # all of cnv is yellow color
# *.chr.call.cns   # only abnormal cnv is yellow color
$CNVKIT scatter $OUT/$NAME.chr.cnr -s $OUT/$NAME.chr.call.cns --y-min -4 --y-max 4 -w 1000000 -o $OUT/$NAME.chr.call.cns.pdf




##=============== Gene-level ===============##
# call genelevel cnv
#https://cnvkit.readthedocs.io/en/stable/reports.html
# use *.call.chr.cns
$CNVKIT genemetrics $OUT/$NAME.chr.cnr > $OUT/$NAME.ratio_gene.chr.raw.tsv
$CNVKIT genemetrics $OUT/$NAME.chr.cnr -s $OUT/$NAME.chr.call.cns -t ${ratio} -m 5 > $OUT/$NAME.segment_gene.chr.raw.tsv

sed '1d' $OUT/$NAME.ratio_gene.chr.raw.tsv | cut -f 1 | sort -u > $OUT/ratio_gene.gene
sed '1d' $OUT/$NAME.segment_gene.chr.raw.tsv | cut -f 1 | sort -u > $OUT/segment_gene.gene
comm -12 $OUT/ratio_gene.gene $OUT/segment_gene.gene > $OUT/trusted-genes.txt

#${PYTHON3} ${SDIR}/extract.rows.py --list $OUT/trusted-genes.txt --matrix $OUT/$NAME.ratio_gene.chr.tsv --colName gene -o $OUT/$NAME.ratio_gene.trusted.gainloss.tsv
${PYTHON3} ${SDIR}/extract.rows.py --list $OUT/trusted-genes.txt --matrix $OUT/$NAME.segment_gene.chr.raw.tsv --colName gene -o $OUT/$NAME.segment_gene.trusted.gainloss.tmp
perl ${SDIR}/filter.cnvkit-geneLevel.pl $OUT/$NAME.segment_gene.trusted.gainloss.tmp > $OUT/$NAME.segment_gene.trusted.gainloss.tsv


# remove process files
rm -f $OUT/*target.bed $OUT/*targetcoverage.cnn $OUT/*.tmp $OUT/*.gene
rm -f $OUT/*.filtered.cns $OUT/*.trusted-genes.txt $OUT/$NAME.segment_gene.chr.raw.tsv 


