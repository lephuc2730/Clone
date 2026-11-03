# Grand Challenge: physical box attachment blocker (2026-11-04)

## Verified in official Docker stack

- Nav2 pickup → Large shelf → pickup: **PASS**, workflow run 41673513311.
- MoveIt SAFE_ARM → PICK_APPROACH → PICK_GRASP → PICK_RETRACT → SAFE_ARM_RETURN: **PASS**, workflow run 41677961683. All five `MoveGroup` results returned status=4 and MoveIt error_code=1.
- ROS 2 runtime interface discovery: **PASS as a diagnostic**, workflow run 41678824265. It found **no ROS service or action** matching grip/attach/detach/vacuum/contact/proximity/model/link/box. Matching topics were `/attached_collision_object` (MoveIt planning-scene collision object, **not** a Unity physics attachment), `/display_contacts`, `/joint_states`, and `/virtual_hand_solo/*`. The only matching arm action was `/tmr_arm_controller/follow_joint_trajectory`. No physical grasp interface was verified.

## Why the full challenge is not yet complete

`pa_warehouse_status/pa_warehouse_status/warehouse_mission_controller.py` currently publishes `CLOSE`/`OPEN` strings on `/warehouse/gripper_command` but does **not** wait for an acknowledgment from a working gripper adapter. Its `BOX_RELEASED_ON_SHELF` status is therefore a **commanded/intended state**, not evidence that a Unity box was picked up, carried or deposited. Do not present this as a successful physical pick-and-place.

The `sepuku1` branch of `lephuc2730/IRS_2026_GROUP5` contains MoveIt arm waypoints in `hand_solo_arm/hand_solo_arm/hs_pick_place.py`, but no gripper attach/detach implementation; its `#trigger under proixmity condition` is only a comment.

## Exact live checks needed in course simulator

1. Open the **official Pine-Apple Unity warehouse simulation** and confirm that a box is actually present at the pickup conveyor.
2. In the running Robot HMI/Unity UI, inspect for a built-in gripper/proximity/attach control; check whether touching a box with the end effector automatically parents it to the arm. If so, document the trigger, exact required arm pose, and any box-type requirements.
3. Command the already-tested MoveIt approach/grasp/retract sequence **with a box physically present**. Record whether the box follows the end effector when retracting and when the mobile base moves. A MoveIt success result alone does not count.
4. If the box does not follow, obtain the simulator's **Unity attachment API / plugin / bridge specification** from course staff or simulator source. An ROS-only `/warehouse/gripper_command` publisher cannot create a Unity physics joint without a receiver.
5. Implement and validate the adapter against that documented interface. Require positive attach/detach acknowledgment (and preferably object pose/proximity confirmation) before advancing the mission state. On timeout or negative acknowledgment, stop the mission instead of marking box picked or released.
6. Verify a box remains attached during pickup → Large shelf navigation, detaches at the shelf, and remains at the shelf after the arm retracts. Save screenshots/logs showing the box before grasp, while carried, and after release.
7. Only after the physical Large box cycle is proven, run PLC/HMI counters and Medium/Small cycles, then Kevin obstacle avoidance and the uninterrupted three-box demo.

**Do not add a speculative ROS attach service or use MoveIt `/attached_collision_object` as proof of physical Unity attachment.**

## Evidence links

- https://github.com/lephuc2730/Clone/actions/runs/41673513311
- https://github.com/lephuc2730/Clone/actions/runs/41677961683
- https://github.com/lephuc2730/Clone/actions/runs/41678824265
