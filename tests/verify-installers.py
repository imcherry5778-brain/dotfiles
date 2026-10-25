#!/usr/bin/env python3
"""Offline installation contracts, using disposable paths and mocked downloads."""
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import sys
import subprocess
import tempfile
import unittest
import tomllib
import urllib.error
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from lib.desktop import desktop_plan, install_ghostty, install_orca, install_opensuse_packages
from lib.runtime import Host, download_verified
from lib.backup import backup_targets, preserve_installer_loaders
from lib.packages import prepare_packages
from lib.tools import reconcile_mise_tools
from lib.macos import install_cask, install_native_cli, inspect_ghostty_configuration
from lib.appimage import install_orca_appimage, desktop_quote

spec = importlib.util.spec_from_file_location("installer", ROOT / "scripts/unix/install.py")
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallerContracts(unittest.TestCase):
    def test_ubuntu_complete_repeat_needs_no_elevated_metadata_refresh(self):
        for status, refresh in [('installed', False), ('unpacked', True), ('', True)]:
            with self.subTest(status=status), \
                 patch('lib.packages.subprocess.run', return_value=subprocess.CompletedProcess([], 0, stdout=status)), \
                 patch('lib.packages.run') as execute, \
                 patch('lib.packages.administrative_command', return_value=['sudo', 'apt-get', 'update']) as elevate:
                prepare_packages(Host('linux', 'x64', 'ubuntu'), desktop=True)
                self.assertEqual(elevate.called, refresh)
                self.assertEqual(sum(call.args[0] == ['sudo', 'apt-get', 'update'] for call in execute.call_args_list), int(refresh))
                self.assertEqual(execute.call_args_list[-1].args[0][-3:], ['bootstrap', 'packages', 'apply'])

    @unittest.skipIf(os.name == 'nt', 'Unix initial config permissions; Windows records ACLs.')
    def test_initial_config_backup_is_private_and_records_original_mode(self):
        with tempfile.TemporaryDirectory(prefix='initial config with spaces ') as temporary:
            home = Path(temporary); config = home / 'chezmoi.toml'
            config.write_text('[data]\nretained = true\n'); config.chmod(0o640)
            environment = dict(os.environ, HOME=str(home))
            subprocess.run(['sh', ROOT / 'scripts/unix/backup-init.sh', config],
                           check=True, env=environment)
            backups = list((home / '.local/state/dotfiles/init-backups').glob('init-*'))
            self.assertEqual(len(backups), 1)
            backup = backups[0]
            self.assertEqual((backup / 'chezmoi.toml').read_bytes(), config.read_bytes())
            self.assertEqual((backup / 'chezmoi.toml').stat().st_mode & 0o777, 0o600)
            self.assertEqual((backup / 'mode.txt').read_text().strip(), '640')
            self.assertEqual(backup.stat().st_mode & 0o777, 0o700)
            self.assertEqual(config.stat().st_mode & 0o777, 0o640)

    def test_missing_binary_repairs_only_selected_version(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary); config = home / '.config/mise'; config.mkdir(parents=True)
            (config / 'miserc.toml').write_text('env = []\n')
            (config / 'config.toml').write_text('[tools]\nfd = "10.4.2"\n')
            def command(arguments, **options):
                if arguments[1] == 'ls':
                    return json.dumps({'fd': [{'version': '10.4.2', 'installed': True}, {'version':'10.3.0','installed':True}]})
                if arguments[1] == 'which':
                    return str(home / '.local/share/mise/installs/fd/10.4.2/missing-fd')
                return ''
            with patch('lib.tools.Path.home', return_value=home), patch('lib.tools.run', side_effect=command) as execute:
                reconcile_mise_tools('mise')
            commands = [call.args[0] for call in execute.call_args_list]
            self.assertIn(['mise','uninstall','--yes','fd@10.4.2'], commands)
            self.assertNotIn(['mise','uninstall','--yes','fd@10.3.0'], commands)
            self.assertEqual(commands[-1], ['mise','install','--yes'])

    @unittest.skipIf(os.name == 'nt', 'Windows uses native ACL loader protection.')
    def test_vendor_failure_restores_managed_loader_but_keeps_vendor_data(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary); loader = home / '.zshrc'
            loader.write_text('existing user hooks\n'); loader.chmod(0o600)
            with self.assertRaisesRegex(RuntimeError, 'publisher failure'):
                with preserve_installer_loaders(home, {'.zshrc'}):
                    loader.write_text('vendor changed loader\n'); loader.chmod(0o644)
                    (home / 'vendor-auth-fixture').write_text('retained fixture')
                    raise RuntimeError('publisher failure')
            self.assertEqual(loader.read_text(), 'existing user hooks\n')
            self.assertEqual(loader.stat().st_mode & 0o777, 0o600)
            self.assertEqual((home / 'vendor-auth-fixture').read_text(), 'retained fixture')

    def test_ai_provider_conflicts_preserve_native_and_accept_mise_shims(self):
        home = Path(tempfile.gettempdir()).resolve() / 'reviewed-home'
        with patch.object(installer.shutil, 'which', return_value='/usr/bin/native-ai'):
            with self.assertRaisesRegex(ValueError, 'no automatic migration'):
                installer.assert_ai_providers(home)
        with patch.object(installer.shutil, 'which', return_value=str(home / '.local/share/mise/shims/claude')):
            installer.assert_ai_providers(home)

    def test_reader_rejects_recursive_apply(self):
        reader = installer.ReviewReader({'chezmoi':'chezmoi','config':'config'}, 'separate-state')
        for operation in ['apply', 'init', 'update', 'state']:
            with self.assertRaisesRegex(ValueError, 'read-only'):
                reader.query(operation)

    def test_full_profiles_reject_numeric_booleans(self):
        for name in ['fedora-full', 'macos-full']:
            with tempfile.TemporaryDirectory() as scratch:
                profile = json.loads((ROOT / f'tests/profiles/{name}.json').read_text())
                profile['features']['delta'] = 0
                path = Path(scratch) / 'profile.json'; path.write_text(json.dumps(profile))
                with self.assertRaisesRegex(ValueError, 'Booleans'):
                    installer.validate_profile(path)

    def test_existing_personal_fedora_is_supported_without_normalizing_owners(self):
        expected = installer.validate_profile(ROOT / 'tests/profiles/fedora-personal.json')
        old = json.loads(json.dumps(expected))
        old['features'].pop('managed_ai'); old['features'].pop('desktop')
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'personal.json'; path.write_text(json.dumps(old))
            self.assertEqual(installer.validate_profile(path), old)
            self.assertTrue(installer.matches_profile(old, expected))
            old['deployment']['externals'] = True; path.write_text(json.dumps(old))
            with self.assertRaisesRegex(ValueError, 'externals=false'):
                installer.validate_profile(path)

    def test_personal_aliases_never_reinstall_healthy_owners(self):
        from lib.tools import COMMANDS
        for tool, command in {'ansible-core':'ansible', 'aws-cli':'aws', 'azure':'az',
                              'bitwarden':'bw', 'mysql-client':'mysql', 'rust':'rustc'}.items():
            self.assertEqual(COMMANDS[tool], command)
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary); config = home / '.config/mise'; config.mkdir(parents=True)
            (config / 'miserc.toml').write_text('env = []\n')
            (config / 'config.toml').write_text('[tools]\n"ansible-core" = "2.16.19"\n')
            executable = home / '.local/share/mise/installs/ansible-core/2.16.19/bin/ansible'
            executable.parent.mkdir(parents=True); executable.touch()
            def command(arguments, **options):
                if arguments[1] == 'ls':
                    return json.dumps({'ansible-core':[{'version':'2.16.19','installed':True}]})
                if arguments[1] == 'which':
                    self.assertEqual(arguments[-1], 'ansible')
                    return str(executable)
                return ''
            with patch('lib.tools.Path.home', return_value=home), patch('lib.tools.run', side_effect=command) as execute:
                reconcile_mise_tools('mise')
            self.assertFalse(any('uninstall' in call.args[0] for call in execute.call_args_list))

    def test_version_probes_isolate_state_and_never_contact_kubernetes(self):
        from lib.tools import version_output
        for command, variable in {'ansible':'ANSIBLE_LOCAL_TEMP', 'az':'AZURE_CONFIG_DIR',
                                   'bw':'BITWARDENCLI_APPDATA_DIR', 'kubectl':'KUBECONFIG'}.items():
            with patch('lib.tools.run', return_value='version') as execute:
                self.assertEqual(version_output('mise',command), 'version')
                call = execute.call_args
                self.assertTrue(Path(call.kwargs['env'][variable]).is_absolute())
                if command == 'az':
                    self.assertEqual(call.kwargs['env']['AZURE_CORE_COLLECT_TELEMETRY'], 'false')
                if command == 'kubectl':
                    self.assertIn('--client=true', call.args[0])
        with patch('lib.tools.run', return_value='version') as execute:
            self.assertEqual(version_output('mise', 'argocd'), 'version')
            self.assertEqual(execute.call_args.args[0],
                             ['mise', 'exec', '--', 'argocd', 'version', '--client', '--short'])

    def test_fedora_full_is_portable_and_not_personal(self):
        profile = installer.validate_profile(ROOT / 'tests/profiles/fedora-full.json')
        self.assertTrue(profile['features']['managed_ai'])
        self.assertTrue(profile['features']['desktop'])
        self.assertFalse(profile['features']['personal_fedora'])

    def test_installer_python_is_not_a_windows_or_plan_dependency(self):
        root = tomllib.loads((ROOT / 'mise.toml').read_text())
        runtime = tomllib.loads((ROOT / 'scripts/unix/mise.toml').read_text())
        self.assertNotIn('tools', root)
        self.assertFalse(root['settings']['auto_install'])
        self.assertEqual(runtime['tools'], {'python': '3.12.15'})

    def test_mac_checks_both_ghostty_locations(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            xdg = home / '.config/ghostty/config'; xdg.parent.mkdir(parents=True)
            xdg.write_text('font-family = D2Coding\n')
            native = home / 'Library/Application Support/com.mitchellh.ghostty/config.ghostty'
            native.parent.mkdir(parents=True); native.write_text('')
            with patch('lib.macos.Path.home', return_value=home):
                inspect_ghostty_configuration()
                native.write_text('font-family = Other Font\n')
                with self.assertRaisesRegex(ValueError, 'font override'):
                    inspect_ghostty_configuration()

    def test_existing_bootstrap_versions_accept_publisher_v_prefix(self):
        with patch.object(installer.shutil, 'which', return_value='/existing/chezmoi'), \
             patch.object(installer, 'run', return_value='chezmoi version v2.73.0, built at upstream'):
            self.assertEqual(installer.pinned_binary('chezmoi', ROOT / 'tests/chezmoi-release.json', 'twpayne/chezmoi'), Path('/existing/chezmoi'))
        with patch.object(installer.shutil, 'which', return_value='/existing/chezmoi'), \
             patch.object(installer, 'run', return_value='chezmoi version v2.72.0'):
            with self.assertRaisesRegex(ValueError, 'current provider'):
                installer.pinned_binary('chezmoi', ROOT / 'tests/chezmoi-release.json', 'twpayne/chezmoi')

    def test_mac_existing_provider_is_never_replaced(self):
        with patch('lib.macos.shutil.which', return_value='/existing/claude'), patch('lib.macos.run') as execute:
            install_cask('claude-code', command='claude')
            execute.assert_not_called()
        with patch('lib.macos.shutil.which', side_effect=lambda command: '/existing/q' if command == 'q' else None), \
             patch('lib.macos.install_cask'), patch('lib.macos.download_verified') as download:
            with self.assertRaisesRegex(ValueError, 'provider review'):
                install_native_cli()
            download.assert_not_called()

    def test_failed_download_leaves_no_partial_destination(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'installer.sh'
            with patch('urllib.request.urlopen', side_effect=urllib.error.URLError('offline')):
                with self.assertRaises(urllib.error.URLError):
                    download_verified('https://publisher.invalid/install.sh', target, 'a' * 64)
            self.assertFalse(target.exists())

    def test_mac_profile_is_explicit_and_native(self):
        profile = installer.validate_profile(ROOT / 'tests/profiles/macos-full.json')
        self.assertTrue(profile['features']['macos_native'])
        self.assertFalse(profile['features']['managed_ai'])
        self.assertTrue(installer.matches_profile(profile, profile))

    @unittest.skipIf(os.name == "nt", "Unix mode/symlink backups; Windows uses its native ACL implementation.")
    def test_backup_preserves_file_modes_symlinks_and_absence(self):
        with tempfile.TemporaryDirectory(prefix='backup with spaces ') as temporary:
            home = Path(temporary)
            (home / 'existing').write_text('private retained')
            (home / 'existing').chmod(0o600)
            (home / 'link').symlink_to('existing')
            (home / 'retained-dir').mkdir(); (home / 'retained-dir').chmod(0o755)
            backup = backup_targets(home, ['existing', 'link', 'absent'], 'reviewed diff', 'macos', directories=['retained-dir','new-dir'])
            self.assertEqual((backup / 'files/existing').read_text(), 'private retained')
            self.assertEqual((backup / 'files/existing').stat().st_mode & 0o777, 0o600)
            self.assertEqual(os.readlink(backup / 'files/link'), 'existing')
            self.assertEqual(backup.stat().st_mode & 0o777, 0o700)
            entries = json.loads((backup / 'manifest.json').read_text())
            self.assertFalse(next(e for e in entries if e['path'] == 'absent')['exists'])
            self.assertEqual(next(e for e in entries if e['path'] == 'retained-dir')['mode'], 0o755)
            with self.assertRaises(ValueError):
                backup_targets(home, ['../outside'], '', 'macos')

    def test_apt_inventory_is_standalone_and_no_upgrade(self):
        with patch('lib.packages.subprocess.run', return_value=subprocess.CompletedProcess([], 1, stdout='')), \
             patch('lib.packages.administrative_command', side_effect=lambda args: args), patch('lib.packages.run') as execute:
            prepare_packages(Host('linux', 'x64', 'ubuntu'), desktop=True)
            commands = [call.args[0] for call in execute.call_args_list]
            self.assertTrue(any(command[-3:] == ['bootstrap', 'packages', 'apply'] for command in commands))
            self.assertFalse(any('upgrade' in command or 'prune' in command for command in commands))

    def test_existing_profiles_and_opt_in(self):
        for name in ["fedora-common", "ubuntu-desktop", "ubuntu-full", "arch-full", "opensuse-tumbleweed-full"]:
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
        for host in [Host("linux", "x64", "ubuntu"), Host("linux", "arm64", "fedora"), Host("linux", "x64", "arch"), Host("linux", "x64", "opensuse-tumbleweed"),
                     Host("macos", "arm64"), Host("windows", "x64")]:
            self.assertEqual(set(desktop_plan(host)), {"ghostty", "orca"})
        self.assertIn("unsupported", desktop_plan(Host("windows", "x64"))["ghostty"])
        with self.assertRaises(ValueError):
            desktop_plan(Host("linux", "x64", "unsupported"))

    def test_opensuse_solver_preserves_installed_packages(self):
        for action in ["to-remove", "to-upgrade", "to-downgrade", "to-change-vendor"]:
            plan = f'<stream><install-summary><{action}><solvable name="existing"/></{action}></install-summary></stream>'
            with patch("lib.desktop.administrative_command", side_effect=lambda args: args), \
                 patch("lib.desktop.run", return_value=plan) as execute:
                with self.assertRaisesRegex(ValueError, "changes installed packages"):
                    install_opensuse_packages(["ghostty"])
                self.assertEqual(execute.call_count, 1)
        plan = '<stream><install-summary><to-install><solvable name="ghostty"/></to-install></install-summary></stream>'
        with patch("lib.desktop.administrative_command", side_effect=lambda args: args), \
             patch("lib.desktop.run", return_value=plan) as execute:
            install_opensuse_packages(["ghostty"])
            self.assertEqual(execute.call_count, 2)
            command = execute.call_args.args[0]
            self.assertIn("--no-force-resolution", command)
            self.assertIn("--no-allow-vendor-change", command)
            self.assertNotIn("--dry-run", command)

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
