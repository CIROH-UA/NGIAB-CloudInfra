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

# Docker image names
PLANKS_IMAGE="Sheargrub/planks_docker"
PLANKS_TAG="dev"

# Fix for missing environment variables that might cause display issues
export TERM=xterm-256color

set -e

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
    echo -e "\033[38;5;39m  ║  \033[1;33;5;231mDeveloper Utilities Script\033[38;5;39m                                                              ║\033[0m"
    echo -e "\033[38;5;39m  ║                                                                                          ║\033[0m"
    echo -e "\033[38;5;39m  ╚══════════════════════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo -e "\n"
    echo -e "  ${ARROW} \033[1;38;5;39mVisit our website: \033[4;38;5;87mhttps://ngiab.ciroh.org\033[0m"
    echo -e "  ${INFO_MARK} \033[1;38;5;231mDeveloped by CIROH & Lynker\033[0m"
    echo -e "\n"
    sleep 1
}

init_conf_dev() {
    if [ ! -f ./conf_dev.yml ]; then
        cp ./conf_dev_default.yml ./conf_dev.yml
        echo -e "${INFO_MARK} ${BYellow}First-time setup: initialized conf_dev.yml.${Color_Off}"
    fi
}

apply_ngen_repo() {
    name=$(awk '/NGEN_DEV_REPO/ {print $2}' conf_dev.yml)
    sed -i "s?ENV NGEN_REPO=CIROH-UA/ngen?ENV NGEN_REPO=${name}?" ./plugins/Dockerfile
}

apply_ngen_branch() {
    name=$(awk '/NGEN_DEV_BRANCH/ {print $2}' conf_dev.yml)
    sed -i "s?ENV NGEN_BRANCH=ngiab?ENV NGEN_BRANCH=${name}?" ./plugins/Dockerfile
}

apply_troute_repo() {
    name=$(awk '/TROUTE_DEV_REPO/ {print $2}' conf_dev.yml)
    sed -i "s?ENV TROUTE_REPO=CIROH-UA/t-route?ENV TROUTE_REPO=${name}?" ./plugins/Dockerfile
}

apply_troute_branch() {
    name=$(awk '/TROUTE_DEV_BRANCH/ {print $2}' conf_dev.yml)
    sed -i "s?ENV TROUTE_BRANCH=ngiab?ENV TROUTE_BRANCH=${name}?" ./plugins/Dockerfile
}

apply_repos() {
    apply_ngen_repo
    apply_ngen_branch
    apply_troute_repo
    apply_troute_branch
}

rebuild_local_image() {
    # TODO: Image selection logic

    echo -e "${ARROW_MARK} ${BYellow}Running Planks for Docker to apply plug-ins...${Color_Off}"
    docker run --rm -it -v "$(pwd):/host_data/" "$PLANKS_IMAGE:$PLANKS_TAG"
    echo -e "${CHECK_MARK} ${BGreen}Plug-ins applied!${Color_Off}"

    echo -e "${ARROW_MARK} ${BYellow}Applying development repos for ngen and t-route...${Color_Off}"
    apply_repos
    echo -e "${CHECK_MARK} ${BGreen}Development repositories applied!${Color_Off}"

    echo -e "${ARROW_MARK} ${BYellow}Rebuilding development Dockerfile...${Color_Off}"
    docker build -f ./plugins/Dockerfile -t awiciroh/ciroh-ngen-image:local ./docker --no-cache
    echo -e "${CHECK_MARK} ${BGreen}Done! Development image built at ${BYellow}awiciroh/ciroh-ngen-image:local${BGreen}.${Color_Off}"
}

create_new_plugin() {
    plugin_name=" "
    echo -e "${BBlue}Creating a new plug-in folder.${Color_Off}"
    while [[ "$plugin_name" == *" "* ]] || [[ "$plugin_name" == *"\t"* ]]
    do
        echo -ne "${ARROW_MARK} ${BYellow}Please enter a name for your plug-in, with no spaces: ${Color_Off}"
        read -e plugin_name

        if [[ "$plugin_name" == *" "* ]] || [[ "$plugin_name" == *"\t"* ]]; then
            echo -e "  ${CROSS_MARK} ${BRed}Please enter a name with no whitespace.${Color_Off}"
        fi
    done
    
    cp -r ./plugins/template ./plugins/$plugin_name
    sed -i "s?plank_name: template?plank_name: ${plugin_name}?" ./plugins/$plugin_name/plank_conf.yml

    echo -e "  ${CHECK_MARK} ${BGreen}New plug-in '$plugin_name' created from template!${Color_Off}"
}

set_ngen_repo() {
    echo -ne "  ${ARROW} Enter your ngen repo: "
    read -e ngen_repo
    echo -ne "  ${ARROW} Enter your preferred branch: "
    read -e ngen_branch

    sed -i "/NGEN_DEV_REPO:/d" ./conf_dev.yml
    sed -i "/NGEN_DEV_BRANCH:/d" ./conf_dev.yml
    echo "" >> conf_dev.yml
    echo "NGEN_DEV_REPO: ${ngen_repo}" >> conf_dev.yml
    echo "NGEN_DEV_BRANCH: ${ngen_branch}" >> conf_dev.yml

    echo -e "${CHECK_MARK} ${BGreen}Done!${Color_Off}"
    echo -ne "  ${ARROW} Would you like to rebuild your image? (Y/N): "
    read -e rebuild_now
    if [[ "$rebuild_now" == [Yy]* ]]; then
        echo -e "${INFO_MARK} ${BBlue}Rebuilding...${Color_Off}"
        rebuild_local_image
    fi
}

set_troute_repo() {
    echo -ne "  ${ARROW} Enter your troute repo: "
    read -e troute_repo
    echo -ne "  ${ARROW} Enter your preferred branch: "
    read -e troute_branch

    sed -i "/TROUTE_DEV_REPO:/d" ./conf_dev.yml
    sed -i "/TROUTE_DEV_BRANCH:/d" ./conf_dev.yml
    echo "" >> conf_dev.yml
    echo "TROUTE_DEV_REPO: ${troute_repo}" >> conf_dev.yml
    echo "TROUTE_DEV_BRANCH: ${troute_branch}" >> conf_dev.yml

    echo -e "${CHECK_MARK} ${BGreen}Done!${Color_Off}"
    echo -ne "  ${ARROW} Would you like to rebuild your image? (Y/N): "
    read -e rebuild_now
    if [[ "$rebuild_now" == [Yy]* ]]; then
        echo -e "${INFO_MARK} ${BBlue}Rebuilding...${Color_Off}"
        rebuild_local_image
    fi
}

do_main_menu() {
    main_loop=1
    options_main=("Rebuild local image" "Create a new plug-in" "Set NextGen development repo" "Set T-Route development repo" "Help" "Exit")

    while [ $main_loop -gt 0 ]
    do
        echo -e "\n  ${ARROW_MARK} ${BBlue}Please select an option below:${Color_Off}"
        select option in "${options_main[@]}"; do
            case $option in
                "Rebuild local image")
                    rebuild_local_image
                    break
                    ;;
                "Create a new plug-in")
                    create_new_plugin
                    break
                    ;;
                "Set NextGen development repo")
                    set_ngen_repo
                    break
                    ;;
                "Set T-Route development repo")
                    set_troute_repo
                    break
                    ;;
                "Help")
                    do_help
                    break
                    ;;
                "Exit")
                    main_loop=0
                    break
                    ;;
                *)
                    echo -e "  ${CROSS_MARK} ${BRed}Invalid option $REPLY. Please select again.${Color_Off}"
                    ;;
            esac
        done
    done
}

do_help() {
    help_loop=1
    options_help=("NGIAB plug-ins" "NextGen and T-Route development settings" "Using your customized local image" "Back")
    while [ $help_loop -gt 0 ]
    do
        echo -e "\n  ${INFO_MARK} ${BBlue}What would you like to know more about?${Color_Off}"
        select option in "${options_help[@]}"; do
            case $option in
                "NGIAB plug-ins")
                    echo -e "\n  ${ARROW} ${BYellow}NGIAB plug-ins${Color_Off}"
                    echo -e ""
                    echo -e "NGIAB plug-ins offer a way for you to import your models into NGIAB!"
                    echo -e "These plug-ins are inserted directly into your Dockerfile, creating a"
                    echo -e "custom image that you can retain for testing."
                    echo -e ""
                    echo -e "Using an existing plug-in is easy: just drag your plug-in's folder into"
                    echo -e "the \"plugins\" directory, then use option [1] in this script's main menu"
                    echo -e "to rebuild a local development image. From there, the development script"
                    echo -e "will compile a new NGIAB image containing your plug-ins."
                    echo -e ""
                    echo -e "Option [2] in this script's main menu will help you create a new plug-in"
                    echo -e "to add additional BMI modules to NGIAB."
                    echo -e "For more information on this process, please see the documentation on CIROH DocuHub: [link]"
                    echo -e ""

                    echo -e "${INFO_MARK} ${BCyan}Press any key to continue...${Color_Off}"
                    read -n 1 -s -r -p ""

                    break
                    ;;
                "NextGen and T-Route development settings")
                    echo -e "\n  ${ARROW} ${BYellow}NGIAB plug-ins${Color_Off}"
                    echo -e ""
                    echo -e "By default, NGIAB uses the most up-to-date versions of the CIROH-UA"
                    echo -e "forks of NextGen and T-Route with the latest functionality. However,"
                    echo -e "while developing new features or changes to these tools, you may want"
                    echo -e "to instead build them from a different repository. Options [3] and [4]"
                    echo -e "in this script's main menu will allow you to do just that by specifying"
                    echo -e "a different source repository and branch on GitHub."
                    echo -e ""

                    echo -e "${INFO_MARK} ${BCyan}Press any key to continue...${Color_Off}"
                    read -n 1 -s -r -p ""

                    break
                    ;;
                "Using your customized local image")
                    echo -e "\n  ${ARROW} ${BYellow}Using your customized local image${Color_Off}"
                    echo -e ""
                    echo -e "This script builds its output to the tag awiciroh/ciroh-ngen-image:local,"
                    echo -e "and the underlying Dockerfile is saved in the plugins folder."
                    echo -e "Don't worry — this image is local to your machine, and won't be published"
                    echo -e "to DockerHub unless you choose to do so. To run your custom image using"
                    echo -e "guide.sh, select the \"Run NextGen using local development image\" choice"
                    echo -e "under the model execution options."
                    echo -e ""
                    echo -e "If you'd like to publish your customized environment for easy"
                    echo -e "reproducibility, you can do so with minimal changes! However, please see"
                    echo -e "the relevant documentation for a few best practices when doing so: [link]"
                    echo -e ""

                    echo -e "${INFO_MARK} ${BCyan}Press any key to continue...${Color_Off}"
                    read -n 1 -s -r -p ""

                    break
                    ;;
                "Back")
                    help_loop=0
                    break
                    ;;
                *)
                    echo -e "  ${CROSS_MARK} ${BRed}Invalid option $REPLY. Please select again.${Color_Off}"
                    ;;
            esac
        done
    done
}

print_welcome_banner
init_conf_dev
do_main_menu

echo -e "\n${INFO_MARK} ${BWhite}For support, please email:${Color_Off}"
echo -e "  ${ARROW} ${UBlue}ciroh-it-support@ua.edu${Color_Off}\n"

# Show date and time of completion
echo -e "  ${INFO_MARK} ${BWhite}Session completed at:${Color_Off} $(date '+%Y-%m-%d %H:%M:%S')\n"

echo -e "${BWhite}Have a great day!${Color_Off}\n"

exit 0
