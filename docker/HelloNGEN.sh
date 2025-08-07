#!/bin/bash
# ANSI color codes
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
RESET='\e[0m'

workdir="${1:-/ngen}"
cd "${workdir}" || { echo -e "${RED}Failed to change directory to ${workdir}${RESET}"; exit 1; }
set -e
echo -e "${CYAN}Working directory is:${RESET}"
pwd
echo -e "\n"



# Function to automatically select file if only one is found
auto_select_file() {
  local files=($1)
  if [ "${#files[@]}" -eq 1 ]; then
    echo "${files[0]}"
  else
    echo ""
  fi
}

# Finding files
HYDRO_FABRIC_CATCHMENTS=$(find . -name "*.gpkg")
HYDRO_FABRIC_NEXUS=$(find . -name "*.gpkg")
NGEN_REALIZATIONS=$(find config/ -name "*realization*.json")

# Auto-selecting files if only one is found
selected_catchment=$(auto_select_file "$HYDRO_FABRIC_CATCHMENTS")
selected_nexus=$(auto_select_file "$HYDRO_FABRIC_NEXUS")
selected_realization=$(auto_select_file "$NGEN_REALIZATIONS")

# Displaying found files
echo -e "${BLUE}\e[4mFound these Catchment files:${RESET}" && echo "$HYDRO_FABRIC_CATCHMENTS" || echo -e "${RED}No Catchment files found.${RESET}"
echo -e "\n"
echo -e "${MAGENTA}\e[4mFound these Nexus files:${RESET}" && echo "$HYDRO_FABRIC_NEXUS" || echo -e "${RED}No Nexus files found.${RESET}"
echo -e "\n"
echo -e "${CYAN}\e[4mFound these Realization files:${RESET}" && echo "$NGEN_REALIZATIONS" || echo -e "${RED}No Realization files found.${RESET}"
echo -e "\n"

generate_partition() {
  /dmod/bin/partitionGenerator "$1" "$2" "partitions_$3.json" "$3" '' ''
}

generate_local_partition() {
  python /dmod/utils/partitioning/local_only_partitions.py "$1" "$2" "."
  # the last line printed by the script is the number of partitions actually generated
  }

if [ "$2" == "auto" ]
  then
    echo "AUTO MODE ENGAGED"
    echo "Running NextGen model framework in parallel mode"
    if [ -z "$3" ]; then
      procs=$(($(nproc) - 2))
    else
      procs=$3
    fi

    partitions=$(find . -name "*partitions_$procs.json")
    if [[ -z $partitions ]]; then
      echo "No partitions file found, generating..."
      if [ "$4" == "local" -o "$3" == "local" ]
      then 
        procs=$(generate_local_partition "$selected_catchment" "$procs"|tail -n 1)
      else
        generate_partition "$selected_catchment" "$selected_nexus" "$procs"
      fi
    else
      echo "Found paritions file! "$partitions
    fi

    mpirun -n $procs /dmod/bin/ngen-parallel $selected_catchment all $selected_nexus all $selected_realization $(pwd)/partitions_$procs.json
    echo "Run completed successfully, exiting, have a nice day!"
    exit 0
  else
    echo "Entering Interactive Mode"    
fi

echo -e "${YELLOW}Select an option (type a number): ${RESET}"
options=("Run NextGen model framework in serial mode" "Run NextGen model framework in parallel mode" "Enter Bash shell (for developers)" "Exit")
select option in "${options[@]}"; do
  case $option in
    "Run NextGen model framework in serial mode"|"Run NextGen model framework in parallel mode")
      echo -e "\n"
      n1=${selected_catchment:-$(read -erp "Enter the hydrofabric catchment file path: " n1; echo "$n1")}
      n2=${selected_nexus:-$(read -erp "Enter the hydrofabric nexus file path: " n2; echo "$n2")}
      n3=${selected_realization:-$(read -erp "Enter the Realization file path: " n3; echo "$n3")}

      echo -e "${GREEN}Selected files:\nCatchment: $n1\nNexus: $n2\nRealization: $n3${RESET}\n"

      if [ "$option" == "Run NextGen model framework in parallel mode" ]; then
        procs=$(nproc)
        # The last line printed by the script is the number of partitions actually generated
        num_partitions=$(generate_local_partition "$n1" "$procs"|tail -n 1)
        echo "Generated $num_partitions partitions"
        run_command="mpirun -n $num_partitions /dmod/bin/ngen-parallel $n1 all $n2 all $n3 $(pwd)/partitions_$num_partitions.json"
      else
        run_command="/dmod/bin/ngen-serial $n1 all $n2 all $n3"
      fi

      echo -e "${YELLOW}Your NGEN run command is $run_command${RESET}"
      break
      ;;
    "Enter Bash shell (for developers)")
      echo -e "${CYAN}Starting a shell, simply exit to stop the process.${RESET}"
      /bin/bash
      echo -e "${CYAN}Shell closed. Hit ${YELLOW}ENTER${CYAN} to continue...${RESET}"
      ;;
    "Exit")
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid option $REPLY${RESET}"
      ;;
  esac
done

echo -e "${GREEN}If your model didn't run, or encountered an error, try checking the Forcings paths in the Realizations file you selected.${RESET}"
# Ask user if they want to redirect output to /dev/null
echo -e "${YELLOW}Do you want to redirect command output to /dev/null? (y/N, default: n):${RESET}"
read -r redirect_choice

# Execute the command
if [[ "$redirect_choice" == [Yy]* ]]; then
    echo -e "${GREEN}Redirecting output to /dev/null.${RESET}"
    time $run_command > /dev/null 2>&1
else
    time $run_command
fi
command_status=$?

# Set message color based on command status
if [ $command_status -eq 0 ]; then
    color=$GREEN
    message="Finished executing command successfully."
else
    color=$RED
    message="Command execution failed with exit code $command_status."
fi

echo -e "${color}${message}${RESET}"

echo -e "${YELLOW}Would you like to continue?${RESET}"
echo -e "${YELLOW}Select an option (type a number): ${RESET}"
options=("Enter Bash shell (for developers)" "Exit")
select option in "${options[@]}"; do
  case $option in
    "Enter Bash shell (for developers)")
      echo -e "${CYAN}Starting a shell, simply exit to stop the process.${RESET}"
      /bin/bash
      echo -e "${GREEN}Exiting container. Have a nice day.${RESET}"
      break
      ;;
    "Exit")
      echo -e "${GREEN}Have a nice day.${RESET}"
      break
      ;;
    *)
      echo -e "${RED}Invalid option $REPLY${RESET}"
      ;;
  esac
done
exit
