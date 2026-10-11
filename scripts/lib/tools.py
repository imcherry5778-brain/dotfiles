"""Verify the selected single-owner mise inventory in the actual user home."""
import json
from pathlib import Path
import tomllib
from lib.runtime import run

COMMANDS = {'ripgrep': 'rg', 'neovim': 'nvim', 'npm:@earendil-works/pi-coding-agent': 'pi',
            'pipx:aider-chat': 'aider', 'http:kiro-cli': 'kiro-cli'}


def verify_mise_tools(mise):
    directory = Path.home() / '.config/mise'
    environments = tomllib.loads((directory / 'miserc.toml').read_text())['env']
    tools = {}
    for name in ['config.toml', *(f'config.{environment}.toml' for environment in environments)]:
        additions = tomllib.loads((directory / name).read_text()).get('tools', {})
        if tools.keys() & additions.keys():
            raise ValueError(f'Duplicate mise owners in {name}.')
        tools.update(additions)
    installed = json.loads(run([mise, 'ls', '--current', '--json'], capture=True))
    evidence = {}
    for tool, specification in tools.items():
        version = specification['version'] if isinstance(specification, dict) else specification
        if not any(item['installed'] and item['version'] == version for item in installed.get(tool, [])):
            raise ValueError(f'{tool} is absent at the selected version {version}.')
        command = COMMANDS.get(tool, tool)
        executable = Path(run([mise, 'which', command], capture=True).strip())
        if not executable.is_relative_to(Path.home() / '.local/share/mise/installs') or not executable.is_file():
            raise ValueError(f'{command} resolves outside its selected mise owner.')
        output = run([mise, 'exec', '--', command, '-V' if command == 'tmux' else '--version'], capture=True, timeout=60).strip()
        if version not in output:
            raise ValueError(f'{command} version output differs from {version}.')
        evidence[command] = {'version': version, 'executable': str(executable), 'output': output}
    return evidence
