#!/usr/bin/env python3
"""Ubuntu source checks in disposable destinations; no real-home deployment."""
import argparse
import importlib.util
import json
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[1]


def run(argv):
    result = subprocess.run([str(x) for x in argv], capture_output=True, text=True, timeout=60)
    if result.returncode:
        raise RuntimeError(result.stderr + result.stdout)
    return result.stdout


def state(home):
    return {str(p.relative_to(home)): (stat.S_IMODE(p.lstat().st_mode),
            str(p.readlink()) if p.is_symlink() else p.read_bytes() if p.is_file() else None)
            for p in home.rglob('*')}


def verify(chezmoi):
    with tempfile.TemporaryDirectory(prefix='ubuntu-source-check-') as temporary:
        scratch = Path(temporary)
        source, home = scratch / 'source with spaces', scratch / 'home with spaces'
        shutil.copytree(ROOT, source, ignore=shutil.ignore_patterns('.git', '__pycache__', '.artifacts'))
        home.mkdir()
        run(['git', '-c', 'init.templateDir=', 'init', '--quiet', source])
        profile = json.loads((source / 'tests/profiles/ubuntu-desktop.json').read_text())
        profile['deployment']['externals'] = False
        profile['chezmoi'] = {'os': 'linux', 'osRelease': {'id': 'ubuntu'}, 'homeDir': str(home)}
        override = scratch / 'profile.json'
        override.write_text(json.dumps(profile))
        config = scratch / 'chezmoi.toml'
        base = [chezmoi, '--source', source, '--destination', home, '--config', config,
                '--cache', scratch / 'cache', '--persistent-state', scratch / 'state', '--no-tty', '--no-pager']
        rendered = run(base + ['--override-data-file', override, 'execute-template', '--init', '--file', source / 'home/.chezmoi.toml.tmpl'])
        document = tomllib.loads(rendered)
        assert document['umask'] == 0o077
        assert document['data']['platform'] == 'ubuntu' and not document['data']['features']['personal_fedora']
        config.write_text(rendered)
        # Use persisted selection rather than masking it with runtime overrides.
        original = "# Local customization\nalias keep_me='printf preserved'\nHISTSIZE=1234\n"
        (home / '.bashrc').write_text(original)
        for name in ['.profile', '.bash_logout']:
            (home / name).write_text(f'{name} must survive\n')
        for name in ['.config', '.local', '.local/share']:
            p = home / name; p.mkdir(parents=True, exist_ok=True); p.chmod(0o700)
        (home / 'unmanaged').write_text('preserved\n')
        run(base + ['apply'])
        before = state(home)
        run(base + ['apply'])
        assert state(home) == before
        run(base + ['verify'])
        assert not run(base + ['diff']).strip()
        bashrc = (home / '.bashrc').read_text()
        assert bashrc.startswith(original) and bashrc.count('source "$HOME/.config/shell/bashrc.bash"') == 1
        for name in ['.profile', '.bash_logout']:
            assert (home / name).read_text() == f'{name} must survive\n'
        assert (home / 'unmanaged').read_text() == 'preserved\n'
        for name in ['.config', '.local', '.local/share']:
            assert stat.S_IMODE((home / name).stat().st_mode) == 0o700
        assert stat.S_IMODE((home / '.bashrc').stat().st_mode) == 0o600
        managed = set(run(base + ['managed', '--include=files,symlinks', '--path-style=relative']).splitlines())
        assert '.config/shell/bashrc.bash' in managed and '.config/shell/zsh-completion.zsh' in managed
        assert not any('shell-completion/' in p or '/carapace/specs/' in p or 'personal-fedora' in p for p in managed)
        assert not any(p.endswith(('auth.json', 'hosts.yml', 'credentials.json')) for p in managed)
        inventory = {}
        for name in ['config.toml', 'config.ai.toml', 'config.editor-ubuntu.toml']:
            tools = tomllib.loads((home / '.config/mise' / name).read_text())['tools']
            assert not set(tools) & set(inventory), 'Duplicate tool owners'
            inventory.update(tools)
        assert len(inventory) == 15 and 'node' in inventory and 'opencode' in inventory
        assert tomllib.loads((home / '.config/mise/miserc.toml').read_text())['env'] == ['ai', 'editor-ubuntu']
        for name in ['.bashrc', '.config/shell/bashrc.bash', '.zshrc', '.config/shell/zsh-completion.zsh']:
            run(['zsh' if name.endswith(('zsh', 'zshrc')) else 'bash', '-n', home / name])
        # External archives are rendered only. No downloads in this verifier.
        profile['deployment']['externals'] = True
        override.write_text(json.dumps(profile))
        external = tomllib.loads(run(base + ['--override-data-file', override, 'execute-template', '--file', source / 'home/.chezmoiexternal.toml.tmpl']))
        assert len(external) == 10 and '.oh-my-zsh' in external and '.tmux' in external
        profile['features']['personal_fedora'] = True
        override.write_text(json.dumps(profile))
        result = subprocess.run([str(x) for x in base + ['--override-data-file', override, 'managed']], capture_output=True, text=True)
        assert result.returncode and 'Fedora-only' in result.stderr
        # Installer must keep platform/feature/profile boundaries explicit.
        spec = importlib.util.spec_from_file_location('installer', ROOT / 'scripts/unix/install.py')
        installer = importlib.util.module_from_spec(spec); spec.loader.exec_module(installer)
        installer.validate_profile(ROOT / 'tests/profiles/ubuntu-desktop.json')
        installer.validate_profile(ROOT / 'tests/profiles/fedora-common.json')
    # Full AI profile is opt-in; its tool ownership must not leak into Fedora/baseline.
    with tempfile.TemporaryDirectory(prefix='ubuntu-full-source-') as temporary:
        scratch = Path(temporary)
        source, home = scratch / 'source with spaces', scratch / 'home with spaces'
        shutil.copytree(ROOT, source, ignore=shutil.ignore_patterns('.git', '__pycache__', '.artifacts'))
        home.mkdir()
        run(['git', '-c', 'init.templateDir=', 'init', '--quiet', source])
        profile = json.loads((ROOT / 'tests/profiles/ubuntu-full.json').read_text())
        profile['deployment']['externals'] = False
        profile['chezmoi'] = {'os': 'linux', 'osRelease': {'id': 'ubuntu'}}
        override = scratch / 'profile.json'
        override.write_text(json.dumps(profile))
        config = scratch / 'chezmoi.toml'
        base = [chezmoi, '--source', source, '--destination', home, '--config', config,
                '--cache', scratch / 'cache', '--persistent-state', scratch / 'state',
                '--override-data-file', override, '--no-tty', '--no-pager']
        config.write_text(run(base + ['execute-template', '--init', '--file', source / 'home/.chezmoi.toml.tmpl']))
        run(base + ['apply'])
        inventory = {}
        for name in ['config.toml', 'config.ai.toml', 'config.ai-managed.toml', 'config.editor-ubuntu.toml']:
            tools = tomllib.loads((home / '.config/mise' / name).read_text())['tools']
            assert not set(tools) & set(inventory), 'Duplicate tool owners in full profile'
            inventory.update(tools)
        assert len(inventory) == 22
        assert tomllib.loads((home / '.config/mise/miserc.toml').read_text())['env'] == ['ai', 'ai-managed', 'editor-ubuntu']
        before = state(home)
        run(base + ['apply'])
        assert state(home) == before and not run(base + ['diff']).strip()
        assert not (home / '.config/ghostty/config').exists(), 'Default-only Ghostty config must not be generated'
    print('Ubuntu source: persisted profile, 15/22 unique tools, explicit AI opt-in, Bash preservation, private modes, repeated apply and guards passed.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--chezmoi', required=True)
    verify(parser.parse_args().chezmoi)
