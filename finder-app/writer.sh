#!/bin/bash

writefile="$1"
writestr="$2"

if [ -z "$1" ] || [ -z "$2" ]; then
	echo "ERROR: missing arguments"
	exit 1
fi

mkdir -p "$(dirname "$writefile")" && echo "$writestr" > "$writefile" || {
	echo "ERROR: failed to create file"
	exit 1
} 
