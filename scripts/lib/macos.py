"""Mac native providers. Existing Homebrew apps retain their installation owner."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from lib.runtime import download_verified, run
from lib.tools import verify_mise_tools

ROOT = Path(__file__).resolve().parents[2]
CATALOG = json.loads((ROOT / 'scripts/macos-providers.json').read_text())


def install_cask(cask, command=None, application=None):
    if command and shutil.which(command):
        print(f'{command}: existing provider preserved.', flush=True)
        return
    if application and any((directory / application).exists() for directory in [Path('/Applications'), Path.home() / 'Applications']):
        print(f'{application}: existing app preserved.', flush=True)
        return
    listed = run(['brew', 'list', '--cask'], capture=True).splitlines()
    if cask.split('/')[-1] not in listed:
        run(['brew', 'install', '--cask', cask])
    if command and not shutil.which(command):
        raise ValueError(f'{cask} is installed but {command} is absent; repair its existing provider separately.')


def install_native_cli():
    for command in ['agy', 'claude', 'codex']:
        install_cask(CATALOG['casks'][command], command=command)
    for asset in CATALOG['official']:
        command = asset['command']
        if shutil.which(command):
            print(f'{command}: existing provider preserved.', flush=True)
            continue
        if command == 'kiro-cli':
            if shutil.which('q') or Path('/Applications/Kiro CLI.app').exists():
                raise ValueError('Existing Q/Kiro installation needs a provider review; no automatic replacement.')
        with tempfile.TemporaryDirectory(prefix='dotfiles-official-') as temporary:
            installer = download_verified(asset['url'], Path(temporary) / 'install.sh', asset['sha256'])
            environment = dict(os.environ)
            # Grok officially supports this bin directory; avoid overwriting an unrelated agent alias.
            # Its generated completion files remain vendor-owned, not chezmoi-managed.
            if command == 'grok':
                environment['PATH'] = str(Path.home() / '.grok/bin') + os.pathsep + environment['PATH']
                environment['SHELL'] = ''
            subprocess.run(['/bin/bash', str(installer), *asset['arguments']], check=True,
                           env=environment, cwd=Path.home(), timeout=900)
        if not shutil.which(command):
            raise ValueError(f'Official {command} installation completed without its CLI. Complete publisher setup, then repeat.')


def install_apps():
    install_cask(CATALOG['casks']['ghostty'], application='Ghostty.app')
    install_cask(CATALOG['casks']['font'])
    install_cask(CATALOG['casks']['orca'], application='Orca.app')


def verify_tools(mise):
    evidence = verify_mise_tools(mise)
    for command in ['agy', 'claude', 'codex', 'kiro-cli', 'grok']:
        evidence[command] = {'executable': shutil.which(command),
                             'output': run([mise, 'exec', '--', command, '--version'], capture=True, timeout=60).strip()}
    if not any(Path(directory, 'Ghostty.app').exists() for directory in ['/Applications', str(Path.home() / 'Applications')]):
        raise ValueError('Ghostty app is absent.')
    if not any(Path(directory, 'Orca.app').exists() for directory in ['/Applications', str(Path.home() / 'Applications')]):
        raise ValueError('Orca app is absent.')
    return evidence
