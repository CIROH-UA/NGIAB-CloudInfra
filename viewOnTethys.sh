#!/bin/bash
# ANSI color codes
BRed='\033[1;31m'
BGreen='\033[1;32m'
BYellow='\033[1;33m'
BBlue='\033[1;34m'
BPurple='\033[1;35m'
BCyan='\033[1;36m'
BWhite='\033[1;37m'
UBlack='\033[4;30m'
URed='\033[4;31m'
UGreen='\033[4;32m'
UYellow='\033[4;33m'
UBlue='\033[4;34m'
UPurple='\033[4;35m'
UCyan='\033[4;36m'
UWhite='\033[4;37m'


################################################
###############HELPER FUNCTIONS#################
################################################

# Function to automatically select file if only one is found
_auto_select_file() {
  local files=("$@")  # Correct the handling of arguments as an array
  if [ "${#files[@]}" -eq 1 ]; then
    echo "${files[0]}"
  else
    echo ""
  fi
}
_check_if_data_folder_exits(){
    # Check the directory exists
    if [ ! -d "$DATA_FOLDER_PATH" ]; then
        echo -e "${BRed}Directory does not exist. Exiting the program.${Color_Off}"
        exit 0
    fi
}

# Check if the config file exists and read from it
_check_and_read_config() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        local last_path=$(cat "$config_file")
        echo -e "Last used data directory path: %s\n" "$last_path"
        read -erp "Do you want to use the same path? (Y/n): " use_last_path
        if [[ "$use_last_path" =~ ^[Yy] ]]; then
            DATA_FOLDER_PATH="$last_path"
            _check_if_data_folder_exits
            return 0
        elif [[ "$use_last_path" =~ ^[Nn] ]]; then
            read -erp "Enter your input data directory path (use absolute path): " DATA_FOLDER_PATH
            _check_if_data_folder_exits
            # Save the new path to the config file
            echo "$DATA_FOLDER_PATH" > "$CONFIG_FILE"
            echo -e "The Directory you've given is:\n$DATA_FOLDER_PATH\n"   
        else
            echo -e "Invalid input. Exiting.\n" >&2
            return 1
        fi
    fi
}

_execute_command() {
  "$@"
  local status=$?
  if [ $status -ne 0 ]; then
    echo -e "${BRed}Error executing command: $1${Color_Off}"
    _tear_down
    exit 1
  fi
  return $status
}

_tear_down(){
    _tear_down_tethys
    docker network rm $DOCKER_NETWORK > /dev/null 2>&1
}

_run_containers(){
    _run_tethys
}

# Wait for a Docker container to become healthy or unhealthy
_wait_container() {
    local container_name=$1
    local container_health_status
    local attempt_counter=0

    echo -e "${UPurple}Waiting for container: $container_name to start, this can take a couple of minutes...${Color_Off}\n"

    until [[ "$container_health_status" == "healthy" || "$container_health_status" == "unhealthy" ]]; do
        # Update the health status
        if ! container_health_status=$(docker inspect -f '{{.State.Health.Status}}' "$container_name" 2>/dev/null); then
            echo -e "${BRed}Failed to get health status for container $container_name. Ensure container exists and has a health check.${Color_Off}\n" >&2
            return 1
        fi

        if [[ -z "$container_health_status" ]]; then
            echo -e "${BRed}No health status available for container $container_name. Ensure the container has a health check configured.${Color_Off}\n" >&2
            return 1
        fi

        ((attempt_counter++))
        sleep 2  # Adjusted sleep time to 2 seconds to reduce system load
    done

    echo -e "${BCyan}Container $container_name is now $container_health_status.${Color_Off}\n"
    return 0
}

_pause_script_execution() {
    while true; do
        echo -e "${BYellow}Press q to exit the visualization (default: q/Q):${Color_Off}\n"
        read -r exit_choice

        if [[ "$exit_choice" =~ ^[qQ]$ ]]; then
            echo -e "${BRed}Cleaning up Tethys ...${Color_Off}\n"
            _tear_down
            exit 0
        else
            echo -e "${BRed}Invalid input. Please press 'q' or 'Q' to exit.${Color_Off}\n"
        fi
    done
}

# Function to handle the SIGINT (Ctrl-C)
handle_sigint() {
    echo -e "${BRed}Cleaning up . . .${Color_Off}"
    _tear_down
    exit 1
}

check_last_path() {
    if [[ -z "$1" ]]; then
        _check_and_read_config "$CONFIG_FILE"
     
    else
        DATA_FOLDER_PATH="$1"
    fi
    # Finding files
    
    HYDRO_FABRIC=$(find "$DATA_FOLDER_PATH/config" -iname "*.gpkg")
    CATCHMENT_FILE=$(find "$DATA_FOLDER_PATH/config" -iname "catchments.geojson")
    NEXUS_FILE=$(find "$DATA_FOLDER_PATH/config" -iname "nexus.geojson")
    FLOWPATHTS_FILE=$(find "$DATA_FOLDER_PATH/config" -iname "flowpaths.geojson")
}
_get_filename() {
  local full_path="$1"
  local filename="${full_path##*/}"
  echo "$filename"
}


################################################
###############TETHYS FUNCTIONS#################
################################################

#create the docker network to communicate between tethys and geoserver
_create_tethys_docker_network(){
    _execute_command docker network create -d bridge tethys-network > /dev/null 2>&1
}

# Link the data to the app workspace
_link_data_to_app_workspace(){
    _execute_command docker exec -it $TETHYS_CONTAINER_NAME sh -c \
        "mkdir -p $APP_WORKSPACE_PATH && \
        ln -s $TETHYS_PERSIST_PATH/ngen-data $APP_WORKSPACE_PATH/ngen-data"
}


_check_for_existing_tethys_image() {
    echo -e "${BYellow}Select an option (type a number): ${Color_Off}\n"
    options=("Run Tethys using existing local docker image" "Run Tethys after updating to latest docker image" "Exit")
    select option in "${options[@]}"; do
        case $option in
            "Run Tethys using existing local docker image")
                echo -e "${BGreen}Using local image of the Tethys platform${Color_Off}\n"
                return 0
                ;;
            "Run Tethys after updating to latest docker image")
                echo -e "${BGreen}Pulling container...${Color_Off}\n"
                if ! docker pull "$TETHYS_IMAGE_NAME"; then
                    echo -e "${BRed}Failed to pull Docker image: $TETHYS_IMAGE_NAME${Color_Off}\n" >&2
                    return 1
                fi
                return 0
                ;;
            "Exit")
                echo -e "${BCyan}Have a nice day!${Color_Off}\n"
                _tear_down
                exit 0
                ;;
            *)
                echo -e "${BRed}Invalid option $REPLY, 1 to continue with existing local image, 2 to update and run, and 3 to exit${Color_Off}\n"
                ;;
        esac
    done
}


_tear_down_tethys(){
    if [ "$(docker ps -aq -f name=$TETHYS_CONTAINER_NAME)" ]; then
        docker stop $TETHYS_CONTAINER_NAME > /dev/null 2>&1
    fi
}


_run_tethys(){
    _execute_command docker run --rm -it -d \
    -v "$DATA_FOLDER_PATH:$TETHYS_PERSIST_PATH/ngen-data" \
    -p 80:80 \
    --platform $PLATFORM \
    --network $DOCKER_NETWORK \
    --name "$TETHYS_CONTAINER_NAME" \
    --env MEDIA_ROOT="$TETHYS_PERSIST_PATH/media" \
    --env MEDIA_URL="/media/" \
    --env SKIP_DB_SETUP=$SKIP_DB_SETUP \
    $TETHYS_IMAGE_NAME \
    > /dev/null 2>&1
}


# Create tethys portal
create_tethys_portal(){
    while true; do
        echo -e "${BYellow}Visualize outputs using the Tethys Platform (https://www.tethysplatform.org/)? (y/N, default: y):${Color_Off}"
        read -r visualization_choice
        
        # Default to 'y' if input is empty
        if [[ -z "$visualization_choice" ]]; then
            visualization_choice="y"
        fi

        # Check for valid input
        if [[ "$visualization_choice" == [YyNn]* ]]; then
            break
        else
            echo -e "${BRed}Invalid choice. Please enter 'y' for yes, 'n' for no, or press Enter for default (yes).${Color_Off}"
        fi
    done
    
    # Execute the command
    if [[ "$visualization_choice" == [Yy]* ]]; then
        echo -e "${BGreen}Setup Tethys Portal image...${Color_Off}"
        _create_tethys_docker_network
        if _check_for_existing_tethys_image; then
            _execute_command _run_containers
            echo -e "${BCyan}Link data to the Tethys app workspace.${Color_Off}"
            _link_data_to_app_workspace
            _wait_container $TETHYS_CONTAINER_NAME
            echo -e "${BGreen}Your outputs are ready to be visualized at http://localhost/apps/ngiab ${Color_Off}"
            echo -e "${UPurple}You can use the following to login: ${Color_Off}"
            echo -e "${BCyan}user: admin${Color_Off}"
            echo -e "${BCyan}password: pass${Color_Off}"
            echo -e "${UPurple}Check the App source code: https://github.com/Aquaveo/ngiab-client ${Color_Off}"
            _pause_script_execution
        else
            echo -e "${BRed}Failed to prepare Tethys portal.${Color_Off}\n"
        fi
    else
        echo -e "${BCyan}Skipping Tethys visualization setup.${Color_Off}\n"
    fi
}


##########################
#####START OF SCRIPT######
##########################

# Set up the SIGINT trap to call the handle_sigint function
trap handle_sigint SIGINT

# Constanst
PLATFORM='linux/amd64'
TETHYS_CONTAINER_NAME="tethys-ngen-portal"
DOCKER_NETWORK="tethys-network"
APP_WORKSPACE_PATH="/usr/lib/tethys/apps/ngiab/tethysapp/ngiab/workspaces/app_workspace"
TETHYS_IMAGE_NAME=awiciroh/tethys-ngiab:main
DATA_FOLDER_PATH="$1"
TETHYS_PERSIST_PATH="/var/lib/tethys_persist"
CONFIG_FILE="$HOME/.host_data_path.conf"
SKIP_DB_SETUP=false

# check for architecture
if uname -a | grep arm64 || uname -a | grep aarch64 ; then
    PLATFORM=linux/arm64
else
    PLATFORM=linux/amd64
fi


check_last_path "$@"

create_tethys_portal

