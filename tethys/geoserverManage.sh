#!/bin/bash
# ANSI color codes
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
RESET='\e[0m'



# Function to get the IP address of the GeoServer container
get_geoserver_container_ip(){
    local ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' tethys-geoserver)
    echo $ip
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


#create the docker network to communicate between tethys and geoserver
create_docker_network(){
    docker network create -d bridge tethys-network
}

#create a tmp folder for the data
create_tmp_geoserver_data_folder(){
    mkdir -p /tmp/nextgen/geoserver_data
}

# run the geoserver docker container
run_geoserver_docker(){
    docker run -it -p 8181:8080 \
    --env CORS_ENABLED=true \
    --env SKIP_DEMO_DATA=true \
    --network tethys-network \
    --name tethys-geoserver \
    -d \
    --mount src=/tmp/nextgen/geoserver_data,target=/opt/geoserver_data/,type=bind \
    docker.osgeo.org/geoserver:2.25.x
}



# check if the geoserver is up and running
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


start_geoserver_docker(){
    create_tmp_geoserver_data_folder
    run_geoserver_docker
    wait_geoserver
}