#! /usr/bin/env bash 

#
# Template script showing how to read the configuration file and how to access params
# 
#

# we are somewhere below src/
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 
# source the util functions
source ${CWD%src*}/src/sh/utils/readconfig.bash


##
# reading parameters from config file
##


cat << EndOfMessage
##
# Reading simple variables
##
EndOfMessage

# reading simple values like the project directory organisation
PROJECT_DIR=$(readconfig global.projectpath)
DATA_DIR="${PROJECT_DIR}/$(readconfig global.datadir)"
echo $DATA_DIR

# ...like executable to use 
BWA=$(readconfig tools.bwa)
echo $BWA

cat << EndOfMessage
##
# Reading ARRAYS
##
EndOfMessage
echo "reading arrays is easy as well ... readconfig example.anarray"
ARR=$(readconfig example.anarray)
echo "When reading arrays, the resulting array ARR contains 3 '-' on top of the expected 3 values : "
echo $ARR
echo "You can loop over the values directly "
for a in $ARR 
do 
	if [ "$a" == "-" ]
	then
		echo "you might want to skip this '-'"
	else
		echo $a
	fi
done

echo " or access the variable directly by position in the array with readconfig example.anarray.0 "
VAL=$(readconfig example.anarray.0)
echo $VAL

echo " finally note the special function for arrays : readconfigarr example.anarray"
ARR=$(readconfigarr example.anarray)
echo $ARR
echo "You can now directly loop over array values"
for a in $ARR 
do 
	echo $a
done

cat << EndOfMessage
##
# Reading DICT
##
EndOfMessage
echo "reading dictionary is easy as well ... readconfig example.ahash"
DICT=$(readconfig example.ahash)
echo "When reading a whole dict, the resulting array DICT is like : "
echo $DICT
echo "One can iterate over these values : "
for d in $DICT 
do
	echo $d
done

echo "but you certainly want to directly read the values by their key name i.e. readconfig example.ahash.name "
NAME=$(readconfig example.ahash.name)
echo $NAME