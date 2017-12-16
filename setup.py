import os
import subprocess
import time

client_number = 2;
prefix_port = 3030
prefix_rpc_port = 810
genesis_block_path = 'genesis_block.json'
genesis_block_url = 'http://genesisblock.altervista.org/genesis_block.json'


def start_nodes():
	node_ids_string = ""
	for i in range(0, client_number):
		node_ids_string += str(i) + " " 
	print(node_ids_string)
	cmd = "parallel python setup_single.py ::: " + node_ids_string
	print (cmd)
	print (cmd.split())
	subprocess.Popen(cmd.split())


def retrieve_enodes():
	enodes = [0] * client_number
	for i in range(0, client_number):
		cmd = "geth --datadir=/tmp/eth/" + str(i) + " attach http://127.0.0.1:810" + str(i) + " --exec admin.nodeInfo.enode"
		enodes[i] = subprocess.check_output(cmd.split( ))
		enodes[i] = enodes[i].decode('ascii').split()[0]
		print(enodes[i])
	return enodes

def add_peers(enodes):
	for i in range(0, client_number):
		for j in range(0, client_number):
			if i != j:
				print(enodes[j])
				cmd = "geth --datadir=/tmp/eth/" + str(i) + " attach http://127.0.0.1:810" + str(i) + " --exec admin.addPeer(" + enodes[j] + ")"
				subprocess.call(cmd.split())
				print(cmd)




def main():
	start_nodes()
	# TODO: Wait untils services are up and running. sleep should be 
	# only a temporary solution
	sleep_time = 3
	time.sleep(sleep_time)
	print(str(sleep_time) + " seconds elapsed")
	
	#Fetching the enodes of the 
	enodes = retrieve_enodes()
	add_peers(enodes)
	

if __name__ == "__main__":
    main(sys.argv)

