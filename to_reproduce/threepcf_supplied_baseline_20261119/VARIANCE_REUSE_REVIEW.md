# Reusing the core variance tables

Source review on 19 November 2026, core `2bc4500`. This records the
remaining integration handoff's item 2. No numerical comparison or
implementation was performed for this review. The completed supplied-baseline
comparison does not establish acceptance of the changes described here.

The proposed reuse changes three aspects of the calculation. Test each
separately before combining them. A faster variance calculation and a
different physical growth prescription must have separate comparisons.

## Amplitude normalization

`physics_3pcf.c`, around line 1501, multiplies the supplied linear spectrum
by the square of its separate input sigma8 divided by its own variance at
8 Mpc/h. Its normalization integrates from 0.001 to 100 h/Mpc; subsequent
fit variances begin at 0.0001 h/Mpc. The core variance readers use the
amplitude of the supplied power spectrum directly.

Removing the extra normalization affects the internal BiHalofit fit,
tree-level diagnostics, linear-power IA mode 0 and the halo covariance.
The last three can change even when the absolute baseline bispectrum is
supplied. The Python BiHalofit producer reproduces the normalization in
`bihalofit.py`, around lines 404–422, so its convention must be updated
with the C consumer after validation. The redundant model-input scalar is
distinct from sigma8 as a forecast parameter: the latter remains a valid
way to determine the upstream power-spectrum amplitude.

## Redshift evolution and matter field

The local calculation uses the redshift-zero linear spectrum multiplied
by scale-independent growth squared (`physics_3pcf.c`, around line 1752).
The bridge copies that zero-redshift row. Shared core variances integrate
the supplied redshift-dependent spectrum. Massive neutrinos can make the
growth depend on wavenumber, so this replacement changes the approximation.

BiHalofit needs the total-matter readers `sigma2_matter`, `sigma8_matter`
and the total-matter Gaussian variance functions. The ordinary `sigma2`
reader selects cold dark matter plus baryons. The three-point covariance
currently uses total-matter variance, total density and factorized growth
with its own Sheth–Tormen and Duffy prescriptions. Replacing only its
variance by the cold-component variance would mix physical conventions;
the corresponding density and mass-radius/neutrino prescription would
also need to be specified and tested.

## Gaussian high-wavenumber tail

The local unit-variance radius solve includes an analytic continuation
above 100 h/Mpc (`physics_3pcf.c`, around line 1058), but its logarithmic
slope calculation passes `tail=0` around line 1089. Core variance and
slope differentiate the same continued spectrum. The omitted local slope
tail can produce a difference that remains when its quadrature is refined.

Start with the same factorized power spectrum and amplitude in each
implementation. Then change amplitude normalization, redshift evolution
and tail treatment one at a time. Only their combined comparison tests
the intended final behavior.

## Numerical contracts

| Quantity | Local three-point calculation | Shared core |
|---|---|---|
| Units | k in h/Mpc, R in Mpc/h, P in (Mpc/h)^3 | Same units for these variance readers; no coverH0 conversion |
| Power reads | Cubic preparation, then dense uniform linear reads | Uniform log-k and piecewise-uniform z, linear reads of ln P |
| Power support | Lower bounds above; upper bound 100, optional Gaussian tail | Endpoint power-law continuation over approximately 1e-7 to 1e25 h/Mpc |
| Gaussian radius | Bisection can extend below 0.01; upper bound 1e4 | Table spans 1e-3 to 1e2 Mpc/h |
| Root and slope | Simpson integrals, root tolerance 1e-5 | FFTLog, dense tables and inverse-table interpolation |
| Fit redshifts | Usually 33 uniform-z anchors, cubic preparation, dense reads | Uniform scale-factor tables, default 256 nodes |

A root outside the supported radius table is not proof that no physical
unit-variance radius exists. Check the domain explicitly rather than
interpreting a clamped value as the root. The top-hat slope also has a
different normalization: `dlnsigma_dlnm_field` returns d ln sigma/d ln M;
the local covariance uses d sigma²/d ln M, requiring a factor 2 sigma².

## Owned preparation arrays

The safe boundary is serial table preparation followed by a copy of the
required results. Prepare the core tables in the state that owns the
power spectrum, then copy redshift, nonlinear radius, effective slope and
sigma8(z) at declared fit anchors into an immutable input object. Record
the matter field, growth convention, numerical controls and input hashes.
Both the internal fit and Python producer can then consume those arrays
without another variance solve or amplitude normalization. An absolute-B
model should still skip fit preparation that it does not use.

Retained models must own their arrays. Callbacks or pointers into mutable
core state would invalidate the retained-old-owner contract when the
next cosmology is installed. The full-growth route must require the full
evolving linear power input explicitly. A factorized comparison input
must be labeled as such rather than synthesized silently when data are
missing.

The standalone DES 3PCF Makefile currently links basics, structs and the
bridge, but not `cosmo3D.c`; the six variance readers have no Python
bindings. This therefore requires build/export work. Do not depend on
symbols from a separately loaded project's extension. Covariance variance
and slope arrays can follow the same copied-input ownership contract in
a separate adoption step.

## Acceptance evidence to produce

Existing project fixtures provide the following starting points. Their
hashes and parameter bases must be checked before reuse.

| Check | Existing inputs and driver | Required comparison |
|---|---|---|
| Small integration test | `tests/data_vector/reference_bihalofit/` and `test_bihalofit_joint.py` | Four rows with a complete joint covariance; useful for interface and ownership checks, not survey acceptance |
| Joint mean | `tests/studies/bihalofit_joint.py` and `results/bihalofit_joint_y3.json` | All 400 two-point and 80 Map3 rows; quadratic displacement no greater than 0.01 |
| Derivatives and forecasts | `runs/{nla,tatt}_accuracy/triangle_1p5_full_fisher.npz` and `runs/{nla,tatt}_full_h4/full_h4.npz` | Every whitened derivative-column relative error no greater than 1e-3; marginalized errors and pair FoMs change by no more than 0.5% |
| Covariance terms | `tests/covariance/test_physical_covariance.py` and `tests/studies/covariance_refinement.py` | Independent halo variance, abundance responses and individual covariance contributions |

The mean criterion is the vector difference contracted with the inverse
covariance, `(new - reference)^T C^-1 (new - reference)`. It is not the
signed change in the likelihood chi-squared. Derivative comparisons need
the same covariance, rows, priors, parameter basis and stencil points.
For a whitened derivative column, compare the norm of its difference
with the norm of the reference column.

Repeat the acceptance checks after independent refinement of power
sampling/support, Gaussian tables, fit anchors and derivative steps.
Include massless and massive neutrinos, amplitude and dark-energy
displacements, retained-model A/B/A changes, resets and one/six-worker
agreement. The stored Fisher studies document absolute step dependence;
passing this replacement comparison would not establish overall Fisher
convergence.
