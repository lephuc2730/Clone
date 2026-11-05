# Official Pine-Apple PLC recovery and physical-demo gate (6 Nov 2026)

## Evidence, not assumptions

The user's live OpenPLC runtime log contains:

```text
[ERROR] No libplc_*.so file found in ./build
[ERROR] Failed to find libplc file
[ERROR] State transition to RUNNING failed
```

`plc_main` and `python3` were present in the running container, and Docker reported `irs-openplc-runtime` healthy. **Healthy container != loaded/running PLC ladder program.** Do not diagnose this as a ROS Nav2 failure. Do not restart Nav2 or delete the OpenPLC volume.

The official course repository's `openplc-data/res/project.json` has `"pous": []`, and its resource references a program named `main`. That sample project **does not contain the ladder logic needed for the conveyor**. The official `irs-openplc-editor` service uses the host X11 `DISPLAY` and `/tmp/.X11-unix`; it is an **Electron GUI**, not an HTTP editor. The OpenPLC Runtime itself is exposed via HTTPS on host port **8443**. VS Code is a different service on port 8080.

## Minimal live recovery, without disturbing the proven navigation stack

On the Ubuntu **host**, in the directory containing the official `compose.yaml`:

```bash
xhost +local:root
docker compose up -d irs-openplc-editor
docker compose ps
docker compose logs --tail=80 irs-openplc-editor
```

Open the graphical OpenPLC Editor window on the Ubuntu desktop, not in the VS Code browser. If the editor does not appear, inspect `echo "$DISPLAY"` and `docker compose logs irs-openplc-editor` before changing anything. On a memory-limited VirtualBox VM, stop only the editor once a program is successfully deployed.

In the editor, **load an existing course-provided conveyor PLC project if available**. Otherwise implement the required ladder program using the **actual course Modbus register map**; do not invent %IX/%QX addresses. Verify the program defines the `main` POU, compiles, and is deployed to the runtime. The course README says to save ST files in `editor_shared_folder` so they appear under `industrial-robots-and-systems-world/openplc_data`. Preserve the source file in Clone after it is validated.

Check runtime status at the exposed HTTPS port and inspect logs:

```bash
docker compose logs --tail=120 irs-openplc-runtime | grep -Ei 'libplc|state transition|running|modbus|error|failed'
```

A `libplc_*.so` library must be present and the runtime must enter RUNNING. Do not assume `GET /api/version` on port 8080 works: that endpoint returned `Not found` in the user's actual runtime.

Test one conveyor ON/OFF command in the **official Unity IRS_Warehouse HMI** with a box present; verify the belt physically moves/stops. Only then proceed to the arm.

## Large-box physical evidence gate

The controller's `/warehouse/gripper_command` currently publishes `CLOSE`/`OPEN`, but the official ROS runtime inspection did **not** identify a Unity physical attach/detach receiver. MoveIt success and `/attached_collision_object` are not evidence that a box follows the arm.

1. Use RViz 2D Pose Estimate at the actual starting pose; verify `/amcl_pose`.
2. Tune `pickup_x`, `pickup_y`, `pickup_yaw` against the **real box**; `(5,0)` is only a default. Keep the robot safely clear of the conveyor.
3. With a Large box physically at pickup, execute the proven approach/grasp sequence. Confirm that the box **moves with the gripper during lift and retract**. If not, stop. Identify the Unity-side gripper/contact API or obtain it from course staff; never bypass `allow_unverified_gripper:=false` merely to make mission status say complete.
4. Only with proven attachment, carry to the Large shelf, verify physical release/stability, retract, and return.
5. Record an MP4 **of the actual simulator window**, with visible box at pickup, attached during travel, and stable on shelf. A screenshot or CI dry run of arm/nav alone is not a full-cycle demo.

## What CI can and cannot prove

GitHub-hosted Actions runners can start the public official Docker stack and capture screenshots or videos of whatever actually renders on the runner, but they cannot operate the user's existing VirtualBox GUI. A workflow artifact is only valid full-cycle evidence if its recorded run shows the physical Large box being grasped, transported and released. The current Clone dry-run workflow's manual category triggers and mission-state logs are **not** such proof. Do not publish or label a navigation-only recording as a successful Large-box cycle.
