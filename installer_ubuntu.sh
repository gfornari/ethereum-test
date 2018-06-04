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


check_if_installed() {
    local readonly CMD_NAME=$1 # e.g. go
    local readonly CMD=$2 # e.g. go env > /dev/null
    printf "Checking if $CMD_NAME is installed ..."
    $CMD 1> /dev/null 2> /dev/null
    ret_val="$?"
    if [[ "$ret_val" -ne 0 ]]; then
        printf "no"
    else
        printf "yes"
    fi
    printf "\n"
    return ret_val
}

install() {
    local readonly INSTALL_STRING=$1
    local readonly CMD_NAME=$2
    local readonly CMD=$3
    local readonly PACKAGE_NAME=$4

    check_if_installed "$CMD_NAME"
    printf "Checking if $CMD_NAME is installed ... "
    $CMD 1> /dev/null 2> /dev/null && printf "yes\n" ||
    {
        printf "no\n"
        printf "Installing $CMD_NAME..\n"
        $INSTALL_STRING $PACKAGE_NAME 1> /dev/null 2> /dev/null ||
        {
            printf "Could not install $CMD_NAME\n"; exit 1;
        }
    }
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


    check_if_installed "go" "go env > /dev/null"

    if [[ "$?" -ne 0 ]]; then

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

        
        export GOROOT="/usr/local/go/"
        export GOPATH="${HOME}/go_path"
        export PATH="$PATH:${GOROOT}/bin:${GOPATH}/bin"

        echo "export GOROOT=${GOROOT}" >> ~/.bashrc
        echo "export GOPATH=${GO_PATH}" >> ~/.bashrc
        echo "export PATH=${PATH}" >> ~/.bashrc

        source ~/.bashrc
        # Checking if go is installed
        go env > /dev/null
        if [[ "$?" -ne "0" ]]; then
            printf "Go was not installed successfully ..."
            exit
        fi
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


