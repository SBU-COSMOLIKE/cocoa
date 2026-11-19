"""Build the retired equation oracle in task-private storage.

Run from the workspace root, outside any active validation run.
"""

import os, sys, json, hashlib, subprocess, shutil
from pathlib import Path
w=Path.cwd(); base=Path('/private/tmp/threepcf_consolidation_20261119'); core=w/'Cocoa/external_modules/code/cosmolike_core'; project=w/'Cocoa/projects/des_3pcf'
source=base/'retired_variance_source'; build=base/'retired_variance_strict'
env=dict(os.environ)
for key in ('OMP_NUM_THREADS','OPENBLAS_NUM_THREADS','MKL_NUM_THREADS','VECLIB_MAXIMUM_THREADS','BLIS_NUM_THREADS','NUMEXPR_NUM_THREADS'): env[key]='1'
env['OMP_THREAD_LIMIT']='6'
# Restore tracked numerical sources at the oracle commit. Leave only the
# unchanged external log submodule dependency in place. No installed file
# is touched; the next validate.py invocation reinstalls current sources.
paths = subprocess.check_output(
    ['git', 'ls-tree', '-r', '--name-only', 'ef64fb1', '--', 'cosmolike', 'cfastpt'],
    cwd=core, text=True,
).splitlines()
for rel in paths:
    destination = source / rel
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(subprocess.check_output(['git', 'show', 'ef64fb1:'+rel], cwd=core))
record=json.loads((w/'to_reproduce/threepcf_consolidation_20261119/retired_variance_builds.json').read_text())
command=next(x['command'] for x in record['builds'] if x['mode']=='strict')
with (base/'freeze_native_b_build.log').open('w') as stream:
    subprocess.run(command,cwd=build,env=env,stdout=stream,stderr=subprocess.STDOUT,check=True)
folder=base/'native_b_oracle';folder.mkdir(exist_ok=True)
shutil.copy2(build/'cosmolike_des_3pcf_interface.so',folder/'cosmolike_des_3pcf_interface.so')
print(folder,flush=True)
