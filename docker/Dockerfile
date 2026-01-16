ARG TROUTE_REPO=CIROH-UA/t-route
ARG TROUTE_BRANCH=ngiab
ARG NGEN_REPO=CIROH-UA/ngen
ARG NGEN_BRANCH=ngiab
FROM rockylinux:9.1 AS base

# Install final dependencies to make sure ngen is build and deployed with matching versions
# Needed here for build caching
RUN echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
RUN dnf update -y && \
    dnf install -y epel-release && \
    dnf config-manager --set-enabled crb && \
    dnf install -y \
    vim libgfortran sqlite \
    bzip2 expat udunits2 zlib \
    mpich hdf5 netcdf netcdf-fortran netcdf-cxx netcdf-cxx4-mpich
# Install UV and setup cargo bin for rust tools (uv and cargo)
ENV PATH="/root/.cargo/bin:${PATH}"
ENV UV_INSTALL_DIR=/root/.cargo/bin
ENV UV_COMPILE_BYTECODE=1
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN uv self update

FROM base AS build_base
# no dnf update to keep devel packages consistent with versions installed in base
RUN echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
RUN dnf install -y epel-release && \
    dnf config-manager --set-enabled crb && \
    dnf install -y \
    sudo gcc gcc-c++ make cmake ninja-build tar git gcc-gfortran libgfortran sqlite sqlite-devel \
    python3 python3-devel python3-pip \
    expat-devel flex bison udunits2-devel zlib-devel \
    wget mpich-devel hdf5-devel netcdf-devel \
    netcdf-fortran-devel netcdf-cxx-devel lld clang \
    netcdf-cxx4-mpich-devel



FROM build_base AS boost_build
ARG BOOST_VERSION=1.86.0
ARG BOOST_FOLDER=boost_${BOOST_VERSION//./_}
ENV BOOST_ROOT=/${BOOST_FOLDER}

ADD --unpack https://archives.boost.io/release/${BOOST_VERSION}/source/${BOOST_FOLDER}.tar.gz /
WORKDIR /${BOOST_FOLDER}
RUN ./bootstrap.sh && ./b2 headers



FROM boost_build AS troute_prebuild
ARG TROUTE_REPO
ARG TROUTE_BRANCH
WORKDIR /ngen
# troute looks for netcdf.mod in the wrong place unless we set this
ENV FC=gfortran NETCDF=/usr/lib64/gfortran/modules/
# it also tries to use python instead of python3
RUN ln -s /usr/bin/python3 /usr/bin/python

WORKDIR /ngen/
RUN uv venv
ENV PATH="/ngen/.venv/bin:$PATH"
## make sure clone isn't cached if repo is updated
ADD https://api.github.com/repos/${TROUTE_REPO}/git/refs/heads/${TROUTE_BRANCH} /tmp/version.json
# install requirements like this so the troute clone can run in parallel with ngen download and build
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install -r https://raw.githubusercontent.com/${TROUTE_REPO}/refs/heads/${TROUTE_BRANCH}/requirements.txt
# this installs numpy 1.26.4 but the produced wheels install a non pinned version



FROM troute_prebuild AS troute_build
WORKDIR /ngen/t-route
ADD https://github.com/${TROUTE_REPO}.git#${TROUTE_BRANCH} /ngen/t-route
# build and save a link to the repo used
RUN echo $(git remote get-url origin | sed 's/\.git$//' | awk '{print $0 "/tree/" }' | tr -d '\n' && git rev-parse HEAD) >> /tmp/troute_url

# disable everything except the kernel builds
RUN sed -i 's/build_[a-z]*=/#&/' compiler.sh
RUN ./compiler.sh no-e

# install / build using UV because it's so much faster
# no build isolation needed because of cython namespace issues
RUN --mount=type=cache,target=/root/.cache/uv <<EOF
    uv pip install build wheel
    uv pip install --config-setting='--build-option=--use-cython' src/troute-network/
    uv build --wheel --config-setting='--build-option=--use-cython' src/troute-network/
    uv pip install --no-build-isolation --config-setting='--build-option=--use-cython' src/troute-routing/
    uv build --wheel --no-build-isolation --config-setting='--build-option=--use-cython' src/troute-routing/
    uv build --wheel --no-build-isolation src/troute-config/
    uv build --wheel --no-build-isolation src/troute-nwm/
EOF

FROM troute_prebuild AS ngen_build
WORKDIR /ngen
ARG NGEN_REPO
ARG NGEN_BRANCH
ENV PATH=${PATH}:/usr/lib64/mpich/bin

ADD https://github.com/${NGEN_REPO}.git#${NGEN_BRANCH} /ngen/ngen

WORKDIR /ngen/ngen
RUN echo $(git remote get-url origin | sed 's/\.git$//' | awk '{print $0 "/tree/" }' | tr -d '\n' && git rev-parse HEAD) >> /tmp/ngen_url

# Define common build arguments
ARG COMMON_BUILD_ARGS="-DNGEN_WITH_NETCDF:BOOL=ON \
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
ARG SERIAL_BUILD_ARGS="${COMMON_BUILD_ARGS} \
    -DNGEN_WITH_EXTERN_ALL=ON \
    -DNGEN_WITH_MPI:BOOL=OFF"

# build args using $(arch) are in RUN below so they're evaulated properly
ARG PARALLEL_BUILD_ARGS="${COMMON_BUILD_ARGS} \
    -DNGEN_WITH_MPI:BOOL=ON \
    -DNetCDF_ROOT=/usr/lib64/mpich \
    -DCMAKE_PREFIX_PATH=/usr/lib64/mpich \
    -DCMAKE_LIBRARY_PATH=/usr/lib64/mpich/lib \
    -DNGEN_WITH_EXTERN_ALL=OFF"

# Build Ngen serial
RUN --mount=type=cache,id=${SERIAL_BUILD_ARGS},target=/ngen/ngen/cmake_build_serial \
    <<EOF
    cmake -G Ninja -B cmake_build_serial -S . ${SERIAL_BUILD_ARGS}
    cmake --build cmake_build_serial --target all -- -j $(nproc)
    cp cmake_build_serial/ngen /tmp/ngen-serial
EOF

# Build Ngen parallel
RUN --mount=type=cache,id=${PARALLEL_BUILD_ARGS},target=/ngen/ngen/cmake_build_parallel \
    <<EOF
    cmake -G Ninja -B cmake_build_parallel -S . ${PARALLEL_BUILD_ARGS} \
    -DNetCDF_CXX_INCLUDE_DIR=/usr/include/mpich-$(arch) \
    -DNetCDF_INCLUDE_DIR=/usr/include/mpich-$(arch)
    cmake --build cmake_build_parallel --target all -- -j $(nproc)
    cp cmake_build_parallel/ngen /tmp/ngen-parallel
    cp cmake_build_parallel/partitionGenerator /tmp/partitionGenerator
EOF

# Setup final directories and permissions
RUN --mount=type=cache,id=${PARALLEL_BUILD_ARGS},target=/ngen/ngen/cmake_build_parallel \
    --mount=type=cache,id=${SERIAL_BUILD_ARGS},target=/ngen/ngen/cmake_build_serial \
    <<EOF
    mkdir -p /dmod/datasets /dmod/datasets/static /dmod/shared_libs /dmod/bin /dmod/utils/
    shopt -s globstar
    cp -a ./extern/**/cmake_build/*.so* /dmod/shared_libs/.
    cp -a ./extern/noah-owp-modular/**/*.TBL /dmod/datasets/static
    cp -a ./cmake_build_parallel/ngen /dmod/bin/ngen-parallel
    cp -a ./cmake_build_serial/ngen /dmod/bin/ngen-serial
    cp -a ./cmake_build_parallel/partitionGenerator /dmod/bin/partitionGenerator
    cp -ar ./utilities/* /dmod/utils/
    ln -s /dmod/bin/ngen-parallel /dmod/bin/ngen
EOF

FROM build_base AS lstm_weights
ADD https://github.com/ciroh-ua/lstm.git#example_weights /lstm_weights
# add the rust weight conversion
RUN --mount=type=cache,target=/root/.cache/uv \
    uv run --with pyyaml --with numpy --with torch --extra-index-url https://download.pytorch.org/whl/cpu \
    https://raw.githubusercontent.com/CIROH-UA/rust-lstm-1025/refs/tags/v0.1.0/scripts/convert.py \
    all /lstm_weights/trained_neuralhydrology_models/
# replace the relative path with the absolute path in the model config files
RUN shopt -s globstar
RUN sed -i 's|\.\.|/ngen/ngen/extern/lstm|g' /lstm_weights/trained_neuralhydrology_models/**/config.yml


FROM build_base AS burn_lstm
WORKDIR /build
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
RUN echo 'source $HOME/.cargo/env' >> $HOME/.bashrc
ADD https://github.com/ciroh-ua/rust-lstm-1025.git#v0.1.2 /build/rust-lstm-1025
WORKDIR /build/rust-lstm-1025
RUN cargo build --release

FROM base AS final

WORKDIR /ngen

# Copy necessary files from build stages
COPY  HelloNGEN.sh /ngen/HelloNGEN.sh
COPY --from=ngen_build /dmod /dmod
COPY --from=troute_build /ngen/t-route/src/troute-*/dist/*.whl /tmp/

RUN ln -s /dmod/bin/ngen /usr/local/bin/ngen
RUN --mount=type=cache,target=/root/.cache/uv \
    uv venv && uv pip install /tmp/*.whl netCDF4==1.6.3
# Clean up some stuff, this doesn't make the image any smaller
RUN rm -rf /tmp/*.whl
# DONT ADD THE VENV TO THE PATH YET

# Set up library path
RUN echo "/dmod/shared_libs/" >> /etc/ld.so.conf.d/ngen.conf && ldconfig -v

# Add mpirun to path
ENV PATH=$PATH:/usr/lib64/mpich/bin
RUN chmod a+x /dmod/bin/* /ngen/HelloNGEN.sh

# Only here after everything else is done will the ngen binary work and provide --info
#                                                             This mess is parsing the version number
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install numpy==$(/dmod/bin/ngen --info | grep -e 'NumPy Version: ' | cut -d ':' -f 2 | uniq | xargs)

# now that the only version of numpy is the one that NGen expects,
# we can add the venv to the path so ngen can find it
ENV PATH="/ngen/.venv/bin:${PATH}"

# Install lstm - the extra index url installs cpu-only pytorch which is ~6gb smaller
COPY --from=ngen_build /ngen/ngen/extern/lstm/lstm /ngen/ngen/extern/lstm
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install /ngen/ngen/extern/lstm --extra-index-url https://download.pytorch.org/whl/cpu

# Replace the noaa-owp example weights with jmframes
RUN rm -rf /ngen/ngen/extern/lstm/trained_neuralhydrology_models
COPY --from=lstm_weights /lstm_weights/trained_neuralhydrology_models /ngen/ngen/extern/lstm/trained_neuralhydrology_models

# Copy the rust version of the lstm over.
COPY --from=burn_lstm /build/rust-lstm-1025/target/release/librust_lstm_1025.so /dmod/shared_libs/librust_lstm_1025.so

## add some metadata to the image
COPY --from=troute_build /tmp/troute_url /ngen/troute_url
COPY --from=ngen_build /tmp/ngen_url /ngen/ngen_url

RUN echo "export PS1='\u\[\033[01;32m\]@ngiab_dev\[\033[00m\]:\[\033[01;35m\]\W\[\033[00m\]\$ '" >> ~/.bashrc

ENTRYPOINT ["/ngen/HelloNGEN.sh"]
