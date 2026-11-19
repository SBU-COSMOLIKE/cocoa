"""Run the current project tests serially with private strict/UBSan builds.

Only the private test checkout receives a different extension. The installed
project library and the separate, pinned forecast checkout remain untouched.
The caller must wait for other numerical jobs before starting this script.
"""

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess


def main():
    """Record extension identities, exact commands and completed test logs."""
    workspace = Path(__file__).resolve().parents[2]
    private = Path("/private/tmp/threepcf_consolidation_20261119")
    project = private / "provider_tests_Cocoa/projects/des_3pcf"
    python = workspace / "Cocoa/.local/bin/python"
    installed = workspace / "Cocoa/projects/des_3pcf/interface"
    destination = project / "interface/cosmolike_des_3pcf_interface.so"
    if destination.resolve().parent == installed.resolve():
        raise ValueError("The regression destination must be private.")
    environment = dict(os.environ)
    for name in ("OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS", "BLIS_NUM_THREADS",
                 "VECLIB_MAXIMUM_THREADS", "NUMEXPR_NUM_THREADS"):
        environment[name] = "1"
    environment["OMP_NUM_THREADS"] = "1"
    environment["OMP_THREAD_LIMIT"] = "6"
    environment["PYTHONDONTWRITEBYTECODE"] = "1"
    environment["UBSAN_OPTIONS"] = "halt_on_error=1:print_stacktrace=1"
    output = Path(__file__).with_name("final_regressions.json")
    records = []
    for mode in ("strict", "debug"):
        binary = private / ("reference_inputs_" + mode) / destination.name
        shutil.copy2(src=binary, dst=destination)
        command = [str(python), "-B", "-m", "pytest", "-q", "-p",
                   "no:cacheprovider", "tests"]
        log = private / ("final_provider_" + mode + ".log")
        print(mode, flush=True)
        with log.open(mode="w") as stream:
            result = subprocess.run(args=command, cwd=project, env=environment,
                                    stdout=stream, stderr=subprocess.STDOUT)
        records.append({
            "mode": mode,
            "extension_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(),
            "command": command,
            "cwd": str(project),
            "returncode": result.returncode,
            "log": str(log),
            "log_sha256": hashlib.sha256(log.read_bytes()).hexdigest(),
            "summary": log.read_text().splitlines()[-5:],
        })
        output.write_text(json.dumps(records, indent=2) + "\n")
        if result.returncode != 0:
            raise RuntimeError(f"Inspect failed {mode} regression: {log}")


if __name__ == "__main__":
    main()
