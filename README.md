# NextGen In A Box (NGIAB)

"NextGen In A Box" (NGIAB) is a containerized version of the NextGen National Water Resources Modeling Framework.

[![ARM Build and push final image](https://github.com/CIROH-UA/NGIAB-CloudInfra/actions/workflows/docker_image_main_branch.yml/badge.svg)](https://github.com/CIROH-UA/NGIAB-CloudInfra/actions/workflows/docker_image_main_branch.yml)
[![X86 Build and push final image](https://github.com/CIROH-UA/NGIAB-CloudInfra/actions/workflows/docker_image_main_x86.yml/badge.svg)](https://github.com/CIROH-UA/NGIAB-CloudInfra/actions/workflows/docker_image_main_x86.yml)


<p align="center">
<img src="https://github.com/CIROH-UA/NGIAB-CloudInfra/assets/54657/1a647024-67f8-489a-9f5e-86437449b6ff" width="300">
</p>
The NextGen Water Resources Modeling Framework (NextGen) is a data-centric framework developed by the NOAA OWP team to enhance the forecasting of flooding and drought, improve water resource management, and protect lives, property, and the environment. 

The Cooperative Institute for Research to Operations in Hydrology (CIROH) along with Lynker has developed “NextGen In A Box” - ready-to-run, containerized and cloud-friendly version of NextGen framework, packaged with scripts to help prepare data and get you modeling more quickly. Leveraging open-source technical tools like Git, GitHub, CI/CD, Docker, NextGen In A Box fosters open research practices, enabling transparent and reproducible research outcomes within the NextGen framework.

We are doing a case study : NWM run for Sipsey Fork, Black Warrior River
- We don’t want to run all of CONUS
- We want to run NextGen locally
- We want to have control over inputs / config.
- How can we do it? Answer: NextGen In A Box (NGIAB)

This repository contains :
- **Dockerfile** for running NextGen Framework (docker/Dockerfile*)
- Documentation of how to run the model. (README.md)

## Table of Contents
* [Prerequisites:](#prerequisites-)
    + [Install docker](#install-docker-)
    + [Install WSL on Windows](#Install-WSL-on-Windows-)
    + [Download the input data in "ngen-data" folder from S3 bucket ](#download-the-input-data-in--ngen-data--folder-from-s3-bucket--)
      - [Linux & Mac](#linux---mac)
  * [Run NextGen-In-A-Box](#run-nextgen-in-a-box)
    + [Clone CloudInfra repo](#clone-cloudinfra-repo)
    + [How to run the model script?](#how-to-run-the-model-script-)
    + [Output of the model script](#output-of-the-model-script)


## Prerequisites:

### Install docker and validate docker is up:
    - On *Windows*:
        - [Install Docker Desktop on Windows](https://docs.docker.com/desktop/install/windows-install/#install-docker-desktop-on-windows)
        - Once docker is installed, start Docker Destop.
        - Open Powershell -> right click and `Run as an Administrator` 
        - Type `docker ps -a` to make sure docker is working.
    
    - On *Mac*:
        - [Install docker on Mac](https://docs.docker.com/desktop/install/mac-install/) 
        - Once docker is installed, start Docker Desktop.
        - Open terminal app
        - Type `docker ps -a` to make sure docker is working.
        
    - On *Linux*:
        - [Install docker on Linux](https://docs.docker.com/desktop/install/linux-install/)
        - Follow similar steps as *Mac* for starting Docker and verifying the installation

### Install WSL on Windows:

1. Follow Microsofts latest [instructions](https://learn.microsoft.com/en-us/windows/wsl/install) to install wsl  
2. Once this is complete, follow the instructions for linux inside your wsl terminal.

    
### Download the sample input data in "ngen-data" folder from S3 bucket :

#### Linux ,Mac, WSL(Windows)

```bash   
    mkdir -p NextGen/ngen-data
    cd NextGen/ngen-data
    wget --no-parent https://ciroh-ua-ngen-data.s3.us-east-2.amazonaws.com/AWI-004/AWI_09_004.tar.gz
    tar -xf AWI_09_004.tar.gz
    # to rename your folder
    mv AWI_09_004 my_data
```

### How to Generate Your Own Input Data?

Follow steps in our [ngen-datastream Repo](https://github.com/CIROH-UA/ngen-datastream/tree/main)

### Case Study Map for the Sipsey Fork, Black Warrior River, AL 

![AGU_113060_03W_002](https://github.com/shahab122/NGIAB-CloudInfra/assets/28275758/cc7978da-081c-44ba-8877-0e235b5cca43)

## Run NextGen In A Box

### Clone NGIAB-CloudInfra repository

Navigate to NextGen directory and clone the repository using below commands:

```bash
    cd ../..
    git clone https://github.com/CIROH-UA/NGIAB-CloudInfra.git
    git checkout main
    cd NGIAB-CloudInfra
```  
Once you are in *NGIAB-CloudInfra* directory, you should see `guide.sh` in it. Now, we are ready to run the model using that script. 

### How to run the model script?

#### WSL, Linux and Mac Steps:
Follow below steps to run `guide.sh` script 

```bash
    ./guide.sh    
```
- The script prompts the user to enter the file path for the input data directory where the forcing and config files are stored. 

Run the following command and copy the path value:  
```bash
    # navigate to the data folder you created earlier
    cd NextGen/ngen-data/my_data
    pwd
    # and copy the path

```
where <path> is the location of the folder with your data in it.
    
- The script sets the entered directory as the `HOST_DATA_PATH` variable and uses it to find all the catchment, nexus, and realization files using the `find` command.
- Next, the user is asked whether to run NextGen or exit. If `run_NextGen` is selected, the script pulls the related image from the awiciroh DockerHub, based on the local machine's architecture:
```
For Mac with apple silicon (arm architecture), it pulls awiciroh/ciroh-ngen-image:latest.
For x86 machines, it pulls awiciroh/ciroh-ngen-image:latest-x86.
```

- The user is then prompted to select whether they want to run the model in parallel or serial mode.
- If the user selects parallel mode, the script uses the `mpirun` command to run the model and generates a partition file for the NGEN model.
- If the user selects the catchment, nexus, and realization files they want to use.

Example NGEN run command for parallel mode: 
```bash
/dmod/bin/partitionGenerator "/ngen/ngen/data/config/catchments.geojson" "/ngen/ngen/data/config/nexus.geojson" "partitions_2.json" "2" '' ''
mpirun -n 2 /dmod/bin/ngen-parallel \
/ngen/ngen/data/config/catchments.geojson "" \
/ngen/ngen/data/config/nexus.geojson "" \
/ngen/ngen/data/config/awi_simplified_realization.json \
/ngen/partitions_2.json
```
- If the user selects serial mode, the script runs the model directly.

Example NGEN run command for serial mode: 
```bash
/dmod/bin/ngen-serial \
/ngen/ngen/data/config/catchments.geojson "" \
/ngen/ngen/data/config/nexus.geojson "" \
/ngen/ngen/data/config/awi_simplified_realization.json
```
- After the model has finished running, the script prompts the user whether they want to continue.
- If the user selects 1, the script opens an interactive shell.
- If the user selects 2, then the script exits.

### Output of the model guide script

The output files are copied to the `outputs` folder in the '/NextGen/ngen-data/my_data/' directory you created in the first step

Using the *flowveldepth.csv files from the 'outputs' folder, the streamflow at the Clear Creek gauge (USGS site ID 02450825) is displayed here. Below is the 'Modelled' vs 'Observed' plot generated in MS Excel after *flowveldepth.csv files are post-processed using Python.

![image](https://github.com/shahab122/NGIAB-CloudInfra/assets/28275758/58aaf351-8bb5-4b61-9f84-d9dd520053e5)


