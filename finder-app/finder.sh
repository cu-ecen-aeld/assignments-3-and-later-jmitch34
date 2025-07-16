#!/bin/bash



#exit with value 1 error and print statements if any of the parameters above are empty
if [ -z "$1" ] || [ -z "$2" ]; then
	echo "ERROR: Missing arguments"
	exit 1
fi

filesdir="$1"
searchstr="$2"

#exits with values 1 error and print statements if filesdir does not represent a directo
# on the filesystem. 

if [ -d "$filesdir" ]; then
	echo "Directory: $1 exists"
else
	echo "ERROR: $1 is not a valid directory"
	exit 1
fi


#print message "the number of files are X and the number of matching lines are Y"
# X is thge number of files in the directory and all its subdirectories and Y is
#the number of matching lines found in respective files

X=$(find "$filesdir" -type f | wc -l)

Y=$(grep -rI "$searchstr" "$filesdir" | wc -l)

echo "The number of files are $X and the number of matching lines are $Y"
