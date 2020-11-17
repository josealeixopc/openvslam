#ifndef MY_RGBD_SLAM_H
#define MY_RGBD_SLAM_H

#include <iostream>

int non_stop_rgbd_tracking(const std::string& config_file_path,
                   const std::string& vocab_file_path, const std::string& sequence_dir_path,
                   const unsigned int frame_skip, const bool no_sleep, const bool auto_term,
                   const bool eval_log, const std::string& map_db_path);

int add(int a, int b);

#endif