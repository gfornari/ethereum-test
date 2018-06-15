#!/usr/bin/python

import json
import sys

def main(argv):
    client_ips_file=argv[0]
    miner_ips_file=argv[1]
    output_file=argv[9]

    config = {}
    config["timeout"] = argv[2]
    config["extra_timeout"] = int(argv[3])    
    config["tx_interval"] = argv[4]
    config["test_dir"] = argv[5]
    config["start_difficulty"] = int(argv[6])
    login_name = argv[7]
    config["bootnode"] = argv[8]
    client_per_machine=2
    miner_per_machine=1
    
    if len(argv) > 10:
        client_per_machine = int(argv[10])
    if len(argv) > 11:
        miner_per_machine = int(argv[11])
    
    nodes=[]
    
    with open(miner_ips_file, "r") as fd:
        ip_address_list = fd.readlines()
        for ip in ip_address_list:
            ip.strip() != "" # Avoid considering empty lines
            if ip.strip() != "": # Avoid considering empty lines
                roles = []
                for i in range(miner_per_machine):
                    roles.append("miner")
                nodes.append({"address": ip.strip(), "login_name": login_name, "roles":roles})

    with open(client_ips_file, "r") as fd:
        ip_address_list = fd.readlines()
        for ip in ip_address_list:
            if ip.strip() != "": # Avoid considering empty lines
                roles = []
                for i in range(client_per_machine):
                    roles.append("client")
                nodes.append({"address": ip.strip(), "login_name": login_name, "roles":roles})
            

            
    config["nodes"] = nodes
    with open(output_file, "w") as out:
        json.dump(config, fp=out, indent=4)

if __name__ == '__main__':    
    
    if len(sys.argv) < 10:
        print("Usage: %s <client_ip-file> <miner_ip-file> <test-time> <padding-time> \
            <tx_interval> <test-output-dir> <start_difficulty>\
            <login_name> <bootnode-enode> <output_file> \
            [number-of-client-per-machine] [number-of-miner-per-machine]" % sys.argv[0])
        sys.exit(0)
    main(sys.argv[1:])


