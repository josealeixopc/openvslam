# directory for installing CMake programs
# default for Linux is "/usr/local"
export CMAKE_INSTALL_PREFIX=/usr/local

# Make sure we don' get prompts
export DEBIAN_FRONTEND=noninteractive

# Export some CMake env variables
export CPATH="${CMAKE_INSTALL_PREFIX}"/include:"${CPATH}"
export C_INCLUDE_PATH="${CMAKE_INSTALL_PREFIX}"/include:"${C_INCLUDE_PATH}"
export CPLUS_INCLUDE_PATH="${CMAKE_INSTALL_PREFIX}"/include:"${CPLUS_INCLUDE_PATH}"
export LIBRARY_PATH="${CMAKE_INSTALL_PREFIX}"/lib:"${LIBRARY_PATH}"
export LD_LIBRARY_PATH="${CMAKE_INSTALL_PREFIX}"/lib:"${LD_LIBRARY_PATH}"

# CMake's "find_package" function searches a variable <PackageName>_DIR for the path to the package
# See more here: https://cmake.org/cmake/help/latest/command/find_package.html#search-procedure
export Eigen3_DIR="${CMAKE_INSTALL_PREFIX}"/share/eigen3/cmake
export g2o_DIR="${CMAKE_INSTALL_PREFIX}"/lib/cmake/g2o
export OpenCV_DIR="${CMAKE_INSTALL_PREFIX}"/lib/cmake/opencv4
export DBoW2_DIR="${CMAKE_INSTALL_PREFIX}"/lib/cmake/DBoW2
export sioclient_DIR="${CMAKE_INSTALL_PREFIX}"/lib/cmake/sioclient