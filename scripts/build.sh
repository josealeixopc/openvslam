#!/bin/sh

set -x

# Import env variables
SCRIPT_DIR=$(dirname "$(readlink -fm "$0")")
. "${SCRIPT_DIR}/env.sh"

echo $CMAKE_INSTALL_PREFIX

# If true, we are using Pangolin to view. Otherwise we are using SockerViewer.
PANGOLIN_VIEWER=OFF
SOCKET_VIEWER=OFF

# if [ "${PANGOLIN_VIEWER}" = ON ] ; then
#     SOCKET_VIEWER=OFF
# else
#     SOCKET_VIEWER=SOCKET_VIEWER
# fi

ROOT_DIR="$(dirname "$(dirname "$(readlink -fm "$0")")")"

cd "${ROOT_DIR}"
mkdir -p build
cd build
cmake \
    -DBUILD_WITH_MARCH_NATIVE=OFF \
    -DUSE_PANGOLIN_VIEWER="$PANGOLIN_VIEWER" \
    -DUSE_SOCKET_PUBLISHER="$SOCKET_VIEWER" \
    -DUSE_STACK_TRACE_LOGGER=ON \
    -DBOW_FRAMEWORK=DBoW2 \
    -DBUILD_TESTS=OFF \
    -DCMAKE_BUILD_TYPE=Debug \
    ..

# nproc returns the number of available processing units
# the '-jX' flag tells make it can launch up to X concurrent processes during build
make -j"$(nproc)"