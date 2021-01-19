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

# Python version (must be >= 3.5)
PYTHON_VERSION=3.6

# If DOCKER_CONTAINER is not defined, then set it to false.
# It should be true if we are running in a container, false otherwise
if [ -z "${DOCKER_CONTAINER}" ]; then
  DOCKER_CONTAINER=false
fi

# Same for MANYLINUX_CONTAINER
if [ -z "${MANYLINUX_CONTAINER}" ]; then
  MANYLINUX_CONTAINER=false
fi

### GLOBAL VARIABLES END ###

### Updating packages and installing dependencies

if [ "${DOCKER_CONTAINER}" = true ]; then
    # ":" is the Bash equivalent of the "pass" Python function.
    # Because we executed 'set -x', this is a way of printing to console.
    : "Updating repositories..." && \
    apt-get update -y -qq && \
    apt-get upgrade -y -qq
else
    # If it's not a container, run with sudo
    sudo apt-get update -y -qq
    # -y means say 'yes' to everything; '-qq' is quiet mode
fi

echo "Installing Python..."
# It is best to use double-quotes everytime you use a variable than to remember when double-quotes are actually necessary
run_sudo apt-get install -y python"${PYTHON_VERSION}" python3-pip
python"${PYTHON_VERSION}" -m pip install pip

echo "Installing basic dependencies..."
run_sudo apt-get install -y -qq \
    build-essential \
    pkg-config \
    cmake \
    git \
    wget \
    curl \
    tar \
    unzip

if [ "${DOCKER_CONTAINER}" = true ]; then
    # Set 'python' command to run the installed version
    # We use dot '.' instead of 'source', because this script is for 'sh' not 'bash'
    echo "alias python=python${PYTHON_VERSION}" >> ${HOME}/.profile && . ${HOME}/.profile
fi


# The following dependencies come from OpenVSlam Dockerfile:
# https://github.com/xdspacelab/openvslam/blob/master/Dockerfile.socket

## OPENVSLAM DEPENDENCIES BEGIN ###
# I prefer using echo instead of the ":", because it works even when 'set -x' is not executed 
echo "Installing OpenVSlam dependencies' dependencies (C++ is fun, lol)..."

echo "Installing G2O dependencies..."
run_sudo apt-get install -y -qq \
    libgoogle-glog-dev \
    libatlas-base-dev \
    libsuitesparse-dev \
    libglew-dev

echo "Installing OpenCV depenendencies..."
run_sudo apt-get install -y -qq \
    libjpeg-dev \
    libpng++-dev \
    libtiff-dev \
    libopenexr-dev \
    libwebp-dev \
    ffmpeg \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswscale-dev \
    libavresample-dev

echo "Installing Protobuf dependencies..."
run_sudo apt-get install -y -qq \
    autogen \
    autoconf \
    libtool

echo "Installing other dependencies..."
run_sudo apt-get install -y -qq \
    libyaml-cpp-dev

if [ "${DOCKER_CONTAINER}" = true ]; then
    echo "Removing cache (Docker only)..."
    apt-get autoremove -y -qq
    rm -rf /var/lib/apt/lists/*
fi