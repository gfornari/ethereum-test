#!/bin/bash
# This script checks if the dependencies are installed.
# Supported Linux distros: debian-based/arch-based
#
# Dependencies:
# GO SSHD GIT GETH


# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

#
# Check if the script has root permissions
#
check_if_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
    fi
}



#
# INSTALL WITH APT-GET
#
apt-get_install() {
    local readonly CMD_NAME=$1
    local readonly CMD=$2
    local readonly PACKAGE_NAME=$3
    install "apt-get install -y " "$CMD_NAME" "$CMD" "$PACKAGE_NAME"
}


main() {
    check_if_root
    architecture=$(uname -m)
    
    
    archive_name=""
    if [[ "$architecture" == "x86_64" ]]; then
        archive_name=go1.10.linux-amd64.tar.gz
       
    else
        printf "Architecture '$architecture' currently not supported..."
        exit
    fi

    archive_url=archive_name=go1.10.linux-amd64.tar.gz
    wget https://storage.googleapis.com/golang/go1.10.linux-amd64.tar.gz
    tar -C /usr/local -xzf "$archive_name"

    echo "export PATH=$PATH:/usr/local/go/bin:${HOME}/go/bin" >> ~/.bashrc

    source ~/.bashrc
    # Checking if go is installed
    go env > /dev/null
    if [[ "$?" -ne "0" ]]; then
        printf "Go was not installed successfully ..."
        exit
    fi
    
    
    apt-get update
    
    # Dependency SSHD
    apt-get_install "sshd" "which sshd" "openssh"
    # Dependency git
    apt-get_install "git" "git --version" "git"
    # Dependency jq
    apt-get_install "jq" "jq --help" "jq"
    
    go get -d github.com/ethereum/go-ethereum
    go install github.com/ethereum/go-ethereum/cmd/geth
    
    
    printf "Done. All dependencies are now installed ...\n"
}

main $args


