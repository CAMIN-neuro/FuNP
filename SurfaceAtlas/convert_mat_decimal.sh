#!/bin/bash

# Read from specified file, or from standard input
infile="$1"
#split=$(echo $infile | tr "." "\n")
#name=$(printf $split)

results=()
while read line; do

    j=()
    for number in $line; do
#        printf "%f " "$number"
        j+=$(printf "%f\t" "$number")
    done
    echo $j
#    echo $j >> "$name"_conv.mat
    echo $j >> "$infile"_conv
done < $infile
