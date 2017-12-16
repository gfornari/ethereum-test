import os
import subprocess
import time
import sys
import errno



prefix_port = 303
prefix_rpc_port = 81
genesis_block_path = 'genesis_block.json'
genesis_block_url = 'http://genesisblock.altervista.org/genesis_block.json'





def main(argv):
	i = int(argv[1])
	port = "%d%02d" % (prefix_port, i)
	rpc_port = "%d%02d" % (prefix_rpc_port, i)
	data_dir = "/tmp/eth/" + str(i)
	tmp_data_dir = "/tmp/foo/" + str(i)
	genesis_block_path = 'genesis_block.json'
	
	try:
		os.makedirs(data_dir)
		os.makedirs(tmp_data_dir)
	except OSError as e:
		if e.errno != errno.EEXIST:
			raise  # raises the error again
	
	
	
	print ("node " + str(i))
	genesis_block_path = tmp_data_dir + "/" + genesis_block_path
	
	cmd1 = "wget " + genesis_block_url + " -O " + genesis_block_path 
	
	# ~ # Create the blockchain
	cmd2 = 'geth --datadir=' + data_dir + ' init ' + genesis_block_path + " 2>> /dev/null "
	print(cmd2)
	
	
	cmd3 = 'geth --datadir=' + data_dir + ' --ipcdisable ' + \
	'--port ' + port + ' --rpcport ' + \
	rpc_port + ' --rpc --rpccorsdomain 127.0.0.1 --rpcapi eth,web3,miner,net,admin' +\
	' --networkid=11691524842890 --nodiscover console'
	cmd = (cmd1 + " ; " + cmd2 + " ; " + cmd3)
	print(cmd)
	# TODO: Find a portable way to open a new terminal, for now we have
	# to comment/uncomment the following lines depending on the used
	# terminal
	# Konsole
	os.system("konsole --new-tab -e bash -c '" + cmd + "'  ");
	# Ubuntu
	# os.system("gnome-terminal --tab -x bash -c '" + cmd + "' --"); 
	

if __name__ == "__main__":
    main(sys.argv)

