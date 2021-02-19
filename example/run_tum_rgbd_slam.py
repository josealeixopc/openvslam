import sys

sys.path.append(
    '/home/jazz/Projects/FEUP/ProDEI/openvslam/build/lib.linux-x86_64-3.7')

import openvslam_python
import argparse
import csv
import os
from typing import List
from cv2 import cv2
import time
from tqdm import tqdm

class TumRgbdSequence:
    class RgbdFrame:
        def __init__(self, rgb_img_path: str, depth_image_path: str, timestamp: float):
            self.rgb_img_path: str = rgb_img_path
            self.depth_image_path: str = depth_image_path
            self.timestamp: float = timestamp

    class ImgInfo:
        def __init__(self, timestamp: float, img_file_path: str):
            self.timestamp: float = timestamp
            self.img_file_path: str = img_file_path

    @staticmethod
    def acquire_image_information(seq_dir_path: str, timestamp_file_path: str):
        img_infos = []

        with open(timestamp_file_path) as tmstmp_file:
            csv_reader = csv.reader(tmstmp_file, delimiter=" ")
            for row in csv_reader:
                img_infos.append(
                    TumRgbdSequence.ImgInfo(float(row[0]), os.path.join(seq_dir_path, row[1])))

        return img_infos

    def __init__(self, seq_dir_path: str, min_timediff_thr: float = 0.1):
        self.seq_dir_path: str = seq_dir_path
        self.min_timediff_thr: float = min_timediff_thr
        self._timestamps: List[float] = []
        self._rgb_img_file_paths: List[str] = []
        self._depth_img_file_paths: List[str] = []

        rgb_img_infos = TumRgbdSequence.acquire_image_information(
            seq_dir_path, os.path.join(seq_dir_path, "rgb.txt"))
        depth_img_infos = TumRgbdSequence.acquire_image_information(
            seq_dir_path, os.path.join(seq_dir_path, "depth.txt"))

        for rgb_img_info in rgb_img_infos:
            nearest_depth_img_timestamp = depth_img_infos[0].timestamp
            nearest_depth_img_file_path = depth_img_infos[0].img_file_path

            min_timediff = abs(rgb_img_info.timestamp -
                               nearest_depth_img_timestamp)

            for depth_img_info in depth_img_infos:
                timediff = abs(rgb_img_info.timestamp -
                               depth_img_info.timestamp)

                if timediff < min_timediff:
                    min_timediff = timediff
                    nearest_depth_img_timestamp = depth_img_info.timestamp
                    nearest_depth_img_file_path = depth_img_info.img_file_path

            if min_timediff_thr < min_timediff:
                continue

            self._timestamps.append(
                (rgb_img_info.timestamp + nearest_depth_img_timestamp) / 2.0)
            self._rgb_img_file_paths.append(rgb_img_info.img_file_path)
            self._depth_img_file_paths.append(nearest_depth_img_file_path)

    def get_frames(self) -> List[RgbdFrame]:
        assert len(self._timestamps) == len(self._rgb_img_file_paths)
        assert len(self._timestamps) == len(self._depth_img_file_paths)

        frames = []

        for i in range(len(self._timestamps)):
            frames.append(TumRgbdSequence.RgbdFrame(
                self._rgb_img_file_paths[i],
                self._depth_img_file_paths[i],
                self._timestamps[i]
            ))

        return frames


def rgbd_tracking(config_file_path: str, vocab_file_path: str, sequence_dir_path: str,
                  frame_skip: int = 1, no_sleep: bool = True, auto_term: bool = True, eval_log: bool = False, map_db_path: str = ""):

    tum_rgbd_sequence = TumRgbdSequence(sequence_dir_path)
    frames = tum_rgbd_sequence.get_frames()

    config = openvslam_python.config(config_file_path)

    slam = openvslam_python.system(cfg=config, vocab_file_path=vocab_file_path)
    slam.startup()

    track_times: List[float] = []

    for i in tqdm(range(len(frames))):
        frame = frames[i]
        rgb_img = cv2.imread(frame.rgb_img_path, cv2.IMREAD_UNCHANGED)
        depth_img = cv2.imread(frame.depth_image_path, cv2.IMREAD_UNCHANGED)

        tp_1 = time.time()

        if (rgb_img is not None) and (depth_img is not None) and (i % frame_skip == 0):
            slam.feed_RGBD_frame(rgb_img, depth_img, float(frame.timestamp))
            
        tp_2 = time.time()

        track_time = tp_2 - tp_1

        if i % frame_skip == 0:
            track_times.append(track_time)

        if(not no_sleep and i < len(frames) - 1):
            wait_time = frames[i + 1].timestamp - (frame.timestamp + track_time)
            if 0.0 < wait_time:
                time.sleep(wait_time * 1e6)

        if slam.terminate_is_requested():
            break

    while slam.loop_BA_is_running():
        time.sleep(5)

    slam.shutdown()

    if eval_log:
        slam.save_frame_trajectory("frame_trajectory.txt", "TUM")
        slam.save_keyframe_trajectory("keyframe_trajectory.txt", "TUM")
        
        with open("track_times.txt", 'w') as tt:
            for track_time in track_times:
                tt.write(f"{track_time}\n")
        
    if map_db_path:
        slam.save_map_database(map_db_path)

    track_times.sort()
    total_track_time = sum(track_times)
    print("Median tracking time: ", track_times[len(track_times) // 2])
    print("Average tracking time: ", total_track_time / len(track_times))


if __name__ == "__main__":
    # parser = argparse.ArgumentParser(description="Run SLAM on the TUM RGBD dataset.")
    # parser.add_argument('config_file_path', type=str, help='path to the config file')
    # parser.add_argument('vocab_file_path', type=str, help='path to DBoW vocab file')
    # parser.add_argument('sequence_dir_path', type=str, help='path to the TUM dataset')
    # parser.add_argument('frame_skip', type=int, help='interval of skip frame')
    # parser.add_argument('--no-sleep', action='store_true', help='not wait for next frame in real time')
    # parser.add_argument('--auto-term',  action='store_true', help='automatically terminate the viewer')
    # parser.add_argument('--eval-log',  action='store_true', help='store trajectory and tracking times for evaluation')
    # parser.add_argument('--map-db-path', default="", type=str, help='store a map database at this path after SLAM')

    # args = parser.parse_args()
    # rgbd_tracking(**vars(args))

    # python run_tum_rgbd_slam.py /home/jazz/Documents/simusafe_dataset/tum_rgbd_config.yaml /home/jazz/Documents/simusafe_dataset/orb_vocab.dbow2 /home/jazz/Projects/FEUP/ProDEI/simusafe/python-modules/output/tum_dataset 1 --no-sleep

    rgbd_tracking(
        "/home/jazz/Documents/simusafe_dataset/tum_rgbd_config.yaml",
        "/home/jazz/Documents/simusafe_dataset/orb_vocab.dbow2",
        "/home/jazz/Projects/FEUP/ProDEI/simusafe/python-modules/output/tum_dataset",
        eval_log=True
    )