"""Compare interpolation implementations on complete NLA or TATT stencils.

Each process imports one explicit native extension. The configuration fixes
all rows, the joint covariance, source reconstruction and numerical controls.
Both derivative spacings are retained. No previously saved Fisher derivative
is reused, because it may describe different source or native-library bytes.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import sys


def main():
    """Save a full mean and both Fisher stencils with their input identities."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--extension", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--project", type=Path)
    parser.add_argument("--threads", type=int, choices=range(1, 7), default=6)
    parser.add_argument("--variance-boost", type=float, default=1.0)
    options = parser.parse_args()
    for name in (
        "OPENBLAS_NUM_THREADS",
        "MKL_NUM_THREADS",
        "BLIS_NUM_THREADS",
        "VECLIB_MAXIMUM_THREADS",
        "NUMEXPR_NUM_THREADS",
    ):
        os.environ[name] = "1"
    os.environ["OMP_NUM_THREADS"] = str(options.threads)
    os.environ["OMP_THREAD_LIMIT"] = "6"
    workspace = Path(__file__).resolve().parents[2]
    project = workspace / "Cocoa/projects/des_3pcf"
    if options.project is not None:
        project = options.project.resolve()
    sys.path.insert(0, str(project / "python"))
    sys.path.insert(0, str(project / "scripts"))
    sys.path.insert(0, str(options.extension.resolve()))
    import numpy as np
    import run_3pcf as driver
    import cosmolike_des_3pcf_interface as compiled
    from des3pcf.forecast import ExactMeanCache, differentiate, fisher_matrix
    from des3pcf.provenance import prediction_identity
    from des3pcf.bihalofit import input_hashes

    config, path, config_hash = driver.load_configuration(
        path=options.config, command="fisher",
    )
    config["threads"] = options.threads
    config["physics"]["variance_source"] = "shared"
    config["physics"]["variance_growth"] = "factorized"
    for name in ("variance_mass_boost", "variance_a_boost",
                 "variance_radius_boost", "variance_inverse_boost"):
        config["accuracy"][name] = options.variance_boost
    if config["physics"].get("bispectrum_source", "internal") != "internal":
        raise ValueError("This interpolation comparison requires internal BiHalofit.")
    rows = driver.rows_for_run(config=config, path=path)
    fixed = driver.read_matrix(settings=config["covariance"], path=path,
                               rows=rows, positive=True)
    compiled.set_omp_threads(nthreads=options.threads)
    provider, unused = driver.provider_for_run(compiled=compiled, config=config, path=path)
    prediction = driver.prediction_for_run(compiled=compiled, config=config,
                                           path=path, rows=rows, provider=provider)
    native_two = prediction.two_point_core.core.__file__
    identity = prediction_identity(
        config=config, configuration_path=path, project=project,
        three_point_path=compiled.__file__, two_point_path=native_two,
    )
    reference = dict(config["ia"])
    reference.update(config["parameters"])
    point_records = []
    table_hashes = []
    vectors = []
    variance_records = []
    table_files = []
    table_file_hashes = []
    table_directory = options.output.with_suffix(".tables")
    table_directory.mkdir(parents=True, exist_ok=True)
    from collections.abc import Mapping
    from des3pcf.inputs import save_tables

    def plain(value):
        if isinstance(value, Mapping):
            result = {}
            for name, item in value.items():
                result[name] = plain(item)
            return result
        if isinstance(value, (list, tuple)):
            return [plain(item) for item in value]
        return value
    options.output.parent.mkdir(parents=True, exist_ok=True)

    def recorded_prediction(parameters):
        """Retain every independently evaluated mean and its physical point."""
        values = prediction(parameters=parameters)
        unused_model, tables, unused_metadata = provider.get(parameters=parameters)
        table_hashes.append(input_hashes(arrays=tables, settings={}))
        variance_record = dict(unused_metadata["variance"])
        variance_record["sampling"] = dict(variance_record["sampling"])
        variance_record["input_sha256"] = dict(variance_record["input_sha256"])
        variance_records.append(variance_record)
        physical_hashes = input_hashes(arrays=provider.cosmology_tables, settings={})
        signature = hashlib.sha256(json.dumps(physical_hashes, sort_keys=True).encode()).hexdigest()
        table_path = table_directory / (signature + ".npz")
        if not table_path.exists():
            save_tables(path=table_path, tables=provider.cosmology_tables,
                        metadata=plain(provider.cosmology_metadata))
        table_files.append(str(table_path))
        table_file_hashes.append(hashlib.sha256(table_path.read_bytes()).hexdigest())
        point_records.append(dict(parameters))
        vectors.append(values.copy())
        changed = []
        for name in parameters:
            if parameters[name] != reference[name]:
                changed.append(name)
        print(len(vectors), changed or ["fiducial"], flush=True)
        return values

    cached = ExactMeanCache(predict=recorded_prediction)
    names, mean, derivative, refined = differentiate(
        predict=cached, parameters=reference, steps=config["fisher"]["steps"],
        bounds=config["fisher"].get("bounds"),
    )
    information = fisher_matrix(derivatives=derivative, names=names,
                                covariance=fixed, priors=config["fisher"]["priors"])
    refined_information = fisher_matrix(
        derivatives=refined, names=names, covariance=fixed,
        priors=config["fisher"]["priors"],
    )
    after = prediction_identity(
        config=config, configuration_path=path, project=project,
        three_point_path=compiled.__file__, two_point_path=native_two,
    )
    if after != identity:
        raise RuntimeError("Prediction inputs changed during the stencil calculation.")
    np.savez(
        file=options.output,
        mean=mean,
        derivatives_h=derivative,
        derivatives_h2=refined,
        fisher_h=information,
        fisher_h2=refined_information,
        covariance=fixed,
        parameter_names=np.asarray(names),
        row_labels=rows.labels,
        row_kind=rows.kind,
        point_means=np.asarray(vectors),
    )
    record = {
        "configuration_sha256": config_hash,
        "configuration": config,
        "prediction_identity": identity,
        "points": point_records,
        "physical_table_hashes": table_hashes,
        "script_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "output_sha256": hashlib.sha256(options.output.read_bytes()).hexdigest(),
        "scope": "shared variance; supplied amplitude; factorized input growth",
        "variance_records": variance_records,
        "point_table_files": table_files,
        "point_table_file_sha256": table_file_hashes,
    }
    options.output.with_suffix(".json").write_text(
        json.dumps(record, indent=2, allow_nan=False) + "\n",
    )


if __name__ == "__main__":
    main()
