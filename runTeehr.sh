#!/bin/bash

# Check if the config file exists and read from it
_check_and_read_config() {
    echo "check"
    local config_file="$1"
    if [ -f "$config_file" ]; then
        local last_path=$(cat "$config_file")
        echo -e "Last used data directory path: %s\n" "$last_path${Color_Off}"
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
            echo -e "The Directory you've given is:\n$DATA_FOLDER_PATH\n${Color_Off}"   
        else
            echo -e "Invalid input. Exiting.\n${Color_Off}" >&2
            return 1
        fi
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
            return 0
        elif [[ "$use_last_path" =~ ^[Nn] ]]; then
            read -erp "Enter your input data directory path (use absolute path): " DATA_FOLDER_PATH
            _check_if_data_folder_exits
            # Save the new path to the config file
            echo "$DATA_FOLDER_PATH" > "$CONFIG_FILE"
            echo -e "The Directory you've given is:\n$DATA_FOLDER_PATH\n${Color_Off}"   
        else
            echo -e "Invalid input. Exiting.\n${Color_Off}" >&2
            return 1
        fi
    fi
}

check_last_path() {
    if [[ -z "$1" ]]; then
        _check_and_read_config "$CONFIG_FILE"
     
    else
        DATA_FOLDER_PATH="$1"
    fi
}

### Start of the Script ###

# Constanst
CONFIG_FILE="$HOME/.host_data_path.conf"

check_last_path "$@"

IMAGE_NAME=awiciroh/ngiab-teehr
while true; do
    echo -e "${YELLOW}Run a TEEHR Evaluation on the output (https://rtiinternational.github.io/ngiab-teehr/)? (y/N, default: y):${RESET}"
    read -r run_teehr_choice
    # Default to 'y' if input is empty
    if [[ -z "$run_teehr_choice" ]]; then
        run_teehr_choice="y"
    fi
    # Check for valid input
    if [[ "$run_teehr_choice" == [YyNn]* ]]; then
        break
    else
        echo -e "${RED}Invalid choice. Please enter 'y' for yes, 'n' for no, or press Enter for default (yes).${RESET}"
    fi
done

# Execute the command
if [[ "$run_teehr_choice" == [Yy]* ]]; then
    # TEEHR run options
    echo -e "${UYellow}Specify the TEEHR image tag to use: ${Color_Off}"
    read -erp "Image tag (ex. v0.1.4, x86, default: 'latest'): " teehr_image_tag
    if [[ -z "$teehr_image_tag" ]]; then
        if uname -a | grep arm64 || uname -a | grep aarch64 ; then
            teehr_image_tag=latest
        else
            teehr_image_tag=x86
        fi
    fi
    echo -e "${UYellow}Select an option (type a number): ${Color_Off}"
    options=("Run TEEHR using existing local docker image" "Run TEEHR after updating to latest docker image" "Exit")
    select option in "${options[@]}"; do
        case $option in
            "Run TEEHR using existing local docker image")
                echo "running the TEEHR evaluation"
                break
                ;;
            "Run TEEHR after updating to latest docker image")
                echo "pulling container and running the TEEHR evaluation"
                docker pull $IMAGE_NAME:$teehr_image_tag
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

    docker run -v "$DATA_FOLDER_PATH:/app/data" "$IMAGE_NAME:$teehr_image_tag"
    echo -e "${GREEN}TEEHR evaluation complete.${RESET}\n"
else
    echo -e "${CYAN}Skipping TEEHR evaluation step.${RESET}\n"
fi
# ================================
