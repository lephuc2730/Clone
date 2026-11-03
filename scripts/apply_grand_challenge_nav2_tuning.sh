#!/usr/bin/env bash
set -euo pipefail

echo "=== Applying Grand Challenge Nav2 runtime tuning ==="

ros2 param set /amcl update_min_d 0.0
ros2 param set /amcl update_min_a 0.0
ros2 param set /controller_server controller_frequency 10.0
ros2 param set /planner_server expected_planner_frequency 2.0
ros2 param set /local_costmap/local_costmap update_frequency 10.0
ros2 param set /local_costmap/local_costmap publish_frequency 5.0

echo
echo "=== Verify ==="
ros2 param get /amcl update_min_d
ros2 param get /amcl update_min_a
ros2 param get /controller_server controller_frequency
ros2 param get /planner_server expected_planner_frequency
ros2 param get /local_costmap/local_costmap update_frequency
ros2 param get /local_costmap/local_costmap publish_frequency

echo "Pre-start TF/BT timing is supplied by config/handsolo-nav2-grand-challenge.yaml."
echo "Grand Challenge AMCL refresh tuning applied."
