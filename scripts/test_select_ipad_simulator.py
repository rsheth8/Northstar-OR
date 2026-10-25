import json
from pathlib import Path
import subprocess
import sys
import unittest

SCRIPT = Path(__file__).with_name("select-ipad-simulator.py")


def device(name, udid, available=True):
    return {"name": name, "udid": udid, "isAvailable": available}


class SimulatorSelectionTests(unittest.TestCase):
    def run_selector(self, sdk, devices):
        return subprocess.run([sys.executable, str(SCRIPT), sdk], input=json.dumps({"devices": devices}), text=True, capture_output=True)

    def test_newer_installed_runtime_does_not_override_pinned_sdk(self):
        result = self.run_selector("18.5", {
            "com.apple.CoreSimulator.SimRuntime.iOS-26-2": [device("iPad Pro 13-inch (M5)", "newer")],
            "com.apple.CoreSimulator.SimRuntime.iOS-18-5": [device("iPad Pro 11-inch (M4)", "small"), device("iPad Pro 13-inch (M4)", "baseline")],
        })
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "baseline")
        self.assertIn("SDK 18.5", result.stderr)
        self.assertIn("iOS-18-5", result.stderr)

    def test_falls_back_to_an_available_ipad_within_sdk_and_app_bounds(self):
        result = self.run_selector("27.1", {
            "com.apple.CoreSimulator.SimRuntime.iOS-27-1": [device("iPhone Duo", "phone")],
            "com.apple.CoreSimulator.SimRuntime.iOS-27-0": [device("iPad Pro 13-inch (M5)", "unavailable", False), device("iPad Air", "available")],
            "com.apple.CoreSimulator.SimRuntime.iOS-18-5": [device("iPad Pro", "older")],
        })
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "available")

    def test_missing_baseline_fails_with_actionable_message(self):
        result = self.run_selector("18.5", {
            "com.apple.CoreSimulator.SimRuntime.iOS-26-2": [device("iPad Pro", "too-new")],
            "com.apple.CoreSimulator.SimRuntime.iOS-16-4": [device("iPad Pro", "below-app-minimum")],
            "com.apple.CoreSimulator.SimRuntime.tvOS-18-5": [device("iPad misleading", "wrong-platform")],
        })
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("between iOS 17.0 and SDK 18.5", result.stderr)
        self.assertIn("Install a matching iOS runtime", result.stderr)

    def test_patch_version_is_compared_numerically(self):
        result = self.run_selector("18.5", {
            "com.apple.CoreSimulator.SimRuntime.iOS-18-5-0": [device("iPad Pro", "exact")],
            "com.apple.CoreSimulator.SimRuntime.iOS-18-5-1": [device("iPad Pro", "newer-patch")],
        })
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "exact")

    def test_invalid_sdk_fails_before_selecting_a_device(self):
        result = self.run_selector("unknown", {})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Invalid simulator SDK version", result.stderr)


if __name__ == "__main__":
    unittest.main()
