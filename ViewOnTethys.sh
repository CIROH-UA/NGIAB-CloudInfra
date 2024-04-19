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



# Create tethys portal
create_tethys_portal(){
    local data_folder_path="$1"
    local tethys_home_path="$2"
    local tethys_image_name="$3"
    echo -e "${YELLOW}Do you want to visualize your outputs using tethys? (y/N, default: y):${RESET}"

    read -r visualization_choice

    # Execute the command
    if [[ "$visualization_choice" == [Yy]* ]]; then
        echo -e "${GREEN}Creating Tethys Portal...${RESET}"
        docker run --rm -it -d -v "$data_folder_path:$tethys_home_path" -p 80:80 --name "tethys-ngen-portal" $tethys_image_name 
        wait_tethys_portal
        convert_gpkg_to_geojson    #convert the geopackage to geojson for the catchments and for the nexus
        echo -e "${GREEN}Your outputs are ready to be visualized at http://localhost:80 ${RESET}"
    else
        echo ""
    fi
}


create_tethys_portal "/home/gio/tethysdev/docker/NextGen/ngen-data/AWI_09_004" "/var/lib/tethys_persist/ngen" "micro-tethys-portal:latest"