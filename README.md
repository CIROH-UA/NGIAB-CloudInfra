# NextGen In A Box (NGIAB)

> Run the NextGen National Water Resources Modeling Framework locally with ease.

[NGIAB](https://ngiab.ciroh.org) provides a containerized and user-friendly solution for running the NextGen framework, allowing you to control inputs, configurations, and execution on your local machine.

<p align="center">
<img src="./docs/img/ngiab.png" width="300">
</p>

| | |
| --- | --- |
| ![CIROH Logo](./docs/img/ciroh-bgsafe.png) | Funding for this project was provided by the National Oceanic & Atmospheric Administration (NOAA), awarded to the Cooperative Institute for Research to Operations in Hydrology (CIROH) through the NOAA Cooperative Agreement with The University of Alabama (NA22NWS4320003). |

[![ARM Build and push final image](https://github.com/CIROH-UA/NGIAB-CloudInfra/actions/workflows/docker_image_main_branch.yml/badge.svg)](https://github.com/CIROH-UA/NGIAB-CloudInfra/actions/workflows/docker_image_main_branch.yml)

## Features

- **Run NextGen Locally**: Experiment with the framework on your machine
- **Control Over Inputs**: Choose specific regions/basins and modify input data
- **Simplified Setup**: Easy deployment using Docker containers
- **Open Research**: Promotes transparency through open-source tooling
- **Evaluation Tools**: Integrated TEEHR evaluation capabilities
- **Visualization**: Built-in support for output visualization via Tethys Platform

| | |
| --- | --- | 
| ![Nexus Output](./docs/img/Provo_GeoSpatial.png) | ![Catchment Time Series](./docs/img/Provo_catchments.png) |

| | |
| --- | --- | 
| ![Teehr Plot](./docs/img/Provo_nexus_point.png) | ![Teehr Metrics](./docs/img/Provo_teehr_metrics.png) |

> 🔗 For more information on this case study, including calibration files, input data, and setup details, visit the [HydroShare resource page for the Provo River near Woodland NGIAB Case Study](https://www.hydroshare.org/resource/88e0ebf2719c492381efcb27fba71032/).

## Navigating this repository

### For general use

- **NGIAB Guide Scripts**: This repository holds several guide scripts: `guide.sh`, `runTeehr.sh`, and `viewOnTethys.sh`. These scripts are the recommended way to run NGIAB.
  - To see CLI flags for these scripts, execute them with `-h` or see the documentation on [containers and guide scripts](./docs/03_01_CONTAINERS.md).

- **Documentation**: The [`docs/` folder](./docs/00_CONTENTS.md) contains information on all of the finer details that can help you get the most out of the contents of this repository.
  - For broader ecosystem-wide documentation, please visit DocuHub at [docs.ciroh.org/products/ngiab](https://docs.ciroh.org/products/ngiab), where all of the information from this and other NGIAB repositories is mirrored.

### For development

- `docker/`: This folder contains the Dockerfile and entrypoint for the NGIAB container. See [Section 3.1](./docs/03_01_CONTAINERS.md) of the documentation for more information.
    - Releases built from this folder are available at [https://hub.docker.com/r/awiciroh/ciroh-ngen-image](https://hub.docker.com/r/awiciroh/ciroh-ngen-image).
- `.github/`: Workflows, issue templates, and other GitHub-focused configuration files.
- `archive/`: Older files that are no longer maintained.

## Contributing

Interested in contributing? Please see our [contribution guide](05_CONTRIBUTE.md) for more information.

## Contributors
- Arpita Patel, Alabama Water Institute, CIROH (apatel54@ua.edu)
- Benjamin Lee, Alabama Water Institute, CIROH (blee60@ua.edu)
- Zach Wills, Lynker (zwills@lynker.com)
- Nels Frazier, Lynker (nfrazier@lynker.com)
- Josh Cunningham, Alabama Water Institute, CIROH (jcunningham8@ua.edu)
- Gio Romero, Aquaveo (gromero@aquaveo.com)
- Sam Lamont, RTI International (slamont@rti.org)
- Matthew Denno, RTI International (mdenno@rti.org)
- James Halgren, Alabama Water Institute, CIROH (jshalgren@ua.edu)

> This repository was originally forked from [AlabamaWaterInstitute/CloudInfra](https://github.com/AlabamaWaterInstitute/CloudInfra), which has now been  deprecated and archived.

## Sponsorship
- NOAA Cooperative Institute for Research to Operations in Hydrology ([CIROH](https://ciroh.org))
Project: CIROH: Community Water Model Infrastructure, Stewardship, and Integration (PI - Steven Burian)
Project: [Advancing Community NextGen and NextGen In A Box (NGIAB) – Paving the Pathway to Operations](https://ciroh.ua.edu/research-projects/advancing-community-nextgen-and-nextgen-in-a-box-ngiab-paving-the-pathway-to-operations/) (PI - Arpita Patel)

## Additional resources

- [NGIAB Website](https://ngiab.ciroh.org)
- [NGIAB 101 Training Module](https://docs.ciroh.org/training-NGIAB-101/)
- [NGIAB on DocuHub](https://docs.ciroh.org/)

### Upstream repositories
- [NextGen Framework Prototype](https://github.com/NOAA-OWP/ngen)
- [Community ngen Repository](https://github.com/CIROH-UA/ngen)
- [Community troute Repository](https://github.com/CIROH-UA/t-route)

### NGIAB ecosystem
- [NGIAB Data Preprocess](https://github.com/CIROH-UA/NGIAB_data_preprocess)
- [NGIAB TEEHR Integration](https://github.com/CIROH-UA/ngiab-teehr)
- [NGIAB Data Visualizer](https://github.com/CIROH-UA/ngiab-client)
- [DataStreamCLI and Research Datastream](https://github.com/CIROH-UA/ngen-datastream/tree/main)
- [NGIAB Calibration](https://github.com/CIROH-UA/ngiab-cal)