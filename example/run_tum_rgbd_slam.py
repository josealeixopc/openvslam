import argparse
import sys

sys.path.append('/home/jazz/Projects/FEUP/ProDEI/openvslam/build/lib.linux-x86_64-3.7')

import openvslam_python

def rgbd_tracking():
    config = openvslam_python.config(config_file_path="/home/jazz/Downloads/dataset/tum_rgbd_config.yaml")

if __name__ == "__main__":
    # parser = argparse.ArgumentParser(description="Run SLAM on the TUM RGBD dataset.")
    # parser.add_argument('config_file_path', type=str, help='path to the config file')
    # parser.add_argument('vocab_file_path', type=str, help='path to DBoW vocab file')
    # parser.add_argument('sequence_dir_path', type=str, help='path to the TUM dataset')
    # parser.add_argument('frame_skip', type=int, help='interval of skip frame')
    # parser.add_argument('no_sleep', type=bool, help='not wait for next frame in real time')
    # parser.add_argument('auto_term', type=bool, help='automatically terminate the viewer')
    # parser.add_argument('eval_log', type=bool, help='store trajectory and tracking times for evaluation')
    # parser.add_argument('map_db_path', type=str, help='store a map database at this path after SLAM')



    # args = parser.parse_args()
    # openvslam_python.non_stop_rgbd_tracking(**vars(args))
    # rgbd_tracking()
    print("HEllo")
