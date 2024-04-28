#!/bin/bash
# ANSI color codes
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
RESET='\e[0m'


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

# todo
create_docker_network(){
    # we need to create a docker network and connect the tethys container and geoserver to that network.
}

# to do need to add the newtwork to the docker run command
run_geoserver_docker(){
    local path_to_local_data="$1"
    docker run -it -p 8181:8080 \ 
    -e CORS_ENABLED=true \
    # -e SKIP_DEMO_DATA=true \
    -d \
    --mount src="$path_to_local_data",target=/opt/geoserver_data/,type=bind \
    docker.osgeo.org/geoserver:2.25.x

    # docker run -d \
    # --name geoserver \
    # -p 8181:8181 \
    # -p 8081:8081 \
    # -p 8082:8082 \
    # -p 8083:8083 \
    # -p 8084:8084 \
    # -e ENABLED_NODES=1 \
    # -e REST_NODES=1 \
    # -e MAX_MEMORY=512 \
    # -e MIN_MEMORY=512 \
    # -e NUM_CORES=2 \
    # -e MAX_TIMEOUT=60 \
    # tethysplatform/geoserver:latest
}

# to check
wait_geoserver(){
    local PORT=8181  # Port to check
    local MAX_TRIES=10
    local SLEEP_TIME=5  # Sleep time in seconds
    local count=0

    while [[ $count -lt $MAX_TRIES ]]; do
        if check_http_response "${PORT}"; then
            printf "GeoServer is up and running.\n"
            return 0
        fi
        ((count++))
        sleep $SLEEP_TIME
    done

    printf "Server failed to return HTTP 200 OK on port %d after %d attempts.\n" "${PORT}" "$MAX_TRIES" >&2
    return 1
}

# Copy the data to the app workspace
link_data_to_app_workspace(){
    local path_to_data="$1"
    local path_to_app_workspace="$2"
    local data_folder_before_rename=$(basename "$path_to_data")
    docker exec -it tethys-ngen-portal sh -c "ln -s $path_to_data $path_to_app_workspace/ngen-data"
}


convert_gpkg_to_geojson() {
    local path_script="$1"
    local gpkg_file="$2"
    local layer_name="$3"
    local geojson_file="$4"
    docker exec -it tethys-ngen-portal /opt/conda/envs/tethys/bin/python $path_script $gpkg_file $layer_name $geojson_file
}

# Main function that implements the retry logic
wait_tethys_portal() {
    local PORT=80  # Port to check
    local MAX_TRIES=10
    local SLEEP_TIME=5  # Sleep time in seconds
    local count=0

    while [[ $count -lt $MAX_TRIES ]]; do
        if check_http_response "${PORT}"; then
            docker exec -it tethys-ngen-portal /opt/conda/envs/tethys/bin/tethys settings --set TETHYS_PORTAL_CONFIG.ENABLE_OPEN_PORTAL true #make portal open
            docker exec -it tethys-ngen-portal sh -c "supervisorctl restart all" #restart asgi service to make tethys take into account he open portal
            printf "Tethys Portal is up and running.\n"
            return 0
        fi
        ((count++))
        sleep $SLEEP_TIME
    done

    printf "Server failed to return HTTP 200 OK on port %d after %d attempts.\n" "${PORT}" "$MAX_TRIES" >&2
    return 1
}

check_for_existing_tethys_container(){
    # Container name
    CONTAINER_NAME="tethys-ngen-portal"

    # Check if the container exists
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        printf "Container '%s' exists. Stopping and removing...\n" "$CONTAINER_NAME"

        # Stop the container if it is running
        if ! docker container stop "$CONTAINER_NAME"; then
            printf "Failed to stop container '%s'.\n" "$CONTAINER_NAME" >&2
            exit 1
        fi

        printf "Container '%s' has been stopped and removed successfully.\n" "$CONTAINER_NAME"
    else
        printf "Container '%s' does not exist.\n" "$CONTAINER_NAME"
    fi
}

# Create tethys portal
create_tethys_portal(){
    local data_folder_path="$1"
    local tethys_persist_path="$2"
    local tethys_image_name="$3"

    local tethys_home_path="/usr/lib/tethys/ngen_visualizer"
    local app_relative_path="tethysapp/ngen_visualizer"
    local geopackage_name="datastream.gpkg"
    local tethys_workspace_volume="workspaces/app_workspace"
    
    echo -e "${YELLOW}Do you want to visualize your outputs using tethys? (y/N, default: y):${RESET}"
    read -r visualization_choice

    # Execute the command
    if [[ "$visualization_choice" == [Yy]* ]]; then
        echo -e "${GREEN}Creating Tethys Portal...${RESET}"
        echo -e "${GREEN}$tethys_home_path/$app_relative_path/$tethys_workspace_volume${RESET}"
        check_for_existing_tethys_container
        docker run --rm -it -d -v "$data_folder_path:$tethys_persist_path" -p 80:80 --name "tethys-ngen-portal" $tethys_image_name 
        wait_tethys_portal

        echo -e "${CYAN}Moving data to the app workspace.${RESET}"
        link_data_to_app_workspace "$tethys_persist_path" "$tethys_home_path/$app_relative_path/$tethys_workspace_volume"

        echo -e "${CYAN}Preparing the data for the portal...${RESET}"
        echo -e "${CYAN}Preparing the catchtments...${RESET}"


        # this needs to be changed
        # this needs to be done calling the docker container
        convert_gpkg_to_geojson "$tethys_home_path/$app_relative_path/cli/convert_geom.py" "$tethys_home_path/$app_relative_path/$tethys_workspace_volume/ngen-data/config/$geopackage_name" "divides" $tethys_home_path/$app_relative_path/$tethys_workspace_volume/ngen-data/config/catchments.geojson
        
        echo -e "${CYAN}Preparing the nexus...${RESET}"
        convert_gpkg_to_geojson "$tethys_home_path/$app_relative_path/cli/convert_geom.py" "$tethys_home_path/$app_relative_path/$tethys_workspace_volume/ngen-data/config/$geopackage_name" "nexus" $tethys_home_path/$app_relative_path/$tethys_workspace_volume/ngen-data/config/nexus.geojson
        echo -e "${GREEN}Your outputs are ready to be visualized at http://localhost:80 ${RESET}"

    else
        echo ""
    fi
}


create_tethys_portal $1 $2 $3
