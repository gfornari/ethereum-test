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
    
    while [[ true ]]; do
        timestamp=$(date +%s)
        out=$(ps -p $pid -o %cpu,%mem --no-header)
        out_array=($out)
        tmp_out=$(top -b -n 1 -p $pid | tail-1)
        tmp_out_array=($tmp_out)
        echo "$timestamp, ${out_array[0]}, ${out_array[1]}, \
        ${tmp_out_array[2]}, ${tmp_out_array[3]}" >> $output_file
        
        sleep 1
    done
}

main $ARGS

