# Building the NGIAB Docker Container

## Building the container locally

The NGIAB image builds from this repository's `docker/` folder. The following command is used to build it locally:

```bash
cd docker
docker build -f Dockerfile -t awiciroh/ciroh-ngen-image:latest . --no-cache
```

For reference, building the image from scratch on a 16-core, 64 GB RAM MacBook Pro with an M4 Max chip takes about 6.5 minutes.

## Running a local version of the container

To run NGIAB, you'll need a valid [NGIAB model run directory](./03_03_RUN_DIRECTORIES.md). These directories define the datasets, forcings, and model configuration that NGIAB should pass to the NextGen framework.

If you're still getting started with NGIAB, consider using the [Data Preprocess](https://docs.ciroh.org/training-NGIAB-101/data-preparation.html) tool to prepare these.

The model outputs will be saved to the `outputs/` subfolder of the model run directory, alongside additional `metadata/` and `forcings/` subfolders.

The following Docker command will launch and run an instance of NGIAB, where `[RUN_DIR]` is replaced with the absolute path of your model run directory:

```bash
# Interactive (choose serial/parallel)
docker run --rm -it -v "[RUN_DIR]:/ngen/ngen/data" "awiciroh/ciroh-ngen-image:latest" /ngen/ngen/data
# Auto mode (parallel)
docker run --rm -it -v "[RUN_DIR]:/ngen/ngen/data" "awiciroh/ciroh-ngen-image:latest" /ngen/ngen/data auto
```

Here's a breakdown of what this command does:

- `--rm` instructs Docker to tear down and delete the container upon exiting. This is important for saving storage.
- `-it` is a pair of standard flags that facilitate CLI access to the container.
- `-v "[RUN_DIR]:/ngen/ngen/data"` mounts your run directory's contents to `/ngen/ngen/data/` within the container.
- `"awiciroh/ciroh-ngen-image:latest"` identifies the image. (All remaining arguments after this one are passed to the container entrypoint script.)
- `/ngen/ngen/data/` tells the container entrypoint script where the mounted data is.
- `auto` is an optional argument. If it is included, the container will automatically perform a parallel run of NextGen. Otherwise, an interactive prompt will offer a choice between serial and parallel options.

Note that all execution is facilitated by the container entrypoint script, `HelloNGEN.sh`, which can be found in this repository's `docker/` folder. As such, even if you're running the container manually, you won't need to worry about the finer details of starting up a NextGen run.

## Modifying the container

### Changing the build flags

The build flags for `ngen` are in the Dockerfile:

```Dockerfile
# Define common build arguments
ARG COMMON_BUILD_ARGS="-DNGEN_WITH_EXTERN_ALL=ON \
    -DNGEN_WITH_NETCDF:BOOL=ON \
    -DNGEN_WITH_BMI_C:BOOL=ON \
    -DNGEN_WITH_BMI_FORTRAN:BOOL=ON \
    -DNGEN_WITH_PYTHON:BOOL=ON \
    -DNGEN_WITH_ROUTING:BOOL=ON \
    -DNGEN_WITH_SQLITE:BOOL=ON \
    -DNGEN_WITH_UDUNITS:BOOL=ON \
    -DUDUNITS_QUIET:BOOL=ON \
    -DNGEN_WITH_TESTS:BOOL=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=. \
    -DCMAKE_CXX_FLAGS='-fuse-ld=lld'"
# lld is the linker, it's faster than the default
```

Generally, the defaults are sufficient, but you can edit the values. Here is a description of each of the `COMMON_BUILD_ARGS`:

- `NGEN_WITH_EXTERN_ALL`: Build with all extern-distributed modules.
- `NGEN_WITH_NETCDF`: Build with NetCDF support.
- `NGEN_WITH_BMI_C`: Build with C BMI support.
- `NGEN_WITH_BMI_FORTRAN`: Build with Fortran BMI support.
- `NGEN_WITH_PYTHON`: Build with embedded Python support.
- `NGEN_WITH_ROUTING`: Build with t-route integration.
- `NGEN_WITH_SQLITE`: Build with SQLite3 support.
- `NGEN_WITH_UDUNITS`: Build with UDUNITS2 support.
- `UDUNITS_QUIET`: Silence UDUNITS2 output.
- `NGEN_WITH_TESTS`: Build with unit tests.
- `CMAKE_BUILD_TYPE`: See the [CMake docs](https://cmake.org/cmake/help/latest/variable/CMAKE_BUILD_TYPE.html).
- `CMAKE_INSTALL_PREFIX`: See the [CMake docs](https://cmake.org/cmake/help/latest/variable/CMAKE_INSTALL_PREFIX.html).
- `CMAKE_CXX_FLAGS`: See the [CMake docs](https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_FLAGS.html).

### Changing `ngen`/`t-route` sources

The `TROUTE_REPO`, `TROUTE_BRANCH`, `NGEN_REPO`, and `NGEN_BRANCH` environment variables can be changed in the `base` build stage of the Dockerfile to a custom `t-route` or `ngen` GitHub repository.

### Adding C/C++/Fortran BMI modules

The repo of the BMI module will first have to be added to the `ngen` repository's `extern` directory as a submodule. Next, the Dockerfile will have to be edited to include the module's build steps. The build stage for this usually can come from `ngen_clone`. An example of one such build is below:

```Dockerfile
# Install SAC-SMA
FROM ngen_clone AS build_sacsma
WORKDIR /ngen/ngen/extern/sac-sma
RUN cmake -B cmake_build -DISO_C_FORTRAN_BMI_PATH=/ngen/ngen/extern/iso_c_fortran_bmi -S .
RUN cmake --build cmake_build -j $(nproc)
```

### Adding Python BMI modules

Python BMI modules should be released on PyPI so that they can be `uv pip install`ed in the final build stage. An example of this command is found below:

```Dockerfile
# Install dhbv
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install "dmg==1.4.0" "hydrodl2==1.3.5" "dhbv2==0.5.3" --extra-index-url https://download.pytorch.org/whl/cpu
```

## Deploying new releases

All new releases should be deployed via the CI/CD scripts.

## Software stack

![software stack](./img/stack.svg)
