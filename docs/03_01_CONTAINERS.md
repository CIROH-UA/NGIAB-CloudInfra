# Containers and Guide Scripts

NGIAB includes a series of guide scripts that invoke both NGIAB itself and several associated utilities from the NGIAB ecosystem. This page will provide information on what these containers are, how to invoke them through the guide scripts, and how they can be called upon manually.

> Remember: for most users, the guide scripts are the best way to invoke NGIAB-related containers. Manually running the containers is mostly useful for automation, custom scripting, and other development purposes.

## NGIAB Docker distribution ([`awiciroh/ciroh-ngen-image`](https://hub.docker.com/r/awiciroh/ciroh-ngen-image/tags))

This image is **the core NGIAB distribution** for non-HPC environments. It contains everything you need to run the NextGen framework, along with a core series of common NextGen-compatible models. For the specifics of which models are included by default, see [3.4. Included Models](./03_04_MODELS.md).

The NGIAB image builds from this repository's `docker/` folder. The following command is used to build it locally:
```bash
cd docker
docker build -f Dockerfile -t awiciroh/ciroh-ngen-image:latest . --no-cache
```

### Input and output
To run NGIAB, you'll need a valid [NGIAB model run directory](./03_03_RUN_DIRECTORIES.md). These directories define the datasets, forcings, and model configuration that NGIAB should pass to the NextGen framework.

If you're still getting started with NGIAB, consider using the [Data Preprocess](https://docs.ciroh.org/training-NGIAB-101/data-preparation.html) tool to prepare these.

The model outputs will be saved to the `outputs/` subfolder of the model run directory, alongside additional `metadata/` and `forcings/` subfolders.

### Running from a guide script
Running `guide.sh` will prompt you to provide a path to your model run directory. After that, it'll automatically begin running NGIAB.

When NGIAB starts up, you will be asked whether you'd like to run in "Serial" or "Parallel" mode. This determines whether the simulation will run on a single thread or across multiple processes. **Pick "Parallel" if you're unsure**, as most modern computers are designed to take full advantage of multithreaded processing.

> The "Run Bash Shell" and "Interactive-Shell" options provide CLI access to the container, allowing its contents to be explored if needed. In practice, this is rarely useful outside of development and debugging.

> **`guide.sh` flags:**  
> `-d [path]`: Designates the provided path as the data directory to import into the visualizer.  
> `-h`: Displays usage information, then exits.  
> `-i [image]`: Specifies which Docker image of NGIAB to run.  
> `-r`: Retains previous console output when launching the script.  
> `-t [tag]`: Specifies which Docker image tag of NGIAB to run.  

### Running the container manually
For most purposes, the `latest` tag will always be the most appropriate option, offering builds for both AMD64 and ARM64 architectures. However, if you find that Docker is pulling the wrong architecture for your system, then `latest-amd64` and `latest-arm64` are available as aliases.

The following Docker command will launch and run an instance of NGIAB, where `[RUN_DIR]` is replaced with the absolute path of your model run directory:
```bash
docker run --rm -it -v "[RUN_DIR]:/ngen/ngen/data" "awiciroh/ciroh-ngen-image:latest" /ngen/ngen/data/ [auto]
```
Here's a breakdown of what this command does:
- `--rm` instructs Docker to tear down and delete the container upon exiting. This is important for saving storage.
- `-it` is a pair of standard flags that facilitate CLI access to the container.
- `-v "[RUN_DIR]:/ngen/ngen/data"` mounts your run directory's contents to `mgen/ngen/data/` within the container.
- `"awiciroh/ciroh-ngen-image:latest"` identifies the image. (All remaining arguments after this one are passed to the container entrypoint script.)
- `ngen/ngen/data/` tells the container entrypoint script where the mounted data is.
- `auto` is an optional argument. If it is included, the container will automatically perform a parallel run of NextGen. Otherwise, an interactive prompt will offer a choice between serial and parallel options.

Note that all execution is facilitated by the container entrypoint script, `HelloNGEN.sh`, which can be found in this repository's `Docker` folder. As such, even if you're running the container manually, you won't need to worry about the finer details of starting up a NextGen run.


## NGIAB TEEHR Integration ([`awiciroh/ngiab-teehr`](https://hub.docker.com/r/awiciroh/ngiab-teehr/tags))

This image runs the NGIAB TEEHR integration, which automatically performs comparisons with NWM and USGS data, calculates preliminary metrics, and prepares your model output for in-depth evaluation with the [TEEHR library](https://rtiinternational.github.io/teehr/).

The image is built from the [ngiab-teehr](https://github.com/CIROH-UA/ngiab-teehr) repository.

### Input and output
The TEEHR integration takes an already-executed NGIAB model run directory as input.The evaluated results will be saved to the `TEEHR/` subfolder of the model run directory.

Note that the TEEHR integration will **fully overwrite the run directory's contents**. If you'd like to retain your run directory for any reason, saving a backup is strongly recommended.

### Running from a guide script
After `guide.sh` completes an NGIAB run, it will optionally ask to run the TEEHR integration. If selected, this will launch the `runTeehr.sh` script. `runTeehr.sh` can also be run independently if desired.

Once run, `runTeehr.sh` will prompt for a data path and an image tag. If the script is being run immediately after an NGIAB execution, both the most recent path and recommended tag will most likely be correct. From there, execution will begin automatically.

> **`runTeehr.sh` flags:**  
> `-d [path]`: Designates the provided path as the data directory to evaluate.  
> `-h`: Displays usage information, then exits.  
> `-i [image]`: Specifies which Docker image of the TEEHR container to run.  
> `-r`: Retains previous console output when launching the script.  
> `-t [tag]`: Specifies which Docker image tag of the TEEHR container to run.  
> `-y`: Launches the evaluation workflow immediately, skipping the initial confirmation prompt.  

### Running the container manually
The TEEHR integration offers both `latest` and `x86` tags, which support ARM64 and AMD64 systems, respectively. Be sure to choose the appropriate tag for your system's architecture.

The following Docker command will launch and run the TEEHR integration, where `[RUN_DIR]` is replaced with the absolute path of your model run directory:
```bash
docker run --rm -v "[RUN_DIR]:/app/data" "awiciroh/ngiab-teehr:[tag]"
```
Here's a breakdown of what this command does:
- `--rm` instructs Docker to tear down and delete the container upon exiting. This is important for saving storage.
- `-v "[RUN_DIR]:/ngen/ngen/data"` mounts your data folder's contents to `app/data/` within the container.
- `"awiciroh/ngiab-teehr:[tag]"` identifies the image. Be sure to select the correct tag for your system.


## NGIAB Data Visualizer ([`awiciroh/tethys-ngiab`](https://hub.docker.com/r/awiciroh/tethys-ngiab/tags))

This image runs the NGIAB Data Visualizer. This tool offers a spatial web-based exploration of your model outputs powered by [Tethys Platform](https://www.tethysplatform.org/).

The image is built from the [ngiab-client](https://github.com/CIROH-UA/ngiab-client) repository.

### Input and output
The Data Visualizer takes an already-executed NGIAB model run directory as input. It will not alter the folder's contents.

The Data Visualizer's outputs are stored in the `ngiab_visualizer/` subfolder of your user home folder. As such, the Data Visualizer will retain model outputs for display between sessions.

### Running from a guide script
After `guide.sh` completes an NGIAB run, it will optionally ask to run the Data Visualizer. If selected, this will launch the `viewOnTethys.sh` script. `viewOnTethys.sh` can also be run independently if desired.

Once run, `viewOnTethys.sh` will prompt for a data path and an image tag. If the script is being run immediately after an NGIAB execution, both the most recent path and recommended tag will most likely be correct. It will then request a port; this should only need to be changed if port 80 is occupied or in certain SSH configurations. From there, follow the on-screen instructions.

For more information on using the visualizer, please see the [ngiab-client](https://github.com/CIROH-UA/ngiab-client) repository.
<!-- TODO: Update link target once visualizer docs are ready -->

> **`viewOnTethys.sh` flags:**  
> `-d [path]`: Designates the provided path as the data directory to import into the visualizer.  
> `-h`: Displays usage information, then exits.  
> `-i [image]`: Specifies which Docker image of the visualizer to run.  
> `-n`: Launches the visualizer immediately without importing a data directory.  
> `-r`: Retains previous console output when launching the script.  
> `-t [tag]`: Specifies which Docker image tag of the visualizer to run.  
> `-y`: Immediately requests to import a data directory.  

### Running the container manually
Due to the complexity of launching the Data Visualizer, launching it without using a guide script is not currently recommended. If necessary, please reference `viewOnTethys.sh` for more details on this process. 