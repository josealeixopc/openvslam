#!/bin/sh

### 
# This script installs all the dependencies for OpenVSlam and enables you to build the binaries for this repository.
###

## See sh options here: https://pubs.opengroup.org/onlinepubs/009695399/utilities/set.html
# 'set -x' makes the console print all executed commands. 
# 'set +x' disables this mode.
set -x 

# 'set -e' aborts the script at first error, when a command exits with non-zero status 
# (except in until or while loops, if-tests, list constructs)
set -e

# This function checks if we're inside a docker container. If we are, then we do not run commands with "sudo".
run_sudo() {
    if [ -z "${DOCKER_CONTAINER}" ] || [ "${DOCKER_CONTAINER}" = false ]; then
        sudo $@
    else
        $@
    fi
}

### GLOBAL VARIABLES BEGIN ###

# Import env variables
SCRIPT_DIR=$(dirname "$(readlink -fm "$0")")
. "${SCRIPT_DIR}/env.sh"

# If DOCKER_CONTAINER is not defined, then set it to false.
# It should be true if we are running in a container, false otherwise
if [ -z "${DOCKER_CONTAINER}" ]; then
  DOCKER_CONTAINER=false
fi

YAML_CPP_VERSION=0.6.3

### GLOBAL VARIABLES END ###

run_sudo yum install -y python3-devel

# These are necessary for the manylinux_2014 image
run_sudo yum install -y \
    wget \
    glog-devel \
    suitesparse-devel \
    gflags-devel #\ # for glog
    # lapack-devel \  # These two are needed to make suitesparse
    # blas-devel \
    # gmp-devel \ # for building suiteparse from source
    # mpfr-devel \ 

# For some reason, yaml-cpp is not recognized by CMake when it is installed through yum
# Instead of changing the CMake, we just build it from source
cd /tmp
wget -q https://github.com/jbeder/yaml-cpp/archive/yaml-cpp-"${YAML_CPP_VERSION}".tar.gz && \
tar xf yaml-cpp-"${YAML_CPP_VERSION}".tar.gz
rm -rf yaml-cpp-"${YAML_CPP_VERSION}".tar.gz
cd yaml-cpp-yaml-cpp-"${YAML_CPP_VERSION}"
mkdir -p build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${CMAKE_INSTALL_PREFIX}" \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    ..
make
run_sudo make install

# Copy suitesparse headers (otherwise they will not be located, don't know why)
cp /usr/include/suitesparse/* /usr/include/
