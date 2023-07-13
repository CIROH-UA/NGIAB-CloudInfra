#!/bin/bash

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Reset
Color_Off='\033[0m'       # Text Reset


set -e

echo -e "\n"
echo "========================================================="
echo -e "${UWhite} Welcome to CIROH-UA:NextGen National Water Model App! ${Color_Off}"
echo "========================================================="
echo -e "\n"
echo -e "Looking for input data (a directory containing the following directories: forcings, config and outputs): \n"

echo -e "${BBlue}forcings${Color_Off} is the hydrofabric input data for your model(s)."
echo -e "${BGreen}config${Color_Off} folder has all the configuration related files for the model."
echo -e "${BPurple}outputs${Color_Off} is where the output files are copied to when the model finish the run"

echo -e "\n"
read -rp "Enter your input data directory path (use absolute path): " HOST_DATA_PATH

echo -e "The Directory you've given is:" && echo "$HOST_DATA_PATH"

Outputs_Count=$(ls $HOST_DATA_PATH/outputs | wc -l)
Forcings_Count=$(ls $HOST_DATA_PATH/forcings | wc -l)
Config_Count=$(ls $HOST_DATA_PATH/config | wc -l)

#Validate paths exist:
[ -d "$HOST_DATA_PATH/forcings" ] && echo -e "${BBlue}forcings${Color_Off} exists. $Forcings_Count forcings found." || echo -e "Error: Directory $HOST_DATA_PATH/${BBlue}forcings${Color_Off} does not exist."
[ -d "$HOST_DATA_PATH/outputs" ] && echo -e "${BPurple}outputs${Color_Off} exists. $Outputs_Count outputs found." || echo -e "Error: Directory $HOST_DATA_PATH/${BPurple}outputs${Color_Off} does not exist, but will be created if you choose to copy the outputs after the run." 
[ -d "$HOST_DATA_PATH/config" ] && echo -e "${BGreen}config${Color_Off} exists. $Config_Count configs found." || echo -e "Error: Directory $HOST_DATA_PATH/${BGreen}config${Color_Off} does not exist."

echo -e "\n"

if [ $Outputs_Count -gt 0 ]; then
    echo -e "${UYellow}Cleanup Process: This step will delete all files in the outputs folder: $HOST_DATA_PATH/outputs! Be Careful.${Color_Off}"
    PS3="Select an option (type a number): "
    options=("Delete output files and run fresh" "Continue without cleaning" "Exit")
    select option in "${options[@]}"; do
        case $option in
            "Delete output files and run fresh")
                echo "Cleaning Outputs folder for fresh run"
                echo "Starting Cleanup of Files:"
		echo "Cleaning Up $Outputs_Count Files"
                rm -f "$HOST_DATA_PATH/outputs"/*
                break
                ;;
            "Continue without cleaning")
                echo "Happy Hydro Modeling."
                break
                ;;
            "Exit")
                echo "Have a nice day!"
		exit 0
                ;;
            *)
                echo "Invalid option $REPLY. Please select again."
                ;;
        esac
    done
else
    echo -e "Outputs directory is empty and model is ready for run."
fi


echo -e "\n"
echo "Looking in the provided directory gives us:" 

HYDRO_FABRIC_CATCHMENTS=$(find $HOST_DATA_PATH -iname "*catchment*.geojson")
HYDRO_FABRIC_NEXUS=$(find $HOST_DATA_PATH -iname "*nexus*.geojson")
NGEN_REALIZATIONS=$(find $HOST_DATA_PATH -iname "*realization*.json")
#pwd
echo -e "${UGreen}Found these Catchment files:${Color_Off}" && sleep 1 && echo "$HYDRO_FABRIC_CATCHMENTS"
echo -e "${UGreen}Found these Nexus files:${Color_Off}" && sleep 1 && echo "$HYDRO_FABRIC_NEXUS"
echo -e "${UGreen}Found these Realization files:${Color_Off}" && sleep 1 && echo "$NGEN_REALIZATIONS"

#Detect Arch
AARCH=$(uname -a)
echo -e "\n"
echo -e "Detected ISA = $AARCH" 
if docker --version ; then
	echo "Docker found"
else 
	echo "Docker not found"
fi 
echo -e "\n"

PS3="Select an option (type a number): "
options=("Run NextGen Model using docker" "Exit")
select option in "${options[@]}"; do
  case $option in
   "Run NextGen Model using docker")
      echo "Pulling NextGen docker image and running the model"
      break
      ;;
    Exit)
      echo "Have a nice day!"
      exit 0
      ;;
    *) 
      echo "Invalid option $REPLY, 1 to continue and 2 to exit"
      ;;
  esac
done
echo -e "\n"

if uname -a | grep arm64 || uname -a | grep aarch64 ; then

docker pull awiciroh/ciroh-ngen-image:latest-arm
echo -e "Pulled awiciroh/ciroh-ngen-image:latest-arm image"
IMAGE_NAME=awiciroh/ciroh-ngen-image:latest-arm
else

docker pull awiciroh/ciroh-ngen-image:latest-x86
echo -e "Pulled awiciroh/ciroh-ngen-image:latest-x86 image"
IMAGE_NAME=awiciroh/ciroh-ngen-image:latest-x86
fi

echo -e "\n"
echo -e "Running NextGen docker container..."
echo -e "Mounting local host directory $HOST_DATA_PATH to /ngen/ngen/data within the container."
docker run --rm -it -v $HOST_DATA_PATH:/ngen/ngen/data $IMAGE_NAME /ngen/ngen/data/

Final_Outputs_Count=$(ls $HOST_DATA_PATH/outputs | wc -l)

echo -e "$Final_Outputs_Count new outputs created."
echo -e "Any copied files can be found here: $HOST_DATA_PATH/outputs"
echo -e "Thank you for running NextGen In A Box: National Water Model! Have a nice day!"
exit 0
