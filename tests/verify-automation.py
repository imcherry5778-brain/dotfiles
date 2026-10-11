#!/usr/bin/env python3
"""Exercise real chezmoi init/apply, script order, dry-run and read-only lock isolation.

Provider installation is tested separately in hosted cold installs. This probe
never installs tools or targets the real user home.
"""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[1]


def run(args):
    result = subprocess.run(list(map(str, args)), capture_output=True, text=True, timeout=45)
    if result.returncode:
        raise RuntimeError(result.stderr + result.stdout)
    return result.stdout


def verify(chezmoi):
    with tempfile.TemporaryDirectory(prefix='chezmoi automation with spaces ') as temporary:
        scratch = Path(temporary); source = scratch / 'source with spaces'; home = scratch / 'home'
        shutil.copytree(ROOT, source, ignore=shutil.ignore_patterns('.git','__pycache__'))
        home.mkdir(); run(['git','init','--quiet',source])
        trace = scratch / 'trace.jsonl'; probe = scratch / 'probe.py'
        probe.write_text('''import importlib.util, json, pathlib, sys, tempfile
context = json.load(sys.stdin)
source = pathlib.Path(context['source'])
spec = importlib.util.spec_from_file_location('installer', source / 'scripts/unix/install.py')
installer = importlib.util.module_from_spec(spec); spec.loader.exec_module(installer)
installer.USER_HOME = pathlib.Path(context['destination'])
with tempfile.TemporaryDirectory() as scratch:
    reader = installer.ReviewReader(context, pathlib.Path(scratch) / 'query-state')
    managed = reader.managed()
    assert '.zshrc' in managed
    reader.query('diff', '--exclude=scripts,externals')
    if sys.argv[1] == 'after':
        reader.query('verify', '--exclude=scripts,externals')
with pathlib.Path(sys.argv[2]).open('a') as stream:
    stream.write(json.dumps({'stage':sys.argv[1], 'profile':context['profile']}) + '\\n')
''')
        # Keep the production script templates. Replace only the provider runner
        # in this disposable checkout to observe orchestration without installations.
        import shlex, sys
        (source / 'scripts/unix/stage.sh').write_text('#!/bin/sh\nexec ' + shlex.join([sys.executable, str(probe)]) + ' "$1" ' + shlex.quote(str(trace)) + '\n')
        config = scratch / 'config.toml'
        base = [chezmoi,'--source',source,'--destination',home,'--config',config,
                '--cache',scratch/'cache','--persistent-state',scratch/'parent-state','--no-tty','--no-pager']
        override = scratch / 'profile.json'
        profile = json.loads((source/'tests/profiles/fedora-full.json').read_text())
        profile['deployment']['externals'] = False
        profile['chezmoi'] = {'os':'linux','osRelease':{'id':'fedora'}}
        override.write_text(json.dumps(profile))
        base += ['--override-data-file',override]
        run([*base,'init','--apply'])
        events = [json.loads(line) for line in trace.read_text().splitlines()]
        assert [event['stage'] for event in events] == ['before','after']
        assert tomllib.loads(config.read_text())['data']['automation']['enabled'] is True
        for args in [['diff'], ['apply','--dry-run'], ['apply','--dry-run','--verbose']]:
            run([*base,*args])
            assert trace.read_text().count('\n') == 2, 'Read-only operation ran provider stages.'
        run([*base,'apply'])
        assert trace.read_text().count('\n') == 4, 'Plain apply skipped reconciliation.'
        run([*base,'verify','--exclude=scripts'])
        assert not run([*base,'diff','--exclude=scripts']).strip()
        # Same init --apply must preserve unmanaged chezmoi options and custom data.
        with config.open('a') as stream:
            stream.write('\n[diff]\npager = ""\n[data.custom]\nretained = "existing"\n')
        run([*base,'init','--apply'])
        document = tomllib.loads(config.read_text())
        assert document['data']['custom']['retained'] == 'existing'
        assert document['diff']['pager'] == ''
        assert trace.read_text().count('\n') == 6
        # A disabled init preview can subsequently opt into a native full install.
        preview_home = scratch / 'preview home'; preview_home.mkdir()
        preview_config = scratch / 'preview-config.toml'
        preview_base = [chezmoi, '--source', source, '--destination', preview_home,
                        '--config', preview_config, '--cache', scratch / 'preview-cache',
                        '--persistent-state', scratch / 'preview-state', '--no-tty', '--no-pager']
        run([*preview_base, 'init'])
        assert not tomllib.loads(preview_config.read_text())['data']['deployment']['enabled']
        # Disable upstream declarations only in this disposable native-choice probe.
        (source / 'home/.chezmoiexternal.toml.tmpl').write_text('')
        # Exclude external entries via the official init filter; the actual native
        # full profile still selects them for a real installation.
        run([*preview_base, 'init', '--apply', '--exclude=externals'])
        selected = tomllib.loads(preview_config.read_text())['data']
        assert selected['deployment']['enabled'] and selected['automation']['enabled']
        assert selected['features']['desktop'] and selected['features']['ai']
        # An explicit profile replacement must fail before replacing machine config.
        original = config.read_bytes()
        profile['features']['desktop'] = False; override.write_text(json.dumps(profile))
        result = subprocess.run(list(map(str,[*base,'init','--apply'])), capture_output=True, text=True)
        assert result.returncode != 0 and 'selection differs' in result.stderr
        assert config.read_bytes() == original
    print('chezmoi: before/after, repeat reconciliation, dry-run, separate read-only state and selection conflict passed.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(); parser.add_argument('--chezmoi', required=True)
    args = parser.parse_args()
    if os.name == 'nt':
        raise SystemExit('Unix orchestration probe; native Windows orchestration runs in hosted installation CI.')
    verify(args.chezmoi)
