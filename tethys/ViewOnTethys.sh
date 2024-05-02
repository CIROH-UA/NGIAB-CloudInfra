#!/bin/bash
# ANSI color codes
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
RESET='\e[0m'

# GEOSERVER FUNCTIONS
# create a tmp folder for the data
create_geoserver_data_folder(){
    # mkdir -p $DATA_FOLDER_PATH/tethys/geoserver_data

    #need to create through the tethys directory for permission issues
    docker exec -it \
    $TETHYS_CONTAINER_NAME \
    sh -c \
    "mkdir -p $APP_WORKSPACE_PATH/ngen-data/tethys/geoserver_data"
}

# run the geoserver docker container
run_geoserver(){
    docker run -it --rm -d -p $GEOSERVER_PORT_HOST:$GEOSERVER_PORT_CONTAINER \
    --env CORS_ENABLED=true \
    --env SKIP_DEMO_DATA=true \
    --network $DOCKER_NETWORK \
    --name $GEOSERVER_CONTAINER_NAME \
    $GEOSERVER_IMAGE_NAME > /dev/null 2>&1
}
# --mount src=$DATA_FOLDER_PATH/tethys/geoserver_data,target=/opt/geoserver_data/,type=bind \

# check if the geoserver is up and running
wait_geoserver(){
    local MAX_TRIES=10
    local SLEEP_TIME=5  # Sleep time in seconds
    local count=0

    while [[ $count -lt $MAX_TRIES ]]; do
        if check_http_response "${GEOSERVER_PORT_HOST}"; then
            printf "GeoServer is up and running at http://localhost:${GEOSERVER_PORT_HOST} .\n"
            return 0
        fi
        ((count++))
        sleep $SLEEP_TIME
    done
    return 1
}

# Start the geoserver container
start_geoserver(){
    run_geoserver
    wait_geoserver
}

# HELPER FUNCTIONS

# Function to automatically select file if only one is found
auto_select_file() {
  local files=($1)
  if [ "${#files[@]}" -eq 1 ]; then
    echo "${files[0]}"
  else
    echo ""
  fi
}

# Function to check HTTP response from a service on a specific port
check_http_response() {
    local port=$1
    local url="http://localhost:${port}"

    # Use curl to get the HTTP status code
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" "${url}")

    if [[ "$status_code" -eq 200 || "$status_code" -eq 302  ]]; then
        return 0
    else
        return 1
    fi
}



# TETHYS FUNCTIONS 

#create the docker network to communicate between tethys and geoserver
create_tethys_docker_network(){
    docker network create -d bridge tethys-network > /dev/null 2>&1
}

# Link the data to the app workspace
link_data_to_app_workspace(){
    docker exec -it $TETHYS_CONTAINER_NAME sh -c \
        "mkdir -p $APP_WORKSPACE_PATH && \
        ln -s $TETHYS_PERSIST_PATH/ngen-data $APP_WORKSPACE_PATH/ngen-data"
}


convert_gpkg_to_geojson() {
    local python_bin_path="$1"
    local path_script="$2"
    local gpkg_file="$3"
    local layer_name="$4"
    local geojson_file="$5"

    docker exec -it \
        $TETHYS_CONTAINER_NAME \
        $python_bin_path \
        $path_script \
        $gpkg_file \
        $layer_name \
        $geojson_file > /dev/null 2>&1
}

publish_gpkg_layer_to_geoserver() {

    local python_bin_path="/opt/conda/envs/tethys/bin/python"
    local path_script="/usr/lib/tethys/apps/ngiab/cli/convert_geom.py"
    local catchment_gpkg_layer="divides"
    local gpkg_file_path="$APP_WORKSPACE_PATH/ngen-data/config/datastream.gpkg"
    local catchment_geojson_path="$APP_WORKSPACE_PATH/ngen-data/config/catchments.geojson"
    local shapefile_path="$APP_WORKSPACE_PATH/ngen-data/config/catchments"
    local geoserver_port="$GEOSERVER_PORT_CONTAINER"
    
    docker exec -it \
        $TETHYS_CONTAINER_NAME \
        $python_bin_path \
        $path_script \
        $gpkg_file_path \
        $catchment_gpkg_layer \
        $catchment_geojson_path \
        --publish \
        --shp_path "$shapefile_path" \
        --geoserver_host $GEOSERVER_CONTAINER_NAME \
        --geoserver_port $geoserver_port \
        --geoserver_username admin \
        --geoserver_password geoserver > /dev/null 2>&1
}




# Main function that implements the retry logic
wait_tethys_portal() {
    local PORT=80  # Port to check
    local MAX_TRIES=1000
    local SLEEP_TIME=5  # Sleep time in seconds
    local count=0

    while [[ $count -lt $MAX_TRIES ]]; do
        if check_http_response "${PORT}"; then
            docker exec -it $TETHYS_CONTAINER_NAME /opt/conda/envs/tethys/bin/tethys settings --set TETHYS_PORTAL_CONFIG.ENABLE_OPEN_PORTAL true > /dev/null 2>&1
            # docker exec -it $TETHYS_CONTAINER_NAME /opt/conda/envs/tethys/bin/tethys settings --set TETHYS_PORTAL_CONFIG.MULTIPLE_APP_MODE false
            # docker exec -it $TETHYS_CONTAINER_NAME /opt/conda/envs/tethys/bin/tethys settings --set TETHYS_PORTAL_CONFIG.STANDALONE_APP ngiab 
            #todo make portal open
            docker exec -it $TETHYS_CONTAINER_NAME sh -c "supervisorctl restart all" #restart asgi service to make tethys take into account he open portal
            printf "Tethys Portal is up and running.\n"
            return 0
        fi
        ((count++))
        sleep $SLEEP_TIME
    done

    printf "Server failed to return HTTP 200 OK on port %d after %d attempts.\n" "${PORT}" "$MAX_TRIES" >&2
    return 1
}


check_for_existing_tethys_image(){
    echo -e "${UYellow}Select an option (type a number): ${Color_Off}"
    options=("Run Tethys using existing local docker image" "Run Tethys after updating to latest docker image" "Exit")
    select option in "${options[@]}"; do
        case $option in
            "Run Tethys using existing local docker image")
                echo -e "${GREEN}Creating Tethys Portal...${RESET}."
                break
                ;;
            "Run Tethys after updating to latest docker image")
                echo "pulling container"
                docker pull $TETHYS_IMAGE_NAME
                break
                ;;
            Exit)
                echo "Have a nice day!"
                exit 0
                ;;
            *) echo "Invalid option $REPLY, 1 to continue with existing local image, 2 to update and run, and 3 to exit"
                ;;
        esac
    done
}


tear_down_tethys(){
    docker stop $TETHYS_CONTAINER_NAME > /dev/null 2>&1
}

tear_down_geoserver(){
    docker stop $GEOSERVER_CONTAINER_NAME > /dev/null 2>&1
    # remove the geoserver data folder
    rm -rf $DATA_FOLDER_PATH/tethys/geoserver_data
}

pause_script_execution(){
    echo -e "${YELLOW}Press q to exit the visualization (default: q/Q):${RESET}"
    read -r exit_choice
    if [[ "$exit_choice" == [qQ]* ]]; then
        echo -e "${GREEN}Cleaning up Tethys ...${RESET}"
        tear_down_tethys
        tear_down_geoserver
        docker network rm $DOCKER_NETWORK > /dev/null 2>&1
        exit 0
    fi
}

prepare_hydrofabrics(){
    local python_bin_path="/opt/conda/envs/tethys/bin/python"
    local path_script="/usr/lib/tethys/apps/ngiab/cli/convert_geom.py"
    local catchment_gpkg_layer="divides"
    local nexus_gpkg_layer="nexus"
    local gpkg_file_path="$APP_WORKSPACE_PATH/ngen-data/config/datastream.gpkg"
    local catchment_geojson_path="$APP_WORKSPACE_PATH/ngen-data/config/catchments.geojson"
    local nexus_geojson_path="$APP_WORKSPACE_PATH/ngen-data/config/nexus.geojson"
    

    # Auto-selecting files if only one is found
    echo -e "${CYAN}Preparing the catchtments...${RESET}"
    selected_catchment=$(auto_select_file "$HYDRO_FABRIC")
    if [[ "$selected_catchment" == "$DATA_FOLDER_PATH/config/datastream.gpkg" ]]; then
        convert_gpkg_to_geojson \
            $python_bin_path \
            $path_script \
            $gpkg_file_path \
            $catchment_gpkg_layer \
            $catchment_geojson_path
    else
        n1=${selected_catchment:-$(read -p "Enter the hydrofabric catchment geojson file path: " n1; echo "$n1")}
        local catchmentfilename=$(basename "$n1")
        local catchment_path_check="$DATA_FOLDER_PATH/config/$catchmentfilename"

        if [[ -e "$catchment_path_check" ]]; then
            if [[ "$catchmentfilename" != "nexus.json" ]]; then
                docker cp $n1 $TETHYS_CONTAINER_NAME:$TETHYS_PERSIST_PATH/ngen-data/config/catchments.geojson > /dev/null 2>&1
            fi
        else
                docker cp $n1 $TETHYS_CONTAINER_NAME:$TETHYS_PERSIST_PATH/ngen-data/config/catchments.geojson > /dev/null 2>&1
        fi

    fi

    echo -e "${CYAN}Preparing the nexus...${RESET}"
    selected_nexus=$(auto_select_file "$HYDRO_FABRIC")

    if [[ "$selected_nexus" == "$DATA_FOLDER_PATH/config/datastream.gpkg" ]]; then
        convert_gpkg_to_geojson \
            $python_bin_path \
            $path_script \
            $gpkg_file_path \
            $nexus_gpkg_layer \
            $nexus_geojson_path
    else
        n2=${selected_nexus:-$(read -p "Enter the hydrofabric nexus geojson file path: " n2; echo "$n2")} 
        local nexusfilename=$(basename "$n2")
        local nexus_path_check="$DATA_FOLDER_PATH/config/$nexusfilename"

        if [[ -e "$nexus_path_check" ]]; then
            if [[ "$nexusfilename" != "nexus.json" ]]; then
                docker cp $n2 $TETHYS_CONTAINER_NAME:$TETHYS_PERSIST_PATH/ngen-data/config/nexus.geojson > /dev/null 2>&1
            fi
        else
            docker cp $n2 $TETHYS_CONTAINER_NAME:$TETHYS_PERSIST_PATH/ngen-data/config/nexus.geojson > /dev/null 2>&1
        fi

    fi
    
}
run_tethys(){
    docker run --rm -it -d \
    -v "$DATA_FOLDER_PATH:$TETHYS_PERSIST_PATH/ngen-data" \
    -p 80:80 \
    --network $DOCKER_NETWORK \
    --name "$TETHYS_CONTAINER_NAME" \
    --env MEDIA_ROOT="$TETHYS_PERSIST_PATH/media" \
    --env MEDIA_URL="/media/" \
    $TETHYS_IMAGE_NAME > /dev/null 2>&1
}

# Create tethys portal
create_tethys_portal(){

    echo -e "${YELLOW}Do you want to visualize your outputs using tethys? (y/N, default: y):${RESET}"
    read -r visualization_choice

    # Execute the command
    if [[ "$visualization_choice" == [Yy]* ]]; then
        echo -e "${GREEN}Starting Tethys Portal...${RESET}"
        #create the docker network to communicate between tethys and geoserver
        create_tethys_docker_network
        check_for_existing_tethys_image
        
        run_tethys
        wait_tethys_portal

        echo -e "${CYAN}Link data to the Tethys app workspace.${RESET}"
        link_data_to_app_workspace         
        echo -e "${GREEN}Preparing the hydrofabrics for the portal...${RESET}"
        prepare_hydrofabrics
        
        echo -e "${CYAN}Preparing a geoserver instance to be used ${RESET}"
        start_geoserver
        
        echo -e "${CYAN}Publishing catchment layer to geoserver${RESET}"
        publish_gpkg_layer_to_geoserver
        # copy_shp_to_geoserver_data_folder "$DATA_FOLDER_PATH/config/catchments.zip" "$APP_WORKSPACE_PATH/ngen-data/tethys/geoserver_data"

        echo -e "${GREEN}Your outputs are ready to be visualized at http://localhost/apps/ngiab ${RESET}"
        pause_script_execution

    else
        echo ""
    fi
}

# Constanst
TETHYS_CONTAINER_NAME="tethys-ngen-portal"
GEOSERVER_CONTAINER_NAME="tethys-geoserver"
GEOSERVER_PORT_CONTAINER="8080"
GEOSERVER_PORT_HOST="8181"
DOCKER_NETWORK="tethys-network"
APP_WORKSPACE_PATH="/usr/lib/tethys/apps/ngiab/tethysapp/ngiab/workspaces/app_workspace"
DATA_FOLDER_PATH="$1"
echo "$DATA_FOLDER_PATH"
TETHYS_PERSIST_PATH="$2"
# Finding files
HYDRO_FABRIC=$(find "$DATA_FOLDER_PATH/config" -name "*datastream*.gpkg")
# check for architecture again 
if uname -a | grep arm64 || uname -a | grep aarch64 ; then
    TETHYS_IMAGE_NAME=gioelkin/tethys-ngiab:dev_latest
    GEOSERVER_IMAGE_NAME=docker.osgeo.org/geoserver:2.25.x
else
    TETHYS_IMAGE_NAME=gioelkin/tethys-ngiab:dev_latest
    GEOSERVER_IMAGE_NAME=docker.osgeo.org/geoserver:2.25.x
    #TODO # IMAGE_NAME=gioelkin/tethys-ngiab:latest-x86
fi

create_tethys_portal

