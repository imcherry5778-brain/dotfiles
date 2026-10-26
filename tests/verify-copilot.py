#!/usr/bin/env python3
"""Offline CLI bootstrap contracts; no native Windows/Mac installation claims."""
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from lib import copilot
from lib.runtime import Host


class CopilotContracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='copilot home with spaces ')
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.target = self.home / '.local/bin/copilot'
        self.state = self.home / '.copilot'; self.state.mkdir()
        (self.state / 'config.json').write_text('private-fixture-preserved')
        self.addCleanup(patch.stopall)
        patch('lib.copilot.Path.home', return_value=self.home).start()
        self.which = patch('lib.copilot.shutil.which', return_value=None).start()
        self.run = patch('lib.copilot.run', return_value='GitHub Copilot CLI 1.0.103.\n').start()
        self.body = self.archive()
        self.response = patch('urllib.request.urlopen', side_effect=lambda *a, **k: io.BytesIO(self.body)).start()
        self.release = patch.dict(copilot.RELEASE, {'version': '1.0.103', 'linux': {
            arch: hashlib.sha256(self.body).hexdigest() for arch in ('x64', 'arm64')}}).start()

    def archive(self, name='copilot', kind=tarfile.REGTYPE, payload=b'\x7fELFfixture'):
        data = io.BytesIO()
        with tarfile.open(fileobj=data, mode='w:gz') as archive:
            item = tarfile.TarInfo(name); item.type = kind; item.size = len(payload)
            item.linkname = '/outside'
            archive.addfile(item, io.BytesIO(payload))
        return data.getvalue()

    def test_linux_distributions_and_architectures_share_verified_standalone(self):
        for distro, arch in [('fedora','x64'), ('ubuntu','arm64'), ('arch','x64'), ('opensuse-tumbleweed','x64')]:
            with self.subTest(distro=distro):
                result = copilot.install_copilot(Host('linux', arch, distro))
                self.assertEqual(result['provider'], 'publisher-standalone')
                self.assertEqual(self.target.read_bytes(), b'\x7fELFfixture')
                self.assertEqual(self.target.stat().st_mode & 0o777, 0o755)
                self.assertTrue(self.response.call_args.args[0].full_url.endswith(f'/copilot-linux-{arch}.tar.gz'))
                self.assertEqual((self.state/'config.json').read_text(), 'private-fixture-preserved')
                self.assertFalse(list(self.target.parent.glob('.copilot-stage-*')))
                self.target.unlink()

    def test_repeat_and_existing_managed_launcher_never_download_or_rewrite(self):
        self.target.parent.mkdir(parents=True)
        self.target.write_text('#!/bin/sh\n# ai-cli managed fixture\n')
        original = self.target.read_bytes(); stamp = self.target.stat().st_mtime_ns
        self.which.return_value = str(self.target)
        for _ in range(2):
            self.assertTrue(copilot.install_copilot(Host('linux','x64','fedora'))['preserved'])
        self.response.assert_not_called()
        self.assertEqual(self.target.read_bytes(), original)
        self.assertEqual(self.target.stat().st_mtime_ns, stamp)

    def test_vscode_shim_is_not_a_cli_installation(self):
        shim = self.home/'vscode/bin/copilot-shim/copilot'; shim.parent.mkdir(parents=True)
        shim.write_text('shim fixture')
        link = self.home/'copilot'; link.symlink_to(shim)
        self.which.return_value = str(link)
        self.assertIsNone(copilot.copilot_command())
        copilot.install_copilot(Host('linux','x64','ubuntu'))
        self.assertEqual(shim.read_text(), 'shim fixture')
        self.assertNotEqual(self.target.read_bytes(), shim.read_bytes())

    def test_probe_environment_excludes_tokens_and_real_user_state(self):
        with patch.dict(os.environ, {'GH_TOKEN':'fixture', 'GITHUB_TOKEN':'fixture'}):
            copilot.verify_copilot('/fixture/copilot')
        options = self.run.call_args.kwargs
        self.assertNotIn('GH_TOKEN', options['env']); self.assertNotIn('GITHUB_TOKEN', options['env'])
        self.assertNotEqual(options['env']['HOME'], str(self.home))
        self.assertTrue(options['noninteractive'])
        self.assertIn('--no-auto-update', self.run.call_args.args[0])

    def test_invalid_hash_has_no_installed_binary(self):
        copilot.RELEASE['linux']['x64'] = '0'*64
        with self.assertRaisesRegex(ValueError, 'Checksum'):
            copilot.install_copilot(Host('linux','x64','ubuntu'))
        self.assertFalse(self.target.exists())

    def test_unsupported_platform_and_architecture_do_not_download(self):
        for host in [Host('linux','x86','ubuntu'), Host('windows','x64')]:
            with self.assertRaisesRegex(ValueError, 'Unsupported'):
                copilot.install_copilot(host)
        self.response.assert_not_called()
        self.assertFalse(self.target.exists())

    def test_paths_links_and_invalid_payloads_are_rejected(self):
        for name, kind, body in [('../copilot',tarfile.REGTYPE,b'\x7fELFfixture'),
                                 ('copilot',tarfile.SYMTYPE,b''),
                                 ('copilot',tarfile.REGTYPE,b'not ELF')]:
            with self.subTest(name=name,kind=kind):
                self.body = self.archive(name, kind, body)
                copilot.RELEASE['linux']['x64'] = hashlib.sha256(self.body).hexdigest()
                with self.assertRaises(ValueError): copilot.install_copilot(Host('linux','x64','arch'))
                self.assertFalse(self.target.exists())

    def test_bad_runtime_version_never_commits(self):
        self.run.return_value = 'GitHub Copilot CLI 1.0.102.'
        with self.assertRaisesRegex(ValueError, 'mismatch'):
            copilot.install_copilot(Host('linux','x64','ubuntu'))
        self.assertFalse(self.target.exists())

    def test_foreign_target_and_concurrent_target_are_preserved(self):
        self.target.parent.mkdir(parents=True); self.target.write_text('foreign')
        with self.assertRaisesRegex(ValueError, 'no overwrite'):
            copilot.install_copilot(Host('linux','x64','ubuntu'))
        self.assertEqual(self.target.read_text(), 'foreign'); self.response.assert_not_called()
        self.target.unlink()
        def race(source, target):
            target.write_text('concurrent owner'); raise FileExistsError(target)
        with patch('lib.copilot.os.link', side_effect=race), self.assertRaises(FileExistsError):
            copilot.install_copilot(Host('linux','x64','ubuntu'))
        self.assertEqual(self.target.read_text(), 'concurrent owner')

    def test_mac_uses_existing_cask_adapter_and_preserves_existing_provider(self):
        with patch('lib.copilot.copilot_command', side_effect=[None,'/brew/bin/copilot']), \
             patch('lib.macos.install_cask') as install:
            result = copilot.install_copilot(Host('macos','arm64'))
        install.assert_called_once_with('copilot-cli', command='copilot')
        self.assertEqual(result['provider'], 'homebrew')
        self.which.return_value = '/existing/copilot'
        with patch('lib.macos.install_cask') as install:
            self.assertTrue(copilot.install_copilot(Host('macos','arm64'))['preserved'])
        install.assert_not_called()

    def test_windows_plan_renders_cli_only_with_single_owner(self):
        profile = json.loads((ROOT/'tests/profiles/windows-full.json').read_text())
        profile['chezmoi'] = {'os':'windows','homeDir':str(self.home),'osRelease':{'id':'windows'}}
        override = self.home/'profile.json'; override.write_text(json.dumps(profile))
        output = subprocess.run(['chezmoi','--source',str(ROOT),'--destination',str(self.home),
            '--config',str(self.home/'chezmoi.toml'),'--override-data-file',str(override),
            '--cache',str(self.home/'cache'),'--persistent-state',str(self.home/'state'),
            'execute-template','--file',str(ROOT/'home/.chezmoitemplates/windows/plan.json.tmpl')],
            check=True,capture_output=True,text=True,timeout=30)
        plan = json.loads(output.stdout)
        self.assertEqual(plan['native'], [{'id':'GitHub.Copilot','command':'copilot','version':'v1.0.103'}])
        self.assertFalse(any('copilot' in key.lower() for key in plan['mise']))
        self.assertFalse(any('copilot' in item.get('command','').lower() for item in plan['official']))
        self.assertFalse(any(item['id'] == 'GitHub.Copilot' for item in plan['bootstrap']))


if __name__ == '__main__':
    unittest.main()
