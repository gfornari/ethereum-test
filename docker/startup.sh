#!/bin/bash



# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"


#
# Given the configuration information of a single machine executes the
# script on the machine passing the right arguments
#
add_machine_to_docker_swarm() {
    local login_name=$1
    local address=$2
    local num_client=$3
    local start_id=$4
    local bootnode_address=$5
    local cmd=$6
    
   
    
    
    
    if [[ "$address" == "127.0.0.1" ]] || [[ "$address" == "localhost" ]] || [[ "$address" == "$IP_ADDRESS" ]]; then
        printf "local\n\n\n"
        printf "Nothing to do here"
    else
        echo $cmd | ssh "$login_name@$address" "bash -s"
    fi

}


main() { 
    if [[ "$#" -lt "1" ]]; then
        printf "Usage %s <conf-file>\n" $0
        exit 1;
    fi
    
    # start a new docker swarm, read the output as an array
    a=$(docker swarm init)
    if [[ "$?" -ne 0 ]]; then
        printf "Probably, a docker swarm is already running. Please stop it.\n"
        exit 1;
    fi
    arr=($a)

    # take the command from the output. It should be run in each machine
    local readonly command="${arr[20]} ${arr[21]} ${arr[22]} ${arr[23]} ${arr[24]} ${arr[25]}"

    echo $command
    
    #~ local readonly CONF_FILE=$1
    

    #~ #FOR_EACH COMPUTER IN TEST_CONF
    #~ local computer_id=0
    #~ local start_node_id=0
    #~ local computer=""
    #~ while [ true ]; do
        #~ computer=$(jq -r ".nodes[$computer_id]" $CONF_FILE)
        #~ if [ "$computer" == "null" ]; then
            #~ break;
        #~ fi
        #~ tmp_file=/tmp/tmp.json
        #~ echo $computer > $tmp_file
        #~ login_name=$(jq -r ".login_name" $tmp_file)
        #~ address=$(jq -r ".address" $tmp_file)
        
        #~ add_machine_to_docker_swarm "$login_name" "$address" "$num_client" "$start_node_id" "$ENODE_ADDRESS" "$command"
        
        #~ computer_id=$((computer_id+1))
    #~ done
    #~ #END FOR_EACH
    
    #~ docker service create --mode global --name helloworld ethereum/client-go -p 8545:8545 -p 30303:30303 ethereum/client-go --rpc --rpcaddr "127.0.0.1"
    #~ echo "done.."
}

main $ARGS

