# robstride_driver

The motor profile registry in `src/motor_profile.cpp` owns the RS00–RS06 and
EL05 protocol ranges. `motor_profile()` exposes these to configuration clients;
unknown names are rejected. These ranges retain the values checked against the
RobStride English manuals dated July 13, 2026, linked in the source and repository
README. They describe CAN normalization, not recommended operating limits.

`robstride_driver` is the bridge-independent core library for RobStride
actuators using the documented 29-bit private CAN protocol. It provides frame
encoding and decoding, `can_msgs/msg/Frame` topic transport, motor lifecycle
commands, feedback monitoring, and Run-mode recovery.

Position feedback is accumulated across periodic wraparounds while the driver
runs. Each joint selects `position_recovery=restore` (default) or `reset` for
unexpected motor resets and ambiguous feedback gaps. Restore selects the phase
equivalent nearest the last position; it assumes less than half a recovery
period of unobserved motion and does not persist across node restarts. See the
[position retention reference](../README.md#position-and-turn-count-retention)
for configuration, command-coordinate handling, and limitations.

The package does not open a SocketCAN interface and does not provide a
standalone ROS node. Applications configure the transmit and receive topics
through `robstride_ros2_control`, then connect any compatible CAN bridge. The
example package uses `ros2_socketcan`.

Public headers are installed under `robstride_driver/` and cover:

- protocol constants and command/feedback encoding;
- per-model and per-joint limits;
- CAN topic transport;
- motor activation, stop, watchdog, and feedback handling.
- lock-free snapshots of traffic counters and per-motor feedback timing.

`RobStrideDriver::metrics()` returns the measured transmit categories,
latest-command-wins motion-command replacement count, recognized receive
counts, transport health, and per-motor mode, temperature, decoded faults,
recovery activity, feedback rate, and age. The snapshot reads a consistent
atomic status sample per motor and does not acquire the transport worker or
driver state mutex. When the normal ROS topic transport is used, the same
information is published once per second as standard diagnostics on
`/diagnostics`.

While active, the driver distinguishes temporary topic endpoint loss from a
persistent transmit failure. Persistent endpoint loss, a stalled sender, or an
unexpectedly stopped worker is propagated through the Hardware Component's
`write()` result. Motor feedback timeout remains an independent end-to-end
check because DDS publication alone cannot prove physical CAN delivery or motor
execution.

Most users should integrate this library through the
[`robstride_ros2_control`](https://github.com/s2015-turtle/robstride_ros2/tree/main/robstride_ros2_control)
Hardware Component. See the
[repository README](https://github.com/s2015-turtle/robstride_ros2#readme) for
supported actuators, safety behavior, configuration parameters, and
installation instructions.

Per-motor `~/zero_position_<can_id>` Trigger services rebase the current ROS joint
position to zero without sending a motor-zero command. Position control must be
released and hardware must be active with fresh feedback. See the
[runtime origin procedure](../README.md#set-the-current-joint-position-as-zero-at-runtime).

Position control now translates ROS accumulated coordinates using a stopped
`0x7019` internal-position measurement before enable. Reboots invalidate this
reference. Resynchronization pauses every axis, drops queued active commands,
and requires previously claimed position controllers to release and reclaim
position before resuming. Maintenance waits occur in the control read thread;
this interval does not preserve the normal realtime update period.

Upper-level homing is available through per-motor Trigger services:
`begin_homing_<id>`, `finish_homing_<id>`, and `homing_ready_<id>`.
Release all command interfaces and stop before beginning or finishing. Between
these calls, use velocity/effort control and detect the reference externally.
Position control is rejected during homing. Joint parameters
`homing_velocity_limit` (default 0.5 rad/s) and `homing_effort_limit`
(default 0.5 Nm) constrain recovery motion. During homing, Kp is zero and Kd is derated using the effort budget and a
velocity-error allowance. This does not implement a hardware current limit.
`finish_homing` acknowledges a queued request: the next control read stops the
motor, sends a mechanical-zero command, checks the internal angle, and restores
the configured command limits with ROS origin zero. Poll `homing_ready` before
starting a new position trajectory. Existing `zero_position` remains a software
coordinate change and does not issue a mechanical-zero command.

The first write after claiming position must match fresh feedback within
`position_start_tolerance` (default 0.01 in ROS joint units). A mismatched initial
target is inhibited with zero gains until position is released and reclaimed.
Write one current-position hold cycle before starting a new trajectory; later
targets are checked against operational and translated wire limits, without a
position-error threshold. All command claims are rejected while mechanical-zero
confirmation is pending.

Boot feedback may change coordinate representation by one output revolution.
Recovery keeps mapping these samples to the same accumulated coordinate until
Run feedback agrees with internal-position readback, then resumes normal wire
unwrapping. This avoids adding a false turn during multi-turn reboot recovery.
Configured startup mechanical zero uses the same confirmed stopped-readback path
and preserves the configured ROS offset.
