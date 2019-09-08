# Snakemake

<br><br>


## Overview of the pipelines

This folder contains four Snakemake workflows that implement the [GATK Best Practice](https://software.broadinstitute.org/gatk/best-practices/workflow?id=11145) for variant calling, the data quality control and some additional analysis. It implements a joint genotyping, that requires larger computation power but can be run in parallel and ensurs the most accurate variant discovery.
The workflows should be run in the following order:


1. **QUALITY_CONTROL**: The fist step in the workflow is the fastq quality control. This step is important to assess the quality of the sequencing and the coverage. It is based on collecting metrics from fastqc and Picard. The metrics are nicely displayed using multiqc. This step requires mapping the reads to the reference.

2. **MAPPING**: The second step maps the reads using bwa. Th reads are trimmed for per base quality, mapped with bwa on the joint genome of Drosophila and Drosophila parasite Wolbachia to remove contaminant DNA. The reads are then sorted, duplicates are marked and then removed and the bam files are annotated to be ready for use in GATK. The mapping quality scores are then recalibrated to take into account variants within the reads.

3. **GATK_VARIANT_CALL**: The third step includes the proper variant calling. It is based on GATK Best Practice guidelines and it performs a joint genotyping. Variants are called running HaplotypeCaller and, to parallelize the vairant call, the ask is split by chromosomes (visible in file "analysis/GATK_variant_call/chromosomes_list.txt"). For larger dataset HaplotypeCaller accepts regions in bed format to further parallelize the variant calling. Variants are then merged across chromosomes. The pipeline then includes three rules that perform the variant recalibration from GATK. This step is usefull to update the QUAL score in the vcf when comparing with a gold standard. Unfortunately Drosophila does not have any gold standard variant annotation and the task is made more difficult when considering inbred flies. This makes the variant recalibration steps unfiesable in this context. I moved forward without variant recalibration and applied [hard filters following GATK suggestions](https://software.broadinstitute.org/gatk/documentation/article?id=11069) on quality metrics (this is discussed in the Rmarkdown section). I applied two sets of hard filters: a stringest (that minimizes false positives) and a lenient (that minimizes false negatives). Finally, the pipeline extracts a few metrics from the variant call that are then plotted in Rmardown GATK_CALL_QC.

4. **POPULATIONS_STRUCTURE**: The population structure pipeline retrieves the genetic relationships between individuals from neutrally evolving variants. In fact, neutrally evolving variants are accumulated at a constant rate during time. To achieve this, I follow the methods in [Grenier et al](http://www.g3journal.org/cgi/pmidlookup?view=long&pmid=25673134). In particular, neutrally evolving variants are located on non-functional DNA regions. For *Drosophila*, they can be represented by short introns (<65bp). To do so, the pipeline makes use of SnpEff to annotate variants, it then identifies variants annotated as exclusively intronic and it then includes only variants that are located on short introns. Finally it filters out rare variants (maf<0.05) and variants with high proportion of missin values (>0.2). The population structure is retreived using plink PCA analysis of variants. The first 10 PCs are then plotted using R.


<br><br>

## Folders structure

All folders contain the following files:

* **Snakemake**: It includes the rules to run the pipeline. The first lines of each Snakemake file read the global settings in the config.yml file. It then sets up internal vairables and targets (lists of output files). Finally, the rules include the instructions to create every file. To run only a part of the pipeline simply change the target in the *rule all*. 

* **cluster.json**: these are the settings used to submit jobs to the cluster via [slurm](https://slurm.schedmd.com/documentation.html). They can be specific for each rule, while the default settings apply to all others.

* **snakemake_default.sh**: This file contains a simple bash line that runs the snakemake pipeline and submits jobs to the cluster integrating the Snakemake, cluster.json and config.yml information.

* **logs/**: this folder contains the STDOUT and STDERR from all jobs submitted to the cluster.


<br><br>

## Execution

In order to run the pipelines you need to:

1. Add all the software absolute paths in the config.yml file.
2. Place all the fastq files in the same folder and add the paths in the config.yml file.
3. Setup the FASTQ_WILDCARD_BASENAME variable in MAPPING/Snakemake (line 51) file so that it can create a list of all fastq file names.
4. Setup all output folder names in the config.yml
5. You can now run the pipelines on the slurm cluster using snakemake_default.sh or on the server by simply running 'snakemake --use-conda --configfile ../../../config/config.yml'. log files will be automatically generated in the logs/ folder if the pipeline runs on the cluster.
6. Make sure that the correct targets are present in the rule all!
