#include <pybind11/pybind11.h>
#include "my_rgbd_slam.h"

PYBIND11_MODULE(openvslam_python, m)
{
    m.doc() = "pybind11 openvslam_python plugin"; // optional module docstring

    m.def("add", &add, "A function which adds two numbers");
    m.def("non_stop_rgbd_tracking", &non_stop_rgbd_tracking, "Function for tracking.");
}