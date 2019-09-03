#
# Gives easy access to variable found in the config/config.yml file
# Wraps yq 

# load the function only once
[[ -n ${_readconfig:-} ]] && return
readonly _readconfig=loaded

# we require yq to function properly 
command -v yq >/dev/null 2>&1 || { echo >&2 "Tool yq is required but it's not installed (https://github.com/mikefarah/yq).  Aborting."; exit 1; }

_CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# we know we are somewhere in the src/ dir ; we split _CWD by 'src' and keep the leftmost part
_PROJECT_DIR=$(echo $_CWD | awk -Fsrc '{print $1}')
# build the config file path
_PROJECT_CONFIG_FILE="${_PROJECT_DIR}/config/config.yml"

# check the file is found and readable
if [ ! -r "$_PROJECT_CONFIG_FILE" ]
then
	echo >&2 "Configuration file not found or need read access: ${_PROJECT_CONFIG_FILE}.   Aborting."
	exit 1
fi

# read a config value by its fully qualified name e.g. section.name
readconfig () {
	command yq r ${_PROJECT_CONFIG_FILE} $1
}

# read a config param that is an array
readconfigarr () {
	ARR=$(readconfig $1)
	V=""
	for a in $ARR 
	do 
		if [ "$a" != "-" ]
		then
			V="${V} $a"
		fi
	done
	# make sure we have no leading and trailing spaces
	echo -e $V | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

