#!/usr/bin/env python3
"""Reviewed renders of the five existing profiles; run in disposable Unix homes."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / 'tests/profile-regression.json'


def run(arguments):
    return subprocess.run(list(map(str, arguments)), check=True, capture_output=True, text=True).stdout


def snapshot(source, chezmoi):
    result = {}
    for target in ['fedora', 'ubuntu', 'arch', 'opensuse-tumbleweed', 'windows']:
        with tempfile.TemporaryDirectory(prefix='profile regression with spaces ') as temporary:
            scratch = Path(temporary); home = scratch / 'home'; home.mkdir()
            if target == 'fedora':
                profile = {'platform': target, 'deployment': {'enabled': True, 'externals': False},
                           'features': {'ai': True, 'conda': True, 'personal_fedora': True,
                                        'bitwarden_agent': True, 'delta': False, 'editor_web': True}}
            else:
                profile = json.loads((source / f'tests/profiles/{target}-full.json').read_text())
                profile['deployment']['externals'] = False
            profile['chezmoi'] = {'os': 'windows' if target == 'windows' else 'linux',
                                  'homeDir': str(home), 'osRelease': {'id': target}}
            override = scratch / 'profile.json'; override.write_text(json.dumps(profile))
            config = scratch / 'config.toml'
            base = [chezmoi, '--source', source, '--destination', home, '--config', config,
                    '--override-data-file', override, '--cache', scratch / 'cache',
                    '--persistent-state', scratch / 'state', '--no-tty', '--no-pager']
            config.write_text(run(base + ['execute-template', '--init', '--file', source / 'home/.chezmoi.toml.tmpl']))
            run(base + ['apply'])
            rendered = {}
            for path in sorted(home.rglob('*')):
                if not path.is_file():
                    continue
                text = path.read_text().replace(str(home), '<HOME>').replace(str(source), '<SOURCE>')
                # Ignore formatting-only blank lines introduced by conditional platform branches.
                text = '\n'.join(line for line in text.splitlines() if line.strip())
                # Fedora ai-cli/sys-update move the OpenCode pin; keep this baseline version-independent.
                text = re.sub(r'(?m)^(opencode|"github:anomalyco/opencode") = "[^"]+"$', r'\1 = "<reviewed-opencode>"', text)
                rendered[str(path.relative_to(home))] = hashlib.sha256(text.encode()).hexdigest()
            result[target] = rendered
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--chezmoi', required=True)
    parser.add_argument('--baseline-source', type=Path, help='Explicit reviewed source used to record the baseline.')
    args = parser.parse_args()
    if args.baseline_source:
        GOLDEN.write_text(json.dumps(snapshot(args.baseline_source, args.chezmoi), indent=2, sort_keys=True) + '\n')
    else:
        expected = json.loads(GOLDEN.read_text()); actual = snapshot(ROOT, args.chezmoi)
        changed = [f'{platform}/{path}' for platform in expected for path in set(expected[platform]) | set(actual[platform])
                   if expected[platform].get(path) != actual[platform].get(path)]
        if changed:
            raise SystemExit('Existing profile render/provider regression:\n' + '\n'.join(sorted(changed)))
        print('Five existing profiles: reviewed target list, rendered configuration and providers unchanged.')
