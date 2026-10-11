"""Private, targeted snapshots. Never copy an entire home or export credentials."""
from contextlib import contextmanager
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile


def backup_targets(home, targets, diff, platform, *, directories=()):
    destination = home / '.local/state/dotfiles/backups' / (datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ') + '-' + platform)
    destination.mkdir(parents=True, mode=0o700)
    destination.chmod(0o700)
    manifest = []
    for relative in sorted(set(targets)):
        path = home / relative
        if path.is_absolute() and not path.relative_to(home).parts:
            raise ValueError('Cannot back up the entire home.')
        if Path(relative).is_absolute() or '..' in Path(relative).parts:
            raise ValueError(f'Invalid managed path: {relative}')
        exists = path.exists() or path.is_symlink()
        entry = {'path': relative, 'exists': exists}
        if exists:
            saved = destination / 'files' / relative
            saved.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            if path.is_symlink():
                saved.symlink_to(os.readlink(path))
                entry['symlink'] = os.readlink(path)
            elif path.is_file():
                shutil.copy2(path, saved)
                entry['sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
                entry['mode'] = path.stat().st_mode & 0o777
            else:
                raise ValueError(f'Managed file is a directory: {relative}')
        manifest.append(entry)
    for relative in sorted(set(directories)):
        path = home / relative
        if Path(relative).is_absolute() or not Path(relative).parts or '..' in Path(relative).parts:
            raise ValueError(f'Invalid managed directory: {relative}')
        if path.exists() and (not path.is_dir() or path.is_symlink()):
            raise ValueError(f'Managed directory conflicts with an existing file/link: {relative}')
        entry = {'path': relative, 'directory': True, 'exists': path.exists()}
        if path.exists():
            entry['mode'] = path.stat().st_mode & 0o777
        manifest.append(entry)
    (destination / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (destination / 'before.diff').write_text(diff)
    for path in destination.glob('*'):
        if path.is_file():
            path.chmod(0o600)
    (destination / 'RESTORE.md').write_text('Restore only paths listed in manifest.json from files/, preserving permissions and symlinks. Directory entries record permissions only, never their full contents. Paths with exists=false were newly created; remove only those managed files and empty managed directories. This restores configuration, not installed binaries.\n')
    (destination / 'RESTORE.md').chmod(0o600)
    return destination


@contextmanager
def preserve_installer_loaders(home, managed):
    """Guard only managed shell loaders around vendor installers, even on failure."""
    loaders = {'.bashrc', '.bash_profile', '.zshrc', '.zprofile',
               'Documents/PowerShell/profile.ps1',
               'Documents/PowerShell/Microsoft.PowerShell_profile.ps1'}
    with tempfile.TemporaryDirectory(prefix='dotfiles-loader-guard-') as temporary:
        saved = Path(temporary)
        for relative in managed & loaders:
            original = home / relative
            if original.is_symlink():
                raise ValueError(f'Vendor installer loader is a symlink: {relative}')
            if original.is_file():
                target = saved / relative; target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(original, target)
        try:
            yield
        finally:
            for target in saved.rglob('*'):
                if target.is_file():
                    original = home / target.relative_to(saved)
                    if original.is_symlink():
                        original.unlink()
                    shutil.copy2(target, original)
