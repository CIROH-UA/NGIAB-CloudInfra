FROM rockylinux:9.1 AS base
ENV TROUTE_REPO=CIROH-UA/t-route
ENV TROUTE_BRANCH=ngiab
ENV NGEN_REPO=CIROH-UA/ngen
ENV NGEN_BRANCH=ngiab

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
    netcdf-fortran-devel netcdf-cxx-devel lld



FROM build_base AS boost_build
RUN wget https://archives.boost.io/release/1.79.0/source/boost_1_79_0.tar.gz
RUN tar -xzf boost_1_79_0.tar.gz
WORKDIR /boost_1_79_0
RUN ./bootstrap.sh && ./b2 headers
ENV BOOST_ROOT=/boost_1_79_0



FROM boost_build AS troute_prebuild
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
RUN uv pip install -r https://raw.githubusercontent.com/$TROUTE_REPO/refs/heads/$TROUTE_BRANCH/requirements.txt
# this installs numpy 1.26.4 but the produced wheels install a non pinned version



FROM troute_prebuild AS troute_build
WORKDIR /ngen/t-route
RUN git clone --depth 1 --single-branch --branch $TROUTE_BRANCH https://github.com/$TROUTE_REPO.git .
# build and save a link to the repo used
RUN echo $(git remote get-url origin | sed 's/\.git$//' | awk '{print $0 "/tree/" }' | tr -d '\n' && git rev-parse HEAD) >> /tmp/troute_url
RUN git submodule update --init --depth 1
RUN uv pip install build wheel

# disable everything except the kernel builds
RUN sed -i 's/build_[a-z]*=/#&/' compiler.sh

RUN ./compiler.sh no-e

# install / build using UV because it's so much faster
# no build isolation needed because of cython namespace issues
RUN uv pip install --config-setting='--build-option=--use-cython' src/troute-network/
RUN uv build --wheel --config-setting='--build-option=--use-cython' src/troute-network/
RUN uv pip install --no-build-isolation --config-setting='--build-option=--use-cython' src/troute-routing/
RUN uv build --wheel --no-build-isolation --config-setting='--build-option=--use-cython' src/troute-routing/
RUN uv build --wheel --no-build-isolation src/troute-config/
RUN uv build --wheel --no-build-isolation src/troute-nwm/

FROM troute_prebuild AS ngen_clone
WORKDIR /ngen
## make sure clone isn't cached if repo is updated
ADD https://api.github.com/repos/${NGEN_REPO}/git/refs/heads/${NGEN_BRANCH} /tmp/version.json
RUN git clone --single-branch --branch $NGEN_BRANCH https://github.com/$NGEN_REPO.git && \
    cd ngen && \
    git submodule update --init --recursive --depth 1



FROM ngen_clone AS ngen_build
ENV PATH=${PATH}:/usr/lib64/mpich/bin

WORKDIR /ngen/ngen
RUN echo $(git remote get-url origin | sed 's/\.git$//' | awk '{print $0 "/tree/" }' | tr -d '\n' && git rev-parse HEAD) >> /tmp/ngen_url

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


# Build Ngen serial
RUN cmake -G Ninja -B cmake_build_serial -S . ${COMMON_BUILD_ARGS} -DNGEN_WITH_MPI:BOOL=OFF && \
    cmake --build cmake_build_serial --target all -- -j $(nproc)

ARG MPI_BUILD_ARGS="-DNGEN_WITH_MPI:BOOL=ON \
    -DNetCDF_ROOT=/usr/lib64/mpich \
    -DCMAKE_PREFIX_PATH=/usr/lib64/mpich \
    -DCMAKE_LIBRARY_PATH=/usr/lib64/mpich/lib"
# the two in the command below can't be here because the $() isn't evaulated properly


# Install the mpi enabled netcdf library and build Ngen parallel with it
RUN dnf install -y netcdf-cxx4-mpich-devel
RUN cmake -G Ninja -B cmake_build_parallel -S . ${COMMON_BUILD_ARGS} ${MPI_BUILD_ARGS} \
    -DNetCDF_CXX_INCLUDE_DIR=/usr/include/mpich-$(arch) \
    -DNetCDF_INCLUDE_DIR=/usr/include/mpich-$(arch) && \
    cmake --build cmake_build_parallel --target all -- -j $(nproc)



FROM ngen_build AS restructure_files
# Setup final directories and permissions
RUN mkdir -p /dmod/datasets /dmod/datasets/static /dmod/shared_libs /dmod/bin /dmod/utils/ && \
    shopt -s globstar && \
    cp -a ./extern/**/cmake_build/*.so* /dmod/shared_libs/. || true && \
    cp -a ./extern/noah-owp-modular/**/*.TBL /dmod/datasets/static && \
    cp -a ./cmake_build_parallel/ngen /dmod/bin/ngen-parallel || true && \
    cp -a ./cmake_build_serial/ngen /dmod/bin/ngen-serial || true && \
    cp -a ./cmake_build_parallel/partitionGenerator /dmod/bin/partitionGenerator || true && \
    cp -ar ./utilities/* /dmod/utils/ && \
    cd /dmod/bin && \
    (stat ngen-parallel && ln -s ngen-parallel ngen) || (stat ngen-serial && ln -s ngen-serial ngen)



FROM restructure_files AS dev

COPY  HelloNGEN.sh /ngen/HelloNGEN.sh
# Set up library path
RUN echo "/dmod/shared_libs/" >> /etc/ld.so.conf.d/ngen.conf && ldconfig -v
# Add mpirun to path
ENV PATH=$PATH:/usr/lib64/mpich/bin
# Set permissions
RUN chmod a+x /dmod/bin/* /ngen/HelloNGEN.sh
RUN mv /ngen/ngen /ngen/ngen_src
WORKDIR /ngen
ENTRYPOINT ["./HelloNGEN.sh"]

FROM build_base AS lstm_weights
RUN git clone --depth=1 --branch example_weights https://github.com/ciroh-ua/lstm.git /lstm_weights
# add the rust weight conversion
RUN uv run --with pyyaml --with numpy --with torch --extra-index-url https://download.pytorch.org/whl/cpu \
    https://raw.githubusercontent.com/CIROH-UA/rust-lstm-1025/refs/tags/v0.1.0/scripts/convert.py \
    all /lstm_weights/trained_neuralhydrology_models/
# replace the relative path with the absolute path in the model config files
RUN shopt -s globstar
RUN sed -i 's|\.\.|/ngen/ngen/extern/lstm|g' /lstm_weights/trained_neuralhydrology_models/**/config.yml


FROM build_base AS burn_lstm
RUN dnf install -y clang
WORKDIR /build
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
RUN echo 'source $HOME/.cargo/env' >> $HOME/.bashrc
RUN git clone --depth=1 https://github.com/aaraney/bmi-rs
RUN git clone --depth=1 --branch v0.1.0 https://github.com/ciroh-ua/rust-lstm-1025
WORKDIR /build/rust-lstm-1025
RUN cargo build --release

FROM base AS final

WORKDIR /ngen

# Copy necessary files from build stages
COPY  HelloNGEN.sh /ngen/HelloNGEN.sh
COPY --from=restructure_files /dmod /dmod
COPY --from=troute_build /ngen/t-route/src/troute-*/dist/*.whl /tmp/

RUN ln -s /dmod/bin/ngen /usr/local/bin/ngen

RUN uv venv && \
    uv pip install --no-cache-dir /tmp/*.whl netCDF4==1.6.3
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
RUN uv pip install numpy==$(/dmod/bin/ngen --info | grep -e 'NumPy Version: ' | cut -d ':' -f 2 | uniq | xargs)

# now that the only version of numpy is the one that NGen expects,
# we can add the venv to the path so ngen can find it
ENV PATH="/ngen/.venv/bin:${PATH}"

# Install lstm - the extra index url installs cpu-only pytorch which is ~6gb smaller
COPY --from=ngen_clone /ngen/ngen/extern/lstm/lstm /ngen/ngen/extern/lstm
RUN uv pip install --no-cache-dir /ngen/ngen/extern/lstm --extra-index-url https://download.pytorch.org/whl/cpu

# Replace the noaa-owp example weights with jmframes
RUN rm -rf /ngen/ngen/extern/lstm/trained_neuralhydrology_models
COPY --from=lstm_weights /lstm_weights/trained_neuralhydrology_models /ngen/ngen/extern/lstm/trained_neuralhydrology_models

# Copy the rust version of the lstm over.
COPY --from=burn_lstm /build/rust-lstm-1025/target/release/librust_lstm_1025.so /dmod/shared_libs/librust_lstm_1025.so

## add some metadata to the image
COPY --from=troute_build /tmp/troute_url /ngen/troute_url
COPY --from=ngen_build /tmp/ngen_url /ngen/ngen_url

RUN echo "export PS1='\u\[\033[01;32m\]@ngiab_dev\[\033[00m\]:\[\033[01;35m\]\W\[\033[00m\]\$ '" >> ~/.bashrc

ENTRYPOINT ["./HelloNGEN.sh"]
