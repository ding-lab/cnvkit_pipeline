#!/bin/bash


#########################################################################
# Hua Sun
# v4 8/2/2020


##====== run general full pipeline from bam-folder

# sh cnvkit_wxs.pipeline.sh -F general -D bam_folder -O outdir



##====== make genome bed	& poolnormal (only run onetime enough)

## make bed
# sh cnvkit_wxs.pipeline.sh -F bed

## make ref cnn
#   sh cnvkit_wxs.pipeline.sh -F cnn -D /path/bamDir -O /cnvkit/result_human
#       // The /cnvkit/bams folder included *.N.bam and *.T.bam. all of sample name only \w+ no special word

## make poolnormal-ref
#   sh cnvkit_wxs.pipeline.sh -F ref -O /cnvkit/result_human



##====== call tumor-only (using poolnormal)

# table (no title)
# sample1   /path/bam1
# sample2   /path/bam2

## pre-call
# sh ~/scripts/pipeline/cnvkit/cnvkit_wxs.pipeline.mgi.sh -F tumorOnly -T sampleList -R poolNorRef.cnn -O poolNor_results

## merge
# sh ~/scripts/pipeline/cnvkit/cnvkit_wxs.pipeline.mgi.sh -F merge-pool -O poolNor_results



##====== call tumor-normal
# table.tsv (head=T)
#    # ID	Group	Normal	Tumor	Normal_path	Tumor_path
#    # TWDE-Fields_1291-D1291a-06-PAR-Tumor	Human_Tumor	TWDE-Fields_1291-D1291-03-PBMC	TWDE-Fields_1291-D1291a-06-PAR-Tumor	/gscmnt/gc3021/dinglab/PDX/Analysis/PDX_U54/batch9/WXS/3.human_wxs_filtered_bam/TWDE-Fields_1291-D1291-03-PBMC/TWDE-Fields_1291-D1291-03-PBMC.remDup.bam	/gscmnt/gc3021/dinglab/PDX/Analysis/PDX_U54/batch9/WXS/3.human_wxs_filtered_bam/TWDE-Fields_1291-D1291a-06-PAR-Tumor/TWDE-Fields_1291-D1291a-06-PAR-Tumor.remDup.bam

## pre-call
# sh cnvkit_wxs.pipeline.sh -F tumorNormal -T table.tsv -O tumNor_results

## merge
# sh cnvkit_wxs.pipeline.sh -F merge-tn -O tumNor_results

#########################################################################




# set default options
CONFIG=/gscuser/hua.sun/scripts/cnvkit_wxs/config/config.gencode_grch38.mgi.ini


## getOptions
while getopts "F:C:T:D:R:O:" opt; do
  case $opt in
    F)
      FLAG=$OPTARG
      ;;
    C)
      CONFIG=$OPTARG
      ;;
    T)
      TABLE=$OPTARG
      ;;
    D)
      bamDir=$OPTARG
      ;;
    R)
      PoolNorRef=$OPTARG
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

if [ ! -d $OUTDIR ]; then
    echo [ERROR] No $OUTDIR directory!
    exit 1
fi




##============================================##
##           General full pipeline
##============================================##

if [[ "$FLAG" = "general" ]]; then
    sh $LSFSUB 8 1 tumNor_cn.${id} bash $SDIR/cnvkit_wxs.general.pipeline.sh -C $CONFIG -B $bamDir -O $OUTDIR
fi




##============================================##
##           Make pool-normal
##============================================##

## run step-0
# prepare file for call target cnv (if the reference version different, then run this step)
if [[ "$FLAG" = "bed" ]]; then
    echo "[INFO] Prepare reference for CNVkit ..."
    sh $LSFSUB 8 1 cnn_wxs.genome "bash $SDIR/0_createGenomeBed.sh $CONFIG"
    exit
fi


## run step-1
# call cnn (before run it, do soft link for all of Normal bam)
if [[ "$FLAG" = "cnn" ]]; then
    ls $bamDir/*.bam | while read bam; do
        fileName=${bam##*/}
        name=${fileName%.bam}
        # submit job to research-hpc
        sh $LSFSUB 8 1 cnn_wxs.$name "bash $SDIR/1_call_cnn.sh $CONFIG $name $bam $OUTDIR"
    done
  
    exit
fi


## run step-2
# make ref.cnn by merging all of *.cnn
if [[ "$FLAG" = "ref" ]]; then
    sh $LSFSUB 8 1 refcnn_wxs "bash $SDIR/2_make_ref_cnn.sh $CONFIG $OUTDIR"
    exit
fi




##============================================##
##   Tumor-only pipeline using poolNormal
##============================================##

## I) call-full-tumor-only
if [[ "$FLAG" = "tumorOnly" ]]; then
    cat $TABLE | while read sample bam; do
        if [ ! -e $bam ];then
            echo "[Error] File not exists ... -> $sample - $bam" >&2
            continue
        fi
        sh $LSFSUB 8 1 tumorOnly-batch.${sample} "bash $SDIR/cnvkit_wxs.perTumor4poolNormal.sh -N $sample -C $CONFIG -B $bam -R $PoolNorRef -O $OUTDIR"
    done
fi


## II) Merge segment and gene-level files from pool normal
if [[ "$FLAG" = "merge-pool" ]]; then
    bash $SDIR/run.cnvkit.merge-results.poolNor.sh $OUTDIR
fi




##============================================##
##   Tumor-normal pipeline
##============================================##

## I) tumor-normal pair samples - call cnv full pipeline
if [[ "$FLAG" = "tumorNormal" ]]; then
    sed '1d' $TABLE | while read id group normal tumor normalBam tumorBam
    do
        if [[ $id == "" ]];then continue; fi
        sh $LSFSUB 8 1 tumNor_cn.${id} bash $SDIR/cnvkit_wxs.tumor-normal.withoutPoolNor.sh -C $CONFIG -S $id -N $normalBam -T $tumorBam -O $OUTDIR
    done
fi


## II) Merge segment and gene-level files from non-poolNor
if [[ "$FLAG" = "merge-tn" ]]; then
    bash $SDIR/run.cnvkit.merge-results.tumor-normal.sh $OUTDIR
fi


