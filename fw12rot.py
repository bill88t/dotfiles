#!/usr/bin/env python3
import os
import time
from collections import deque
import math

IIO_BASE = "/sys/bus/iio/devices"
SAMPLES = 128
PERIOD = 0.5
STABILITY = 3
THRESHOLD = 0.4


def find_iio_device(name, axis_files=None):
    """Find IIO device by name."""
    try:
        for dev in os.listdir(IIO_BASE):
            name_path = os.path.join(IIO_BASE, dev, "name")
            if not os.path.exists(name_path):
                continue
            with open(name_path) as f:
                dev_name = f.read().strip()
            if dev_name == name:
                if axis_files:
                    full_paths = {
                        axis: os.path.join(IIO_BASE, dev, f)
                        for axis, f in axis_files.items()
                    }
                    if all(os.path.exists(p) for p in full_paths.values()):
                        return full_paths
                else:
                    return os.path.join(IIO_BASE, dev, "in_angl_raw")
    except Exception as e:
        print(f"[WARN] IIO scan failed: {e}")
    return None


def get_scale_factor(dev_dir, axis="x"):
    """Get accelerometer scale factor"""
    try:
        scale_path = os.path.join(dev_dir, f"in_accel_{axis}_scale")
        if os.path.exists(scale_path):
            with open(scale_path) as f:
                return float(f.read().strip())
    except Exception:
        pass
    return 0.0098


def read_average(path_map, samples=SAMPLES, period=PERIOD, scale=1.0):
    interval = period / samples
    values = {k: [] for k in path_map}
    for _ in range(samples):
        try:
            for k, p in path_map.items():
                with open(p) as f:
                    values[k].append(float(f.read().strip()) * scale)
        except Exception:
            return None
        time.sleep(interval)
    return {k: sum(v) / len(v) for k, v in values.items()}


def normalize_accel(accel):
    """Normalize acceleration vector"""
    magnitude = math.sqrt(accel["x"] ** 2 + accel["y"] ** 2 + accel["z"] ** 2)
    if magnitude < 0.1:
        return None
    return {k: v / magnitude for k, v in accel.items()}


def get_tablet_mode(lid_angle_path, last_tablet_mode=False):
    """
    Determine tablet mode with hysteresis and validation.
    Returns (tablet_mode, lid_angle) or (None, None) if sensor is broken.
    """
    try:
        with open(lid_angle_path) as f:
            lid_angle = float(f.read().strip())
    except Exception:
        return None, None

    # Validate lid angle is in reasonable range (0-360)
    if lid_angle < 0 or lid_angle > 360:
        print(f"[WARN] Invalid lid angle: {lid_angle}° (outside 0-360 range)")
        return None, None

    # Hysteresis: require 200+ degrees for tablet mode, 180- degrees to exit
    if last_tablet_mode:
        tablet_mode = lid_angle > 180  # Exit if below 180
    else:
        tablet_mode = lid_angle > 200  # Enter only if above 200

    return tablet_mode, lid_angle


def classify_orientation(accel, tablet_mode):
    """Classify orientation based on accelerometer"""
    x, y, z = accel["x"], accel["y"], accel["z"]

    # In tablet mode, rotate 90° around Z-axis
    if tablet_mode:
        x, y = -y, x

    abs_vals = {"x": abs(x), "y": abs(y), "z": abs(z)}
    main_axis = max(abs_vals, key=abs_vals.get)
    main_val = abs_vals[main_axis]

    if main_val < THRESHOLD:
        return "unknown"

    if main_axis == "z":
        return "normal" if z > 0 else "upside-down"
    elif main_axis == "x":
        return "right-up" if x > 0 else "left-up"
    elif main_axis == "y":
        return "bottom-up" if y > 0 else "top-up"

    return "unknown"


def main():
    base_accel_axes = {
        "x": "in_accel_x_raw",
        "y": "in_accel_y_raw",
        "z": "in_accel_z_raw",
    }
    stable_queue = deque(maxlen=STABILITY)
    last_orientation = None
    last_tablet_mode = False
    scale_factor = 0.0098

    print("[INFO] Framework System Orientation Monitor starting...")

    device_found = False

    while True:
        if not device_found:
            base_accel = find_iio_device("cros-ec-accel", axis_files=base_accel_axes)
            lid_angle_path = find_iio_device("cros-ec-lid-angle")
            if not base_accel or not lid_angle_path:
                print("[WARN] Waiting for devices...")
                time.sleep(2)
                continue
            device_found = True
            dev_dir = os.path.dirname(base_accel["x"])
            scale_factor = get_scale_factor(dev_dir, "x")
            print(f"[INFO] Devices found. Scale factor: {scale_factor}")

        # Read lid angle with validation
        tablet_mode, lid_angle = get_tablet_mode(lid_angle_path, last_tablet_mode)
        if tablet_mode is None:
            print("[WARN] Invalid lid angle sensor reading, skipping cycle")
            time.sleep(1)
            continue

        last_tablet_mode = tablet_mode

        # Read accelerometer
        accel_raw = read_average(base_accel, scale=scale_factor)
        if accel_raw is None:
            print("[WARN] Failed to read accelerometer")
            time.sleep(1)
            continue

        accel = normalize_accel(accel_raw)
        if accel is None:
            print("[DEBUG] Accel magnitude too small")
            continue

        orient = classify_orientation(accel, tablet_mode)

        if orient != "unknown":
            stable_queue.append(orient)

            if len(stable_queue) == STABILITY and all(
                o == orient for o in stable_queue
            ):
                if orient != last_orientation:
                    print(f"[INFO] Orientation changed → {orient}")
                    last_orientation = orient

        print(
            f"[DEBUG] Lid: {lid_angle:6.1f}° | Tablet: {tablet_mode} | Accel: X={accel['x']:+.3f} Y={accel['y']:+.3f} Z={accel['z']:+.3f} | Orient: {orient}"
        )


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[INFO] Exiting.")
