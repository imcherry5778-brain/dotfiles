#!/usr/bin/env python3
"""Offline installation contracts, using disposable paths and mocked downloads."""
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from lib.desktop import desktop_plan, install_ghostty, install_orca
from lib.runtime import Host, download_verified
from lib.appimage import install_orca_appimage, desktop_quote

spec = importlib.util.spec_from_file_location("installer", ROOT / "scripts/unix/install.py")
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallerContracts(unittest.TestCase):
    def test_existing_profiles_and_opt_in(self):
        for name in ["fedora-common", "ubuntu-desktop", "ubuntu-full", "arch-full"]:
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
        for host in [Host("linux", "x64", "ubuntu"), Host("linux", "arm64", "fedora"), Host("linux", "x64", "arch"),
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

    @unittest.skipIf(os.name == "nt", "AppImage installation is Linux-only; platform plans remain tested on Windows.")
    def test_appimage_layout_and_existing_paths(self):
        with tempfile.TemporaryDirectory(prefix="desktop user with spaces ") as temporary:
            home = Path(temporary)
            def extracted(arguments, **options):
                app = Path(options["cwd"]) / "squashfs-root"
                for name in ["AppRun", "orca-ide", "resources/bin/orca-ide",
                             "resources/app.asar.unpacked/out/cli/index.js",
                             "usr/share/icons/hicolor/256x256/apps/orca-ide.png"]:
                    path = app / name
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text("publisher fixture")
                (app / "orca-ide.desktop").write_text("X-AppImage-Version=1.4.224\n")
            def downloaded(url, destination, checksum):
                destination.write_bytes(b"verified fixture")
            asset = {"name": "orca.AppImage", "url": "https://publisher.invalid/orca", "sha256": "a" * 64}
            with patch("lib.appimage.Path.home", return_value=home), patch("lib.appimage.os.geteuid", return_value=1000, create=True), \
                 patch("lib.appimage.download_verified", side_effect=downloaded), patch("lib.appimage.run", side_effect=extracted), \
                 patch("lib.appimage.shutil.which", return_value=None):
                install_orca_appimage(asset, "1.4.224")
                cli = home / ".local/bin/orca-ide"
                self.assertTrue(cli.is_symlink() and cli.is_file())
                launcher = home / ".local/share/applications/orca-ide.desktop"
                self.assertIn('Exec=' + desktop_quote(home / '.local/share/orca/appimage/AppRun'), launcher.read_text())
                before = launcher.read_bytes()
                with self.assertRaisesRegex(ValueError, "Existing Orca path"):
                    install_orca_appimage(asset, "1.4.224")
                self.assertEqual(launcher.read_bytes(), before)
        self.assertEqual(desktop_quote('/a b/100%/AppRun'), '"/a b/100%%/AppRun"')

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
