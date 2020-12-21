#include <pybind11/pybind11.h>
#include "my_rgbd_slam.h"

PYBIND11_MODULE(openvslam_python, m)
{
    m.doc() = "pybind11 openvslam_python plugin"; // optional module docstring

    m.def("add", &add, "A function which adds two numbers");

    m.def("non_stop_rgbd_tracking", &non_stop_rgbd_tracking, "Function for tracking.",
        pybind11::arg("config_file_path"),
        pybind11::arg("vocab_file_path"),
        pybind11::arg("sequence_dir_path"),
        pybind11::arg("frame_skip"),
        pybind11::arg("no_sleep"),
        pybind11::arg("auto_term"),
        pybind11::arg("eval_log"),
        pybind11::arg("map_db_path")
    );
}