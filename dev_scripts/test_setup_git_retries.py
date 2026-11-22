"""Exercise standalone setup Git helpers with local repositories and failures.

No packages are installed and no network is used. The fake Git command fails
selected clone/fetch calls before delegating to real Git. Every setup script's
own helper copy is tested, so a missed edit cannot hide behind a shared helper.
"""
from pathlib import Path
import os
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(command, env):
    return subprocess.run(
        ['bash', '-c', command], env=env, text=True, capture_output=True,
    )


with tempfile.TemporaryDirectory() as temporary:
    base = Path(temporary)
    remote = base / 'remote'
    remote.mkdir()
    subprocess.run(['git', 'init', '-q', str(remote)], check=True)
    for key, value in [('user.name', 'Test'), ('user.email', 'test@example.invalid')]:
        subprocess.run(['git', '-C', str(remote), 'config', key, value], check=True)
    for value in ['first', 'second']:
        (remote / 'value').write_text(value)
        subprocess.run(['git', '-C', str(remote), 'add', 'value'], check=True)
        subprocess.run(['git', '-C', str(remote), 'commit', '-qm', value], check=True)
    wrapper = base / 'git'
    wrapper.write_text('''#!/bin/bash
if [ "$1" = clone ] || [ "$1" = fetch ]; then
  count=0
  if [ -f "$COUNTER" ]; then read count < "$COUNTER"; fi
  count=$((count + 1))
  echo "$count" > "$COUNTER"
  if [ "$count" -le "$FAIL_COUNT" ]; then
    # Simulate the partial directory a recursive clone can leave behind.
    if [ "$1" = clone ]; then mkdir -p "${@: -1}"; fi
    exit 42
  fi
fi
exec /usr/bin/git "$@"
''')
    wrapper.chmod(0o755)
    scripts = []
    for script in sorted((ROOT / 'Cocoa/installation_scripts').glob('setup_*.sh')):
        text = script.read_text()
        if 'gitclone()' not in text:
            continue
        scripts.append(script)
        helpers = text[text.index('gitfetch()'):text.index('unset_env_vars () {')]
        env = dict(os.environ, GIT=str(wrapper), COUNTER=str(base/'count'),
                   FAIL_COUNT='2', GIT_NETWORK_MAX_ATTEMPTS='3',
                   GIT_NETWORK_RETRY_DELAY='0', REMOTE=remote.as_uri(),
                   DEST=str(base/'checkout'))
        # Two failed clones leave temporary files; the third succeeds cleanly.
        command = helpers + '\ngitclone "$DEST" "$REMOTE" --depth 1'
        result = run(command, env)
        assert result.returncode == 0, (script, result.stderr)
        assert (base/'count').read_text().strip() == '3'
        assert not list(base.glob('checkout.clone.*'))
        # Retry a shallow fetch and verify that it actually retrieves history.
        (base/'count').unlink()
        result = run(helpers + '\ncd "$DEST"\ngitfetch', env)
        assert result.returncode == 0, (script, result.stderr)
        assert (base/'count').read_text().strip() == '3'
        # Permanent failure stops at the configured limit and publishes nothing.
        (base/'count').unlink()
        env['FAIL_COUNT'] = '10'
        env['DEST'] = str(base/'failed')
        result = run(command, env)
        assert result.returncode == 1, (script, result.stderr)
        assert (base/'count').read_text().strip() == '3'
        assert not (base/'failed').exists()
        assert not list(base.glob('failed.clone.*'))
        # A pre-existing directory must never be removed by clone recovery.
        env['DEST'] = str(base/'checkout')
        result = run(command, env)
        assert result.returncode == 1
        assert (base/'checkout/value').read_text() == 'second'
        subprocess.run(['rm', '-rf', str(base/'checkout')], check=True)
        (base/'count').unlink()
    print(f'PASS: {len(scripts)} standalone copies: clone/fetch recovery, retry limit, partial-clone cleanup, existing-directory preservation')

# The complete FBRE setup has no patch/download steps after checkout, making
# it a useful end-to-end representative of the common package scripts.
original = (ROOT/'dev_scripts/test_setup_pyspk.py').read_text()
with tempfile.TemporaryDirectory(dir=ROOT/'dev_scripts') as temporary:
    test = Path(temporary)/'test_fbre.py'
    original = original.replace("Path(__file__).resolve().parents[1]", repr(str(ROOT)))
    original = original.replace(repr(str(ROOT)) + " /", 'Path(' + repr(str(ROOT)) + ') /')
    original = original.replace('pyspk', 'fbre').replace('PYSPK', 'FBRE')
    test.write_text(original)
    env = dict(os.environ, GIT_NETWORK_MAX_ATTEMPTS='2', GIT_NETWORK_RETRY_DELAY='0')
    subprocess.run([str(ROOT/'Cocoa/.local/bin/python'), str(test)], env=env, check=True)

# Exercise each generated package revision block with both a commit and a
# branch key set. The explicit commit must win over the default branch.
with tempfile.TemporaryDirectory() as temporary:
    base = Path(temporary)
    subprocess.run(['git', 'init', '-q', str(base)], check=True)
    for key, value in [('user.name', 'Test'), ('user.email', 'test@example.invalid')]:
        subprocess.run(['git', '-C', str(base), 'config', key, value], check=True)
    for value in ['first', 'second']:
        (base/'value').write_text(value)
        subprocess.run(['git', '-C', str(base), 'add', 'value'], check=True)
        subprocess.run(['git', '-C', str(base), 'commit', '-qm', value], check=True)
    first = subprocess.check_output(['git', '-C', str(base), 'rev-parse', 'HEAD~1'], text=True).strip()
    subprocess.run(['git', '-C', str(base), 'tag', 'test-tag', first], check=True)
    count = 0
    for script in scripts:
        text = script.read_text()
        for match in re.finditer(r'# Resolve the requested revision[\s\S]*?\n  fi\nfi\n', text):
            block = match[0]
            prefix = re.search(r'\$\{(\w+)_GIT_COMMIT', block)[1]
            if prefix in ['MGCAMB', 'COBAYA']:
                block = block.replace('${ECODEF:?}/${TFOLDER:?}', '${PACKDIR:?}')
                block = block.replace('${COB:?}', '${PACKDIR:?}')
            env = dict(os.environ, GIT='/usr/bin/git', PACKDIR=str(base),
                       OUT1='/dev/null', OUT2='/dev/null', EC16='CHECKOUT',
                       **{prefix+'_GIT_COMMIT': first,
                          prefix+'_GIT_BRANCH': 'missing-branch',
                          prefix+'_GIT_TAG': ''})
            setup = '''cdfolder() { cd "$1"; }
error() { echo "$*" >&2; }
gitfetch() { echo UNEXPECTED_FETCH >&2; return 1; }
'''
            result = run(setup + block, env)
            assert result.returncode == 0, (script, result.stderr)
            assert (base/'value').read_text() == 'first'
            # Tags can be selected repeatedly without a TMP-branch collision.
            env[prefix+'_GIT_COMMIT'] = ''
            env[prefix+'_GIT_BRANCH'] = ''
            env[prefix+'_GIT_TAG'] = 'test-tag'
            for repeat in range(2):
                result = run(setup + block, env)
                assert result.returncode == 0, (script, result.stderr)
            count += 1
    assert count >= 30, count
    print(f'PASS: {count} package revision blocks: commit precedence, local-only pins and repeated tag checkout')
