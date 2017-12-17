import os
import subprocess
import time
import sys
import errno
import json


prefix_port = 303
prefix_rpc_port = 81
genesis_block_url = 'http://genesisblock.altervista.org/genesis_block.json'

def create_dirs(remote_string_prefix, directory):
	subprocess.call((remote_string_prefix + " mkdir -p " + directory).split()) 

def download_genesis_block(remote_string_prefix, genesis_block_path):
	cmd1 = remote_string_prefix + " wget " + genesis_block_url + " -O " + genesis_block_path
	print(cmd1)
	subprocess.call(cmd1.split())

def initialize_blockchain(remote_string_prefix, data_dir, genesis_block_path):
	# Command to initialize the the blockchain with the genesis_block
	cmd2 = remote_string_prefix + ' geth --datadir=' + data_dir + ' init ' + genesis_block_path + " 2>> /dev/null "
	print(cmd2)
	subprocess.call(cmd2.split())

def start_node(remote_string_prefix, data_dir, port, rpc_port, network_id, rpcaddr, rpccorsdomain):
	# Command to start a geth client that uses our test blockchain
	cmd3 = remote_string_prefix + 'geth --datadir=' + data_dir + ' --ipcdisable ' + \
	'--port ' + port + ' --rpcport ' + \
	rpc_port + ' --rpc --rpcaddr ' + rpcaddr + ' --rpccorsdomain ' + rpccorsdomain + ' --rpcapi eth,web3,miner,net,admin' +\
	' --networkid=' + str(network_id) + '  --nodiscover'
	print (cmd3)
	subprocess.Popen(cmd3.split())


def main(argv):
	remote = False
	login_name = ""
	server_name = ""
	rpcaddr = "127.0.0.1"
	rpccorsdomain = "127.0.0.1"
	
	if len(argv) < 2:
		print("Usage: python %s <node_id> [login_name@server_name] [allowed_rpc_client_ip]" % (argv[0]))
	else:
		i = int(argv[1])
		if len(argv) > 2:
			a = argv[2].split("@")
			login_name = a[0]
			server_name = a[1]
			rpcaddr = a[1]
			remote = True
		if len(argv) > 3:
			rpccorsdomain = argv[3]
		
		print ("node " + str(i))
		remote_string_prefix = ""
		if remote:
			print("remote")
			login_name = "root"
			server_name = rpcaddr
			remote_string_prefix = "ssh " + argv[2] + " "
		
		port = "%d%02d" % (prefix_port, i)
		rpc_port = "%d%02d" % (prefix_rpc_port, i)
		data_dir = "/tmp/eth/" + str(i)
		tmp_data_dir = "/tmp/foo/" + str(i)
		genesis_block_path = 'genesis_block.json'
		genesis_block_path = tmp_data_dir + "/" + genesis_block_path
		try:
			create_dirs(remote_string_prefix, data_dir)
			create_dirs(remote_string_prefix, tmp_data_dir)
		except OSError as e:
			if e.errno != errno.EEXIST:
				raise  # raises the error again
		
		download_genesis_block(remote_string_prefix, genesis_block_path)
		
		
		initialize_blockchain(remote_string_prefix, data_dir, genesis_block_path)
		
		genesis_block = json.loads(subprocess.check_output((remote_string_prefix + " cat " + genesis_block_path).split()).decode('ascii'))
		network_id=genesis_block["config"]["chainId"]
		
		start_node(remote_string_prefix,data_dir, port, rpc_port, network_id, rpcaddr, rpccorsdomain)
		
		# TODO: Find a portable way to open a new terminal, for now we have
		# to comment/uncomment the following lines depending on the used
		# terminal
		# Konsole
		#os.system("konsole --new-tab -e bash -c '" + cmd + "'  ");
		# Ubuntu
		# os.system("gnome-terminal --tab -x bash -c '" + cmd + "' --"); 
	

if __name__ == "__main__":
    main(sys.argv)

