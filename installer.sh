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
    local readonly INSTALL_STRING=$1
    local readonly CMD_NAME=$2
    local readonly CMD=$3
    local readonly PACKAGE_NAME=$4

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
    local readonly CMD_NAME=$1
    local readonly CMD=$2
    local readonly PACKAGE_NAME=$3
    install "pacman -Sy " "$CMD_NAME" "$CMD" "$PACKAGE_NAME"
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

    PACKAGE_MANAGER=$(get_package_manager)

    echo "Detected $PACKAGE_MANAGER"

    case $PACKAGE_MANAGER in

        ### Arch-Based
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

        ### Debian-Based
        "apt-get")
        # Dependency GO
        apt-get_install "go" "go help" "golang-go"
        # Dependency SSH
        apt-get_install "ssh" "which ssh" "openssh-client"
        # Dependency GIT
        apt-get_install "git" "git --version" "git"
	# Dependency jq
        apt-get_install "jq" "jq --help" "jq"
        # Depedency GETH
        #~ sudo apt-get install software-properties-common
        #~ sudo add-apt-repository -y ppa:ethereum/ethereum
        #~ sudo apt-get update
        #~ sudo apt-get -y install ethereum
        printf "Checking if geth is installed ... "
        geth version 1> /dev/null 2> /dev/null && printf "yes\n" || {
            # Make sure that curl is already installed. It is used to
            # get the latest RELEASE TAG
            apt-get_install "curl" "curl --help" "curl"

            LATEST_RELEASE_TAG=$(curl -L -s -H \
            'Accept: application/json'\
            https://github.com/ethereum/go-ethereum/releases/latest |\
            jq -r ".tag_name")
            git clone https://github.com/ethereum/go-ethereum.git \
            --branch $LATEST_RELEASE_TAG --single-branch
            cd go-ethereum/
            make geth
            sudo cp build/bin/geth /usr/local/bin/
        }
        ;;



        *) printf "Your package manager is not yet supported\n"
        exit 1;
        ;;
    esac

    printf "Done. All dependencies are now installed ...\n"
}

main $args


