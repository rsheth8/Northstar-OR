#!/usr/bin/env python3
"""Select an iPad baseline for the active SDK, rather than the newest installed OS."""
import json
import re
import sys

MINIMUM_IOS = (17, 0, 0)


def version(text, separator="."):
    parts = tuple(int(part) for part in text.split(separator))
    return parts + (0,) * max(0, 3 - len(parts))


def select_device(catalog, sdk):
    if not re.fullmatch(r"[0-9]+(?:\.[0-9]+){0,2}", sdk):
        raise ValueError(f"Invalid simulator SDK version: {sdk}")
    maximum = version(sdk)
    runtimes = []
    for identifier, devices in catalog["devices"].items():
        match = re.fullmatch(r"com\.apple\.CoreSimulator\.SimRuntime\.iOS-([0-9]+(?:-[0-9]+)*)", identifier)
        if not match:
            continue
        os_version = version(match.group(1), "-")
        if not MINIMUM_IOS <= os_version <= maximum:
            continue
        ipads = [device for device in devices if device.get("isAvailable")
                 and device.get("name", "").startswith("iPad") and device.get("udid")]
        if ipads:
            # Keep the landscape evidence baseline large where one is installed.
            ipads.sort(key=lambda device: (not any(size in device["name"] for size in ("13-inch", "12.9-inch")), device["name"], device["udid"]))
            runtimes.append((os_version, identifier, ipads[0]))
    if not runtimes:
        raise ValueError(f"No available iPad simulator between iOS 17.0 and SDK {sdk}. Install a matching iOS runtime in Xcode Settings > Components, or explicitly set SIMULATOR_ID for a separate runtime check.")
    _, identifier, device = max(runtimes, key=lambda item: item[0])
    return identifier, device


def main():
    if len(sys.argv) != 2:
        sys.exit("Usage: select-ipad-simulator.py SDK_VERSION < simctl-devices.json")
    try:
        runtime, device = select_device(json.load(sys.stdin), sys.argv[1])
    except (ValueError, KeyError, TypeError) as error:
        sys.exit(str(error))
    print(f"Selected {device['name']} on {runtime} for simulator SDK {sys.argv[1]}", file=sys.stderr)
    print(device["udid"])


if __name__ == "__main__":
    main()
