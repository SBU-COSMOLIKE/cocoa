# Project endpoint refreeze and retained FFTW preparation

The refreeze and notebook queue is in progress. This record separates
completed checks from work still running. The configuration and ordering
are specified in [PLAN.md](PLAN.md). All heavy jobs are serial, with at most
six OpenMP workers and one BLAS worker. No changes have been pushed.

The isolated endpoint comparisons vary only the `nonlimber_zmax` control
with the binary, parameters and other settings fixed. At a fixed radial
node count, changing the endpoint also changes the logarithmic radial and
Fourier spacings: the projection uses
`dlnchi = log(chimax/chimin)/(nchi-1)` and `dlnk = dlnchi`. These comparisons
therefore isolate the endpoint control from unrelated code changes, but
do not separate omitted-domain error from sampling error. That separation
requires varying the endpoint and node count together; the present
refreeze does not establish it.

Independent input audits now cover the first seven projects: 325 manifest
entries and 28 frozen sampled points, parameter definitions and prior
dictionaries match their saved originals. Frozen physical input data are
unchanged; only generated model-vector files move. Roman real
`halo_reference.json` is unchanged. The Roman real audit was performed
while its quick checks were still running, so this input result is not a
claim that those checks have passed. The separate records are
`root_manifest_audit_first_four.json` and the Roman Fourier, Roman KL and
Roman real files with the same prefix.

## Completed implementation and binding checks

The shared test harness accepts an explicit `COCOA_TEST_OMP_THREADS=6`
override while retaining its normal four-thread default. Two import tests
passed, including invalid counts and the serial-count rejection needed by
race tests. The harness also reads the correct extended Fourier vector for
LSST Y1 with DESI and does not insert its absent galaxy-lensing probe.
These changes are committed in core `7a3ae44`.

The endpoint bindings for Roman KL and LSST Y1 with DESI were built
privately, tested, and installed with backups. Their endpoint suites passed
9 and 7 checks respectively. The tests cover finite values at least four,
reset to four, independence from sampling boosts, notebook validation
before mutation, and repeated endpoint changes against fresh processes.
Both project YAMLs explicitly retain the handoff's endpoint of 4.5.

The concurrent FFTW work is committed in core `f9ccd3b`.
`production.TwoBesselPlan` and its notebook adapters retain immutable
geometry, Mellin kernels, aligned arrays and two FFTW plans. Each new input
recomputes the forward coefficients; several requested Bessel-order pairs
can then reuse those coefficients. Returned arrays own their values.
Constructor checks compare every worker slice's actual FFTW alignment
class with the planning buffers.

Both strict and UBSan builds passed 94 tests. Private instrumentation
observed twenty plan creations/destructions for ten one-shot calls, and
two creations with no intervening destruction for ten calls through one
retained owner. NaN-filled private allocations checked complete FFT input
and padding initialization. Full arrays were checked against one-shot and
independent numerical references, with state changes, multiple owners,
reset, destruction order and one/four/six-worker finite-triangle cases.
The durable commands, hashes and limitations are in the core's
`dev_scripts/threepcf_fft_plan_check/RUN_RECORD.md` and `validation.json`.

The installed DES 3PCF extension has not yet been rebuilt. The later request
to repeat its timings and notebooks authorizes that rebuild in phase E,
after the notebook queue and follow-ups. Its existing API is unchanged.
The new API is built and usable in the private validation extensions, and
becomes available in the project after its rebuild from committed core.
No speedup is claimed: the finite-triangle forecast already retains its
plans. Sharing plans across geometry owners and changing the planning
policy remain separate experiments requiring measured evidence.

The concurrent supplied-bispectrum implementation is committed in core
`1fa68b0` and the DES 3PCF project `1086ce5`. Its validation and scientific
limits are recorded in the [supplied-baseline status](../threepcf_supplied_baseline_20261119/STATUS.md).
That work also awaits the phase E installation; it does not change the
installed two-point libraries used for this refreeze.

## DES Y3 reference history

DES Y3 passed all 108 quick tests and thirteen endpoint/state comparisons,
and its cumulative reference update is committed as `f429b69`. The endpoint
is four in both sides of the isolated comparison, so every observable block
is identical. The historical September 30 references nevertheless differ
in shear, galaxy-shear and clustering entries. Those comparisons span later
growth, quadrature, projection and FFT changes; they are not endpoint-only
differences.

A separate four-vector check verifies that explicitly selecting the current
growth sampling at 0.05/Mpc reproduces all regenerated columns exactly.
Reinstating the old 0.0005/Mpc convention alone does not recover the September
vectors. The controlled Halofit comparison described below supplies the
additional shear attribution and identifies the remaining residuals.
The durable project file `tests/refreeze_record_20261119.json`
retains the old source IDs, tested binary hash, column/block comparisons,
growth comparison and this limitation. Frozen physical parameters, priors
and sampled points were preserved.

## DES Y1 × Planck checks

All 91 quick tests passed, and the reference update is committed as
`ec63a45`. Seven endpoint/state comparisons cover the complete six-block
vector: shear, galaxy-shear, galaxy clustering, galaxy-CMB lensing,
shear-CMB lensing and CMB-lensing autocorrelation. Every entry is identical
between endpoints four and four, including restored evaluations.

The configuration audit preserved the older sampled lens parameters and
priors. The live likelihood's later `fixed_params` block would fix the
fifth and sixth lens-bin nuisances, so generated reference configurations
explicitly set that option to null. The resolved parameter blocks and
sampled points equal their original versions. The first rejected expansion
and the successful retry both remain recorded.

The comparison with September 30 vectors finds cumulative differences in
each active observable block; it is separate from the exact endpoint-only
comparison. File hashes, all serialized-column comparisons and the previous
reference commit are retained in `tests/refreeze_record_20261119.json`.
This evidence does not assign the cumulative differences to individual
historical commits. Notebook outputs remain pending the rest of phase A.

## DES cluster checks

All 73 quick tests and nine endpoint/state comparisons passed. The reference
update is committed as `eb6fc9d`. The shipped 2,812-entry cluster vector is
unchanged in every serialized column and in file bytes. The current theory
has reference chi-squared values of `1.0390264834404088e-05` for the 4x2pt
plus counts example and `0.00022056552534465635` for the 6x2pt plus counts
example; both older references were zero. The two generated galaxy-only
NLA/TATT vectors have separately recorded cumulative shear, galaxy-shear
and clustering differences. The exact endpoint-four comparison changes
none of these rows.

The shared comparison script includes both `.modelvector` files and the
cluster `.datavector` file. It verifies row indices and every serialized
numeric column, and uses the native seven-block layout for cluster data.
The project record retains its source history, exact binary hash, numerical
settings and test outcomes. The bounded private CAMB comparison below tests
the installed Halofit tolerance directly; file modification dates are not
used as evidence of when it was first enabled.

## Controlled Halofit attribution

The [private CAMB comparison](../refreeze_halofit_attribution_20261119/RESULTS.md)
changes only the Halofit bisection tolerance between 0.001 and 1e-7, with
separate evaluations at growth sampling 0.0005/Mpc and 0.05/Mpc. Thirty-six
fresh-process evaluations preserve the physical points, inputs, native
libraries and projection controls. All twelve rebuilt patched-CAMB controls
reproduce the installed model-vector files byte for byte; linear-power probes are
identical between the two tolerance choices. No installed library changed.

Stock tolerance with the older growth convention restores every shear
value in the DES Y3/Y1 NLA/TATT vectors and every DES Y1 galaxy-shear value.
For the cluster project's two generated galaxy-only vectors, stock tolerance
with the current growth convention restores shear and galaxy-shear values
exactly. This is a measured explanation of those blocks at their frozen
points; the original reference records did not pin their CAMB binaries.

DES Y3 galaxy-shear still differs by up to `3.13989e-7` for NLA and
`3.258402e-7` for TATT. Its saved setting is explicitly Limber, so the
remaining historical drift cannot all be classified as non-Limber.
Galaxy-clustering residuals also remain; in the cluster galaxy-only example
their largest magnitude is `2.742999999985618e-7`. These residuals are not
assigned to individual historical commits. The full 2,812-row cluster model
and baryon-emulator vectors were outside this diagnostic.

The project records include the full controls, hashes and limitations in
DES Y3 commit `df047e8` and DES cluster commit `d6f9353`. Production retains
Halofit tolerance 1e-7 and growth sampling 0.05/Mpc. The isolated endpoint
comparisons remain the evidence that changing only the endpoint leaves the
protected observable blocks identical.

## Roman Fourier endpoint checks

Roman Fourier is committed as `42428b3`: 88 tests passed and one
real-space-only stencil test was skipped because Fourier vectors never
take that early exit. Configuration expansion, seven endpoint comparisons,
reference generation, baryon references and constant measurements passed.
The shared cap-expectation helper is core commit `0de919b`, with identical
file content during the run and commit. The independent audit confirms all
34 manifest hashes and all three frozen points, parameter dictionaries and
priors; no physical input file changed. The interim notebook remains out
of this commit. At the frozen fiducial, changing only the endpoint from four to
five changes 330 galaxy-shear entries and 48 clustering entries. They are
exactly the first six bands of each active spectrum, below the FKEM cap of
200. All shear entries and all galaxy bands at multipoles at least 200
remain identical. The all-Limber and endpoint-restoration checks also pass.

The squared vector displacement is
`delta_m.T @ inverse_covariance @ delta_m = 0.0011282403045923335`
for the full NLA 3x2pt fiducial. This is distinct from the earlier difficult
parameter point's reported change of about 0.20 in likelihood chi-squared
when the endpoint moved from 4.5 to five: that uses a different physical
point, different endpoints and a different statistic. The fiducial checks
do not establish convergence at endpoint five throughout the prior or for
Fisher derivatives. The noise table holds the endpoint fixed and cannot
test that source of systematic numerical error.

The shipped Roman data vector remains byte-identical. The comparison with
older generated TATT and baryon vectors includes shear changes of about
`3.4e-13`, recorded separately from the endpoint-only comparisons. Their
historical attribution is not inferred from the DES controls.

The offline raw-bit audit in `endpoint_bits_first_six.json` confirms that
all 50 saved endpoint baseline/target comparisons in the first six projects
have the same numeric and bitwise change masks, including signed zeros.
The earlier restoration checks asserted exact numerical equality but did
not retain restored arrays. Subsequent Roman real/DESI checks also assert
bitwise restoration and preserve those arrays; this distinction does not
require another scientific evaluation of the completed cases.

## Roman KL endpoint checks

Roman KL is committed as `14281fd`, with portable reproduction evidence
in follow-up `d1730d3`. Its original quick suite had 91 passes, one failure
in the cap-150 SVD/FKEM fourth-difference comparison, and one intentional
Fourier skip. That complete log/XML remains unchanged. The corrected
comparison and production-restoration tests pass, giving 92 applicable
passes and one intentional skip across the full run and targeted retry.
Configuration, endpoint, reference, baryon and constant phases passed.

Five fresh-process controls identified the failure's cause: the legacy SVD
run kept the galaxy-shear cap at 200 while the paired FKEM run used 150.
At cap 150, matching that setting changes the SVD w0 diagnostic from
`0.004545113503941975` to `0.004134682950091227`, against FKEM's
`0.004129304802344561`. All fifteen paired shear and galaxy-shear stencil
vectors are bitwise identical after matching; old-to-corrected SVD changes
675 galaxy-shear values and no shear or clustering values. Both caps pass
the original margins, and every private process restores production
bitwise. The fourth difference still includes smooth curvature; this
control does not establish purely stochastic numerical noise.

Core commit `2bc4500` fixes only the test helper's cap placement and its
explanation. Six targeted checks passed across Roman KL, LSST Y1 and Roman
Fourier, with unchanged native libraries, inputs and numerical margins.
Their portable records include the reproduction command, old/new helper
revisions and five-process input hashes. LSST's supplement is `f682191`;
Roman Fourier's is `eb51b99`. An independent cold audit
verifies all 51 manifest files and all five frozen evaluation points,
parameter dictionaries and priors; no physical data input changed. At the full 3x2pt NLA
fiducial, the endpoint 4→4.5 comparison changes 405 galaxy-shear and 90
clustering entries, with squared vector displacement
`4.550362021557787e-05`. All 1,100 shear entries are identical. The changed
galaxy rows occupy only the first nine of twenty bands, through
multipole 190.09, below the FKEM cap of 200. All higher bands, the
all-Limber comparison and endpoint restoration are exact.

The separate old-reference comparison has identical shear in the two
regenerated 3x2pt vectors. The FLAMINGO vector changes 23 serialized shear
values by at most `1.0e-16`; this small historical difference is recorded
rather than attributed to the endpoint.

## Roman real checks

Roman real is committed as `064cb94`: 127 tests passed and 24 slow
halo-model checks were explicitly skipped under their existing default
policy. No numerical assertion was relaxed. All seven endpoint/state
comparisons passed, including saved bitwise-restored vectors. At the full
NLA fiducial, changing the endpoint from four to 4.5 moves 769 galaxy-shear
and 101 clustering entries, with squared vector displacement
`1.3310599774914823e-4`; all 1,080 cosmic-shear entries are identical.

The older TATT reference also retains its shear entries exactly. The
FLAMINGO reference changes 25 serialized shear values by at most
`1.0000000502143058e-13`; these historical differences are separate from
the endpoint comparison. The protected `halo_reference.json` remains
byte-identical to its committed version. The record pins the repaired
shared-cap comparison helper `2bc4500`; all its existing bounds pass.
Only explanatory test prose changed after execution, with the executable
AST verified unchanged. The two notebook outputs remain pending phase C.

## LSST Y1 × DESI configuration scope

The live DESI examples now select the model-B likelihood, whereas the
stored regression configurations select the earlier linear-bias model.
The first standard configuration expansion therefore stopped on the
changed likelihood name. This refreeze preserves all five stored physical
models and resolves them through Cobaya with endpoint 4.5. The current
live model-B physics is not substituted into those regression tests.

Every parameter, prior and sampled point remains identical. Resolution
makes the existing default galaxy tolerances explicit and records the
already-disabled higher-order bias, nonlinear Kaiser and orientation
selection controls as zero, zero and null. Their fallback values were
checked in the likelihood source before acceptance. Both rejected
attempts and the successful field audit are retained. Endpoint comparisons,
reference generation, the four random-model archives and the final quick
checks now run in order; their results are not yet complete.

## LSST endpoint comparison

The same current library and frozen physical point were evaluated at
endpoints 4.0 and 4.5. Of 1,560 entries, 198 galaxy-lensing and 56 galaxy
clustering entries change. All 780 cosmic-shear entries remain bitwise
equal. The covariance-weighted difference is
`5.7424027298554934e-06`. The all-Limber vector is bitwise unchanged, and
the endpoint round trip reproduces the original vector numerically exactly.

The configuration audit found only the explicit endpoint and the accepted
inactive SVD-cap change from 150 to 200. Frozen predictions select FKEM.
Physical parameters, evaluation points and priors are unchanged. Generated
reference and baryonic-feedback vectors are complete. The deterministic
50-model high-accuracy archive completed all fifty points. Non-Limber
constants were measured with bitwise state round trips: clustering
148.96733723247738, galaxy lensing 1.887714086298397, and SVD versus FKEM
0.0016079769394488925. All 115 quick-test cases passed across the full run
and one targeted retry. The first run passed 114 cases; its original-EE2
comparison could not link GSL because the job lacked Cocoa's compiler and
library settings. The unchanged failed case passed after sourcing the
normal build environment. Both XML records and their hashes are retained;
no assertion or reference was changed to resolve that build failure.
The refreeze is committed in LSST `57b50d5`.

The fifty-point accuracy check is advisory in this project
(`NMODELS_LIMIT=None`); a passing test therefore does not certify a bound
of 0.2 across the prior. Its median squared vector difference is 0.005377
and its maximum is 1.439154. With the amplitude, matter density and linear
galaxy biases fixed to their fiducial values, the maximum is 0.058521.
The generated scatter figure was visually inspected: labels, scales,
legend and the advisory 0.2 line are legible. These accuracy results are
distinct from the much smaller endpoint-only comparison above.

## Random-model archives and CAMB warnings

The completed LSST archive retains all fifty original sampled points
byte for byte, with identical names, held flags, seed and draw rules.
Every regenerated vector entry is finite. The same offline comparison
will check the four DESI archives after their generation completes.

CAMB printed a transfer-time integration warning in the LSST log and
in the ongoing DESI generation. This is not an established observable
error budget: its message omits the actual time discrepancy. The Fortran
output is buffered. In LSST, 640 lines appear between Python progress
messages for models two and three, and another 49 appear after all fifty
vectors were stored. Those positions therefore cannot identify the
physical row that caused each warning. The records retain log boundaries,
warning counts and the candidate progress-point information with that
limitation explicit. Finite likelihoods and vectors do not establish
convergence; neither warnings nor failed accuracy bounds are suppressed.

## Notebook preparation

The prepared notebooks distinguish marginalization over their listed
parameters from quantities conditional on parameters held fixed. The base
Fisher matrix is computed once at default accuracy; selected higher-accuracy
stencils estimate derivative-noise information. This is a noise diagnostic,
not proof that smooth discretization errors have converged.

The shared derivative context restores production base tolerances in a
`finally` block, including after an exception. It never treats the
accuracy-scaled native getters as base tolerances. Four state tests passed.
The prepared eleven notebooks passed structure and transformed-Python
syntax checks. All eleven native smoke phases also passed: eight wrapper
initializations, DES Y3's boost 1-to-2-to-1 state round trip, and DESI
Fourier and real-space Fisher reads. Restored tolerances match their
accuracy-scaled production bases, and the repeated DES vector is bitwise
identical. The shared helper is committed in core `87195ee`.
Full notebook execution and visual inspection remain pending; no old
output is represented as a new result.
The detailed notebook record is [PREPARATION.md](notebooks/PREPARATION.md).

## Run records

Each project receives `projects/<name>/queue.json`, per-phase logs,
configuration differences, endpoint arrays and measured constant records.
The driver stops on unrecognized failures. It does not relax assertions or
silently accept failed reference generation. The explicitly allowed DESI
N-model accuracy failures will retain their diagnostics; any IA-edge
classification requires checking the failing physical points.

The first DES Y3 configuration audit found previously unrecorded inactive
histogram controls and unit power-grid refinement, plus narrower priors
in today's live examples. The generation procedure preserves the original
frozen physical parameter/prior blocks and point, resolves that model
through Cobaya, and records the live-prior differences separately. New
explicit inactive controls are accepted only at the values previously
used by the likelihood's fallback. Unrelated physical changes still stop
the audit. Prior rollout remains a later task.

The original frozen state is copied before generation. Roman real's
`halo_reference.json` must remain identical to its committed bytes.
Notebooks are committed separately after execution and figure review;
the interim Roman Fourier notebook is excluded from reference commits.
