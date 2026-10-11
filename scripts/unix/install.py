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
REVIEWED_PLATFORMS = {'fedora', 'macos', *DESKTOP_PLATFORMS}
# Installer imports must not leave bytecode in the source checkout, especially as root.
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / "scripts"))
from lib.runtime import Host, download_verified, run
from lib.desktop import desktop_plan, install_desktop
from lib.packages import prepare_packages
from lib.backup import backup_targets
from lib.macos import install_native_cli, install_apps, verify_tools
from lib.tools import verify_mise_tools


def validate_profile(path):
    profile = json.loads(path.read_text())
    target = profile.get('platform')
    if target not in REVIEWED_PLATFORMS or profile.get('deployment') != {'enabled': True, 'externals': True}:
        raise ValueError('Explicit reviewed Fedora/Ubuntu/Arch/openSUSE enabled/externals profile required.')
    if target == 'macos':
        expected = json.loads((ROOT / 'tests/profiles/macos-full.json').read_text())
        if profile != expected:
            raise ValueError('Only the reviewed native Mac full profile is supported.')
        return profile
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
    host = Host.detect()
    if (host.system, host.architecture) not in {('linux', 'x64'), ('macos', 'arm64')}:
        raise ValueError('Supported: reviewed Linux x86_64 or Apple Silicon Mac.')
    import pwd
    if os.geteuid() == 0 or USER_HOME != Path(pwd.getpwuid(os.getuid()).pw_dir):
        raise ValueError('Run as a regular user with their actual login home.')
    if (host.distribution if host.system == 'linux' else host.system) != profile['platform']:
        raise ValueError('Installation profile must match the actual OS.')
    if host.distribution == 'ubuntu' and platform.freedesktop_os_release().get('VERSION_ID') != '26.04':
        raise ValueError('Ubuntu installation is reviewed for 26.04 only.')
    if any(os.environ.get(key) for key in ['MISE_CONFIG_DIR', 'MISE_GLOBAL_CONFIG_FILE',
                                          'MISE_DATA_DIR', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME']):
        raise ValueError('Baseline installer requires default user config/data locations; do not redirect HOME or XDG.')
    # mise exec exports the selected global environments on repeat installation.
    # Accept only the environment list already declared by this user's config.
    if os.environ.get('MISE_ENV'):
        selection = USER_HOME / '.config/mise/miserc.toml'
        declared = tomllib.loads(selection.read_text()).get('env', []) if selection.exists() else []
        if os.environ['MISE_ENV'].split(',') != declared:
            raise ValueError('MISE_ENV overrides the reviewed global environment selection.')
    # An existing personal environment must not be downgraded into this baseline.
    config = USER_HOME / '.config/chezmoi/chezmoi.toml'
    if config.exists():
        document = tomllib.loads(config.read_text())
        if profile['platform'] in DESKTOP_PLATFORMS | {'macos'} and document.get('umask') != 0o077:
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
        import re
        match = re.search(r'(?<![0-9])(\d+\.\d+\.\d+)(?![0-9])', output)
        if not match or tuple(map(int, match[1].split('.'))) < tuple(map(int, expected.split('.'))):
            raise ValueError(f'Existing {name} is below {expected}; update through its current provider.')
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
    host = Host.detect()
    prepare_packages(host, desktop=profile['platform'] in DESKTOP_PLATFORMS)
    mise = pinned_binary('mise', ROOT / 'scripts/mise-release.json', 'jdx/mise')
    chezmoi = pinned_binary('chezmoi', ROOT / 'tests/chezmoi-release.json', 'twpayne/chezmoi')
    paths = [USER_HOME / '.local/bin']
    if host.system == 'macos':
        paths.extend([Path('/opt/homebrew/bin'), USER_HOME / '.grok/bin'])
    os.environ['PATH'] = os.pathsep.join(map(str, paths)) + os.pathsep + os.environ['PATH']
    config = USER_HOME / '.config/chezmoi/chezmoi.toml'
    review = USER_HOME / '.local/state/dotfiles/review' / profile['platform']
    review.mkdir(parents=True, mode=0o700, exist_ok=True)
    review.chmod(0o700)
    preview = review / 'preview.toml'
    base = [chezmoi, '--source', ROOT, '--config', preview, '--no-tty', '--no-pager']
    rendered = run(base + ['--override-data-file', profile_path, 'execute-template',
                           '--init', '--file', ROOT / 'home/.chezmoi.toml.tmpl'], capture=True)
    if not matches_profile(tomllib.loads(rendered)['data'], profile):
        raise ValueError('Generated machine config does not match the explicit profile.')
    preview.write_text(rendered)
    preview.chmod(0o600)
    managed = set(run(base + ['managed', '--include=files,symlinks', '--path-style=relative'], capture=True).splitlines())
    required = ['.zshrc', '.gitconfig', '.config/gh/config.yml', '.config/mise/config.toml',
                '.config/mise/miserc.toml', '.tmux.conf', '.tmux.conf.local', '.config/nvim/init.lua']
    if host.system == 'linux':
        required.append('.bashrc')
    for target in required:
        if target not in managed:
            raise ValueError(f'Empty or incomplete deployment: {target} is not managed.')
    diff = run(base + ['diff'], capture=True)
    # Keep the complete private review, without dumping thousands of vendor files.
    (review / 'config.diff').write_text(diff)
    (review / 'config.diff').chmod(0o600)
    print(f'Fresh diff: {review / "config.diff"}', flush=True)
    changed = [line.removeprefix('diff --git ') for line in diff.splitlines() if line.startswith('diff --git ')]
    print(f'{len(changed)} changed files; configuration targets:', flush=True)
    own_targets = [USER_HOME / target for target in managed
                   if not target.startswith(('.oh-my-zsh/', '.tmux/', '.local/share/tmux/'))]
    print(run(base + ['diff', *sorted(own_targets)], capture=True), flush=True)
    extras = {'.config/chezmoi/chezmoi.toml', '.grok/config.toml'}
    if host.system == 'macos':
        extras.update({'.zprofile', '.bashrc', '.bash_profile'})
    backup = backup_targets(USER_HOME, managed | extras, diff, profile['platform'])
    print(f'Private targeted backup: {backup}', flush=True)
    config.parent.mkdir(parents=True, exist_ok=True)
    if config.exists():
        # Keep machine-specific data from the reviewed matching selection.
        actual = [chezmoi, '--source', ROOT, '--config', config, '--no-tty', '--no-pager']
    else:
        shutil.copy2(preview, config)
        config.chmod(0o600)
        actual = [chezmoi, '--source', ROOT, '--config', config, '--no-tty', '--no-pager']
    run(actual + ['init', '--config-path', config])
    selected = json.loads(run(actual + ['data', '--format=json'], capture=True))
    if not matches_profile(selected, profile):
        raise ValueError('Persisted selection differs from the explicit profile.')
    run(actual + ['--force', 'apply', USER_HOME / '.config/mise'])
    # Run from the real home, never inherit repository-only installer Python as a global CLI.
    run([mise, 'install', '--yes'])
    if host.system == 'macos':
        install_native_cli()
        if profile['features'].get('desktop', False):
            install_apps()
    elif profile['features'].get('desktop', False):
        install_desktop()
    final_diff = run(actual + ['diff'], capture=True)
    (backup / 'after-install.diff').write_text(final_diff)
    (backup / 'after-install.diff').chmod(0o600)
    run(actual + ['--force', 'apply'])
    run(actual + ['verify'])
    if run(actual + ['diff'], capture=True).strip():
        raise ValueError('Configuration still differs after installation.')
    evidence = verify_tools(mise) if host.system == 'macos' else verify_mise_tools(mise)
    (review / 'cli-verification.json').write_text(json.dumps(evidence, indent=2) + '\n')
    (review / 'cli-verification.json').chmod(0o600)
    print(f"{profile['platform']} configuration and tools applied. Authentication and desktop verification remain separate.", flush=True)


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
