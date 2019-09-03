## Overview
The run_pipeline.sh can be use to execute all your workflows. 
The script expose some options visiable when calling 

`> run_pipeline.sh -h`
 
Note that additional options can be tweecked directly in the file (go to the section *options you might want to change that cannot be manipulated with command line*). 

You can of course duplicate this script to customize it the specific needs of a workflow


## How Workflows Must Be Organized
* Create a new directory named after your workflow (for example `WF_example`)
* Copy the cluster_template.json from the `WF_example` dir to your new dir
  * rename it to `cluster.json` 
  * keep all existing parameters and adpat them as needed 
  * add specific sections matching your rules as needed
* Note that the `config.yml` file found in the `config` dir is provided to snakemake so that config parameters are available in your snakemake file as usual e.g. `SAMTOOLS=config["tools"]["samtools"]`. 
  * See the example Snakemake file in the existing `src/snakemake/WF_example`
  * All needed additional configurations should go the `config/config.yml` possibly under a new section specific to this workflow

## Execution
* simply call 

```bash
> ./src/sh/run_pipeline.sh -w MY_WORKFLOW_DIRNAME -o /path/to.output/dir
```

* everything will then occur in this ouput directory. Please note that a copy of the Snakemake, config.yml and cluster.json file is placed in an `input` dir of the output directory; allowing to run the pipeline with different settings if needed