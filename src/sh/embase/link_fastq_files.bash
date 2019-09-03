#! /usr/bin/env bash 


# FUNCTIONS

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


printhelp() {
cat << HELPTXT
This script creates symbolic links to all the fastq files registered in embase for this project.
emBASE experiment names to synchronize must be defined as the 'embase.expids' array in config.yml.
The symbolic links are created under the directory defined by the 'global.fastqdir' config, 
or as given with the '-o' option; then : 
  - a sub-directory is created per experiment (can be turned off with '-e')
  - symlinks are further organized into 'flowcell_lane' dirs (can be turned off with '-f')
 
N.B.:
  1. A text file listing all samples and their annotations is exported for each experiment
  2. Both symlinks to multiplexed and demultiplexed fastq files are exported (when relevant)

> ./link_fastq_files.bash [-feh] [-i expid] [-o outdir]

with :
    -e: do not organize symlinks per 'e'xperiment subdirs
    -f: do not organize symlinks per 'f'lowcell_lane directory but as a flat structure 
        (all under 'global.fastqdir')  
    -i expid : limit the synchronization to this embase experiment id
    -o outdir: create links in specified dir (abs. path) instead of 'global.fastqdir'
    -h : print this message
HELPTXT
}

# we are somewhere below src/
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 
# source the util functions
source ${CWD%src*}/src/sh/utils/readconfig.bash


#
# Parse cmd line
#
CREATE_EXP_DIR=true
CREATE_FLOWCELL_DIR=true
HELP=false
OUTPUT_DIR=""
EID=""
while getopts efhi:o: option
do
 case "${option}"
 in
 e) CREATE_EXP_DIR=false;;
 f) CREATE_FLOWCELL_DIR=false;;
 i) EID=${OPTARG};;
 o) OUTPUT_DIR=${OPTARG};;
 h) HELP=true;;
 esac
done


if [ "$HELP" = true ]; then
	printhelp
	exit 0
fi


# reading simple values like the project directory organisation
PROJECT_DIR=$(readconfig global.projectpath)
FASTQ_DIR="${PROJECT_DIR}/$(readconfig global.fastqdir)"
EMBASE=$(readconfig tools.embase)

if [ -z $OUTPUT_DIR ]; then
	OUTPUT_DIR=$FASTQ_DIR
else
	checkorcreatedir $OUTPUT_DIR
fi

yell "INFO : embase fastq files will be sync'ed in :   $OUTPUT_DIR"
yell "INFO : create a sub-dir per experiment ?     :   ${CREATE_EXP_DIR}"
yell "INFO : create a sub-dir per flowcell/lane ?  :   ${CREATE_FLOWCELL_DIR}"


# loop over exp names
if [ -z $EID ]; then
	EXPNAMES=$(readconfigarr embase.expids)
else 
	EXPNAMES=$EID
fi
yell "INFO: will synch embase exp ids              :   ${EXPNAMES}"
for expid in $EXPNAMES 
do 
	propname="embase.expnames.${expid}"
	exp=$(readconfig ${propname})
	# exp might contain spaces ! quote it like "$exp"
	if [ -z "$exp" ] || [ "$exp" = "null" ]; then
		yell "WARN : NO EXP NAME DEFINED FOR EXP ID=$expid !"
		exp=$expid
	fi
	expdname=${exp// /_}
	yell "INFO : Synch'ing embase experiment $expdname ..."
	SYNC_DIR="${OUTPUT_DIR}"
	if [ "$CREATE_EXP_DIR" = true ]; then
		SYNC_DIR="${OUTPUT_DIR}/${expdname}"
		checkorcreatedir $SYNC_DIR
	fi
	cd $SYNC_DIR
	#fetch data and save in a local file
	EFNAME="${OUTPUT_DIR}/${expdname}.txt"
	# fetch RBA files
	$EMBASE fetch experiment -e $expid --split --cols Flowcell,Lane,RBAFastqFiles,LibraryName,Barcode,RBAID,RBAName,RBAQuality | \
	awk -v OFS=\\t ' $0!="" && $3 !="" {if(NR==1) print "IsLaneFile",$0 ; if(NR>1) print "No",$0 }' > $EFNAME
	# fetch lane files
	$EMBASE fetch experiment -e $expid -n --split --cols Flowcell,Lane,LaneFile1,LaneFile2 | \
	awk -v OFS=\\t 'NR>1 && $0!="" && $3 !="" {print "Yes",$1, $2, $3 ; if($4!="") print "Yes",$1, $2, $4 ;}' >> $EFNAME

	# make sure all needed subdirs exists
	if [ "$CREATE_FLOWCELL_DIR" = true ]; then
		try cut -f2,3 $EFNAME | grep -v "Flowcell" | sort -u | awk '{system("mkdir -p " $1"_"$2)}'
		try awk 'NR>1 && $4 !="" {system("ln -sf " $4 " "$2"_"$3"/")}' $EFNAME
	else
		# directly create the symlink where we are
		try awk 'NR>1 && $4 !="" {system("ln -sf " $4)}' $EFNAME
	fi
	yell "INFO : Synch'ing embase experiment $expdname ... done"
done







