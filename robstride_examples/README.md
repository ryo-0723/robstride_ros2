# robstride_examples

`robstride_examples` contains the ready-to-run integration files for
`robstride_ros2_control`:

- compatibility Xacro includes for the production-owned motor profiles;
- position, velocity, and effort controller configuration;
- a robot description for a single EL05 actuator;
- a launch file that starts `ros2_socketcan`, `ros2_control`, and the example
  controller.

After bringing up a 1 Mbit/s SocketCAN interface, launch the example with:

```bash
ros2 launch robstride_examples robstride_example.launch.py interface:=can0
```

The default launch uses motor CAN ID 1 and starts the position controller.
Commands are accepted on
`/robstride_position_controller/commands`. Alternative controller definitions
for velocity and effort are included in `config/controllers.yaml`.

The profiles supply protocol encoding ranges, but robot-specific operational
limits and control gains must still be selected for the actual mechanism. See
the [repository README](https://github.com/s2015-turtle/robstride_ros2#readme)
for command examples, profile arguments, multi-motor configuration, and safety
notes.

For a read-only EL05 encoder investigation with an already running USB-CAN
bridge, use:

```bash
ros2 run robstride_examples encoder_probe.py --ids 32 33 34 35 --duration 30 \
  > encoder-baseline.jsonl
```

By default, the probe sends only Type 17 reads for run mode, load-side counted position,
velocity, voltage, power-on range, zero offset, and initialization calibration.
It uses the bridge's `/to_can_bus` and `/from_can_bus` topics; it does not launch
the controller manager. Some firmware may reject newer parameters. The JSONL
contains raw frames, reply status, and host timestamps. A timeout or missing
reply is not evidence of a zero parameter value. To investigate specific indices,
add `--indices 0x7019 0x701D`; values with unknown types are retained as raw frames.
For internal table entries, use Type 9 instead:

```bash
ros2 run robstride_examples encoder_probe.py --read-type 9 --ids 33 34 \
  --indices 0x3014 0x3016 0x2006 --duration 30 > internal-encoder.jsonl
```

Type 9 replies carry a value type; the probe decodes supported types from that
field. On the tested firmware, `0x3014` is the internal rotation count and
`0x3016` is counted load-side position. Internal table indices change between
firmware releases. A readable count is not evidence of retention across power cycles.
The meaning of `0x2006` depends on the motor firmware.
See the
[EL05 encoder investigation](../doc/edulite05_encoder_check.ja.md) for retention
conditions and the hardware test procedure.

To inventory the union of candidate indices from the four inspected EL05
firmware releases (170 requests per motor), use:

```bash
ros2 run robstride_examples encoder_probe.py --ids 33 --all-el05 --once \
  --interval 0.1 --duration 30 > encoder-inventory.jsonl
```

The final record distinguishes a complete request pass from a complete response
pass and lists missing replies; `--once` exits with code 4 if replies are missing.
A rejected reply counts as an answered request, with its status retained.
This range covers the inspected tables, rather than all possible undocumented
indices. See the [extended rotation and power-cycle measurements](../doc/edulite05_multiturn_measurements.ja.md)
for the measured values and firmware-specific names.
