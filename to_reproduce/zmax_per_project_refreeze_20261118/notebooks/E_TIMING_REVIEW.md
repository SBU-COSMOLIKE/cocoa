# Requirements for the next DES 3PCF timing study

This is a source audit made on 19 November 2026 while the C notebook queue
was running. It prepares E, after the D fixes and their validation. No
benchmark, CAMB calculation or compiled prediction was run for this audit.
No production file was changed. Historical timings remain historical.

The requested new study uses ten different physical points through the
command-line interface, with CAMB excluded, separate NLA and TATT cases,
and no more than six OpenMP workers. BLAS must use one. A timing result
must identify the physical calculation, its numerical resolution and what
work the stopwatch includes. A faster calculation of a different observable
or a coarser model does not measure an implementation speedup.

## What the present driver measures correctly

`python/des3pcf/scaling.py` hashes and loads each prepared table archive
before starting the stopwatch. The measured operation is the workload's
`evaluate` call. For the current 3PCF route that includes parameter and
array checks, copying physical inputs, constructing a fresh standalone C
physical model, the projected-bispectrum batches, natural-component FFTs,
aperture contractions and shear calibration. CAMB, source shifting, file
reads and the first fixed-geometry preparation are outside that interval.

`ThreePointWorkload` creates its geometry once and retains it for the ten
points. Its mean engine also retains the transform query geometry. A
separate point warms each process before timing begins; it is not one of
the ten reported points. Each worker count uses the same prepared archives.
Cross-thread checks compare output bytes, and changed-point checks require
different final vectors. The LSST interval similarly includes installing
the prepared cosmology and nuisances and calculating the native vector.

These observations support the present interval definition. They do not
establish that the driver honors every newer configuration option or
contains every recently committed core change.

## Match the current project settings explicitly

The LSST timing control still declares the old low-rank cap of 150 and does
not set the non-Limber redshift endpoint, galaxy-clustering tolerance or
galaxy-shear tolerance. A fresh current core consequently supplies defaults
of zmax=4 and tolerances 0.002 and 0.01. The current LSST 3x2pt likelihood
uses zmax=4.5, zero tolerances and cap 200. The ordinary non-Limber cap also
needs an explicit setter; selecting an inactive low-rank engine must not
be assumed to set the other engine's cap.

Update the timing settings schema and initialization together. Record and
read back the effective endpoint, both caps, both tolerance bases and their
effective values, radial boost, overall accuracy and integration control.
Compare them with the selected likelihood before timing. Keep the existing
all-ones mask and other intentional workload differences explicitly named.
A historical control may retain the old settings if separately labelled;
do not describe it as the current production configuration.

The current timing profiles use 80 aperture entries. New scientific
profiles can use 160 entries, different triangle cuts, and substantially
finer interpolation. The 18 November benchmark record already identifies
large errors in its coarse TATT interpolation. Select and print the new
configuration's actual row count and resolution. Do not divide its runtime
by the older 80-entry runtime and call the ratio an optimization speedup.

## Honor, or reject, every selected physical route

The timing source helper in `scaling_threepcf.py` resamples with linear
`numpy.interp` directly on `physics.z`. It does not use the newer independent
source grid, source interpolation choice or padding controls. The current
scientific route can use measured-bin-edge PCHIP interpolation with 9601
source samples, 401 kernel samples and 129 line-of-sight samples. Merely
pointing the timing YAML at that scientific configuration would not make
the source preparation agree.

Likewise, `ThreePointWorkload.evaluate` calls `mean.physics_model` without
a supplied baseline bispectrum, feedback object or pixel window. A
configuration selecting one of those features would therefore time another
physical model unless the driver forwards it explicitly.

Before preparing any of the eleven CAMB archives, preflight must reject
options the timing route cannot execute. Prefer sharing the scientific
preparation operation where its inputs and timing boundary permit this;
do not maintain a second approximation under the same configuration name.
If a supported timing profile deliberately uses simpler sources or omits
feedback, make that an explicit profile choice. Add checks that supplied
bispectra, PCHIP/source-grid controls, feedback/BACCO and pixel windows are
either passed through and checked or refused before expensive work.

The authorized clipping of the twelve negative Y3 source samples is still
limited to the recorded timing policy and separately approved demonstration
forecasts. Preserve the original input, removed area, normalization and
shift convention. A benchmark change does not authorize altering survey
inputs or turning that policy into a universal default.

## Distinguish standalone construction from bridge reuse

The present benchmark always creates a fresh standalone physical model.
It never calls `core.model_from_core`, so it does not measure the new
bridge's distinction between model construction and query-only IA changes.
The current construction itself ensures the physical model is rebuilt at
each point. Keep that scope in the timing description if retaining this
route.

If the new benchmark instead uses the bridge, install every point through
its normal public setters. Check its model-generation counter outside the
timed interval: each changed cosmology must advance the generation, while
the expected fixed geometry remains reusable. Do not edit internal nonces
or toggle a run mode to force artificial work. The existing bridge cache
tests supply the ownership and rebuild patterns.

A changed final vector alone is insufficient proof of physical
recomputation on a caching route. For example, changing a multiplicative
shear calibration can change the final vector while stale physical tables
remain hidden. Check construction state and compare with an independently
prepared point as well as checking that output vectors differ.

## Preserve the exact execution inputs

The controller already copies each extension binary and verifies prepared
NPZ hashes. Retain those protections and add the following missing checks.

1. **Python implementation.** Fresh workers currently import live project
   and core helpers. Pin the helper sources and compare their identities
   in every worker. Record core/project revisions, changed source hashes,
   compiler flags and relevant native-library identities. Rebuild the
   DES 3PCF extension after D; the installed binary must not be presumed to
   contain the latest commits merely because the branch has advanced.
2. **Fixed survey inputs.** LSST preflight hashes inputs, but initialization
   only checks file existence and the all-ones mask. The 3PCF aperture
   rows are also reread without a comparison to the preflight digest.
   Copy the fixed inputs or compare their loaded bytes with the frozen
   manifest in each worker. A changed file must stop the run before timing.
3. **CAMB lineage.** Record the actual loaded CAMB binary and local source
   or patch identity when creating physical archives. A version string
   does not distinguish the Halofit variants already encountered during
   the refreeze investigation. Archive hashes guarantee that worker counts
   receive the same arrays; they do not alone explain how those arrays
   were generated.
4. **Point identity.** The 3PCF evaluator checks its table metadata against
   the requested physical point. The LSST evaluator receives the table
   bundle without matching its stored `point` against the point bank's
   corresponding index. Add that comparison before the stopwatch. A
   permuted preparation record must fail instead of producing a valid
   timing labelled with another point.
5. **Archive reuse.** Current runs write `tables/lsst_nla`, but the
   `--reuse-from` lookup requests `tables/lsst`. Resolve the recorded format
   explicitly, test the current format and any deliberately supported old
   format, and retain the input checks. Do not silently accept whichever
   directory happens to exist.

## Six-worker execution and plotting

The YAML, configuration validator, point-bank/preflight records, child
environment and plot currently assume one/four/eight workers. The plot's
x coordinates are constants. Update them together for the requested
one/four/six study, deriving plotted coordinates from measured records.
Reject duplicate, missing, noninteger or out-of-limit worker counts before
preparation. The children must verify the actual OpenMP setting and every
loaded BLAS pool. Preserve old eight-worker artifacts without relabelling.

Only after the scientific/configuration checks pass should a quiet-machine
preflight permit timing. The expired earlier quiet window is not evidence
about current load or power conditions. A contended run can be retained
as a diagnostic but cannot supply a new performance claim.

## Checks before accepting a new figure

Cold tests should exercise the unsupported-option failures, worker-count
validation, permuted LSST point record, changed fixed input, changed helper
source and current archive-reuse layout. They should evaluate no cosmology.
After the new extension is built, a small native check must establish
agreement with the selected ordinary scientific route at identical inputs.
Do not accept timing until this agreement and required recomputation checks
hold.

Then run the ten changed points for NLA and TATT with the selected worker
counts, one process at a time and one BLAS thread. Retain individual times,
warmups, arrays, settings and all failures. Compare each point across worker
counts before drawing the median runtime and scaling. The spread across
ten different cosmologies includes physical parameter dependence; it is
not a confidence interval from repeated measurements of one model.

## Source locations inspected

All paths below are within `Cocoa/projects/des_3pcf/`, except where named.
Line numbers describe the source at the time of this review.

| Source | Relevant operation |
| --- | --- |
| `python/des3pcf/scaling.py:73` | Configuration fields and worker-count validation |
| `python/des3pcf/scaling.py:375` | Archive loading before the timed `evaluate` call |
| `python/des3pcf/scaling.py:453` | Changed final-vector check |
| `python/des3pcf/scaling.py:507` | Binary copies; preparation and archive-reuse paths |
| `python/des3pcf/scaling_lsst.py:72` | Legacy LSST workload settings |
| `python/des3pcf/scaling_lsst.py:564` | LSST evaluation and ordinary setters |
| `python/des3pcf/scaling_lsst.py:635` | Fixed-input checks during initialization |
| `python/des3pcf/scaling_lsst.py:695` | Non-Limber setup without endpoint/tolerance setters |
| `python/des3pcf/scaling_threepcf.py:365` | Separate coarse source preparation |
| `python/des3pcf/scaling_threepcf.py:535` | Prepared-table request identity |
| `python/des3pcf/scaling_threepcf.py:709` | Retained geometry creation and aperture-row reread |
| `python/des3pcf/scaling_threepcf.py:729` | Point checks and standalone model construction |
| `python/des3pcf/mean.py:389` | Reused transform query geometry |
| `python/des3pcf/inputs.py:629` | CAMB version metadata |
| `python/des3pcf/scaling_plot.py:144` | Hard-coded worker-count coordinates |
| `scripts/benchmark_scaling.py:24` | Command-line OpenMP limit |
| `../lsst_y1/likelihood/combo_3x2pt.yaml` | Current LSST production settings |
| Core `cosmolike/3pcf/threepcf_interface.cpp:650` | Separate bridge model-generation route |
