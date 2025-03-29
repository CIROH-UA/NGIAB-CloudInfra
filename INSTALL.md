# Installation instructions

Detailed instructions on how to install, configure, and get the project running.

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

## Quick Start Setup

### 1. Set Up Project Directory

```bash
mkdir -p NextGen/ngen-data
cd NextGen/ngen-data
```

### 2. Download Sample Data

#### Option 1: AWI-007 input data (realization file includes - SLOTH, NoahOWP, CFE)

```bash
wget https://ciroh-ua-ngen-data.s3.us-east-2.amazonaws.com/AWI-007/AWI_16_2863657_007.tar.gz
tar -xf AWI_16_2863657_007.tar.gz
```

#### Option 2: AWI-008 input data (realization file includes - SLOTH, Demostration LSTM)

```bash
wget --no-parent https://ciroh-ua-ngen-data.s3.us-east-2.amazonaws.com/AWI-008/AWI_16_2863806_008.tar.gz
tar -xf AWI_16_2863806_008.tar.gz
```

### 3. Clone and Run

The `guide.sh` script will install some of the necessary dependencies and run the project.

```bash
cd NextGen
git clone https://github.com/CIROH-UA/NGIAB-CloudInfra.git
cd NGIAB-CloudInfra
./guide.sh
```
