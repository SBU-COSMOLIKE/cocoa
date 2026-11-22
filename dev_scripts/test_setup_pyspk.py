"""Test the real pyspk setup script against temporary local Git repositories.

No GitHub access or Cocoa installation is needed. The shell stubs only supply
Cocoa's logging/environment helpers; clone/fetch/checkout use real Git.
"""
from pathlib import Path
import os
import subprocess
import tempfile

SCRIPT = Path(__file__).resolve().parents[1] / 'Cocoa/installation_scripts/setup_pyspk.sh'


def git(folder, *args):
    return subprocess.check_output(['git', '-C', str(folder), *args], text=True).strip()


with tempfile.TemporaryDirectory() as temporary:
    base = Path(temporary)
    remote = base / 'remote'
    remote.mkdir()
    git(remote, 'init', '-q')
    git(remote, 'config', 'user.name', 'Test')
    git(remote, 'config', 'user.email', 'test@example.invalid')
    (remote / 'value').write_text('first')
    git(remote, 'add', 'value')
    git(remote, 'commit', '-qm', 'first')
    first = git(remote, 'rev-parse', 'HEAD')
    (remote / 'value').write_text('second')
    git(remote, 'commit', '-qam', 'second')
    tip = git(remote, 'rev-parse', 'HEAD')
    wrapper = base / 'git-wrapper'
    wrapper.write_text('''#!/bin/bash
if [ "$1" = fetch ]; then
  echo fetch >> "$FETCH_LOG"
  if [ "$DENY_FETCH" = 1 ]; then exit 42; fi
fi
exec git "$@"
''')
    wrapper.chmod(0o755)

    def run(name, pin, deny, expected):
        root = base / name
        (root / 'external_modules/code').mkdir(parents=True, exist_ok=True)
        (root / 'installation_scripts').mkdir(exist_ok=True)
        (root / 'installation_scripts/flags_check.sh').write_text('return 0\n')
        env = dict(os.environ, ROOTDIR=str(root), GIT=str(wrapper),
                   PYSPK_URL=remote.as_uri(), PYSPK_GIT_COMMIT=pin,
                   GIT_CLONE_MAXIMUM_DEPTH='1', OUT1=str(root/'out'),
                   OUT2=str(root/'err'), FETCH_LOG=str(root/'fetches'),
                   DENY_FETCH=str(deny), EC15='GIT CLONE', EC16='GIT CHECKOUT')
        for key in ['IGNORE_PYSPK_CODE', 'OVERWRITE_EXISTING_PYSPK_CODE',
                    'PYSPK_GIT_BRANCH', 'PYSPK_GIT_TAG', 'PYSPK_NAME']:
            env.pop(key, None)
        result = subprocess.run(['bash', '-c', '''
cdroot() { cd "$ROOTDIR"; }
ptop() { :; }
pbottom() { :; }
fail_script_msg() { echo "$*" >&2; }
source "$1"
status=$?
[ -z "${PYSPK_REQUESTED_REF+x}" ] || exit 98
exit "$status"
''', 'test', str(SCRIPT)], env=env, capture_output=True, text=True)
        assert result.returncode == expected, (name, result.stderr)
        return root, result

    root, _ = run('local_tip', tip, 1, 55)
    assert not (root/'fetches').exists()
    git(root/'external_modules/code/pyspk', 'checkout', '--detach', 'HEAD')
    run('local_tip', tip, 1, 55)
    assert not (root/'fetches').exists(), 'rerun unexpectedly accessed network'
    root, result = run('missing_pin', first, 1, 1)
    assert 'PYSPK GIT FETCH' in result.stderr
    run('missing_pin', first, 0, 55)
    assert git(root/'external_modules/code/pyspk', 'rev-parse', 'HEAD') == first
    run('missing_pin', tip, 1, 55)
    assert git(root/'external_modules/code/pyspk', 'rev-parse', 'HEAD') == tip
    bad = base/'bad_directory/external_modules/code/pyspk'
    bad.mkdir(parents=True)
    _, result = run('bad_directory', tip, 1, 1)
    assert 'NOT A GIT CHECKOUT' in result.stderr
print('PASS: local pin without fetch, rerun, missing-pin failure/recovery, changed pin, invalid checkout, cleanup')
