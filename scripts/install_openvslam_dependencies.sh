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
    if [ "${DOCKER_CONTAINER}" = false ]; then
        sudo $@
    else
        $@
    fi
}

### GLOBAL VARIABLES BEGIN ###

# Import env variables
SCRIPT_DIR=$(dirname "$(readlink -fm "$0")")
. "${SCRIPT_DIR}/env.sh"

# dependencies versions
EIGEN3_VERSION=3.3.7
G2O_COMMIT=9b41a4ea5ade8e1250b9c1b279f3a9c098811b5a
OPENCV_VERSION=4.1.0
DBOW2_COMMIT=687fcb74dd13717c46add667e3fbfa9828a7019f
SIOCLIENT_COMMIT=ff6ef08e45c594e33aa6bc19ebdd07954914efe0

# If DOCKER_CONTAINER is not defined, then set it to false.
# It should be true if we are running in a container, false otherwise
if [ -z "${DOCKER_CONTAINER}" ]; then
  DOCKER_CONTAINER=false
fi

### GLOBAL VARIABLES END ###

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
run_sudo make install

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
run_sudo make install

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
run_sudo make install

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
run_sudo make install

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
run_sudo make install

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
run_sudo make install