#!/usr/bin/env python3
"""Hosted Fedora migration: 34 real mise CLI, retained native-provider fixtures."""
import json
import os
from pathlib import Path
import pwd
import subprocess
import sys
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[1]
HOME = Path.home()
sys.path.insert(0, str(ROOT / 'scripts'))
from lib.fedora import NATIVE_COMMANDS, snapshot_providers
from lib.tools import selected_tools, verify_mise_tools
sys.path.insert(0, str(ROOT / 'tests'))
import importlib.util
spec = importlib.util.spec_from_file_location('acceptance', ROOT / 'tests/test-install.py')
acceptance = importlib.util.module_from_spec(spec); spec.loader.exec_module(acceptance)
def managed_snapshot(chezmoi):
    return acceptance.snapshot([chezmoi, '--no-tty', '--no-pager'])


def run(*arguments, capture=False):
    result = subprocess.run(list(map(str, arguments)), check=True, cwd=HOME, text=True,
                            stdout=subprocess.PIPE if capture else None, timeout=1800)
    return result.stdout


def main():
    assert Path('/.dockerenv').exists() and pwd.getpwuid(os.getuid()).pw_name == 'dotfiles-test'
    assert ' ' in str(ROOT)
    assert not (HOME / '.config/chezmoi/chezmoi.toml').exists()
    profile = json.loads((ROOT / 'tests/profiles/fedora-personal.json').read_text())
    # Emulate the legacy machine selection without newer optional false flags.
    profile['features'].pop('managed_ai'); profile['features'].pop('desktop')
    conda = HOME / 'retained conda'
    native_bin = HOME / '.local/bin'; native_bin.mkdir(parents=True, exist_ok=True)
    for name in NATIVE_COMMANDS:
        path = native_bin / name
        path.write_text('#!/bin/sh\nprintf "retained native fixture\\n"\n'); path.chmod(0o755)
    for name in ['conda', 'mamba']:
        path = conda / 'condabin' / name; path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text('#!/bin/sh\nprintf "retained conda fixture\\n"\n'); path.chmod(0o755)
    machine = {'conda_prefix': str(conda), 'ssh_agent_socket': str(HOME / 'retained-agent.sock'),
               'mise_data_dir': ''}
    run('git', '-c', 'init.templateDir=', 'init', '--quiet', ROOT)
    # Test prerequisite only: obtain chezmoi, without preparing OS packages.
    run('mise', '-C', ROOT / 'scripts/unix', 'exec', '--', 'python', ROOT / 'scripts/unix/install.py', '--bootstrap-chezmoi')
    chezmoi = HOME / '.local/bin/chezmoi'
    with tempfile.TemporaryDirectory(prefix='personal migration ') as temporary:
        scratch = Path(temporary); override = scratch / 'legacy.json'
        override.write_text(json.dumps(dict(profile, initialized=True, machine=machine, automation={'enabled':False})))
        run(chezmoi, '--source', ROOT, '--override-data-file', override, 'init')
        # Existing shell checkouts are a prerequisite, not part of migration.
        seed = json.loads(override.read_text()); seed['deployment']['externals'] = True
        upstream = scratch / 'existing-shell.json'; upstream.write_text(json.dumps(seed))
        run(chezmoi, '--override-data-file', upstream, 'apply', '--include=externals')
        marker = HOME / '.oh-my-zsh/custom/retained-user-plugin.txt'; marker.write_text('preserved\n')
        run(chezmoi, 'apply')  # legacy configuration, automation disabled
        assert not tomllib.loads((HOME / '.config/chezmoi/chezmoi.toml').read_text())['data']['automation']['enabled']
        run('mise', 'install', 'fd', '--yes')
        fd = Path(run('mise', 'which', 'fd', capture=True).strip()); fd_time = fd.stat().st_mtime_ns
        providers = snapshot_providers(HOME)
        activation = scratch / 'activation.json'; activation.write_text('{"automation":{"enabled":true}}')
        run(chezmoi, '--override-data-file', activation, 'init', '--apply')
        data = tomllib.loads((HOME / '.config/chezmoi/chezmoi.toml').read_text())['data']
        assert data['automation']['enabled'] and not data['deployment']['externals']
        assert data['machine']['conda_prefix'] == str(conda)
        assert data['machine']['ssh_agent_socket'] == machine['ssh_agent_socket']
        assert len(selected_tools()) == 34
        before = managed_snapshot(chezmoi)
        run(chezmoi, 'apply')
        assert managed_snapshot(chezmoi) == before
        ansible = Path(run('mise', 'which', 'ansible', capture=True).strip()); ansible.unlink()
        run(chezmoi, 'apply')
        assert ansible.is_file() and fd.stat().st_mtime_ns == fd_time
        assert managed_snapshot(chezmoi) == before
        assert snapshot_providers(HOME) == providers and marker.read_text() == 'preserved\n'
        assert len(verify_mise_tools('mise')) == 34
        run(chezmoi, 'verify', '--exclude=scripts')
        assert not run(chezmoi, 'diff', '--exclude=scripts', capture=True).strip()
    print('Fedora personal: 34 real mise CLI, legacy activation, repeat apply and deleted Ansible repair passed; native fixtures retained, GUI/authentication excluded.')


if __name__ == '__main__':
    main()
