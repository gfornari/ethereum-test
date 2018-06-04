#!/bin/bash



# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

main() {    
    # start a new docker swarm, read the output as an array
    a=$(docker swarm init)
    if [[ "$?" -ne 0 ]]; then
        printf "Probably, a docker swarm is already running. Please stop it. docker swarm leave --force\n"
        exit 1;
    fi
    arr=($a)

    # take the command from the output. It should be run in each machine
    local readonly command="${arr[20]} ${arr[21]} ${arr[22]} ${arr[23]} ${arr[24]} ${arr[25]}"

    echo $command
}

main $ARGS

