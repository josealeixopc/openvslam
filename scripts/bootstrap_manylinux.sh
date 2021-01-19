#!/bin/sh

# Install wget
yum install wget -y

# Install yaml-cpp
yum install yaml-cpp-devel -y

# Install glog
yum install glog-devel -y

# Install python libraries
yum install python-devel -y

# Install SuiteSparse
yum install suitesparse-devel -y

CMAKE_INSTALL_PREFIX=/usr/local

# dependencies versions
EIGEN3_VERSION=3.3.7
G2O_COMMIT=9b41a4ea5ade8e1250b9c1b279f3a9c098811b5a
OPENCV_VERSION=4.1.0
DBOW2_COMMIT=687fcb74dd13717c46add667e3fbfa9828a7019f
SIOCLIENT_COMMIT=ff6ef08e45c594e33aa6bc19ebdd07954914efe0

### Install eigen as you would on a ubuntu machine (see bootstrap.sh)



# Install opencv as you would on bootstrap.sh

# Install G2O and DBoW2 and protobuf as you would on bootstrap.sh