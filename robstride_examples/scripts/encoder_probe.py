#!/usr/bin/env python3
"""Read-only EL05 parameter probe through a can_msgs USB-CAN bridge.

Only Type 17 or Type 9 reads are sent. No enable, stop, zero, save or motion commands.
Raw frames and monotonic timestamps are retained as JSONL for power-cycle tests.
"""

import argparse
import json
import math
import struct
import time


PARAMETERS = {
    0x7005: ("run_mode", "B"),
    0x7019: ("mechPos", "f"),
    0x701B: ("mechVel", "f"),
    0x701C: ("VBUS", "f"),
    0x701D: ("rotation_low16", "h"),
    0x7029: ("zero_sta", "B"),
    0x702B: ("add_offset", "f"),
    0x702D: ("iq_test", "B"),
}

INTERNAL_PARAMETERS = {
    0x2005: "MechOffset",
    0x2006: "status4_firmware_dependent",
    0x2021: "zero_sta",
    0x2023: "add_offset",
    0x3014: "rotation",
    0x3015: "modPos",
    0x3016: "mechPos",
}

# Type 9 includes the internal table's type code. Only values fitting the
# four-byte value field are decoded; other types remain available as raw data.
INTERNAL_TYPES = {0: "B", 1: "b", 2: "H", 3: "h", 4: "I", 5: "i", 6: "f"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ids", type=int, nargs="+", required=True)
    parser.add_argument("--host-id", type=int, default=253)
    parser.add_argument("--read-type", type=int, choices=(17, 9), default=17,
                        help="17: private parameter reads; 9: internal table reads")
    parser.add_argument("--all-el05", action="store_true",
                        help="Read all candidate codes from four released EL05 tables via Types 9/17")
    parser.add_argument("--once", action="store_true", help="Stop after one request pass")
    parser.add_argument("--indices", type=lambda value: int(value, 0), nargs="+",
                        help="Read specific indices (e.g. 0x701D); unknown values stay raw")
    parser.add_argument("--duration", type=float, default=15.0)
    parser.add_argument("--interval", type=float, default=0.05)
    parser.add_argument("--tx-topic", default="/to_can_bus")
    parser.add_argument("--rx-topic", default="/from_can_bus")
    args = parser.parse_args()
    if args.all_el05 and args.indices:
        parser.error("--all-el05 and --indices cannot be combined")
    indices = args.indices or list(PARAMETERS if args.read_type == 17 else INTERNAL_PARAMETERS)
    if args.all_el05:
        plan = [(9, index) for index in (*range(0x2000, 0x2028), *range(0x3000, 0x3053))]
        plan += [(17, index) for index in range(0x7000, 0x702F)]
    else:
        plan = [(args.read_type, index) for index in indices]
    if not all(0 <= value <= 255 for value in [*args.ids, args.host_id]):
        parser.error("CAN IDs must be in 0..255")
    if args.indices and not all(0 <= value <= 65535 for value in args.indices):
        parser.error("parameter indices must be in 0..65535")
    if not (math.isfinite(args.duration) and args.duration > 0 and
            math.isfinite(args.interval) and args.interval >= 0.01):
        parser.error("duration must be positive; interval must be >= 0.01 s")

    import rclpy
    from can_msgs.msg import Frame
    from rclpy.qos import QoSProfile, ReliabilityPolicy

    def emit(**record):
        print(json.dumps({"monotonic_s": time.monotonic(),
                          "unix_s": time.time(), **record}, allow_nan=False), flush=True)

    rclpy.init()
    node = rclpy.create_node("el05_encoder_probe")
    qos = QoSProfile(depth=100, reliability=ReliabilityPolicy.RELIABLE)
    publisher = node.create_publisher(Frame, args.tx_topic, qos)
    received = 0
    answered = set()

    def receive(frame):
        nonlocal received
        if frame.is_error or frame.is_rtr or not frame.is_extended or frame.dlc != 8:
            return
        kind = (frame.id >> 24) & 31
        motor_id = (frame.id >> 8) & 255
        if motor_id not in args.ids or (frame.id & 255) != args.host_id:
            return
        record = {"event": "rx", "id": frame.id, "type": kind,
                  "motor_id": motor_id, "data": bytes(frame.data).hex()}
        if kind == 17:
            index = int.from_bytes(bytes(frame.data[:2]), "little")
            status = (frame.id >> 16) & 255
            record.update(index=hex(index), status=status)
            if status == 0 and index in PARAMETERS:
                name, fmt = PARAMETERS[index]
                value = struct.unpack_from("<" + fmt, bytes(frame.data), 4)[0]
                record.update(parameter=name, value=value if math.isfinite(value) else None)
        elif kind == 9:
            index, type_code = struct.unpack_from("<HH", bytes(frame.data))
            status = (frame.id >> 16) & 255
            record.update(index=hex(index), value_type_code=type_code, status=status)
            # Subtypes in the ID can carry parameter descriptions instead of values.
            if status == 0 and type_code in INTERNAL_TYPES:
                value = struct.unpack_from("<" + INTERNAL_TYPES[type_code],
                                           bytes(frame.data), 4)[0]
                record.update(parameter=INTERNAL_PARAMETERS.get(index, f"internal_{index:#06x}"),
                              value=value if math.isfinite(value) else None)
        elif kind == 2:
            # Keep raw data: firmware replies can also use Type 2.
            record.update(mode=(frame.id >> 22) & 3, faults=(frame.id >> 16) & 63)
        if kind in (9, 17):
            answered.add((motor_id, kind, int(record["index"], 16)))
        emit(**record)
        received += 1

    subscription = node.create_subscription(Frame, args.rx_topic, receive, qos)
    emit(event="start", ids=args.ids, host_id=args.host_id, duration=args.duration,
         read_type=args.read_type, indices=indices, all_el05=args.all_el05,
         request_plan=plan, once=args.once)
    try:
        discovery_deadline = time.monotonic() + 5.0
        while publisher.get_subscription_count() == 0 and time.monotonic() < discovery_deadline:
            rclpy.spin_once(node, timeout_sec=0.05)
        if publisher.get_subscription_count() == 0:
            emit(event="error", message="No bridge subscriber on TX topic")
            return 2
        requests = [(motor_id, kind, index) for motor_id in args.ids for kind, index in plan]
        deadline = time.monotonic() + args.duration
        sequence = 0
        next_send = time.monotonic()
        while rclpy.ok() and time.monotonic() < deadline:
            if args.once and sequence >= len(requests):
                if time.monotonic() >= next_send + 0.2:
                    break
                rclpy.spin_once(node, timeout_sec=0.005)
                continue
            if time.monotonic() >= next_send:
                motor_id, kind, index = requests[sequence % len(requests)]
                frame = Frame()
                frame.id = (kind << 24) | (args.host_id << 8) | motor_id
                frame.is_extended = True
                frame.dlc = 8
                frame.data = list(struct.pack("<H", index) + bytes(6))
                publisher.publish(frame)
                emit(event="tx", id=frame.id, read_type=kind, motor_id=motor_id, index=hex(index))
                sequence += 1
                next_send = time.monotonic() + args.interval
            rclpy.spin_once(node, timeout_sec=0.005)
        missing = [request for request in requests if request not in answered]
        emit(event="end", received=received, sent=sequence,
             complete_request_pass=sequence >= len(requests),
             complete_response_pass=not missing, missing_requests=missing)
        if args.once and missing:
            return 4
        return 0 if received else 3
    except KeyboardInterrupt:
        emit(event="interrupted", received=received)
        return 130
    finally:
        node.destroy_subscription(subscription)
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    raise SystemExit(main())
