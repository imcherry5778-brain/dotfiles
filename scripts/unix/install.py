#!/usr/bin/env python3
"""Explicit Fedora baseline installer; never invoked by shell startup or apply hooks."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import pwd
import shutil
import subprocess
import tempfile
import tomllib
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
USER_HOME = Path.home()


def run(argv, *, capture=False, cwd=None):
    return subprocess.run([str(x) for x in argv], check=True, text=True,
                          stdout=subprocess.PIPE if capture else None,
                          cwd=cwd or USER_HOME, timeout=900).stdout


def validate_profile(path):
    profile = json.loads(path.read_text())
    if profile.get('platform') != 'fedora' or profile.get('deployment') != {'enabled': True, 'externals': True}:
        raise ValueError('Explicit Fedora enabled/externals profile required.')
    features = profile.get('features', {})
    required = {'ai', 'personal_fedora', 'conda', 'bitwarden_agent', 'delta', 'editor_web'}
    if set(features) != required or any(value is not False for value in features.values()):
        raise ValueError('Only the Fedora common baseline is installable; personal and AI migrations need separate preparation.')
    if set(profile) != {'platform', 'deployment', 'features'}:
        raise ValueError('Baseline profile may not override machine paths or chezmoi runtime data.')
    return profile


def preflight(profile_path):
    profile = validate_profile(profile_path)
    if os.geteuid() == 0 or USER_HOME != Path(pwd.getpwuid(os.getuid()).pw_dir):
        raise ValueError('Run as a regular user with their actual login home.')
    if platform.system() != 'Linux' or platform.machine() != 'x86_64':
        raise ValueError('Installation currently supports Fedora x86_64 only.')
    release = dict(line.split('=', 1) for line in Path('/etc/os-release').read_text().splitlines() if '=' in line)
    if release.get('ID', '').strip('"') != 'fedora':
        raise ValueError('Installation currently supports Fedora only.')
    if any(os.environ.get(key) for key in ['MISE_ENV', 'MISE_CONFIG_DIR', 'MISE_GLOBAL_CONFIG_FILE',
                                          'MISE_DATA_DIR', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME']):
        raise ValueError('Baseline installer requires default user config/data locations; do not redirect HOME or XDG.')
    for binary in ['git', 'zsh', 'tmux', 'tar', 'gzip', 'unzip']:
        if not shutil.which(binary):
            raise ValueError(f'Missing OS prerequisite: {binary}. Installer does not run sudo or dnf.')
    # An existing personal environment must not be downgraded into this baseline.
    config = USER_HOME / '.config/chezmoi/chezmoi.toml'
    if config.exists():
        data = tomllib.loads(config.read_text()).get('data', {})
        for key in profile:
            if data.get(key) != profile[key]:
                raise ValueError('Existing chezmoi machine selection differs; review the migration instead of replacing it.')
    return profile


def pinned_binary(name, metadata_path, repository):
    release = json.loads(metadata_path.read_text())
    expected = release['version']
    existing = shutil.which(name)
    if existing:
        output = run([existing, '--version'], capture=True)
        if expected not in output.split()[0:3]:
            # chezmoi reports vX.Y.Z or X.Y.Z, depending on its build.
            if not any(word.lstrip('v').rstrip(',') == expected for word in output.split()[:4]):
                raise ValueError(f'Existing {name} does not match reviewed bootstrap version {expected}; no upgrade performed.')
        return Path(existing)
    asset = release['assets']['linux-amd64']
    directory = USER_HOME / '.local/bin'
    directory.mkdir(parents=True, exist_ok=True)
    destination = directory / name
    if destination.exists() or destination.is_symlink():
        raise ValueError(f'{destination} exists outside PATH; refusing to overwrite it.')
    url = f"https://github.com/{repository}/releases/download/v{expected}/{asset['name']}"
    with tempfile.TemporaryDirectory(prefix='dotfiles-download-') as temporary:
        download = Path(temporary) / name
        with urllib.request.urlopen(url, timeout=120) as response, download.open('wb') as target:
            shutil.copyfileobj(response, target)
        if hashlib.sha256(download.read_bytes()).hexdigest() != asset['sha256']:
            raise ValueError(f'{name} checksum mismatch; downloaded binary was not executed.')
        download.chmod(0o755)
        shutil.copy2(download, destination)
    print(f'Installed checksum-verified {name} {expected}', flush=True)
    return destination


def install(profile_path):
    preflight(profile_path)
    mise = pinned_binary('mise', ROOT / 'scripts/mise-release.json', 'jdx/mise')
    chezmoi = pinned_binary('chezmoi', ROOT / 'tests/chezmoi-release.json', 'twpayne/chezmoi')
    os.environ['PATH'] = str(USER_HOME / '.local/bin') + os.pathsep + os.environ['PATH']
    config = USER_HOME / '.config/chezmoi/chezmoi.toml'
    base = [chezmoi, '--source', ROOT, '--config', config, '--no-tty', '--no-pager']
    print('Initialize explicit machine selection', flush=True)
    run(base + ['--override-data-file', profile_path, 'init'])
    managed = set(run(base + ['managed', '--include=files,symlinks', '--path-style=relative'], capture=True).splitlines())
    for required in ['.zshrc', '.bashrc', '.gitconfig', '.config/gh/config.yml', '.config/mise/config.toml',
                     '.config/mise/miserc.toml', '.tmux.conf', '.tmux.conf.local', '.config/nvim/init.lua']:
        if required not in managed:
            raise ValueError(f'Empty or incomplete deployment: {required} is not managed.')
    # Materialize the single tool inventory first; shell configs wait for installed tools.
    run(base + ['apply', USER_HOME / '.config/mise'])
    print('Install tools selected by the rendered global mise config', flush=True)
    run([mise, 'install', '--yes'])
    print('Apply configuration and pinned external plugins', flush=True)
    run(base + ['apply'])
    run(base + ['verify'])
    print('Fedora common baseline applied; authentication and personal profile were not configured.', flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', type=Path, required=True)
    args = parser.parse_args()
    try:
        install(args.profile.resolve(strict=True))
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        raise SystemExit(f'Installation stopped: {error}')
