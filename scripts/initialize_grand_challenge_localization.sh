#!/usr/bin/env bash
set -eo pipefail

source /opt/ros/jazzy/setup.bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Grand Challenge localization initialization ==="
python3 "$SCRIPT_DIR/publish_initial_pose.py"

echo "Waiting for /amcl_pose..."
for attempt in 1 2 3 4 5; do
  if timeout 5s ros2 topic echo /amcl_pose --once >/tmp/grand_challenge_amcl.txt 2>/dev/null; then
    cat /tmp/grand_challenge_amcl.txt
    break
  fi
  if [ "$attempt" -eq 5 ]; then
    echo "ERROR: AMCL did not publish a pose."
    exit 1
  fi
  sleep 1
done

echo "Clearing costmaps after localization reset..."
ros2 service call /local_costmap/clear_entirely_local_costmap nav2_msgs/srv/ClearEntireCostmap "{}" >/dev/null 2>&1 || true
ros2 service call /global_costmap/clear_entirely_global_costmap nav2_msgs/srv/ClearEntireCostmap "{}" >/dev/null 2>&1 || true

sleep 2

echo "Waiting for fresh map -> base_link TF..."
for attempt in 1 2 3 4 5; do
  if timeout 4s ros2 run tf2_ros tf2_echo map virtual_hand_solo/base_link >/tmp/grand_challenge_tf.txt 2>/dev/null; then
    tail -20 /tmp/grand_challenge_tf.txt
    echo "LOCALIZATION_READY"
    exit 0
  fi
  sleep 1
done

echo "ERROR: map -> base_link TF was not ready."
exit 1
