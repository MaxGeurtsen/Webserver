#!/usr/bin/env bash
# Max Geurtsen, 0922018

# Define global variable here

# TODO: Add required and additional packagenas dependecies
# for your implementation
declare -a packages=("unzip" "wget" "curl")

# TODO: define a function to handle errors
# This funtion accepts two parameters one as the error message and one as the command to be excecuted when error occurs.
function handle_error() {
    # Do not remove next line!
    echo "function handle_error"
   # TODO Display error and return an exit code
    echo "Error message: $1"
    if [ -n "$2" ]
    then
        echo "Executing command: $2"
        eval "$2"
    fi
    exit 1
}

# Function to solve dependencies
function setup() {
    # Do not remove next line!
    echo "function setup"

        if [[ -z "$INSTALL_DIR" || -z "$APP1_URL" || -z "$APP2_URL" ]]
        then
            handle_error "Invalid configuration settings in dev.conf."
        fi
        # TODO check if nessassary dependecies and folder structure exists and
        # print the outcome for each checking step
        for p in "${packages[@]}"
        do
            if ! command -v "$p" &> /dev/null
            then
                sudo apt install "$p"
                handle_error "$p is not installed."
            fi
        done

        if [ ! -d "$INSTALL_DIR" ]
        then
            handle_error "This directory does not exist. Creating $INSTALL_DIR." "mkdir -p "$INSTALL_DIR""
        fi
        # TODO installation from online package requires values for
        # package_name package_url install_dir

        # TODO check if required dependency is not already installed otherwise install it
        # if a a problem occur during the this process
        # use the function handle_error() to print a message and handle the error

        # TODO check if required folders and files exists before installations
        # For example: the folder ./apps/ and the file "dev.conf"

}

# Function to install a package from a URL
# TODO assign the required parameter needed for the logic
# complete the implementation of the following function.
function install_package() {
    # Do not remove next line!
    echo "function install_package"

    local package_name="$1"
    local package_url="$2"
    local install_dir="$3"

    if [ ! -d "$install_dir" ] || [ -z "$package_url" ]
    then
        handle_error "Invalid package url or installation directory for package: $package_name."
    fi

    local package_map="$install_dir/$package_name"
    if [ ! -d "$package_map" ]
    then
        handle_error "This directory does not exist. Creating $package_map" "mkdir -p "$package_map""
    fi
    # TODO The logic for downloading from a URL and unizpping the downloaded files of different applications must be generic
    echo "$package_name is downloading."
    if ! wget "$package_url" -O "$package_map/$package_name-master.zip"
    then
        handle_error "Downloading $package_name from $package_url has failed."
    fi

    echo "Unzipping $package_name."
    if ! unzip "$package_map/$package_name-master.zip" -d "$package_map"
    then
        if [ "pywebserver" == "$package_name" ]
        then
            rollback_pywebserver "$package_map"
        elif [ "nosecrets" == "$package_name" ]
        then
            rollback_nosecrets "$package_map"
        fi
        handle_error "Unzipping $package_name has failed."
    fi

    # TODO Specific actions that need to be taken for a specific application during this process should be handeld in a separate if-else

    if [ "pywebserver" == "$package_name" ]
    then
        sudo curl -L https://raw.githubusercontent.com/nickjj/webserver/master/webserver -o /usr/local/bin/webserver && sudo chmod +x /usr/local/bin/webserver

        echo "Installation pywebserver completed."
    elif [ "nosecrets" == "$package_name" ]
    then
        local -a nosecrets_tools=("git" "gcc" "make")
        for t in "${nosecrets_tools[@]}"
        do
            sudo apt install "$t"
            if ! command -v "$t" &> /dev/null
            then
                handle_error "$t is not installed."
            fi
        done

        cd "$package_map/no-more-secrets-master"

        if ! make nms
        then
            handle_error "Building No-More-Secrets failed."
        fi

        if ! make sneakers
        then
            handle_error "Building Sneakers failed." "make sneakers"
         fi

        if ! sudo make install
        then
            rollback_nosecrets "$package_map"
            handle_error "The installation of No-More-Secrets has failed." "sudo make install"
        fi

        echo "The installation of No-More-Secrets has completed."

    else
        if [ "pywebserver" == "$package_name" ]
        then
            rollback_pywebserver "$package_map"
        elif [ "nosecrets" == "$package_name" ]
        then
            rollback_nosecrets "$package_map"
        fi
        handle_error "$package_name is not supported."
    fi
    # TODO Every intermediate steps need to be handeld carefully. error handeling should be dealt with using handle_error() and/or rolleback()

    # TODO If a file is downloaded but cannot be zipped a rollback is needed to be able to start from scratch
    # for example: package names and urls that are needed are passed or extracted from the config file

    # TODO check if the application-folder and the url of the dependency exist
    # TODO create a specific installation folder for the current package

    # TODO Download and unzip the package
    # if a a problem occur during the this proces use the function handle_error() to print a messgage and handle the error

    # TODO extract the package to the installation folder and store it into a dedicated folder
    # If a problem occur during the this proces use the function handle_error() to print a messgage and handle the error

    # TODO this section can be used to implement application specifc logic
    # nosecrets might have additional commands that needs to be executed
    # make sure the user is allowed to remove this folder during uninstall

}

function rollback_nosecrets() {
    # Do not remove next line!
    echo "function rollback_nosecrets"

    local package_map="$1"
    # TODO rollback intermediate steps when installation fails
    if [ -d "$package_map" ]
    then
        sudo make uninstall -C "$package_map"
        sudo rm -f "$package_map"
    fi
}

function rollback_pywebserver() {
    # Do not remove next line!
    echo "function rollback_pywebserver"
    local package_map="$1"

        if [ -d "$package_map" ]
        then
            sudo make uninstall -C "$package_map"
            sudo rm -f "$package_map"
        fi
    # TODO rollback intermediate steps when installation fails
    sudo rm -f /usr/local/bin/webserver
}

function test_nosecrets() {
    # Do not remove next line!
    echo "function test_nosecrets"

    # TODO test nosecrets
    # kill this webserver process after it has finished its job
    if ! ls -l | nms
    then
        handle_error "Testing No-More-Secrets has failed."
        return 1
    fi
}

function test_pywebserver() {
    # Do not remove next line!
    echo "function test_pywebserver"    

    # Check if command webserver exists redirect all output to /dev/null and handle error
    if ! command -v webserver >/dev/null 2>&1; then
        handle_error "webserver is not installed"
    fi
    webserver "$WEBSERVER_IP:$WEBSERVER_PORT" &

    # Sleep so that the server can set up

    sleep 1

    # Send curl
    curl -i $WEBSERVER_IP:$WEBSERVER_PORT/ \
        -H "Content-Type: application/json" \
        -X POST --data @test.json
    # Get process id
    processId=$(pgrep -f "python3 /usr/local/bin/webserver")
    # Raise error if no id
    if [ ! -n $processId ]; then
        handle_error "Couldnt find process id"
    fi

    # kill
    kill $processId
}

function uninstall_nosecrets() {
    # Do not remove next line!
    echo "function uninstall_nosecrets"

    #TODO uninstall nosecrets application
    cd "$INSTALL_DIR/nosecrets"
    sudo make uninstall
}

function uninstall_pywebserver() {
    echo "function uninstall_pywebserver"
    #TODO uninstall pywebserver application
    if command -v webserver &> /dev/null
    then
        if ! sudo rm -f /usr/local/bin/webserver
        then
            handle_error "Failed to uninstall pywebserver."
        else
            echo "Uninstalled pywebserver."
        fi
    else
        handle_error "pywebserver is not installled."
    fi
}

#TODO removing installed dependency during setup() and restoring the folder structure to original state
function remove() {
    # Do not remove next line!
    echo "function remove"

    # Remove each package that was installed during setup
    if [ -d "$INSTALL_DIR" ]
    then
        for p in "${packages[@]}"
        do
            sudo apt-get remove "$p"
        done
        rollback_nosecrets "$INSTALL_DIR"
        rollback_pywebserver "$INSTALL_DIR"
    fi

    if ! rm -rf "$INSTALL_DIR"
    then
        echo "Unable to remove $INSTALL_DIR"
    else
        echo "Removed installation directory."
    fi
}

function main() {
    # Do not remove next line!
    echo "function main"

    # TODO
    # Read global variables from configfile
    source dev.conf

    # Get arguments from the commandline
    # Check if the first argument is valid
    # allowed values are "setup" "nosecrets" "pywebserver" "remove"
    # bash must exit if value does not match one of those values
    # Check if the second argument is provided on the command line
    # Check if the second argument is valid
    # allowed values are "--install" "--uninstall" "--test"
    # bash must exit if value does not match one of those values
    if [[ "$1" != "setup" && "$1" != "nosecrets" && "$1" != "pywebserver" && "$1" != "remove" ]]
    then
        echo "The first argument is invalid. Values that are allowed are: setup, nosecrets, pywebserver or remove."
        exit 1
    fi

    if [ -z "$2" ]
    then
        if [ "$1" == "setup" ]
        then
            setup "$INSTALL_DIR"
        elif  [ "$1" == "remove" ]
        then
            remove
        else
            echo "Second argument is missing to install, uninstall or test the packages."
            exit 1
        fi
    fi

    if [[ -z "$1" && "$2" != "--install" && "$2" != "--uninstall" && "$2" != "--test" ]]
    then
        echo "The second argument is invalid. Values that are allowed are: --install, --uninstall or --test."
        exit 1
    fi

    if [ "$2" == "--install" ]
    then
        if [ "$1" == "nosecrets" ]
        then
            install_package "nosecrets" "$APP1_URL" "$INSTALL_DIR"
        elif [ "$1" == "pywebserver" ]
        then
            install_package "pywebserver" "$APP2_URL" "$INSTALL_DIR"
        fi
    elif [ "$2" == "--uninstall" ]
    then
        if [ "$1" == "nosecrets" ]
        then
            uninstall_nosecrets
        elif [ "$1" == "pywebserver" ]
        then
            uninstall_pywebserver
        fi
    elif [ "$2" == "--test" ]
        then
            if [ "$1" == "nosecrets" ]
            then
                test_nosecrets
            elif [ "$1" == "pywebserver" ]
            then
                test_pywebserver
            fi
    fi
    # Execute the appropriate command based on the arguments
    # TODO In case of setup
    # excute the function check_dependency and provide necessary arguments
    # expected arguments are the installation directory specified in dev.conf

}

# Pass commandline arguments to function main
main "$@"
