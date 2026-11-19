"""Score paired interpolation runs in the same full joint covariance.

The comparison tests means, every whitened derivative, marginalized errors
and all parameter-pair figures of merit at both recorded derivative steps.
The unchanged two-point rows and all generated physical input-table hashes
must match before numerical differences can be attributed to interpolation.
"""

import argparse
import json
import os
from pathlib import Path


def main():
    """Write numerical differences and explicit acceptance decisions."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("output", type=Path)
    options = parser.parse_args()
    for name in ("OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS", "VECLIB_MAXIMUM_THREADS"):
        os.environ[name] = "1"
    import numpy as np

    before_record = json.loads(options.reference.with_suffix(".json").read_text())
    after_record = json.loads(options.candidate.with_suffix(".json").read_text())
    # Only smoothing-engine selection and its four accuracy controls may
    # differ. All other physical/numerical choices, arrays and rows stay fixed.
    configurations = []
    for record in (before_record, after_record):
        config = json.loads(json.dumps(record["configuration"]))
        config["physics"].pop("variance_source", None)
        growth = config["physics"].pop("variance_growth", "factorized")
        if growth != "factorized":
            raise ValueError("Evolving growth is a separate physical comparison.")
        for name in ("variance_mass_boost", "variance_a_boost",
                     "variance_radius_boost", "variance_inverse_boost"):
            config["accuracy"].pop(name, None)
        configurations.append(config)
    if configurations[0] != configurations[1]:
        raise ValueError("Settings other than shared variance differ.")
    for key in ("points", "physical_table_hashes"):
        if before_record[key] != after_record[key]:
            raise ValueError(f"Paired {key} differ; this is not an interpolation comparison.")
    before = np.load(file=options.reference, allow_pickle=False)
    after = np.load(file=options.candidate, allow_pickle=False)
    for name in ("covariance", "parameter_names", "row_labels", "row_kind"):
        np.testing.assert_array_equal(before[name], after[name])
    names = before["parameter_names"].tolist()
    factor = np.linalg.cholesky(a=before["covariance"])
    delta = np.linalg.solve(a=factor, b=after["mean"] - before["mean"])
    mean_error = float(delta @ delta)
    two_point = before["row_kind"] != "map3"
    two_point_equal = np.array_equal(
        before["point_means"][:, two_point].view(np.uint64),
        after["point_means"][:, two_point].view(np.uint64),
    )
    report = {
        "reference": str(options.reference),
        "candidate": str(options.candidate),
        "scope": "shared versus reference smoothing at fixed physical inputs",
        "mean_delta_chi2": mean_error,
        "two_point_all_stencil_rows_equal": bool(two_point_equal),
        "steps": {},
        "passed": mean_error <= 0.01 and bool(two_point_equal),
    }
    for step in ("h", "h2"):
        reference = np.linalg.solve(a=factor, b=before["derivatives_" + step])
        difference = np.linalg.solve(
            a=factor, b=after["derivatives_" + step] - before["derivatives_" + step],
        )
        norms = np.linalg.norm(x=reference, axis=0)
        if np.any(norms <= 0.0):
            raise ValueError("A zero derivative needs an explicit unresolved-column report.")
        epsilon = np.linalg.norm(x=difference, axis=0) / norms
        covariance_before = np.linalg.inv(a=before["fisher_" + step])
        covariance_after = np.linalg.inv(a=after["fisher_" + step])
        error_ratio = np.sqrt(np.diag(covariance_after) / np.diag(covariance_before))
        if not np.all(np.isfinite(error_ratio)):
            raise ValueError("Nonfinite marginalized errors; do not regularize the Fisher matrix.")
        columns = {}
        pairs = {}
        for index, name in enumerate(names):
            columns[name] = {
                "whitened_derivative_relative_error": float(epsilon[index]),
                "marginalized_error_ratio": float(error_ratio[index]),
            }
            for other in range(index + 1, len(names)):
                selected = np.ix_([index, other], [index, other])
                old = np.linalg.det(a=covariance_before[selected])
                new = np.linalg.det(a=covariance_after[selected])
                if old <= 0.0 or new <= 0.0:
                    raise ValueError("Unresolved parameter pair; no finite FoM is defined.")
                pairs[name + "/" + names[other]] = float(np.sqrt(old / new))
        maximum_fom_change = max(abs(value - 1.0) for value in pairs.values())
        passed = (np.max(epsilon) <= 1.0e-3
                  and np.max(np.abs(error_ratio - 1.0)) <= 0.005
                  and maximum_fom_change <= 0.005)
        report["steps"][step] = {
            "columns": columns,
            "pair_fom_ratios": pairs,
            "maximum_derivative_error": float(np.max(epsilon)),
            "maximum_marginalized_error_change": float(np.max(np.abs(error_ratio - 1.0))),
            "maximum_pair_fom_change": float(maximum_fom_change),
            "passed": bool(passed),
        }
        report["passed"] = report["passed"] and bool(passed)
    options.output.write_text(json.dumps(report, indent=2, allow_nan=False) + "\n")
    print("mean difference", mean_error, "accepted", report["passed"])
    for name, step in report["steps"].items():
        print(name, step["maximum_derivative_error"],
              step["maximum_marginalized_error_change"], step["maximum_pair_fom_change"])

    if not report["passed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
