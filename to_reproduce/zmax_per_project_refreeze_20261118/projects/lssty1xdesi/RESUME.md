# DESI refreeze deferred at the user's request

The quick suite stopped at 07:21:47 EST on 19 November 2026. Its queue,
pytest process and numerical worker exited; `heavy.lock` was released.
This project is unfinished. The remaining notebooks for other projects
continue after the separately reserved native validation interval.
No scheduled restart was created.

Configuration expansion, endpoint checks, reference/baryon generation,
all 200 high-accuracy archive vectors and constant measurements completed.
All 200 default-versus-archive comparisons also completed. The partial
quick suite contains eight passing tests and the four permitted accuracy
threshold failures, with their actual XML messages checked. It collected
110 tests in total; 98 remain. An anonymous XML entry records setup for
the interrupted test and does not count as a completed test.

All 91 frozen files still match the generated manifest after stopping.
No input or frozen-reference repair is required. The interrupted BF0
baryonic one-knob test creates a temporary `cocoa_baryon_model_*` directory
for its synthetic vector and descriptor; those names are explicitly
excluded from the links to the frozen data. The completed five sub-knob
results remain in the log. BF0 must restart as one test because its
sub-knob state was not checkpointed between processes.

## Preserved evidence

- `PAUSED_20261119.json` records the complete physical/input fingerprint,
  shared test-source hashes, all 91 file checks and the twelve named results.
- `pause_processes.json` records signals to only the owned pytest/worker
  and verifies that all three owned processes exited.
- `attempt_history/paused_20261119_072147/` preserves the original log,
  XML and queue record before any later retry.
- `figures/` holds all four reviewed archive-comparison figures. The LSST
  figure with the same example2 filename was separately preserved in its
  own project evidence directory before it could be replaced.

## Resume tonight

1. Recheck `PAUSED_20261119.json` against the installed binary, current
   frozen manifest/physical inputs and shared test sources. A changed
   numerical dependency requires an explicit assessment; do not silently
   reuse these results with a different model or binary.
2. Acquire the same shared `heavy.lock`. Restore the saved build environment
   from `../../logs/build_environment.json`, then set six OpenMP workers,
   `OMP_THREAD_LIMIT=6`, `COCOA_TEST_OMP_THREADS=6` and all BLAS settings to one.
   Run from the Cocoa directory, with this project interface and core on
   `PYTHONPATH`, as `scripts/run_queue.py` does.
3. Skip the entirely completed `test_accuracy.py` module. The remaining
   pytest invocation is:

```bash
python -B -m pytest projects/lssty1xdesi/tests/data_vector --ignore=projects/lssty1xdesi/tests/data_vector/test_accuracy.py -p no:cacheprovider -rfEs --durations=20 --junitxml=/absolute/path/to/new_resume_quick_tests.xml
```

4. Send output to a new resume log/XML. Do not overwrite the preserved
   interrupted attempt. Do not rerun `--nmodels`, reference generation,
   endpoint checks, constant measurements or the completed accuracy module.
   The unmodified generic `run_queue.py` would rerun the whole quick phase,
   so it is not the continuation command for this partial suite.
5. Check the union of named completed cases: twelve from the original XML
   and the remaining cases from the new XML, with no omissions/duplicates.
   Accept only the four original threshold AssertionErrors; crashes,
   setup errors and unrelated assertions remain failures. Record the two
   logs/XMLs and their hashes as separate evidence before marking the quick
   phase complete. Its old return code two remains the honest record of
   the user-requested interruption.
6. Finish the pending documentation-only corrections in the DESI tests:
   SVD/FKEM/SVD sequence, November 19 constant provenance, and the
   fourth-difference curvature/empirical-bound caveat. Verify the executable
   AST is unchanged after excluding docstrings. Finish the portable review
   record and explicit-path A commit only after the remaining gates pass.

The separately prepared CAMB background diagnostic is deferred too. It is
not a prerequisite for the other projects' notebook queue.
