# Developing

```bash
docker run -it -v "$(pwd)":/openvslam openvslam-dev:latest
```

Arguments for the RGBD SLAM are [here](https://openvslam.readthedocs.io/en/master/simple_tutorial.html#tracking-and-mapping).

## Keyframe trajectory vs frame trajectory

From [Wikipedia], a "keyframe" defines the starting and ending points of any smooth transition. 

According to the [OpenVSLAM article](https://arxiv.org/pdf/1910.01122.pdf) (Section 3.1), a module decides whether a regular frame is a keyframe or not. If it is, it gets sent to the mapping module, which incorporates the keyframe's points in its map.