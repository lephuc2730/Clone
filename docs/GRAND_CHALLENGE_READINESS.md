# Pine-Apple Grand Challenge Readiness — Group 5

## Current status

This repository contains an integrated Grand Challenge mission controller plus the semester PLC, Nav2 and MoveIt components.

### Ready in code / runtime interface verified

| Requirement | Status | Evidence / implementation |
|---|---|---|
| PLC/HMI status topic | READY | `/hmi/unified_status` |
| Build of all 3 packages | READY | `pa_warehouse_status`, `hand_solo_virtual_nav`, `hand_solo_arm` |
| Nav2 action | READY | `/navigate_to_pose` |
| MoveIt action | READY | `/move_action` |
| Lidar obstacle source | READY | `/virtual_hand_solo/scan` |
| Arbitrary-start gate | READY IN CODE | waits for RViz `/initialpose` then AMCL |
| Safe arm before navigation | READY IN CODE | `SAFE_ARM` state before Nav2 shelf travel |
| Continuous mission queue | READY IN CODE | pending deque + automatic next cycle |
| Large/Medium/Small classification | READY IN CODE | PLC count deltas, weight fallback |
| Retry/manual fallback | READY | `/warehouse/start_*`, `/warehouse/retry_current` |
| Placement screenshot hook | READY | waits for `BOX_RELEASED_ON_SHELF` |

### Still requires live calibration / proof

| Requirement | Remaining work |
|---|---|
| PLC sorts each L/M/S box correctly | Must be demonstrated through HMI/PLC during assessed run |
| PLC counts accurately | Must deploy boxes and confirm Large/Medium/Small/Total values |
| Large physical grasp | Verify simulator box attachment/grasp |
| Medium physical grasp | Verify simulator box attachment/grasp |
| Small physical grasp | Verify simulator box attachment/grasp |
| Kevin avoidance | Walk dynamic obstacle in front during live Nav2 test |
| Shared right-corner shelf | Large `(31.0,-5.5,π)`, Medium `(31.0,-4.7,π)`, Small `(31.0,-6.3,π)`; verify exact stop/orientation live |
| Stable box placement | Verify physical/simulated release and stability |
| Full L→M→S continuous run | Run after shelf/grasp calibration |

## Intended state sequence

```text
WAITING_FOR_JUDGE_INITIAL_POSE
→ LOCALIZING
→ LOCALIZED
→ READY_FOR_BOX
→ SAFE_ARM_BEFORE_PICKUP
→ NAVIGATING_PICKUP
→ PICKING_<CATEGORY>
→ ARM_RETRACTED_SAFE
→ NAVIGATING_<CATEGORY>_SHELF
→ PLACING_<CATEGORY>
→ BOX_RELEASED_ON_SHELF
→ ARM_RETRACTED_AFTER_PLACE
→ NAVIGATING_PICKUP_RETURN
→ BOX_COMPLETE
→ READY_FOR_BOX / next queued box
```

## Demo-day minimum validation order

1. Start official Docker stack.
2. Build Group 5 packages.
3. Run `scripts/grand_challenge_preflight.sh`.
4. Launch `grand_challenge.launch.py`.
5. Set RViz **2D Pose Estimate** at the actual robot start.
6. Echo `/warehouse/mission_status`.
7. Test **Large only** first.
8. Confirm pickup arm pose and actual box attachment.
9. Confirm the shared right-corner shelf lane goals.
10. Run L→M→S continuously.
11. Put Kevin in front of Hand Solo and verify Nav2 avoidance.
12. Capture placement evidence.

## Do not claim as completed until seen live

- physical box grasp/attachment
- stable shelf release
- final live confirmation of the shared shelf lane coordinates
- full three-box autonomous run
- Kevin avoidance in the assessed warehouse
