"""Verify the selected single-owner mise inventory in the actual user home."""
import json
import subprocess
from pathlib import Path
import tomllib
from lib.runtime import run

COMMANDS = {'ripgrep': 'rg', 'neovim': 'nvim', 'npm:@earendil-works/pi-coding-agent': 'pi',
            'pipx:aider-chat': 'aider', 'http:kiro-cli': 'kiro-cli'}


def selected_tools():
    directory = Path.home() / '.config/mise'
    environments = tomllib.loads((directory / 'miserc.toml').read_text())['env']
    tools = {}
    for name in ['config.toml', *(f'config.{environment}.toml' for environment in environments)]:
        additions = tomllib.loads((directory / name).read_text()).get('tools', {})
        if tools.keys() & additions.keys():
            raise ValueError(f'Duplicate mise owners in {name}.')
        tools.update(additions)
    return tools


def verify_mise_tools(mise):
    tools = selected_tools()
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


def reconcile_mise_tools(mise):
    """Restore missing commands at declared versions without upgrading other tools."""
    tools = selected_tools()
    installed = json.loads(run([mise, 'ls', '--current', '--json'], capture=True))
    for tool, specification in tools.items():
        version = specification['version'] if isinstance(specification, dict) else specification
        entry = next((item for item in installed.get(tool, []) if item['version'] == version and item['installed']), None)
        if not entry:
            continue
        command = COMMANDS.get(tool, tool)
        try:
            executable = Path(run([mise, 'which', command], capture=True).strip())
        except subprocess.CalledProcessError:
            executable = None
        if executable is not None and executable.is_file():
            continue
        # Only the selected mise-owned version is repaired, never native providers.
        print(f'Repairing missing {command}: {tool}@{version}', flush=True)
        run([mise, 'uninstall', '--yes', f'{tool}@{version}'])
    run([mise, 'install', '--yes'])
