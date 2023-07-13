# Welcome to NextGen Framework National Water Model Community Repo. (NextGen In A Box).

We are doing a case study : NWM run for Sipsey Fork,Black Warrior river
- We don’t want to run all of CONUS
- We want to run NextGen locally
- We want to have control over inputs / config.
- How can we do it? Answer: NextGen In A Box

This repository contains :
- **Dockerfile** for running NextGen Framework (docker/Dockerfile*)
- **Terraform** configuration files for provisioning infrastructure in AWS (terraform/README.md)
- Documentation of how to use the **infrastructure** and run the model. (README.md)

## Table of Contents
* [Prerequisites:](#prerequisites-)
    + [Install docker](#install-docker-)
    + [Install WSL on Windows](#Install-WSL-on-Windows-)
    + [Download the input data in "ngen-data" folder from S3 bucket ](#download-the-input-data-in--ngen-data--folder-from-s3-bucket--)
      - [Linux & Mac](#linux---mac)
      - [Windows Steps:](#windows-steps-)
  * [Run NextGen-In-A-Box](#run-nextgen-in-a-box)
    + [Clone CloudInfra repo](#clone-cloudinfra-repo)
    + [How to run the model script?](#how-to-run-the-model-script-)
    + [Output of the model script](#output-of-the-model-script)


## Prerequisites:

### Install docker and validate docker is up:
    - On *Windows*:
        - [Install Docker Desktop on Windows](https://docs.docker.com/desktop/install/windows-install/#install-docker-desktop-on-windows)
        - Once docker is installed, start Docker Destop.
        - Open powershell -> right click and `Run as an Administrator` 
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

1. Open **PowerShell** as an administrator.

2. Run the following command to enable WSL feature:
    ```
    wsl --install
    ```

3. Wait for the installation to complete. It may take some time as it will download and install the necessary components.

4. Once the installation is finished, you will be prompted to restart your computer. Type `Y` and press Enter to restart.

5. After the computer restarts, open **Microsoft Store**.

6. Search for "WSL" or "Windows Subsystem for Linux" in the search bar.

7. Select the desired Linux distribution (e.g., Ubuntu, Debian, Fedora) from the search results.

8. Click on the distribution and then click the **Install** button.

9. Wait for the installation to complete. The installation process will download the Linux distribution package from the Microsoft Store.

10. Once the installation is finished, you can launch the Linux distribution from the Start menu or by running its command (e.g., `ubuntu`).

11. The first time you launch the Linux distribution, it will take some time to set up. Follow the on-screen instructions to create a username and password.

12. After the setup is complete, you can use the Linux distribution through WSL on your Windows system.

    
### Download the input data in "ngen-data" folder from S3 bucket :

#### Linux & Mac & WSL

```Linux   
    $ mkdir NextGen
    $ cd NextGen
    $ mkdir ngen-data
    $ cd ngen-data
    $ wget --no-parent https://ciroh-ua-ngen-data.s3.us-east-2.amazonaws.com/AWI-001/AWI_03W_113060_001.tar.gz
    $ tar -xf AWI_03W_113060_001.tar.gz 
    $ cd AWI_03W_113060_001
```


#### Windows Steps:
#### Note: It is recommended to use WSL and follow [instructions for Linux & Mac & WSL](#Linux-&-Mac-&-WSL-)

```Windows  
    $ mkdir NextGen
    $ cd NextGen
    $ mkdir ngen-data
    $ cd ngen-data
    $ Invoke-WebRequest -Uri "https://ciroh-ua-ngen-data.s3.us-east-2.amazonaws.com/AWI-001/AWI_03W_113060_001.tar.gz"
    $ tar -xzf "\AWI_03W_113060_001.tar.gz"
    $ cd AWI_03W_113060_001
```

## Run NextGen In A Box

### Clone CloudInfra repo

Navigate to NextGen directory and clone the repo using below commands:

```
$ git clone https://github.com/CIROH-UA/CloudInfra.git

$ cd CloudInfra
```  
Once you are in *CloudInfra* directory, you should see `guide.sh` in it. Now, we are ready to run the model using that script. 

### How to run the model script?

#### WSL, Linux and Mac Steps:
Follow below steps to run `guide.sh` script 
```
    # Note: Make sure you are in ~/Documents/NextGen/CloudInfra directory
    $ ./guide.sh   
    
```
### Output of the model guide script

>*What you will see when you run above `guide.sh`?*

- The script prompts the user to enter the file path for the input data directory where the forcing and config files are stored. 

Run the following command based on your OS and copy the path value:

 **Windows:**
```
C:> cd ~\<path>\NextGen\ngen-data
c:> pwd
and copy the path
```

 **Linux/Mac:**
```
$ cd ~/<path>/NextGen/ngen-data
$ pwd
and copy the path

```
where <path> is the localtion of NextGen folder.
    
- The script sets the entered directory as the `HOST_DATA_PATH` variable and uses it to find all the catchment, nexus, and realization files using the `find` command.
- Next, the user is asked whether to run NextGen or exit. If `run_NextGen` is selected, the script pulls the related image from the awiciroh Dockerhub, based on the local machine's architecture:
```
For Mac (arm architecture), it pulls awiciroh/ciroh-ngen-image:latest-arm.
For x86 machines, it pulls awiciroh/ciroh-ngen-image:latest-x86.
```

- The user is then prompted to select whether they want to run the model in parallel or serial mode.
- If the user selects parallel mode, the script uses the `mpirun` command to run the model and generates a partition file for the NGEN model.
- If the user selects the catchment, nexus, and realization files they want to use.

Example NGEN run command for parallel mode: 
```
mpirun -n 2 /dmod/bin/ngen-parallel 
/ngen/ngen/data/config/catchments.geojson "" 
/ngen/ngen/data/config/nexus.geojson "" 
/ngen/ngen/data/config/awi_simplified_realization.json 
/ngen/partitions_2.json
```
- If the user selects serial mode, the script runs the model directly.

Example NGEN run command for serial mode: 
```
/dmod/bin/ngen-serial 
/ngen/ngen/data/config/catchments.geojson "" 
/ngen/ngen/data/config/nexus.geojson "" 
/ngen/ngen/data/config/awi_simplified_realization.json
```
- After the model has finished running, the script prompts the user whether they want to continue.
- If the user selects 1, the script opens an interactive shell. If the user selects 2, then the script copies the output data from container to local machine.
- If the user selects 3, then the script exits.

The output files are copied to the `outputs` folder in '/NextGen/ngen-data/AWI_03W_113060_001/' directory.
