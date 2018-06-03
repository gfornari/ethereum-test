#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

main() {
    if [[ "$#" -lt "2" ]]; then
        printf "Usage %s <pid> <output_file>\n" $0
        exit 1;
    fi
    pid=$1
    output_file=$2
    
    # Create file
    rm $output_file
    touch $output_file
    
    while [[ true ]]; do
        date +%s >> $output_file
        ps -p $pid -o %cpu,%mem | sed 1d >> $output_file
        sleep 1
    done
}

main $ARGS
