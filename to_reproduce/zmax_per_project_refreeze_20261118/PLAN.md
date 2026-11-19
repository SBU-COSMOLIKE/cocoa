# Per-project endpoint refreeze and notebook validation

This continues the paused refreeze with explicit `nonlimber_zmax` values.
The earlier scripts and results in the supplied `scratchpad/zmax45/` folder
remain as historical evidence. This directory holds the adapted scripts,
input copies, logs and completion records. Heavy numerical jobs run one at a
time with six OpenMP threads and one BLAS thread. The six-thread instruction
supersedes the earlier eight-thread exception for the LSST notebooks.

| Project | Endpoint | Additional numerical settings to retain |
| --- | ---: | --- |
| lsst_y1 | 4.5 | Zero galaxy early-exit tolerances; FKEM and SVD caps 200 |
| des_y3 | 4.0 | Existing production sampling, caps and tolerances |
| desy1xplanck | 4.0 | Existing production sampling, caps and tolerances |
| des_cluster | 4.0 | Existing production settings, including the cluster paths |
| roman_fourier | 5.0 | Radial boost 4; FKEM cap 200; retain its separate SVD cap unless a measured change is requested |
| roman_kl | 4.5 | Retain radial boost 4 in the clustering likelihoods and their caps 200 |
| roman_real | 4.5 | Radial boost 4; zero galaxy tolerances; FKEM and SVD caps 200 |
| lssty1xdesi | 4.5 | Preserve each DESI layout's own sampling, multipole cap and physical assumptions |

Roman KL and LSST Y1 × DESI retain the previous handoff's 4.5 endpoint.
They require the YAML/native/notebook endpoint bindings before their
refreeze. All endpoint values must be finite and at least 4.0. The endpoint
is independent of node count and of the global accuracy boost.

## A. Refreeze in the requested project order

1. Save the starting repositories, compiled-library hashes, frozen inputs
   and manifests. Preserve the original partially completed LSST work.
   The interrupted N-models phase writes its final archive atomically, so
   its twelve completed evaluations do not provide a resumable archive:
   restart that phase with its same deterministic fifty points.
2. Compare endpoint 4.0 with the project's chosen endpoint using one current
   compiled library and fixed physical inputs. This isolates the endpoint
   effect from the FFT parity and other intervening code changes. Preserve
   the older binary comparisons separately; do not call them endpoint-only
   comparisons. Require identical cosmic-shear and all-Limber vectors.
   Inspect the actual cluster vector for the cluster project; its cc/cg
   projections also use the endpoint and are allowed to change. In DES,
   the two chosen endpoint values are both 4.0, so this check is an identity.
3. Re-expand frozen configurations through the existing generator, so they
   explicitly store `nonlimber_zmax` and the accepted numerical settings.
   Do not edit generated configurations by hand. Review configuration
   differences and stop for unexpected changes to physical parameters,
   input files or priors. Keep the frozen input data copy and preserve
   Roman real's committed `halo_reference.json` byte for byte.
4. Regenerate reference vectors/statistics through the existing freeze
   functions and regenerate baryon references where present. For LSST,
   first verify whether any frozen reference actually selects SVD. Its
   current configurations select FKEM; changing only the inactive SVD cap
   does not change their prediction, but their resolved settings must still
   record 200. Record this distinction in the refreeze history.
5. Regenerate the N-models archives for LSST and all four DESI examples,
   with the original draws, seeds and accuracy settings. Rebuild each
   manifest after the corresponding generated files are complete.
6. Measure and re-pin non-Limber test constants on the new frozen settings.
   Include the SVD constants in LSST, Roman real and Roman KL. Retain the
   separate engine caps in the measurement record. Update the Roman
   Fourier tolerance test's expected FKEM cap to 200.
7. Run each project's quick data-vector tests. Accepted failures remain
   visible in the report: the specified LSST × DESI N-models checks and
   failures demonstrated to occur at the accepted IA-prior edges. Do not
   weaken assertions, remove points or classify unrelated failures as
   accepted. Errors, missing archives, manifest failures and unexpected
   failures stop the queue for investigation.
8. Commit each completed project with explicit file paths. Include the
   numerical YAMLs, matching wrappers, measured constants, generated
   references and manifest that belong to that project. Preserve unrelated
   changes. The interim Roman Fourier notebook stays out of refreeze
   commits. Check all eight Makefiles for both `halo_profile.c` and its
   object; add either only where missing.

The shared test machinery accepts `COCOA_TEST_OMP_THREADS=6`. Its default
remains four, and a race test still requires at least two threads. Driver
and worker environments set `OMP_NUM_THREADS=6`, `OMP_THREAD_LIMIT=6`, and
BLAS thread controls to one before importing native libraries.

## B. Concurrent 3PCF FFTW work

A separate implementation task owns the retained standalone double-Bessel
API and its lifecycle/state tests. It preserves the already-retained
finite-triangle design. Development can proceed concurrently; its heavy
validation shares the same lock and thread budget. No measured-planning
policy or global plan cache is adopted without the evidence required by
the supplied study. The two-point binaries used for refreezing are pinned
independently of these 3PCF source edits.

## C. Notebooks

1. Match wrapper initialization to each likelihood's endpoint, non-Limber
   tolerances, caps and radial sampling. Roman real needs the missing
   projection initialization calls as well as the requested values.
2. Run Fisher derivatives and noise estimates with both galaxy early-exit
   tolerances zero. Restore the production values in a `finally` block,
   including when an evaluation raises. Preserve this guard when an
   accuracy setter changes the effective tolerances.
3. Create Roman KL's missing output directory before executing EV1. Check
   that a finite likelihood evaluation replaces the reported infinity.
4. Execute, serially, LSST EV1/EV2; Roman real EV1/EV2; DES Y3 EV2;
   Roman Fourier EV1; Roman KL EV1; and other EV2 notebooks whose numerical
   settings change. Audit every EV1 for its Fisher section and FoM-noise
   table, with the stated exception for DES cluster's noise table. Every
   EV2 should contain its 3x2pt comparison table. Existing completed cells
   are adapted rather than duplicating the shared Fisher calculations.
5. Use six OpenMP threads and one BLAS thread for every notebook. Preserve
   the notebook's physical parameter choices and scientific caveats.
   Distinguish an illustrative Fisher calculation from a numerically
   converged forecast.
6. After each run, apply the math-label correction, validate notebook
   structure and execution outputs, and inspect every figure. Retain logs
   and separately recorded failures. Commit reviewed notebook outputs in
   their own commits; do not commit the unreviewed Roman Fourier interim
   notebook as part of a reference refresh.

## Completion record

The report will list the eight endpoint values, actual test outcomes,
accepted failures with their evidence, notebook execution/figure checks,
commits and any remaining scientific or numerical limitations. It will
separate the refreeze results from the concurrent FFTW implementation.

## D. Follow-ups after the notebook queue

The user added these after the refreeze/notebook task was already running.
Complete C before beginning this investigation and repair queue:

1. Check derivkit's reported ten-percent discrepancy in the wa derivative
   against independently evaluated finite differences, including the
   w0/wa versus w/w0pwa parameter conversion. Identify and fix the cause
   before deciding whether derivkit or the comparison was wrong. Prevent
   its use from changing the caller's Matplotlib rcParams.
2. Change `cnu.plot_Fisher` so seagreen and firebrick are not adjacent;
   render and inspect the resulting figures in the supported plot modes.
3. Audit wrapper AccuracyBoost propagation. Some current docstrings
   explicitly describe a squared native boost. Trace the actual controls
   and establish the intended convention before changing it. If a fix
   changes C's numerical outputs, regenerate the affected evidence.
4. Give DES cluster's non-Limber cluster rows the same explicit
   early-exit-control discipline as the DES Y3 galaxy rows. The existing
   cluster tolerance of 0.002 must not silently enter Fisher derivatives.
   Include cache invalidation, restoration and numerical checks.
5. Investigate Roman real's slow-tier halo-reference drift. Preserve the
   committed reference during A/C as required; make and document a refresh
   decision here using an independent accuracy comparison. A changed
   reference alone cannot establish that the new result is correct.
6. Complete LSST Y1 with DESI's pending one-loop RSD check E3, locating its
   exact definition in the project records before running it.

## E. Repeat DES 3PCF timings and notebooks after D

The user's new request authorizes the necessary rebuild, output regeneration
and notebook updates in `projects/des_3pcf`. Retain unrelated project edits.
Rebuild its extension from the reviewed core, including the committed
retained-FFTW API, before executing those checks.

Repeat the existing ten-point CLI timing protocol with real recomputation
at distinct parameter points, CAMB excluded from the measured interval,
separate NLA/TATT results, BLAS one, and the current six-OpenMP-worker limit.
Use one/four/six-worker comparisons unless that allocation is explicitly
changed. Keep prior eight-worker results labeled as historical rather than
claiming a new eight-worker measurement. Recheck the current timing driver
and input/provenance conventions before starting; the existing permission
for recorded n(z) clipping remains limited to its stated timing and
demonstration uses.

Re-execute the project's notebooks against the resulting library and inputs,
inspect every figure, and review scientific statements against the actual
outputs. Distinguish reproduction of published results from synthetic or
illustrative forecasts. Save provenance, numerical/test outcomes and timing
plots, and commit the completed work with explicit paths. No push.
