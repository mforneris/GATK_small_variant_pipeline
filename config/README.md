The `config` dir contains configuration information, of which the `config.yml` 
is the main place where you should define the configuration variables (in different sections).

IMPORTANT: the `config.yml` must not be renamed or moved !!!

We recommend to use [yq](https://github.com/mikefarah/yq) to parse YAML from bash script.

* On Mac, simply install it with brew  
* On servers, simply use the /g/funcgen/bin/yq executable [GBCS](gbservices.embl.de) made available
       
Then, in your script, use (note how the parameter name is made by concatenating 
the yaml levels using `.`):

```bash
BWA=$(yq r global_config.yml tools.bwa)
```

Extended example on how to read config file from bash is visible in `src/sh/read_config_example.bash`