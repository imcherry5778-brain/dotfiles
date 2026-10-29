"""Verify the selected single-owner mise inventory in the actual user home."""
import json
import os
import tempfile
import subprocess
from pathlib import Path
import tomllib
from lib.runtime import run

COMMANDS = {'ripgrep': 'rg', 'neovim': 'nvim', 'npm:@earendil-works/pi-coding-agent': 'pi',
            'pipx:aider-chat': 'aider', 'http:kiro-cli': 'kiro-cli',
            'ansible-core': 'ansible', 'aws-cli': 'aws', 'azure': 'az',
            'bitwarden': 'bw', 'cloudflare-cf': 'cf', 'mysql-client': 'mysql',
            'opentofu': 'tofu', 'rust': 'rustc'}

VERSION_ARGUMENTS = {'az': ['version'], 'go': ['version'],
                     'argocd': ['version', '--client', '--short'],
                     'cosign': ['version'], 'k3d': ['version'], 'oras': ['version'],
                     'helm': ['version', '--short'], 'k9s': ['version'],
                     'kubectl': ['version', '--client=true', '--output=json'],
                     'tmux': ['-V']}


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
        executable = owned_executable(mise, tool, command, version)
        if not executable.is_file():
            raise ValueError(f'{command} resolves outside its selected mise owner.')
        output = version_output(mise, command)
        expected = version.removeprefix('corretto-') if tool == 'java' else version
        if expected not in output:
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
            executable = owned_executable(mise, tool, command, version)
        except subprocess.CalledProcessError:
            executable = None
        if executable is not None and executable.is_file():
            continue
        # Only the selected mise-owned version is repaired, never native providers.
        print(f'Repairing missing {command}: {tool}@{version}', flush=True)
        run([mise, 'uninstall', '--yes', f'{tool}@{version}'])
    if 'opencode' in tools:
        # Scope strict locking to OpenCode; other tools retain their existing
        # backends and update policy. Missing/stale locks must fail closed.
        specification = tools['opencode']
        version = specification['version'] if isinstance(specification, dict) else specification
        run([mise, 'install', '--yes', '--locked', f'opencode@{version}'])
    run([mise, 'install', '--yes'])


def owned_executable(mise, tool, command, version):
    """Resolve mise artifacts, or its selected rustup toolchain behind Cargo proxies."""
    if tool == 'rust':
        executable = Path(run([mise, 'exec', '--', 'rustup', 'which', 'rustc'], capture=True).strip())
        toolchains = Path(os.environ.get('RUSTUP_HOME', Path.home() / '.rustup')) / 'toolchains'
        if not executable.is_relative_to(toolchains) or not executable.relative_to(toolchains).parts[0].startswith(version + '-'):
            raise ValueError('Rust does not resolve to the selected mise/rustup toolchain.')
    else:
        executable = Path(run([mise, 'which', command], capture=True).strip())
        if not executable.is_relative_to(Path.home() / '.local/share/mise/installs'):
            raise ValueError(f'{command} resolves outside its selected mise owner.')
    return executable


def version_output(mise, command):
    # Version commands may create state. Probe with temporary application state,
    # leaving existing Ansible/Azure/Bitwarden credentials and configuration alone.
    with tempfile.TemporaryDirectory(prefix='dotfiles-version-') as temporary:
        scratch = Path(temporary)
        variables = {'ansible': {'ANSIBLE_LOCAL_TEMP': str(scratch / 'ansible')},
                     'az': {'AZURE_CONFIG_DIR': str(scratch / 'azure'),
                            'AZURE_CORE_COLLECT_TELEMETRY': 'false'},
                     'bw': {'BITWARDENCLI_APPDATA_DIR': str(scratch / 'bitwarden')},
                     'k9s': {'K9S_CONFIG_DIR': str(scratch / 'k9s')},
                     'kubectl': {'KUBECONFIG': str(scratch / 'no-cluster-config')}}
        environment = dict(os.environ, **variables.get(command, {}))
        return run([mise, 'exec', '--', command, *VERSION_ARGUMENTS.get(command, ['--version'])],
                   capture=True, timeout=60, env=environment, noninteractive=True).strip()
