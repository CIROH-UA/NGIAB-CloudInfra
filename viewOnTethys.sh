#!/bin/bash

# ======================================================================
# CIROH: NextGen In A Box (NGIAB) - Tethys Visualization
# ======================================================================

# Enable debug mode to see what's happening
# set -x

# Color definitions with enhanced palette
BBlack='\033[1;30m'
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

# Extended color palette with 256-color support
LBLUE='\033[38;5;39m'  # Light blue
LGREEN='\033[38;5;83m' # Light green
LPURPLE='\033[38;5;171m' # Light purple
LORANGE='\033[38;5;215m' # Light orange
LTEAL='\033[38;5;87m'  # Light teal

# Background colors for highlighting important messages
BG_Green='\033[42m'
BG_Blue='\033[44m'
BG_Red='\033[41m'
BG_LBLUE='\033[48;5;117m' # Light blue background

# Symbols for better UI
CHECK_MARK="${BGreen}✓${Color_Off}"
CROSS_MARK="${BRed}✗${Color_Off}"
ARROW="${LORANGE}→${Color_Off}"
INFO_MARK="${LBLUE}ℹ${Color_Off}"
WARNING_MARK="${BYellow}⚠${Color_Off}"

# Fix for missing environment variables that might cause display issues
export TERM=xterm-256color

# Constants
CONFIG_FILE="$HOME/.host_data_path.conf"
DOCKER_NETWORK="tethys-network"
TETHYS_CONTAINER_NAME="tethys-ngen-portal"
TETHYS_REPO="docker.io/awiciroh/tethys-ngiab"

MODELS_RUNS_DIRECTORY="${MODELS_RUNS_DIRECTORY:-$HOME/ngiab_visualizer}"
TETHYS_PERSIST_PATH="/home/tethys/persist"

# Parameters
DOCKER_CMD="docker"
# Engine-derived defaults; populated by configure_container_engine() after arg parsing.
USERNS_ARGS=()
NETWORK_ARGS=()
VOLUME_SUFFIX=""
CONTAINER_PORT=8080
WWW_UID=1000  # tethys-uvx base image: the "tethys" user is uid 1000
PORTAL_ALLOWED_HOSTS=""
TETHYS_SECRET_KEY=""
DATA_FOLDER_PATH="" # If non-empty, gets used as the gage path to import.
TETHYS_TAG="" # If non-empty, gets used as the image tag.
IMPORT_GAGE="ask" # "ask"/"yes"/"no"/"done"
CLEAR_CONSOLE=true # If true, clears the console when starting execution.
FLAGS_USED=false # Backwards compatibility. If false, uses the first argument as the data directory path.

# Disable error trapping initially so we can catch and report errors
set +e

# Function for animated loading with gradient colors
show_loading() {
    local message=$1
    local duration=${2:-3}
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local colors=("\033[38;5;39m" "\033[38;5;45m" "\033[38;5;51m" "\033[38;5;87m")
    local end_time=$((SECONDS + duration))

    while [ $SECONDS -lt $end_time ]; do
        for (( i=0; i<${#chars}; i++ )); do
            color_index=$((i % ${#colors[@]}))
            echo -ne "\r${colors[$color_index]}${chars:$i:1}${Color_Off} $message"
            sleep 0.1
        done
    done
    echo -ne "\r${CHECK_MARK} $message - Complete!   \n"
}

# Function for section headers
print_section_header() {
    local title=$1
    local width=70
    local right_padding=$(( (width - ${#title}) / 2 ))
    local left_padding=$(( (width - ${#title}) % 2 + right_padding ))

    # Create a more visually appealing section header with light blue background
    echo -e "\n\033[48;5;117m$(printf "%${width}s" " ")\033[0m"
    echo -e "\033[48;5;117m$(printf "%${left_padding}s" " ")${BBlack}${title}$(printf "%${right_padding}s" " ")\033[0m"
    echo -e "\033[48;5;117m$(printf "%${width}s" " ")\033[0m\n"
}

# Welcome banner with improved design - fixed formatting
print_welcome_banner() {
    echo -e "\n\n"
    echo -e "\033[38;5;39m  ╔═══════════════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[38;5;39m  ║                                                                                   ║\033[0m"
    echo -e "\033[38;5;39m  ║  \033[1;38;5;231mCIROH: NextGen In A Box (NGIAB) - Tethys\033[38;5;39m                                         ║\033[0m"
    echo -e "\033[38;5;39m  ║  \033[1;38;5;231mInteractive Model Output Visualization\033[38;5;39m                                           ║\033[0m"
    echo -e "\033[38;5;39m  ║                                                                                   ║\033[0m"
    echo -e "\033[38;5;39m  ╚═══════════════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo -e "\n"
    echo -e "  ${INFO_MARK} \033[1;38;5;231mDeveloped by CIROH\033[0m"
    echo -e "\n"
    sleep 1
}

# Function for error handling
handle_error() {
    echo -e "\n${BG_Red}${BWhite} ERROR: $1 ${Color_Off}"
    # Save error to log file
    echo "$(date): ERROR: $1" >> ~/ngiab_tethys_error.log

    # Be sure to clean up resources even on error
    tear_down
    exit 1
}

# Function to handle the SIGINT (Ctrl-C)
handle_sigint() {
    echo -e "\n${BG_Red}${BWhite} Operation cancelled by user. Cleaning up... ${Color_Off}"
    tear_down
    exit 1
}

# Set up trap for signal handlers
trap handle_sigint INT TERM
trap 'handle_error "Unexpected error occurred at line $LINENO: $BASH_COMMAND"' ERR

# Detect platform
if uname -a | grep -q 'arm64\|aarch64'; then
    PLATFORM="linux/arm64"
else
    PLATFORM="linux/amd64"
fi

# Main functions
ensure_host_dir() {
    local dir="$1"

    # Create the directory if it doesn't exist
    if [ ! -d "$dir" ]; then
        echo -e "${INFO_MARK} Directory ${BWhite}$dir${Color_Off} doesn't exist - creating it..."
        mkdir -p "$dir" || { echo "Could not create directory $dir"; return 1; }
    fi

    # Get owner UID (portable: Linux uses -c, macOS/BSD uses -f)
    local owner_uid=""
    if owner_uid=$(stat -c '%u' "$dir" 2>/dev/null); then
        :  # GNU stat (Linux)
    elif owner_uid=$(stat -f '%u' "$dir" 2>/dev/null); then
        :  # BSD stat (macOS, Git-Bash)
    fi

    if [[ -n "$owner_uid" && "$owner_uid" != "$(id -u)" ]] && [ ! -w "$dir" ]; then
        if command -v chown >/dev/null 2>&1; then
            # 1) \n guarantees its own line
            # 2) >&2 sends it to stderr (same stream as sudo prompt)
            # 3) sleep 0.1 lets the text reach the terminal before sudo starts
            echo -e "${INFO_MARK} ${BYellow}Reclaiming ownership of $dir " \
                    "(sudo may prompt)...${Color_Off}" >&2
            sleep 0.1
            if ! sudo chown -R "$(id -u):$(id -g)" "$dir"; then
                echo -e "${WARNING_MARK} ${BRed}Could not take ownership of $dir${Color_Off}" >&2
                echo -e "  It is owned by uid $owner_uid and you cannot write to it." >&2
                echo -e "  Fix it once with:" >&2
                echo -e "    ${BWhite}sudo chown -R $(id -u):$(id -g) $dir${Color_Off}" >&2
                echo -e "  or point the launcher elsewhere:" >&2
                echo -e "    ${BWhite}MODELS_RUNS_DIRECTORY=~/my_runs $0${Color_Off}" >&2
                return 1
            fi
        fi
    fi

    # Ensure the current user has rwx on the directory
    chmod u+rwx "$dir" || { echo "Could not set directory permissions on $dir"; return 1; }
    return 0
}


configure_container_engine() {
    if [ "${DOCKER_CMD}" != "podman" ]; then
        NETWORK_ARGS=(--network "$DOCKER_NETWORK")
        return 0
    fi
    USERNS_ARGS=(--userns=keep-id:uid=${WWW_UID})
    VOLUME_SUFFIX=":Z"
}

create_tethys_docker_network() {
    if [ "${DOCKER_CMD}" == "podman" ]; then
        return 0
    fi

    echo -e "${INFO_MARK} Setting up Docker network for Tethys..."

    # Check if Docker daemon is running
    if ! ${DOCKER_CMD} info >/dev/null 2>&1; then
        echo -e "${BRed}Docker daemon is not running or accessible.${Color_Off}"
        return 1
    fi

    # Check if network already exists
    if ${DOCKER_CMD} network inspect "$DOCKER_NETWORK" >/dev/null 2>&1; then
        echo -e "  ${CHECK_MARK} Network ${BCyan}$DOCKER_NETWORK${Color_Off} already exists."
        return 0
    fi

    # Create the network
    if ${DOCKER_CMD} network create -d bridge "$DOCKER_NETWORK" >/dev/null 2>&1; then
        echo -e "  ${CHECK_MARK} Network ${BCyan}$DOCKER_NETWORK${Color_Off} created successfully."
        # Add a small delay to ensure network is fully created
        sleep 1
        return 0
    else
        echo -e "  ${CROSS_MARK} ${BRed}Failed to create Docker network.${Color_Off}"
        return 1
    fi
}

set_tethys_tag() {
    if [[ -z "$TETHYS_TAG" ]]; then
        echo -e "${Color_Off}${BBlue}Specify the Tethys image tag to use: ${Color_Off}"
        read -erp "$(echo -e "  ${ARROW} Tag (e.g. v0.2.1, default: latest): ")" TETHYS_TAG
        if [[ -z "$TETHYS_TAG" ]]; then
            TETHYS_TAG="latest"
        fi
    fi
}

check_for_existing_tethys_image() {
    if ! ${DOCKER_CMD} info >/dev/null 2>&1; then
        echo -e "${BRed}Docker daemon is not running or accessible.${Color_Off}"
        return 1
    fi

    local image_exists=false
    if ${DOCKER_CMD} image inspect "${TETHYS_REPO}:${TETHYS_TAG}" >/dev/null 2>&1; then
        image_exists=true
    fi

    if [ "$image_exists" = true ]; then
        echo -e "  ${CHECK_MARK} ${BGreen}Using local Tethys image: ${TETHYS_REPO}:${TETHYS_TAG}${Color_Off}"
        return 0
    else
        echo -e "  ${INFO_MARK} ${BYellow}Tethys image not found locally. Pulling from registry...${Color_Off}"
        show_loading "Downloading Tethys image" 3
        if ! ${DOCKER_CMD} pull "${TETHYS_REPO}:${TETHYS_TAG}"; then
            echo -e "  ${CROSS_MARK} ${BRed}Failed to pull Docker image: ${TETHYS_REPO}:${TETHYS_TAG}${Color_Off}"
            return 1
        fi
        echo -e "  ${CHECK_MARK} ${BGreen}Tethys image downloaded successfully${Color_Off}"
        return 0
    fi
}


port_in_use() {
    local port="$1"
    if command -v ss >/dev/null 2>&1; then
        ss -ltn "sport = :${port}" 2>/dev/null | grep -q LISTEN && return 0
        return 1
    fi
    if command -v lsof >/dev/null 2>&1; then
        lsof -i:"${port}" >/dev/null 2>&1 && return 0
    fi
    return 1
}

choose_port_to_run_tethys() {
    local default_port=8080
    while true; do
        echo -e "${BBlue}Select a port to run Tethys on. [Default: ${default_port}] ${Color_Off}"
        read -erp "$(echo -e "  ${ARROW} Port: ")" nginx_tethys_port

        if [[ -z "$nginx_tethys_port" ]]; then
            nginx_tethys_port=${default_port}
            echo -e "${ARROW} ${BWhite}Using default port ${default_port} for Tethys.${Color_Off}"
        fi

        # Validate numeric port 1-65535
        if ! [[ "$nginx_tethys_port" =~ ^[0-9]+$ ]] || \
           [ "$nginx_tethys_port" -lt 1 ] || [ "$nginx_tethys_port" -gt 65535 ]; then
            echo -e "${BRed}Invalid port number. Please enter 1-65535.${Color_Off}"
            continue
        fi

        if port_in_use "$nginx_tethys_port"; then
            echo -e "${BRed}Port $nginx_tethys_port is already in use. Choose another.${Color_Off}"
            continue
        fi

        break
    done

    local host_ips
    host_ips=$(hostname -I 2>/dev/null || ip -4 -o addr show 2>/dev/null | awk '{split($4,a,"/"); print a[1]}' | tr '\n' ' ' || echo)
    local allowed_list="localhost,127.0.0.1"
    for ip in $host_ips; do
        case "$ip" in
            127.*|"") ;;  # skip loopback duplicates and empties
            *)
                allowed_list="${allowed_list},$ip"
                ;;
        esac
    done
    PORTAL_ALLOWED_HOSTS="${allowed_list}"

    if [ -z "${TETHYS_SECRET_KEY:-}" ]; then
        TETHYS_SECRET_KEY=$(head -c 32 /dev/urandom | base64 | tr -d '=+/' 2>/dev/null)
        if [ -z "$TETHYS_SECRET_KEY" ]; then
            TETHYS_SECRET_KEY="ngiab-fallback-$(date +%s)-$$"
        fi
    fi

    echo -e "  ${CHECK_MARK} ${BGreen}Port $nginx_tethys_port selected${Color_Off}"

    return 0
}

wait_container_healthy() {
    local container_name=$1

    local has_healthcheck
    has_healthcheck=$(${DOCKER_CMD} inspect -f '{{if .State.Health}}yes{{else}}no{{end}}' "$container_name" 2>/dev/null)

    if [ "$has_healthcheck" = "yes" ]; then
        echo -e "${INFO_MARK} ${BWhite} Waiting for container: $container_name to become healthy. This can take a couple of minutes...${Color_Off}"
        while true; do
            local container_health_status
            container_health_status=$(${DOCKER_CMD} inspect -f '{{.State.Health.Status}}' "$container_name" 2>/dev/null)
            if [ $? -ne 0 ]; then
                echo -e "\n ${WARNING_MARK} ${BG_Red}${BWhite} Failed to get health status for container $container_name. ${Color_Off}"
                return 1
            fi
            if [[ "$container_health_status" == "healthy" ]]; then
                echo -e "\n ${CHECK_MARK} ${BG_Green}${BWhite} Container $container_name is now healthy! ${Color_Off}"
                return 0
            elif [[ "$container_health_status" == "unhealthy" ]]; then
                echo -e "\n ${WARNING_MARK} ${BG_Red}${BWhite} Container $container_name is unhealthy! ${Color_Off}"
                return 0
            fi
            sleep 2
        done
    fi

    echo -e "${INFO_MARK} ${BWhite} Image has no healthcheck; polling http://127.0.0.1:${nginx_tethys_port}/ for readiness (max 5 min)...${Color_Off}"
    local max_wait=300
    local elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        if curl -sf --max-time 3 -o /dev/null "http://127.0.0.1:${nginx_tethys_port}/" 2>/dev/null; then
            echo -e "\n ${CHECK_MARK} ${BG_Green}${BWhite} Container $container_name is serving requests! ${Color_Off}"
            return 0
        fi
        local running
        running=$(${DOCKER_CMD} inspect -f '{{.State.Running}}' "$container_name" 2>/dev/null)
        if [ "$running" != "true" ]; then
            echo -e "\n ${WARNING_MARK} ${BG_Red}${BWhite} Container $container_name is no longer running. ${Color_Off}"
            return 1
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done
    echo -e "\n ${WARNING_MARK} ${BG_Red}${BWhite} Timed out waiting for $container_name to respond on port ${nginx_tethys_port}. ${Color_Off}"
    return 1
}

run_tethys() {
    ensure_host_dir "$MODELS_RUNS_DIRECTORY"

    echo -e "${ARROW} ${BWhite}Launching Tethys container...${Color_Off}"

    # First, make sure any existing Tethys containers are stopped
    if ${DOCKER_CMD} ps -q -f name="$TETHYS_CONTAINER_NAME" >/dev/null 2>&1; then
        echo -e "  ${INFO_MARK} ${BYellow}Tethys container is already running. Stopping it first...${Color_Off}"
        ${DOCKER_CMD} stop "$TETHYS_CONTAINER_NAME" >/dev/null 2>&1
        sleep 3
    fi

    # Final check - if container still exists, force removal
    if ${DOCKER_CMD} ps -a -q -f name="$TETHYS_CONTAINER_NAME" >/dev/null 2>&1; then
        echo -e "  ${WARNING_MARK} ${BYellow}Forcibly removing container...${Color_Off}"
        ${DOCKER_CMD} rm -f "$TETHYS_CONTAINER_NAME" >/dev/null 2>&1 || true
        sleep 2
    fi

    # Create new network
    create_tethys_docker_network

    # Brief delay before starting
    sleep 1
    echo -e "  ${INFO_MARK} ${BYellow}Starting Tethys container...${Color_Off}"

    echo -e "  ${INFO_MARK} Running ${DOCKER_CMD} command..."
    ${DOCKER_CMD} run --rm -d \
        "${USERNS_ARGS[@]}" \
        -v "$MODELS_RUNS_DIRECTORY:$TETHYS_PERSIST_PATH/ngiab_visualizer${VOLUME_SUFFIX}" \
        -p "$nginx_tethys_port:$CONTAINER_PORT" \
        "${NETWORK_ARGS[@]}" \
        --name "$TETHYS_CONTAINER_NAME" \
        --env TETHYS_PERSIST="$TETHYS_PERSIST_PATH" \
        --env MEDIA_ROOT="$TETHYS_PERSIST_PATH/media" \
        --env MEDIA_URL="/media/" \
        --env PORT="$CONTAINER_PORT" \
        --env PORTAL_ALLOWED_HOSTS="$PORTAL_ALLOWED_HOSTS" \
        --env TETHYS_SECRET_KEY="$TETHYS_SECRET_KEY" \
        "${TETHYS_REPO}:${TETHYS_TAG}"

    if [ $? -eq 0 ]; then
        echo -e "  ${CHECK_MARK} ${BGreen}Tethys container started successfully.${Color_Off}"
        return 0
    else
        echo -e "  ${CROSS_MARK} ${BRed}Failed to start Tethys container.${Color_Off}"
        return 1
    fi
}

# ──────────────────────────────────────────────────────────────────────
# Decide whether to use the local Tethys image or pull an update
# ──────────────────────────────────────────────────────────────────────
select_tethys_image_source() {
    # Bail out early if Docker is unavailable
    if ! ${DOCKER_CMD} info >/dev/null 2>&1; then
        echo -e "  ${CROSS_MARK} ${BRed}Docker daemon not running.${Color_Off}"
        return 1
    fi

    local image_ref="${TETHYS_REPO}:${TETHYS_TAG}"

    # Does the image already exist locally?
    if ${DOCKER_CMD} image inspect "$image_ref" >/dev/null 2>&1; then
        echo -e "  ${INFO_MARK} Found local image ${BCyan}$image_ref${Color_Off}"
        if [ ! -r /dev/tty ]; then
            echo -e "  ${INFO_MARK} No terminal to prompt on; using the local image."
            return 0
        fi
        while true; do
            echo -ne "  ${ARROW} Use local copy (L) or Pull latest from registry (P)? [L/P]: "
            read -r decision < /dev/tty || {
                echo -e "\n  ${INFO_MARK} Could not read a choice; using the local image."
                return 0
            }
            case "$decision" in
                [Ll]* )
                    echo -e "  ${CHECK_MARK} Using local image" ; return 0 ;;
                [Pp]* )
                    echo -e "  ${INFO_MARK} ${BYellow}Pulling image - this may take a moment...${Color_Off}"
                    show_loading "Downloading Tethys image" 3
                    ${DOCKER_CMD} pull "$image_ref" && return 0
                    echo -e "  ${CROSS_MARK} ${BRed}Failed to pull $image_ref${Color_Off}"
                    return 1 ;;
                * )
                    echo -e "  ${CROSS_MARK} ${BRed}Invalid choice. Enter 'L' or 'P'.${Color_Off}" ;;
            esac
        done
    else
        # No local image - pull automatically
        echo -e "  ${INFO_MARK} ${BYellow}Image not found locally - pulling $image_ref...${Color_Off}"
        show_loading "Downloading Tethys image" 3
        ${DOCKER_CMD} pull "$image_ref" && return 0
        echo -e "  ${CROSS_MARK} ${BRed}Failed to pull $image_ref${Color_Off}"
        return 1
    fi
}

tear_down() {
    echo -e "\n${ARROW} ${BYellow}Cleaning up resources...${Color_Off}"

    # Check if Docker daemon is running
    if ! ${DOCKER_CMD} info >/dev/null 2>&1; then
        echo -e "  ${CROSS_MARK} ${BRed}Docker daemon is not running, cannot clean up containers.${Color_Off}"
        return 1
    fi

    # Stop the Tethys container if it's running
    if ${DOCKER_CMD} ps -q -f name="$TETHYS_CONTAINER_NAME" >/dev/null 2>&1; then
        echo -e "  ${INFO_MARK} Stopping Tethys container..."
        ${DOCKER_CMD} stop "$TETHYS_CONTAINER_NAME" >/dev/null 2>&1
        sleep 2
    fi

    # Remove the Docker network if it exists
    if ${DOCKER_CMD} network inspect "$DOCKER_NETWORK" >/dev/null 2>&1; then
        echo -e "  ${INFO_MARK} Removing Docker network..."
        ${DOCKER_CMD} network rm "$DOCKER_NETWORK" >/dev/null 2>&1 || true
    fi

    echo -e "  ${CHECK_MARK} ${BGreen}Cleanup completed${Color_Off}"
    return 0
}

prompt_fresh_start() {
    # ────────────────────────────────────────────────────────────────────
    # 0. Top-level directory already contains runs?  Ask user what to do.
    # ────────────────────────────────────────────────────────────────────
    if [ -d "$models_dir" ] && [ -n "$(ls -A "$models_dir" 2>/dev/null)" ]; then
        echo -e "  ${WARNING_MARK} ${BYellow}$models_dir is not empty.${Color_Off}" >&2
        while true; do
            echo -ne "  ${ARROW} Keep (K) or Fresh start (F)? [K/F]: " >&2
            read -r keep_choice < /dev/tty
            case "$keep_choice" in
                [Kk]* ) break ;;   # keep as-is
                [Ff]* )
                    echo -e "  ${INFO_MARK} ${BYellow}Removing previous runs..." \
                            "${LBLUE}(sudo may be required)${Color_Off}" >&2
                    rm -rf "${models_dir:?}/"* 2>/dev/null || sudo rm -rf "${models_dir:?}/"*
                    break ;;
                * ) echo -e "  ${CROSS_MARK} ${BRed}Invalid choice.${Color_Off}" >&2 ;;
            esac
        done
    fi
}

copy_models_run() {
    local input_path="$1"
    local models_dir="$MODELS_RUNS_DIRECTORY"

    # ────────────────────────────────────────────────────────────────────
    # 1. Ensure ~/ngiab_visualizer exists & is writable
    # ────────────────────────────────────────────────────────────────────
    ensure_host_dir "$models_dir" || {
        echo -e "  ${CROSS_MARK} ${BRed}Cannot access $models_dir${Color_Off}" >&2
        return 1
    }

    # 2. Figure out target paths
    local base_name
    base_name="$(basename "$input_path")"
    local model_run_path="$models_dir/$base_name"
    local final_copied_path="$model_run_path"

    # 3. Copy / overwrite / duplicate - user-driven
    if [ ! -e "$model_run_path" ]; then
        cp -r "$input_path" "$models_dir/" || {
            echo -e "  ${CROSS_MARK} ${BRed}Copy failed${Color_Off}" >&2 ; return 1 ; }
        echo -e "  ${CHECK_MARK} ${BCyan}Copied${Color_Off} ➜ $model_run_path" >&2
    else
        echo -e "  ${WARNING_MARK} ${BYellow}Directory exists:${Color_Off} $model_run_path" >&2
        while true; do
            echo -ne "  ${ARROW} Overwrite (O) or Duplicate (D)? [O/D]: " >&2
            read -r choice < /dev/tty
            case "$choice" in
                [Oo]* )
                    rm -rf "$model_run_path" 2>/dev/null || sudo rm -rf "$model_run_path"
                    cp -r "$input_path" "$models_dir/" || {
                        echo -e "  ${CROSS_MARK} ${BRed}Overwrite failed${Color_Off}" >&2 ; return 1 ; }
                    echo -e "  ${CHECK_MARK} ${BCyan}Overwritten${Color_Off} ➜ $model_run_path" >&2
                    break ;;
                [Dd]* )
                    echo -ne "  ${ARROW} ${BBlue}New directory name:${Color_Off} " >&2
                    read -r new_name < /dev/tty
                    [[ -z "$new_name" ]] && { echo -e "  ${CROSS_MARK} ${BRed}No name entered${Color_Off}" >&2 ; continue ; }
                    local new_path="$models_dir/$new_name"
                    if [ -e "$new_path" ]; then
                        echo -e "  ${CROSS_MARK} ${BRed}'$new_name' already exists${Color_Off}" >&2
                        continue
                    fi
                    cp -r "$input_path" "$new_path" || {
                        echo -e "  ${CROSS_MARK} ${BRed}Copy failed${Color_Off}" >&2 ; return 1 ; }
                    echo -e "  ${CHECK_MARK} ${BPurple}Copied to${Color_Off} ➜ $new_path" >&2
                    final_copied_path="$new_path"
                    break ;;
                * ) echo -e "  ${CROSS_MARK} ${BRed}Invalid choice. Enter 'O' or 'D'.${Color_Off}" >&2 ;;
            esac
        done
    fi

    # 4. Return the final path
    echo "$final_copied_path"
}

# Convert the copied run's ngen CSV outputs to parquet.
convert_run_outputs() {
    local final_path="$1"

    local image="${TETHYS_REPO}:${TETHYS_TAG:-latest}"
    if ! ${DOCKER_CMD} image inspect "$image" >/dev/null 2>&1; then
        echo -e "  ${INFO_MARK} Image $image not present locally; leaving outputs as CSV."
        return 0
    fi

    echo -e "  ${ARROW} ${BCyan}Converting outputs to parquet...${Color_Off}"
    if ${DOCKER_CMD} run --rm \
        "${USERNS_ARGS[@]}" \
        -v "$MODELS_RUNS_DIRECTORY:$TETHYS_PERSIST_PATH/ngiab_visualizer${VOLUME_SUFFIX}" \
        --env TETHYS_SECRET_KEY="${TETHYS_SECRET_KEY:-conversion-only}" \
        --entrypoint /usr/local/bin/ngiab-convert.sh \
        "$image" \
        --path "$final_path"; then
        echo -e "  ${CHECK_MARK} ${BCyan}Outputs converted.${Color_Off}"
    else
        # Non-fatal: the app reads CSV too, so a failed conversion costs speed, not function.
        echo -e "  ${WARNING_MARK} ${BYellow}Conversion failed; the run will be read as CSV.${Color_Off}"
    fi
}

# Prepare a copied run for the visualizer.
prepare_model_run() {
    local final_path="$TETHYS_PERSIST_PATH/ngiab_visualizer/$(basename "$1")"
    convert_run_outputs "$final_path"
}

print_visualization_urls() {
    # Single-app mode (MULTIPLE_APP_MODE false in conf/portal_config.yml) serves the app at
    # the root; there is no /apps/<name>/ prefix to print.
    local app_path=""
    local is_wsl=false
    grep -qi microsoft /proc/version 2>/dev/null && is_wsl=true

    # Only the IP of the default-route interface -- skips docker bridges,
    # minikube/k3s vifs, and other noise that hostname -I returns.
    local primary_ip default_iface
    default_iface=$(ip -4 route show default 2>/dev/null | awk '/default/ {print $5; exit}')
    if [ -n "$default_iface" ]; then
        primary_ip=$(ip -4 -o addr show dev "$default_iface" 2>/dev/null | awk '{split($4,a,"/"); print a[1]; exit}')
    fi

    echo -e "${INFO_MARK} Access the visualization at:"

    if [ "${DOCKER_CMD}" = "podman" ]; then
        if [ -n "$primary_ip" ] && [ "$primary_ip" != "127.0.0.1" ]; then
            echo -e "  ${ARROW} ${UBlue}http://${primary_ip}:${nginx_tethys_port}${app_path}${Color_Off}"
        fi
        echo -e "  ${ARROW} ${UBlue}http://127.0.0.1:${nginx_tethys_port}${app_path}${Color_Off}  ${BWhite}(loopback)${Color_Off}"
        if [ "${is_wsl}" = true ]; then
            echo -e "  ${INFO_MARK} ${BWhite}On WSL+Podman, the host-IP URL above is the most reliable; localhost is intentionally not listed.${Color_Off}"
        else
            echo -e "  ${INFO_MARK} ${BWhite}Rootless Podman does not bind 'localhost' reliably; use an address above.${Color_Off}"
        fi
    else
        echo -e "  ${ARROW} ${UBlue}http://localhost:${nginx_tethys_port}${app_path}${Color_Off}"
        echo -e "  ${ARROW} ${UBlue}http://127.0.0.1:${nginx_tethys_port}${app_path}${Color_Off}"
        if [ -n "$primary_ip" ] && [ "$primary_ip" != "127.0.0.1" ]; then
            echo -e "  ${ARROW} ${UBlue}http://${primary_ip}:${nginx_tethys_port}${app_path}${Color_Off}"
        fi
    fi
}

pause_script_execution() {
    echo -e "\n${BG_Blue}${BWhite} Tethys is now running ${Color_Off}"
    print_visualization_urls
    echo -e "${INFO_MARK} Press ${BWhite}Ctrl+C${Color_Off} to stop Tethys when you're done."

    # Keep script running until user interrupts
    while true; do
        sleep 10
    done
}

print_usage() {
    echo -e "${BYellow}Usage: ${BCyan}viewOnTethys.sh [arg ...]${Color_Off}"
    echo -e "${BYellow}Options:${Color_Off}"
    echo -e "${BCyan}  -d [path]:${Color_Off} Designates the provided path as the data directory to import into the visualizer."
    echo -e "${BCyan}  -h:${Color_Off} Displays usage information, then exits."
    echo -e "${BCyan}  -i [image]:${Color_Off} Specifies which container image of the visualizer to run."
    echo -e "${BCyan}  -n:${Color_Off} Launches the visualizer immediately without importing a data directory."
    echo -e "${BCyan}  -p:${Color_Off} Use Podman instead of Docker."
    echo -e "${BCyan}  -r:${Color_Off} Retains previous console output when launching the script."
    echo -e "${BCyan}  -t [tag]:${Color_Off} Specifies which container image tag of the visualizer to run."
    echo -e "${BCyan}  -y:${Color_Off} Immediately requests to import a data directory."
}

# Pre-script execution
while getopts 'd:hi:nprt:y' flag; do
    case "${flag}" in
        d) DATA_FOLDER_PATH="${OPTARG}" ;;
        h) print_usage
           exit 1 ;;
        i) TETHYS_REPO="${OPTARG}" ;;
        n) IMPORT_GAGE="no";;
        p) DOCKER_CMD="podman" ;;
        r) CLEAR_CONSOLE=false ;;
        t) TETHYS_TAG="${OPTARG}" ;;
        y) IMPORT_GAGE="yes" ;;
        *) echo -e "${CROSS_MARK} ${BRed}ERROR: Unrecognized flag.${Color_Off}"
           print_usage
           exit 1 ;;
    esac
    FLAGS_USED=true
done

if [ -n "$DATA_FOLDER_PATH" ] && [ "$IMPORT_GAGE" == "no" ]; then
    echo -e "${CROSS_MARK} ${BRed}ERROR: Flags -d and -n are incompatible.${Color_Off}"
    print_usage
    exit 1
fi

# Populate USERNS_ARGS, VOLUME_SUFFIX, NETWORK_ARGS based on -p flag selection.
configure_container_engine

# Backwards compatibility: If no flags provided, first argument should be used as data path
if [ "$FLAGS_USED" == false ] && [ -n "$1" ]; then
    DATA_FOLDER_PATH="$1"
fi

# Main script execution
$CLEAR_CONSOLE && clear
print_welcome_banner

# Check if a data path should be added
while [[ -z "$DATA_FOLDER_PATH" && $IMPORT_GAGE == "ask" ]]; do
    read -erp "$(echo -e "  ${ARROW} Import a NextGen model run? [Y/n]: ")" import_choice
    if [[ "$import_choice" =~ ^[Yy] ]]; then
        IMPORT_GAGE="yes"
    elif [[ "$import_choice" =~ ^[Nn] ]]; then
        echo -e "    ${CHECK_MARK} ${BGreen}Skipping NextGen model import.${Color_Off}"
        IMPORT_GAGE="no"
    else
        echo -e "    ${CROSS_MARK} ${BRed}Invalid input.${Color_Off}"
    fi
done

# Check if data path is provided as argument
if [[ -z "$DATA_FOLDER_PATH" && $IMPORT_GAGE == "yes" ]]; then
    # If no path provided, check if we have a saved path
    if [ -f "$CONFIG_FILE" ]; then
        LAST_PATH=$(cat "$CONFIG_FILE")
        echo -e "${INFO_MARK} Last used data directory: ${BBlue}$LAST_PATH${Color_Off}"
        read -erp "$(echo -e "  ${ARROW} Use this path? [Y/n]: ")" use_last_path

        if [[ -z "$use_last_path" || "$use_last_path" =~ ^[Yy] ]]; then
            DATA_FOLDER_PATH="$LAST_PATH"
            echo -e "  ${CHECK_MARK} ${BGreen}Using previously configured path${Color_Off}"
        else
            echo -ne "  ${ARROW} Enter your input data directory path: "
            read -e DATA_FOLDER_PATH
        fi
    else
        echo -e "${INFO_MARK} ${BYellow}No previous configuration found.${Color_Off}"
        echo -ne "  ${ARROW} Enter your input data directory path: "
        read -e DATA_FOLDER_PATH
    fi

    # Save the new path
    echo "$DATA_FOLDER_PATH" > "$CONFIG_FILE"
    echo -e "  ${CHECK_MARK} ${BGreen}Path saved for future use.${Color_Off}"
fi

# Validate the directory
if [[ -n "$DATA_FOLDER_PATH" && ! -d "$DATA_FOLDER_PATH" ]]; then
    echo -e "${CROSS_MARK} ${BRed}Directory does not exist: $DATA_FOLDER_PATH${Color_Off}"
    exit 1
fi

print_section_header "PREPARING VISUALIZATION ENVIRONMENT"

# If visualization directory is non-empty, offer a fresh start option
prompt_fresh_start

# If importing a model run...
if [ -n "$DATA_FOLDER_PATH" ]; then
    # Copy model data to visualization directory
    final_dir=$(copy_models_run "$DATA_FOLDER_PATH") || {
        echo -e "${CROSS_MARK} ${BRed}Failed to copy model data. Exiting.${Color_Off}"
        exit 1
    }

    prepare_model_run "$final_dir" || {
        echo -e "${CROSS_MARK} ${BRed}Failed to prepare the model run. Exiting.${Color_Off}"
        exit 1
    }
    echo -e "  ${INFO_MARK} ${BCyan}It appears in the visualizer's run picker once the portal is up.${Color_Off}"
fi

print_section_header "LAUNCHING TETHYS VISUALIZATION"

# Select Tethys image
set_tethys_tag

select_tethys_image_source || {
    echo -e "${CROSS_MARK} ${BRed}Unable to obtain Tethys image. Exiting.${Color_Off}"
    exit 1
}


choose_port_to_run_tethys
run_tethys || {
    echo -e "${CROSS_MARK} ${BRed}Failed to start Tethys container. Exiting.${Color_Off}"
    exit 1
}

# Wait for container to be ready
wait_container_healthy "$TETHYS_CONTAINER_NAME" || {
    echo -e "${CROSS_MARK} ${BRed}Tethys container failed to start properly. Exiting.${Color_Off}"
    exit 1
}

print_section_header "VISUALIZATION READY"

echo -e "${BG_Green}${BWhite} Your model outputs are now available for visualization! ${Color_Off}\n"
print_visualization_urls
# The portal runs open (ENABLE_OPEN_PORTAL), so the map needs no sign-in. The admin
# account still exists for /admin/, which is why it is worth mentioning at all.
echo -e "${INFO_MARK} Viewing needs no sign-in. Uploading or deleting a run does: sign in as ${BWhite}admin / pass${Color_Off} from the account card."
echo -e "\n${INFO_MARK} Source code: ${UBlue}https://github.com/CIROH-UA/ngiab-client${Color_Off}"

# Keep the script running
pause_script_execution

exit 0
