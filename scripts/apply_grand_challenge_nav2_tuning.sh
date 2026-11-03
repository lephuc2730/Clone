#!/usr/bin/env bash
set -euo pipefail

echo "=== Applying Grand Challenge Nav2 runtime tuning ==="

ros2 param set /amcl update_min_d 0.0
ros2 param set /amcl update_min_a 0.0
ros2 param set /amcl transform_tolerance 3.0
ros2 param set /controller_server FollowPath.transform_tolerance 3.0
ros2 param set /local_costmap/local_costmap transform_tolerance 3.0
ros2 param set /bt_navigator default_server_timeout 5000

echo
echo "=== Verify ==="
ros2 param get /amcl update_min_d
ros2 param get /amcl update_min_a
ros2 param get /amcl transform_tolerance
ros2 param get /controller_server FollowPath.transform_tolerance
ros2 param get /local_costmap/local_costmap transform_tolerance
ros2 param get /bt_navigator default_server_timeout

echo "Grand Challenge Nav2 tuning applied."
