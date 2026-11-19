"""Finish paired NLA/TATT acceptance checks serially on frozen CAMB inputs.

Start only after the high-accuracy NLA local reference has completed. Each
comparison must pass before more expensive work begins. A failed comparison
keeps its report and stops the sequence; it never replaces a reference.
"""

import json
import os
from pathlib import Path
import subprocess


def main():
    """Record each numerical command and stop on the first failed criterion."""
    study = Path(__file__).resolve().parent
    workspace = study.parents[1]
    private = Path("/private/tmp/threepcf_consolidation_20261119")
    python = workspace / "Cocoa/.local/bin/python"
    project = private / "highaccuracy_Cocoa/projects/des_3pcf"
    replay = private / "highaccuracy_nla_shared4_fisher.json"
    environment = dict(os.environ)
    for name in ("OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS", "BLIS_NUM_THREADS",
                 "VECLIB_MAXIMUM_THREADS", "NUMEXPR_NUM_THREADS"):
        environment[name] = "1"
    environment["OMP_NUM_THREADS"] = "6"
    environment["OMP_THREAD_LIMIT"] = "6"
    status = study / "highaccuracy_sequence_status.json"
    completed = []

    def run(label, command):
        """Wait for one child, saving its PID and exact command before work."""
        log = private / (label + ".log")
        with log.open(mode="w") as stream:
            child = subprocess.Popen(args=command, env=environment,
                                     stdout=stream, stderr=subprocess.STDOUT)
            record = {"stage": label, "pid": child.pid, "command": command,
                      "log": str(log), "completed": completed}
            status.write_text(json.dumps(record, indent=2) + "\n")
            code = child.wait()
        completed.append({"stage": label, "returncode": code})
        record["returncode"] = code
        status.write_text(json.dumps(record, indent=2) + "\n")
        if code != 0:
            raise RuntimeError(f"Inspect {label}: {log}")

    def compare(reference, candidate, label):
        """Apply the original criteria to every saved column and pair."""
        run(label=label, command=[
            str(python), "-B", str(study / "compare_shared_forecasts.py"),
            str(private / (reference + ".npz")),
            str(private / (candidate + ".npz")),
            str(study / (label + ".json")),
        ])

    def capture(model, variant, boost, label):
        """Recompute all rows at both derivative steps with one explicit build."""
        run(label=label, command=[
            str(python), "-B", str(study / "capture_replay_forecast.py"),
            "--config", str(private / ("highaccuracy_" + model + ".json")),
            "--project", str(project),
            "--extension", str(private / "sampling_strict"),
            "--output", str(private / (label + ".npz")),
            "--threads", "6", "--variance-boost", str(boost),
            "--replay", str(replay), "--variant", variant,
        ])

    compare(reference="highaccuracy_nla_legacy_refined_fisher",
            candidate="highaccuracy_nla_shared4_fisher",
            label="highaccuracy_nla_shared4_comparison")
    capture(model="nla", variant="shared", boost=8,
            label="highaccuracy_nla_shared8_fisher")
    compare(reference="highaccuracy_nla_legacy_refined_fisher",
            candidate="highaccuracy_nla_shared8_fisher",
            label="highaccuracy_nla_shared8_comparison")
    compare(reference="highaccuracy_nla_shared4_fisher",
            candidate="highaccuracy_nla_shared8_fisher",
            label="highaccuracy_nla_refinement_comparison")
    capture(model="tatt", variant="legacy_refined", boost=4,
            label="highaccuracy_tatt_legacy_refined_fisher")
    capture(model="tatt", variant="shared", boost=4,
            label="highaccuracy_tatt_shared4_fisher")
    compare(reference="highaccuracy_tatt_legacy_refined_fisher",
            candidate="highaccuracy_tatt_shared4_fisher",
            label="highaccuracy_tatt_shared4_comparison")
    capture(model="tatt", variant="shared", boost=8,
            label="highaccuracy_tatt_shared8_fisher")
    compare(reference="highaccuracy_tatt_legacy_refined_fisher",
            candidate="highaccuracy_tatt_shared8_fisher",
            label="highaccuracy_tatt_shared8_comparison")
    compare(reference="highaccuracy_tatt_shared4_fisher",
            candidate="highaccuracy_tatt_shared8_fisher",
            label="highaccuracy_tatt_refinement_comparison")


if __name__ == "__main__":
    main()
