# cnvkit_pipeline
call copy number from WES(WXS)


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

