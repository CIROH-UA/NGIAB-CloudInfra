# NextGen In A Box (NGIAB)

> Run the NextGen National Water Resources Modeling Framework locally with ease.

NGIAB provides a containerized and user-friendly solution for running the NextGen framework, allowing you to control inputs, configurations, and execution on your local machine.

<p align="center">
<img src="https://github.com/CIROH-UA/NGIAB-CloudInfra/blob/main/image/README/ngiab.png" width="300">
</p>

| | |
| --- | --- |
| ![CIROH Logo](https://ciroh.ua.edu/wp-content/uploads/2022/08/CIROHLogo_200x200.png) | Funding for this project was provided by the National Oceanic & Atmospheric Administration (NOAA), awarded to the Cooperative Institute for Research to Operations in Hydrology (CIROH) through the NOAA Cooperative Agreement with The University of Alabama (NA22NWS4320003). |

[![ARM Build and push final image](https://github.com/CIROH-UA/NGIAB-CloudInfra/actions/workflows/docker_image_main_branch.yml/badge.svg)](https://github.com/CIROH-UA/NGIAB-CloudInfra/actions/workflows/docker_image_main_branch.yml)

## Features

- **Run NextGen Locally**: Experiment with the framework on your machine
- **Control Over Inputs**: Choose specific regions/basins and modify input data
- **Simplified Setup**: Easy deployment using Docker containers
- **Open Research**: Promote transparency through open-source tools
- **Visualization**: Built-in support for output visualization
- **Evaluation Tools**: Integrated TEEHR evaluation capabilities

## Prerequisites

### Windows
1. **Install WSL**
   ```bash
   wsl --install
   # If the above doesn't work, try:
   sudo apt install wsl
   ```

2. **Install Docker Desktop**
   - Download from [Docker's official website](https://docs.docker.com/desktop/install/windows-install/#install-docker-desktop-on-windows)
   - Launch Docker Desktop
   - Open WSL as Administrator
   - Verify installation: `docker ps -a`

### Mac
1. **Install Docker Desktop**
   - Download from [Docker's Mac installer page](https://docs.docker.com/desktop/install/mac-install/)
   - Launch Docker Desktop
   - Verify installation: `docker ps -a`

### Linux
1. **Install Docker**
   - Follow [Linux installation guide](https://docs.docker.com/desktop/install/linux-install/)
   - Start Docker service
   - Verify installation: `docker ps -a`

## Quick Start Guide

### 1. Set Up Project Directory
```bash
mkdir -p NextGen/ngen-data
cd NextGen/ngen-data
```

### 2. Download Sample Data
#### Option 1: AWI-009 input data (realization file includes - SLOTH, NoahOWP, CFE) - calibrated realization file for Provo River near Woodland, UT
```bash
wget https://ciroh-ua-ngen-data.s3.us-east-2.amazonaws.com/AWI-009/AWI_16_10154200_009.tar.gz
tar -xf AWI_16_2863657_007.tar.gz
```
#### Option 2: AWI-007 input data (realization file includes - SLOTH, NoahOWP, CFE)
```bash
wget https://ciroh-ua-ngen-data.s3.us-east-2.amazonaws.com/AWI-007/AWI_16_2863657_007.tar.gz
tar -xf AWI_16_2863657_007.tar.gz
```
#### Option 3: AWI-008 input data (realization file includes - SLOTH, Demostration LSTM)
```bash
wget --no-parent https://ciroh-ua-ngen-data.s3.us-east-2.amazonaws.com/AWI-008/AWI_16_2863806_008.tar.gz
tar -xf AWI_16_2863806_008.tar.gz
```

### 3. Clone and Run
```bash
cd NextGen
git clone https://github.com/CIROH-UA/NGIAB-CloudInfra.git
cd NGIAB-CloudInfra
./guide.sh
```

### 4. NextGen Run Directory Structure (`ngen-run/`)

Running NextGen requires building a standard run directory complete with only the necessary files. Below is an explanation of the standard. Reference for discussion of the standard [here](https://github.com/CIROH-UA/NGIAB-CloudInfra/pull/17).

A NextGen run directory `ngen-run` is composed of three necessary subfolders `config, forcings, outputs` and an optional fourth subfolder `metadata`.

```
ngen-run/
│
├── config/
│
├── forcings/
│
├── lakeout/
|
├── metadata/
│
├── outputs/
│
├── restart/
```

The `ngen-run` directory contains the following subfolders:

- `config`:  model configuration files and hydrofabric configuration files. A deeper explanation [here](#configuration-directory-ngen-runconfig)
- `forcings`: catchment-level forcing timeseries files. These can be generated with the [forcingprocessor](https://github.com/CIROH-UA/ngen-datastream/tree/main/forcingprocessor). Forcing files contain variables like wind speed, temperature, precipitation, and solar radiation.
- `lakeout`: for t-route 
- `metadata` is an optional subfolder. This is programmatically generated and it used within to ngen. Do not edit this folder.
- `outputs`: This is where ngen will place the output files.
- `restart`: For restart files
 
#### Configuration directory `ngen-run/config/`
This folder contains the NextGen realization file, which serves as the primary model configuration for the ngen framework. This file specifies which models to run and with which parameters, run parameters like date and time, and hydrofabric specifications.

Based on the models defined in the realization file, BMI configuration files may be required. For those models that require per-catchment configuration files, a folder will hold these files for each model in `ngen-run/config/cat-config`. See [here](https://github.com/CIROH-UA/ngen-datastream/blob/main/docs/NGEN_MODULES.md) for which models ngen-datastream supports automated BMI configuration file generation. See the directory structure convention below.

```
ngen-run/
|
├── config/
|   │
|   ├── nextgen_09.gpkg
|   |
|   ├── realization.json
|   |
|   ├── ngen.yaml
|   |
|   ├── cat-config/
|   │   |
|   |   ├──PET/
|   │   |
|   |   ├──CFE/
|   │   |
|   |   ├──NOAH-OWP-M/
...
```

Hydrofabric Example files: `conus_nextgen.gpkg`
NextGen requires a single geopackage file. This file is the [hydrofabric](https://mikejohnson51.github.io/hyAggregate/) (spatial data). An example geopackage can be found on Lynker-Spatial [here](https://www.lynker-spatial.com/data?path=hydrofabric%2Fv2.2%2F). Tools to subset a geopackage into a smaller domain can be found at [Lynker's hfsubset](https://github.com/LynkerIntel/hfsubset). 

## Case Study: Provo River Basin, UT

![Provo River Basin Map](https://github.com/CIROH-UA/NGIAB-CloudInfra/blob/main/image/README/VPU16_007.png)

This repository includes a complete case study of the Provo River Basin, demonstrating NGIAB's capabilities in a real-world scenario.
1. **Geospatial Visualization**
   ![Nexus Output](https://github.com/CIROH-UA/NGIAB-CloudInfra/blob/main/image/README/outputnexus.png)

2. **Time Series Analysis**
   - Catchments
     ![Catchment Time Series](image/README/Provo_catchments.png)
   - Nexus Points
     ![Nexus Time Series](image/README/Provo_nexus_point.png) 

## Advanced Usage

### Running the Visualizer
```bash
./viewOnTethys.sh
```

### Building NGIAB Locally
```bash
cd docker
docker build -f Dockerfile -t awiciroh/ciroh-ngen-image:latest . --no-cache
```

## Additional Resources

- [End-to-End Setup Guide](https://docs.ciroh.org/docs/products/Community%20Hydrologic%20Modeling%20Framework/nextgeninaboxDocker/workflow)
- [NextGen Framework Prototype](https://github.com/NOAA-OWP/ngen)
- [Community ngen Repository](https://github.com/CIROH-UA/ngen)
- [Community troute Repository](https://github.com/CIROH-UA/t-route)
- [NGIAB Data Preprocessor](https://github.com/AlabamaWaterInstitute/NGIAB_data_preprocess)
- [ngen-datastream Repository](https://github.com/CIROH-UA/ngen-datastream/tree/main)
- [NGIAB TEEHR Integration](https://github.com/CIROH-UA/ngiab-teehr)
- [Data Visualizer](https://github.com/CIROH-UA/ngiab-client)
   
