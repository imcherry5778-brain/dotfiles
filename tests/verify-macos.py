#!/usr/bin/env python3
"""Mac configuration contracts in a disposable destination; runs on any Unix host."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[1]


def run(arguments):
    return subprocess.run(list(map(str, arguments)), check=True, text=True, capture_output=True).stdout


def verify(chezmoi):
    with tempfile.TemporaryDirectory(prefix='mac configuration with spaces ') as temporary:
        scratch = Path(temporary)
        home = scratch / 'home'; home.mkdir()
        source = scratch / 'source with spaces'
        shutil.copytree(ROOT, source, ignore=shutil.ignore_patterns('.git', '__pycache__', '.artifacts'))
        run(['git', '-c', 'init.templateDir=', 'init', '--quiet', source])
        selection = json.loads((source / 'tests/profiles/macos-full.json').read_text())
        selection['deployment']['externals'] = False
        selection['chezmoi'] = {'os': 'darwin', 'homeDir': str(home)}
        override = scratch / 'selection.json'; override.write_text(json.dumps(selection))
        config = scratch / 'config.toml'
        base = [chezmoi, '--source', source, '--destination', home, '--config', config, '--override-data-file', override,
                '--cache', scratch / 'cache', '--persistent-state', scratch / 'state', '--no-tty', '--no-pager']
        config.write_text(run(base + ['execute-template', '--init', '--file', source / 'home/.chezmoi.toml.tmpl']))
        original = '# Hermes\nexport PATH="$HOME/.local/bin:$PATH"\n'
        (home / '.zprofile').write_text(original)
        (home / '.bashrc').write_text('# native bash retained\n')
        ghostty = home / '.config/ghostty/config'; ghostty.parent.mkdir(parents=True)
        ghostty.write_text('font-family = D2Coding\n# retained\n')
        run(base + ['apply'])
        managed = run(base + ['managed', '--include=files,symlinks', '--path-style=relative']).splitlines()
        assert '.zprofile' in managed and '.config/mise/config.macos.toml' in managed
        assert '.bashrc' not in managed and '.config/mise/config.ai-managed.toml' not in managed
        assert '.config/shell/zsh-completion.zsh' in managed
        assert (home / '.zprofile').read_text().startswith(original)
        assert (home / '.bashrc').read_text() == '# native bash retained\n'
        assert ghostty.read_text() == 'font-family = D2Coding\n# retained\n'
        assert '[[ ! -S ${SSH_AUTH_SOCK:-}' in (home / '.zshrc').read_text()
        inventory = {}
        for name in ['config.toml', 'config.ai.toml', 'config.macos.toml']:
            tools = tomllib.loads((home / '.config/mise' / name).read_text())['tools']
            assert not set(tools) & inventory.keys(), 'Duplicate Mac CLI owners'
            inventory.update(tools)
        assert len(inventory) == 19
        assert inventory['node'] == '24.21.0' and inventory['pnpm'] == '12.9.1'
        assert tomllib.loads((home / '.config/mise/miserc.toml').read_text())['env'] == ['ai', 'macos']
        snapshot = {str(p.relative_to(home)): p.read_bytes() for p in home.rglob('*') if p.is_file()}
        run(base + ['apply']); run(base + ['verify'])
        assert not run(base + ['diff']).strip()
        assert snapshot == {str(p.relative_to(home)): p.read_bytes() for p in home.rglob('*') if p.is_file()}
        for name in ['.zshrc', '.zprofile', '.config/shell/zsh-completion.zsh']:
            run(['zsh', '-n', home / name])
        print('Mac source: native opt-in, 19 unique mise tools, login/Bash/font preservation and repeated apply passed.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(); parser.add_argument('--chezmoi', required=True)
    verify(parser.parse_args().chezmoi)
