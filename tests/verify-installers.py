#!/usr/bin/env python3
"""Offline installation contracts, using disposable paths and mocked downloads."""
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from lib.desktop import desktop_plan, install_ghostty, install_orca
from lib.runtime import Host, download_verified

spec = importlib.util.spec_from_file_location("installer", ROOT / "scripts/unix/install.py")
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallerContracts(unittest.TestCase):
    def test_existing_profiles_and_opt_in(self):
        for name in ["fedora-common", "ubuntu-desktop", "ubuntu-full"]:
            profile = installer.validate_profile(ROOT / f"tests/profiles/{name}.json")
            self.assertTrue(installer.matches_profile(profile, profile))
        baseline = installer.validate_profile(ROOT / "tests/profiles/ubuntu-desktop.json")
        current = json.loads(json.dumps(baseline))
        current["features"].update(managed_ai=False, desktop=False)
        self.assertTrue(installer.matches_profile(current, baseline))
        full = installer.validate_profile(ROOT / "tests/profiles/ubuntu-full.json")
        self.assertFalse(installer.matches_profile(current, full))

    def test_preserve_fedora_and_reject_unknown_flags(self):
        profile = installer.validate_profile(ROOT / "tests/profiles/fedora-common.json")
        for addition in [{"managed_ai": True}, {"desktop": True}, {"desktop": 1}, {"unknown": False}]:
            with tempfile.TemporaryDirectory() as temporary:
                profile["features"] = {"ai": False, "personal_fedora": False, "conda": False,
                                       "bitwarden_agent": False, "delta": False, "editor_web": False, **addition}
                path = Path(temporary) / "profile.json"
                path.write_text(json.dumps(profile))
                with self.assertRaises(ValueError):
                    installer.validate_profile(path)

    def test_native_platform_plans(self):
        for host in [Host("linux", "x64", "ubuntu"), Host("linux", "arm64", "fedora"),
                     Host("macos", "arm64"), Host("windows", "x64")]:
            self.assertEqual(set(desktop_plan(host)), {"ghostty", "orca"})
        self.assertIn("unsupported", desktop_plan(Host("windows", "x64"))["ghostty"])
        with self.assertRaises(ValueError):
            desktop_plan(Host("linux", "x64", "unsupported"))

    def test_download_verification_and_existing_file(self):
        payload = b"verified publisher package"
        digest = hashlib.sha256(payload).hexdigest()
        with tempfile.TemporaryDirectory(prefix="installer paths with spaces ") as temporary:
            path = Path(temporary) / "package with spaces.deb"
            with patch("urllib.request.urlopen", return_value=io.BytesIO(payload)):
                download_verified("https://publisher.invalid/package", path, digest)
            self.assertEqual(path.read_bytes(), payload)
            with patch("urllib.request.urlopen", return_value=io.BytesIO(b"replacement")):
                with self.assertRaises(FileExistsError):
                    download_verified("https://publisher.invalid/package", path, digest)
            self.assertEqual(path.read_bytes(), payload)
            path.unlink()
            with patch("urllib.request.urlopen", return_value=io.BytesIO(payload)):
                with self.assertRaisesRegex(ValueError, "Checksum mismatch"):
                    download_verified("https://publisher.invalid/package", path, "0" * 64)
            self.assertFalse(path.exists())

    def test_existing_apps_do_not_download_or_upgrade(self):
        host = Host("linux", "x64", "fedora")
        with patch("lib.desktop.package_present", return_value=True), \
             patch("lib.desktop.download_verified") as download, patch("lib.desktop.run") as run:
            install_ghostty(host)
            install_orca(host)
            download.assert_not_called()
            run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
