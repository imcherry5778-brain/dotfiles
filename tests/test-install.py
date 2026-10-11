#!/usr/bin/env python3
"""Cold install acceptance test. Refuses to run outside the disposable CI container."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import pwd
import shlex
import shutil
import stat
import subprocess
import tempfile
import time
import tomllib

ROOT = Path(__file__).resolve().parents[1]
USER_HOME = Path.home()
RELEASE = dict(line.split('=', 1) for line in Path('/etc/os-release').read_text().splitlines() if '=' in line)
TARGET = RELEASE.get('ID', '').strip('"')
FULL = os.environ.get('DOTFILES_FULL_INSTALL') == '1'
PROFILE = ROOT / 'tests/profiles' / (f'{TARGET}-full.json' if FULL else f'{TARGET}-desktop.json' if TARGET in {'ubuntu', 'arch', 'opensuse-tumbleweed'} else 'fedora-common.json')


def run(argv, *, capture=True, timeout=900, env=None):
    try:
        result = subprocess.run([str(x) for x in argv], check=True, text=True,
                                stdout=subprocess.PIPE if capture else None,
                                cwd=USER_HOME, timeout=timeout, env=env)
    except subprocess.CalledProcessError as error:
        if error.stdout:
            print(error.stdout, flush=True)
        raise
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
        cases = [dict(profile, platform='unsupported-linux'), dict(profile, deployment={'enabled': False, 'externals': True}),
                 dict(profile, features=dict(profile['features'], personal_fedora=True)),
                 dict(profile, machine={'home': '/wrong'}),
                 dict(profile, features=dict(profile['features'], ai=not profile['features']['ai'])),
                 dict(profile, features=dict(profile['features'], delta=0))]
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
set -ex
[[ $ZSH_THEME == robbyrussell && $HISTSIZE == 50000 && $SAVEHIST == 50000 ]]
[[ $EDITOR == nvim && $VISUAL == nvim && $SUDO_EDITOR == $HOME/.local/share/mise/installs/* ]]
[[ ${aliases[vi]} == nvim && ${aliases[y]} == yazi ]]
[[ ${#plugins} == EXPECTED_PLUGINS && $plugins[-1] == zsh-syntax-highlighting ]]
(( $+functions[__zoxide_z] && $+widgets[fzf-history-widget] && $+widgets[history-substring-search-up] ))
[[ $(bindkey '^X^H') == *stash-to-history* ]]
[[ $(bindkey '^[OA') == *history-substring-search-up* ]]
for binary in rg fd bat jq carapace delta fzf zoxide gh lazygit nvim yazi uv; do
  [[ $(command -v $binary) == $HOME/.local/share/mise/installs/* ]]
done
[[ $(printf '%s\n' $path | sort | uniq -d) == '' ]]
print 'ZSH_RUNTIME_OK'
"""
    code = code.replace('EXPECTED_PLUGINS', '11' if FULL or TARGET in {'ubuntu', 'arch', 'opensuse-tumbleweed'} else '10')
    if FULL or TARGET in {'ubuntu', 'arch', 'opensuse-tumbleweed'}:
        code += r'''
(( $+functions[_sc_carapace_base] ))
[[ $(command -v node) == $HOME/.local/share/mise/installs/* ]]
[[ $(command -v opencode) == $HOME/.local/share/mise/installs/* ]]
'''
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
                keys = run(tmux + ['list-keys'], env=env)
                ready = 'copycat' in keys and 'resurrect' in keys and 'update_plugins' in keys
                busy = run(tmux + ['show-options', '-sqv', '@__apply_plugins'], env=env).strip()
                if ready and not busy:
                    break
                time.sleep(0.1)
            require(ready and not busy, 'TPM did not initialize its plugin/update key bindings.')
            require(run(tmux + ['show-options', '-gqv', 'prefix'], env=env).strip() == 'C-Space', 'tmux prefix changed.')
            require(run(tmux + ['show-options', '-gqv', 'mouse'], env=env).strip() == 'on', 'tmux mouse disabled.')
            keys = run(tmux + ['list-keys'], env=env)
            require('copycat' in keys and 'resurrect' in keys, 'Configured tmux plugin key bindings missing.')
        finally:
            subprocess.run(tmux + ['kill-server'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=env, timeout=15)


def bash_state():
    code = r"""
printf 'STATE_START\n'
complete -p
alias ll la l
printf 'HISTORY:%s:%s:%s\n' "$HISTCONTROL" "$HISTSIZE" "$HISTFILESIZE"
shopt -p histappend checkwinsize
:
"""
    if TARGET == 'arch':
        code = code.replace('alias ll la l', 'alias ls grep')
    return run(['bash', '--noprofile', '-ic', code])


def verify_native_bash(before, originals):
    after = bash_state()
    require(sum(line.startswith('complete ') for line in after.splitlines()) >= 100,
            'Installer did not prepare native Bash completions.')
    for line in before.splitlines():
        require(line in after.splitlines(), f'{TARGET} Bash behavior lost: {line}')
    for name in originals.keys() - {'.bashrc'}:
        require((USER_HOME / name).read_bytes() == originals[name], f'{TARGET} {name} was replaced.')
    content = (USER_HOME / '.bashrc').read_bytes()
    require(content.startswith(originals['.bashrc']), 'Native original Bash configuration was overwritten.')
    require(content.count(b'source "$HOME/.config/shell/bashrc.bash"') == 1, 'Native Bash module duplicated.')
    code = r"""
set -e
[[ $PRESERVED_CLI == yes && $EDITOR == nvim && $VISUAL == nvim ]]
[[ $(alias preserved_cli) == *retained* ]]
declare -F _sc_carapace_bash
[[ $(bind -X) == *__fzf_history__* ]]
declare -F __zoxide_z
printf 'NATIVE_BASH_OK\n'
"""
    require('NATIVE_BASH_OK' in run(['bash', '--noprofile', '-ic', code]), 'Native CLI shell module did not initialize.')


def main():
    require(Path('/.dockerenv').exists() and os.geteuid() != 0, 'Run only in the disposable non-root Docker test user.')
    require(pwd.getpwuid(os.getuid()).pw_name == 'dotfiles-test' and USER_HOME == Path('/home/dotfiles-test'), 'Unexpected test user/home.')
    require(' ' in str(ROOT), 'Checkout path must exercise spaces.')
    require(TARGET in {'fedora', 'ubuntu', 'arch', 'opensuse-tumbleweed'}, 'Unexpected container distribution.')
    # Distribution useradd may copy OS shell defaults from /etc/skel; those are legitimate inputs.
    require(not (USER_HOME / '.config/chezmoi').exists() and not (USER_HOME / '.config/mise').exists(), 'Cold installation requires no prior dotfiles selection.')
    # Python is only the acceptance-test runtime; no OS prerequisite installer ran.
    require(shutil.which('zsh') is None, 'Cold image must not preinstall the managed shell prerequisite.')
    verify_guards()
    original_shell = pwd.getpwuid(os.getuid()).pw_shell
    native_original = None
    if TARGET in {'ubuntu', 'arch', 'opensuse-tumbleweed'}:
        native_original = {name: (USER_HOME / name).read_bytes() for name in (['.bashrc', '.profile', '.bash_logout'] if TARGET == 'ubuntu' else ['.bashrc', '.bash_profile'] if TARGET == 'arch' else ['.bashrc', '.profile'])}
        with (USER_HOME / '.bashrc').open('a') as stream:
            stream.write("\n# User customization retained across installation.\nalias preserved_cli='printf retained'\nexport PRESERVED_CLI=yes\n")
        native_original['.bashrc'] = (USER_HOME / '.bashrc').read_bytes()
        native = bash_state()
        native_count = sum(line.startswith('complete ') for line in native.splitlines())
        # Minimal images may lack bash-completion. Preserve all existing behavior
        # and assert the installer adds the native completion package afterward.
    run(['git', '-c', 'init.templateDir=', 'init', '--quiet', '--initial-branch=main', ROOT])
    # Ordinary, non-secret pre-existing settings must survive the actual installer.
    identity = '[user]\n name = CI Existing User\n email = ci@example.invalid\n[commit]\n gpgsign = false\n[acceptance]\n keep = existing\n'
    (USER_HOME / '.gitconfig').write_text(identity)
    gh_config = USER_HOME / '.config/gh/config.yml'
    gh_config.parent.mkdir(parents=True)
    if TARGET in {'ubuntu', 'arch', 'opensuse-tumbleweed'}:
        for relative in ['.config', '.local', '.local/share']:
            directory = USER_HOME / relative
            directory.mkdir(parents=True, exist_ok=True)
            directory.chmod(0o700)
    gh_config.write_text('editor:\nbrowser:\naliases:\n  retained: repo view\n# retained comment\n')
    if FULL:
        spec = importlib.util.spec_from_file_location('installer_binary', ROOT / 'scripts/unix/install.py')
        module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        chezmoi = module.pinned_binary('chezmoi', ROOT / 'tests/chezmoi-release.json', 'twpayne/chezmoi')
        command = [chezmoi, '--source', ROOT, 'init', '--apply']
    else:
        command = ['sh', ROOT / 'install.sh', '--apply', '--profile', PROFILE]
    run(command, capture=False)
    base = [USER_HOME / '.local/bin/chezmoi', '--no-tty', '--no-pager']
    data = json.loads(run(base + ['data', '--format=json']))
    require(Path(data['chezmoi']['workingTree']) == ROOT, 'Persisted config does not point to the real checkout.')
    require(data['deployment'] == json.loads(PROFILE.read_text())['deployment'], 'Native initialization chose the wrong deployment.')
    expected_features = json.loads(PROFILE.read_text())['features']
    require(all(data['features'].get(key) == value for key, value in expected_features.items()),
            'Native initialization chose the wrong feature selection.')
    mise = USER_HOME / '.local/bin/mise'
    tools = tomllib.loads((USER_HOME / '.config/mise/config.toml').read_text())['tools']
    require(len(tools) == 13, 'Expected the common 13-tool inventory, not a personal environment.')
    editor_env = 'editor-ubuntu' if TARGET == 'ubuntu' else 'editor-web'
    expected_env = ['ai', 'ai-managed', editor_env] if FULL else ['ai', editor_env] if TARGET in {'ubuntu', 'arch', 'opensuse-tumbleweed'} else []
    require(tomllib.loads((USER_HOME / '.config/mise/miserc.toml').read_text())['env'] == expected_env, 'Wrong mise environments selected.')
    if FULL or TARGET in {'ubuntu', 'arch', 'opensuse-tumbleweed'}:
        for name in [environment for environment in expected_env if environment != 'personal-fedora']:
            extras = tomllib.loads((USER_HOME / f'.config/mise/config.{name}.toml').read_text())['tools']
            require(not set(extras) & set(tools), 'Duplicate tool owners.')
            tools.update(extras)
        require(len(tools) == (22 if FULL else 15), 'Wrong desktop tool inventory.')
        if native_original:
            verify_native_bash(native, native_original)
    installed = json.loads(run([mise, 'ls', '--current', '--json']))
    require(set(installed) == set(tools), 'Installed tool selection differs from the single config inventory.')
    commands = {'ripgrep': 'rg', 'neovim': 'nvim', 'npm:@earendil-works/pi-coding-agent': 'pi',
                'pipx:aider-chat': 'aider', 'http:kiro-cli': 'kiro-cli'}
    versions = {}
    for tool, specification in tools.items():
        version = specification['version'] if isinstance(specification, dict) else specification
        require(any(item['version'] == version and item['installed'] for item in installed[tool]), f'{tool} was not installed at its declared version.')
        binary = commands.get(tool, tool)
        resolved = Path(run([mise, 'which', binary]).strip())
        require(resolved.is_relative_to(USER_HOME / '.local/share/mise/installs') and resolved.is_file(), f'{tool} resolved to a preinstalled system executable.')
        output = run([mise, 'exec', '--', binary, '--version'], timeout=60)
        require(version in output, f'{tool} version output does not match {version}.')
        versions[tool] = version
    if FULL:
        run(['ghostty', '--version'], timeout=30)
        if TARGET == 'fedora':
            run(['rpm', '-q', 'orca-ide'])
        elif TARGET == 'ubuntu':
            require(run(['dpkg-query', '-W', '-f=${db:Status-Status}', 'orca-ide']).strip() == 'installed', 'Orca native package missing.')
        else:
            output = run([USER_HOME / '.local/bin/orca-ide', '--version'], timeout=30)
            require('1.4.224' in output, 'Orca bundled CLI version missing.')
            require((USER_HOME / '.local/share/applications/orca-ide.desktop').is_file(), 'Orca desktop launcher missing.')
    # CLI installation may need the read-only job token; runtime checks do not.
    runtime_env = dict(os.environ)
    runtime_env.pop('GITHUB_TOKEN', None)
    before_runtime = snapshot(base)
    verify_shell(runtime_env)
    verify_tmux(runtime_env)
    # Load no editor plugins here: verify real Neovim and the deployed Lua syntax separately.
    for lua in (USER_HOME / '.config/nvim').rglob('*.lua'):
        run([mise, 'exec', '--', 'nvim', '--headless', '-u', 'NONE', '-i', 'NONE',
             '-c', 'lua if not loadfile(' + json.dumps(str(lua)) + ') then vim.cmd("cquit 1") end', '-c', 'qa'], env=runtime_env, timeout=30)
    require(snapshot(base) == before_runtime, 'Reading/starting shells altered managed configuration.')
    run(base + ['apply'], capture=False)
    require(snapshot(base) == before_runtime, 'Second installation changed managed file contents, links or modes.')
    # A damaged installed version is repaired, not merely a missing version directory.
    fd = Path(run([mise, 'which', 'fd']).strip())
    fd.unlink()
    run(base + ['apply'], capture=False)
    require(fd.is_file(), 'apply did not restore a deleted selected CLI binary.')
    require(snapshot(base) == before_runtime, 'Repair altered managed configuration.')
    run(base + ['verify', '--exclude=scripts'])
    require(not run(base + ['diff', '--exclude=scripts']).strip(), 'Second installation still has a configuration diff.')
    for key, expected in [('user.name', 'CI Existing User'), ('user.email', 'ci@example.invalid'), ('commit.gpgsign', 'false'), ('acceptance.keep', 'existing')]:
        require(run(['git', 'config', '--get', key]).strip() == expected, f'Existing Git setting lost: {key}')
    require('retained: repo view' in gh_config.read_text() and '# retained comment' in gh_config.read_text(), 'Unmanaged gh settings lost.')
    for relative, mode in [('.config/gh', 0o700), ('.config/gh/config.yml', 0o600), ('.local/share', 0o700)]:
        require(stat.S_IMODE((USER_HOME / relative).stat().st_mode) == mode, f'Wrong private mode: {relative}')
    if TARGET in {'ubuntu', 'arch', 'opensuse-tumbleweed'}:
        verify_native_bash(native, native_original)
        for relative in ['.config', '.local', '.local/share']:
            require(stat.S_IMODE((USER_HOME / relative).stat().st_mode) == 0o700, f'{TARGET} private directory changed: {relative}')
        require(pwd.getpwuid(os.getuid()).pw_shell == original_shell, 'Installer silently changed the login shell.')
    print(json.dumps({'native_completion_specs': native_count if TARGET in {'ubuntu', 'arch', 'opensuse-tumbleweed'} else None,
                      'result': 'passed', 'platform': TARGET + RELEASE.get('VERSION_ID', '-rolling').strip(chr(34)), 'tools': versions,
                      'managed_paths': len(before_runtime), 'installs': 2,
                      'runtime': ['interactive-zsh', 'tmux-and-plugins', f'{len(tools)}-cli-version-commands', 'neovim-lua-syntax'],
                      'excluded': ['authentication', 'gui', 'neovim-plugin-installation', 'personal-fedora-tools']}, indent=2), flush=True)


if __name__ == '__main__':
    main()
