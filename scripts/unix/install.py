#!/usr/bin/env python3
"""Explicit reviewed Fedora/Ubuntu/Arch/openSUSE installer; never invoked by shell startup or apply hooks."""
import argparse
import json
import os
from pathlib import Path
import platform
import sys
import shutil
import subprocess
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[2]
USER_HOME = Path.home()
DESKTOP_PLATFORMS = {'ubuntu', 'arch', 'opensuse-tumbleweed'}
REVIEWED_PLATFORMS = {'fedora', *DESKTOP_PLATFORMS}
# Installer imports must not leave bytecode in the source checkout, especially as root.
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / "scripts"))
from lib.runtime import Host, download_verified, run
from lib.desktop import desktop_plan, install_desktop


def validate_profile(path):
    profile = json.loads(path.read_text())
    target = profile.get('platform')
    if target not in REVIEWED_PLATFORMS or profile.get('deployment') != {'enabled': True, 'externals': True}:
        raise ValueError('Explicit reviewed Fedora/Ubuntu/Arch/openSUSE enabled/externals profile required.')
    features = profile.get('features', {})
    required = {'ai', 'personal_fedora', 'conda', 'bitwarden_agent', 'delta', 'editor_web'}
    expected = {key: target in DESKTOP_PLATFORMS and key in {'ai', 'editor_web'} for key in required}
    optional = {key: features.get(key, False) for key in ['managed_ai', 'desktop']}
    expected.update({key: value for key, value in optional.items() if key in features})
    if features != expected or any(type(value) is not bool for value in features.values()):
        raise ValueError('Only the Fedora common or Ubuntu/Arch/openSUSE desktop CLI profile is installable; review other selections separately.')
    if optional['managed_ai'] and (target not in DESKTOP_PLATFORMS or not features['ai']):
        raise ValueError('Managed AI migration is currently reviewed for Ubuntu/Arch/openSUSE only; preserve Fedora providers.')
    if optional['desktop'] and target not in DESKTOP_PLATFORMS:
        raise ValueError('Desktop profile installation is reviewed for Ubuntu/Arch/openSUSE only.')
    if set(profile) != {'platform', 'deployment', 'features'}:
        raise ValueError('Installation profile may not override machine paths or chezmoi runtime data.')
    return profile


def matches_profile(data, profile):
    """Absent optional flags mean false, so existing baseline selections remain valid."""
    if any(data.get(key) != profile[key] for key in ['platform', 'deployment']):
        return False
    requested = dict(profile['features'])
    actual = dict(data.get('features', {}))
    for key in ['managed_ai', 'desktop']:
        requested.setdefault(key, False)
        actual.setdefault(key, False)
    return requested == actual


def preflight(profile_path):
    profile = validate_profile(profile_path)
    if platform.system() != 'Linux':
        raise ValueError('Real configuration installation is currently reviewed for Linux only.')
    import pwd
    if os.geteuid() == 0 or USER_HOME != Path(pwd.getpwuid(os.getuid()).pw_dir):
        raise ValueError('Run as a regular user with their actual login home.')
    if platform.system() != 'Linux' or platform.machine() != 'x86_64':
        raise ValueError('Installation currently supports reviewed Fedora/Ubuntu/Arch/openSUSE x86_64 profiles only.')
    release = dict(line.split('=', 1) for line in Path('/etc/os-release').read_text().splitlines() if '=' in line)
    if release.get('ID', '').strip('"') != profile['platform']:
        raise ValueError('Installation profile must match the actual OS.')
    if profile['platform'] == 'ubuntu' and release.get('VERSION_ID', '').strip('"') != '26.04':
        raise ValueError('Ubuntu installation is reviewed for 26.04 only.')
    if any(os.environ.get(key) for key in ['MISE_ENV', 'MISE_CONFIG_DIR', 'MISE_GLOBAL_CONFIG_FILE',
                                          'MISE_DATA_DIR', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME']):
        raise ValueError('Baseline installer requires default user config/data locations; do not redirect HOME or XDG.')
    for binary in ['git', 'zsh', 'tmux', 'tar', 'gzip', 'unzip', 'perl', 'sed', 'awk']:
        if not shutil.which(binary):
            raise ValueError(f'Missing OS prerequisite: {binary}. Installer does not run sudo or dnf.')
    if profile['platform'] in DESKTOP_PLATFORMS:
        for binary in ['curl', 'wl-copy', 'gcc', 'make']:
            if not shutil.which(binary):
                raise ValueError(f'Missing desktop OS prerequisite: {binary}. Prepare OS packages separately.')
        if not Path('/usr/share/bash-completion/bash_completion').is_file():
            raise ValueError('Desktop bash-completion is required to preserve native providers.')
    # An existing personal environment must not be downgraded into this baseline.
    config = USER_HOME / '.config/chezmoi/chezmoi.toml'
    if config.exists():
        document = tomllib.loads(config.read_text())
        if profile['platform'] in DESKTOP_PLATFORMS and document.get('umask') != 0o077:
            raise ValueError('Existing desktop chezmoi permissions policy differs; review it before installation.')
        data = document.get('data', {})
        if not matches_profile(data, profile):
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
        download_verified(url, download, asset['sha256'])
        download.chmod(0o755)
        shutil.copy2(download, destination)
    print(f'Installed checksum-verified {name} {expected}', flush=True)
    return destination


def install(profile_path):
    profile = preflight(profile_path)
    mise = pinned_binary('mise', ROOT / 'scripts/mise-release.json', 'jdx/mise')
    chezmoi = pinned_binary('chezmoi', ROOT / 'tests/chezmoi-release.json', 'twpayne/chezmoi')
    os.environ['PATH'] = str(USER_HOME / '.local/bin') + os.pathsep + os.environ['PATH']
    config = USER_HOME / '.config/chezmoi/chezmoi.toml'
    base = [chezmoi, '--source', ROOT, '--config', config, '--no-tty', '--no-pager']
    print('Initialize explicit machine selection', flush=True)
    # chezmoi 2.73 init does not consume override-data-file for its config template.
    # Render with the documented execute-template --init data path, then persist once.
    if not config.exists():
        rendered = run(base + ['--override-data-file', profile_path, 'execute-template',
                               '--init', '--file', ROOT / 'home/.chezmoi.toml.tmpl'], capture=True)
        selected = tomllib.loads(rendered)['data']
        if not matches_profile(selected, profile):
            raise ValueError('Generated machine config does not match the explicit profile.')
        config.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(mode='w', dir=config.parent, delete=False) as target:
            target.write(rendered)
            temporary_config = Path(target.name)
        temporary_config.chmod(0o600)
        temporary_config.replace(config)
    run(base + ['init', '--config-path', config])
    selected = json.loads(run(base + ['data', '--format=json'], capture=True))
    if not matches_profile(selected, profile):
        raise ValueError('Persisted selection differs from the explicit profile.')
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
    if profile['features'].get('desktop', False):
        install_desktop()
    print(f"{profile['platform']} reviewed CLI profile applied; authentication and login shell were not configured.", flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', type=Path)
    stages = parser.add_mutually_exclusive_group()
    stages.add_argument('--desktop-plan', action='store_true', help='Show native application suppliers without installing.')
    stages.add_argument('--desktop-only', action='store_true', help='Explicit native application stage; no user config is touched.')
    args = parser.parse_args()
    try:
        if args.desktop_plan:
            print(json.dumps(desktop_plan(Host.detect()), ensure_ascii=False, indent=2))
        elif args.desktop_only:
            install_desktop()
        elif args.profile:
            install(args.profile.resolve(strict=True))
        else:
            parser.error('--profile is required for user configuration installation.')
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        raise SystemExit(f'Installation stopped: {error}')
