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
Color_Off='\033[0m'


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
        echo -e "Last used data directory path: %s\n" "$last_path${Color_Off}"
        read -erp "Do you want to use the same path? (Y/n): " use_last_path
        
        if [[ "$use_last_path" =~ ^[Yy] ]]; then
            DATA_FOLDER_PATH="$last_path"
            _check_if_data_folder_exits
            final_dir=$(_copy_models_run "$DATA_FOLDER_PATH")
            _add_model_run "$final_dir"
            return 0
        elif [[ "$use_last_path" =~ ^[Nn] ]]; then
            read -erp "Enter your input data directory path (use absolute path): " DATA_FOLDER_PATH
            _check_if_data_folder_exits
            # Save the new path to the config file
            echo "$DATA_FOLDER_PATH" > "$CONFIG_FILE"
            final_dir=$(_copy_models_run "$DATA_FOLDER_PATH")
            _add_model_run "$final_dir"
            echo -e "The Directory you've given is:\n$DATA_FOLDER_PATH\n${Color_Off}"   
        else
            echo -e "Invalid input. Exiting.\n${Color_Off}" >&2
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

_choose_port_to_run_tethys(){
    while true; do
        echo -e "${BYellow}Select a port to run Tethys (default: 80): ${Color_Off}"
        read -erp "Port (default: 80): " NGINX_TETHYS_PORT
        if [[ -z "$NGINX_TETHYS_PORT" ]]; then
            NGINX_TETHYS_PORT=80
            CSRF_TRUSTED_ORIGINS="\"[http://localhost:$NGINX_TETHYS_PORT, http://127.0.0.1:$NGINX_TETHYS_PORT]\""
        fi

        # Check if the port is already in use
        if lsof -i:$NGINX_TETHYS_PORT > /dev/null; then
            echo -e "${BRed}Port $NGINX_TETHYS_PORT is already in use. Please choose another port.${Color_Off}"
        else
            break
        fi
    done
}

# Wait for a Docker container to become healthy
_wait_container() {
    local container_name=$1
    local container_health_status=""
    local attempt_counter=0

    echo -e "${UPurple}Waiting for container: $container_name to become healthy. This can take a couple of minutes...\n${Color_Off}"

    while true; do
        # Update the health status
        container_health_status=$(docker inspect -f '{{.State.Health.Status}}' "$container_name" 2>/dev/null)

        if [ $? -ne 0 ]; then
            echo -e "${BRed}Failed to get health status for container $container_name. Ensure the container exists and has a health check.\n${Color_Off}" >&2
            return 1
        fi

        if [[ "$container_health_status" == "healthy" ]]; then
            echo -e "${BCyan}Container $container_name is now healthy.\n${Color_Off}"
            return 0
        elif [[ "$container_health_status" == "unhealthy" ]]; then
            echo -e "${BRed}Container $container_name is unhealthy.\n${Color_Off}" >&2
            return 1
        elif [[ -z "$container_health_status" ]]; then
            echo -e "${BRed}No health status available for container $container_name. Ensure the container has a health check configured.\n${Color_Off}" >&2
            return 1
        fi

        ((attempt_counter++))
        sleep 2  # Adjust the sleep time as needed
    done
}

_pause_script_execution() {
    while true; do
        echo -e "${BYellow}Press q to exit the visualization (default: q/Q):\n${Color_Off}"
        read -r exit_choice

        if [[ "$exit_choice" =~ ^[qQ]$ ]]; then
            echo -e "${BRed}Cleaning up Tethys ...\n${Color_Off}"
            _tear_down
            exit 0
        else
            echo -e "${BRed}Invalid input. Please press 'q' or 'Q' to exit.\n${Color_Off}"
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
        _check_if_data_folder_exits
        final_dir=$(_copy_models_run "$DATA_FOLDER_PATH")
        _add_model_run "$final_dir"
        return 0
    fi
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
    network_result=$(_execute_command docker network create -d bridge tethys-network 2>&1)
    if grep -i "Error" <<< "$network_result"; then
        echo -e "${BRed}Error while attempting to create Docker network. (Is Docker running?)${Color_Off}"
        _tear_down
        exit 1
    fi
}

_check_for_existing_tethys_image() {
    echo -e "${BYellow}Select an option (type a number): ${Color_Off}\n"
    options=("Run Tethys using existing local docker image" "Run Tethys after updating to latest docker image" "Exit")
    select option in "${options[@]}"; do
        case $option in
            "Run Tethys using existing local docker image")
                echo -e "${BGreen}Using local image of the Tethys platform\n${Color_Off}"
                return 0
                ;;
            "Run Tethys after updating to latest docker image")
                echo -e "${BGreen}Pulling container...${Color_Off}\n"
                if ! docker pull "$TETHYS_IMAGE_NAME"; then
                    echo -e "${BRed}Failed to pull Docker image: $TETHYS_IMAGE_NAME\n${Color_Off}" >&2
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
                echo -e "${BRed}Invalid option $REPLY, 1 to continue with existing local image, 2 to update and run, and 3 to exit\n${Color_Off}"
                ;;
        esac
    done
}


_tear_down_tethys(){
    if [ "$(docker ps -aq -f name=$TETHYS_CONTAINER_NAME)" ]; then
        docker stop $TETHYS_CONTAINER_NAME > /dev/null 2>&1
    fi
}


_ensure_host_dir() {
    local dir="$1"

    # 1) Create the directory (and parents) if it does not exist
    if [ ! -d "$dir" ]; then
        echo -e "${BYellow}Directory $dir doesn’t exist — creating it…${Color_Off}"
        mkdir -p "$dir"
    fi

    # 2) Get owner UID (portable: Linux uses -c, macOS/BSD uses -f)
    local owner_uid=""
    if owner_uid=$(stat -c '%u' "$dir" 2>/dev/null); then
        :  # GNU stat (Linux)
    elif owner_uid=$(stat -f '%u' "$dir" 2>/dev/null); then
        :  # BSD stat (macOS, Git-Bash)
    fi

    # 3) If the directory is not owned by the current user, try to chown it
    if [[ -n "$owner_uid" && "$owner_uid" != "$(id -u)" ]]; then
        if command -v chown >/dev/null 2>&1; then
            echo -e "${BYellow}Reclaiming ownership of $dir (sudo may prompt)…${Color_Off}"
            sudo chown -R "$(id -u):$(id -g)" "$dir"
        fi
    fi

    # 4) Ensure the current user has rwx on the directory
    chmod u+rwx "$dir"
}

# Ensure a *regular file* exists (and is writable) without touching siblings
_ensure_visualizer_conf_host_file() {
    local file="$1"
    local dir
    dir=$(dirname "$file")

    # 1) make sure the directory exists and is writable by the user
    _ensure_host_dir "$dir" || return 1

    # 2) create the file if it doesn't exist, and initialise it
    if [ ! -f "$file" ]; then
        echo -e "${BRed}File $file does not exist. Creating it...${Color_Off}"
        echo '{"model_runs":[]}' > "$file"
    fi

    # 3) ensure *you* can read/write the file
    chmod u+rw "$file"
}


_run_tethys() {

    _ensure_host_dir  "$MODELS_RUNS_DIRECTORY"
    _ensure_host_dir  "$DATASTREAM_DIRECTORY"
    _ensure_visualizer_conf_host_file "$VISUALIZER_CONF"

    _execute_command docker run --rm -it -d \
        -v "$MODELS_RUNS_DIRECTORY:$TETHYS_PERSIST_PATH/ngiab_visualizer" \
        -v "$DATASTREAM_DIRECTORY:$TETHYS_PERSIST_PATH/.datastream_ngiab" \
        -p 80:80 \
        --platform "$PLATFORM" \
        --network "$DOCKER_NETWORK" \
        --name "$TETHYS_CONTAINER_NAME" \
        --env MEDIA_ROOT="$TETHYS_PERSIST_PATH/media" \
        --env MEDIA_URL="/media/" \
        --env SKIP_DB_SETUP="$SKIP_DB_SETUP" \
        --env DATASTREAM_CONF="$TETHYS_PERSIST_PATH/.datastream_ngiab" \
        --env VISUALIZER_CONF="$TETHYS_PERSIST_PATH/ngiab_visualizer/ngiab_visualizer.json" \
        --env NGINX_PORT=$NGINX_TETHYS_PORT \
        --env CSRF_TRUSTED_ORIGINS=$CSRF_TRUSTED_ORIGINS \
        "$TETHYS_IMAGE_NAME" \
        > /dev/null 2>&1
}


_copy_models_run() {
    local input_path="$1"
    local models_dir="$HOME/ngiab_visualizer"
    # 1) make sure ~/ngiab_visualizer exists and you own it
    _ensure_host_dir "$models_dir" || {
        echo -e "${BRed}Failed to create or fix permissions on $models_dir${Color_Off}" >&2
        return 1
    }

    # 2) derive the target path
    local base_name
    base_name="$(basename "$input_path")"
    local model_run_path="$models_dir/$base_name"
    local final_copied_path="$model_run_path"

    # 3) copy logic
    if [ ! -e "$model_run_path" ]; then
        cp -r "$input_path" "$models_dir" || {
            echo -e "${BRed}Error: Could not copy $input_path → $models_dir${Color_Off}" >&2
            return 1
        }
        echo -e "${BCyan}Copied: $input_path → $model_run_path${Color_Off}" >&2
    else
        echo -e "${BYellow}Directory '$model_run_path' already exists.${Color_Off}" >&2
        while true; do
            echo -ne "${BYellow}Overwrite (O) or copy with different name (D)? [O/D]: ${Color_Off}" >&2
            read -r choice < /dev/tty
            case "$choice" in
                [Oo]* )
                    rm -rf "$model_run_path"
                    cp -r "$input_path" "$models_dir" || {
                        echo -e "${BRed}Error: Could not overwrite $model_run_path${Color_Off}" >&2
                        return 1
                    }
                    echo -e "${BCyan}Overwritten with: $input_path → $model_run_path${Color_Off}" >&2
                    break
                    ;;
                [Dd]* )
                    echo -ne "${BBlue}Enter a new directory name: ${Color_Off}" >&2
                    read -r new_name < /dev/tty
                    if [ -z "$new_name" ]; then
                        echo -e "${BRed}No name entered. Try again.${Color_Off}" >&2
                        continue
                    fi
                    local new_path="$models_dir/$new_name"
                    if [ -e "$new_path" ]; then
                        echo -e "${BRed}'$new_name' already exists. Choose another name.${Color_Off}" >&2
                        continue
                    fi
                    cp -r "$input_path" "$new_path" || {
                        echo -e "${BRed}Error: Could not copy to $new_path${Color_Off}" >&2
                        return 1
                    }
                    echo -e "${BPurple}Copied to: $new_path${Color_Off}" >&2
                    final_copied_path="$new_path"
                    break
                    ;;
                * )
                    echo -e "${BRed}Invalid choice. Enter 'O' or 'D'.${Color_Off}" >&2
                    ;;
            esac
        done
    fi

    # 4) output the directory the caller should register
    echo "$final_copied_path"
}

_add_model_run() {
  local input_path="$1"
  local json_file="$VISUALIZER_CONF"

  # 1) Ensure $json_file exists
  echo -e "${BGreen}Checking for $json_file...${Color_Off}"
  if [ ! -f "$json_file" ]; then
    echo '{"model_runs":[]}' > "$json_file"
  fi

  # 2) Extract the basename for label
  local base_name
  base_name=$(basename "$input_path")

  # Generate a new UUID for the id field
  local new_uuid
  new_uuid=$(uuidgen)

  # Current date/time (adjust format as needed)
  local current_time
  current_time=$(date +"%Y-%m-%d:%H:%M:%S")

  # Always use /var/lib/tethys_persist/ngiab_visualizer as the base directory
  local final_path="/var/lib/tethys_persist/ngiab_visualizer/$base_name"

  jq --arg label "$base_name" \
     --arg path  "$final_path" \
     --arg date  "$current_time" \
     --arg id    "$new_uuid" \
     '.model_runs += [ 
       { 
         "label": $label, 
         "path": $path, 
         "date": $date, 
         "id": $id, 
         "subset": "", 
         "tags": [] 
       }
     ]' \
     "$json_file" > "${json_file}.tmp" && mv -f "${json_file}.tmp" "$json_file"
}

create_tethys_portal(){
    while true; do
        echo -e "${BYellow}Visualize outputs using the Tethys Platform (https://www.tethysplatform.org/)? (Y/n, default: n):${Color_Off}"
        read -r visualization_choice
        
        # Default to 'n' if input is empty
        if [[ -z "$visualization_choice" ]]; then
            visualization_choice="n"
        fi

        # Check for valid input
        if [[ "$visualization_choice" =~ ^[YyNn]$ ]]; then
            break
        else
            echo -e "${BRed}Invalid choice. Please enter 'y' for yes, 'n' for no, or press Enter for default (no).${Color_Off}"
        fi
    done
    
    echo -e "${BYellow}Specify the Tethys image tag to use: ${Color_Off}"
    read -erp "Tag (e.g. v0.2.1, default: latest): " TETHYS_TAG
    if [[ -z "$TETHYS_TAG" ]]; then
        TETHYS_TAG="latest"
    fi

    # Build the full image reference
    TETHYS_IMAGE_NAME="${TETHYS_REPO}:${TETHYS_TAG}"    


    # Execute the command
    if [[ "$visualization_choice" =~ ^[Yy]$ ]]; then
        echo -e "${BGreen}Setting up Tethys Portal image...${Color_Off}"
        _create_tethys_docker_network
        if _check_for_existing_tethys_image; then
            _choose_port_to_run_tethys
            _execute_command _run_containers
            _wait_container $TETHYS_CONTAINER_NAME
            echo -e "${BGreen}Your outputs are ready to be visualized at http://localhost:8080/apps/ngiab ${Color_Off}"
            echo -e "${UPurple}You can use the following to login: ${Color_Off}"
            echo -e "${BCyan}user: admin${Color_Off}"
            echo -e "${BCyan}password: pass${Color_Off}"
            echo -e "${UPurple}Check the App source code: https://github.com/CIROH-UA/ngiab-client ${Color_Off}"
            _pause_script_execution
        else
            echo -e "${BRed}Failed to prepare Tethys portal.\n${Color_Off}"
        fi
    else
        echo -e "${BCyan}Skipping Tethys visualization setup.\n${Color_Off}"
    fi
}


##########################
#####START OF SCRIPT######
##########################

# Set up the SIGINT trap to call the handle_sigint function
trap handle_sigint SIGINT

# Constanst
PLATFORM='linux/amd64'
MODELS_RUNS_DIRECTORY="$HOME/ngiab_visualizer"
VISUALIZER_CONF="$MODELS_RUNS_DIRECTORY/ngiab_visualizer.json"
DATASTREAM_DIRECTORY="$HOME/.datastream_ngiab"
TETHYS_CONTAINER_NAME="tethys-ngen-portal"
DOCKER_NETWORK="tethys-network"
TETHYS_REPO="awiciroh/tethys-ngiab"
TETHYS_TAG="latest"
TETHYS_IMAGE_NAME=""
DATA_FOLDER_PATH="$1"
TETHYS_PERSIST_PATH="/var/lib/tethys_persist"
CONFIG_FILE="$HOME/.host_data_path.conf"
SKIP_DB_SETUP=false
NGINX_TETHYS_PORT=80
CSRF_TRUSTED_ORIGINS="\"[http://localhost:$NGINX_TETHYS_PORT, http://127.0.0.1:$NGINX_TETHYS_PORT]\""


# check for architecture
if uname -a | grep arm64 || uname -a | grep aarch64 ; then
    PLATFORM=linux/arm64
else
    PLATFORM=linux/amd64
fi


check_last_path "$@"

create_tethys_portal
