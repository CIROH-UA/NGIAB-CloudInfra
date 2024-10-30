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
############GEOSERVER FUNCTIONS#################
################################################

# run the geoserver docker container
_run_geoserver(){
    _execute_command docker run -it --rm -d \
    --platform $PLATFORM \
    -p $GEOSERVER_PORT_HOST:$GEOSERVER_PORT_CONTAINER \
    --env SAMPLE_DATA=false \
    --env GEOSERVER_ADMIN_USER=admin \
    --env GEOSERVER_ADMIN_PASSWORD=geoserver \
    --network $DOCKER_NETWORK \
    --name $GEOSERVER_CONTAINER_NAME \
    $GEOSERVER_IMAGE_NAME \
    > /dev/null 2>&1
}

_check_for_existing_geoserver_image() {
    printf "${BYellow}Select an option (type a number): ${Color_Off}\n"
    options=("Run GeoServer using existing local docker image" "Run GeoServer after updating to latest docker image" "Exit")
    select option in "${options[@]}"; do
        case $option in
            "Run GeoServer using existing local docker image")
                printf "${BGreen}Using local image of GeoServer${Color_Off}\n"
                return 0
                ;;
            "Run GeoServer after updating to latest docker image")
                printf "${BGreen}Pulling container...${Color_Off}\n"
                if ! docker pull "$GEOSERVER_IMAGE_NAME"; then
                    printf "${BRed}Failed to pull Docker image: $GEOSERVER_IMAGE_NAME${Color_Off}\n" >&2
                    return 1
                else
                    printf "${BGreen}Successfully updated GeoServer image.${Color_Off}\n"
                fi
                return 0
                ;;
            "Exit")
                printf "${BCyan}Have a nice day!${Color_Off}\n"
                _tear_down
                exit 0
                ;;
            *)
                printf "${BRed}Invalid option $REPLY. Please type 1 to continue with existing local image, 2 to update and run, or 3 to exit.${Color_Off}\n"
                ;;
        esac
    done
}

_tear_down_geoserver(){
    if [ "$(docker ps -aq -f name=$GEOSERVER_CONTAINER_NAME)" ]; then
        docker stop $GEOSERVER_CONTAINER_NAME > /dev/null 2>&1 
        rm -rf $DATA_FOLDER_PATH/tethys/geoserver_data
    fi
}

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
        printf "Last used data directory path: %s\n" "$last_path"
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
            printf "Invalid input. Exiting.\n" >&2
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
    _tear_down_geoserver
    docker network rm $DOCKER_NETWORK > /dev/null 2>&1
}

_run_containers(){
    _run_tethys
    echo -e "${BGreen}Setup GeoServer image...${Color_Off}"
    _check_for_existing_geoserver_image
    _run_geoserver
}

# Wait for a Docker container to become healthy or unhealthy
_wait_container() {
    local container_name=$1
    local container_health_status
    local attempt_counter=0

    printf "${UPurple}Waiting for container: $container_name to start, this can take a couple of minutes...${Color_Off}\n"

    until [[ "$container_health_status" == "healthy" || "$container_health_status" == "unhealthy" ]]; do
        # Update the health status
        if ! container_health_status=$(docker inspect -f '{{.State.Health.Status}}' "$container_name" 2>/dev/null); then
            printf "${BRed}Failed to get health status for container $container_name. Ensure container exists and has a health check.${Color_Off}\n" >&2
            return 1
        fi

        if [[ -z "$container_health_status" ]]; then
            printf "${BRed}No health status available for container $container_name. Ensure the container has a health check configured.${Color_Off}\n" >&2
            return 1
        fi

        ((attempt_counter++))
        sleep 2  # Adjusted sleep time to 2 seconds to reduce system load
    done

    printf "${BCyan}Container $container_name is now $container_health_status.${Color_Off}\n"
    return 0
}



_pause_script_execution() {
    while true; do
        printf "${BYellow}Press q to exit the visualization (default: q/Q):${Color_Off}\n"
        read -r exit_choice

        if [[ "$exit_choice" =~ ^[qQ]$ ]]; then
            printf "${BRed}Cleaning up Tethys ...${Color_Off}\n"
            _tear_down
            exit 0
        else
            printf "${BRed}Invalid input. Please press 'q' or 'Q' to exit.${Color_Off}\n"
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

_convert_gpkg_to_geojson() {
    local python_bin_path="$1"
    local path_script="$2"
    local gpkg_name="$3"
    local layer_name="$4"
    local geojson_file="$5"
    local gpkg_file="$APP_WORKSPACE_PATH/ngen-data/config/$gpkg_name"
    echo "$gpkg_file"
    _execute_command docker exec -it \
        $TETHYS_CONTAINER_NAME \
        $python_bin_path \
        $path_script \
        --convert_to_geojson \
        --gpkg_path $gpkg_file \
        --layer_name $layer_name \
        --output_path $geojson_file
}

_publish_gpkg_layer_to_geoserver() {
    local python_bin_path="$1"
    local path_script="$2"
    local gpkg_file="$3"
    local catchment_gpkg_layer="$4"
    local shapefile_path="$5"
    local store_name="$6"
    local geoserver_port="$GEOSERVER_PORT_CONTAINER"
    local gpkg_file_path="$APP_WORKSPACE_PATH/ngen-data/config/$gpkg_file"

    _execute_command docker exec -it \
        $TETHYS_CONTAINER_NAME \
        $python_bin_path \
        $path_script \
        --publish \
        --gpkg_path $gpkg_file_path \
        --layer_name $catchment_gpkg_layer \
        --shp_path "$shapefile_path" \
        --store_name $store_name \
        --geoserver_host $GEOSERVER_CONTAINER_NAME \
        --geoserver_port $geoserver_port \
        --geoserver_username admin \
        --geoserver_password geoserver
}

_publish_geojson_layer_to_geoserver() {
    local python_bin_path="$1"
    local path_script="$2"
    local geojson_path="$3"
    local shapefile_path="$4"
    local store_name="$5"
    _execute_command docker exec -it \
        $TETHYS_CONTAINER_NAME \
        $python_bin_path \
        $path_script \
        --publish_geojson \
        --geojson_path $geojson_path \
        --shp_path "$shapefile_path" \
        --store_name $store_name \
        --geoserver_host $GEOSERVER_CONTAINER_NAME \
        --geoserver_port $GEOSERVER_PORT_CONTAINER \
        --geoserver_username admin \
        --geoserver_password geoserver
}

_create_geoserver_workspace() {
    local python_bin_path="$1"
    local path_script="$2"
    _execute_command docker exec -it \
        $TETHYS_CONTAINER_NAME \
        $python_bin_path \
        $path_script \
        --create_workspace \
        --geoserver_host $GEOSERVER_CONTAINER_NAME \
        --geoserver_port $GEOSERVER_PORT_CONTAINER \
        --geoserver_username admin \
        --geoserver_password geoserver
}



_check_for_existing_tethys_image() {
    printf "${BYellow}Select an option (type a number): ${Color_Off}\n"
    options=("Run Tethys using existing local docker image" "Run Tethys after updating to latest docker image" "Exit")
    select option in "${options[@]}"; do
        case $option in
            "Run Tethys using existing local docker image")
                printf "${BGreen}Using local image of the Tethys platform${Color_Off}\n"
                return 0
                ;;
            "Run Tethys after updating to latest docker image")
                printf "${BGreen}Pulling container...${Color_Off}\n"
                if ! docker pull "$TETHYS_IMAGE_NAME"; then
                    printf "${BRed}Failed to pull Docker image: $TETHYS_IMAGE_NAME${Color_Off}\n" >&2
                    return 1
                fi
                return 0
                ;;
            "Exit")
                printf "${BCyan}Have a nice day!${Color_Off}\n"
                _tear_down
                exit 0
                ;;
            *)
                printf "${BRed}Invalid option $REPLY, 1 to continue with existing local image, 2 to update and run, and 3 to exit${Color_Off}\n"
                ;;
        esac
    done
}


_tear_down_tethys(){
    if [ "$(docker ps -aq -f name=$TETHYS_CONTAINER_NAME)" ]; then
        docker stop $TETHYS_CONTAINER_NAME > /dev/null 2>&1
    fi
}


_prepare_hydrofabrics(){
    local python_bin_path="/opt/conda/envs/tethys/bin/python"
    local path_script="/usr/lib/tethys/apps/ngiab/cli/convert_geom.py"
    local catchment_gpkg_layer="divides"
    local nexus_gpkg_layer="nexus"
    local flowpaths_gpkg_layer="flowpaths"
    local catchment_geojson_path="$APP_WORKSPACE_PATH/ngen-data/config/catchments.geojson"
    local nexus_geojson_path="$APP_WORKSPACE_PATH/ngen-data/config/nexus.geojson"
    local flowpaths_geojson_path="$APP_WORKSPACE_PATH/ngen-data/config/flowpaths.geojson"
    local shapefile_path="$APP_WORKSPACE_PATH/ngen-data/config/catchments"
    local flowpaths_shapefile_path="$APP_WORKSPACE_PATH/ngen-data/config/flowpaths"
    local catchment_store_name="catchments"
    local flowpaths_store_name="flowpaths"

    echo -e "${BCyan}Creating Nextgen workspace. ${Color_Off}"
    _create_geoserver_workspace \
            $python_bin_path \
            $path_script \

    # Auto-selecting files if only one is found
    echo -e "${BCyan}Preparing the catchments...${Color_Off}"
    selected_catchment=$(_auto_select_file "$CATCHMENT_FILE")
    if [[ -n $selected_catchment ]]; then
        _publish_geojson_layer_to_geoserver \
            $python_bin_path \
            $path_script \
            $catchment_geojson_path \
            $shapefile_path \
            $catchment_store_name \
            > /dev/null 2>&1
    else
        selected_catchment=$(_auto_select_file "$HYDRO_FABRIC")
        if [[ -n  $selected_catchment ]]; then
            catchment_gpkg_filename=$(_get_filename "$selected_catchment")                
            _publish_gpkg_layer_to_geoserver \
                $python_bin_path \
                $path_script \
                $catchment_gpkg_filename \
                $catchment_gpkg_layer \
                $shapefile_path \
                $catchment_store_name \
                > /dev/null 2>&1
        else
            n1=${selected_catchment:-$(read -p "Enter the hydrofabric catchment geojson file path: " n1; echo "$n1")}
            local catchmentfilename=$(basename "$n1")
            local catchment_path_check="$DATA_FOLDER_PATH/config/$catchmentfilename"
            if [[ -e "$catchment_path_check" ]]; then
                if [[ "$catchmentfilename" != "catchments.geojson" ]]; then
                    _execute_command docker cp $n1 $TETHYS_CONTAINER_NAME:$TETHYS_PERSIST_PATH/ngen-data/config/catchments.geojson > /dev/null 2>&1
                fi
            else
                    _execute_command docker cp $n1 $TETHYS_CONTAINER_NAME:$TETHYS_PERSIST_PATH/ngen-data/config/catchments.geojson > /dev/null 2>&1
            fi
            _publish_geojson_layer_to_geoserver \
                $python_bin_path \
                $path_script \
                $catchment_geojson_path \
                $shapefile_path \
                $catchment_store_name \
                > /dev/null 2>&1

        fi
    fi

    echo -e "${BCyan}Preparing the nexus...${Color_Off}"

    selected_nexus=$(_auto_select_file "$NEXUS_FILE")
    if [[ -n  $selected_nexus ]]; then
        _execute_command docker cp $selected_nexus $TETHYS_CONTAINER_NAME:$TETHYS_PERSIST_PATH/ngen-data/config/nexus.geojson > /dev/null 2>&1
    else
        selected_nexus=$(_auto_select_file "$HYDRO_FABRIC")
        if [[ -n  $selected_nexus ]]; then
            nexus_gpkg_filename=$(_get_filename "$selected_nexus")
            _convert_gpkg_to_geojson \
                $python_bin_path \
                $path_script \
                $nexus_gpkg_filename \
                $nexus_gpkg_layer \
                $nexus_geojson_path \
                > /dev/null 2>&1
        else
            n2=${selected_nexus:-$(read -p "Enter the hydrofabric nexus geojson file path: " n2; echo "$n2")} 
            local nexusfilename=$(basename "$n2")
            local nexus_path_check="$DATA_FOLDER_PATH/config/$nexusfilename"

            if [[ -e "$nexus_path_check" ]]; then
                if [[ "$nexusfilename" != "nexus.geojson" ]]; then
                    _execute_command docker cp $n2 $TETHYS_CONTAINER_NAME:$TETHYS_PERSIST_PATH/ngen-data/config/nexus.geojson > /dev/null 2>&1
                fi
            else
                _execute_command docker cp $n2 $TETHYS_CONTAINER_NAME:$TETHYS_PERSIST_PATH/ngen-data/config/nexus.geojson > /dev/null 2>&1
            fi

        fi
    fi
    
    echo -e "${BCyan}Preparing the flow paths...${Color_Off}"

    selected_flowpaths=$(_auto_select_file "$FLOWPATHTS_FILE")
    if [[ -n  $selected_flowpaths ]]; then
        _publish_geojson_layer_to_geoserver \
            $python_bin_path \
            $path_script \
            $flowpaths_geojson_path \
            $flowpaths_shapefile_path \
            $flowpaths_store_name \
            > /dev/null 2>&1

    else
        selected_flowpaths=$(_auto_select_file "$HYDRO_FABRIC")
        if [[ -n  $selected_flowpaths ]]; then
            flowpaths_gpkg_filename=$(_get_filename "$selected_flowpaths")
            _publish_gpkg_layer_to_geoserver \
                $python_bin_path \
                $path_script \
                $flowpaths_gpkg_filename \
                $flowpaths_gpkg_layer \
                $flowpaths_geojson_path \
                $flowpaths_store_name \
                > /dev/null 2>&1

        else
            n2=${selected_flowpaths:-$(read -p "Enter the flow paths  geojson file path: " n2; echo "$n2")} 
            local flowpathfilename=$(basename "$n2")
            local flowpath_path_check="$DATA_FOLDER_PATH/config/$flowpathfilename"

            if [[ -e "$flowpath_path_check" ]]; then
                if [[ "$flowpathfilename" != "flowpaths.geojson" ]]; then
                    _execute_command docker cp $n2 $TETHYS_CONTAINER_NAME:$TETHYS_PERSIST_PATH/ngen-data/config/flowpaths.geojson
                fi
            else
                _execute_command docker cp $n2 $TETHYS_CONTAINER_NAME:$TETHYS_PERSIST_PATH/ngen-data/config/flowpaths.geojson
            fi
            _publish_geojson_layer_to_geoserver \
                $python_bin_path \
                $path_script \
                $flowpaths_geojson_path \
                $flowpaths_shapefile_path \
                $flowpaths_store_name \
                > /dev/null 2>&1

        fi
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
            sleep 60
            echo -e "${BCyan}Link data to the Tethys app workspace.${Color_Off}"
            _link_data_to_app_workspace         
            echo -e "${BGreen}Preparing the hydrofabrics for the portal...${Color_Off}"
            _prepare_hydrofabrics
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
GEOSERVER_CONTAINER_NAME="tethys-geoserver"
GEOSERVER_PORT_CONTAINER="8080"
GEOSERVER_PORT_HOST="8181"
DOCKER_NETWORK="tethys-network"
APP_WORKSPACE_PATH="/usr/lib/tethys/apps/ngiab/tethysapp/ngiab/workspaces/app_workspace"
TETHYS_IMAGE_NAME=awiciroh/tethys-ngiab:troute_addition
GEOSERVER_IMAGE_NAME=kartoza/geoserver:2.26.0
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

