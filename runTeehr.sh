#!/bin/bash

# ======================================================================
# CIROH: NextGen In A Box (NGIAB) - TEEHR Evaluation Tool
# Version: 1.4.1
# ======================================================================

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

set -e

# Constants
CONFIG_FILE="$HOME/.host_data_path.conf"
IMAGE_NAME="awiciroh/ngiab-teehr"
TEEHR_CONTAINER_PREFIX="teehr-evaluation"

# Parameters
DOCKER_CMD="docker"
DATA_FOLDER_PATH="" # Path to the model run being evaluated.
FORCED_IMAGE_TAG="" # If non-empty, overrides the normal tag selection process.
DO_STARTUP_PROMPT=true # If false, skips the "Would you like to run a TEEHR evaluation?" prompt.
CLEAR_CONSOLE=true # If true, clears the console when starting execution.
FLAGS_USED=false # Backwards compatibility. If false, uses the first argument as the data directory path.

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
    echo -e "\033[38;5;39m  ╔══════════════════════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[38;5;39m  ║                                                                                          ║\033[0m"
    echo -e "\033[38;5;39m  ║  \033[1;38;5;231mCIROH: NextGen In A Box (NGIAB) - TEEHR Evaluation\033[38;5;39m                                      ║\033[0m"
    echo -e "\033[38;5;39m  ║  \033[1;38;5;231mModel Performance Assessment Tool\033[38;5;39m                                                       ║\033[0m"
    echo -e "\033[38;5;39m  ║                                                                                          ║\033[0m"
    echo -e "\033[38;5;39m  ╚══════════════════════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo -e "\n"
    echo -e "  ${INFO_MARK} \033[1;38;5;231mDeveloped by CIROH\033[0m"
    echo -e "\n"
    sleep 1
}

# Function for error handling
handle_error() {
    echo -e "\n${BG_Red}${BWhite} ERROR: $1 ${Color_Off}"
    clean_up_resources
    exit 1
}

# Function to handle the SIGINT (Ctrl-C)
handle_sigint() {
    echo -e "\n${BG_Red}${BWhite} Operation cancelled by user. Cleaning up... ${Color_Off}"
    clean_up_resources
    exit 1
}

# Clean up resources function
clean_up_resources() {
    echo -e "\n${ARROW} ${BYellow}Cleaning up resources...${Color_Off}"
    
    # Check if Docker daemon is running
    if ! ${DOCKER_CMD} info >/dev/null 2>&1; then
        if [ "${DOCKER_CMD}" == 'docker' ]; then
            echo -e "  ${CROSS_MARK} ${BRed}Docker daemon is not running, cannot clean up containers.${Color_Off}"
        else
            echo -e "  ${CROSS_MARK} ${BRed}Command \"${DOCKER_CMD} info\" failed, container runtime inoperative, cannot clean up containers.${Color_Off}"
        fi
        return 1
    fi
    
    # Find and stop any running TEEHR containers
    local running_containers=$(${DOCKER_CMD} ps -q --filter "ancestor=$IMAGE_NAME")
    if [ -n "$running_containers" ]; then
        echo -e "  ${INFO_MARK} Stopping TEEHR containers..."
        ${DOCKER_CMD} stop $running_containers >/dev/null 2>&1 || true
    fi
    
    # Also check for containers with our prefix
    local prefix_containers=$(${DOCKER_CMD} ps -q --filter "name=$TEEHR_CONTAINER_PREFIX")
    if [ -n "$prefix_containers" ]; then
        echo -e "  ${INFO_MARK} Stopping additional TEEHR containers..."
        ${DOCKER_CMD} stop $prefix_containers >/dev/null 2>&1 || true
    fi
    
    # Remove any stopped containers matching our criteria
    local all_containers=$(${DOCKER_CMD} ps -a -q --filter "ancestor=$IMAGE_NAME")
    if [ -n "$all_containers" ]; then
        echo -e "  ${INFO_MARK} Removing TEEHR containers..."
        ${DOCKER_CMD} rm $all_containers >/dev/null 2>&1 || true
    fi
    
    # Also remove any with our prefix
    local all_prefix_containers=$(${DOCKER_CMD} ps -a -q --filter "name=$TEEHR_CONTAINER_PREFIX")
    if [ -n "$all_prefix_containers" ]; then
        echo -e "  ${INFO_MARK} Removing additional TEEHR containers..."
        ${DOCKER_CMD} rm $all_prefix_containers >/dev/null 2>&1 || true
    fi
    
    echo -e "  ${CHECK_MARK} ${BGreen}Cleanup completed${Color_Off}"
}

# Set up trap for Ctrl-C and EXIT
trap handle_sigint INT
trap clean_up_resources EXIT

# Check if a directory exists
check_if_data_folder_exists() {
    if [ ! -d "$DATA_FOLDER_PATH" ]; then
        handle_error "Directory does not exist: $DATA_FOLDER_PATH"
    fi
}

# Check and read from config file
check_and_read_config() {
    if [ -f "$CONFIG_FILE" ]; then
        LAST_PATH=$(cat "$CONFIG_FILE")
        echo -e "${INFO_MARK} Last used data directory: ${BBlue}$LAST_PATH${Color_Off}"
        read -erp "$(echo -e "  ${ARROW} Use this path? [Y/n]: ")" use_last_path
        
        if [[ -z "$use_last_path" || "$use_last_path" =~ ^[Yy] ]]; then
            DATA_FOLDER_PATH="$LAST_PATH"
            check_if_data_folder_exists
            echo -e "  ${CHECK_MARK} ${BGreen}Using previously configured path${Color_Off}"
        else
            echo -ne "  ${ARROW} Enter your input data directory path: "
            read -e DATA_FOLDER_PATH
            check_if_data_folder_exists
            
            # Save the new path to the config file
            echo "$DATA_FOLDER_PATH" > "$CONFIG_FILE"
            echo -e "  ${CHECK_MARK} ${BGreen}Path saved for future use${Color_Off}"
        fi
    else
        echo -e "${INFO_MARK} ${BYellow}No previous configuration found${Color_Off}"
        echo -ne "  ${ARROW} Enter your input data directory path: "
        read -e DATA_FOLDER_PATH
        check_if_data_folder_exists
        
        # Save the path to the config file
        echo "$DATA_FOLDER_PATH" > "$CONFIG_FILE"
        echo -e "  ${CHECK_MARK} ${BGreen}Path saved for future use${Color_Off}"
    fi
}

# Handle path from arguments or config
handle_data_path() {
    if [[ -z "$DATA_FOLDER_PATH" ]]; then
        check_and_read_config
    else
        check_if_data_folder_exists
    fi
}


print_usage() {
    echo -e "${BYellow}Usage: ${BCyan}runTeehr.sh [arg ...]${Color_Off}"
    echo -e "${BYellow}Options:${Color_Off}"
    echo -e "${BCyan}  -d [path]:${Color_Off} Designates the provided path as the data directory to evaluate."
    echo -e "${BCyan}  -h:${Color_Off} Displays usage information, then exits."
    echo -e "${BCyan}  -i [image]:${Color_Off} Specifies which container image of the TEEHR container to run."
    echo -e "${BCyan}  -p:${Color_Off} Use Podman instead of Docker."
    echo -e "${BCyan}  -r:${Color_Off} Retains previous console output when launching the script."
    echo -e "${BCyan}  -t [tag]:${Color_Off} Specifies which container image tag of the TEEHR container to run."
    echo -e "${BCyan}  -y:${Color_Off} Launches the evaluation workflow immediately, skipping the initial confirmation prompt."
}


# Pre-script execution
while getopts 'd:phrt:y' flag; do
    case "${flag}" in
        d) DATA_FOLDER_PATH="${OPTARG}" ;;
        h) print_usage
           exit 1 ;;
        p) DOCKER_CMD="podman" ;;
        r) CLEAR_CONSOLE=false ;;
        i) IMAGE_NAME="${OPTARG}" ;;
        t) FORCED_IMAGE_TAG="${OPTARG}" ;;
        y) DO_STARTUP_PROMPT=false ;;
        *) echo -e "${CROSS_MARK} ${BRed}ERROR: Unrecognized flag.${Color_Off}"
           print_usage
           exit 1 ;;
    esac
    FLAGS_USED=true
done

# Backwards compatibility: If no flags provided, first argument should be used as data path
if [ "$FLAGS_USED" == false ] && [ -n "$1" ]; then
    DATA_FOLDER_PATH="$1"
fi


# Main script execution

$CLEAR_CONSOLE && clear
print_welcome_banner

print_section_header "TEEHR EVALUATION SETUP"

echo -e "${INFO_MARK} ${BWhite}TEEHR will evaluate model outputs against observations${Color_Off}"
echo -e "  ${ARROW} Learn more: ${UBlue}https://rtiinternational.github.io/ngiab-teehr/${Color_Off}\n"

if [ "$DO_STARTUP_PROMPT" == true ]; then
    echo -e "${ARROW} ${BWhite}Would you like to run a TEEHR evaluation on your model outputs?${Color_Off}"
    read -erp "  Run evaluation? [Y/n]: " run_teehr_choice
else
    run_teehr_choice="y"
fi

# Default to 'y' if input is empty
if [[ -z "$run_teehr_choice" ]]; then
    run_teehr_choice="y"
fi

# Check data directory validity as appropriate
handle_data_path

# Execute the TEEHR evaluation if requested
if [[ "$run_teehr_choice" =~ ^[Yy] ]]; then

    if [[ -z "$FORCED_IMAGE_TAG" ]]; then
    # Detect platform architecture for default tag
        if uname -a | grep -q 'arm64\|aarch64'; then
            default_tag="latest" # ARM64 architecture
        else
            default_tag="x86"    # x86 architecture
        fi
        
        echo -e "\n${ARROW} ${BWhite}System architecture detected: ${BCyan}$(uname -m)${Color_Off}"
        echo -e "  ${INFO_MARK} Recommended image tag: ${BCyan}$default_tag${Color_Off}"
        read -erp "$(echo -ne "  ${ARROW} Specify TEEHR image tag [default: $default_tag]: ")" teehr_image_tag

        if [[ -z "$teehr_image_tag" ]]; then
            teehr_image_tag="$default_tag"
            echo -e "  ${CHECK_MARK} ${BGreen}Using default tag: $default_tag${Color_Off}"
        else
            echo -e "  ${CHECK_MARK} ${BGreen}Using specified tag: $teehr_image_tag${Color_Off}"
        fi
    else
        teehr_image_tag="$FORCED_IMAGE_TAG"
        echo -e "  ${CHECK_MARK} ${BGreen}Using specified tag: $teehr_image_tag${Color_Off}"
    fi

    print_section_header "CONTAINER MANAGEMENT"
    
    echo -e "${ARROW} ${BWhite}Select an option:${Color_Off}\n"
    options=("Run TEEHR using existing local image" "Update to latest TEEHR image" "Exit")
    select option in "${options[@]}"; do
        case $option in
            "Run TEEHR using existing local image")
                echo -e "  ${CHECK_MARK} ${BGreen}Using existing local TEEHR image${Color_Off}"
                break
                ;;
            "Update to latest TEEHR image")
                echo -e "  ${ARROW} ${BYellow}Updating TEEHR image...${Color_Off}"
                show_loading "Downloading latest TEEHR image" 3
                
                if ! ${DOCKER_CMD} pull "${IMAGE_NAME}:${teehr_image_tag}"; then
                    handle_error "Failed to pull container image: ${IMAGE_NAME}:${teehr_image_tag}"
                fi
                
                echo -e "  ${CHECK_MARK} ${BGreen}TEEHR image updated successfully${Color_Off}"
                break
                ;;
            "Exit")
                echo -e "\n${BYellow}Exiting script. Have a nice day!${Color_Off}"
                exit 0
                ;;
            *)
                echo -e "  ${CROSS_MARK} ${BRed}Invalid option $REPLY. Please try again.${Color_Off}"
                ;;
        esac
    done

    print_section_header "RUNNING TEEHR EVALUATION"
    
    echo -e "${INFO_MARK} ${BWhite}Evaluating model outputs in: ${BCyan}$DATA_FOLDER_PATH${Color_Off}"
    echo -e "  ${ARROW} This analysis may take several minutes depending on your dataset size"
    
    show_loading "Initializing TEEHR evaluation" 2
    
    # Create a unique container name
    CONTAINER_NAME="${TEEHR_CONTAINER_PREFIX}-$(date +%s)"
    
    # First clean up any old containers
    clean_up_resources
    
    # Run the TEEHR container with a name for easier cleanup
    if ! ${DOCKER_CMD} run --name "$CONTAINER_NAME" --rm -v "$DATA_FOLDER_PATH:/app/data" "${IMAGE_NAME}:${teehr_image_tag}"; then
        handle_error "TEEHR evaluation failed"
    fi
    
    print_section_header "EVALUATION COMPLETE"
    
    echo -e "${BG_Green}${BWhite} TEEHR evaluation completed successfully! ${Color_Off}\n"
    echo -e "${INFO_MARK} ${BWhite}Results have been saved to your outputs directory:${Color_Off}"
    echo -e "  ${ARROW} ${BCyan}$DATA_FOLDER_PATH/teehr/${Color_Off}"
    echo -e "\n${INFO_MARK} You can visualize these results using the Tethys platform"
    echo -e "  ${ARROW} Run ${UBlue}./viewOnTethys.sh $DATA_FOLDER_PATH${Color_Off} to start visualization"
else
    echo -e "\n${INFO_MARK} ${BCyan}Cancelling TEEHR evaluation.${Color_Off}"
fi

echo -e "\n${BG_Blue}${BWhite} Thank you for using NGIAB! ${Color_Off}"
echo -e "${INFO_MARK} For support, please email: ${UBlue}ciroh-it-support@ua.edu${Color_Off}\n"

# Clean up any lingering resources before exit
clean_up_resources

exit 0
