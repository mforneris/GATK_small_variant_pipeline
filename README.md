# GATK Joint Genotype Call pipeline

<br /><br />

## Global folder structure of the project

The directory containing this file is the project root or project folder.
All data, analysis etc ... related to the project should be found in sub-directories.
Here is a list a pre-defined directories and what they are made for:

* The **config** folder contains a project config file and conda environment files (not present in this project):
    * **config.yml**. This file contains all the global settings of the project. These settings are used throughout in the pipelines (src/snakemake folder). In particular, it sets up folder paths for inputs and outputs and tools absolute paths. **If you are cloning this pipeline it is very important to setup the config.yml file so it can owrk on your install.**


<br />

* The **src** dir is sub-divided into programming language dir and host code to perform all the analysis. In particular:
    * **snakemake** folder contains the pipelines to produce the entire variant call. There are four pipelines to perform: 1. Input quality control 2. Read mapping 3. Proper variant calling 4. Population structure analysis
    * **Rmd** dir contains the Rmarkdown notebooks with the visual analysis of the results.
    * **R** folder contains R scripts
    * **python** folder contains python scripts
    * **sh** folder contains bash scripts
    * **metadata** folder contains information used in the data analysis, such as the primers used for library generation.

<br />

* The **data** dir contains ALL data used as input and partial output files. It is divided in:
    * **fastq** folder that contains the links to all the fastq raw files.
    * **bam** folder for mapped reads. (For now bam files are stored on /scratch to save disk space. The output directories can be easily set up in the config.yml file). 

<br />

* The **analysis** dir is organized into different analysis sub-directories. In particular:
    * The **QC** folder contains all the Quality control metrics from fastqc and from the mapping. In addition these metrics are collected in multiqc files.
    * The **GATK_variant_call** folder contains the outputs from GATK and the multiple steps of the variant call.
    * The **population_structure** folder contains the outputs from SnpEff and plink to obtain the relationships between individuals after genotyping them.

<br /><br />

## Necessary software to run the pipeline

Theis software is necessary to run the pipeline. In general, you need an [Anaconda](https://www.anaconda.com/) installation. All the software listed here can be installed trhough Anaconda. <br />
The table below lists the software necessary to run the pipeline, the version used in this pipeline and the conda command to install the software (simply run in a shell to install). If you want to install a specific version of the softare use '=='. E.g. to install version 0.11.5 of fastqc run 'conda install -c bioconda fastqc==0.11.5'

| Software  |  version | conda install command |
|:---|:---|:---:|
| fastqc | 0.11.5 | conda install -c bioconda fastqc |
| multiqc | 1.6 | conda install -c bioconda multiqc |
| trimgalore | 0.5.0 | conda install -c bioconda trim-galore |
| bwa | 0.7.17 | conda install -c bioconda bwa |
| samtools | 1.9 | conda install -c bioconda samtools |
| picard | 2.16.0 | conda install -c bioconda picard |
| gatk | 4.1.0.0 | Dowload from [GATK website](https://software.broadinstitute.org/gatk/download/index)  |
| vcftools | 0.1.14 | conda install -c bioconda vcftools |
| tabix | 1.9 | conda install -c bioconda tabix |
| bgzip | 1.9 | conda install -c bioconda htslib |
| bcftools | 1.9 | conda install -c bioconda bcftools |
| snpeff | 4.3T  | Dowload from [SnpEff website](http://snpeff.sourceforge.net/) |
| snpsift | 4.3T  | Dowload from [SnpEff website](http://snpeff.sourceforge.net/) |
| bedtools | 2.26.0  | conda install -c bioconda bedtools |
| plink | 1.90b3  | conda install -c bioconda plink |
| rscript | 3.4.3  |  Dowload from [R website](https://cran.uni-muenster.de/) |