#!/bin/bash

# Hua Sun
# v2 08/02/2020 beta


# Call single tumor sample CNV using existing poolNormal - reference_normals.cnn
#
# Usage
# bash cnvkit_wxs.sh -N sampleName -C config.ini -B /path/tumor.bam -R /path/reference_normals.cnn -O /path/outputDir
# the output - sampleName.T.*
# the bam only need tumor bam & bam.bai
# sample.N.bam (normal), sample.T.bam (tumor)
# the best sample name as no '.'


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
  echo "[ERROR] No code directory $SDIR ..." >&2
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


##=============== Pre-call cna ===============##

# target  
$CNVKIT coverage $BAM $GENOME_TARGET -o $OUTDIR/$NAME.T.targetcoverage.cnn
# antitarget
$CNVKIT coverage $BAM $GENOME_ANTITARGET -o $OUTDIR/$NAME.T.antitargetcoverage.cnn

$CNVKIT fix $OUTDIR/$NAME.T.targetcoverage.cnn $OUTDIR/$NAME.T.antitargetcoverage.cnn $POOLS_REF_CNN -o $OUTDIR/$NAME.T.cnr


##=============== Filter ===============##
# add --min-variant-depth 20 11/8
$CNVKIT segment $OUTDIR/$NAME.T.cnr --method cbs --drop-low-coverage --min-variant-depth 20 -o $OUTDIR/$NAME.T.cns


# default bin >10kb
# cutoff probe >10
# chromosome      start   end     gene    log2    depth   probes  weight
perl -ne '@F=split/\t/; $probe=$F[6]; $len=$F[2]-$F[1]; if($.==1){print}elsif($probe>10 && $len>1000){print}' $OUTDIR/$NAME.T.cns > $OUTDIR/$NAME.T.filtered.cns


# chr1-22 (XY also removed because it had low accuracy)
perl -ne 'print if (/^chr\d+/ || /^chromosome/ || /^\d+/)' $OUTDIR/$NAME.T.cnr > $OUTDIR/$NAME.T.chr.cnr
perl -ne 'print if (/^chr\d+/ || /^chromosome/ || /^\d+/)' $OUTDIR/$NAME.T.filtered.cns > $OUTDIR/$NAME.T.chr.cns



##=============== Plot cn pattern ===============##
# draw plot DO NOT use *.noNeutral due to understand the neutral pattern
$CNVKIT scatter $OUTDIR/$NAME.T.chr.cnr -s $OUTDIR/$NAME.T.chr.cns --y-min -4 --y-max 4 -w 1000000 -o $OUTDIR/$NAME.T.chr.cns.pdf



##=============== Add absolute CN ===============##
$CNVKIT call $OUTDIR/$NAME.T.chr.cns -m threshold -t=-1.3,-0.4,0.3,0.9 -o $OUTDIR/$NAME.T.chr.call.cns



##=============== Gene-level ===============##
# call genelevel cnv
#https://cnvkit.readthedocs.io/en/stable/reports.html
# use *.call.chr.cns
$CNVKIT genemetrics $OUTDIR/$NAME.T.chr.cnr > $OUTDIR/$NAME.T.ratio_gene.chr.tsv
$CNVKIT genemetrics $OUTDIR/$NAME.T.chr.cnr -s $OUTDIR/$NAME.T.chr.call.cns -t 0.4 -m 5 > $OUTDIR/$NAME.T.segment_gene.chr.tsv

sed '1d' $OUTDIR/$NAME.T.ratio_gene.chr.tsv | cut -f 1 | sort -u > $OUTDIR/$NAME.T.ratio-genes.txt
sed '1d' $OUTDIR/$NAME.T.segment_gene.chr.tsv | cut -f 1 | sort -u > $OUTDIR/$NAME.T.segment-genes.txt
comm -12 $OUTDIR/$NAME.T.ratio-genes.txt $OUTDIR/$NAME.T.segment-genes.txt > $OUTDIR/$NAME.T.trusted-genes.txt

${PYTHON3} ${SDIR}/extract.rows.py --list $OUTDIR/$NAME.T.trusted-genes.txt --matrix $OUTDIR/$NAME.T.ratio_gene.chr.tsv --colName gene -o $OUTDIR/$NAME.T.ratio_gene.trusted.gainloss.tsv
${PYTHON3} ${SDIR}/extract.rows.py --list $OUTDIR/$NAME.T.trusted-genes.txt --matrix $OUTDIR/$NAME.T.segment_gene.chr.tsv --colName gene -o $OUTDIR/$NAME.T.segment_gene.trusted.gainloss.tmp
perl ${SDIR}/filter.cnvkit-geneLevel.pl $OUTDIR/$NAME.T.segment_gene.trusted.gainloss.tmp > $OUTDIR/$NAME.T.segment_gene.trusted.gainloss.tsv



# remove process files
rm -f $OUTDIR/$NAME.T.*target.bed $OUTDIR/$NAME.T.*targetcoverage.cnn $OUTDIR/$NAME.T.ratio-genes.txt $OUTDIR/$NAME.T.segment-genes.txt $OUTDIR/$NAME.T.*.tmp


