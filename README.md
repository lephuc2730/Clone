# Pine-Apple Grand Challenge — Group 5

This repository contains the current integrated solution for **12059 Industrial Robots and Systems — Pine-Apple Grand Challenge 2026**.

> **Important:** this is the active project repository. Use **`Clone`** for the Grand Challenge. Do not use the old `IRS_2026_GROUP5` paths in the demo commands below.

---

# Demo-Day Grand Challenge Procedure

Follow these steps in order. Do not jump directly to the full three-box run until the preflight, localisation, navigation and arm checks are working.

## 1. Update the Clone repository

On the machine where the project is stored:

```bash
cd ~/Clone
git pull origin main
```

Inside the ROS workspace, the project should be available as:

```text
/workspace/irs_ws/src/Clone
```

The important Grand Challenge folders are:

```text
Clone/
├── pa_warehouse_status/
├── hand_solo_arm/
├── hand_solo_virtual_nav/
└── scripts/
```

---

## 2. Start the official course Docker system

Go to the folder containing the official course `compose.yaml`.

Before starting Docker, make sure Hand Solo is using the simulated TM arm:

```text
tm_use_simulation:=true
```

The Hand Solo command should keep the arm, base, MoveIt, Nav2 and RViz enabled:

```text
tm_use_simulation:=true use_arm:=true use_base:=true use_moveit:=true use_nav2:=true use_rviz:=true
```

If the compose file still contains `tm_use_simulation:=false`, change it:

```bash
sed -i 's/tm_use_simulation:=false/tm_use_simulation:=true/' compose.yaml
```

Check it:

```bash
grep -A2 'command: ros2 launch handsolo_ros' compose.yaml
```

Then start the required services:

```bash
docker compose up -d irs-simulation irs-openplc-runtime omron-workspace omron_handsolo
```

Check that the containers are running:

```bash
docker compose ps
```

---

## 3. Enter the ROS workspace container

```bash
docker compose exec omron-workspace bash
```

Inside the container:

```bash
source /opt/ros/jazzy/setup.bash
cd /workspace/irs_ws
```

---

## 4. Build the Clone packages

```bash
colcon build --packages-select pa_warehouse_status hand_solo_virtual_nav hand_solo_arm
source install/setup.bash
```

The build should complete without errors.

---

## 5. Run the Grand Challenge preflight

```bash
bash /workspace/irs_ws/src/Clone/scripts/grand_challenge_preflight.sh
```

The important interfaces are:

```text
/hmi/unified_status
/virtual_hand_solo/scan
/amcl_pose
/move_action
/navigate_to_pose
/amcl
/move_group
```

You want the script to finish with:

```text
PRE-FLIGHT: core PLC + Nav2 + MoveIt interfaces are visible.
```

If one of the core interfaces is missing, fix that before starting the challenge.

---

## 6. Set the robot's starting location in RViz

The judge may place Hand Solo at an arbitrary starting position.

In RViz:

1. Select **2D Pose Estimate**.
2. Click the robot's actual position on the map.
3. Drag the arrow in the direction the robot is facing.

Then verify AMCL:

```bash
ros2 topic echo /amcl_pose --once
```

If an AMCL pose is printed, localisation is active.

### Optional scripted localisation helper

For repeatable testing, the repository also contains:

```bash
bash /workspace/irs_ws/src/Clone/scripts/initialize_grand_challenge_localization.sh
```

For the judged demo, RViz **2D Pose Estimate** is the preferred method because the judge may choose the robot's starting location.

---

## 7. Start the integrated Grand Challenge controller

Use the helper script:

```bash
bash /workspace/irs_ws/src/Clone/scripts/start_grand_challenge.sh
```

This script:

```text
sources ROS
→ sources the workspace
→ applies the tested Nav2 tuning
→ launches warehouse_mission_controller
```

Keep this terminal open.

---

## 8. Open a second terminal and watch mission status

Enter the workspace container again if necessary:

```bash
docker compose exec omron-workspace bash
```

Then:

```bash
source /opt/ros/jazzy/setup.bash
source /workspace/irs_ws/install/setup.bash
```

Watch the mission state machine:

```bash
ros2 topic echo /warehouse/mission_status
```

Useful PLC status monitor:

```bash
ros2 topic echo /hmi/unified_status
```

These two terminals are useful during the presentation because they show what the PLC and robot controller are doing.

---

# Proven Navigation Targets

The current tested pickup pose is:

```text
Pickup / conveyor:
x = 5.0
y = 0.0
yaw = 3.14159
```

The shelf targets are:

```text
Medium: x=31.0, y=-4.7, yaw=3.14159
Large:  x=31.0, y=-5.5, yaw=3.14159
Small:  x=31.0, y=-6.3, yaw=3.14159
```

The official Docker validation has successfully completed:

```text
localisation
→ pickup (5,0)
→ Large shelf (31,-5.5)
→ return to pickup
```

Do **not** start the old `hand_solo_virtual_nav/nav_launch.py` at the same time as the official Hand Solo Nav2 stack.

---

# Proven Arm Sequence

The official simulator validation has successfully executed:

```text
SAFE_ARM
→ PICK_APPROACH
→ PICK_GRASP
→ PICK_RETRACT
→ SAFE_ARM_RETURN
```

MoveIt reported success for each pose.

The current controller also checks both:

- ROS action status = succeeded
- MoveIt internal error code = success

This prevents the mission from continuing after a failed MoveIt plan or execution.

---

# 9. Run ONE Large box first

Do not begin with all three boxes.

Start with one Large box and watch the entire system.

Expected sequence:

```text
Judge/HMI deploys Large box
        ↓
PLC sorts and counts Large
        ↓
/hmi/unified_status
        ↓
warehouse_mission_controller detects Large
        ↓
SAFE arm
        ↓
Nav2 → conveyor pickup (5,0)
        ↓
MoveIt → PICK_APPROACH
        ↓
MoveIt → PICK_GRASP
        ↓
gripper / box attachment
        ↓
MoveIt → PICK_RETRACT
        ↓
SAFE travel pose
        ↓
Nav2 → Large shelf (31,-5.5)
        ↓
place / release
        ↓
SAFE arm
        ↓
Nav2 → pickup
        ↓
Large cycle complete
```

Watch:

```bash
ros2 topic echo /warehouse/mission_status
```

and:

```bash
ros2 topic echo /hmi/unified_status
```

---

# 10. Manual fallback controls

If automatic PLC triggering does not start the mission, use these services.

### Start Large

```bash
ros2 service call /warehouse/start_large std_srvs/srv/Trigger "{}"
```

### Start Medium

```bash
ros2 service call /warehouse/start_medium std_srvs/srv/Trigger "{}"
```

### Start Small

```bash
ros2 service call /warehouse/start_small std_srvs/srv/Trigger "{}"
```

### Retry the current failed box

```bash
ros2 service call /warehouse/retry_current std_srvs/srv/Trigger "{}"
```

### Clear the mission queue

```bash
ros2 service call /warehouse/reset_queue std_srvs/srv/Trigger "{}"
```

These are fallback/debug controls. The final judged run should preferably be triggered by the PLC/HMI.

---

# 11. Run Medium

After Large completes and the robot returns to the pickup area, deploy Medium.

Expected shelf target:

```text
x = 31.0
y = -4.7
yaw = 3.14159
```

Expected flow:

```text
Medium detected
→ pickup
→ grasp
→ retract SAFE
→ navigate to Medium shelf lane
→ place/release
→ return to pickup
```

---

# 12. Run Small

After Medium completes, deploy Small.

Expected shelf target:

```text
x = 31.0
y = -6.3
yaw = 3.14159
```

Expected flow:

```text
Small detected
→ pickup
→ grasp
→ retract SAFE
→ navigate to Small shelf lane
→ place/release
→ return
```

---

# 13. Kevin dynamic obstacle test

The official Nav2 stack uses:

```text
/virtual_hand_solo/scan
```

for obstacle information.

During a conveyor-to-shelf navigation leg, Kevin should cross in front of Hand Solo.

Expected behavior:

```text
LiDAR detects Kevin
→ local costmap updates
→ controller slows/stops/replans
→ Hand Solo avoids collision
→ navigation continues
```

Do not manually steer around Kevin unless required for safety.

---

# 14. Final full Grand Challenge run

Once the one-box tests are satisfactory, run the complete sequence:

```text
Judge places Hand Solo at arbitrary start
        ↓
Set 2D Pose Estimate
        ↓
Large deployed
→ Large sorted/count updated
→ Large picked
→ Large delivered
→ robot returns
        ↓
Medium deployed
→ Medium sorted/count updated
→ Medium picked
→ Medium delivered
→ robot returns
        ↓
Small deployed
→ Small sorted/count updated
→ Small picked
→ Small delivered
→ mission complete
```

The target is minimal manual intervention after initial localisation.

---

# PLC Classification Logic

Preferred classification uses PLC count increments:

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

The Large / Medium / Small classification logic has passed the official Docker test workflow.

---

# Current Validation Status

The following have been validated in the official Docker/simulator environment:

```text
✅ project build
✅ core preflight interfaces
✅ AMCL/localisation helper
✅ Nav2 pickup → Large shelf → return
✅ SAFE/PICK/RETRACT MoveIt arm sequence
✅ MoveIt result/error-code protection
✅ PLC Large/Medium/Small classification
✅ fail-closed gripper safety logic
```

The remaining item that must be treated carefully in the live simulator is:

```text
⚠ actual simulated box attachment / carry / release
```

The controller publishes:

```text
/warehouse/gripper_command
```

with `CLOSE` and `OPEN` at the correct mission states, but a confirmed ROS attach/detach or vacuum interface has not been identified in the official runtime.

Therefore, before the final three-box demonstration, confirm that one Large box actually follows the arm after the grasp pose and releases correctly at the shelf.

Kevin avoidance should also be demonstrated live.

---

# Useful Emergency Checks

### List warehouse services

```bash
ros2 service list | grep '^/warehouse/'
```

### List warehouse topics

```bash
ros2 topic list | grep '^/warehouse/'
```

### Check Nav2

```bash
ros2 action list | grep navigate_to_pose
```

### Check MoveIt

```bash
ros2 action list | grep move_action
```

### Check PLC

```bash
ros2 topic echo /hmi/unified_status --once
```

### Check AMCL

```bash
ros2 topic echo /amcl_pose --once
```

---

# Main Grand Challenge Files

- `pa_warehouse_status/pa_warehouse_status/warehouse_mission_controller.py` — integrated state machine
- `pa_warehouse_status/config/grand_challenge_params.yaml` — pickup and shelf targets
- `pa_warehouse_status/launch/grand_challenge.launch.py` — mission controller launch
- `scripts/grand_challenge_preflight.sh` — checks PLC, Nav2, MoveIt and LiDAR interfaces
- `scripts/start_grand_challenge.sh` — applies Nav2 tuning and starts the controller
- `scripts/initialize_grand_challenge_localization.sh` — repeatable localisation helper
- `scripts/test_grand_challenge_arm_sequence.py` — isolated MoveIt validation
- `scripts/test_grand_challenge_plc_events.py` — PLC classification validation
- `scripts/test_grand_challenge_moveit_result.py` — MoveIt result guard validation
- `scripts/capture_box_on_shelf.sh` — evidence screenshot helper

---

# Existing Semester Work Retained

- `pa_warehouse_status` — PLC/ROS communication
- `hand_solo_virtual_nav` — mapping and navigation lab work
- `hand_solo_arm` — MoveIt arm lab work
- `docs/evidence/` — previous runtime evidence

See `docs/GRAND_CHALLENGE_READINESS.md` for the rubric-by-rubric readiness check.
