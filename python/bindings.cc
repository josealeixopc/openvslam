
#include "openvslam/config.h"
#include "openvslam/system.h"

// These headers need to be added to avoid 'invalid use of incomplete type' errors which derive from forward declaration issues
#include "openvslam/publish/frame_publisher.h"
#include "openvslam/publish/map_publisher.h"

#include "socket_publisher/publisher.h"

#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>
#include <pybind11/eigen.h>

// These need to be included to map cv::Mat to a Python type

#include "my_rgbd_slam.h"

namespace pybind11 {
namespace detail {
template<>
struct type_caster<cv::Mat> {
public:
    PYBIND11_TYPE_CASTER(cv::Mat, _("numpy.ndarray"));

    //! 1. cast numpy.ndarray to cv::Mat
    bool load(handle obj, bool) {
        array b = reinterpret_borrow<array>(obj);
        buffer_info info = b.request();

        //const int ndims = (int)info.ndim;
        int nh = 1;
        int nw = 1;
        int nc = 1;
        int ndims = info.ndim;
        if (ndims == 2) {
            nh = info.shape[0];
            nw = info.shape[1];
        }
        else if (ndims == 3) {
            nh = info.shape[0];
            nw = info.shape[1];
            nc = info.shape[2];
        }
        else {
            char msg[64];
            std::sprintf(msg, "Unsupported dim %d, only support 2d, or 3-d", ndims);
            throw std::logic_error(msg);
            return false;
        }

        int dtype;
        if (info.format == format_descriptor<unsigned char>::format()) {
            dtype = CV_8UC(nc);
        }
        else if (info.format == format_descriptor<unsigned short>::format()) {
            dtype = CV_16UC(nc);
        }  
        else if (info.format == format_descriptor<int>::format()) {
            dtype = CV_32SC(nc);
        }
        else if (info.format == format_descriptor<float>::format()) {
            dtype = CV_32FC(nc);
        }
        else {
            throw std::logic_error("Unsupported type, only support uchar, uint16, int32, float");
            return false;
        }

        value = cv::Mat(nh, nw, dtype, info.ptr);
        return true;
    }

    //! 2. cast cv::Mat to numpy.ndarray
    static handle cast(const cv::Mat& mat, return_value_policy, handle defval) {
        std::ignore = defval;

        std::string format = format_descriptor<unsigned char>::format();
        size_t elemsize = sizeof(unsigned char);
        int nw = mat.cols;
        int nh = mat.rows;
        int nc = mat.channels();
        int depth = mat.depth();
        int type = mat.type();
        int dim = (depth == type) ? 2 : 3;

        if (depth == CV_8U) {
            format = format_descriptor<unsigned char>::format();
            elemsize = sizeof(unsigned char);
        } 
        else if (depth == CV_16U) {
            format = format_descriptor<unsigned short>::format();
            elemsize = sizeof(unsigned short);
        }
        else if (depth == CV_32S) {
            format = format_descriptor<int>::format();
            elemsize = sizeof(int);
        }
        else if (depth == CV_32F) {
            format = format_descriptor<float>::format();
            elemsize = sizeof(float);
        }
        else {
            throw std::logic_error("Unsupport type, only support uchar, int32, float");
        }

        std::vector<size_t> bufferdim;
        std::vector<size_t> strides;
        if (dim == 2) {
            bufferdim = {(size_t)nh, (size_t)nw};
            strides = {elemsize * (size_t)nw, elemsize};
        }
        else if (dim == 3) {
            bufferdim = {(size_t)nh, (size_t)nw, (size_t)nc};
            strides = {(size_t)elemsize * nw * nc, (size_t)elemsize * nc, (size_t)elemsize};
        }
        return array(buffer_info(mat.data, elemsize, format, dim, bufferdim, strides)).release();
    }
};
} // namespace detail
} // namespace pybind11

namespace py = pybind11;

PYBIND11_MODULE(openvslam_python, m) {
    m.doc() = "pybind11 openvslam_python plugin"; // optional module docstring

    // Config class
    py::class_<openvslam::config, std::shared_ptr<openvslam::config>>(m, "config")
        .def(py::init<const std::string&>(),
             py::arg("config_file_path"));

    // py::class_<openvslam::data::landmark>(m, "landmark")
    // 	.def();

    // py::class_<openvslam::data::map_database>(m, "map_database")
    // .def();

    py::class_<openvslam::data::keyframe>(m, "keyframe")
        .def("to_json", &openvslam::data::keyframe::to_json_string)
        .def("get_cam_pose", &openvslam::data::keyframe::get_cam_pose);

    // System class
    py::class_<openvslam::system>(m, "system")
        .def(py::init<const std::shared_ptr<openvslam::config>&, const std::string&>(), py::arg("cfg"), py::arg("vocab_file_path"))
        .def("startup", &openvslam::system::startup, py::arg("need_initialize") = true)
        .def("shutdown", &openvslam::system::shutdown)
        .def("save_frame_trajectory", &openvslam::system::save_frame_trajectory, py::arg("path"), py::arg("format"))
        .def("save_keyframe_trajectory", &openvslam::system::save_keyframe_trajectory, py::arg("path"), py::arg("format"))
        .def("load_map_database", &openvslam::system::load_map_database, py::arg("path"))
        .def("save_map_database", &openvslam::system::save_map_database, py::arg("path"))
        .def("get_map_publisher", &openvslam::system::get_map_publisher)
        .def("get_frame_publisher", &openvslam::system::get_frame_publisher)
        .def("enable_mapping_module", &openvslam::system::enable_mapping_module)
        .def("disable_mapping_module", &openvslam::system::disable_mapping_module)
        .def("mapping_module_is_enabled", &openvslam::system::mapping_module_is_enabled)
        .def("enable_loop_detector", &openvslam::system::enable_loop_detector)
        .def("disable_loop_detector", &openvslam::system::disable_loop_detector)
        .def("loop_detector_is_enabled", &openvslam::system::loop_detector_is_enabled)
        .def("loop_BA_is_running", &openvslam::system::loop_BA_is_running)
        .def("abort_loop_BA", &openvslam::system::abort_loop_BA)
        .def("feed_monocular_frame", &openvslam::system::feed_monocular_frame, py::arg("img"), py::arg("timestamp"), py::arg("mask") = cv::Mat{})
        .def("feed_stereo_frame", &openvslam::system::feed_stereo_frame, py::arg("left_img"), py::arg("right_img"), py::arg("timestamp"), py::arg("mask") = cv::Mat{})
        .def("feed_RGBD_frame", &openvslam::system::feed_RGBD_frame, py::arg("rgb_img"), py::arg("depthmap"), py::arg("timestamp"), py::arg("mask") = cv::Mat{})
        .def("pause_tracker", &openvslam::system::pause_tracker)
        .def("tracker_is_paused", &openvslam::system::tracker_is_paused)
        .def("resume_tracker", &openvslam::system::resume_tracker)
        .def("request_reset", &openvslam::system::request_reset)
        .def("reset_is_requested", &openvslam::system::reset_is_requested)
        .def("request_terminate", &openvslam::system::request_terminate)
        .def("terminate_is_requested", &openvslam::system::terminate_is_requested);

    py::class_<openvslam::publish::map_publisher, std::shared_ptr<openvslam::publish::map_publisher>>(m, "map_publisher")
        // .def(py::init<const std::shared_ptr<openvslam::config>&, openvslam::data::map_database*>(), py::arg("cfg"), py::arg("map_db"))
        .def("set_current_cam_pose", &openvslam::publish::map_publisher::set_current_cam_pose, py::arg("cam_pose_cw"))
        .def("get_current_cam_pose", &openvslam::publish::map_publisher::get_current_cam_pose)
        .def("get_keyframes", &openvslam::publish::map_publisher::get_keyframes_pybind, py::return_value_policy::reference_internal);
    // .def("get_landmarks", &openvslam::publish::map_publisher::get_landmarks, py::arg("all_landmarks"), py::arg("local_landmarks"));

    py::class_<socket_publisher::publisher>(m, "socket_publisher")
        .def(py::init<const std::shared_ptr<openvslam::config>&, 
        openvslam::system*, 
        const std::shared_ptr<openvslam::publish::frame_publisher>&, 
        const std::shared_ptr<openvslam::publish::map_publisher>&>(), 
        py::arg("cfg"), py::arg("system"), py::arg("frame_publisher"), py::arg("map_publisher"))
        .def("is_paused", &socket_publisher::publisher::is_paused)
        .def("is_terminated", &socket_publisher::publisher::is_terminated)
        .def("request_pause", &socket_publisher::publisher::request_pause)
        .def("request_terminate", &socket_publisher::publisher::request_terminate)
        .def("resume", &socket_publisher::publisher::resume)
        .def("run", &socket_publisher::publisher::run);


    m.def("non_stop_rgbd_tracking", &non_stop_rgbd_tracking, "Function for tracking.",
          py::arg("config_file_path"),
          py::arg("vocab_file_path"),
          py::arg("sequence_dir_path"),
          py::arg("frame_skip"),
          py::arg("no_sleep"),
          py::arg("auto_term"),
          py::arg("eval_log"),
          py::arg("map_db_path"));

    // For testing purposes
    m.def("add", &add, "A function which adds two numbers");

}