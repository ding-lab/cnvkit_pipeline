# cnvkit_pipeline
Call copy number from WES(WXS)


## Usage

```
Call CNV - cnvkit - v0.96

The usage example

Please set create and set "config.ini" file before using the pipeline. 

##------ Simple run as pool samples

bash subScripts/run.cnvkit_wxs.batch.v1.sh -C config.ini -B ./bamFolder -O ./result



##------ Tumor-Normal

# run call-cnv
sh cnvkit_wxs.pipeline.mgi.sh -C config.ini -F batch-tn -T tumorNor.wxs.table -D ./wxs/all_wxs_sampleBams -O ./tumorNormal_cnv

# merge results
sh cnvkit_wxs.pipeline.mgi.sh -C config.ini -F merge-tn -O tumorNormal_cnv


##------ Tumor-Only

# make pool normal
sh cnvkit_wxs.pipeline.mgi.sh -C config.ini -F cnn -D `pwd`/softlink_bams -O `pwd`/poolNormal
sh cnvkit_wxs.pipeline.mgi.sh -C config.ini -F ref -O poolNormal


# call cnv from pool normal
sh cnvkit_wxs.pipeline.mgi.sh -C config.ini -F batch-tumor -T sampleList -R ./cnvkit/reference_normals.cnn -D ./wxs/all_wxs_sampleBams -O tumorOnly_cnv


# merge results
sh cnvkit_wxs.pipeline.mgi.sh -C config.ini -F merge-pool -O tumorOnly_cnv

```


## Install

```
https://github.com/etal/cnvkit

miniconda2 - python 2.7

# Install CNVkit in a new environment named "cnvkit"
conda create -n cnvkit python=3.6
conda activate cnvkit
	conda install -c bioconda cnvkit
	conda install numpy scipy pandas matplotlib reportlab biopython pyfaidx pysam pyvcf
	conda install r-cghflasso
conda deactivate

# install not inner cnvkit
conda install -c bioconda bioconductor-dnacopy


To run the segmentation algorithm CBS, you will need to also install the R dependencies (bioconda bioconductor-dnacopy)

```




## Contact
Hua Sun (hua.sun@wustl.edu)
