"""Build pinned strict and UBSan libraries without replacing installed files."""

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess


def main():
    """Record the source snapshot and each serial compiler invocation."""
    workspace = Path(__file__).resolve().parents[2]
    cocoa = workspace / "Cocoa"
    core = cocoa / "external_modules/code/cosmolike_core"
    private = Path("/private/tmp/threepcf_consolidation_20261119")
    source = private / "reference_inputs_source"
    source.mkdir(exist_ok=False)
    for name in ("cosmolike", "cfastpt", "log.c"):
        shutil.copytree(src=core / name, dst=source / name)
    hashes = {}
    for path in sorted(source.rglob("*")):
        if path.is_file():
            hashes[str(path.relative_to(source))] = hashlib.sha256(
                path.read_bytes()).hexdigest()
    environment = dict(os.environ)
    environment["PATH"] = (str(cocoa / ".local/bin")
                           + ":/Users/vivianmiranda/miniforge/envs/cocoapy311/bin:"
                           + environment["PATH"])
    for name in ("OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS", "BLIS_NUM_THREADS",
                 "VECLIB_MAXIMUM_THREADS", "NUMEXPR_NUM_THREADS"):
        environment[name] = "1"
    environment["OMP_NUM_THREADS"] = "1"
    environment["OMP_THREAD_LIMIT"] = "6"
    record = {"source_sha256": hashes, "builds": []}
    output = Path(__file__).with_name("reference_inputs_builds.json")
    for mode in ("strict", "debug"):
        build = private / ("reference_inputs_" + mode)
        build.mkdir(exist_ok=False)
        for name in ("MakefileCosmolike", "interface.cpp"):
            shutil.copy2(src=cocoa / "projects/des_3pcf/interface" / name,
                         dst=build / name)
        command = [
            "make", "-j1", "-f", "MakefileCosmolike",
            "ROOTDIR=" + str(cocoa),
            "CORE=" + str(source),
            "SOURCE=" + str(source / "cosmolike/3pcf"),
            "PYTHON=" + str(cocoa / ".local/bin/python"),
            "CONDA_PREFIX=/Users/vivianmiranda/miniforge/envs/cocoapy311",
            "C_COMPILER=/opt/homebrew/opt/llvm@22/bin/clang",
            "CXX_COMPILER=/opt/homebrew/opt/llvm@22/bin/clang++",
        ]
        if mode == "debug":
            command.append("COSMOLIKE_DEBUG_MODE=1")
        log = private / ("reference_inputs_" + mode + "_build.log")
        print(mode, flush=True)
        with log.open(mode="w") as stream:
            result = subprocess.run(args=command, cwd=build, env=environment,
                                    stdout=stream, stderr=subprocess.STDOUT)
        entry = {"mode": mode, "command": command,
                 "returncode": result.returncode,
                 "log_sha256": hashlib.sha256(log.read_bytes()).hexdigest()}
        if result.returncode == 0:
            binary = build / "cosmolike_des_3pcf_interface.so"
            entry["binary_sha256"] = hashlib.sha256(binary.read_bytes()).hexdigest()
        record["builds"].append(entry)
        output.write_text(json.dumps(record, indent=2) + "\n")
        if result.returncode != 0:
            raise RuntimeError(f"Inspect failed {mode} build: {log}")


if __name__ == "__main__":
    main()
