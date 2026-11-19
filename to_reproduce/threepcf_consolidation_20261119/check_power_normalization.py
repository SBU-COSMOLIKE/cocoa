"""Check the legacy amplitude multiplier with finer CAMB and output sampling.

The private producer differs only in CAMB AccuracyBoost=2 and
k_per_logint=50. It solves to 5/Mpc and retains the existing extrapolation.
This study also requests 1025 uniform log-k samples. No installed module,
project default, notebook or frozen survey reference is changed.
"""

import hashlib
import json
import os
from pathlib import Path
import sys


def main():
    """Save nine input tables and their independently integrated amplitudes."""
    for name in ("OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS", "BLIS_NUM_THREADS",
                 "VECLIB_MAXIMUM_THREADS", "NUMEXPR_NUM_THREADS"):
        os.environ[name] = "1"
    os.environ["OMP_NUM_THREADS"] = "6"
    os.environ["OMP_THREAD_LIMIT"] = "6"
    private = Path("/private/tmp/threepcf_consolidation_20261119")
    project = private / "highaccuracy_Cocoa/projects/des_3pcf"
    sys.path.insert(0, str(project / "python"))
    import numpy as np
    from des3pcf.inputs import camb_tables, load_tables, save_tables
    from des3pcf.bihalofit import BiHalofit

    replay = json.loads((private / "nla_shared2_fisher.json").read_text())
    initial, unused = load_tables(path=replay["point_table_files"][0])
    parameters = replay["points"][0]
    points = [("fiducial", dict(parameters))]
    for name, step in (("h", 0.005), ("omega_m", 0.003)):
        for offset in (-1.0, -0.5, 0.5, 1.0):
            point = dict(parameters)
            point[name] += offset * step
            points.append((name + "_" + str(offset), point))
    wave = np.exp(np.linspace(start=np.log(initial["k"][0]),
                              stop=np.log(initial["k"][-1]), num=1025))
    output = private / "highaccuracy_normalization"
    output.mkdir(exist_ok=False)
    records = []
    for label, point in points:
        tables, metadata = camb_tables(
            parameters=point, k=wave, z=initial["z"],
            sources=initial["sources"], los_z=initial["los_z"],
            source_z=initial.get("source_z"), kmax_boltzmann=5.0,
        )
        metadata["diagnostic_camb_accuracy_boost"] = 2.0
        metadata["diagnostic_camb_k_per_logint"] = 50
        filename = output / (label + ".npz")
        save_tables(path=filename, tables=tables, metadata=metadata)
        matter = tables["omega_m"] * (1.0 + tables["z"])**3
        dark = tables["omega_de"] * (1.0 + tables["z"])**(
            3.0 * (1.0 + tables["w0"] + tables["wa"]),
        )
        dark *= np.exp(-3.0 * tables["wa"] * tables["z"]
                       / (1.0 + tables["z"]))
        arguments = {}
        for name in ("k", "p_linear0", "z", "growth", "ns", "sigma8"):
            arguments[name] = tables[name]
        model = BiHalofit(
            **arguments, omega_m_z=matter / (matter + dark), fit_nz=33,
            table_boost=8, source_readers=False, variance_nodes=8000,
            slope_nodes=16000, radius_rtol=1.0e-10,
        )
        records.append({
            "label": label, "parameters": point,
            "power_normalization": model.power_normalization,
            "input_path": str(filename),
            "input_sha256": hashlib.sha256(filename.read_bytes()).hexdigest(),
        })
        Path(__file__).with_suffix(".json").write_text(
            json.dumps(records, indent=2) + "\n",
        )
        print(label, model.power_normalization, flush=True)


if __name__ == "__main__":
    main()
