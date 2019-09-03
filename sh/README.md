This dir contains all your `bash` scripts. The utils sub-folder should be used to store common bash functions you might want to re-use in your scripts. 

We recommend to use [yq](https://github.com/mikefarah/yq) to parse YAML from bash script.

* On Mac, simply install it with brew  
* On servers, simply use the /g/funcgen/bin/yq executable [GBCS](gbservices.embl.de) made available
       
Then, in your script, use (note how the parameter name is made by concatenating 
the yaml levels using `.`):

```bash
BWA=$(yq r global_config.yml tools.bwa)
```

Extended example on how to read config file from bash is visible in `src/sh/read_config_example.bash`