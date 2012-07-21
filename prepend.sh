#!/bin/bash

if [ $# -lt 2 ] ; then
    echo "usage: $0 <header_file> <list of files to prepend header to>"
    exit 1
fi

header=$1; shift

file=$1; shift
while [ ! -z $file ] ; do
    mv $file "$file.temp"
    cat $header "$file.temp" > $file
    rm "$file.temp"
    file=$1; shift
done