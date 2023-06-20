NextGen guide instructions


# Before you run it
The guide script will prompt the user for an absolute path to the ngen input data. That directory must follow this format:
```

├── config
│   ├── catchment.geojson
│   ├── nexus.geojson
│   ├── realization.json
├── forcings
├── outputs

Make sure your working directory is the same as the guide's parent directory.

```

# Run it
If you're using a linux host: `bash guide.sh`

If you're using a window shost `.\guide.ps1` .

Script will prompt user: `Enter your data directory file path: `

User will be prompted to either run ngen, or exit

If running ngen, based on the host machine's architecture, a docker ngen image will be pulled and run (awiciroh/ciroh-ngen-image). The docker container will mount the user provided data directory to the container at `/ngen/ngen/data`

# awiciroh/ciroh-ngen-image

User will be prompted to select to run ngen serially, in parallel, bash, or quit

User will be prompted to select which configuration files to input to ngen. Make sure to input the full paths.

If ngen-parallel is chosen, a partition file will be generated for two processors and then executed with MPI.

After the run completes, user will be prompted to either enter an interactive shell, copy the output data, or exit.

