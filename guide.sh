#!/bin/bash

# ======================================================================
# CIROH: NextGen In A Box (NGIAB)
# Version: 1.4.3
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

CONFIG_FILE="$HOME/.host_data_path.conf"
TETHYS_SCRIPT="./viewOnTethys.sh"
TEEHR_SCRIPT="./runTeehr.sh"

# Container and image constants
NGEN_IMAGE_NAME="awiciroh/ciroh-ngen-image"
NGEN_IMAGE_TAG="latest"
# (The rest of these are solely used to manage shutdowns)
DOCKER_NETWORK="tethys-network"
TETHYS_CONTAINER_NAME="tethys-ngen-portal"
TETHYS_IMAGE_NAME="awiciroh/tethys-ngiab"
TEEHR_IMAGE_NAME="awiciroh/ngiab-teehr"

# Parameters
DATA_FOLDER_PATH="" # Path to the model run being evaluated.
DO_STARTUP_PROMPT=true # If false, skips the "Would you like to run a TEEHR evaluation?" prompt.
FLAGS_USED=false # Backwards compatibility. If false, uses the first argument as the data directory path.
CUSTOM_TAG_USED=false # Used to provide direct feedback if a custom tag is used.

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

# Welcome banner with improved design
print_welcome_banner() {
    echo -e "\n\n"
    echo -e "\033[38;5;39m  ╔══════════════════════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[38;5;39m  ║                                                                                          ║\033[0m"
    echo -e "\033[38;5;39m  ║  \033[1;38;5;231mCIROH: NextGen In A Box (NGIAB)\033[38;5;39m                                                         ║\033[0m"
    echo -e "\033[38;5;39m  ║  \033[1;38;5;231mAdvanced Hydrologic Modeling Tool\033[38;5;39m                                                       ║\033[0m"
    echo -e "\033[38;5;39m  ║                                                                                          ║\033[0m"
    echo -e "\033[38;5;39m  ╚══════════════════════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo -e "\n"
    echo -e "  ${ARROW} \033[1;38;5;39mVisit our website: \033[4;38;5;87mhttps://ngiab.ciroh.org\033[0m"
    echo -e "  ${INFO_MARK} \033[1;38;5;231mDeveloped by CIROH & Lynker\033[0m"
    echo -e "\n"
    sleep 1
}

# Cleanup function for all resources
clean_up_resources() {
    echo -e "\n${ARROW} ${BYellow}Cleaning up resources...${Color_Off}"
    
    # Stop any running TEEHR containers
    local teehr_containers=$(docker ps -q --filter "ancestor=$TEEHR_IMAGE_NAME" 2>/dev/null)
    if [ -n "$teehr_containers" ]; then
        echo -e "  ${INFO_MARK} Stopping TEEHR containers..."
        docker stop $teehr_containers >/dev/null 2>&1
    fi
    
    # Stop the Tethys container if it's running
    if docker ps -q -f name="$TETHYS_CONTAINER_NAME" >/dev/null 2>&1; then
        echo -e "  ${INFO_MARK} Stopping Tethys container..."
        docker stop "$TETHYS_CONTAINER_NAME" >/dev/null 2>&1
    fi
    
    # Remove the Docker network
    if docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1; then
        echo -e "  ${INFO_MARK} Removing Docker network..."
        docker network rm "$DOCKER_NETWORK" >/dev/null 2>&1
    fi
    
    # Check for other containers using our images and stop them
    local ngen_containers=$(docker ps -q --filter "ancestor=$NGEN_IMAGE_NAME" 2>/dev/null)
    if [ -n "$ngen_containers" ]; then
        echo -e "  ${INFO_MARK} Stopping NGEN containers..."
        docker stop $ngen_containers >/dev/null 2>&1
    fi
    
    echo -e "  ${CHECK_MARK} ${BGreen}Cleanup completed.${Color_Off}"
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

# Set up trap for Ctrl-C and regular exit
trap handle_sigint SIGINT
trap clean_up_resources EXIT


print_usage() {
    echo -e "${BYellow}Usage: ${BCyan}guide.sh [arg ...]${Color_Off}"
    echo -e "${BYellow}Options:${Color_Off}"
    echo -e "${BCyan}  -d [path]:${Color_Off} Designates the provided path as the data directory to import into the visualizer."
    echo -e "${BCyan}  -h:${Color_Off} Displays usage information, then exits."
    echo -e "${BCyan}  -i [image]:${Color_Off} Specifies which Docker image of NGIAB to run."
    echo -e "${BCyan}  -r:${Color_Off} Retains previous console output when launching the script."
    echo -e "${BCyan}  -t [tag]:${Color_Off} Specifies which Docker image tag of NGIAB to run."
}


# Pre-script execution
while getopts 'd:hi:rt:' flag; do
    case "${flag}" in
        d) HOST_DATA_PATH="${OPTARG}" ;;
        h) print_usage
           exit 1 ;;
        i) NGEN_IMAGE_NAME="${OPTARG}" ;;
        r) CLEAR_CONSOLE=false ;;
        t) NGEN_IMAGE_TAG="${OPTARG}"
           CUSTOM_TAG_USED=true ;;
        *) echo -e "${CROSS_MARK} ${BRed}ERROR: Unrecognized flag.${Color_Off}"
           print_usage
           exit 1 ;;
    esac
    FLAGS_USED=true
done

# For consistency with other scripts: if no flags provided, first argument should be used as data path
if [ "$FLAGS_USED" == false ] && [ -n "$1" ]; then
    DATA_FOLDER_PATH="$1"
fi


## Main execution

$CLEAR_CONSOLE && clear
print_welcome_banner

# Input data section with improved descriptions
print_section_header "MODEL INPUT REQUIREMENTS"

echo -e "This application requires the following directory structure for proper operation:\n"
echo -e "  ${ARROW} \033[38;5;33mforcings/\033[0m - Contains hydrofabric input data for model simulations"
echo -e "          \033[38;5;117m└─ Meteorological and terrain data for hydrologic calculations\033[0m"
echo -e "\n  ${ARROW} \033[38;5;35mconfig/\033[0m - Contains all configuration settings for the model"
echo -e "          \033[38;5;117m└─ Model parameters, simulation period, and execution settings\033[0m"
echo -e "\n  ${ARROW} \033[38;5;205moutputs/\033[0m - Target directory for simulation results"
echo -e "          \033[38;5;117m└─ Flow estimates, water levels, and diagnostic information\033[0m"

# If no path provided as an argument...
if [ -z "$HOST_DATA_PATH" ]; then
    echo -e "\n${INFO_MARK} ${BWhite}Please specify a directory containing these components below.${Color_Off}\n"

    # Path selection with improved user experience and fixed formatting
    if [ -f "$CONFIG_FILE" ]; then
        LAST_PATH=$(cat "$CONFIG_FILE")
        echo -e "${INFO_MARK} Last used data directory: ${BBlue}$LAST_PATH${Color_Off}"
        echo -ne "  ${ARROW} Use the same path? [Y/n]: "
        read -e use_last_path
        if [[ "$use_last_path" != [Nn]* ]]; then
            HOST_DATA_PATH=$LAST_PATH
            echo -e "  ${CHECK_MARK} Using previously configured path"
        else
            echo -ne "  ${ARROW} Enter your input data directory path: "
            read -e HOST_DATA_PATH
        fi
    else
        echo -e "${INFO_MARK} ${BYellow}No previous configuration found${Color_Off}"
        echo -ne "  ${ARROW} Enter your input data directory path: "
        read -e HOST_DATA_PATH
    fi
fi

# Handle paths with special characters properly
HOST_DATA_PATH=$(echo "$HOST_DATA_PATH" | sed 's/\\/\\\\/g')

# Directory validation with visual feedback
if [ ! -d "$HOST_DATA_PATH" ]; then
    handle_error "Directory does not exist: $HOST_DATA_PATH"
fi

# Save the new path
echo "$HOST_DATA_PATH" > "$CONFIG_FILE"
echo -e "\n${CHECK_MARK} Configuration saved successfully"

# Improved directory validation with progress indication
print_section_header "VALIDATING INPUT DIRECTORY"
echo -e "Checking directory structure at: ${BWhite}$HOST_DATA_PATH${Color_Off}\n"

show_loading "Analyzing directory structure" 2

# Function to validate directories with improved visual feedback
validate_directory() {
    local dir=$1
    local name=$2
    local color=$3
    local required=$4

    # Add a small delay to make the process visible to the user
    sleep 0.3
    
    echo -ne "  ${ARROW} Checking for ${color}${name}${Color_Off} directory... "
    
    if [ -d "$dir" ]; then
        # Count files safely with proper error handling
        local count=0
        if [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
            count=$(find "$dir" -type f 2>/dev/null | wc -l)
        fi
        
        # Colorize the count based on number of files
        if [ $count -eq 0 ]; then
            echo -e "${CHECK_MARK} Found but ${BYellow}empty${Color_Off} (0 files)"
        elif [ $count -lt 5 ]; then
            echo -e "${CHECK_MARK} Found with ${BYellow}$count${Color_Off} files"
        else
            echo -e "${CHECK_MARK} Found with ${BGreen}$count${Color_Off} files"
        fi
    else
        if [ "$required" = "true" ]; then
            echo -e "${CROSS_MARK} ${BRed}Missing required directory!${Color_Off}"
            return 1
        else
            echo -e "${WARNING_MARK} ${BYellow}Optional directory not found. Continuing...${Color_Off}"
            return 0
        fi
    fi
    return 0
}

# Validate critical directories with status tracking
error_count=0
validate_directory "$HOST_DATA_PATH/forcings" "forcings" "$BBlue" "true" || ((error_count++))
validate_directory "$HOST_DATA_PATH/config" "config" "$BGreen" "true" || ((error_count++))
validate_directory "$HOST_DATA_PATH/outputs" "outputs" "$BPurple" "true" || ((error_count++))
validate_directory "$HOST_DATA_PATH/restarts" "restarts" "$BCyan" "false"

# Check if we can proceed based on validation results
if [ $error_count -gt 0 ]; then
    handle_error "Missing required directories. Please check your setup."
else
    echo -e "\n${BG_Green}${BWhite} SUCCESS: Directory structure validated successfully! ${Color_Off}"
fi

# Improved cleanup function with better visuals
cleanup_folder() {
    local folder_path="$1"
    local file_types="$2"
    local folder_name="$3"

    # Construct the find command
    local find_cmd="find \"$folder_path\" -maxdepth 2 -type f \( $file_types \)"

    # Execute the find command and count the results
    local file_count=$(eval "$find_cmd" 2> /dev/null | wc -l)

    echo -e "\n${ARROW} Checking ${BWhite}$folder_name${Color_Off} directory for existing files..."
    
    if [ "$file_count" -gt 0 ]; then
        echo -e "  ${WARNING_MARK} Found ${BYellow}$file_count${Color_Off} existing files"
        echo -e "\n${UYellow}Cleanup options for $folder_name:${Color_Off}"
        choose_option "$folder_path" "$file_types"
    else
        echo -e "  ${CHECK_MARK} ${BGreen}$folder_name is clean and ready for new simulations!${Color_Off}"
    fi
}

choose_option() {
    local folder_path="$1"
    local file_types="$2"
    
    options=("Delete files and run fresh simulation" "Continue with existing files" "Exit")
    select option in "${options[@]}"; do
        case $option in
            "Delete files and run fresh simulation")
                echo -e "\n  ${ARROW} ${BYellow}Cleaning folder for fresh run...${Color_Off}"
                
                # Show progress for long operations
                show_loading "Removing existing files" 2
                
                # Construct the find delete command
                local find_delete_cmd="find \"$folder_path\" -maxdepth 2 -type f \( $file_types \) -delete"
                
                # Execute the find delete command
                eval "$find_delete_cmd"
                echo -e "  ${CHECK_MARK} ${BGreen}Cleanup completed successfully${Color_Off}"
                break
                ;;
            "Continue with existing files")
                echo -e "  ${INFO_MARK} ${BCyan}Proceeding with existing files.${Color_Off}"
                break
                ;;
            "Exit")
                echo -e "\n${BYellow}Exiting script. Have a nice day!${Color_Off}"
                exit 0
                ;;
            *) echo -e "  ${CROSS_MARK} ${BRed}Invalid option $REPLY. Please select again.${Color_Off}"
                ;;
        esac
    done
}

# Cleanup process with improved section header
print_section_header "FILE MANAGEMENT"

# Cleanup Process for Outputs Folder
cleanup_folder "$HOST_DATA_PATH/outputs/" "-name '*' " "Outputs"

# Cleanup Process for restarts Folder
cleanup_folder "$HOST_DATA_PATH/restarts/" "-name '*' " "Restarts"

# File discovery with improved visuals
print_section_header "HYDROFABRIC ANALYSIS"

show_loading "Scanning for model files" 2

find_files() {
    local path=$1
    local name=$2
    local regex=$3
    local color=$4

    echo -e "${ARROW} Searching for ${color}$name${Color_Off} files..."
    
    local files=$(find "$path" -iname "$regex" 2>/dev/null)
    if [ -n "$files" ]; then
        echo -e "  ${CHECK_MARK} ${BGreen}Found $(echo "$files" | wc -l) files:${Color_Off}"
        echo -e "  ${BCyan}$(echo "$files" | sed 's/^/    /')${Color_Off}"
    else
        echo -e "  ${WARNING_MARK} ${BYellow}No $name files found.${Color_Off}"
    fi
}

find_files "$HOST_DATA_PATH" "hydrofabric" "*.gpkg" "$UGreen"
find_files "$HOST_DATA_PATH" "realization" "realization.json" "$UGreen"

# System detection with improved visuals
print_section_header "SYSTEM CONFIGURATION"

echo -e "${ARROW} ${BWhite}Hardware Detection:${Color_Off}"
system_arch=$(uname -m)
os_name=$(uname -s)

echo -e "  ${INFO_MARK} Operating System: ${BCyan}$os_name${Color_Off}"
echo -e "  ${INFO_MARK} Architecture: ${BCyan}$system_arch${Color_Off}"

# Docker detection with better error handling
echo -e "\n${ARROW} ${BWhite}Checking for Docker:${Color_Off}"
if command -v docker >/dev/null 2>&1; then
    docker_version=$(docker --version | cut -d' ' -f3 | sed 's/,//')
    echo -e "  ${CHECK_MARK} Docker detected (version: ${BGreen}$docker_version${Color_Off})"
else
    handle_error "Docker not found. This script requires Docker to run the NextGen model."
fi

# Model run options with improved visuals
print_section_header "MODEL EXECUTION OPTIONS"

IMAGE_NAME="$NGEN_IMAGE_NAME:$NGEN_IMAGE_TAG"
$CUSTOM_TAG_USED && echo -e "  ${CHECK_MARK} Using specified tag: ${BGreen}$IMAGE_NAME${Color_Off}\n"

echo -e "${ARROW} ${BWhite}Please select an option to proceed:${Color_Off}\n"
options=("Run NextGen using existing local docker image" "Update to latest docker image and run" "Exit")
select option in "${options[@]}"; do
    case $option in
        "Run NextGen using existing local docker image")
            echo -e "\n${CHECK_MARK} ${BGreen}Using existing Docker image${Color_Off}"
            break
            ;;
        "Update to latest docker image and run")
            echo -e "\n${ARROW} ${BYellow}Updating Docker image...${Color_Off}"
            show_loading "Downloading latest NextGen image" 3
            docker pull $IMAGE_NAME
            echo -e "${CHECK_MARK} ${BGreen}Docker image updated successfully${Color_Off}"
            break
            ;;
        "Exit")
            echo -e "\n${BYellow}Exiting script. Have a nice day!${Color_Off}"
            exit 0
            ;;
        *) echo -e "${CROSS_MARK} ${BRed}Invalid option $REPLY. Please try again.${Color_Off}"
            ;;
    esac
done

# Running model with improved progress indicators
print_section_header "RUNNING NEXTGEN MODEL SIMULATION"

echo -e "${ARROW} ${BWhite}Preparing to run NextGen model...${Color_Off}"
echo -e "  ${INFO_MARK} ${BCyan}Local directory: ${BWhite}$HOST_DATA_PATH${Color_Off}"
echo -e "  ${INFO_MARK} ${BCyan}Container directory: ${BWhite}/ngen/ngen/data${Color_Off}"
echo -e "  ${INFO_MARK} ${BCyan}Docker image: ${BWhite}$IMAGE_NAME${Color_Off}"

# Pause for visual confirmation
sleep 2

echo -e "\n${ARROW} ${BYellow}Launching NextGen container...${Color_Off}"
docker run --rm -it -v "$HOST_DATA_PATH:/ngen/ngen/data" "$IMAGE_NAME" /ngen/ngen/data/

# Final output count with improved presentation
print_section_header "SIMULATION RESULTS"

Final_Outputs_Count=$(find "$HOST_DATA_PATH/outputs/" -type f | wc -l)

if [ $Final_Outputs_Count -gt 0 ]; then
    echo -e "${CHECK_MARK} ${BGreen}Simulation completed successfully!${Color_Off}"
    echo -e "  ${INFO_MARK} ${BWhite}$Final_Outputs_Count${Color_Off} output files generated"
    echo -e "  ${INFO_MARK} Results stored in: ${BWhite}$HOST_DATA_PATH/outputs${Color_Off}"
else
    echo -e "${WARNING_MARK} ${BYellow}No output files were generated.${Color_Off}"
    echo -e "  ${INFO_MARK} Please check the simulation configuration and try again."
fi

# ============ Run TEEHR using the runTeehr.sh script ============
if [ $Final_Outputs_Count -gt 0 ]; then
    print_section_header "EVALUATION OPTIONS"
    
    echo -e "${ARROW} ${BWhite}Would you like to run a TEEHR evaluation on the output?${Color_Off}"
    echo -e "  ${INFO_MARK} This will analyze your simulation results using the TEEHR toolkit"
    echo -e "  ${INFO_MARK} Learn more: ${UBlue}https://rtiinternational.github.io/ngiab-teehr/${Color_Off}\n"
    
    read -erp "  Run TEEHR evaluation? [Y/n]: " run_teehr_choice
    
    # Default to 'y' if input is empty
    if [[ -z "$run_teehr_choice" ]]; then
        run_teehr_choice="y"
    fi
    
    # Execute TEEHR if requested
    if [[ "$run_teehr_choice" == [Yy]* ]]; then
        # Check if the runTeehr.sh script exists
        if [ -f "$TEEHR_SCRIPT" ]; then
            echo -e "\n${INFO_MARK} ${BWhite}Launching TEEHR evaluation...${Color_Off}"
            
            # Make sure the script is executable
            if [ ! -x "$TEEHR_SCRIPT" ]; then
                chmod +x "$TEEHR_SCRIPT"
            fi
            
            # Disable clearing console if needed
            if [ "$CLEAR_CONSOLE" == true ]; then
                teehr_call="$TEEHR_SCRIPT -y -d $HOST_DATA_PATH"
            else
                teehr_call="$TEEHR_SCRIPT -y -r -d $HOST_DATA_PATH"
            fi

            # Call the runTeehr.sh script with the data path
            if ! bash -c "$teehr_call"; then
                echo -e "\n${WARNING_MARK} ${BRed}Failed to run TEEHR evaluation.${Color_Off}"
                echo -e "  ${INFO_MARK} Check that the runTeehr.sh script is properly configured."
            fi
        else
            echo -e "\n${WARNING_MARK} ${BRed}Could not find the TEEHR evaluation script.${Color_Off}"
            echo -e "  ${INFO_MARK} Expected location: ${BWhite}$TEEHR_SCRIPT${Color_Off}"
            echo -e "  ${INFO_MARK} Please make sure the script is in the current directory."
            
            # Fallback to inline TEEHR execution
            echo -e "\n${INFO_MARK} ${BYellow}Falling back to embedded TEEHR evaluation...${Color_Off}"
            
            # Detect architecture for default tag
            if uname -a | grep -q 'arm64\|aarch64'; then
                default_tag="latest"
            else
                default_tag="x86"
            fi
            
            echo -e "  ${INFO_MARK} Detected architecture: ${BCyan}$(uname -m)${Color_Off} (default tag: ${BCyan}$default_tag${Color_Off})"
            read -erp "  ${ARROW} Specify TEEHR image tag [default: '$default_tag']: " teehr_image_tag
            
            if [[ -z "$teehr_image_tag" ]]; then
                teehr_image_tag=$default_tag
            fi
            
            IMAGE_NAME=$TEEHR_IMAGE_NAME
            
            print_section_header "RUNNING TEEHR EVALUATION"
            
            echo -e "${ARROW} ${BYellow}Launching TEEHR evaluation...${Color_Off}\n"
            docker run -v "$HOST_DATA_PATH:/app/data" "$IMAGE_NAME:$teehr_image_tag"
            
            echo -e "\n${BG_Green}${BWhite} TEEHR EVALUATION COMPLETE ${Color_Off}"
            echo -e "${INFO_MARK} ${BCyan}Results have been saved to your output directory${Color_Off}"
        fi
    else
        echo -e "${INFO_MARK} ${BCyan}Skipping TEEHR evaluation step.${Color_Off}"
    fi
else
    echo -e "\n${INFO_MARK} ${BYellow}No outputs available for evaluation.${Color_Off}"
fi

# ============ Use viewOnTethys.sh for visualization ============
if [ $Final_Outputs_Count -gt 0 ]; then
    print_section_header "VISUALIZATION OPTIONS"
    
    echo -e "${ARROW} ${BWhite}Would you like to visualize results using Tethys?${Color_Off}"
    echo -e "  ${INFO_MARK} This will provide an interactive web interface to explore your model results"
    read -erp "  Visualize results? [Y/n]: " visualize_choice
    
    # Default to 'y' if input is empty
    if [[ -z "$visualize_choice" || "$visualize_choice" == [Yy]* ]]; then
        # Check if the viewOnTethys.sh script exists
        if [ -f "$TETHYS_SCRIPT" ]; then
            echo -e "\n${INFO_MARK} ${BWhite}Launching Tethys visualization...${Color_Off}"
            
            # Make sure the script is executable
            if [ ! -x "$TETHYS_SCRIPT" ]; then
                chmod +x "$TETHYS_SCRIPT"
            fi

            # Disable clearing console if needed
            if [ "$CLEAR_CONSOLE" == true ]; then
                tethys_call="$TETHYS_SCRIPT -d $HOST_DATA_PATH"
            else
                tethys_call="$TETHYS_SCRIPT -r -d $HOST_DATA_PATH"
            fi

            # Call the viewOnTethys.sh script with the data path
            if ! bash -c "$tethys_call"; then
                echo -e "\n${WARNING_MARK} ${BRed}Failed to launch Tethys visualization.${Color_Off}"
                echo -e "  ${INFO_MARK} Check that the viewOnTethys.sh script is properly configured."
            fi
        else
            echo -e "\n${WARNING_MARK} ${BRed}Could not find the Tethys visualization script.${Color_Off}"
            echo -e "  ${INFO_MARK} Expected location: ${BWhite}$TETHYS_SCRIPT${Color_Off}"
            echo -e "  ${INFO_MARK} Please make sure the script is in the current directory."
        fi
    else
        echo -e "${INFO_MARK} ${BCyan}Skipping visualization step.${Color_Off}"
    fi
else
    echo -e "\n${INFO_MARK} ${BYellow}No outputs available for visualization.${Color_Off}"
fi

# Closing message with improved visuals
print_section_header "SESSION COMPLETE"

# Create a fancy box for the thank you message
echo -e "\033[38;5;39m  ┌────────────────────────────────────────────────────────────┐\033[0m"
echo -e "\033[38;5;39m  │\033[48;5;39m\033[1;37m  Thank you for using NGIAB!                               \033[0m\033[38;5;39m  │\033[0m"
echo -e "\033[38;5;39m  └────────────────────────────────────────────────────────────┘\033[0m\n"

echo -e "${INFO_MARK} ${BWhite}Your simulation results are available at:${Color_Off}"
echo -e "  ${ARROW} ${LBLUE}$HOST_DATA_PATH/outputs${Color_Off}\n"

# Check if any outputs were generated
output_count=$(find "$HOST_DATA_PATH/outputs/" -type f 2>/dev/null | wc -l)
if [ "$output_count" -gt 0 ]; then
    echo -e "  ${CHECK_MARK} ${BGreen}$output_count files were successfully generated${Color_Off}"
else
    echo -e "  ${WARNING_MARK} ${BYellow}No output files found. Check simulation parameters.${Color_Off}"
fi

echo -e "\n${INFO_MARK} ${BWhite}For support, please email:${Color_Off}"
echo -e "  ${ARROW} ${UBlue}ciroh-it-support@ua.edu${Color_Off}\n"

# Show date and time of completion
echo -e "  ${INFO_MARK} ${BWhite}Session completed at:${Color_Off} $(date '+%Y-%m-%d %H:%M:%S')\n"

echo -e "${BWhite}Have a great day!${Color_Off}\n"

exit 0
