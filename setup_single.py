import subprocess
import sys
import errno
import json


PREFIX_PORT = 303
PREFIX_RPC_PORT = 81
GENESIS_BLOCK_URL = 'http://genesisblock.altervista.org/genesis_block.json'

def create_dirs(remote_string_prefix, directory):
    print("Create dir: %s" % (directory))
    subprocess.call((remote_string_prefix + " mkdir -p " + directory).split())

def download_genesis_block(remote_string_prefix, genesis_block_path):
    cmd = remote_string_prefix + " wget " + GENESIS_BLOCK_URL + " -O " + genesis_block_path
    print(cmd)
    subprocess.call(cmd.split())

def initialize_blockchain(remote_string_prefix, data_dir, genesis_block_path):
    # Command to initialize the the blockchain with the genesis_block
    cmd = remote_string_prefix + ' geth --datadir=' + data_dir +\
    ' init ' + genesis_block_path + " 2>> /dev/null "
    print(cmd)
    subprocess.call(cmd.split())

def start_node(remote_string_prefix, data_dir, port, rpc_port, network_id, rpcaddr, rpccorsdomain, bootnode):
    # Command to start a geth client that uses our test blockchain
    cmd = remote_string_prefix + 'geth --datadir=' + data_dir + ' --ipcdisable ' + \
    '--port ' + port + ' --rpcport ' + \
    rpc_port + ' --rpc --rpcaddr ' + rpcaddr + ' --rpccorsdomain ' +\
    rpccorsdomain + ' --rpcapi eth,web3,miner,net,admin,personal' +\
    ' --networkid=' + str(network_id) + '  --bootnodes ' + bootnode + ' --'
    print(cmd)
    subprocess.Popen(cmd.split())


def main(argv):
    remote = False
    login_name = ""
    server_name = ""
    rpcaddr = "127.0.0.1"
    rpccorsdomain = "127.0.0.1"
    bootnode = ""
    if len(argv) < 2:
        print("Usage: python %s <node_id> <bootnode> [login_name@server_name]" +\
        "[allowed_rpc_client_ip]" % (argv[0]))
    else:
        print(argv[1])
        i = int(argv[1])
        bootnode = argv[2]
        
        print("This is a : " + bootnode)
        if len(argv) > 4:
            tmp = argv[3].split("@")
            login_name = tmp[0]
            server_name = tmp[1]
            rpcaddr = tmp[1]
            remote = True
            if login_name == "":
                remote = False
        if len(argv) > 5:
            rpccorsdomain = argv[4]
            print(rpccorsdomain)

        remote_string_prefix = ""
        if remote:
            remote_string_prefix = "ssh " + argv[2] + " "

        port = "%d%02d" % (PREFIX_PORT, i)
        rpc_port = "%d%02d" % (PREFIX_RPC_PORT, i)
        data_dir = "/tmp/eth/" + str(i)
        tmp_data_dir = "/tmp/foo/" + str(i)
        genesis_block_path = 'genesis_block.json'
        genesis_block_path = tmp_data_dir + "/" + genesis_block_path
        try:
            create_dirs(remote_string_prefix, data_dir)
            create_dirs(remote_string_prefix, tmp_data_dir)
        except OSError as exc:
            if exc.errno != errno.EEXIST:
                raise  # raises the error again

        download_genesis_block(remote_string_prefix, genesis_block_path)


        initialize_blockchain(remote_string_prefix, data_dir, genesis_block_path)

        genesis_block = json.loads(subprocess.check_output(\
        (remote_string_prefix + " cat " + genesis_block_path).\
        split()).decode('ascii'))

        network_id = genesis_block["config"]["chainId"]

        start_node(remote_string_prefix, data_dir, port, rpc_port,\
        network_id, rpcaddr, rpccorsdomain, bootnode)

        # TODO: Find a portable way to open a new terminal, for now we have
        # to comment/uncomment the following lines depending on the used
        # terminal
        # Konsole
        #os.system("konsole --new-tab -e bash -c '" + cmd + "'  ");
        # Ubuntu
        # os.system("gnome-terminal --tab -x bash -c '" + cmd + "' --");


if __name__ == "__main__":
    main(sys.argv)
