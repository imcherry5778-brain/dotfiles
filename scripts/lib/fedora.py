"""Personal Fedora migration: retain unmanaged runtimes and native providers."""
import hashlib
from pathlib import Path
import shutil
import tomllib

NATIVE_COMMANDS = ['agy', 'claude', 'codex', 'aider', 'pi', 'kiro-cli', 'grok',
                   'ghostty', 'orca-ide']
SHELL_ANCHORS = ['.oh-my-zsh/oh-my-zsh.sh', '.tmux/.tmux.conf', '.tmux/plugins/tpm/tpm']


def require_existing_environment(home):
    """This profile migrates an installed Fedora; it does not replace native owners."""
    for relative in SHELL_ANCHORS:
        if not (home / relative).is_file():
            raise ValueError(f'Personal Fedora requires its retained shell checkout: {relative}')
    config = home / '.config/chezmoi/chezmoi.toml'
    if not config.is_file():
        raise ValueError('Personal Fedora requires an existing machine configuration.')
    data = tomllib.loads(config.read_text()).get('data', {})
    prefix = Path(data.get('machine', {}).get('conda_prefix', ''))
    if not prefix.is_absolute() or not (prefix / 'condabin/conda').is_file():
        raise ValueError('Restore the existing Conda installation; no automatic provider replacement.')
    for command in NATIVE_COMMANDS:
        if not shutil.which(command):
            raise ValueError(f'Restore missing native {command} with its existing provider before migration.')


def snapshot_providers(home):
    data = tomllib.loads((home / '.config/chezmoi/chezmoi.toml').read_text())['data']
    conda = Path(data['machine']['conda_prefix'])
    paths = {}
    for name in NATIVE_COMMANDS:
        executable = shutil.which(name)
        if not executable:
            raise ValueError(f'Retained provider is absent: {name}')
        paths[name] = Path(executable)
    paths.update({name: conda / 'condabin' / name for name in ['conda', 'mamba']})
    result = {}
    for name, path in paths.items():
        if not path.is_file():
            raise ValueError(f'Retained provider is absent: {name}')
        with path.open('rb') as stream:
            digest = hashlib.file_digest(stream, 'sha256').hexdigest()
        result[name] = {'path': str(path), 'target': str(path.resolve()), 'sha256': digest}
    return result
