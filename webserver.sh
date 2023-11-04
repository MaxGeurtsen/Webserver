#!/usr/bin/env bash

# Define global variable here
INSTALL_DIR="./apps"
CONFIG_FILE="dev.conf"
TEST_FILE="test.json"
NOSECRETS_URL="https://github.com/bartobri/no-more-secrets"
PYWEBSERVER_URL="https://github.com/nickjj/webserver#installation"

# TODO: Add required and additional packagenas dependecies 
# for your implementation
# declare -a packages=()

# TODO: define a function to handle errors
# This funtion accepts two parameters one as the error message and one as the command to be excecuted when error occurs.
function handle_error() {
    # Do not remove next line!
    echo "function handle_error"

   # TODO Display error and return an exit code
    local error_message="$1"
    local error_command="$2"
    echo "Error: $error_message"
    if [ -n "$error_command" ]; then
        eval "$error_command"
    fi
    exit 1
}
 
# Function to solve dependencies
function setup() {
    # Do not remove next line!
    echo "function setup"


    # TODO check if nessassary dependecies and folder structure exists and 
    # print the outcome for each checking step
    if ! command -v unzip > /dev/null || ! command -v wget > /dev/null || ! command -v curl > /dev/null; then
        handle_error "System dependencies missing. Please install 'unzip', 'wget', and 'curl'." "--install"
    fi

    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
        touch "$CONFIG_FILE"
    fi
}

# Function to install a package from a URL
# TODO assign the required parameter needed for the logic
# complete the implementation of the following function.
function install_package() {
    # Do not remove next line!
    echo "function install_package"

    # TODO The logic for downloading from a URL and unizpping the downloaded files of different applications must be generic
    local package_name="$1" 
    local package_url="$2"    
    local install_dir="$3"    

    echo "Installing $package_name from $package_url to $install_dir..."
    # TODO Specific actions that need to be taken for a specific application during this process should be handeld in a separate if-else
    # TODO Every intermediate steps need to be handeld carefully. error handeling should be dealt with using handle_error() and/or rolleback()
    # TODO check if the application-folder and the url of the dependency exist
    # TODO create a specific installation folder for the current package
    # Check dir
    if [ ! -d "$install_dir" ]; then
        mkdir -p "$install_dir"
    fi

    # Check if installed
    if [ -d "$install_dir/$package_name" ]; then
        handle_error "$package_name already installed"
    fi
    # TODO If a file is downloaded but cannot be zipped a rollback is needed to be able to start from scratch
    # for example: package names and urls that are needed are passed or extracted from the config file



    # TODO Download and unzip the package
    # if a a problem occur during the this proces use the function handle_error() to print a messgage and handle the error

    # donwnload 
    wget -q "$package_url" -P "$install_dir"
    if [ $? -ne 0 ]; then
        handle_error "Failed to download $package_name." "rm -rf $install_dir/$package_name"
    fi

    # TODO extract the package to the installation folder and store it into a dedicated folder
    # If a problem occur during the this proces use the function handle_error() to print a messgage and handle the error

    # package to dir
    unzip -q "$install_dir/$(basename $package_url)" -d "$install_dir"
    if [ $? -ne 0 ]; then
        handle_error "Failed to unzip $package_name." "rm -rf $install_dir/$package_name"
    fi

    # TODO this section can be used to implement application specifc logic
    # nosecrets might have additional commands that needs to be executed
    # make sure the user is allowed to remove this folder during uninstall

    # install nosecrets
    if [ "$package_name" == "nosecrets" ]; then
        cd "$install_dir"
        make nnms
        make sneakers
        sudo make install
    # install pywebserver
    elif [ "$package_name" == "pywebserver" ]; then
        
        sudo curl \
        -L https://raw.githubusercontent.com/nickjj/webserver/v0.2.0/webserver \
        -o $install_dir && sudo chmod +x $install_dir
        
    else
        echo "No specific installation steps defined for $package_name."
    fi



function rollback_nosecrets() {
    # Do not remove next line!
    echo "function rollback_nosecrets"

    # TODO rollback intermiediate steps when installation fails
    rm "$INSTALL_DIR/nosecrets"
}

function rollback_pywebserver() {
    # Do not remove next line!
    echo "function rollback_pywebserver"

    # TODO rollback intermiediate steps when installation fails
    rm "$INSTALL_DIR/pywebserver"
}

function test_nosecrets() {
    # Do not remove next line!
    echo "function test_nosecrets"

    # TODO test nosecrets
    ls -l nms
    # kill this webserver process after it has finished its job

}

function test_pywebserver() {
    # Do not remove next line!
    echo "function test_pywebserver"    

    # TODO test the webserver
    # server and port number must be extracted from config.conf
    local server=$(grep 'WEBSERVER_IP' config.conf | awk -F' = ' '{print $2}')
    local port=$(grep 'WEBSERVER_PORT' config.conf | awk -F' = ' '{print $2}')
    # test data must be read from test.json 
    test_data=$(jq '.' test.json)
    # kill this webserver process after it has finished its job

}

function uninstall_nosecrets() {
    # Do not remove next line!
    echo "function uninstall_nosecrets"  

    #TODO uninstall nosecrets application
    sudo make uninstall
}

function uninstall_pywebserver() {
    echo "function uninstall_pywebserver"    
    #TODO uninstall pywebserver application
}

#TODO removing installed dependency during setup() and restoring the folder structure to original state
function remove() {
    # Do not remove next line!
    echo "function remove"

    if [ -d "$INSTALL_DIR" ]; then
        rmdir -p "$INSTALL_DIR"
    fi
    uninstall_nosecrets
    uninstall_pywebserver

}

function check_dependency() {
    local install_dir="$1"
    INSTALL_DIR=install_dir
}

function main() {
    # Do not remove next line!
    echo "function main"

    # TODO
    # Read global variables from configfile

    # Get arguments from the commandline
    # Check if the first argument is valid
    # allowed values are "setup" "nosecrets" "pywebserver" "remove"
    # bash must exit if value does not match one of those values
    # Check if the second argument is provided on the command line
    # Check if the second argument is valid
    # allowed values are "--install" "--uninstall" "--test"
    # bash must exit if value does not match one of those values

    # Execute the appropriate command based on the arguments
    # TODO In case of setup
    # excute the function check_dependency and provide necessary arguments
    # expected arguments are the installation directory specified in dev.conf
    if [ "$1" == "setup" ]; then
        setup
        install_dir=$(grep 'install_dir' dev.conf | awk -F= '{print $2}' | tr -d ' ')
        check_dependency "$install_dir"
    elif [ "$1" == "nosecrets" ]; then
        if [ "$2" == "--install" ]; then
            install_package "Nosecrets" "$NOSECRETS_URL" "$INSTALL_DIR/nosecrets"
        elif [ "$2" == "--test" ]; then
            test_nosecrets
        elif [ "$2" == "--uninstall" ]; then
            uninstall_nosecrets
        else
            handle_error "incorrect arguments"
        fi
    elif [ "$1" == "pywebserver" ]; then
        if [ "$2" == "--install" ]; then
            install_package "Pywebserver" "$PYWEBSERVER_URL" "$INSTALL_DIR/pywebserver"
        elif [ "$2" == "--test" ]; then
            test_pywebserver
        elif [ "$2" == "--uninstall" ]; then
            uninstall_pywebserver
        else
            handle_error "incorrect arguments"
        fi
    elif [ "$1" == "remove" ]; then
        remove
    else
        handle_error "incorrect arguments"
    fi
}

# Pass commandline arguments to function main
main "$@"
}
