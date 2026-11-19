"""Regenerate the archived equation outputs with the matching retired producer.

Run from the workspace root only after build_retired_bihalofit.py, outside
any active validation run. This explicitly replaces the regression fixture.
"""

import os
for key in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS",
            "VECLIB_MAXIMUM_THREADS", "BLIS_NUM_THREADS"):
    os.environ[key] = "1"

import sys, json, hashlib, subprocess, importlib.util
from pathlib import Path
import numpy as np
base=Path('/private/tmp/threepcf_consolidation_20261119')
p=base/'provider_tests_Cocoa/projects/des_3pcf'
sys.path[:0]=[str(base/'native_b_oracle'),str(p/'python'),str(p/'tests'),str(p/'tests/data_vector')]
import cosmolike_des_3pcf_interface as compiled
compiled.set_omp_threads(nthreads=1)
from test_bihalofit_python import comparison_inputs,query_triangles
from test_bihalofit_squeezed import squeezed_queries
# Load the matching historical preparation under its own module name.
# This does not replace or modify a production import.
project = Path.cwd() / 'Cocoa/projects/des_3pcf'
historical = subprocess.check_output(
    ['git', 'show', '09493eb:python/des3pcf/variance.py'], cwd=project,
)
helper = base / 'native_b_oracle/retired_variance_reference.py'
helper.write_bytes(historical)
spec = importlib.util.spec_from_file_location('des3pcf.retired_variance_reference', helper)
reference_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reference_module)
reference_physics_model = reference_module.reference_physics_model
SharedVariance = reference_module.SharedVariance
from des3pcf.bihalofit import fit_redshifts,input_hashes
from test_piecewise_physics import piecewise_inputs
record={'core_commit':'ef64fb1','binary_sha256':hashlib.sha256(Path(compiled.__file__).read_bytes()).hexdigest(),'cases':{}}
for source in (False,True):
    for fit,boost in ((17,4),(33,8),(65,16)):
        native,supplied=comparison_inputs(source_readers=source,fit_nz=fit);native['table_boost']=boost
        sides,z=query_triangles()
        model=reference_physics_model(factory=compiled.PhysicsModel,**native)
        record['cases'][f'equation_{int(source)}_{fit}_{boost}']={'inputs':input_hashes(arrays=native,settings={}), 'matter':[model.matter(sides=sides,redshifts=z,component=c).tolist() for c in range(4)]}
    native,supplied=comparison_inputs(source_readers=source)
    engine=SharedVariance(compiled=compiled)
    anchors=fit_redshifts(zmax=native['z'][-1],fit_nz=native['fit_nz'],source_readers=source)
    snap,_=engine.prepare(tables=native,parameters={'omega_b':.05,'h':.7},metadata={},z=anchors)
    native['variance']={key:snap[key] for key in ('z','rnl','neff','sigma8')}
    model=reference_physics_model(factory=compiled.PhysicsModel,**native)
    sides,z=query_triangles()
    record['cases'][f'shared_{int(source)}']={'matter':[model.matter(sides=sides,redshifts=z,component=c).tolist() for c in range(4)]}
    native,supplied=comparison_inputs(source_readers=source)
    model=reference_physics_model(factory=compiled.PhysicsModel,**native)
    sides,_=squeezed_queries();z=np.full(sides.shape[0],.7)
    record['cases'][f'squeezed_{int(source)}']={'matter':[model.matter(sides=sides,redshifts=z,component=c).tolist() for c in range(4)]}
native=piecewise_inputs(refinement=1)
model=reference_physics_model(factory=compiled.PhysicsModel,**native)
sides,z=query_triangles()
record['cases']['piecewise']={'matter':[model.matter(sides=sides,redshifts=z,component=c).tolist() for c in range(4)]}
out=Path('Cocoa/projects/des_3pcf/tests/data_vector/reference_retired_c_bihalofit.json')
out.write_text(json.dumps(record,indent=2)+'\n');print(out)
