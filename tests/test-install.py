#!/usr/bin/env python3
"""Cold install acceptance test. Refuses to run outside the disposable CI container."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import pwd
import shlex
import stat
import subprocess
import tempfile
import time
import tomllib

ROOT = Path(__file__).resolve().parents[1]
USER_HOME = Path.home()
PROFILE = ROOT / 'tests/profiles/fedora-common.json'


def run(argv, *, capture=True, timeout=900, env=None):
    result = subprocess.run([str(x) for x in argv], check=True, text=True,
                            stdout=subprocess.PIPE if capture else None,
                            cwd=USER_HOME, timeout=timeout, env=env)
    return result.stdout


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def snapshot(base):
    paths = run(base + ['managed', '--include=files,symlinks,dirs', '--path-style=relative']).splitlines()
    require(len(paths) > 20, 'Empty/disabled deployment must never pass installation checks.')
    result = {}
    for relative in paths:
        path = USER_HOME / relative
        mode = stat.S_IMODE(path.lstat().st_mode)
        if path.is_symlink():
            result[relative] = ('link', mode, os.readlink(path))
        elif path.is_dir():
            result[relative] = ('directory', mode)
        else:
            result[relative] = ('file', mode, hashlib.sha256(path.read_bytes()).hexdigest())
    return result


def verify_guards():
    spec = importlib.util.spec_from_file_location('installer', ROOT / 'scripts/unix/install.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    profile = json.loads(PROFILE.read_text())
    require(module.validate_profile(PROFILE) == profile, 'Valid installation profile rejected.')
    with tempfile.TemporaryDirectory() as temporary:
        invalid = Path(temporary) / 'invalid.json'
        cases = [dict(profile, platform='ubuntu'), dict(profile, deployment={'enabled': False, 'externals': True}),
                 dict(profile, features=dict(profile['features'], personal_fedora=True)),
                 dict(profile, machine={'home': '/wrong'})]
        for case in cases:
            invalid.write_text(json.dumps(case))
            try:
                module.validate_profile(invalid)
            except ValueError:
                pass
            else:
                raise AssertionError('Unsafe or incomplete installation profile accepted.')


def verify_shell(env):
    code = r"""
set -e
[[ $ZSH_THEME == robbyrussell && $HISTSIZE == 50000 && $SAVEHIST == 50000 ]]
[[ $EDITOR == nvim && $VISUAL == nvim && $SUDO_EDITOR == $HOME/.local/share/mise/installs/* ]]
[[ ${aliases[vi]} == nvim && ${aliases[y]} == yazi ]]
[[ ${#plugins} == 10 && $plugins[-1] == zsh-syntax-highlighting ]]
(( $+functions[_zoxide_z] && $+widgets[fzf-history-widget] && $+widgets[history-substring-search-up] ))
[[ $(bindkey '^X^H') == *stash-to-history* ]]
[[ $(bindkey '^[OA') == *history-substring-search-up* ]]
for binary in rg fd bat jq carapace delta fzf zoxide gh lazygit nvim yazi uv; do
  [[ $(command -v $binary) == $HOME/.local/share/mise/installs/* ]]
done
[[ $(printf '%s\n' $path | sort | uniq -d) == '' ]]
print 'ZSH_RUNTIME_OK'
"""
    output = run(['script', '--quiet', '--return', '--command', shlex.join(['zsh', '-lic', code]), '/dev/null'], env=env, timeout=60)
    require('ZSH_RUNTIME_OK' in output, 'Interactive Zsh did not finish its runtime assertions.')
    for name in ['.bashrc', '.zshrc']:
        run(['bash' if name == '.bashrc' else 'zsh', '-n', USER_HOME / name], env=env, timeout=30)


def verify_tmux(env):
    with tempfile.TemporaryDirectory(prefix='dotfiles-tmux-') as temporary:
        tmux = ['tmux', '-S', str(Path(temporary) / 'server.sock')]
        try:
            run(tmux + ['-f', USER_HOME / '.tmux.conf', 'new-session', '-d', '-s', 'acceptance', 'sleep 60'], env=env, timeout=30)
            for _ in range(100):
                ready = run(tmux + ['show-options', '-gqv', '@tpm-update'], env=env).strip()
                busy = run(tmux + ['show-options', '-sqv', '@__apply_plugins'], env=env).strip()
                if ready == 'u' and not busy:
                    break
                time.sleep(0.1)
            require(ready == 'u' and not busy, 'TPM did not initialize.')
            require(run(tmux + ['show-options', '-gqv', 'prefix'], env=env).strip() == 'C-Space', 'tmux prefix changed.')
            require(run(tmux + ['show-options', '-gqv', 'mouse'], env=env).strip() == 'on', 'tmux mouse disabled.')
            keys = run(tmux + ['list-keys'], env=env)
            require('copycat' in keys and 'resurrect' in keys and 'stash' not in keys, 'Configured tmux plugin key bindings missing.')
        finally:
            subprocess.run(tmux + ['kill-server'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=env, timeout=15)


def main():
    require(Path('/.dockerenv').exists() and os.geteuid() != 0, 'Run only in the disposable non-root Docker test user.')
    require(pwd.getpwuid(os.getuid()).pw_name == 'dotfiles-test' and USER_HOME == Path('/home/dotfiles-test'), 'Unexpected test user/home.')
    require(' ' in str(ROOT), 'Checkout path must exercise spaces.')
    require(not (USER_HOME / '.zshrc').exists() and not (USER_HOME / '.local/share/mise').exists(), 'Cold installation requires empty config and tool caches.')
    verify_guards()
    run(['git', '-c', 'init.templateDir=', 'init', '--quiet', '--initial-branch=main', ROOT])
    # Ordinary, non-secret pre-existing settings must survive the actual installer.
    identity = '[user]\n name = CI Existing User\n email = ci@example.invalid\n[commit]\n gpgsign = false\n[acceptance]\n keep = existing\n'
    (USER_HOME / '.gitconfig').write_text(identity)
    gh_config = USER_HOME / '.config/gh/config.yml'
    gh_config.parent.mkdir(parents=True)
    gh_config.write_text('editor:\nbrowser:\naliases:\n  retained: repo view\n# retained comment\n')
    command = ['sh', ROOT / 'install.sh', '--apply', '--profile', PROFILE]
    run(command, capture=False)
    base = [USER_HOME / '.local/bin/chezmoi', '--source', ROOT, '--no-tty', '--no-pager']
    mise = USER_HOME / '.local/bin/mise'
    tools = tomllib.loads((USER_HOME / '.config/mise/config.toml').read_text())['tools']
    require(len(tools) == 13, 'Expected the common 13-tool inventory, not a personal environment.')
    require(tomllib.loads((USER_HOME / '.config/mise/miserc.toml').read_text())['env'] == [], 'Unexpected personal/AI environment selected.')
    installed = json.loads(run([mise, 'ls', '--current', '--json']))
    require(set(installed) == set(tools), 'Installed tool selection differs from the single config inventory.')
    commands = {'ripgrep': 'rg', 'neovim': 'nvim'}
    versions = {}
    for tool, version in tools.items():
        require(any(item['version'] == version and item['installed'] for item in installed[tool]), f'{tool} was not installed at its declared version.')
        binary = commands.get(tool, tool)
        resolved = Path(run([mise, 'which', binary]).strip())
        require(resolved.is_relative_to(USER_HOME / '.local/share/mise/installs') and resolved.is_file(), f'{tool} resolved to a preinstalled system executable.')
        output = run([mise, 'exec', '--', binary, '--version'], timeout=60)
        require(version in output, f'{tool} version output does not match {version}.')
        versions[tool] = version
    # CLI installation may need the read-only job token; runtime checks do not.
    runtime_env = dict(os.environ)
    runtime_env.pop('GITHUB_TOKEN', None)
    before_runtime = snapshot(base)
    verify_shell(runtime_env)
    verify_tmux(runtime_env)
    # Load no editor plugins here: verify real Neovim and the deployed Lua syntax separately.
    for lua in (USER_HOME / '.config/nvim').rglob('*.lua'):
        run([mise, 'exec', '--', 'nvim', '--headless', '-u', 'NONE', '-i', 'NONE',
             '-c', 'lua assert(loadfile(' + json.dumps(str(lua)) + '))', '-c', 'qa'], env=runtime_env, timeout=30)
    require(snapshot(base) == before_runtime, 'Reading/starting shells altered managed configuration.')
    run(command, capture=False)
    require(snapshot(base) == before_runtime, 'Second installation changed managed file contents, links or modes.')
    run(base + ['verify'])
    require(not run(base + ['diff']).strip(), 'Second installation still has a configuration diff.')
    for key, expected in [('user.name', 'CI Existing User'), ('user.email', 'ci@example.invalid'), ('commit.gpgsign', 'false'), ('acceptance.keep', 'existing')]:
        require(run(['git', 'config', '--get', key]).strip() == expected, f'Existing Git setting lost: {key}')
    require('retained: repo view' in gh_config.read_text() and '# retained comment' in gh_config.read_text(), 'Unmanaged gh settings lost.')
    for relative, mode in [('.config/gh', 0o700), ('.config/gh/config.yml', 0o600), ('.local/share', 0o700)]:
        require(stat.S_IMODE((USER_HOME / relative).stat().st_mode) == mode, f'Wrong private mode: {relative}')
    print(json.dumps({'result': 'passed', 'platform': 'fedora44', 'tools': versions,
                      'managed_paths': len(before_runtime), 'installs': 2,
                      'runtime': ['interactive-zsh', 'tmux-and-plugins', '13-cli-version-commands', 'neovim-lua-syntax'],
                      'excluded': ['authentication', 'gui', 'neovim-plugin-installation', 'personal-and-ai-environments']}, indent=2), flush=True)


if __name__ == '__main__':
    main()
