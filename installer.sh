#!/bin/bash
# This script checks if the dependencies are installed.
# Supported Linux distros: debian-based/arch-based
#
# Dependencies:
# GO SSHD GIT GETH


#
# Check if the script has root permissions
#
check_if_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
    fi
}



KNOWN_PACKAGE_MANAGERS=(apt-get pacman)


#
# Detect the installed package manager
#
get_package_manager() {
    for PROGRAM in ${KNOWN_PACKAGE_MANAGERS[@]}; do
        $PROGRAM --help 1> /dev/null 2> /dev/null
        if [ "$?" -ne "127" ]; then
            echo $PROGRAM
            return
        fi
    done
    echo ""
}

install() {
    INSTALL_STRING=$1
    CMD_NAME=$2
    CMD=$3
    PACKAGE_NAME=$4

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
# INSTALL WITH PACMAN
#
pacman_install() {
    CMD_NAME=$1
    CMD=$2
    PACKAGE_NAME=$3
    install "pacman -Sy " "$CMD_NAME" "$CMD" "$PACKAGE_NAME"
}

#
# INSTALL WITH APT-GET
#
apt-get_install() {
    CMD_NAME=$1
    CMD=$2
    PACKAGE_NAME=$3
    install "apt-get install " "$CMD_NAME" "$CMD" "$PACKAGE_NAME"
}



check_if_root

SUCCESS=0
PACKAGE_MANAGER=$(get_package_manager)

echo "Detected $PACKAGE_MANAGER"


case $PACKAGE_MANAGER in

    "pacman")
    # Dependency GO
    pacman_install "go" "go help" "go"
    # Dependency SSHD
    pacman_install "sshd" "which sshd" "openssh"
    # Dependency git
    pacman_install "git" "git --version" "git"
    # Dependency GETH
    pacman_install "geth" "geth --help" "geth"
    # Dependency jq
    pacman_install "jq" "jq --help" "jq"
    ;;
    "apt-get")
    # Dependency GO
    apt-get_install "go" "go help" "golang-go"
    # Dependency SSH
    apt-get_install "ssh" "which ssh" "openssh-client"
    # Dependency GIT
    apt-get_install "git" "git --version" "git"
    # Depedency GETH
    sudo apt-get install software-properties-common
    sudo add-apt-repository -y ppa:ethereum/ethereum
    sudo apt-get update
    sudo apt-get install ethereum
    # Dependency jq
    apt-get_install "jq" "jq --help" "jq"
    ;;
    *) echo "Not yet supported"
    ;;
esac




