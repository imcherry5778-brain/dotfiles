#!/usr/bin/env python3
"""Explicit reviewed Fedora/Ubuntu/Arch/openSUSE installer; provider stages invoked by chezmoi; never invoked by shell startup."""
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
from lib.macos import install_native_cli, install_apps, verify_tools, inspect_ghostty_configuration
from lib.tools import verify_mise_tools


def validate_profile(path):
    profile = json.loads(path.read_text())
    target = profile.get('platform')
    if any(type(value) is not bool for value in profile.get('features', {}).values()) or any(type(value) is not bool for value in profile.get('deployment', {}).values()):
        raise ValueError('Feature and deployment flags must be Booleans.')
    if set(profile) != {'platform', 'deployment', 'features'}:
        raise ValueError('Installation profile may not override machine paths or chezmoi runtime data.')
    if target == 'fedora' and profile.get('features', {}).get('personal_fedora'):
        expected = json.loads((ROOT / 'tests/profiles/fedora-personal.json').read_text())
        if not matches_profile(profile, expected):
            raise ValueError('Personal Fedora preserves its reviewed features, native providers and externals=false.')
        return profile
    if target not in REVIEWED_PLATFORMS or profile.get('deployment') != {'enabled': True, 'externals': True}:
        raise ValueError('Explicit reviewed Fedora/Ubuntu/Arch/openSUSE enabled/externals profile required.')
    if target == 'fedora' and profile == json.loads((ROOT / 'tests/profiles/fedora-full.json').read_text()):
        return profile
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
    if profile['features'].get('personal_fedora'):
        from lib.fedora import require_existing_environment
        require_existing_environment(USER_HOME)
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
    print(f'Installed checksum-verified {name} {expected}', file=sys.stderr, flush=True)
    return destination


def install(profile_path):
    """Compatibility entry: chezmoi owns application and calls provider stages."""
    profile = preflight(profile_path)
    chezmoi = pinned_binary('chezmoi', ROOT / 'tests/chezmoi-release.json', 'twpayne/chezmoi')
    run([chezmoi, '--source', ROOT, '--override-data-file', profile_path,
         'init', '--apply'])


class ReviewReader:
    """Read-only queries with a separate state file; never reenter apply/init.

    The parent apply holds its state database lock. A disposable query database
    prevents lock recursion without disabling locks or changing the parent's state.
    Source, destination and config remain the parent's exact paths.
    """
    def __init__(self, context, state):
        self.base = [context['chezmoi'], '--source', ROOT, '--config', context['config'],
                     '--destination', USER_HOME, '--persistent-state', state,
                     '--no-tty', '--no-pager']

    def query(self, command, *arguments):
        if command not in {'managed', 'diff', 'status', 'verify'}:
            raise ValueError('Only read-only review commands are permitted inside apply.')
        return run([*self.base, command, *arguments], capture=True)

    def managed(self):
        return set(self.query('managed', '--include=files,symlinks', '--path-style=relative').splitlines())


def validate_context(context):
    if Path(context['source']).resolve() != ROOT or Path(context['destination']) != USER_HOME:
        raise ValueError('Install scripts require the actual checkout and login home, never an isolated render destination.')
    if context['automation'] is not True:
        raise ValueError('Installation automation must be explicitly enabled.')
    with tempfile.TemporaryDirectory(prefix='dotfiles-profile-') as scratch:
        path = Path(scratch) / 'profile.json'
        path.write_text(json.dumps(context['profile']))
        return preflight(path)


def assert_ai_providers(home):
    """Portable full profiles never take over an existing native AI provider."""
    for command in ['agy', 'claude', 'codex', 'pi', 'kiro-cli', 'grok', 'aider']:
        existing = shutil.which(command)
        if existing and not Path(existing).absolute().is_relative_to(home / '.local/share/mise'):
            raise ValueError(f'Existing {command} provider needs review; no automatic migration to mise.')


def apply_stage(stage, context):
    profile = validate_context(context)
    host = Host.detect()
    os.environ['PATH'] = os.pathsep.join(map(str, [USER_HOME / '.local/bin',
        *([Path('/opt/homebrew/bin'), USER_HOME / '.grok/bin'] if host.system == 'macos' else [])])) + os.pathsep + os.environ['PATH']
    mise = pinned_binary('mise', ROOT / 'scripts/mise-release.json', 'jdx/mise')
    review = USER_HOME / '.local/state/dotfiles/review' / profile['platform']
    review.mkdir(parents=True, mode=0o700, exist_ok=True); review.chmod(0o700)
    with tempfile.TemporaryDirectory(prefix='dotfiles-read-only-') as scratch:
        reader = ReviewReader(context, Path(scratch) / 'state.boltdb')
        managed = reader.managed()
        if '.config/mise/config.toml' not in managed or '.zshrc' not in managed:
            raise ValueError('Empty or incomplete deployment.')
        if stage == 'before':
            if profile['features'].get('managed_ai', False):
                assert_ai_providers(USER_HOME)
            if host.system == 'macos':
                inspect_ghostty_configuration()
            if profile['features'].get('personal_fedora'):
                from lib.fedora import snapshot_providers
                preserved = review / 'preserved-providers.json'
                preserved.write_text(json.dumps(snapshot_providers(USER_HOME), indent=2) + '\n')
                preserved.chmod(0o600)
            diff = reader.query('diff', '--exclude=scripts')
            (review / 'config.diff').write_text(diff); (review / 'config.diff').chmod(0o600)
            rows = reader.query('status', '--include=files,symlinks', '--path-style=relative').splitlines()
            changed = {row[3:] for row in rows if len(row) >= 4 and row[1] != ' '}
            if not changed <= managed:
                raise ValueError('Review includes an unmanaged target.')
            directories = {row[3:] for row in reader.query('status', '--include=dirs', '--path-style=relative').splitlines()
                           if len(row) >= 4 and row[1] != ' '}
            extras = {'.config/chezmoi/chezmoi.toml', '.grok/config.toml'}
            if host.system == 'macos':
                extras.update({'.zprofile', '.bashrc', '.bash_profile'})
            backup = backup_targets(USER_HOME, changed | extras, diff, profile['platform'], directories=directories)
            (review / 'last-backup.txt').write_text(str(backup)); (review / 'last-backup.txt').chmod(0o600)
            print(f'Fresh diff: {review / "config.diff"}\nPrivate targeted backup: {backup}', flush=True)
            prepare_packages(host, desktop=profile['features'].get('desktop', False) or profile['features']['editor_web'])
            return
        from lib.tools import reconcile_mise_tools
        from lib.backup import preserve_installer_loaders
        reconcile_mise_tools(mise)
        # Native installers may append shell loaders. Keep the already-applied
        # managed shell byte-for-byte, including user customizations. Their PATH
        # additions and vendor-owned completions/authentication remain intact.
        with preserve_installer_loaders(USER_HOME, managed):
            if host.system == 'macos':
                install_native_cli()
                if profile['features'].get('desktop', False):
                    install_apps()
            elif profile['features'].get('desktop', False):
                install_desktop()
        if profile['features'].get('personal_fedora'):
            from lib.fedora import snapshot_providers
            if snapshot_providers(USER_HOME) != json.loads((review / 'preserved-providers.json').read_text()):
                raise ValueError('An existing native Fedora provider changed during installation.')
        evidence = verify_tools(mise) if host.system == 'macos' and profile['features'].get('desktop', False) else verify_mise_tools(mise)
        (review / 'cli-verification.json').write_text(json.dumps(evidence, indent=2) + '\n')
        (review / 'cli-verification.json').chmod(0o600)
        reader.query('verify', '--exclude=scripts')
        if reader.query('diff', '--exclude=scripts').strip():
            raise ValueError('Configuration differs after installation.')
        print(f"{profile['platform']}: configuration and tool execution verified; authentication/GUI are separate.", flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', type=Path)
    stages = parser.add_mutually_exclusive_group()
    stages.add_argument('--desktop-plan', action='store_true', help='Show native application suppliers without installing.')
    stages.add_argument('--desktop-only', action='store_true', help='Explicit native application stage; no user config is touched.')
    stages.add_argument('--stage', choices=['before', 'after'])
    stages.add_argument('--bootstrap-chezmoi', action='store_true')
    args = parser.parse_args()
    try:
        if args.bootstrap_chezmoi:
            print(pinned_binary('chezmoi', ROOT / 'tests/chezmoi-release.json', 'twpayne/chezmoi'))
        elif args.stage:
            apply_stage(args.stage, json.load(sys.stdin))
        elif args.desktop_plan:
            print(json.dumps(desktop_plan(Host.detect()), ensure_ascii=False, indent=2))
        elif args.desktop_only:
            install_desktop()
        elif args.profile:
            install(args.profile.resolve(strict=True))
        else:
            parser.error('--profile is required for user configuration installation.')
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        raise SystemExit(f'Installation stopped: {error}')
