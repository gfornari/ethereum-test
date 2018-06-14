#!/usr/bin/python

import json
import sys

def main(argv):
    config = {}
    config["timeout"] = argv[1]
    config["extra_timeout"] = int(argv[2])
    config["tx_interval"] = argv[3]
    config["test_dir"] = argv[4]
    config["start_difficulty"] = int(argv[5])
    login_name = argv[6]
    config["bootnode"] = argv[7]


    with open(argv[0], "r") as fd:
        ip_address_list = fd.readlines()
        node=[]
        for ip in ip_address_list:
            node.append({"address": ip.strip(), "login_name": login_name, "roles":["client"]})
    
    config["nodes"] = node
    with open(argv[8], "w") as out:
        json.dump(config, fp=out, indent=4)

if __name__ == '__main__':    
    
    if len(sys.argv) < 10:
        print("Usage: %s <ip_file> <test-time> <padding-time> <tx_interval> <test-output-dir> <start_difficulty> <login_name> <bootnode-enode> <output_file>" % sys.argv[0])
        sys.exit(0)
    main(sys.argv[1:])


