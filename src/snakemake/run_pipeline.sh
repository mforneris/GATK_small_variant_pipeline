#! /usr/bin/env bash 


##################
# This script is based on Christian Arnold work. 
# Wrapper script to execute snakemake 
# please run with -h to get help
##################



##################
# FUNCTIONS 
##################
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

# expects the absolute path to the dir to check or create
checkorcreatedir(){
	DIR=$1
	if [ ! -d  $DIR ]; then 
		try mkdir -p $DIR
		yell "$DIR created"
	else
		yell "Skipping $DIR creation (already exists)"
	fi
}

# current dir, we are somewhere below <project>/src dir 
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# source the util functions
source ${CWD%src*}/src/sh/utils/readconfig.bash


##################
# HELP SECTION
##################
printhelp() {
cat << HELPTXT

Execute the Snakefile file found in the indicated <workflow dirname>. 
Important :
- the snakemake file must be named "Snakemake"
- there must be a cluster.json file found in this folder. All params listed in 
  cluster_template.json must be listed. 

SYNOPSIS

> run_pipeline.sh [opts] -w <workflow dirname> -o <output dir abspath>

Where opts in :
   -a <additional snakemake command line options> will be injected on top of given options 
      and default options already injected (i.e. cerefully review the default commad line)
   -c <config_file_path> to overwrite the default use of config/config.yml 
   -d dry-run i.e. inject a --dryrun in snakemake call
   -e <custom snakemake command line options> all other optional options will be ignore but 
     '-w' and '-o' that are still expected and -c if provided (otherwise the project config is given 
     to the snakemake command)
   -f force re-run all i.e. inject --forceall in snakemake call
   -h flag print this message
   -i flag to ignore the zero-sized-files, only if you are sure these must be ignored
   -l only use local computation i.e. no cluster mode
   -n inject a --nolock option in the snakemake call
   -o <output dir abspath> abs path to the output directory where everything will be happening
   -t <thread number> to pass to --cores directive (default to 6) in snakemake call
   -v verbose , also inject a --verbose in snakemake call
   -w <workflow dirname>, this dir is expected to be in the same dir as this script 
   -x also generate summary and workflow image files

HELPTXT

}


##################
# INIT DEFAULTs AND COMMAND LINE PARSING
##################

# read config values as needed 
PROJECT_ROOT=$(readconfig global.projectpath)


# options you might want to change that cannot be manipulated with command line

# Maximum number of simultaenous jobs
maxJobsCluster=400
# Maximum number of times a job should be reexecuted when failing
maxRestartsPerJob=2
clusterConfig="cluster.json"
snakefile="Snakefile"
# You can usually leave this untouched unless you also suffer from the "bug" that dot has a problem producing PDF files. Then change to "svg" pr "png"
workflowGraphFileType="pdf"

printShellDirective="--printshellcmds"
tempDirective=""                        # or "--notemp"
touchDirective=""                       # or ="--touch"
allowedRulesDirective=""                # or allowedRulesDirective="--allowed-rules ALLOWED_RULES [ALLOWED_RULES ...]"


# Rerun jobs for incomplete tasks
# in what situation RERUN_INCOMPLETE would be false ?
rerunIncompleteDirective="--rerun-incomplete"    # or ""


# options that can be manipulated with command line
WORKFLOW_DIR=""
OUTPUT_DIR=""
HELP=false
CONFIG_FILE="${PROJECT_ROOT}/config/config.yml"
IGNORE_ZERO_SIZED_FILE=false
submitToCluster=true
nolockDirective=""
forceRerunDirective=""
dryRunDirective=""
verboseDirective=""
# Only execute the last part: Calling Snakemake
skipSummaryAndDAG=true
runCustomOptions=""
additionalOptions=""
nCores=6  

#
# Parse cmd line
#
while getopts a:c:e:o:t:w:dfilnvxh option
do
 case "${option}"
 in
 # args
 a) additionalOptions=${OPTARG};;
 c) CONFIG_FILE=${OPTARG};;
 e) runCustomOptions=${OPTARG};;
 o) OUTPUT_DIR=${OPTARG};;
 t) nCores=${OPTARG};;
 w) WORKFLOW_DIR=${OPTARG};;
 # flags
 d) dryRunDirective="--dryrun";;
 f) forceRerunDirective="--forceall";;
 i) IGNORE_ZERO_SIZED_FILE=true;;
 l) submitToCluster=false;;
 n) nolockDirective="--nolock";;
 v) verboseDirective="--verbose";;
 x) skipSummaryAndDAG=false;;
 h) HELP=true;;
 esac
done


if [ "$HELP" = true ]; then
	printhelp
	exit 0
fi

# check workflow dir exists and contains expected files
if [ -z $WORKFLOW_DIR ]; then
	die "no workflow dir provided; please provide -w option."
fi

# make it abs path
WORKFLOW_DIR="${CWD}/${WORKFLOW_DIR}"
if [ ! -d $WORKFLOW_DIR ] || [ ! -r $WORKFLOW_DIR ]; then
	die "workflow dir provided does not exist or cannot be read: ${WORKFLOW_DIR}"
else
	SNAKEFILE_ABS="${WORKFLOW_DIR}/${snakefile}"
	if [ ! -r $SNAKEFILE_ABS ]; then
		die "Expected ${snakefile} not found in ${WORKFLOW_DIR}"
	fi
	
	CLUSTERCONFIG_ABS="${WORKFLOW_DIR}/${clusterConfig}"
	if [ ! -r $CLUSTERCONFIG_ABS ]; then
		die "Expected cluster config file ${clusterConfig} not found in ${WORKFLOW_DIR}"
	fi
	# reset to abs path now
	snakefile="${WORKFLOW_DIR}/${snakefile}"
	clusterConfig="${WORKFLOW_DIR}/${clusterConfig}"
fi

if [ -z $OUTPUT_DIR ]; then
	die "no output dir provided; please provide -o option."
else
	checkorcreatedir $OUTPUT_DIR
fi

if [ ! -r $CONFIG_FILE ]; then
	die "Expected config file not found or not readable: ${CONFIG_FILE}"
fi

if [ -z $verboseDirective ]; then
	printShellDirective=""
fi

condaDirective=""
CONDA_DIR=$(readconfig global.condaenvdir)
if [ -n $CONDA_DIR ] && [ "$CONDA_DIR" != "null" ] ; then
	condaDirective="--use-conda --conda-prefix ${PROJECT_ROOT}/${CONDA_DIR}"
fi

##################
# BUSINESS SECTION
##################

now="$(date +'%Y-%m-%d_%H-%M-%S')"


# Create a subdirectory where the stuff goes
logDirBasename="logs"
reportsDirBasename="reports"
OUTPUT_DIRLog="${OUTPUT_DIR}/$logDirBasename"
OUTPUT_DIRReports="${OUTPUT_DIR}/$reportsDirBasename"
inputDirBasename="0.Input/$now"
inputDir="${OUTPUT_DIR}/$inputDirBasename"
logParameters="${inputDir}/SnakemakeParams.log"
fileDAG="$OUTPUT_DIRReports/workflow.dag"
workflowGraphPDF="$OUTPUT_DIRReports/workflow.pdf"
workflowGraphSVG="$OUTPUT_DIRReports/workflow.svg"
stats="$OUTPUT_DIRLog/snakemake_stats.txt"
stats2="$OUTPUT_DIRLog/snakemake_summaryDetailed.txt"

checkorcreatedir $OUTPUT_DIRLog
checkorcreatedir $OUTPUT_DIRReports
checkorcreatedir $inputDir


# Handle potential empty files
if [ "$IGNORE_ZERO_SIZED_FILE" = false ] ; then

  # Check for 0-sized output files and abort if some are present
  echo "Check for zero-sized files (excluding files in $OUTPUT_DIRLog)...."
  command="find $OUTPUT_DIR -type f -size 0 ! -path '*$logDirBasename*' ! -path '*/.snakemake/*'"

  echo "Execute command \"$command\""

  nEmptyFiles=$(eval "$command | wc -l")
  if [ $nEmptyFiles -gt 0 ] ; then
    echo -e "\nWARNING\nThe following $nEmptyFiles zero-sized files have been found:"
    emptyFiles=$(eval "$command")
    echo $emptyFiles
    echo "Check them carefully and delete them to avoid potential issues"
    echo "Use '$command -delete' to delete them"
    exit 1
  fi

else
	cat << WARN
Found option -i => ignoring Zero-sized files. 
You must be sure that all existing zero-sized files are supposed to be empty.
Note that empty files might indicate an error during last Snakemake execution."
WARN

fi

############
# Build cmd lines 
############
clusterDirective=""

if [ "$submitToCluster" = true ] ; then
	nHits=$(grep -c nodes $clusterConfig)
	if [ "$nHits" -eq "0" ]; then
		clusterSpecifics="--cluster \" sbatch -N 1 -p {cluster.queueSLURM} -J {cluster.name} -A {cluster.group} --cpus-per-task {cluster.nCPUs} --mem {cluster.memory} --time {cluster.maxTime} -o \"{cluster.output}\" -e \"{cluster.error}\" --mail-type=FAIL \""
	else
		clusterSpecifics="--cluster \" sbatch -N 1 -p {cluster.queueSLURM} -J {cluster.name} -C {cluster.nodes} -A {cluster.group} --cpus-per-task {cluster.nCPUs} --mem {cluster.memory} --time {cluster.maxTime} -o \"{cluster.output}\" -e \"{cluster.error}\" --mail-type=FAIL \""
	fi

	clusterDirective="--jobs $maxJobsCluster --cluster-config $clusterConfig $clusterSpecifics --local-cores 1 --restart-times $maxRestartsPerJob"

fi

echo "Automated parameter report, generated $now"              | tee $logParameters
echo ""                                                        | tee -a $logParameters

echo "##############"                                          | tee -a $logParameters
echo "# PARAMETERS #"                                          | tee -a $logParameters
echo "##############"                                          | tee -a $logParameters

echo " FILES AND DIRECTORIES"                                  | tee -a $logParameters
echo "  CONFIG_FILE                  = $CONFIG_FILE"           | tee -a $logParameters
echo "  snakefile                    = $snakefile"             | tee -a $logParameters
echo "  OUTPUT_DIR                   = $OUTPUT_DIR"            | tee -a $logParameters
echo "  IGNORE_ZERO_SIZED_FILE       = $IGNORE_ZERO_SIZED_FILE"  | tee -a $logParameters

echo " PERFORMANCE OPTIONS"                                    | tee -a $logParameters
echo "  nCores                       = $nCores"                | tee -a $logParameters
echo "  nolock                       = $nolockDirective"       | tee -a $logParameters
echo "  skipSummaryAndDAG            = $skipSummaryAndDAG"     | tee -a $logParameters

echo " DEVELOPMENT OPTIONS"                                    | tee -a $logParameters
echo "  useVerbose                   = $verboseDirective"      | tee -a $logParameters
echo "  dryRun                       = $dryRunDirective"       | tee -a $logParameters
echo "  ignoreTemp                   = $tempDirective"         | tee -a $logParameters
echo "  touchOutputFiles             = $touchDirective"        | tee -a $logParameters
echo "  runCustomOptions             = $runCustomOptions"      | tee -a $logParameters
echo "  additionalOptions            = $additionalOptions"     | tee -a $logParameters
echo "  workflowGraphFileType        = $workflowGraphFileType" | tee -a $logParameters

echo " CONDA OPTIONS"                                          | tee -a $logParameters
echo "  condaDirective               = $condaDirective"        | tee -a $logParameters

echo " CLUSTER OPTIONS"                                        | tee -a $logParameters
echo "  submitToCluster              = $submitToCluster"       | tee -a $logParameters
echo "  clusterConfig                = $clusterConfig"         | tee -a $logParameters
echo "  maxJobsCluster               = $maxJobsCluster"        | tee -a $logParameters
echo "  maxNoRestartJobsUponFailure  = $maxRestartsPerJob"     | tee -a $logParameters
echo "  clusterDirective             = $clusterDirective"     | tee -a $logParameters

echo " RULE OPTIONS"                                           | tee -a $logParameters
echo "  forceRerunDirective          = $forceRerunDirective"   | tee -a $logParameters
echo "  allowedRules                 = $allowedRulesDirective" | tee -a $logParameters


# Copy the configuration files etc to the input folder
cp $CONFIG_FILE    $inputDir
cp $snakefile     $inputDir
cp $clusterConfig $inputDir
# and make sure to now use the copy in commands, not the original ones 
CONFIG_FILE="${inputDir}/$(basename ${CONFIG_FILE})"
snakefile="${inputDir}/$(basename ${snakefile})"
clusterConfig="${inputDir}/$(basename ${clusterConfig})"

if [ -n  "$runCustomOptions" ] ; then
   echo "Run with custom options:"
   commandFull="snakemake -s $snakefile --configfile $CONFIG_FILE $runCustomOptions"
   echo "$commandFull"
else

	# Run 1: Detailed summary about what files will be generated
	command1="snakemake -s $snakefile --configfile $CONFIG_FILE $forceRerunDirective \
			  $tempDirective --detailed-summary  >$stats2"

	#Run 2: Produce a workflow graph
	command2="snakemake -s $snakefile --configfile $CONFIG_FILE --forceall --dag > $fileDAG"

	if [ "$skipPDFWorkflow" = true ] ; then
		command2a="echo \"skipping creation of PDF workflow graph\""
	else
		command2a="dot $fileDAG -Tpdf > $workflowGraphPDF"
	fi
	# Also do a SVG in addition for easier edits
	command2b="dot $fileDAG -Tsvg > $workflowGraphSVG"

	# Run 3: Main run: Execute the pipeline
	command3="snakemake -s $snakefile $condaDirective $nolockDirective --reason --configfile $CONFIG_FILE \
			  --latency-wait 30  $verboseDirective $dryRunDirective $forceRerunDirective \
			  $printShellDirective $touchDirective $allowedRulesDirective $tempDirective \
			  $rerunIncompleteDirective --timestamp --cores $nCores \
			  --keep-going --stats $stats $additionalOptions $clusterDirective"

	if [ "$skipSummaryAndDAG" = true ] ; then
		commandFull="$command3"
	else
		commandFull="$command1 && $command2 && $command2a && $command2b && $command3"

		echo "$command1"                            | tee  -a    $logParameters
		echo "#######################"              | tee  -a    $logParameters
		echo "$command2"                            | tee  -a    $logParameters
		echo "#######################"              | tee  -a    $logParameters
		echo "$command2a"                           | tee  -a    $logParameters
		echo "#######################"              | tee  -a    $logParameters
		echo "$command2b"                           | tee  -a    $logParameters
		echo "#######################"              | tee  -a    $logParameters
	fi

	echo "$command3"                                | tee  -a    $logParameters
	echo "#######################"                  | tee  -a    $logParameters
fi
eval $commandFull






