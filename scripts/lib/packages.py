"""One OS prerequisite inventory; CLI versions stay in the global mise files."""
from pathlib import Path
import shutil
import subprocess
import tempfile
from lib.runtime import administrative_command, run
from lib.desktop import install_opensuse_packages

BASE = {
    'ubuntu': ['git', 'zsh', 'tmux', 'tar', 'gzip', 'unzip', 'xz-utils', 'bzip2', 'perl', 'gawk', 'util-linux', 'ncurses-bin', 'libstdc++6', 'bash-completion'],
    'fedora': ['git', 'zsh', 'tmux', 'tar', 'gzip', 'unzip', 'xz', 'bzip2', 'perl', 'gawk', 'util-linux', 'util-linux-script', 'findutils', 'ncurses', 'libstdc++'],
    'arch': ['git', 'zsh', 'tmux', 'tar', 'gzip', 'unzip', 'xz', 'bzip2', 'perl', 'gawk', 'util-linux', 'ncurses', 'bash-completion'],
    'opensuse-tumbleweed': ['git-core', 'zsh', 'tmux', 'tar', 'gzip', 'unzip', 'xz', 'bzip2', 'perl', 'gawk', 'util-linux', 'ncurses-utils', 'bash-completion'],
}
DESKTOP = {
    'fedora': ['wl-clipboard', 'gcc', 'gcc-c++', 'make', 'bash-completion', 'dnf5-plugins'],
    'ubuntu': ['wl-clipboard', 'build-essential'],
    'arch': ['wl-clipboard', 'base-devel'],
    'opensuse-tumbleweed': ['wl-clipboard', 'gcc', 'gcc-c++', 'make'],
}


def prepare_packages(host, *, desktop=False):
    if host.system == 'macos':
        run(['xcode-select', '-p'], capture=True)
        return
    packages = BASE[host.distribution] + (DESKTOP.get(host.distribution, []) if desktop else [])
    if host.distribution in {'ubuntu', 'fedora'}:
        manager = 'apt' if host.distribution == 'ubuntu' else 'dnf'
        # A private standalone config avoids inheriting unrelated bootstrap sections.
        with tempfile.TemporaryDirectory(prefix='dotfiles-packages-') as temporary:
            config = Path(temporary) / 'mise.toml'
            config.write_text('[bootstrap.packages]\n' + ''.join(f'"{manager}:{name}" = "latest"\n' for name in packages))
            run(['mise', 'trust', config])
            command = ['mise', '-C', temporary, 'bootstrap', 'packages', 'apply']
            if manager == 'apt':
                # Existing complete environments need no elevated metadata refresh.
                # An unpacked/absent package still needs normal APT preparation.
                missing = any(subprocess.run(
                    ['dpkg-query', '-W', '-f=${db:Status-Status}', name],
                    capture_output=True, text=True).stdout.strip() != 'installed'
                    for name in packages)
                if missing:
                    run(administrative_command(['apt-get', 'update']))
            run(command)
    elif host.distribution == 'arch':
        missing = [name for name in packages if subprocess.run(['pacman', '-Q', name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode]
        if missing:
            if not any(Path('/var/lib/pacman/sync').glob('*.db')):
                raise ValueError('Arch package databases are absent. Run a full pacman -Syu first; never -Sy alone.')
            run(administrative_command(['pacman', '-S', '--needed', '--noconfirm', *missing]))
    else:
        # Minimal openSUSE images already provide busybox awk. No GNU-only awk
        # feature is required; avoid replacing its existing package/provider.
        if shutil.which('awk'):
            packages = [name for name in packages if name != 'gawk']
        missing = [name for name in packages if subprocess.run(['rpm', '-q', name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode]
        if missing:
            install_opensuse_packages(missing)
