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
DATA_FOLDER_PATH=""
IMAGE_NAME="awiciroh/ngiab-teehr"
TEEHR_CONTAINER_PREFIX="teehr-evaluation"

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
    local padding=$(( (width - ${#title}) / 2 ))
    
    # Create a more visually appealing section header with light blue background
    echo -e "\n\033[48;5;117m$(printf "%${width}s" " ")\033[0m"
    echo -e "\033[48;5;117m$(printf "%${padding}s" " ")${BBlack}${title}$(printf "%${padding}s" " ")\033[0m"
    echo -e "\033[48;5;117m$(printf "%${width}s" " ")\033[0m\n"
}

# Welcome banner with improved design - fixed formatting
print_welcome_banner() {
    clear
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
    if ! docker info >/dev/null 2>&1; then
        echo -e "  ${CROSS_MARK} ${BRed}Docker daemon is not running, cannot clean up containers.${Color_Off}"
        return 1
    fi
    
    # Find and stop any running TEEHR containers
    local running_containers=$(docker ps -q --filter "ancestor=$IMAGE_NAME")
    if [ -n "$running_containers" ]; then
        echo -e "  ${INFO_MARK} Stopping TEEHR containers..."
        docker stop $running_containers >/dev/null 2>&1 || true
    fi
    
    # Also check for containers with our prefix
    local prefix_containers=$(docker ps -q --filter "name=$TEEHR_CONTAINER_PREFIX")
    if [ -n "$prefix_containers" ]; then
        echo -e "  ${INFO_MARK} Stopping additional TEEHR containers..."
        docker stop $prefix_containers >/dev/null 2>&1 || true
    fi
    
    # Remove any stopped containers matching our criteria
    local all_containers=$(docker ps -a -q --filter "ancestor=$IMAGE_NAME")
    if [ -n "$all_containers" ]; then
        echo -e "  ${INFO_MARK} Removing TEEHR containers..."
        docker rm $all_containers >/dev/null 2>&1 || true
    fi
    
    # Also remove any with our prefix
    local all_prefix_containers=$(docker ps -a -q --filter "name=$TEEHR_CONTAINER_PREFIX")
    if [ -n "$all_prefix_containers" ]; then
        echo -e "  ${INFO_MARK} Removing additional TEEHR containers..."
        docker rm $all_prefix_containers >/dev/null 2>&1 || true
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
        echo -e "  ${ARROW} Use this path? [Y/n]: "
        echo -ne "\r\033[2A"  # Move up 2 lines
        read -e use_last_path
        echo -e "\033[2B"  # Move down 2 lines
        
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
check_last_path() {
    if [[ -z "$1" ]]; then
        check_and_read_config
    else
        DATA_FOLDER_PATH="$1"
        check_if_data_folder_exists
    fi
}

# Main script execution
print_welcome_banner

# Check if data path is provided as argument
check_last_path "$1"

print_section_header "TEEHR EVALUATION SETUP"

echo -e "${INFO_MARK} ${BWhite}TEEHR will evaluate model outputs against observations${Color_Off}"
echo -e "  ${ARROW} Learn more: ${UBlue}https://rtiinternational.github.io/ngiab-teehr/${Color_Off}\n"

echo -e "${ARROW} ${BWhite}Would you like to run a TEEHR evaluation on your model outputs?${Color_Off}"
read -erp "  Run evaluation? [Y/n]: " run_teehr_choice

# Default to 'y' if input is empty
if [[ -z "$run_teehr_choice" ]]; then
    run_teehr_choice="y"
fi

# Execute the TEEHR evaluation if requested
if [[ "$run_teehr_choice" =~ ^[Yy] ]]; then
    # Detect platform architecture for default tag
    if uname -a | grep -q 'arm64\|aarch64'; then
        default_tag="latest" # ARM64 architecture
    else
        default_tag="x86"    # x86 architecture
    fi
    
    echo -e "\n${ARROW} ${BWhite}System architecture detected: ${BCyan}$(uname -m)${Color_Off}"
    echo -e "  ${INFO_MARK} Recommended image tag: ${BCyan}$default_tag${Color_Off}"
    echo -ne "  ${ARROW} Specify TEEHR image tag [default: $default_tag]: "
    read -e teehr_image_tag
    
    if [[ -z "$teehr_image_tag" ]]; then
        teehr_image_tag="$default_tag"
        echo -e "  ${CHECK_MARK} ${BGreen}Using default tag: $default_tag${Color_Off}"
    else
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
                
                if ! docker pull "${IMAGE_NAME}:${teehr_image_tag}"; then
                    handle_error "Failed to pull Docker image: ${IMAGE_NAME}:${teehr_image_tag}"
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
    if ! docker run --name "$CONTAINER_NAME" --rm -v "$DATA_FOLDER_PATH:/app/data" "${IMAGE_NAME}:${teehr_image_tag}"; then
        handle_error "TEEHR evaluation failed"
    fi
    
    print_section_header "EVALUATION COMPLETE"
    
    echo -e "${BG_Green}${BWhite} TEEHR evaluation completed successfully! ${Color_Off}\n"
    echo -e "${INFO_MARK} ${BWhite}Results have been saved to your outputs directory:${Color_Off}"
    echo -e "  ${ARROW} ${BCyan}$DATA_FOLDER_PATH/outputs/teehr/${Color_Off}"
    echo -e "\n${INFO_MARK} You can visualize these results using the Tethys platform"
    echo -e "  ${ARROW} Run ${UBlue}./viewOnTethys.sh $DATA_FOLDER_PATH${Color_Off} to start visualization"
else
    echo -e "\n${INFO_MARK} ${BCyan}Skipping TEEHR evaluation.${Color_Off}"
fi

echo -e "\n${BG_Blue}${BWhite} Thank you for using NGIAB! ${Color_Off}"
echo -e "${INFO_MARK} For support, please email: ${UBlue}ciroh-it-support@ua.edu${Color_Off}\n"

# Clean up any lingering resources before exit
clean_up_resources

exit 0
