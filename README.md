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
```bash
wget https://ciroh-ua-ngen-data.s3.us-east-2.amazonaws.com/AWI-007/AWI_16_2863657_007.tar.gz
tar -xf AWI_16_2863657_007.tar.gz
```

### 3. Clone and Run
```bash
cd NextGen
git clone https://github.com/CIROH-UA/NGIAB-CloudInfra.git
cd NGIAB-CloudInfra
./guide.sh
```

## Case Study: Provo River Basin, UT

![Provo River Basin Map](https://github.com/CIROH-UA/NGIAB-CloudInfra/blob/main/image/README/VPU16_007.png)

This repository includes a complete case study of the Provo River Basin, demonstrating NGIAB's capabilities in a real-world scenario.

## Output Visualization

NGIAB provides comprehensive visualization options through the Tethys Platform:

1. **Geospatial Visualization**
   ![Nexus Output](https://github.com/CIROH-UA/NGIAB-CloudInfra/blob/main/image/README/outputnexus.png)

2. **Time Series Analysis**
   - Catchments
     ![Catchment Time Series](https://github.com/CIROH-UA/NGIAB-CloudInfra/blob/main/image/README/outputcat.png)
   - Nexus Points
     ![Nexus Time Series](https://github.com/CIROH-UA/NGIAB-CloudInfra/blob/main/image/README/outputnexusteehr.png)

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

Note: For ARM64 architecture, use `latest` tag; for X86 architecture, use `latest-x86` tag.

## Additional Resources

- [End-to-End Setup Guide](https://docs.ciroh.org/docs/products/Community%20Hydrologic%20Modeling%20Framework/nextgeninaboxDocker/workflow)
- [NextGen Framework Prototype](https://github.com/NOAA-OWP/ngen)
- [Community ngen Repository](https://github.com/CIROH-UA/ngen)
- [Community troute Repository](https://github.com/CIROH-UA/t-route)
- [NGIAB Data Preprocessor](https://github.com/AlabamaWaterInstitute/NGIAB_data_preprocess)
- [ngen-datastream Repository](https://github.com/CIROH-UA/ngen-datastream/tree/main)
