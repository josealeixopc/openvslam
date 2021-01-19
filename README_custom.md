# Developing

```bash
docker run -it -v "$(pwd)":/openvslam openvslam-dev:latest
```

Arguments for the RGBD SLAM are [here](https://openvslam.readthedocs.io/en/master/simple_tutorial.html#tracking-and-mapping).

## Keyframe trajectory vs frame trajectory

From [Wikipedia], a "keyframe" defines the starting and ending points of any smooth transition. 

According to the [OpenVSLAM article](https://arxiv.org/pdf/1910.01122.pdf) (Section 3.1), a module decides whether a regular frame is a keyframe or not. If it is, it gets sent to the mapping module, which incorporates the keyframe's points in its map.

## Using Auditwheel

Start a ManyLinux CentOS7 image (which already has `auditwheel` installed): 

```bash
docker run -i -t -v `pwd`:/io quay.io/pypa/manylinux2014_x86_64 /bin/bash
``` 

Inside the docker container, change to the `io` folder and try to generate a wheel using the appropiate Python version:

```bash
/opt/python/cp36-cp36m/bin/python setup.py bdist_wheel
```

If it succeeds, you have a wheel that can be installed without fixing. If not, then you need to install the missing libraries.

### Installing missing libraries for OpenVSLAM

```bash

``` 