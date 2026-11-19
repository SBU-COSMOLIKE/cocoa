"""Save physical outputs around a removal of the internal C matter fit.

Arguments are a private project checkout and an output NPZ path. Both source
comparison and production readers run with NLA and TATT. Each result is captured
with one and six OpenMP workers, while the calling environment limits BLAS to one.
"""

from pathlib import Path
import sys

import numpy as np


def main():
    """Evaluate matter, alignment, projection and all covariance families."""
    project = Path(sys.argv[1])
    for folder in ('interface', 'python', 'tests', 'tests/data_vector'):
        sys.path.insert(0, str(project / folder))
    if len(sys.argv) > 3:
        sys.path.insert(0, sys.argv[3])
    import cosmolike_des_3pcf_interface as compiled
    from des3pcf.variance import reference_physics_model
    from test_physics_model import physical_inputs
    from test_supplied_baseline import baseline_input
    from covariance.test_physical_covariance import covariance_arguments

    output = {}
    sides = np.asarray([[0.03, 0.04, 0.05], [0.1, 0.2, 0.25], [0.5, 0.7, 1.0]])
    redshift = np.asarray([0.0, 0.4, 1.8])
    angular = np.asarray([[170.0, 240.0, 330.0], [600.0, 800.0, 1050.0]])
    bins = np.asarray([0, 1, 0], dtype=np.int32)
    ell = np.asarray([140.0, 260.0])
    for readers in (False, True):
        inputs = physical_inputs()
        inputs['source_readers'] = readers
        inputs['los_z'] = np.asarray([0.15, 0.5, 1.0, 1.8])
        for name in ("omega_de", "w0", "wa", "ns"):
            inputs.pop(name)
        inputs["omega_m_z"] = np.full(inputs["z"].shape, 0.3)
        model = reference_physics_model(
            factory=compiled.production.PhysicsModelWithBispectrum,
            **inputs, baseline=baseline_input(),
        )
        for threads in (1, 6):
            compiled.set_omp_threads(nthreads=threads)
            prefix = f'{int(readers)}_{threads}_'
            for component in range(2):
                output[prefix + f'matter_{component}'] = model.matter(
                    sides=sides, redshifts=redshift, component=component,
                )
            for name, parameters in (
                ('nla', {'a1': 0.4}),
                ('tatt', {'a1': 0.4, 'a2': 0.7, 'bta': 0.3}),
            ):
                output[prefix + name + '_ia'] = model.ia(
                    sides=sides, redshifts=redshift, parameters=parameters,
                )
                output[prefix + name + '_projected'] = model.projected(
                    sides=angular, bins=bins, parameters=parameters,
                )
                output[prefix + name + '_multipoles'] = model.multipoles(
                    ell=ell, bins=bins, parameters=parameters, lmax=3, nmu=33,
                )
            for key, values in model.radial().items():
                output[prefix + key] = values
            mean, covariance = compiled.production.physical_covariance(
                model=model, inputs=covariance_arguments(),
            )
            output[prefix + 'mean'] = mean
            output[prefix + 'covariance'] = covariance
    np.savez(file=sys.argv[2], **output)
    print('Saved', len(output), 'arrays', flush=True)


if __name__ == '__main__':
    main()
