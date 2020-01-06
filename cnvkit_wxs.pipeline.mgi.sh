#!/bin/bash

# Hua Sun
# v2.3 12/24/2019


# Usage

# Items
#		Full steps by one
#		Separate steps
#		Draw heatmap
#		Extract gene based cnv

# bash cnvkit_wxs.sh -F full -D ./bamFolder -O /path/outputDir
# the bamfolder includes normal(*.N.bam) & tumor (*.T.bam) bam and bam.bai
# sample.N.bam (normal), sample.T.bam (tumor)
# the best sample name as no '.'
# [Tip] if normal and tumor bam folder separated, then run two time only step 1 for each folder.
# [Tip] only -O require input full path

# Step 0 make genome bed	(only run onetime enough)
#		sh cnvkit_wxs.pipeline.sh -F bed


#----- call tumor-normal
# table
# id group normal tumor

# bamDir/sample.remDup.bam

# sh cnvkit_wxs.pipeline.sh -F batch-tn -T table.tsv -D 2.remDup_renameB3_samples -O `pwd`/results_tumNor

# merge
# sh ~/scripts/pipeline/cnvkit/cnvkit_wxs.pipeline.mgi.sh -F merge-tn -O results_tumNor


# Gene-level cnv call
# sh cnvkit_wxs.pipeline.mgi.sh -F callGene-tn -O `pwd`/results


#----- tumor-only

# Step 1 make ref cnn
#   sh cnvkit_wxs.pipeline.sh -F cnn -D /path/bamDir -O /cnvkit/result_human
#       // The /cnvkit/bams folder included *.N.bam and *.T.bam. all of sample name only \w+ no special word
# Step 2 make ref
#   sh cnvkit_wxs.pipeline.sh -F ref -O /cnvkit/result_human
#

# Step 3 call cnv by poolNormal
# table 
# sample1
# sample2
# sh ~/scripts/pipeline/cnvkit/cnvkit_wxs.pipeline.mgi.sh -F batch-tumor -T sampleList -R poolNorRef.cnn -D bamDir -O results_tumNor

# merge
# sh ~/scripts/pipeline/cnvkit/cnvkit_wxs.pipeline.mgi.sh -F merge-pool -O results_tumNor


# Gene-level cnv call
# sh cnvkit_wxs.pipeline.mgi.sh -F callGene -O `pwd`/results


#---------------------------------------

# All of steps in one step (draft call)
#		sh cnvkit_wxs.pipeline.sh -F test-full -D /gscmnt/cnvkit/bams -O /gscmnt/cnvkit/result
#  No-control full step
# 	sh cnvkit_wxs.pipeline.sh -F test-full-noControl -D /gscmnt/cnvkit/bams -O /gscmnt/cnvkit/result
#
# Cutoff and only show chr1-22 in visualization
#		sh cnvkit_wxs.pipeline.sh -F call -O /gscmnt/cnvkit/result
# Plot
#   sh cnvkit_wxs.pipeline.sh -F scatter -O /gscmnt/cnvkit/result
# Summary heatmap 
#		sh cnvkit_wxs.pipeline.sh -F heatmap -O /gscmnt/cnvkit/result





# set default options
CONFIG=/gscuser/hua.sun/scripts/pipeline/cnvkit/mgi.config.gencode_grch38.ini


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
##           Pool-normal pipeline
##============================================##

## run step-0
# prepare file for call target cnv (if the reference version different, then run this step)
if [[ "$FLAG" = "bed" ]]; then
	echo "[INFO] Prepare reference for CNVkit ..."
  sh $LSFSUB 8 1 cnn_wxs.genome "bash $SDIR/0_createGenomeBed.sh $CONFIG"
  exit
fi


## run step-1
# call cnn
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



## run step-3
# call cnv
if [[ "$FLAG" = "cnv" ]]; then
  ls $OUTDIR/*.T.targetcoverage.cnn | while read cnn; do
    fileName=${cnn##*/}
    name=${fileName%.T.targetcoverage.cnn}       
    if [ -e $OUTDIR/$name.T.targetcoverage.cnn ] && [ -e $OUTDIR/$name.T.antitargetcoverage.cnn ]; then
       # submit job to research-hpc
      sh $LSFSUB 4 1 cnv_wxs.$name "bash $SDIR/3_call_cnv.sh $CONFIG $PoolNorRef $name  $OUTDIR"
    else
      continue
    fi
  done
fi




##========= run call and only extract chr1-22
# call
if [[ "$FLAG" = "call" ]]; then
  ls $OUTDIR/*.T.cns | while read cns; do
    fileName=${cns##*/}
    name=${fileName%.T.cns}
    # submit job to research-hpc
    sh $LSFSUB 1 1 call_wxs.$name "bash $SDIR/call_chr1-22.sh $CONFIG $name $OUTDIR"
  done
fi




##========= run call tumor-only full pipeline
# call-full-tumor-only
if [[ "$FLAG" = "batch-tumor" ]]; then
	cat $TABLE | while read sample; do
		sh $LSFSUB 8 1 tumorOnly-batch.${sample} "bash $SDIR/cnvkit_wxs.perTumor4poolNormal.sh -N $sample -C $CONFIG -B $bamDir/$sample.remDup.bam -R $PoolNorRef -O $OUTDIR"
	done
fi




##========= Extract Gene-level CNA

if [[ "$FLAG" = "callGene" ]]; then
  ls $OUTDIR/*.T.call.chr.cns | while read cns; do
    fileName=${cns##*/}
    name=${fileName%.T.call.chr.cns}
    # submit job to research-hpc
    sh $LSFSUB 1 1 geneCNV.$name "bash $SDIR/callGeneLevel_cnv.sh $CONFIG $name $OUTDIR"
  done
fi




##========= Merge segment and gene-level files 

# Merge segment and gene-level files from pool normal
if [[ "$FLAG" = "merge-pool" ]]; then
  bash $SDIR/run.cnvkit.merge-results.poolNor.sh $OUTDIR
fi




##========= Draw CNV-plot 

## run step-x only do re-plot for call.cns
# draw plot
if [[ "$FLAG" = "scatter" ]]; then
  ls $OUTDIR/*.T.call.cns | while read cns; do
    fileName=${cns##*/}
    name=${fileName%.T.call.cns}
    # submit job to research-hpc
    sh $LSFSUB 1 1 scatter_wxs.$name "bash $SDIR/scatter.sh $CONFIG $name $OUTDIR"
  done
fi


## draw heatmap for all samples (chr1-22)

# draw summary heatmap
if [[ "$FLAG" = "heatmap" ]]; then
  sh $LSFSUB 1 1 heatmap.cnvkit "bash $SDIR/heatmap.sh $CONFIG $OUTDIR"
fi



##============================================##
##       Tumor-normal pipeline without Pool normal
##============================================##

#table=$1
#table=./tumor-normal.info
#id      group   normal  tumor (header=T)
#H_XU-528-M1503126       Human   H_XU-528-M1510195_1     H_XU-528-M1503126

# dir_bam=/gscmnt/gc3021/dinglab/PDX/Analysis/PDX_U54/integration/1.set_filtered_bam/wxs/2.remDup_renameB3_samples
# the bamfile name "sample.remDup.bam"

# tumor-normal pair samples - call cnv full pipeline
if [[ "$FLAG" = "batch-tn" ]]; then

	sed '1d' $TABLE | while read id group normal tumor
	do
    
    if [[ $id == "" ]];then continue; fi

		sh $LSFSUB 8 1 tumNor_cn.${id} bash $SDIR/cnvkit_wxs.tumor-normal.withoutPoolNor.sh -S $id -N ${bamDir}/$normal.remDup.bam -T ${bamDir}/$tumor.remDup.bam -O $OUTDIR

	done

fi


# Merge segment and gene-level files from non-poolNor
if [[ "$FLAG" = "merge-tn" ]]; then
  bash $SDIR/run.cnvkit.merge-results.tumor-normal.sh $OUTDIR
fi




# only re-call gene-level cnv
if [[ "$FLAG" = "callGene-tn" ]]; then
  ls $OUTDIR | grep -v '^\.' | perl -pe 's/\/$//' | while read sample
  do
    # submit job to research-hpc
    sh $LSFSUB 1 1 geneCNV.$name "bash $SDIR/callGeneLevel_cnv.sh $CONFIG $sample $OUTDIR f2"
  done
fi



