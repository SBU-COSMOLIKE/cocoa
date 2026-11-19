"""Build private 3PCF revisions and test them without replacing installed files.

The stage argument labels the evidence. Optional pytest paths select a focused
check; omitting them runs the project suite. Builds and tests run sequentially,
with one BLAS worker and at most six OpenMP workers.
"""

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


def main():
    """Snapshot current sources and record strict and UBSan results."""
    workspace = Path(__file__).resolve().parents[2]
    study = Path(__file__).resolve().parent
    base = Path('/private/tmp/threepcf_consolidation_20261119')
    core = workspace / 'Cocoa/external_modules/code/cosmolike_core'
    project = workspace / 'Cocoa/projects/des_3pcf'
    target = base / 'provider_tests_Cocoa/projects/des_3pcf'
    source = base / 'retired_variance_source'
    stage = sys.argv[1]
    paths = sys.argv[2:] or ['tests']
    prior = workspace / 'to_reproduce/threepcf_consolidation_20261119'
    builds = json.loads((prior / 'retired_variance_builds.json').read_text())
    environment = dict(os.environ)
    for name in ('OPENBLAS_NUM_THREADS', 'MKL_NUM_THREADS',
                 'VECLIB_MAXIMUM_THREADS', 'BLIS_NUM_THREADS',
                 'NUMEXPR_NUM_THREADS', 'OMP_NUM_THREADS'):
        environment[name] = '1'
    environment['OMP_THREAD_LIMIT'] = '6'
    environment['UBSAN_OPTIONS'] = 'halt_on_error=1:print_stacktrace=1'
    environment['PATH'] = (
        str(workspace / 'Cocoa/.local/bin')
        + ':/Users/vivianmiranda/miniforge/envs/cocoapy311/bin:'
        + environment['PATH']
    )
    for name in ('python', 'scripts', 'tests', 'interface'):
        for path in (project / name).rglob('*.py'):
            destination = target / path.relative_to(project)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src=path, dst=destination)
    record = {'stage': stage, 'source_sha256': {}, 'runs': []}
    for folder in ('cosmolike', 'cfastpt', 'log.c'):
        for path in (core / folder).rglob('*'):
            if not path.is_file():
                continue
            relative = path.relative_to(core)
            destination = source / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            if not destination.exists() or path.read_bytes() != destination.read_bytes():
                shutil.copy2(src=path, dst=destination)
                destination.touch()
            record['source_sha256'][str(relative)] = hashlib.sha256(
                path.read_bytes()).hexdigest()
    for mode in ('strict', 'debug'):
        build = base / ('retired_variance_' + mode)
        shutil.copy2(src=project / 'interface/MakefileCosmolike',
                     dst=build / 'MakefileCosmolike')
        binary = build / 'cosmolike_des_3pcf_interface.so'
        saved = base / ('before_followup_' + mode + '.so')
        if not saved.exists():
            shutil.copy2(src=binary, dst=saved)
        for entry in builds['builds']:
            if entry['mode'] == mode:
                command = [value if value != '-j1' else '-j6'
                           for value in entry['command']]
        log = base / (stage + '_' + mode + '_build.log')
        print(stage, mode, 'build', flush=True)
        with log.open(mode='w') as stream:
            subprocess.run(args=command, cwd=build, env=environment,
                           stdout=stream, stderr=subprocess.STDOUT, check=True)
        shutil.copy2(src=binary, dst=target / 'interface' / binary.name)
        command = [sys.executable, '-B', '-m', 'pytest', '-v', '-p',
                   'no:cacheprovider', '--maxfail=3'] + paths
        log = base / (stage + '_' + mode + '_tests.log')
        print(stage, mode, 'tests', flush=True)
        with log.open(mode='w') as stream:
            result = subprocess.run(args=command, cwd=target, env=environment,
                                    stdout=stream, stderr=subprocess.STDOUT)
        record['runs'].append({
            'mode': mode,
            'returncode': result.returncode,
            'command': command,
            'binary_sha256': hashlib.sha256(binary.read_bytes()).hexdigest(),
            'log_sha256': hashlib.sha256(log.read_bytes()).hexdigest(),
            'summary': log.read_text().splitlines()[-8:],
        })
        (study / (stage + '.json')).write_text(json.dumps(record, indent=2) + '\n')
        if result.returncode:
            raise SystemExit(result.returncode)
        print(record['runs'][-1]['summary'][-1], flush=True)


if __name__ == '__main__':
    main()
