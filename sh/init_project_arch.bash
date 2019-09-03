#! /usr/bin/env bash 

#
# Initialise folder structure for the project according to names found in config.yaml
# This is indeed needed as .gitignore prevents to register dirs like data, analysis, env, tmp
#


# ADAPT THE LIST OF DIR_TO_CREATE to REFLCT YOUR CONFIG.YML
# datadir will be created as an artefact
DIR_TO_CREATE=( "global.genomedatadir" "global.seqdatadir" "global.analysisdir" "global.condaenvdir" "global.tmpdir" "global.fastqdir" "global.bamdir" "global.bigwigdir" "global.qcdir" "global.pysrcdir" "global.Rsrcdir" )


# we are somewhere below src/
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 
# source the util functions
source ${CWD%src*}/src/sh/utils/readconfig.bash

#functions 
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

# expects 2 values : 
# - the PROJECT_DIR abs path
# - the parameter name to use to grab the folder name to be created
checkorcreatedir(){
	VAL=$(readconfig $2)
	if [ -n $VAL ] && [ "$VAL" != "null" ] ; then
		DIR=$1"/"$VAL
		if [ ! -d  $DIR ]; then 
			try mkdir -p $DIR
			echo "$DIR created"
		else
			echo "Skipping $DIR creation (already exists)"
		fi
	else
		yell "no property found for value $2; skipping dir creation!"
	fi
}
##
# reading parameters from config file
##


# reading simple values like the project directory organisation
PROJECT_DIR=$(readconfig global.projectpath)


for d in "${DIR_TO_CREATE[@]}"
do
	echo "Checking dir for property $d ..."
	checkorcreatedir ${PROJECT_DIR} $d
done