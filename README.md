# IRS_2026_GROUP5 — Pine-Apple Grand Challenge

This repository now contains the integrated Group 5 solution for **12059 Industrial Robots and Systems — Pine-Apple Grand Challenge 2026** while preserving the earlier Week 5/6/10 lab work.

## Integrated Grand Challenge flow

```text
Judge places Hand Solo at arbitrary start
        ↓
RViz 2D Pose Estimate → AMCL localisation
        ↓
PLC/HMI deploys + sorts box
        ↓
/hmi/unified_status
        ↓
Mission controller detects Large / Medium / Small
        ↓
Safe arm position
        ↓
Nav2 → pickup/conveyor
        ↓
MoveIt → pick approach / grasp pose
        ↓
Arm retracts to SAFE travel pose
        ↓
Nav2 → category shelf
   ↳ live lidar costmaps handle dynamic obstacles ("Kevin")
        ↓
MoveIt → place pose
        ↓
OPEN hook + 2 s placement hold
        ↓
Safe arm retract
        ↓
Nav2 → pickup/home
        ↓
Next queued box automatically
```

## Main Grand Challenge files

- `pa_warehouse_status/pa_warehouse_status/warehouse_mission_controller.py` — integrated state machine
- `pa_warehouse_status/config/grand_challenge_params.yaml` — pickup + shelf targets
- `pa_warehouse_status/launch/grand_challenge.launch.py` — controller launch
- `scripts/grand_challenge_preflight.sh` — checks PLC/Nav2/MoveIt/lidar interfaces
- `scripts/capture_box_on_shelf.sh` — screenshot helper after shelf release
- `.github/workflows/grand-challenge-preflight.yml` — official full-stack safety-locked validation
- `.github/workflows/grand-challenge-build-check.yml` — build/static validation
- `.github/workflows/grand-challenge-runtime-probe.yml` — full official runtime interface probe

## Important map choice

For the Grand Challenge, use the **official Hand Solo/Nav2 stack and official full warehouse map** launched by the course Docker environment.

Do **not** start the old Group 5 `hand_solo_virtual_nav/nav_launch.py` at the same time as the official Hand Solo Nav2 stack. The Group 5 map is retained for the earlier lab evidence, but it is only a partial SLAM map and does not cover the right-side warehouse shelf around x≈31.

## Current shelf targets

`pa_warehouse_status/config/grand_challenge_params.yaml` currently contains:

```text
Shared right-corner shelf:
Large:  x=31.0, y=-5.5, yaw=3.14159
Medium: x=31.0, y=-4.7, yaw=3.14159
Small:  x=31.0, y=-6.3, yaw=3.14159
```

All three categories now use the same marked lower-right shelf area. They use slightly different Y positions so the robot places Large, Medium and Small along the same shelf rather than returning to one identical drop point.

## Build tomorrow

From the course workspace:

```bash
cd /workspace/irs_ws/src/IRS_2026_GROUP5
git pull origin main

cd /workspace/irs_ws
source /opt/ros/jazzy/setup.bash
colcon build --packages-select pa_warehouse_status hand_solo_virtual_nav hand_solo_arm
source install/setup.bash
```

## Start the official course system

From the folder containing the course `compose.yaml`, make sure the Hand Solo command uses the simulated TM arm **and keeps the base, MoveIt and Nav2 enabled**:

```text
tm_use_simulation:=true use_arm:=true use_base:=true use_moveit:=true use_nav2:=true use_rviz:=true
```

A quick way to switch the current course compose file from `false` to `true` is:

```bash
sed -i 's/tm_use_simulation:=false/tm_use_simulation:=true/' compose.yaml
grep -A2 'command: ros2 launch handsolo_ros' compose.yaml
docker compose pull
docker compose up
```

This matters: the live dry-run showed MoveIt execution returning `CONTROL_FAILED` with `tm_use_simulation:=false`, while the SAFE_ARM motion completed when simulation mode was enabled. The course manipulation lab also uses `tm_use_simulation:=true`.

The official `omron_handsolo` launch then provides the mobile base, arm, MoveIt, Nav2 and RViz.

## Preflight

Inside the ROS workspace/container:

```bash
cd /workspace/irs_ws
source install/setup.bash
bash src/IRS_2026_GROUP5/scripts/grand_challenge_preflight.sh
```

Required interfaces:

```text
/hmi/unified_status
/virtual_hand_solo/scan
/amcl_pose
/move_action
/navigate_to_pose
/amcl
/move_group
```

## Launch integrated controller

```bash
source /workspace/irs_ws/install/setup.bash
ros2 launch pa_warehouse_status grand_challenge.launch.py
```

Watch the state machine:

```bash
ros2 topic echo /warehouse/mission_status
```

Before the first cycle, use **2D Pose Estimate** in RViz at the robot's judge-specified starting location. The controller intentionally waits for `/initialpose` and an AMCL update.

## Manual test/fallback

```bash
ros2 service call /warehouse/start_large std_srvs/srv/Trigger "{}"
ros2 service call /warehouse/start_medium std_srvs/srv/Trigger "{}"
ros2 service call /warehouse/start_small std_srvs/srv/Trigger "{}"
ros2 service call /warehouse/retry_current std_srvs/srv/Trigger "{}"
```

## PLC classification

Preferred detection is by PLC count increments:

```text
counts.big     → Large
counts.medium  → Medium
counts.small   → Small
```

Weight fallback:

```text
> 10 kg   → Large
5–10 kg   → Medium
< 5 kg    → Small
```

## Dynamic obstacle avoidance

The official Nav2 stack uses the live `/virtual_hand_solo/scan` lidar in its costmaps. The intended Grand Challenge behavior is to let Nav2 detect and replan/control around Kevin rather than hard-coding an avoidance route.

## Shelf placement screenshot

Run this on the Ubuntu host from the course Docker folder before the mission:

```bash
bash /workspace/irs_ws/src/IRS_2026_GROUP5/scripts/capture_box_on_shelf.sh
```

When the controller enters `BOX_RELEASED_ON_SHELF`, the script saves a screenshot under:

```text
docs/evidence/grand_challenge/box_on_shelf_YYYYMMDD_HHMMSS.png
```

## Known live-demo limitations

1. **The conveyor/pickup base pose still needs one live verification against the judged warehouse.**
2. The current runtime exposes MoveIt and Nav2, but no confirmed ROS gripper/attach/vacuum action or service has been identified. The controller therefore publishes `/warehouse/gripper_command` with `CLOSE` / `OPEN` hooks at the correct states, but physical/simulated box attachment must still be verified live.
3. PLC automatic triggering must be observed with real HMI box deployment because idle PLC messages contain empty weight/location fields and null counts.

## Existing semester work retained

- `pa_warehouse_status` — Week 5 PLC/ROS communication
- `hand_solo_virtual_nav` — Week 6/7 mapping and Nav2 lab work
- `hand_solo_arm` — Week 10 MoveIt pick/carry/place joint sequence
- `docs/evidence/` — prior lab runtime evidence

See `docs/GRAND_CHALLENGE_READINESS.md` for the rubric-by-rubric readiness check.
