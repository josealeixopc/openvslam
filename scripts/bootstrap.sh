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

### GLOBAL VARIABLES BEGIN ###

# Import env variables
SCRIPT_DIR=$(dirname "$(readlink -fm "$0")")
. "${SCRIPT_DIR}/env.sh"

# Python version (must be >= 3.5)
PYTHON_VERSION=3.7  

# true if we are running in a container, false otherwise
DOCKER_BOOTSTRAP=false    

# dependencies versions
EIGEN3_VERSION=3.3.7
G2O_COMMIT=9b41a4ea5ade8e1250b9c1b279f3a9c098811b5a
OPENCV_VERSION=4.1.0
DBOW2_COMMIT=687fcb74dd13717c46add667e3fbfa9828a7019f
SIOCLIENT_COMMIT=ff6ef08e45c594e33aa6bc19ebdd07954914efe0

### GLOBAL VARIABLES END ###

# ":" is the Bash equivalent of the "pass" Python function.
# Because we executed 'set -x', this is a way of printing to console.
: "Updating repositories..." && \
sudo apt-get update -y -qq
# -y means say 'yes' to everything; '-qq' is quiet mode

if [ "${DOCKER_BOOSTRAP}" = true ]; then
    apt-get upgrade -y -qq
fi


# It is best to use double-quotes everytime you use a variable than to remember when double-quotes are actually necessary
sudo apt-get install -y python"${PYTHON_VERSION}" python3-pip
python"${PYTHON_VERSION}" -m pip install pip


if [ "${DOCKER_BOOSTRAP}" = true ]; then
    # Set 'python' command to run the installed version
    # We use dot '.' instead of 'source', because this script is for 'sh' not 'bash'
    echo "alias python=python${PYTHON_VERSION}" >> ${HOME}/.bashrc && . ${HOME}/.bashrc
fi

# The following dependencies come from OpenVSlam Dockerfile:
# https://github.com/xdspacelab/openvslam/blob/master/Dockerfile.socket

## OPENVSLAM DEPENDENCIES BEGIN ###
# I prefer using echo instead of the ":", because it works even when 'set -x' is not executed 
echo "Installing OpenVSlam dependencies' dependencies (C++ is fun, lol)..."

echo "Installing G2O dependencies..."
sudo apt-get install -y -qq \
    libgoogle-glog-dev \
    libatlas-base-dev \
    libsuitesparse-dev \
    libglew-dev

echo "Installing OpenCV depenendencies..."
sudo apt-get install -y -qq \
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

echo "Installing other dependencies..."
sudo apt-get install -y -qq \
    libyaml-cpp-dev

if [ "${DOCKER_BOOSTRAP}" = true ]; then
    echo "Removing cache (Docker only)..."
    sudo apt-get autoremove -y -qq
    rm -rf /var/lib/apt/lists/*
fi

echo "Installing Eigen3..."

cd /tmp
wget -q https://gitlab.com/libeigen/eigen/-/archive/"${EIGEN3_VERSION}"/eigen-"${EIGEN3_VERSION}".tar.bz2 && \
tar xf eigen-"${EIGEN3_VERSION}".tar.bz2
rm -rf eigen-"${EIGEN3_VERSION}".tar.bz2
cd eigen-"${EIGEN3_VERSION}"
mkdir -p build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${CMAKE_INSTALL_PREFIX}" \
    ..
make
sudo make install

echo "Installing G2O..."

cd /tmp
git clone https://github.com/RainerKuemmerle/g2o.git 
cd g2o
git checkout "${G2O_COMMIT}"
mkdir -p build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${CMAKE_INSTALL_PREFIX}" \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_UNITTESTS=OFF \
    -DBUILD_WITH_MARCH_NATIVE=OFF \
    -DG2O_USE_CHOLMOD=OFF \
    -DG2O_USE_CSPARSE=ON \
    -DG2O_USE_OPENGL=OFF \
    -DG2O_USE_OPENMP=ON \
    -DG2O_BUILD_APPS=OFF \
    -DG2O_BUILD_EXAMPLES=OFF \
    -DG2O_BUILD_LINKED_APPS=OFF \
    ..
make 
sudo make install

echo "Installing OpenCV"

cd /tmp
wget -q https://github.com/opencv/opencv/archive/"${OPENCV_VERSION}".zip
unzip -q "${OPENCV_VERSION}".zip
rm -rf "${OPENCV_VERSION}".zip
cd opencv-"${OPENCV_VERSION}"
mkdir -p build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${CMAKE_INSTALL_PREFIX}" \
    -DBUILD_DOCS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_JASPER=OFF \
    -DBUILD_OPENEXR=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_opencv_apps=OFF \
    -DBUILD_opencv_dnn=OFF \
    -DBUILD_opencv_ml=OFF \
    -DBUILD_opencv_python_bindings_generator=OFF \
    -DENABLE_CXX11=ON \
    -DENABLE_FAST_MATH=ON \
    -DWITH_EIGEN=ON \
    -DWITH_FFMPEG=ON \
    -DWITH_OPENMP=ON \
    ..
make
sudo make install

echo "Installing DBoW2..."

cd /tmp
git clone https://github.com/shinsumicco/DBoW2.git
cd DBoW2
git checkout "${DBOW2_COMMIT}"
mkdir -p build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${CMAKE_INSTALL_PREFIX}" \
    .. 
make
sudo make install

echo "Installing socket.io-client-cpp..."

cd /tmp

git clone https://github.com/shinsumicco/socket.io-client-cpp.git
cd socket.io-client-cpp
git checkout "${SIOCLIENT_COMMIT}"
git submodule init
git submodule update
mkdir -p build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${CMAKE_INSTALL_PREFIX}" \
    -DBUILD_UNIT_TESTS=OFF \
    ..
make
sudo make install

echo "Installing Protobuf..."

cd /tmp

wget -q https://github.com/google/protobuf/archive/v3.6.1.tar.gz
tar xf v3.6.1.tar.gz
cd protobuf-3.6.1
./autogen.sh
./configure \
    --prefix=/usr/local \
    --enable-static=no
make
sudo make install

if [ "${DOCKER_BOOSTRAP}" = true ]; then
    echo "Removing temporary files and cache (Docker only)..."
    cd /tmp
    rm -rf *
    sudo apt-get purge -y -qq autogen autoconf libtool
    sudo apt-get autoremove -y -qq
    rm -rf /var/lib/apt/lists/*
fi

## OPENVSLAM DEPENDENCIES END ###