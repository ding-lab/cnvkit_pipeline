# cnvkit_pipeline (beta v2)
Call copy number from WES(WXS)


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


## Usage

```
Call CNV - cnvkit - v0.96

The usage example

Please create and set "config.ini" before running the pipeline. 


##------ General full pipeline
sh src/cnvkit_wxs.general.pipeline.sh -C config.ini -B ./bamFolder -O ./result


##------ Tumor-Normal
# call cna
sh src/cnvkit_wxs.tumorNormal.v2.sh -C config.ini -S sampleName -N normal.bam -T tumor.bam -O tunorNormal_results

# merge results
sh src/run.cnvkit.merge-results.tumor-normal.sh tunorNormal_results


##------ Tumor-Only
# call cna
sh src/cnvkit_wxs.tumorOnly.v2.sh -C config.ini -N sampleName -B tumor.bam -R ref_normal.cnn -O tumorOnly_results

# merge results
sh src/run.cnvkit.merge-results.poolNor.sh tumorOnly_results


##------ pipeline for mgi-server
use 'cnvkit_wxs.pipeline.mgi.v4.sh' pipeline

## Tumor-Normal
* tumorNormal.table
  ID  DataType Group  Normal  Tumor  Normal_bam  Tumor_bam

# call cnv
sh cnvkit_wxs.pipeline.mgi.v4.sh -F tumorNormal -T tumorNormal.table -O cnvkit_tumorNormal -C config.ini
            
# merge results
sh cnvkit_wxs.pipeline.mgi.v4.sh -F merge-tn -O cnvkit_tumorNormal


## Tumor-Only
* tumor-only.table
  SampleID DataType BAM

# call cnv
sh cnvkit_wxs.pipeline.mgi.v4.sh -F tumorOnly -T tumor-only.table -R ./poolNormal/reference_normals.cnn -O cnv_tumorOnly -C config.ini 

# merge results
sh cnvkit_wxs.pipeline.mgi.v4.sh -F merge-pool -O cnv_tumorOnly

```



## Contact
Hua Sun (hua.sun@wustl.edu)
