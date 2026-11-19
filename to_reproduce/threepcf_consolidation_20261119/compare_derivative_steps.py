"""Separate derivative-step sensitivity in saved two- and three-point rows.

The blockwise norms diagnose each calculation's finite differences. They
are not separate Fisher information contributions: the full joint forecast
continues to use every two/three-point cross-covariance entry.
"""

import argparse
import json
import os
from pathlib import Path


def main():
    """Read saved arrays and write blockwise and full-Fisher step changes."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("inputs", type=Path, nargs="+")
    options = parser.parse_args()
    for name in ("OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS",
                 "VECLIB_MAXIMUM_THREADS", "BLIS_NUM_THREADS"):
        os.environ[name] = "1"
    import numpy as np

    records = {}
    for path in options.inputs:
        with np.load(file=path, allow_pickle=False) as data:
            names = data["parameter_names"].tolist()
            record = {"blocks": {}}
            for label in ("two_point", "map3"):
                rows = data["row_kind"] == "map3"
                if label == "two_point":
                    rows = ~rows
                covariance = data["covariance"][np.ix_(rows, rows)]
                factor = np.linalg.cholesky(a=covariance)
                coarse = np.linalg.solve(
                    a=factor, b=data["derivatives_h"][rows],
                )
                fine = np.linalg.solve(
                    a=factor, b=data["derivatives_h2"][rows],
                )
                scale = np.linalg.norm(x=coarse, axis=0)
                if np.any(scale <= 0.0):
                    raise ValueError("A zero derivative needs separate treatment.")
                epsilon = np.linalg.norm(x=fine - coarse, axis=0) / scale
                columns = {}
                for index, name in enumerate(names):
                    columns[name] = float(epsilon[index])
                record["blocks"][label] = columns
            coarse = np.linalg.inv(a=data["fisher_h"])
            fine = np.linalg.inv(a=data["fisher_h2"])
            errors = np.sqrt(np.diag(fine) / np.diag(coarse))
            record["maximum_marginalized_error_change"] = float(
                np.max(np.abs(errors - 1.0)),
            )
            indices = [names.index("w0"), names.index("wa")]
            selected = np.ix_(indices, indices)
            record["w0wa_fom_ratio"] = float(np.sqrt(
                np.linalg.det(a=coarse[selected])
                / np.linalg.det(a=fine[selected]),
            ))
        records[str(path)] = record
    options.output.write_text(json.dumps(records, indent=2) + "\n")


if __name__ == "__main__":
    main()
