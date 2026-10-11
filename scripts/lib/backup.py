"""Private, targeted snapshots. Never copy an entire home or export credentials."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil


def backup_targets(home, targets, diff, platform):
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
    (destination / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (destination / 'before.diff').write_text(diff)
    for path in destination.glob('*'):
        if path.is_file():
            path.chmod(0o600)
    (destination / 'RESTORE.md').write_text('Restore only paths listed in manifest.json from files/, preserving permissions and symlinks. Paths with exists=false were newly created; remove only those managed destinations. This restores configuration, not installed binaries.\n')
    (destination / 'RESTORE.md').chmod(0o600)
    return destination
