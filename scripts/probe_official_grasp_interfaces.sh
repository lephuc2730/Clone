#!/usr/bin/env bash
# Read-only inspection of official simulator gripper/box interfaces.
# Run inside omron-workspace with ROS sourced; does not command robot or PLC.
set -u
OUT="${1:-/tmp/grand_challenge_grasp_probe}"
mkdir -p "$OUT"
echo "Writing read-only diagnostics to $OUT"
date -Is > "$OUT/timestamp.txt"
if ! command -v ros2 >/dev/null 2>&1; then
  echo "ros2 not on PATH: source /opt/ros/jazzy/setup.bash and workspace/install/setup.bash" >&2
  exit 2
fi
timeout 20 ros2 node list > "$OUT/nodes.txt" 2>&1 || true
timeout 20 ros2 topic list -t > "$OUT/topics.txt" 2>&1 || true
timeout 20 ros2 service list -t > "$OUT/services.txt" 2>&1 || true
timeout 20 ros2 action list -t > "$OUT/actions.txt" 2>&1 || true
grep -Ei 'grip|attach|detach|vacuum|suction|box|conveyor|unity|warehouse|joint|tf' "$OUT/topics.txt" > "$OUT/relevant_topics.txt" || true
grep -Ei 'grip|attach|detach|vacuum|suction|box|conveyor|unity|warehouse' "$OUT/services.txt" > "$OUT/relevant_services.txt" || true
grep -Ei 'grip|attach|detach|vacuum|suction|box|conveyor|unity|warehouse' "$OUT/nodes.txt" > "$OUT/relevant_nodes.txt" || true
# Inspect command subscribers. A publisher with zero subscribers cannot actuate the simulated gripper.
timeout 15 ros2 topic info /warehouse/gripper_command -v > "$OUT/gripper_command_info.txt" 2>&1 || true
for topic in /hmi/unified_status /warehouse/mission_status /amcl_pose; do
  file="${topic//\//_}"
  timeout 8 ros2 topic echo "$topic" --once > "$OUT/${file}.txt" 2>&1 || true
done
echo
echo "=== Gripper command endpoint ==="
cat "$OUT/gripper_command_info.txt"
echo
echo "=== Relevant topics ==="
cat "$OUT/relevant_topics.txt"
echo
echo "=== Relevant services ==="
cat "$OUT/relevant_services.txt"
echo
echo "This script does NOT prove attachment. Verify box motion visually in the official simulator."
