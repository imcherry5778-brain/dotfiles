"""Copilot CLI bootstrap only; preserve existing owners and all user state."""
import json
import os
from pathlib import Path
import re
import shutil
import tarfile
import tempfile
from lib.runtime import download_verified, run

ROOT = Path(__file__).resolve().parents[2]
RELEASE = json.loads((ROOT / 'scripts/copilot-release.json').read_text())


def copilot_command():
    command = shutil.which('copilot')
    if command and 'copilot-shim' not in Path(command).resolve().parts:
        return command
    return None


def verify_copilot(command):
    # No real credentials, user config, plugin setup or model requests.
    with tempfile.TemporaryDirectory(prefix='dotfiles-copilot-version-') as temporary:
        env = {'PATH': os.environ.get('PATH', '/usr/bin:/bin'), 'HOME': temporary,
               'COPILOT_HOME': temporary, 'XDG_CONFIG_HOME': temporary,
               'XDG_DATA_HOME': temporary, 'XDG_STATE_HOME': temporary,
               'XDG_CACHE_HOME': temporary, 'TMPDIR': temporary}
        output = run([command, '--no-auto-update', '--version'], capture=True,
                     timeout=60, noninteractive=True, env=env).strip()
    match = re.search(r'^GitHub Copilot CLI (\d+\.\d+\.\d+)\.?\s*$', output, re.M)
    if not match:
        raise ValueError('Copilot command did not report a recognizable CLI version.')
    return {'executable': str(command), 'version': match[1]}


def install_copilot(host):
    """Install a missing CLI, never update/migrate an existing native provider."""
    existing = copilot_command()
    if existing:
        return dict(verify_copilot(existing), provider='existing', preserved=True)
    if host.system == 'macos':
        from lib.macos import CATALOG, install_cask
        install_cask(CATALOG['casks']['copilot'], command='copilot')
        command = copilot_command()
        if not command:
            raise ValueError('Homebrew completed without a Copilot CLI command.')
        return dict(verify_copilot(command), provider='homebrew')
    if host.system != 'linux' or host.architecture not in RELEASE['linux']:
        raise ValueError('Unsupported Copilot standalone platform/architecture.')
    target = Path.home() / '.local/bin/copilot'
    if os.path.lexists(target):
        raise ValueError('Existing Copilot destination needs review; no overwrite.')
    if target.parent.resolve() != target.parent:
        raise ValueError('Copilot installation parent contains a symlink.')
    target.parent.mkdir(parents=True, exist_ok=True)
    version = RELEASE['version']
    url = f'https://github.com/github/copilot-cli/releases/download/v{version}/copilot-linux-{host.architecture}.tar.gz'
    with tempfile.TemporaryDirectory(prefix='.copilot-stage-', dir=target.parent) as temporary:
        stage = Path(temporary)
        archive = download_verified(url, stage / 'copilot.tar.gz', RELEASE['linux'][host.architecture])
        binary = stage / 'copilot'
        with tarfile.open(archive, 'r:gz') as source:
            members = source.getmembers()
            if len(members) != 1 or members[0].name != 'copilot' or not members[0].isfile() or not 0 < members[0].size <= 512 * 1024 * 1024:
                raise ValueError('Unexpected Copilot archive members, type or size.')
            with source.extractfile(members[0]) as data, binary.open('xb') as output:
                shutil.copyfileobj(data, output)
        with binary.open('rb') as data:
            if data.read(4) != b'\x7fELF':
                raise ValueError('Copilot archive does not contain a Linux ELF executable.')
        binary.chmod(0o755)
        if verify_copilot(binary)['version'] != version:
            raise ValueError('Copilot archive/runtime version mismatch.')
        # Same-filesystem, exclusive commit: a concurrently created target wins.
        os.link(binary, target)
    return {'executable': str(target), 'version': version, 'provider': 'publisher-standalone'}
