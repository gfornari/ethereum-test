#!/usr/bin/python

import json
import sys

def main(argv):
    client_ips_file=argv[0]
    miner_ips_file=argv[1]
    output_file=argv[10]

    config = {}
    config["timeout"] = argv[2]
    config["extra_timeout"] = int(argv[3])    
    config["tx_interval"] = argv[4]
    config["test_dir"] = argv[5]
    config["start_difficulty"] = int(argv[6])
    login_name = argv[7]
    config["bootnode"] = argv[8]
    config["gasLimit"] = int(argv[9])
    config["genesis_file"] = "conf/genesis_block.json"
    client_per_machine=2
    miner_per_machine=1
    
    if len(argv) > 11:
        client_per_machine = int(argv[11])
    if len(argv) > 12:
        miner_per_machine = int(argv[12])
    
    
    nodes=[]
    
    with open(miner_ips_file, "r") as fd:
        ip_address_list = [ip.strip() for ip in fd.readlines() if ip.strip() != ""]
        number_of_miner_machines = len(ip_address_list)
        if len(argv) > 14:
            tmp = int(argv[14])
            if tmp > number_of_miner_machines:
                print("Warning number of miner machines exceed ips in " + miner_ips_file + " . Exit ...")
                sys.exit(1)
            number_of_miner_machines = tmp

            
           
        for i in range(number_of_miner_machines):
            ip = ip_address_list[i]
            roles = []
            for i in range(miner_per_machine):
                roles.append("miner")
            nodes.append({"address": ip.strip(), "login_name": login_name, "roles":roles})

    with open(client_ips_file, "r") as fd:
        ip_address_list = [ip.strip() for ip in fd.readlines() if ip.strip() != ""]
        number_of_client_machines = len(ip_address_list)
        if len(argv) > 13:
                tmp = int(argv[13])
                if tmp > number_of_client_machines:
                    print("Warning number of client machines exceed ips in " + client_ips_file + " . Exit ...")
                    sys.exit(1)
                number_of_miner_machines = tmp
        for i in range(number_of_client_machines):
            ip = ip_address_list[i]
            roles = []
            for i in range(client_per_machine):
                roles.append("client")
            nodes.append({"address": ip.strip(), "login_name": login_name, "roles":roles})
    
    if len(argv) > 15:
        config["genesis_file"] = argv[15]

            
    config["nodes"] = nodes
    with open(output_file, "w") as out:
        json.dump(config, fp=out, indent=4)

if __name__ == '__main__':    
    
    if len(sys.argv) < 12:
        print("Usage: %s <client_ip-file> <miner_ip-file> <test-time> <padding-time> \
            <tx_interval> <test-output-dir> <start_difficulty>\
            <login_name> <bootnode-enode> <gas_limit> <output_file> \
            [number-of-clients-per-machine] [number-of-miners-per-machine] \
            [number of client machines] [number of mining machines] \
            [genesis_file]" % sys.argv[0])
        sys.exit(0)
    main(sys.argv[1:])


