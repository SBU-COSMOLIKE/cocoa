# Notebook preparation and validation record

The sources are prepared for headless execution. Native initialization and Fisher-vector smoke checks have passed (see
`NATIVE_RESULTS.md`). Full notebook execution and visual inspection still
follow the remaining project refreezes. No notebook output
is being reported as a newly validated result at this stage. Original notebooks
and wrappers, including the untracked Roman Fourier draft, are preserved under
`original/`. `prepared_paths.json` lists the 21 source files assigned to this
part of the work; no project likelihood or test file was changed here.

## Projection settings

All seven projects that have EV1/EV2 notebooks explicitly initialize their
configured galaxy early-exit tolerances and FKEM multipole cap. Roman real now
also initializes its radial boost of four, galaxy projection flags and separate
SVD cap. LSST and Roman real use zero production galaxy tolerances and caps of
200. Roman Fourier uses radial boost four and FKEM cap 200, with its existing
separate SVD cap retained. Roman KL retains radial boost one for cosmic shear
and caps 200. The DES configurations retain their own projection choices.
Existing per-project endpoint setters are preserved.

`fisher.nonlimber_derivative_mode` receives a compiled interface and the two
production **base** tolerances. It sets both to zero and restores those bases
in `finally`. This distinction matters because the native getter returns
accuracy-scaled effective values; restoring those as bases would divide them a
second time. The nine existing wrapper Fisher-vector entry points now guard
the compiled vector read. LSST EV2's separately defined 3x2pt vector has the
same guard. No C calculation or interpolation rule changes.

The module contains no compiled-interface import. Its four focused state tests
use an explicitly passed small interface class, with no monkey patches.
Success, exceptions, validation before mutation, and accuracy changes inside
the context all passed. The native test will additionally check restoration
after DES Y3 Fisher-vector returns at two boosts.

## What each new table means

| Notebook | Varied parameters in the base matrix | Fixed assumptions |
| --- | --- | --- |
| LSST EV1 | Five ordinary cosmological parameters, two NLA parameters, ten source nuisances, plus w0 and wa | Fisher fiducial w0=-1, wa=0; neutrino mass fixed; does not assert the separate likelihood example has the same w0 |
| LSST EV2 | Existing 29-parameter 3x2pt matrix and its recorded Gaussian priors | Fixed higher-order bias, magnification and point-mass choices are retained |
| Roman real EV1 | Seven cosmological parameters, two NLA parameters and sixteen source nuisances | Neutrino mass and nonlinear-model choices fixed |
| Roman real EV2 | The EV1 parameters plus eight linear galaxy biases | Lens and source photo-z shifts tied as in its YAML; remaining lens nuisances fixed |
| Roman Fourier EV1 | Seven cosmological parameters, two NLA parameters and sixteen source nuisances | Neutrino mass and nonlinear-model choices fixed |
| Roman KL EV1 | Seven cosmological parameters and twenty source calibration parameters | IA amplitude fixed at zero and neutrino mass fixed, as in the example |
| DES cluster EV1 | Only 10^9 A_s and Omega_m | All other cosmology and cluster/galaxy nuisances fixed; explicitly conditional |

The ordinary noise tables marginalize over every parameter in their printed
lists. They do not marginalize over a missing parameter merely because that
parameter exists in the likelihood. Flat prior walls and covariance derivatives
are outside this Fisher approximation.

The base Fisher matrix is computed at default accuracy. Higher-accuracy rows
recompute selected five-point stencils, using the shared fourth-difference
noise estimator. Selecting 99% of the base matrix's weight reduces cost but
does not prove that the omitted noise is small. The explanations state this
limit, the smooth-error limitation, and the fact that an exact diagonal FoM
ratio does not make the stochastic-error approximation exact. Existing DES
noise explanations were revised to remove stale numerical conclusions before
new execution.

Cluster EV1 has a two-step conditional Fisher example but no noise table. The
cluster-specific early-exit tolerance is not exposed through a Python setter,
so it stays active. The example does not claim its derivatives have converged.
Cluster EV2 remains excluded from the noise table.

## Saved state and execution

LSST EV2 forces Fisher recomputation and records endpoint, radial boost,
multipole caps and zero derivative tolerances with its saved matrix. It still
requires manual recomputation after a model-code or input-data change: its
cache is not advertised as a complete content-addressed archive.

Roman KL's initialization now uses its project wrapper and creates `chains/`
before optional diagnostic output. A finite likelihood value still needs to
be demonstrated by execution. The runner creates per-attempt directories,
checkpoints every completed cell and preserves failures. It records source,
wrapper, binary and shared-Fisher hashes, six OpenMP workers and one BLAS
worker. The project notebook is replaced only after every cell succeeds.
Every PNG output is exported with its cell index for later visual inspection.

## Cold checks

- Four state-restoration tests passed; command and result in `cold_checks.log`.
- All 11 notebook files passed notebook-structure validation and Python syntax
  checks after IPython transformation; output in `structure_checks.log`.
- All eight project wrappers parsed with `ast.parse`.
- Native Fisher-return checks subsequently passed; see `NATIVE_RESULTS.md`.
- Full notebook runs and new figure inspection remain pending.

Unrelated inherited issues noticed during reading are not hidden: some old
wrapper comments retain draft markers, some old notebook sections contain
quantitative prose tied to earlier outputs, and the existing notebooks with
many retina figures range up to about 18 MB. Final notebook review must check
those statements against the new outputs and inspect the figure labels.

## LSST Y1 × DESI Fisher entry points

The separate DESI Fisher module and the older notebook wrapper now use the same
zero-tolerance rule. `ModelFisher.dv` guards the full likelihood evaluation and
the final saved/native vector read, so a failed likelihood restores production
bases too. The stored-vector route retains the stochastic terms the DESI
likelihood adds outside C. Its Fourier projections do not early-exit.

A real-space model fingerprint records `derivative_nonlimber_tolerances`
explicitly; old real-space caches without this rule must be regenerated. No
policy field is added to Fourier fingerprints because their computation does
not change from this guard. The newly resolved endpoint settings can still
invalidate existing Fourier caches independently. No archived cache is edited
or replaced, and dedicated DESI Fisher notebooks are outside this execution
queue. Both changed modules passed Python syntax checks.

A further inherited discrepancy needs to be stated when reviewing Roman Fourier
outputs: its notebook says the wrapper defaults reproduce its YAML, but the
wrapper's default global boost is one while EV1 YAML uses two. This work changes
the requested radial boost and multipole caps; it does not silently reinterpret
the earlier global-accuracy scans.

Roman Fourier now states and prints its AB1 notebook baseline versus AB2 in the production YAML, with radial boost four, endpoint five and FKEM cap 200 explicit. The other inspected EV1/EV2 YAMLs use a global boost of one.

## Final source review while refreezes run

LSST EV1's inherited claim that DerivativeKit makes AccuracyBoost 3 the
"safest" choice was removed before execution. Its text now distinguishes
reduced uncorrelated noise from smooth numerical errors and requires checks
of step size and parameter definitions. This is a claim correction, not the
separate DerivativeKit investigation in follow-up D. The notebook structure
and transformed Python syntax pass the existing check-only runner.

The same qualification now appears in the other EV1 derivative comparisons.
Legacy Fisher introductions explicitly hold the data covariance fixed, and
LSST's Limber glossary retains the distance integral. LSST and Roman real
explain that their dark-energy noise sections build new 19- and 25-parameter
matrices; the earlier amplitude/matter forecasts condition on fixed dark
energy. Their two kinds of FoM are therefore not interchangeable.

DES Y3's recorded external ten-percent wa discrepancy is retained with its
settings and its provenance limit: those numbers are not generated by the
current cells and do not identify which derivative is accurate. Planck's
old ten-worker timings and hard-coded Fisher conclusions were removed;
the executed outputs will supply the current measurements. Roman Fourier's
draft markers were replaced and its stated FKEM cap is 200. Roman real's
accuracy contour legend now labels all five matrices. These revisions leave
the numerical Fisher calculations unchanged. All eleven prepared notebooks
again passed structure and transformed Python syntax checks.

The runner also fingerprints the shared notebook helper sources, each CAMB
package's Python sources and native binary, project likelihood/configuration
files, and the contents of project data files. Directory links are followed
with cycle detection; Git metadata is excluded. Roman real EV1 additionally
pins the four supplied MCMC chain inputs (samples, parameter names, ranges
and properties), excluding generated GetDist caches. Notebook-owned Fisher
caches and output directories are outside the input map.

A temporary final cell checks the actual CAMB binary imported by the kernel
against the pinned installed/source copies and records its resolved path.
Both native copies currently have the same hash, but their Python sources
are pinned separately. The audit cell evaluates no cosmology and is removed
before publication. Failed audits retain the executed checkpoint without
replacing the project notebook. Cold tests verified changed/restored data,
added/removed YAML files, external directory links, cycle termination and
rejection of a wrong native hash; they evaluated no scientific model.

The same final audit cell saves completed Fisher matrices in
`completed_fisher.npz`, with variable names, shapes, available fiducials and
parameter labels in `completed_fisher.json`. Only numeric square arrays,
same-shaped lists of these arrays, and a dictionary's numeric `F` member
are selected. Object arrays, models and native interfaces are excluded;
loading the NPZ requires no pickle. This records values still present at
the end, not overwritten intermediates, and does not guess which label
list belongs to which parameter basis. Cold checks verified these boundaries
and that source arrays remain unchanged. These files are execution evidence
for later plotting checks; they do not replace or alter scientific caches.

The nine Limber/non-Limber galaxy-spectrum labels in LSST, Roman real and
DES Y3 EV2 now use raw Python strings and braced `\mathrm{L}` or
`\mathrm{NL}`. Their notebook syntax checks passed; figure inspection
will verify their rendering after execution.

Roman real EV1 now states the provenance limit of its archived MCMC
comparison. Its parameter-name file contains the same 23 sampled
coordinates and 17 derived columns, but the supplied properties file does
not establish matching data, priors, model and numerical settings. The
notebook reads that chain rather than rerunning it, so differences cannot
be attributed to the local Gaussian approximation alone. LSST EV2 also
states the linear non-Limber plus nonlinear Limber correction explicitly;
its density-only formula is identified as a schematic contribution.
These changes affect explanations only.

The shared Fisher explanations were subsequently corrected in core
`48da11f`: a fourth difference may contain smooth curvature; a small
base-matrix weight does not bound an omitted column's noise; and the
small-noise FoM criterion is an approximation rather than a guaranteed
error bound. The executable AST is identical to the previously tested
source. The source audit is `../fisher_noise_doc_audit.json`; execution
fingerprints will include this final helper file.
