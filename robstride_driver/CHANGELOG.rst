^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Changelog for package robstride_driver
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Forthcoming
-----------
* Keep boot coordinate aliases in the recovery period until internal position and
  Run feedback agree; prevent a spurious extra turn after multi-turn reboot.
* Confirm startup mechanical zero through stopped readback while preserving the
  configured ROS joint offset.
* Poll stopped axes during reference readback to preserve multi-axis reference freshness.
* Synchronize position commands with stopped internal-angle readback before
  enabling; inhibit stale position targets after resets and mismatched first writes.
* Add upper-controlled homing services with restricted velocity/effort commands,
  explicit stationary mechanical-zero confirmation, and readiness polling.
* Add per-motor runtime joint-origin services without changing motor zero;
  reject calls while position control is claimed and translate command limits.
* Accumulate periodic position feedback in memory and support restoring or
  resetting its coordinate after detected motor resets and feedback gaps.
* Translate restored position targets to motor coordinates and reject stale
  position commands after resetting the reference.

0.2.0 (2026-09-06)
------------------
* Add CAN traffic metrics and human-readable motor and transport diagnostics.
* Report motor mode, temperature, faults, feedback age, and recovery attempts.
* Reduce transport contention during control updates and propagate persistent
  transmit-path failures.
* Add virtual CAN transport and fake-motor lifecycle integration tests.
* Centralize RS00-RS06 and EL05 protocol ranges in the motor profile registry.
* Contributors: Yamato.K

0.1.2 (2026-08-26)
------------------
* Apply ``gear_ratio`` when converting effort commands and feedback between
  ROS joint and motor coordinates.
* Add tests for unity and non-unity ratios with both joint directions.
* Contributors: Yamato.K

0.1.1 (2026-08-25)
------------------
* Synchronize the package version for the multi-package compatibility release.
* Contributors: Yamato.K

0.1.0 (2026-08-09)
------------------
* Add the RobStride private-CAN protocol, topic transport, motor lifecycle,
  feedback monitoring, and Run-mode recovery library.
* Clamp position, velocity, and effort commands to per-joint operational
  limits before CAN encoding.
* Contributors: Yamato.K
