#!/usr/bin/bash

/g/furlong/forneris/software/anaconda3/bin/snakemake -j 2000 --use-conda --cluster-config cluster.json --configfile ../../../config/config.yml --cluster "{cluster.sbatch} -p {cluster.partition} --cpus-per-task {cluster.n} --mem {cluster.mem} {cluster.moreoptions}" --timestamp --keep-going --rerun-incomplete
