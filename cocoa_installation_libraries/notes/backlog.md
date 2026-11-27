# Cocoa execution backlog

Tracked in Git so unfinished work survives a new clone and a new
maintenance session. The commit that closes a ticket updates its entry
in the same change.

## Contents

- [Open tickets](#open-tickets)
- [Closed tickets](#closed-tickets)

## How to read this backlog

Active scope (2026-11-26): finish the required DES Y6 work below. The
cluster-robustness derivative repair is complete; the full LambdaCDM
plus CMB 3x2pt Nautilus timing run has restarted from scratch with the
repaired emulator-only theory. Native CosmoLike timings and all 92
configuration startup checks are complete. The requested cache review
and its three fixes are complete. Other older tickets remain recorded
but are outside this work queue.

One line beginning exactly `- OPEN` per unfinished ticket in the index
below, each carrying `BUG FIX` or `NEW FUNCTIONALITY`. Never a second
`- OPEN` line inside a ticket. Every ticket has one anchored section
with its summary, status, and what is missing; pointers to files and
commits go in the collapsed technical record at the end of the section.

<a id="open-tickets"></a>
# Open tickets

Severity sorts first, type second: High bugs, Medium bugs, Medium
features, Low bugs, Low features.

- **High** — the science can be wrong, data can be lost, or a core
  operation halts.
- **Medium** — a concrete problem reasonably likely during normal
  work, below the High boundary.
- **Low** — concrete but improbable edge cases.

## Open ticket index

### High

- OPEN **HIGH** **NEW FUNCTIONALITY** — [Covariance-owned all-pairs non-Limber spectra](#open-covariance-nonlimber)
- OPEN **HIGH** **NEW FUNCTIONALITY** — [NLA in complete covariance forecasts](#open-covariance-nla)

### Medium

- OPEN **MEDIUM** **NEW FUNCTIONALITY** — [DES Y6 comparison and PPD studies](#open-des-y6-studies)
- OPEN **MEDIUM** **NEW FUNCTIONALITY** — [Rewrite analytic covariances in an isolated module](#open-covariance-rewrite)
- OPEN **MEDIUM** **NEW FUNCTIONALITY** — [Project endpoint refreezes, notebooks and numerical follow-ups](#open-project-endpoint-refreeze)
- OPEN **MEDIUM** **NEW FUNCTIONALITY** — [Remaining 3PCF integration follow-ups](#open-threepcf-integration-followups)


- CLOSED **MEDIUM** **NEW FUNCTIONALITY** — [Modernize the DES Y6 project](#closed-des-y6-modernization)

### Low

- OPEN **LOW** **NEW FUNCTIONALITY** — [IA x higher-order-bias (gb2) cross terms in cfastpt](#open-cfastpt-gb2-ia-bias)
- OPEN **LOW** **NEW FUNCTIONALITY** — [Web-halo model (WHM, arXiv:2508.10902) for nonlinear P(k)](#open-web-halo-model)
- OPEN **LOW** **NEW FUNCTIONALITY** — [Vectorization study for halo.c (SIMDe, SLEEF)](#open-halo-vectorization)

<a id="open-des-y6-studies"></a>
## DES Y6 comparison and PPD studies

**Ticket type: NEW FUNCTIONALITY. Severity: MEDIUM. OPEN (2026-11-24).**

Current priorities (2026-11-26):

1. Cluster-robustness derivative repair completed in core `72a63a7` and
   DES Y6 `d1d295c`. The derivative calculation keeps a fixed non-Limber
   multipole range; ordinary sampling tolerances remain unchanged.
2. Time the maintained case-1 LambdaCDM plus CMB 3x2pt Nautilus run with
   ten MPI ranks, one native OpenMP thread per rank and BLAS=1. Ten ranks
   provide nine likelihood workers and one coordinator. The target is
   15,000 effective posterior samples, with a safety cap of 5,000,000
   likelihood evaluations. Apply these defaults to the shared Nautilus
   driver while preserving explicitly bounded test runs. Retain the
   checkpoint and report the actual convergence status and elapsed time.
   After convergence, run case 11 (CPL plus CMB), then cases 21 and 31
   (LambdaCDM and CPL DES-only) unless the user changes the schedule.
   Each run starts fresh with its own prefix and the same resource limits.
   Advance only after a successful exit and at least 15,000 effective
   samples with convergence confirmed; stop the queue on failure or a
   nonconverged exit. These local full runs are explicitly authorized.

The repaired cluster forecasts use two coherent derivative bases. The
344-evaluation calculation took 155 seconds with two MPI ranks and four
OpenMP threads per rank. All eleven forecasts are finite. Refining six
influential columns changes their FoMs and widths by at most 0.0065%.
The remaining counts fourth difference follows smooth fourth-order
curvature: halving only the mass–richness normalization step changes the
FoM by at most 0.058%. The 2.5% stencil is retained. The ordinary vector
is restored bit for bit after derivative mode. Results and four reusable
caches are under `projects/des_y6/chains/cluster_robustness/evaluate2_full_range/`.
DES Cluster is rebuilt against the same fix. Its default 6x2pt+N
prediction, mask and likelihood match the preceding binary bit for bit;
toggling the cluster derivative range and restoring it also passes.

The full case-1 Nautilus timing run started at 21:18 EST on 26 November.
All ten ranks verified native OpenMP=1 and BLAS=1; all nine likelihood
workers returned finite scores. The checkpoint, log and accumulated
timing record are under
`projects/des_y6/chains/nautilus_3x2pt_lcdm_cmb_20261127.2f9FHO/`.
The controller and all MPI ranks are stopped with the checkpoint intact.
The pause follows 19,116 completed calls and about 88 minutes of active
wall time. First measure native CosmoLike alone at one and eight OpenMP
threads, averaging ten changing cosmology and nuisance points after warmup;
exclude theory preparation from this timing. This check is complete:
native setters, projection and chi-squared average 0.22 seconds at one
thread and 0.058 seconds at eight threads, with BLAS=1. The ten vectors
are bitwise identical across thread counts. The full DES likelihood,
including its Python preparation, averages 0.22 and 0.066 seconds.
Evidence is in `/private/tmp/desy6_nautilus_neff15000_20261127.rqq1U9/`,
files `case1_native_omp1` and `case1_native_omp8` (JSON, NPZ and logs).
The original run was retired without changing its checkpoint. Its
convergence time was not measured. Shared defaults and checkpoint resume
support are committed as core `f922f3c`; the safety cap counts calls from
earlier resumed segments too.

The exact run requests derived sigma8 from CAMB, causing a full transfer
calculation despite emulated matter and CMB spectra. Ten matched uncached
points average 1.9 seconds per evaluation, of which CAMB takes 1.7 seconds.
EMUL2 must never calculate with CAMB, including background distances or
acoustic-scale conversion. DES Y6 `9f49b55` switches all 92 sampler YAMLs
to the existing distance emulators and explicit matter-emulator sigma8;
their 276 Nautilus, minimization and profile launchers read the same inputs.
All 92 configurations return finite startup scores with no CAMB calls.
The other active matter-emulator project recipes already have no outer
CAMB block. Core `bbdcce2` enforces the emulator-only sampler route and
updates the comparison candidate, retaining CAMB only as the reference.
All ten shared sampler regression tests pass. Nine project comparison
wrappers produce finite reference and candidate predictions at a saved
point; these startup checks do not certify prediction accuracy across
the prior. The CAMB reweights for cases 1, 11 and 31 also pass.
The complete LambdaCDM emulator replacement passes ten matched points:
maximum prediction delta chi-squared is 0.00030 and mean total time is
0.26 seconds at one OpenMP thread. The ten-point CPL comparison has maximum
combined DES and Plik prediction delta chi-squared 0.11, below 0.2, and
mean total time 0.26 seconds. Both candidate routes are entirely emulated.

The fresh case-1 run started at 23:13 EST on 26 November, using ten MPI
ranks, one OpenMP thread per rank and BLAS=1, targeting 15,000 effective
samples with the 5,000,000-evaluation cap. No previous samples or checkpoint
were reused. Its prefix is
`projects/des_y6/chains/nautilus_3x2pt_lcdm_cmb_emul2_20261127.U5yHbK/case1`.
The old checkpoint remains archived with its original checksum.

The sequential supervisor is active under
`projects/des_y6/chains/nautilus_sequence_20261127.s9APVv/`.
It observes the existing case-1 run, then starts fresh cases 11, 21 and 31
one at a time. `status.json` records each completed run's elapsed time,
effective samples, likelihood calls and evidence. `CONTROL.md` describes
holding or stopping the queue before the next case; the active run is not
interrupted by those controls. There is no automatic retry or resume.

Refresh the saved emulator comparison figures through the corrected
candidate route, using the same fixed cosmologies and Fisher references.
Existing figures used CAMB backgrounds and are labeled accordingly.
The DES 3PCF check remains an explicitly separate matter-spectrum comparison;
it is not validation of a full EMUL2 sampler.

Current status (2026-11-25): the project organization, numbered examples,
sampler/minimizer/profile launchers, CAMB postprocessing configurations and
Slurm array example are implemented. The comparison, redshift-mode,
cluster-robustness and PPD teaching notebooks have been executed. Archived
Lighthouse inputs are portable; they are not a new external-code run.

The archived 21 CPL matter-emulator comparisons are complete: 50 broad and
25 focused points per scope, strict w0+wa < -0.4, matching saved Fisher
contours, and a 21-page combined PDF. All 1,575 paired evaluations are
finite. Finite does not mean accurate: DES Cluster's largest focused
distance is 122.72. DES 3PCF's focused maximum is 0.01074. The completed
results and threshold counts are in each project's data-vector test guide.

Execution update (2026-11-26): DES Y6 `eff1cfe` aligns all ten Evaluate
cosmologies with TATT 3x2pt and ordinary CAMB controls with
AccuracyBoost=1.05, k_per_logint=10 and kmax=10. Native, CAMB, nonlinear
and three CPL emulator comparisons were rerun at this baseline. The
current cluster cheap-FoM screen first gave successive shifts of -3.7%
and -7.4%. Refining only its radial grid then changed the estimate by
+16% from 2,045 to 8,177 nodes and -0.016% from 8,177 to 16,353 nodes.
The last comparison meets the 1% selected-column convergence target at
the current fiducial. Both refinements reused the ordinary 35-parameter
Fisher matrix and evaluated only five selected derivative stencils.
The maintained radial driver is committed as `826532b`; its guide and
the numerical random-model references are in DES Y6 `5f818e1`.

The runtime photo-z and non-Limber additions pass together (seven checks).
They cover n(z) modes and calibrated shift/stretch, require exact return
to the default, and report direct prediction distances. BACCO also passes
its cosmology-response check and has a measured feedback plot. The joint
accuracy check passes at all nine points with native boost 3, integration
level 10, lmax=200000 and the raised CAMB controls (effective kmax=120).
Maximum prediction distances are 0.0067 (TATT), 0.010 (NLA) and 0.0068
(4x2pt+N). Both cosmic-shear sector ladders pass with bitwise return.
CFASTPT comparisons pass for shear, 3x2pt and 2x2pt in DES Y6 and the
DES Cluster optical configurations. The DES Y6 cache/tolerance suite
passes all 12 checks; its setting sequences pass all 11. Targeted LSST
checks preserve the existing shared API. DES Y6 additions are committed
as `9db5112` and `544cfc1`, with shared core implementation `05a9ee0`.
DES Cluster's optical comparison is committed as `b6648be`. The shared
reference-worker BLAS initialization is committed as `0018ccd`.
DES 3PCF's joint-shear photo-z check passes with unchanged Map3 entries
and exact restoration (`87eec7d`).

All seven 50-model comparisons finished with finite prediction distances
between ordinary and refined CAMB/CosmoLike settings.

| Analysis | Δχ² < 0.2 | Maximum Δχ² | Result commit |
|---|---:|---:|---|
| DES Y6 | 43/50 | 1.2 | `5f818e1` |
| DES Y3 | 23/50 | 6.7×10² | `ed8528e` |
| Roman Fourier | 31/50 | 1.4×10³ | `25fed1f` |
| DES Y3 × Planck | 18/50 | 4.0×10² | `a439076` |
| Roman kinematic lensing | 16/50 | 19 | `c66b6fd` |
| Roman real space | 30/50 | 3.4×10⁵ | `8f947cd` |
| DES Cluster optical 3×2pt | 0/50 | 1.1×10⁴ | `62e33b2` |

Deep numerical diagnosis and accuracy tuning are restricted to DES Y6.
DES Y6's seven above-target points fall below 0.2 when the diagnostic
jointly uses `lmax: 200000`, CAMB `kmax: 50` and a shear integration
multiplier of 4.
Interpret large prior-tail distances with the fixed covariance and signal
amplitudes in mind: a fixed fractional vector error grows with the signal,
and its quadratic distance grows with the squared amplitude. A large
distance alone does not establish a code defect or require raising all
production settings. The DES Y6 candidate replay is descriptive evidence,
not an automatic requirement to force every prior draw below 0.2.
The full 50-point candidate replay remains on hold. The numerical-accuracy
plots use saved approximate 68% and 95% Fisher contours where the probe
set matches. The four-panel layout is in shared core `4912a7d`, DES Y6
`c662c1f`, DES Y3 `d2e5e75`, Roman Fourier `54bfd4c`, DES Y3 × Planck
`454cb5a` and Roman real space `8f947cd`. Roman KL's saved contours cover
cosmic shear. DES Cluster's saved contours cover 4×2pt+N.

Maintained pytest setup now loads BLAS with a one-thread cap in the six
current-prior projects (`efc7f67` in the shared core, with project hooks).
All six plain-command collection checks verified the requested native
team and a real one-thread BLAS matrix product without scratch preloads.
The ten guides now use compact FoM settings/change tables; the nine
sibling-guide revisions are committed. The cross-project audit is also
adding missing applicable test bindings, with current prior inputs kept
separate from historical synthetic snapshots.

The bounded startup runs for all 92 numbered cases gave these outcomes.

| Workflow | Outcome |
|---|---|
| MCMC | 92/92 passed |
| Matched CAMB postprocessing | 92/92 passed |
| Nautilus startup | All 92 passed; case 80 needed the larger evaluation budget |
| Minimization startup | All 92 have finite MPI worker evidence |
| Profile setup | 92/92 passed |

The original minimizer runs reached finite MPI worker evaluations in 82
cases and hit the cap in 10. The original log for case 30 records four
finite MPI pool stages. Fresh retries reached finite worker evaluations
in cases 1, 2, 12, 31, 69, 71, 79, 80 and 83. All nine verified two MPI
ranks, four native OpenMP threads per rank and one BLAS thread. MPI
cleanup was verified after every retry.

The last two retries took about 19 minutes for case 80 and 10 minutes for
case 83. Case 79 was the longest at about 21 minutes. These times include
teardown. The local verification ledger is
`/private/tmp/desy6_extended_minimize_startups_20261126.zlPNuZ/verified_results.jsonl`.

Shared core `bb39c3a` preserves the Nautilus checkpoint and reports an
empty posterior when the effective sample size is nonfinite or
nonpositive. Review verified three passing regression tests. The
larger-budget Nautilus retry for case 80 completed 1,000 draws with six
finite likelihood evaluations and two finite weighted rows. Its effective
sample size was 1 and it did not converge. The first 100 draws reproduced
the original empty result exactly; priors and physical settings were
unchanged. The local validation report is
`/private/tmp/desy6_nautilus80_1000draws_20261126.4TJbTE/validation.json`.
Representative ΛCDM and CPL+Planck fixed-parameter profile checks
reached finite MPI worker evaluations. Those checks exercise optimizer
startup. Numbered case 30 also completed the genuine minimum-to-profile
CLI handoff: five minimization temperatures followed by two fixed-parameter
points with four temperatures each, using one step per walker. Both
profile rows are finite, preserve the fixed coordinate and pass the
driver's matching-configuration and saved-score checks. These bounded
searches do not establish convergence or confidence limits. Outputs are
under `/private/tmp/desy6_profile30_cli_smoke_20261126.CvYpJE/chains/`.

The PPD notebook's conditioning-mask preparation,
weighted chain intake and missing-nuisance prior draws were reviewed and
committed as DES Y6 `ba49a61`. Two actual native predictions validate the
reader-to-prediction path; they do not supply calibrated DES
posterior-predictive probabilities or replace conditioning chains.
The cluster-robustness notebook was rerun at the current Evaluate2
settings: its two derivative bases required 153 and 133 evaluations,
yielding 11 finite positive Fisher forecasts. A replay of all notebook
cells reproduces the saved table from those caches. Source is committed
as DES Y6 `8748df5`; outputs are under `chains/cluster_robustness/evaluate2/`.
The derivative-noise proxy is about 6.7% for the baseline and reaches 31%
for clustering plus counts, so these are approximate forecasts. The two
systematics cases still require their missing measured data vectors.

The CPL linear cold-power extension is implemented in emulator `af209ae`,
using a matched-LambdaCDM anchor at physical k=0.05/Mpc. Five regression
tests passed. The seven-point spectrum pilot bounds the isolated ratio
error below 0.12% at z<=4; it is not a full-prior guarantee. At the two
largest DES Cluster discrepancies, changing only the cold input gave
E=0.00265 and 0.00001298, far below the full emulator errors. A separate
CPL spectrum outlier was traced to the learned correction, not the
metadata-version warning. No extra parameter cuts conceal these errors.

The proposal notebook `Cocoa/projects/des_y6/mcmc/FISHER_PROPOSALS.ipynb`
has regenerated all 40 matrices from the current YAMLs. Independent review
confirmed parameter headers, finite symmetric entries and positive
definiteness; the smallest correlation-matrix eigenvalue is 2.18e-5.
Survey LambdaCDM proposals reproduce the previous files exactly, and joint
LambdaCDM changes are below 1.8e-8 in old-diagonal-scaled units. CPL
proposals change with the narrower prior and updated acoustic-scale solve.
The standalone generator is retired; reproducibility lives in the notebook.

The legacy `desy3_4x2ptN/`, `desy6_cardinal/`,
`lighthouse_6x2ptN_comparison/`, `yamls/` and root `plots/` directories
are removed. The existing redshift notebook reproduces the useful DES Y3
redshift panels; active data, configurations and frozen references remain.
Cleanup commits are DES Y6 `b9972c3` and `bdb442d`.

A subsequent numerical review found a Z_MID n(z) row-selection bug:
rounding a reconstructed sample coordinate back through `floor` could read
row k-1 instead of k. Core `d925d26` reads the known stored row directly
for midpoint inputs; 18 native reader tests pass. Both Z_LOW curves and
the DES 3PCF benchmark grid retain byte-identical values. All four DESI
emulator comparisons have been recomputed after this physical correction,
with their existing cosmologies and saved E5 contours. Every prediction
changes, but none crosses a plotted error threshold, so the reviewed
figures and combined PDF remain byte-identical. The DESI data-vector guide
records the corrected archives in commit `030da4c`.
All four corrected DESI screens pass: their final-tier approximate FoM
shifts are +0.00002129% (Delta z=0.20), -0.00004291% (Delta z=0.05),
-0.00019123% (62 Mpc bins) and -0.00007391% (Delta z=0.02), with unchanged
accuracy controls. Before the reader fix these shifts ranged from -2.08%
to -29.83%. The ordinary baselines were rebuilt after the physical fix;
the higher settings evaluated only their newly ranked selected columns.
At Delta z=0.20 the new ordinary fiducial differs from the old vector
by E=0.000184067; no regression data were refrozen.

The final DES Y6 4x2pt+N radial refinement also passes: the four-column
estimated FoM changes by +0.026905% from g16 to g32, versus +1.123387%
from g8 to g16. The ordinary Fisher, stencil steps and selected coordinates
are unchanged. A mixed stencil identified radial resolution as the main
source of its q-column shift. All scopes now have a final successive
approximate-noise comparison below 1%; this does not replace a full
higher-accuracy Fisher calculation. The updated guides are committed in
DESI `dbd8de6` and DES Y6 `0ea8a43`.

DES Y6 testing and remaining work:

Scope decision (2026-11-26): full feedback-specific Fisher proposals for
the forty feedback companions, broader CMB-emulator validation and
converged profile confidence limits are not requested. Keep the existing
proposals and eight-point CMB validation; profile work covers bounded
execution checks. These extensions are removed from the TODO list.

- The five LSST Y1 baryonic-feedback templates are fully commented in
  all ten DES Y6 Evaluate examples (`f04ff2f`). They include the theory
  selector, parameter priors and overrides, with a warning to replace CAMB's
  `mead2020_feedback` by `mead2020` and remove `HMCode_logT_AGN` before
  enabling external feedback. Independent parsing and active-line checks
  confirm that the ten existing evaluation configurations are unchanged.
- SP(k), BCemu, Flamingo, BACCO and BCemu2025 inference companions are
  implemented as cases 53--92 (`fac2e58`, notebook follow-up `7dc11bb`).
  Each covers TATT cosmic shear and 3x2pt, LambdaCDM and CPL, with and
  without CMB. MCMC/minimizer/Nautilus/profile and matched plain-CAMB
  postprocessing use the existing routes. The README maps every case.
  The proposal notebook checks all 52 full and 40 partial base proposals
  and can compute full feedback-specific matrices. A scratch case-58
  build produced a full 23-parameter SPD proposal; two MPI MCMC ranks
  used it and saved scored samples, whose replay agreed within 5.7e-5
  in minus log posterior. All forty configurations evaluate at their
  fiducials with finite positive non-unity suppression. Each feedback family passes
  a genuine CPL point with w=-0.9, wa=0.1. DES Y6 `6648718` requests the
  hybrid suppression and refuses missing or invalid grids. Feedback theory
  `4ceb199` declares all BACCO cosmology dependencies and matches BCEmu's
  actual eta/deta upper bound 0.40 and baryon-fraction bounds [0.10,0.25].
  The maintained BACCO regression passes for changes in amplitude, tilt,
  w and wa with cached results exactly matching fresh calculations.
  Core `201db8a` allows fifty startup posterior draws: four joint examples
  required a sixth draw, beyond the previous five-draw budget.
- SP(k) case 60 reproduced a draw that used unity after an invalid
  suppression calculation inside the calibrated redshift range.
  BFMT `365006f` rejects that draw. The DES Y6 regression `5cdecfe`
  passed, and the valid control's full suppression grid and shear data
  vector matched bit for bit before and after the fix. All 32 startup
  rechecks passed for cases 53–60: MCMC, matched CAMB postprocessing,
  Nautilus and finite MPI minimizer-worker evaluations. Across 800
  identical Nautilus draws, 113 formerly accepted invalid scores became
  rejections; valid scores agreed within 2.4e-10 in log likelihood.
  These bounded checks do not establish sampler or minimizer convergence.
  The verification report is
  `/private/tmp/desy6_spk_startup_recheck_20261126.PSPtcQ/validation.json`.
- The twelve calibrated shift-and-stretch cases 41--52 and full named
  Fisher proposals are committed in `00c0416`. All twelve matrices passed
  finite, symmetry and Cholesky checks. MCMC, CAMB postprocessing and
  Nautilus startup pass for all twelve; each minimizer reaches finite
  worker evaluations. Numbered profiles await matching minima.
  Their priors and redshift notebook are committed in `5f5c198`. CosmoSIS and
  Cardinal inventories are now documented in the data README. Data
  utilities moved to `scripts/` in `9d96174`, and the incomplete cluster
  descriptor and obsolete DES Y3 proposal were cleaned up in `096e17f`.
- Per-probe radial-resolution multipliers are implemented in core
  `4549367`, with preservation during shared tolerance checks in `75238a2`.
  The keys use the prefix `integration_accuracy_` and suffixes `ss`, `gs`,
  `gg`, `gk`, `ks`, `kk`, `cg`, `cc`, `cs`, `n`. They multiply the quadrature
  resolution at the existing global level; counts have a 1024-node base
  minimum before multiplication. Default factors are 1. Strict rebuilds,
  installation and finite native checks passed across all ten projects.
  Default optical parity, unrelated-probe isolation,
  non-Limber linear/full matching and factor/reset restoration are checked.
- The user adopted DES Y6 global integration level 0 with SS=1, GS=4,
  GG=2, CG=CC=CS=4 and N=1 where those probes are active. Ten changing
  points give maximum direct-vector errors 0.003724 (TATT optical),
  0.003474 (NLA optical) and 0.000518 (clusters), relative to global level
  7 with unity factors. The observed-data chi-squared shift is a separate
  advisory and can be larger because it includes a residual linear term.
  Production Evaluate/MCMC/post settings have been updated; the sampler,
  minimizer and profile drivers inherit their corresponding MCMC files.
  Maintained tests passed (12 checks), recorded in DES Y6 `1425736`.
- The maintained DES Y6 CAMB trials now cover sampling density,
  AccuracyBoost, power coverage, joint refinement and cluster neutrino
  momenta at three chosen points per family. All 78 comparisons meet the
  user's numerical target: full-vector E < 0.2. The earlier 0.01 E and
  0.05 observed-fit criteria were introduced incorrectly; current tests
  and guides are corrected in `f4d3803` and `97cd21c`. Smaller diagnostic
  errors must not become a stricter requirement. Observed fit shifts are
  separate from prediction error. Main skill `c9e13462` requires checking
  the requested metric, threshold and scope before running or choosing
  defaults. The optional DESI radial convergence criterion is also 0.2
  (`e784b38`); that optional study was not rerun for the policy change.
- DES Cluster's combined native+CAMB test passes at the unchanged global
  integration level 1 and unity factors: maximum E=0.0006892 for 4x2pt+N
  and 0.04703 for 6x2pt+N at H0=61,69,77. GG uses 256 nodes. A 128-node
  diagnostic gives maxima 0.04898 and 0.34240 respectively. The user
  explicitly prefers the simpler existing GG256 defaults for both, so
  remove the briefly proposed GG0.5 and GS2 live overrides; no YAML diff
  remains. The four simplified maintained tests and both cheap Fisher
  screens passed, recorded in DES Cluster `e3cbcaa`. Successive refined
  FoM changes were 0.008855% and 0.008388%; these are selected-column
  estimates, not full refined Fishers. The measured optical
  DES Y3 configuration also passes at its own fiducial (full E=0.004606).
- The DES Y6 cheap FoM screens at the new ordinary controls are complete.
  Shear and 3x2pt pass the separate 1% successive-tier screen, with final
  shifts +0.021209% and -0.058381%. The initial 4x2pt+N estimate changes
  -6.78090%. Its selected-column radial follow-up passes at the final
  refinement: g16 to g32 changes the estimate by +0.0243077%, after
  g4 to g16 changes it by -2.83917% (`0ea8b55`). The saved baseline and
  selected columns were reused. Accepted chi-squared defaults remain
  unchanged by this separate Fisher diagnostic. These runs
  used one full baseline, one 2.5% stencil spacing and selected-column
  refinement, with two MPI ranks, four OpenMP threads each and BLAS=1.
  Emulator benchmark points and saved contours remain intact.
- The completed CPL and LambdaCDM emulator comparisons are readable from
  `notes/code_comparison/EMULATOR_CAMB.ipynb` (`2d96d2e`). All 150 saved
  distances reproduced without new predictions or Fisher calculations.
- Case 30 completed the numbered profile CLI smoke test using its genuine
  matching minimization record and a one-step profile schedule.

Longer scientific follow-ups, not completed by the teaching demonstrations:

- Calibrate DES PPD tests using conditioning-only chains and repeated
  simulated null/alternative analyses. The Tensiometer and nuisance toy
  checks are executed; they do not supply a calibrated DES p-value.
- Extend the released-chain importance pilot only with compatible support
  and adequate effective sample size. The current fixed-mass pilot has
  ESS=12.50; it is not a replacement for a production posterior fit.
- Revisit cluster-robustness cases with large numerical diagnostics before
  treating their Fisher forecasts as quantitative posterior constraints.
- Obtain the missing systematics-weight and scale-dependent metacalibration
  vectors, and the full 6x2pt+N measured vector, covariance and mask.
  Those configurations cannot be validated from the supplied inputs alone.

Use the eight-core DES Y6 lane with two MPI ranks, four OpenMP threads per
rank and one BLAS thread. Keep BLAS at one thread in every lane. Deep
numerical analysis is restricted to DES Y6. Covariance work and map
generation remain paused. TreeCorr runs stay on the HPC. Do not launch
production chains as part of these test tasks.

<a id="closed-des-y6-modernization"></a>
## Modernize the DES Y6 project

**Ticket type: NEW FUNCTIONALITY. Severity: MEDIUM. CLOSED (2026-10-07).**

Bring the project interface, optional covariance CLI and notebook, data-vector
notebooks, tests and documentation into line with DES Y3 and LSST Y1. Preserve
DES Y6 input files, six lens bins, four source bins and the active 26-angle
layout. The active likelihood uses dummy data; its separate 1690-entry
covariance does not match that 1300-entry layout and must not be activated
without a verified ordering and compatible data vector.

Completed the current-core interface and likelihood port, optional covariance
CLI, three notebooks, stored-input NLA/TATT regressions, cache and probe-selection
checks, input-index validation, documentation and installation covariance flag.
All 27 tests passed. Enabled, disabled and debug builds were checked; all four
NLA/TATT vectors agree bitwise across modes. The full 1300-entry G/SSC/cNG/total
arrays agree bitwise between CLI and notebook routes. Total covariance is positive
before and after the 541-entry selection. Doubling the non-Limber cutoff and
distance-grid intervals changes the largest generalized Gaussian variance mode
by 0.00553% in real space and 0.00527% in Fourier space. This is not a full
quadrature, interpolation or Fisher convergence certificate.

The three executed notebooks contain 12 embedded figures, including separated
halo trispectra. Original survey inputs and nuisance priors remain unchanged.
The production module stays enabled locally; disabled/debug checks used isolated
build directories. Validation records are in the project's tests/validation/
folder and the external des_y6_validation/20261007/ run directory. The
1690-versus-1300 observational-data mismatch remains an explicit data limitation.

<a id="open-covariance-nonlimber"></a>
## Covariance-owned all-pairs non-Limber spectra

### High-level summary

Extend Gaussian covariance inputs with all-pairs non-Limber density and
shear spectra, including the cross-bin spectra absent from a measured
data vector. DES Y6 Appendix F explicitly includes non-Limber covariance
to capture cross-tomographic correlations.

### Current status

**Ticket type: NEW FUNCTIONALITY. Severity: HIGH. OPEN, remaining extensions.**
Gaussian gg/gs was subsequently authorized and implemented on 2026-10-05
UTC in small local commits. All-pairs shear–shear and selected-cluster
non-Limber remain open. Covariance generation stays outside MCMC;
SSC/cNG changes were explicitly excluded from this implementation block.

### What is already in place

Data-vector `cosmo2D.c` has FFTLog galaxy autos and galaxy–shear spectra.
Covariance-owned `fftlog_cov.c` and `nonlimber_cov.c` now supply every
gg/gs pair with a common growth/power anchor and matched linear subtraction.
Serial shared FFTW plans, worker arrays, SIMD contractions and both C++
entry paths are implemented. Independent Bessel checks and full real/Fourier
Gaussian refinements pass for all seven galaxy/shear adapters: largest
variance-mode change below 0.019%, all base/refined matrices positive.
Project defaults use the tested cutoff/grid; this does not certify Fisher
or every other integration/interpolation setting.

### What is missing

1. Extend shear–shear consistently beyond Limber and test lower-noise surveys.
2. Add selected-cluster transfers and preserve joint transformations.
3. Measure 1/2/4/8-thread scaling across the intended survey sizes.
4. Validate multiple cosmologies, IA choices and full covariance/Fisher accuracy.

The partial gg/gs hybrid has negative low-ell noiseless field modes for
some Roman inputs. Their actual catalog noise restores positive observed
fields, and the full Gaussian matrices pass. Never generalize those checks
to arbitrary source densities or repair negative modes.

New C stays inside `cosmolike/covariances/`, with `_cov.c` filenames.
Shared transforms, serial FFTW planning, bounded worker buffers, SIMDe
and field/multipole parallelism are part of the design. Study and test the
actual `cosmo2D.c` optimizations; do not infer speed or accuracy from them.
Global accuracy boost multiplies tuned internal refinements; the GSL
quadratures remain controlled separately by integration accuracy.

Non-Limber spectra change Gaussian contractions. They do not remove
long-mode Limber from SSC or equal-time projection approximations from
cNG. Keep those approximation labels separate, preserve signed cross
spectra, and never repair a failed total covariance by clipping eigenvalues.

### Technical record

The tracked core plan has deliverables N1–N6, proposed files and API
boundaries, equations, independent tests, performance experiments and
release criteria:
[covariance_nonlimber_ia_plan.md](../../Cocoa/external_modules/code/cosmolike_core/.claude/skills/cosmolike-dev/references/covariance_nonlimber_ia_plan.md).
Primary sources include
[Fang et al.](https://arxiv.org/html/1911.11947),
[N5K](https://arxiv.org/html/2212.04291) and
[DES Y6 Appendix F](https://arxiv.org/html/2503.13631v1#A6).
Each major implementation must pass tests and a separate didactic review
before starting the next; commit locally and never push.

<a id="open-covariance-nla"></a>
## NLA in complete covariance forecasts

### High-level summary

Allow an explicitly configured nonlinear-alignment model (NLA) in a
complete forecast, with consistent source fields in Gaussian, SSC and
cNG terms. Gaussian-only NLA/TATT is implemented; connected terms retain
zero IA until their response and four-point models are justified.

### Current status

**Ticket type: NEW FUNCTIONALITY. Severity: HIGH. OPEN, connected IA deferred.**
The authorized Gaussian-only implementation is complete: explicit per-bin
NLA/TATT parameters, E/B spectra, B-mode real-space covariance and CLI/
notebook choices. SSC/cNG keep lensing-only windows and their original
mean-subtraction signal; a full-assembly test verifies bitwise preservation.

### What is already in place

`spectra_cov.c` constructs signed NLA windows and all-pairs Limber spectra.
Low-level checks exercise their signs and contractions. The data-vector
non-Limber source transfer also includes linear/NLA alignment. These
components do not establish a validated full NLA covariance forecast.

### What is missing

1. Derive and test the declared NLA approximation for every SSC/cNG source leg.
2. Propagate source IA consistently into cluster and count–source SSC crosses.
3. Validate full modes/Fisher effects across the intended IA range.
4. Extend the explicit per-bin API if survey-specific redshift evolution is needed.

The initial connected proposal holds deterministic IA amplitudes fixed
under the background perturbation and uses signed windows with the matter
response/trispectrum. This needs physical justification and independent
tests; NLA two-point spectra alone do not specify a complete intrinsic-shape
four-point model. If that gate fails, expose limited Gaussian-NLA components
and clearly label the Gaussian-only scope. Stochastic IA and additional
IA responses remain separate extensions; Gaussian TATT is implemented.

### Technical record

Deliverables I1–I4, sources and acceptance checks are in the tracked core
[non-Limber and IA plan](../../Cocoa/external_modules/code/cosmolike_core/.claude/skills/cosmolike-dev/references/covariance_nonlimber_ia_plan.md).
The plan requires zero-amplitude recovery, odd/even amplitude sign checks,
independent source-field expansions, CLI/notebook and thread agreement,
positive total covariances and unchanged data-vector regressions.

<a id="open-covariance-rewrite"></a>
## Rewrite analytic covariances in an isolated module

### High-level summary

Compute Gaussian, super-sample and connected non-Gaussian covariances in
one process, with covariance-owned numerical choices and caches. Physics
comes from the papers, especially Krause and Takada; the CosmoCov code is
a convention comparison, not the final numerical reference.

### Current status

**Ticket type: NEW FUNCTIONALITY.**

**OPEN.** Full galaxy/shear Gaussian, super-sample (SSC) and connected
non-Gaussian (cNG) forecasts are available in real and Fourier space through
C++ component interfaces and shared Python assembly. All seven projects
have executed notebooks and thin survey adapters. These use the supported
massless-neutrino, Limber, linear-bias model; their teaching resolutions
are not validated inference settings. DESxPlanck currently covers its
galaxy/shear sector. DES cluster also has a 2812-entry angular joint
forecast, with explicitly limited cluster cNG and count-cross physics.

A supplied-abundance cluster component returns count means, Poisson noise,
count SSC and count–two-point SSC. A second component projects all supplied
cluster–galaxy, cluster–shear and cross-cluster Limber spectra. Selected
halo moments, fixed-selection responses and all joint Y-transformed blocks
are available. The joint forecast uses linearly biased matter cNG and
SSC-only count crosses. Completing the discrete-halo model, non-Limber
corrections and survey accuracy validation remains open.

**Severity: MEDIUM.** New science functionality; existing project
covariances remain in use.

### What is already in place

- New covariance C remains isolated in `cosmolike/covariances/`, with
  `_cov.c` filenames and `_cluster_cov.c` for cluster extensions.
  Existing data-vector C is unchanged by the covariance port.
- Shared C++ wrappers expose full Gaussian matrices and low-level numerical
  components. Shared Python performs all-pairs Limber spectra, bin-averaged
  transforms, SSC and five cNG halo terms without copying algorithms into
  project adapters.
- LSST Y1, Roman real, Roman Fourier, Roman KL, DES Y3, DESxPlanck and DES
  cluster have executed real/Fourier notebooks, saved-input workflows and
  covariance instructions in their main READMEs. Their ordinary test
  command selects data-vector tests; covariance tests are a separate suite.
- Every notebook compares one covariance `accuracy_boost` at two values,
  separates G/SSC/cNG and checks total positivity. All 28 example totals
  (seven projects, two spaces, two boosts) are positive definite. Several
  refinement changes are substantial; no boost is certified for inference.
- Shared SSC responses retain all cross-bin blocks before their weighted
  outer products. The complete supported LSST and Roman timing runs also
  pass full and selected positivity checks, with no eigenvalue repair.
- Supplied cluster abundances and density responses give count-shell
  quantities, count means, Poisson noise and SSC through a DES cluster
  binding. Six analytic/project checks and 16 isolated debug checks pass,
  including units, signed cross responses and 1/2/4/8-thread repeatability.
  The model of the selected abundance is still a separate physical input.
- The supplied-table cluster spectrum component agrees with independent
  DES all-pairs projection to 2e-15 relative and repeats bitwise at
  1/2/4/8 threads. Selected mass moments and physical halo samples have
  independent analytic/scalar checks and isolated sanitizer checks.
  Count–matter non-SSC terms are separately tested by Poisson enumeration.
- Shared cluster preparation keeps the actual count insertion and every
  internal field pair; streamed multipole/profile batches bound scratch
  memory without changing quadrature. The full angular forecast and its
  archive preserve model omissions, count positions and defined Y null rows.
  All 46 DES covariance checks pass, including thread repeatability,
  catalog normalization and transformations of every joint cross block.
- The 2812-entry joint baseline agrees with independent component pilots
  within 2.1e-15 in total-variance units. The Y total is positive after
  excluding its 48 defined null rows. Notebook boosts 1 and 2 are both
  positive; after nested-grid refinement their largest generalized variance
  change is 18.45%, so
  neither is presented as a converged inference setting. Selected-cluster
  cNG corrections and non-SSC count crosses remain omitted in this baseline.
- SIMDe arithmetic is unconditional. OpenMP distributes independent output
  work, BLAS remains single-threaded and no C code calls MPI. Benchmarks
  run one at a time on a quiet machine; tests are not timing evidence.
- Each completed major component receives a separate didactic review:
  equations and units, loop rationale, every SIMD operation, paragraph
  breaks, separate comparisons and 80-column C/header lines.
- Earlier component/reference runs and their optimized/debug checks remain
  recorded in the core references. All seven projects pass 392 data-vector
  checks, including Roman real's 24 opt-in halo checks, and 114 covariance
  checks. Stored likelihood references were not changed by the notebook
  rollout, test reorganization or shared matter extraction. The subsequent
  nested-grid and bounded-spectrum changes pass 116 covariance checks.
  All seven refreshed notebooks execute successfully; all 28 galaxy/shear
  totals and both DES joint totals remain positive on their defined spaces.
- Before the later spectrum-batching change, the full DES joint baseline
  took 13.80/8.98/6.55/6.35 s at 1/2/4/8
  threads on the Apple M2 Pro. These are three-call means after one warm-up
  per worker count, at a fixed cosmology and boost 1, excluding CAMB and
  initialization. No competing numerical job ran; ordinary desktop
  activity remained. Every component is bitwise identical across workers.
  Scaling beyond four threads is weak and still needs optimization.
- Covariance interpolation refinement retains every old window and
  non-Gaussian multipole node. Raising a cutoff extends the grid without
  stretching its cells. Settings archive the actual multipole samples;
  quadrature-node refinement remains a separate numerical check.
- A full boost-1/2/4/8 LSST single-source Gaussian test is positive and its
  successive maximum generalized variance changes fall from 1.02e-4 to
  1.10e-5 to 2.29e-6. Multipole batching preserves every radial sum bitwise
  and bounds the high-boost C scratch from about 27.52 GB to 176.16 MB.
  Quiet component measurements and didactic checks are recorded in the
  core's covariance_limber_batches.md; these are not full-matrix timings.

### What is missing

Establish a refined numerical reference and practical accuracy settings
using Fisher Figure of Merit, parameter errors and relative covariance
modes. Positive definiteness is necessary but does not establish numerical
convergence. The proposed 1e-3 mode scale is a diagnostic starting point,
not a literature requirement; do not impose the data-vector
|delta chi2| < 0.2 rule or the study's old 1e-6 entrywise rule on covariance
accuracy. Check several cosmologies and the intended scale cuts.

The high-resolution halo-response diagnostic still finds a copied-power
derivative floor: a nested 241-to-961-node response table stalls near 0.8%
maximum error at its fixed off-grid queries. Merely inserting linear
power samples preserves that floor. Cubic construction of a nested dense
power copy reduces the same table-refinement error to about 0.03%, but
changes the between-node input function. Validate against CAMB's own
interpolator and covariance/Fisher results before adopting that policy;
production input copying remains unchanged. These component errors are
not full-covariance generalized-mode bounds.

Covariance-owned all-pairs Gaussian gg/gs and NLA/TATT are implemented. The detailed
[non-Limber ticket](#open-covariance-nonlimber) and
[NLA ticket](#open-covariance-nla) now track those extensions separately.
Their remaining connected/cluster/shear extensions are deferred. Validate physical response choices,
mask/estimator conventions and the independent CosmoCov comparison. The
massive-neutrino nonlinear model, CMB fields and more general nuisance
models remain outside the supported notebook configuration.

For DES cluster, extend the joint baseline with selected-cluster one-halo
cNG and non-SSC count–spectrum terms, including discrete cluster partners
and consistent observed-catalog normalization. The validated count–matter
helper alone does not supply those missing terms. Check full and selected
positivity and Fisher refinement for the completed physical model without
clipping modes. The existing supplied likelihood covariance is unchanged.

The initial small-component runtime estimates have been superseded by
complete supported-model runs: 162.93 s for LSST Y1 and 214.39 s for Roman
real on an Apple M2 Pro with eight OpenMP threads, before the later C++
Gaussian assembly optimization. These are single cold runs at explicit
high-resolution settings, not means, accepted accuracy defaults or x86
performance measurements. Re-measure the current implementation on a
quiet machine when making a new full-runtime or scaling claim.
The later DES baseline measurement does not replace these LSST/Roman
measurements: it uses different grids and explicitly limited cluster
physics. Its boost is not a converged inference setting.

Existing likelihood covariances must not be replaced before their survey
model, conventions and accuracy are validated.

### Technical record

<details>
<summary>Constraints and first measured kernel</summary>

Owner request: 2026-10-03. The detailed plan is external
`test/cosmocov_port_study/PLAN.md`; the durable core record is
`.claude/skills/cosmolike-dev/references/covariance_rewrite.md`.
The plan's old singular folder, total-matter halo default, and three-build
validation language are superseded by `covariances/`, cb halo statistics,
and strict default/debug builds. OpenBLAS stays at one thread.

Apple M2 Pro, Clang 19.1.7, strict flags: a 20 x 20 projection over
50,001 supplied multipoles takes median 24.041/6.359/3.296 ms in the scalar
path and 1.848/0.616/0.398 ms with tiled SIMDe at 1/4/8 OpenMP threads
(51 calls, three excluded warm-ups). This is a kernel comparison, not a
full-covariance forecast or evidence for a delta-chi-squared threshold.
The raw timing and validation logs remain in the external reference folder.

</details>

<a id="open-project-endpoint-refreeze"></a>
## Project endpoint refreezes, notebooks and numerical follow-ups

### High-level summary

Expose the non-Limber redshift endpoint as a project YAML parameter, retain
the requested per-project numerical settings, regenerate frozen tests, and
execute the example notebooks with reviewed figures and Fisher-noise tables.
The work queue runs serially with six OpenMP workers and BLAS fixed to one.

### Current status

The endpoint defaults to four and rejects nonfinite values or values below
four. LSST Y1 and Roman real use 4.5, Roman Fourier uses 5.0, and the DES
projects use 4.0. Roman KL and LSST Y1 with DESI retain 4.5. Seven project
refreezes are committed. The remaining LSST Y1 with DESI checks are paused
until tonight at the user's request; its completed comparisons and resume
boundary are preserved. The notebook queue proceeds during that deferral.

| Project | Refreeze commit | Quick-test outcome |
|---|---|---|
| LSST Y1 | `57b50d5` | 115 cases covered, including the successful environment retry |
| DES Y3 | `f429b69` | 108 passed |
| DES with Planck | `ec63a45` | 91 passed |
| DES cluster | `eb6fc9d` | 73 passed |
| Roman Fourier | `42428b3` | 88 passed, one inapplicable Fourier stencil check skipped |
| Roman KL | `14281fd` | 92 applicable cases passed after the comparison repair below; one Fourier skip |
| Roman real | `064cb94` | 127 passed, 24 optional slow-halo checks skipped |

The initial LSST missing-GSL build failure passed on a targeted retry in
the normal Cocoa build environment. Roman KL's original run remains
recorded as 91 passes, one failed comparison and one intentional skip.
Its failed comparison was rerun after correcting the test setup, with
the original numerical allowance unchanged.

### What is already in place

Each project retains fixed-input endpoint comparisons separately from
cumulative differences against older frozen references. A separate private
CAMB comparison recovers every historical shear value in six DES/cluster
cases using the appropriate growth convention and older halofit tolerance.
DES Y3 retains an explicitly Limber galaxy-lensing residual, and clustering
residuals remain. The installed CAMB is unchanged; numerical agreement does
not identify the unrecorded historical binary. Frozen physical parameters,
points and priors are preserved even when live example defaults differ.
An independent audit checks 325 frozen-file hashes and 28 parameter
configurations across the first seven projects. Roman real's seven saved
endpoint comparisons preserve shear entries and restore the original vectors
bit for bit; its halo reference is unchanged. Eleven notebooks have prepared settings,
Fisher tolerance restoration and checked structure; full execution remains
separate from those preparation checks.

Core `2bc4500` matches the galaxy-shear cap between the FKEM and SVD
clustering comparisons. The earlier SVD-at-150 case had left galaxy-shear
at its production cap of 200. Five fresh-process controls isolate that
confound: matching the caps changes only galaxy-shear entries and reduces
the Roman KL w0 diagnostic ratio from 1.10070 to 1.00130. All production
restorations are bitwise. The comparison and restoration tests then pass
for Roman KL, LSST and Roman Fourier; their supplemental records are
`d1730d3`, `f682191` and `eb51b99`. No native calculation or numerical
allowance changed. Fourth differences also contain smooth curvature;
the record does not interpret every residual as independent noise.

Core `48da11f` qualifies the shared Fisher-noise explanations without
changing their executable AST. Small sensitivity weights do not bound
unmeasured columns whose numerical jitter is unknown. The diagonal-addition
estimate predicts a change in its approximate Fisher matrix; it does not
bound the error of one computed forecast or remove smooth derivative bias.

### What is missing

Finish and inspect the eleven notebooks, which are now running serially.
Resume the remaining DESI refreeze tonight from its saved checkpoint;
do not repeat its completed 200-model comparison. After the notebook queue,
investigate derivkit's wa column and style mutation, the Fisher color
order, squared wrapper accuracy boosts, cluster early-exit control, Roman
real's slow halo reference and the DESI E3 one-loop RSD check. Finally rebuild
DES 3PCF, repeat its ten-point CLI timings with CAMB excluded, and rerun its
notebooks. Prior eight-worker timings remain historical; current runs use
at most six workers. No push is authorized.

<details>
<summary>Technical record</summary>

The local [execution plan](../../to_reproduce/zmax_per_project_refreeze_20261118/PLAN.md)
and [report](../../to_reproduce/zmax_per_project_refreeze_20261118/REPORT.md)
retain the ordered A/C/D/E queue, hashes, logs and exceptions. Durable
project commits retain their tests and reference records. The shared
derivative context is core `87195ee`; the test thread override and DESI
vector handling are core `7a3ae44`.
The [DESI resume record](../../to_reproduce/zmax_per_project_refreeze_20261118/projects/lssty1xdesi/RESUME.md)
identifies the 98 remaining quick cases and the completed comparisons.
The [follow-up source review](../../to_reproduce/zmax_per_project_refreeze_20261118/notebooks/D_SOURCE_REVIEW.md)
records the different wrapper boost paths, derivkit's near-zero sampling
scale and plotting side effect, and the interpretation of response plots.
The [timing source audit](../../to_reproduce/zmax_per_project_refreeze_20261118/notebooks/E_TIMING_REVIEW.md)
identifies the older LSST settings, unsupported newer source/physics choices,
input-pinning gaps and worker-count assumptions to correct before E.

</details>

<a id="open-threepcf-integration-followups"></a>
## Remaining 3PCF integration follow-ups

### High-level summary

Consolidate the remaining shared numerical work. Preserve the
physical input conventions, retained-model lifetimes and explicit cache
invalidation. The supplied-baseline route, independent background check,
bridge query reuse and documented NFW scalar reader are implemented.

### Current status

The user's second integration handoff lists additional work beyond those
completed changes. Check each item against the current source before
implementing it: the handoff describes a moving branch, not a new numerical
reference. The ordered project refreeze/notebook queue above remains active.
Its follow-up D includes the cluster early-exit setting, and E includes the
installed DES 3PCF rebuild, timings and notebook runs.

Bridge ownership/cache changes, array-count checks, the adapter style pass,
typed empty-array allocation, removal of redundant allocation checks and
the normalized NFW reader are committed. The strict and UBSan builds each
passed all 829 project tests, including the 40 focused bridge/count cases.
Saved outputs agree byte for byte across the reference and candidate
builds at one and four workers. Four targeted ASan checks reproduce the
old borrowed-input lifetime errors and pass with the replacement order
corrected. The allocator checks pass in strict, UBSan and ASan modes at
one and six workers. BLAS remains one throughout.

The core changes are `dbc9ff7`, `4b5d017`, `f2d3de0`, `fbe4b90`,
`26b3844`, `b86891a` and `df28967`; `7264f96` records the validation.
Permanent project tests are committed as `2cfc4a3`, `4bf9a54` and
`a84b249`. See `cosmolike_core/dev_scripts/bridge_cache_check/` for input
hashes, comparison scopes and retained setup-failure records. Bridge
setters, model refresh and reset still require sequential Python entry.

The NFW tests cover four concentrations, both adapters, dimensionless
phases through 20000 and both interpolation boundaries. Larger physical
domain, covariance-convergence and performance checks remain below. DESI's
remaining refreeze tests and background diagnostic are deferred at the
user's request; the other projects' notebook queue has started.

### What is already in place

The core has power-table variance functions and a shared dimensionless NFW
evaluator. The bridge copies its inputs, compares state contents and returns
immutable models with owned arrays. IA and feedback amplitudes reuse these
models while new query dictionaries carry the changed parameters. The
Python bispectrum producer reuses unchanged cosmological inputs. Further
consolidations require their own derivative-accuracy and runtime checks.

### What is missing

- Replace module-local variance and normalization work with the shared
  power-table functions after accepting the planned uniform-grid changes.
  The handoff requires joint-mean squared covariance-weighted displacement
  at most 0.01, derivative-column error at most 1e-3, and changes below
  0.5% in marginalized errors and pair figures of merit, stable under
  further refinement. Removing the separate sigma8 normalization is a
  scientific change that must pass those checks.
  The source review also separates scale-dependent growth from amplitude
  normalization and an inconsistent Gaussian-tail derivative. The
  [variance reuse record](../../to_reproduce/threepcf_supplied_baseline_20261119/VARIANCE_REUSE_REVIEW.md)
  identifies the immutable-array boundary and existing comparison inputs;
  it contains no numerical acceptance result. The physical model still
  uses its local irregular builder and natural-spline solve; feedback's
  uniform preparation does not complete those separate interpolation stages.
- Finish the NFW domain/cache checks and remaining consolidation described
  by its plan. SIMD work for NFW and feedback preparation requires a quiet
  machine and measured benefit before adoption.
- Respect the handoff's separate ownership of the uncommitted DES 3PCF
  Makefile lines. Build with them, but do not include them incidentally in
  another change's commit.
- Retain the upstream-preparation flags for their requested later pass:
  unused covariance workspace members, mutable array access inside released
  GIL scopes, error-string vocabulary and the named local-variable changes.

<details>
<summary>Technical record</summary>

The copied [integration handoff](../../to_reproduce/threepcf_supplied_baseline_20261119/FOLLOWUPS_HANDOFF.txt)
retains the original item numbers, ownership constraints and sequencing.
The [NFW plan](../../to_reproduce/nfw_sharing_review_20261118/IMPLEMENTATION_PLAN.md)
separates correctness checks from performance experiments. This ticket does
not authorize a default change, push, or the separately gated DESI stage.

</details>

<a id="open-cfastpt-gb2-ia-bias"></a>
## IA x higher-order-bias (gb2) cross terms in cfastpt

### High-level summary

The galaxy-intrinsic (gI) part of gamma_t is computed with linear
galaxy bias times the full NLA/TATT alignment spectrum, while the
density part of the same probe keeps the quadratic-bias terms (b2,
bs). The missing sector is the cross between the two expansions: the
spectra <delta^2|E> and <s^2|E> (times b2/2 and bs/2), which upstream
FAST-PT ships as the IA_gb2 module (tables fe, he, F2, G2, S2F2,
S2G2, S2fe, S2he). Add these tables to cfastpt and wire them into the
gI integrand, closing the one-loop consistency gap.

### Current status

**Ticket type: NEW FUNCTIONALITY.**

**OPEN.** Idea stage; gated on upstream FAST-PT resolving issue #29
(see below).

**Severity: LOW.** The truncation matches the community baseline
(DES-Y3 TATT, cosmosis tatt_interface, CCL): no current result is
wrong. The terms are a loop correction inside a correction (of order
b2*A1 relative to the linear-bias gI term); whether LSST-Y1/Roman
gamma_t precision cares is a quantifiable question to answer as part
of this ticket.

### What is already in place

`get_FPT_bias` (pt_cfastpt.c) provides the exact machinery: hardcoded
(alpha, beta, ell) J-tables accumulated through one `J_abl` call,
with exchange pairs collapsed into single doubled rows - an idiom
that is structurally immune to the transcription slip found upstream
(see the technical record). Its 13 rows were verified analytically on
2026-09-25, and the Pd1s2 rows are literally the S2F2 kernel of the
gb2 family, so part of the derivation work already exists.
`get_FPT_IA` provides the TATT (ta/tt/mix) side the new terms couple
to. Upstream FAST-PT 4.0.0 is installed in `.local` and carries the
IA_gb2 module as a cross-check reference (with caveats below).

### What is missing

- Derive the eight gb2 tables independently and write them in the
  `get_FPT_bias` collapsed-row style. Do NOT transcribe upstream:
  FAST-PT issue #28 (confirmed 2026-09-25 by direct Legendre
  derivation) has a typo in IA_gb2_S2G2 - the last row must be
  (-1,1,l=3,1/5), not l=1 - and issue #29 (a duplicated row in
  IA_gb2_he) is unresolved; the row placement is numerically inert,
  but whether the total is -1/3 or -2/3 needs the source derivation.
- Wire the new spectra into the gI integrand of gamma_t with the
  b2/2 and bs/2 coefficients paired to C1/C1delta/C2 per the gb2
  module's source paper.
- Quantify the effect on gamma_t at LSST-Y1 and Roman precision
  (delta^T C^-1 delta against the truncated model) before deciding
  whether any default changes.
- Validate against python FAST-PT once upstream has fixed #28 and
  resolved #29 (a comparison against the current upstream would
  inherit its typo).

<details><summary>Technical record</summary>

- Owners: `external_modules/code/cosmolike_core/cosmolike/
  pt_cfastpt.c` (new table block beside `get_FPT_bias`), `IA.c` /
  `cosmo2D.c` (gI integrand), plus the source-paper coefficient map.
- Upstream references: FAST-PT issues jablazek/FAST-PT#28 and #29
  (both filed 2026-09-25), fastpt/IA/IA_gb2.py at commit b91f6b7.
- Analytic facts established 2026-09-25: F2 and G2 share the
  identical (q1/q2 + q2/q1)(mu/2) term, so the (+-1,-+1) rows of the
  S2F2 and S2G2 tables must coincide; (mu/2)(mu^2 - 1/3) =
  (2/15) P1 + (1/5) P3 fixes those rows, proving #28. With
  alpha = beta = 0 and the same P(k) on both legs, J(l1,l2) equals
  J(l2,l1), which is why #29's duplicated row is numerically
  equivalent to the symmetric pair and only the TOTAL coefficient is
  in question.
- Exposure audit (2026-09-25): no gb2-family table or caller exists
  anywhere in cocoa (cfastpt, PyFAST-PT, likelihoods, notebooks);
  the cosmolike function `gb2(z, ni)` is the b2(z) galaxy bias, a
  name collision only.

</details>

<a id="open-halo-vectorization"></a>
## Vectorization study for halo.c (SIMDe, SLEEF)

### High-level summary

After the algorithmic steps of the halo.c campaign, the spectrum
tables spend their time in one scalar kernel, the NFW transform nfw_um
(three table reads and two sines per (a, k, mass node)). Under
Cocoa's default strict-IEEE flags (-frounding-math,
-fno-associative-math) clang auto-vectorizes no floating-point loop -
reductions and element-wise loops alike, silently, because the Darwin
build passes -Wno-pass-failed - so vectorization has to be explicit:
SIMDe intrinsics (the cosmo2D.c pattern) for arithmetic loops, and for
the loops dominated by exp, log, pow, sin and cos a vector math library
such as SLEEF, which SIMDe's SVML-style functions can use
(SIMDE_MATH_SLEEF_ENABLE).

### Current status

**Ticket type: NEW FUNCTIONALITY.**

**CLOSED for now (2026-09-29, maintainer decision).** The measurement
study ran on the dev machine (Apple M2 Pro; harness and full report in
the session scratchpad, sleef_study/REPORT.md + bench/): SLEEF u10
makes the nfw_um loop SLOWER there (0.92x; Apple libm's small-argument
fast paths beat SLEEF's full polynomial - 73 percent of the real sine
arguments are below pi/4); the only variant above 1.3x needs the
3.5-ULP inline header, which leaks `#pragma STDC FP_CONTRACT OFF` into
the rest of the file (maintainer: never add things with side effects
like that). Production is x86 (glibc sine slower, AVX2 4 lanes), where
the kernel-level case is plausibly >= 1.5x - but no dev runs are
possible on SeaWulf, and the algorithmic reductions that landed the
same day (mass-node ladder, coarse ln k queued) shrink the halo builds
to where the sine stops mattering in the MCMC budget. Judgment call
(delegated by the maintainer): do not add SLEEF; revisit only if a
post-reduction x86 profile shows the sine hot again. If revisited: the
libsleef.a library form only, Sleef_sind4_u10 direct calls, pin 3.9.0
commit 906ca7512ee483296780a81a21b9ca715d40dfe1, build with
-DSLEEF_ENABLE_TLFLOAT=OFF (its ON default git-clones tlfloat at build
time - forbidden in compile scripts), opt-in guard.

Collateral finding (recorded here; separate ticket if acted on):
simde_mm256_fmadd_pd is NOT fused on arm64 (fmul.2d + fadd.2d, two
roundings; only the 128-bit simde_mm_fmadd_pd emits a fused fmla.2d),
so the existing uses in basics.c ~1207-1211, cosmo2D.c:320 and
cosmo2D_scuts.c:162 are unfused on Apple Silicon but fused on x86 - a
silent cross-platform bitwise difference (harmless under the
tolerance-based frozen tests, but worth knowing when comparing dev and
production numbers). Related: under -frounding-math -ftrapping-math,
SIMDe FP compares and cvttpd scalarize on arm64.

Original request (2026-09-29): "try multiple vectorizations on halo.c
given how slow it is"; adding SLEEF as a dependency was acceptable if
testing showed it worth it. The
algorithmic steps are done (NFW transform through a Si/Ci table,
one-pass HOD tables, one loop nest per spectrum table); what remains in
the hot loops is nfw_um's sines and table reads.

**Severity: LOW.** Performance only.

### What is already in place

- u_KS: its S and Q sums are SIMDe loops, confirmed in the disassembly
  (fmul.2d/fadd.2d); a small gain (3.15 -> 3.00 ms per Gamma change).
- basics.c spline2d_upsample_uniform: row-wise second pass with SIMDe
  (2026-09-29, single thread: 2.50 -> 0.41 ms per call at the u_KS Q
  table size).
- Measured 2026-09-29 (4 threads): p_mm table build 0.42 s, p_gm and
  p_gg 0.65 s each. A sample(1) profile of the p_mm build puts nfw_um's
  own code and the libm sine at about equal time; merging the two sines
  into one sincos gave no gain.
- The measurement recipe: clang -Rpass/-Rpass-missed/-Rpass-analysis
  remarks with the house flags (minus -flto) to see what the compiler
  does, disassembly (otool -tv / objdump -d) to confirm SIMDe paths,
  interleaved A/B medians for every speed claim.

### What is missing

- nfw_um in SIMDe over the mass nodes: the table reads become gathers
  and the sines need a vector sine (SLEEF through SIMDe's
  simde_mm256_sin_pd; without SLEEF that call is a per-lane libm loop);
  A/B against the scalar path.
- SLEEF through Cocoa's package mechanism (pinned commit, setup and
  compile scripts, .gitignore entry), and a decision on the default:
  SLEEF results differ from libm at the ULP level (1-ULP variants),
  deterministic per machine but not bitwise across x86/ARM - on by
  default, or behind a flag like COSMOLIKE_AGGRESSIVE_MODE.

<a id="open-web-halo-model"></a>
## Web-halo model (WHM, arXiv:2508.10902) for nonlinear P(k)

### High-level summary

The web-halo model (Stuecker et al., arXiv:2508.10902) is a
parameter-free variant of the halo model: alongside halos it adds
structures collapsed along two axes (filaments) and one axis
(sheets), combined with 1-loop Lagrangian Perturbation Theory in
one consistent framework. Against N-body power spectra it reaches
better than 2% up to k = 0.4, 0.7 and 1.3 h/Mpc at z = 0, 0.8 and
1.5, matching baccoemu and EuclidEmulator2 across their full
w0waCDM + sum m_nu space - where HMcode-2020 needs 12 tuned
parameters and degrades at high z. The authors released WHMcode
integrated into the HMcode implementations for CAMB and CLASS.

### Current status

**Ticket type: NEW FUNCTIONALITY.**

**OPEN.** Longer-term interest declared by the maintainer
(2026-09-28); intake ticket, no implementation started. Sequencing:
after (or alongside the later phases of) the halo.c modernization
campaign, which supplies the unit-test harness and the HMcode-family
porting precedent any WHM work would build on.

**Severity: LOW.** Pure feature; no current pipeline depends on it.

### What is already in place

- The halo.c campaign staging (halo_wrapper.cpp bindings plus
  test_halo.py with frozen references) gives new halo-model code a
  validation harness.
- Original-cosmolike `theory/halo_hmcode.c` (HMCode-2020, Ludlow16
  concentrations, multi-field I0j_y) is available as a reference and
  its port is a staged campaign phase - the natural precedent for a
  WHM sector.
- EuclidEmulator2 already runs inside Cocoa, so one of the paper's
  two accuracy baselines is available in-tree for validation.
- Cocoa ships a pinned custom CAMB fork; WHMcode being released
  inside HMcode for CAMB means an upstream-adoption route exists in
  addition to a native cosmolike-side port.

### What is missing

- Route decision: adopt WHMcode through the custom CAMB fork's
  HMcode (pin bump, Fortran fences per house rules) versus a native
  C port next to the halo_hmcode phase; criteria include whether the
  halo-model sector must stay differentiable/emulable inside
  cosmolike and how the y/gas extensions interact. Maintainer lean
  (2026-09-28): a native cosmolike implementation, including the
  1-loop LPT ingredient itself, "may be advantageous for us ...
  when the time comes" - so scope the native route first and treat
  the CAMB adoption as the comparison baseline, not the target.
- Physics review of the WHM construction (sheet/filament mass
  fractions, 1l-LPT matching) before any port.
- Validation plan: reproduce the paper's accuracy claims against
  EuclidEmulator2 in-tree over the shared parameter space.

<details><summary>Technical record</summary>

- Paper: https://arxiv.org/abs/2508.10902 (WHM; public code WHMcode
  in the CAMB and CLASS HMcode implementations).
- Maintainer intake: 2026-09-28, "longer term - I am also very
  interested in implement this".
- Related staging: halo campaign documents (session scratchpad
  halo/STAGE.md, 2026-09-28) list the halo_hmcode.c inclusion phase
  this ticket would follow.

</details>

<a id="closed-tickets"></a>
# Closed tickets

<a id="closed-cache-key-hardening"></a>
## Cache invalidation review and fixes (2026-11-26)

Core `d9281c0` fixes three reproduced in-process state defects:

- Native FAST-PT checks the existing Python-producer flag before reusing
  a table. Memory-address reuse no longer hides a producer change.
- Loaded optical and cluster measurements retain their angular bin
  definitions; Fourier measurements retain their band centers. Changed
  bins require matching measurements to be reloaded. Integration-accuracy
  changes and exact restoration of the binning remain allowed.
- `initial_setup` clears the previous model's optical measurements and
  baryon principal components through the existing state owners.

The new checks reproduced the defects on the previous libraries. After
rebuilding, 37 native checks passed: eight focused optical transitions,
13 LSST Y1 setting/cache checks, 14 DES Y6 setting/cache checks and two
Fourier checks. The LSST Y1 optical and DES Y6 optical/cluster predictions,
masks and likelihood values were bitwise unchanged at the saved ordinary
points, using four OpenMP threads and one BLAS thread. All ten project
interfaces rebuilt and were installed. Seven sibling interfaces also
passed direct import/reset checks; no new numerical survey was run there.

Regression commits: LSST Y1 `9f147c8`, LSST Y1×DESI `2d5bc9e`, DES Y6
`43d4d71`. The core README explains ownership, measured bins and reset
behavior. The production diff stays within five existing files and adds
no new framework, dependency or numerical kernel.

Verification records:
`/private/tmp/cocoa_cache_baseline_20261126.bcHOqh/`,
`/private/tmp/cocoa_cache_fixes_build_zeuu9clf/` and
`/private/tmp/cocoa_cache_fixes_other_builds.DjFub8/`.

<a id="closed-vic-emulator-validation"></a>
## Vic emulator validation for DES Y6

**NEW FUNCTIONALITY. CLOSED (2026-11-24).**

DES Y6 commit `03efa2e` records an executed CAMB comparison notebook,
legacy-reader spectra with provenance, and physical-theory MCMC/Nautilus
examples. Candidate code `5324e81` and data `c0f19f3` were tested in
separate checkouts; installation defaults and other projects were not changed.
The seven-input `w0wa_mead2020` bundle does not supply the DES feedback
parameter or a trained neutrino-mass dimension. At the fixed-mass fiducial,
its nonlinear spectrum differs by up to 1.24% from plain HMCode2020 and
28.5% from the DES feedback model. At 0.30 eV the plain-HMCode discrepancy
reaches 14.2%; 0.60 eV produces nonfinite values. These mass tests probe
compatibility with the DES prior, outside the network's trained inputs.
CAMB reference refinement changes nonlinear power by up to 0.53%, so the
percent-level discrepancy is not a converged error bound. The new reader
changes legacy nonlinear predictions by up to 0.76% at three tested points.
An inherited derived-sigma8 bug uses radius 8 Mpc instead of 8/h Mpc:
1.0575 versus 0.8141 on the same fiducial spectrum. No claim is made that
this bug originates in the candidate branch.

Validation: seven notebook code cells executed, plot inspected, candidate
Cobaya spectra including extrapolation finite at the fixed-mass fiducial,
native DES Y6 build passed after adding the shared halo-profile source.
MCMC and Nautilus preserve the original likelihood, theory and priors;
their evaluated log prior and log likelihood match exactly. Four OpenMP
threads and BLAS=1. No sampling or production simulations were launched.
Adoption is deferred pending a matching physical model and further
likelihood-weighted validation; the DES Y6 studies ticket remains open.


<a id="closed-covariance-geometry-prs"></a>
## Survey-mask and cluster-area covariance inputs (2026-11-24)

**Ticket type: NEW FUNCTIONALITY. Severity: MEDIUM. CLOSED.**

Manually ported upstream PRs 63 and 64 in core `a5dc03c`, with native
regressions in DES cluster `606995a`. Raw binary-mask power, measured
pair availability and redshift-dependent count area reach notebook and
production forecasts and the covariance YAML reader. Measured pair areas
bypass harmonic reconstruction. Invalid geometry and distinct-window
SSC approximations violating the Cauchy bound fail explicitly; remaining
mask and cross-window assumptions accompany the saved forecast.

An isolated covariance build passed 59 tests, with 10 opt-in slow halo
checks skipped; four existing CLI-reader tests also passed. The 27 default
ordinary/joint forecast arrays remained byte-identical. BLAS used one
thread; OpenMP was capped at four. Installed libraries and other teams'
C/C++ edits were left intact.

<a id="closed-bacco-cobaya"></a>
## BACCO paired-response Cobaya integration (2026-11-19)

Registered the bundled `bacco_bispectrum` theory through Cocoa start/stop
links and `IGNORE_BACCO_BISPECTRUM_CODE`, including key cleanup. It reads the
solved CAMB state and reuses the existing total-matter response producer;
BiHalofit remains the absolute DMO bispectrum provider. DES numbered evaluate,
MCMC and Nautilus examples teach the optional theory, five feedback parameters
and likelihood switch with commented YAML, following LSST Y1. Their active
configurations are unchanged. No separate named BACCO example is retained.

All 78 focused checks passed, including real CAMB/BACCO state restoration,
offline agreement, the massless limit and isolated start/stop cleanup.
Production-sampling NLA/TATT joint checks changed both probes and restored
bitwise after feedback, sigma8 and source-shift changes; the nonlinear power
response is applied once. The ordinary gravity-only regression also passed.
No notebook, refreeze, Fisher forecast, posterior or timing study was run.
The native kernels are unchanged; the project binds the existing nonlinear
power setter. Full records and commands are in DES `tests/VALIDATION.md`.

## 2026-11-19 — Independent 3PCF bridge background derivative

DES 3PCF `d9f2a1e` adds the permanent analytic-geometry test and its
[measured record](../../Cocoa/projects/des_3pcf/tests/studies/bridge_background_analytic.md).
All five cases pass in strict and UBSan builds with identical measurements.
A test-only C reader uses the public header, so the check observes the
bridge's actual Jacobian without duplicating its layout in Python.

For chi(z)=3000 z/(1+0.35z), the maximum interior Jacobian error falls from
2.958e-4 to 4.764e-6 between 41 and 321 nodes. The observer endpoint remains
first order, decreasing from 1.75e-2 to 2.1875e-3. With source and projection
grids fixed, the largest toy IA error falls from 8.638e-5 to 1.345e-6.
Production-like TATT and BACCO grid checks also converge, and all fifteen
paired input-archive hashes agree across builds. These are controlled
uniform-background tests, not survey-level Fisher accuracy bounds. The
direct CAMB route instead supplies H(z)/(299792.458 h); it does not use
this finite-difference Jacobian. No native implementation was changed.

## 2026-11-19 — Optional supplied BiHalofit baseline and NFW documentation

Core `1fa68b0` and DES 3PCF `1086ce5` add the positive absolute-bispectrum
table, Python equation producer, Cobaya Theory adapter and optional YAML
selector. The default remains internal. Strict and UBSan validation covered
the 767-test snapshot; final producer and frozen-input checks passed 57 in
each build. All 344 default-output array comparisons are byte-identical.

The permanent frozen four-row joint test measures a squared covariance-
weighted difference of 1.62e-5 at its fine resolution. The separate 480-row
fiducial NLA comparison gives a data chi-squared change of -0.0831549 with
49/193/97/33 baseline nodes, and keeps all 400 two-point entries byte-identical.
Its squared vector difference is 0.000799865; these are different statistics.
The actual Cobaya/CAMB provider graph passes A/A/B/A cache checks. Neither
comparison establishes Fisher-derivative convergence across the prior.

The [project guide](../../Cocoa/projects/des_3pcf/BIHALOFIT_PYTHON.md) links
durable inputs, results and commands. Core `90a1b3a` explains the persistent
universal NFW table and the separate per-halo angular shear spline, including
their numerical controls and ownership. Core `8c1bfd3` distinguishes their
comoving length and angular units. These documentation-only changes pass
rendering and link checks. Installed DES 3PCF rebuilding remains in
the ordered execution ticket above; the route was validated in isolated
strict/debug builds. No default switch or push was made.

## 2026-11-19 — Retained standalone 3PCF FFTW plans

Core `f9ccd3b` adds retained double-Bessel owners without changing the
existing one-shot API. Strict and UBSan builds each pass 94 tests. Private
instrumentation counts twenty plan creations/destructions for ten one-shot
calls, versus two creations with no intervening destruction for ten calls
through one retained owner. Padding initialization, state changes, multiple
owners and one/four/six-worker comparisons are checked. The finite-triangle
forecast already retained its plans, so these checks are not a forecast
speedup claim. The durable record is
`cosmolike_core/dev_scripts/threepcf_fft_plan_check/RUN_RECORD.md`.

## 2026-10-07 — Covariance CLI timings with dense power tables

Refreshed the main README from 21 fresh sequential production CLI runs:
three per project, eight OpenMP threads, global 11,993-node power tables.
The [timing record](covariance_timings_20261007.json) preserves individual
measurements, sample scatter, source revisions and input/library hashes.
All G, SSC, cNG and total components repeat bitwise; component sums are
exact and totals pass Cholesky checks. DES cluster retains its 2,812-entry
archive and is positive on its documented 2,764-entry valid subspace.
These saved-run checks do not replace accuracy-convergence studies.

## 2026-10-03 — Retired production scalar SIMD switches

Removed `COSMO2D_NOT_USE_SIMD`, `HALO_NOT_USE_SIMD`, and the covariance
scalar opt-out. Existing SIMDe paths now compile in optimized and debug
builds; all seven project Makefiles require their headers. Scalar
single-point kernels and incomplete-vector tails remain where needed.
The global switch retirement was explicitly requested separately from the
covariance port and does not relax its `cosmolike/covariances/` boundary.

The retained C tokens match the previous SIMD branches in all 11 affected
existing C/header files. Scalar comparisons are available through external
tests and pinned historical sources; no replacement production switch was
introduced. The unused halo sources remain uncompiled.

All seven optimized interfaces were rebuilt, then **399 project tests
passed**, including all Roman slow halo checks and the seven new covariance
primitive tests. No references were refrozen. Selected debug runs passed
another **24 checks**: 10 LSST Y1 and 14 DES cluster, covering the common
and cluster paths. The project libraries were left in optimized mode.

| Project | Passed | Test runtime (s) |
|---|---:|---:|
| roman_real | 104 | 1285.27 |
| roman_kl | 49 | 1513.83 |
| roman_fourier | 45 | 1029.51 |
| des_y3 | 63 | 1090.45 |
| lsst_y1 | 64 | 824.30 |
| desy1xplanck | 45 | 897.60 |
| des_cluster | 29 | 517.33 |

These runtimes include CAMB and repeated models; they are not likelihood
benchmarks. A separate manual didactic review followed the tests, fixing
stale branch references and recording the remaining scalar-tail roles.
The Gaussian foundation also completed its own review: 80-column C/header
lines, separate comparisons, house SIMD names, equations, array ownership,
units and thread responsibilities. The full covariance rewrite remains
[open](#open-covariance-rewrite).

<details>
<summary>Source, validation records and local commits</summary>

Core retirement: `b8be6c5`. Gaussian baseline, SIMD implementation and
naming follow-up: `6f055d0`, `6bc8cb7`, `7286d55`. LSST primitive checks:
`fe865a6`. Durable records are in the core skill's
`references/simd_retirement.md` and `references/covariance_rewrite.md`.
External validation lives in `test/simd_reference/results/` and
`test/covariance_reference/results/`; their runners keep build/import
checks and every test exit status. Earlier interrupted or environment-only
attempts are separate from the final rebuilt-project results.

Project build commits:

| Project | Commit |
|---|---|
| lsst_y1 | `8ad57c9` |
| roman_real | `3edba1a` |
| roman_fourier | `96b0af6` |
| roman_kl | `30f8bcc` |
| des_y3 | `3c4af70` |
| desy1xplanck | `7194601` |
| des_cluster | `ddd94da` |

All commits are local. Nothing was pushed.

</details>

## 2026-10-03 — Evolving neutrino variance and cb halo statistics

Completed owner-approved Phases 2 and 3: FFTLog sigma_m^2(M,a),
sigma_cb^2(M,a) and their mass slopes; production halo statistics use cb
peak heights and mean density, with D_cb(M,a) in the concentration.
Retired halo_matter_field. The M200m radius definition and lensing mass
weight retain total matter. CAMB supplies cb directly; EMUL2 retains its
existing documented approximation.

Reused serially created FFTW plans and grouped per-thread work arrays,
with step-by-step physics and numerical documentation. The complete
(field,a) row schedule was about 6% faster than the tested split collapse(3)
layout at 8 threads. Removed COSMO3D_ASSUME_PIECEWISE_UNIFORM and its
binary-search alternatives; all builds use direct-index helpers.
OpenBLAS stays at one thread in both covariance paths and after setup;
explicit CosmoLike OpenMP loops retain their requested team. Both paths
check the inverse residual without recovery machinery.

All seven final default-build suites passed (392 tests):

| Project | Result | Elapsed seconds |
|---|---:|---:|
| des_cluster | 29 passed | 577.39 |
| lsst_y1 | 57 passed | 891.94 |
| roman_real | 104 passed | 1367.35 |
| roman_fourier | 45 passed | 1093.93 |
| roman_kl | 49 passed | 1564.64 |
| des_y3 | 63 passed | 1191.31 |
| desy1xplanck | 45 passed | 948.81 |

The independent cluster reference suite passed 30 tests; selected debug
checks passed 39 Roman and one cluster test. Aggressive mode was retired
by owner decision (separate closed record). Direct-integration variance
error is at most 1.81e-5; one/eight-thread tables and the complete Roman
NLA/TATT vectors are bit-identical. Independent matched cluster joint
vectors satisfy delta chi2 < 0.2, including nuisance and production checks.
Three of 33 stricter row-level precision targets still miss 1e-4 and are
explicitly documented; no claim of universal row-level agreement is made.

Intentional frozen updates use the documented generators, in separate
commits; vector changes also include the previously committed Phase 1
growth convention. The tracked implementation record and plan are in
cosmolike_core/.claude/skills/cosmolike-dev/references/. Raw execution logs
are local in test/neutrino_growth_study/implementation/. No pushes; the
owner handles publication.

## 2026-10-03 — Accuracy-qualified M2 Pro comparison timings

Replaced the old Intel/default-setting table with the four saved M2 Pro
LSST-Y1/Roman-Real NLA/TATT measurements (8 OpenMP threads, 2026-10-02).
The timing log was committed in CCL-benchmark a6212ea on 2026-10-02.
Audited `CCL-benchmark/cocoa_comparison/timing_macos.txt`, both timing
scripts, `results.json` and saved study reviews: CoCoA means
0.0459/0.0528/0.0703/0.0764 s, DESC-CCL means
10.450/15.414/17.962/22.747 s, rounded ratios 228/292/256/298.
This is verification of the saved run, not a new benchmark of the modified
libraries. README explains within-code convergence (delta chi2 < 0.2),
CAMB exclusion, two warm-ups, 20/10 evaluations and configuration scope.
The older Intel measurements for other likelihoods were not relabeled.
Follow-up gamma_t check against timing commit a6212ea: the older
ccl_test_lsst.py/ccl_test_roman.py benchmark used Limber for galaxy-galaxy
lensing, while CoCoA included non-Limber C_gs. The M2 timing script runs
ref, whose nonlimber_gs=True passes l_limber=150 and FKEM to angular_cl
for the gamma_t pairs. README distinguishes those configurations explicitly;
it does not attribute the older omission to the new reference timings.
Linked the study and raw log for reproduction or challenges; both URLs
returned HTTP 200. Markdown render passed (1 table, 39 blockquotes), all
internal anchors resolved.

## 2026-10-03 — Retired aggressive compiler mode

Owner chose the optimized strict-IEEE default and debug builds only.
Removed the aggressive branch from all seven project Makefiles; requesting
COSMOLIKE_AGGRESSIVE_MODE now fails clearly at parse time (all seven guards
checked). Installation guidance and the development skill list unsupported
fast-math flags, including -Ofast; the failing bundle was tested, not each
flag in isolation. Default/debug compiler options are unchanged apart from
the separately validated direct-index and BLAS-link changes.

Evidence: pre-change core 4adf735 and cluster interface aa32535 reproduce
max |R R^-1 - I| = 4 on dummy-data initialization with OpenBLAS=1 and
OpenMP=1. The current aggressive cluster build also fails. Current Roman
aggressive tests had 34 passes and 5 failures: four covariance-inverse
residual failures (83919.9135), plus one tiny halo rounding mismatch
(max relative 1.47e-12 against a 1e-12 frozen tolerance). Default builds
pass; permanent BLAS pinning does not repair the aggressive configuration.
The chosen resolution is to withdraw that configuration, not add fallback
inversion machinery. Raw evidence remains in the local study logs and the
tracked sigma_fftlog_implementation.md record.

Grouped by subject and compressed. Nothing here is open work; dated
measurements are kept, since this section is a decision record, not a
README. To reopen a ticket, move its content back under
[Open tickets](#open-tickets) as a full ticket section and add its
`- OPEN` index line.

## Scale-cut refill: coarse dln caches and the 128 default (2026-09-28)

- **Implemented** (cosmolike_core 1f67c0b + one binding commit per
  project): the dlnxi/dlnw_ks caches - the measured owner of the
  scale-cut refill, one full nointerp Legendre build per ln k node -
  run their exact builds on the coarse nodes of the scale-cut k
  knob, and the house cubic spline upsamples every row onto the
  unchanged 256-node grid. The nointerp node fills read the dC
  tables' two bracketing k-rows through the new dCss_/dCks_ sharing
  structs via the file-local limber_krow_blend (SIMDe: contiguous
  loads and one fused multiply-add per lane - no gathers, since the
  weight and row offset are shared by every entry, unlike
  limber_fill_interp's per-multipole indices).
- The knob default moved 0 -> 128 from measurement (roman_real):
  refill 5.628 -> 2.788 s (2.0x; 96 gives 2.107 s = 2.7x; 192 gives
  4.317 s), max |dRF| 2.8e-3 ss / 5.9e-3 ks with ~1e-6 medians - at
  or below the response error the retired quadrature imposed; chi2
  is knob-independent, and the shipped default was verified end to
  end (2.795 s with no knob calls). The RF workers keep their
  scalar cache sampling: measured at 1.1 ms warm, nothing to win -
  the third attribution lesson of the day, this one caught before
  implementing. Suites lsst_y1 57 + roman_real 50 on the shipped
  default.

## RF workers: closed-form cumulative, quadrature retired (2026-09-28)

- **Implemented** (cosmolike_core 6e160ac): RF(kmax) integrates
  |dlnX/dlnk|, and the tabulated response the workers consume is
  piecewise linear in ln k, so both RF integrals are closed form
  (trapezoids; two triangles where the response crosses zero; a
  partial = prefix + the analytically cut last interval, direct
  index, no search). All four workers (RF_xi, RF_w_ks, RF_C_ss,
  RF_C_ks) dropped their per-kmax Gauss-Legendre sweeps for one
  cumulative per row: a per-kmax sweep was an expensive
  approximation of a function whose integral has a closed form.
- Measured: removed Gauss-Legendre error max |dRF| 3.1e-3 (ss) /
  5.4e-3 (ks), medians 8e-17 / 5.5e-5 - the old rule failed at the
  |.| kinks, where the closed form is exact, and the error was
  comparable to the coarse-table dRF, so RF accuracy was never
  better than few x 1e-3 before this change. Honest timing:
  roman_real per-cosmology rf refill 5.754 -> 5.676 s; the sweeps
  were ~80 ms of it (the open dlnxi ticket holds the true owner).
  Suites lsst_y1 57 + roman_real 50.

## Threaded scuts plane upsamples (2026-09-28)

- **Implemented** (cosmolike_core caaba62): the four coarse-grid
  refills upsample their ~120 independent (ln k, ln l) planes under
  omp parallel for (collapse(2) on the ss pair). Bitwise against
  the serial build; interleaved A/B timing (one process, 12
  alternating samples per setting): fully coarse derivative refill
  45.0 ms vs 42.8 ms exact - the upsampling overhead is gone and
  the coarse path is break-even on the already-cheap derivative
  tables.

## sigma2(M): lobe-summed quadrature, the 14.1 cutoff retired (2026-09-28)

- **Implemented** (cosmolike_core 080347a + one binding commit per
  project): the mass-variance quadrature integrates lobe by lobe
  between the zeros of the top-hat window (roots of tan x = x,
  McMahon start + Newton), one low-order Gauss-Legendre rule per
  single-bump segment, stopping when the near-geometric tail bound
  s_j r/(1 - r) drops below 1e-7 of the running total. The node
  cache (nodes, weights folded with 9 j1^2, segment offsets) is
  mass-independent and Ntable-keyed; sigma2_work fills the whole
  table threaded over masses with one p_lin read + fma per node.
  int_for_sigma2 and the fixed x < 14.1 cutoff are DELETED;
  sigma2_nointerp is the one-mass point diagnostic. The cached
  table upsamples from Ntable.N_M_internal = 192 coarse ln M nodes
  (house cubic spline in ln sigma^2); the knob joined
  init_accuracy_boost's ladder.
- Measured: the old cutoff cost up to 4.577e-3 relative in sigma^2
  (worst at M = 2e12 Msun/h; median 5.7e-4 over 1e10..1e16) - the
  cutoff sat just past the window's 4th zero (14.0662) with no
  stated error budget. Table upsampling + interpolation: max
  2.7e-5. Stage-2 point diagnostic bitwise-reproduces the stage-1
  lobe values; OMP 1 vs 4 bitwise identical; suites lsst_y1 57 +
  roman_real 50.

- **Implemented** (cosmolike_core 0172c0e + one binding commit per
  project): C_gk_tomo_limber and C_ks_tomo_limber adopt the internal
  coarse ell grid (exact quadrature on Ntable.N_ell_internal nodes,
  the house cubic spline upsampled onto the unchanged N_ell table,
  workspace static in the Ntable rebuild block, threaded
  evaluation); C_gg alone keeps the exact grid. The four dC_X/dlnk
  scale-cut tables coarsen in 2D through the new
  spline2d_upsample_uniform (basics.c: tensor-product natural
  bicubic, two passes of the house 1D spline, precomputed direct
  indices): the ell axis follows N_ell_internal, the ln k axis gets
  Ntable.dCX_dlnk_nlnk_internal (default 0 = exact; ln k carries
  the BAO wiggles). init_accuracy_boost became the global super
  function - one call scales every sampling knob, internal grids
  and FPT_internal_accuracy_boost included, from first-call
  baselines, so the coarse/dense ratios are boost-invariant -
  recorded in the cosmolike-dev skill with the rule that every new
  sampling knob joins its ladder.
- Validated: lsst_y1 frozen chi2 3.4316970976e-02 bitwise (3x2pt
  untouched by gk/ks); desy1xplanck 6x2pt exact-vs-192 dv max rel
  1.159e-05 (median 2.2e-07), chi2 delta 4.3e-08; suites lsst_y1
  57, roman_real 50, desy1xplanck 45, all green. Scale-cut impact
  measured through RF, the real consumer (the dlnC batch reads
  compute on caller grids and bypass the cached tables): ell at
  192, max |dRF| 3.2e-3 ss / 4.3e-3 ks (medians 2e-16 / 8e-5);
  k at 192-of-256 adds a similar 3.2e-3 / 3.5e-3 - RF integrates
  |dlnC/dlnk| over ln k, so wiggle interpolation errors partly
  cancel. Also fixed in passing: a factor-2 error in the
  spline_coeffs_uniform header derivation (the code was always
  right).
- Ticket-B evidence from the A/B: on desy1xplanck the fresh chi2 at
  internal=192 depends on how many pre-first-evaluation
  Ntable.random bumps ran (8.6002538251e-06 after one init call,
  8.5994603071e-06 after two; the exact path is bump-invariant in
  the same comparison) - the invalidation-sequence dependence the
  cache-hardening ticket hunts.
- Timing post-mortem (three protocols, roman_real): on
  Ntable.random bumps the scuts rebuild is ~5.9 s of Ntable-keyed
  machinery regardless of the knobs; on cosmology-keyed refills it
  is ~5.7 s dominated by the dlnxi cache build (its open ticket
  holds the contraction design); the dC+dlnxi table stage in
  isolation is 42.8 ms exact vs 154 ms coarse-serial vs 45.0 ms
  coarse-threaded (caaba62). Lesson recorded: time the
  invalidation class the workflow actually triggers, and profile
  before attributing.

## Sector-ladder cache-consistency test (2026-09-28)

- **Implemented** (one commit per project, all six):
  `tests/test_cache_consistency.py` walks a deterministic parameter
  ladder in one process - three cosmology-only steps, then IA-only,
  source-photo-z, lens-photo-z and shear-calibration steps, a sector
  the configuration does not sample dropping out (the Roman lenses
  are the source sample; roman_kl also fixes every IA amplitude) -
  evaluating after every step with cobaya's cache bypassed, then
  scrambles every sector at once and returns to the ladder's final
  point: the data vector and chi2 must reproduce bit for bit, and a
  second instance walking the mirrored sector order must land on the
  same vector. Every step must change the vector, each
  shear-calibration step must equal the analytic (1+m_i)(1+m_j)
  block rescale to 1e-12 (the ks cross scales by its source factor;
  the point-mass term rides inside gamma_t), and a no-op update must
  change nothing. Both IA models run: the TATT ladder exercises the
  FAST-PT rebuild machinery NLA never touches.
- All six projects pass (NLA + TATT, forward + mirrored). The target
  is the partial-invalidation class the per-point suites never
  exercise - the class of the cache-hardening ticket's measured
  post-initialize Ntable.random bump defect.

## Internal coarse ell grid for the C_ss/C_gs tables (2026-09-28)

- **Implemented** (cosmolike_core a3d19e2 + one binding commit per
  project): the exact quadrature runs on Ntable.N_ell_internal
  log-spaced nodes (default 192) and a cubic spline in ln l upsamples
  each (component, pair) row onto the unchanged 512-node table at
  cache-build time; init_ntable_ell_internal (bound in all six
  projects, 0 = exact) is the A/B switch. C_gg keeps the exact grid
  at every node, with the BAO-wiggle warning in its header.
- Validated (lsst_y1 frozen fiducial, equal footing): data-vector
  upsampling error max 2.1e-4 relative (median 5.6e-7), chi2 delta
  1.9e-6. Timing (median of 8, 4 threads; the deltas are CAMB-free -
  the theory cost is identical in both settings and cancels):
  lsst_y1 saves ~3 ms per evaluation, roman_real ~19.5 ms
  (1.5037 -> 1.4842 s; ~13% of its cosmolike share), roman_kl
  ~68 ms (2.2294 -> 2.1615 s; its 10 source bins carry the largest
  tables) - the pair-count scaling the ticket predicted. Suites
  lsst_y1 55, roman_real 48 after the six projects
  re-pinned their baryon drift vectors on this build (the
  test_accuracy_baryons in-place rewrite, now documented in the
  maintenance skill, surfaced with the first shear-touching change).
- The A/B also exposed and recorded a pre-existing defect in the
  cache-hardening ticket: a bare post-initialize Ntable.random bump
  shifts the frozen fiducial chi2 by 2.5e-4.
- Follow-up after review (cosmolike_core e1e33f8): the coarse-grid
  workspace - nodes, prefactors, result and coefficient tables, and
  the precomputed fine-node interval indices and offsets - is
  allocated only in the Ntable.random-keyed rebuild block, and the
  GSL spline objects were replaced by the house natural cubic spline
  (spline_coeffs_uniform + direct-index Horner evaluation; both
  grids are uniform in ln l, so there is no search and no
  accelerator state), with the evaluation loop threaded. The lsst_y1
  frozen fiducial chi2 3.4316970976e-02 reproduces exactly.

## cfftlog activity mask: empty radial slots skipped (2026-09-28)

- **Implemented** (cosmolike_core da14c54): cfftlog_ells_p1/_p2 accept a
  per-(row, slot) activity mask (NULL = all active); inactive slots
  skip their forward and inverse FFTs and write exact zeros.
  C_gs_tomo declares the mask its fx assembly implies (lens rows:
  density always, RSD under include_RSD_GS, magnification when some
  gbmag != 0; source rows: slot 2 alone) - 10 of 30 row-slots active
  at the lsst_y1 defaults. C_cl_tomo keeps NULL: its conditional
  SIZE2 already drops the magnification slot when bmag = 0. The
  relevance grew with the 2026-09-28 default switch: non-Limber ggl
  now runs by default in four projects.
- Validated: bitwise (the skipped slots held identically zero
  kernels; lsst_y1 frozen references reproduce to all ten printed
  digits); full-evaluation median 1.677 -> 1.673 s (macOS arm64,
  4 threads, median of 8). Suites: lsst_y1 55, roman_real 48.

## Correctness sweep of the 2026-09-28 review findings (2026-09-28)

- **All confirmed defects fixed in one pass** (cosmolike_core
  c4aa392): the sigma2_nointerp out-of-bounds ar[1] read (the scale
  factor now reaches p_lin), the chi_all fallback j+2 clamp, finite
  f_growth/norm_growfac_all at exactly z = 0 (all four variants,
  z > 0 branch bit-identical), the swapped f_K open/closed labels,
  the swapped zmean_source cache stamps (table rebuilt every call),
  the N_ggl < -1 rebuild guard (an excluded pair (0, 0) rebuilt the
  map per call), the W_RSD bin guard, the stale bs2 on b1-only
  updates, the set_source_sample bump-before-warm-up order, the
  init_probes mixed-case out_of_range, the init_ggl_exclude
  odd-length refusal, the dlnxi normalization swap (1 - p; reported
  2026-09-27), and the RF_C_ss/RF_C_ks vanishing-denominator guard
  (the BB plane under NLA was 0/0 = NaN). Cleanups: misattributed
  fname strings, wrong wrapper error names, dead has_b2 copy and the
  disabled flat-vector block, double semicolons, the gg scalar
  wrapper overload declared.
- Validated: frozen lsst_y1 references reproduce the pivot-build
  values at all compared digits; test_scale_cut_diagnostics 4/4
  (the dlnxi and RF changes live under its assertions); suites
  lsst_y1 55, roman_real 48, green.

## Per-bin pivot for the FKEM separable spectrum (2026-09-28)

- **Implemented the same day it was proposed** (cosmolike_core
  3c9ed69): the separable linear spectrum of the non-Limber split
  is anchored per lens bin at a_piv = 1/(1 + zmean(bin)),
  P_sep = (D(z)/D(a_piv))^2 P_lin(k, a_piv), in the FFTLog terms of
  C_cl_tomo and C_gs_tomo and both use_linear_ps = 1 Limber legs
  together (the cancellation invariant); C_gs_tomo's shared P_lin
  table became per lens bin. COSMO2D_FKEM_PIVOT_Z0 restores the
  z = 0 anchor exactly.
- Validated: the l = 149 cancellation floor unchanged (des_y3 BMAG
  fiducials, 1.126e-3 vs 1.125e-3); lsst_y1 references move by
  delta chi2 = 0.034 (3x2pt) / 0.031 (2x2pt), inside the 0.2 band,
  deliberately not refrozen; at the fiducial Sigma m_nu the
  correction content shifts by 0.05-0.15% of itself at l <= 50 (the
  removed error grows with Sigma m_nu). Suites on the pivot build:
  lsst_y1 55, roman_real 48, all green.

## Non-Limber defaults, regenerated data vectors, and the refreeze (2026-09-28)

- **ggl defaults switched to non-Limber** (`adopt_limber_gs: 0` in
  the yamls, interface bindings, prototype fallbacks, tests and
  READMEs) for lsst_y1, roman_real, roman_fourier and roman_kl: the
  measured Limber cost, delta^T C^-1 delta = 1.86 / 0.49 / 1.30 /
  1.63 at the frozen fiducials, was judged too large to absorb.
  des_y3 and desy1xplanck keep Limber ggl (0.011 / 0.0037).
- **Shipped simulated data vectors regenerated** at the frozen
  fiducial points with the gg growth fix and the new defaults:
  lsst_y1_theory.modelvector (NLA) and lsst_y1_theory_TATT
  .modelvector, roman_real example1.modelvector, roman_fourier
  roman_example.datavector, roman_kl roman_kl_3x2.modelvector and
  roman_kl_2.modelvector (KL-mode vectors: the ggl switch moves
  every 3x2 mode and the probe-mixed third of the mcmc vector, by
  construction of the compression).
- **All six snapshots refrozen** (`--overwrite`, `--baryons`): every
  exact-configuration reference sits at its minimum again
  (0.000000-level; the des_y3 0.168 and desy1xplanck 0.0092 gg-fix
  drifts absorbed into the regenerated frozen fiducial vectors; the
  measured drifts matched the predictions to three digits). lsst_y1
  emul2 references now read the pure emulator-vs-exact difference
  (0.289 / 0.772, was 0.554 / 1.383 against the stale vector).
- **Freeze-generator gap closed**: the per-mask TATT dataset
  descriptors of the `--mask` comparison sweeps (hand-added in
  lsst_y1 712739e and siblings) were not reproduced by
  `generate_frozen_reference.py`, so any refreeze silently dropped
  them. All six generators now carry `TATT_MASK_VARIANTS` +
  `generate_tatt_mask_datasets()` (run inside `--overwrite`, plus
  the incremental `--tatt-masks` mode).

## int_for retirement and the C_gk _work port (2026-09-28)

- **int_for_C_gs/gg/gk_tomo_limber retired** with their GSL
  per-(node, ell) quadratures; every probe keeps one single-ell
  point diagnostic in the C_ss_tomo_limber_nointerp pattern (one
  batch call, one entry read), and C_ks gained the missing one.
  int_for_C_kk_limber stays: kk has no tomography. Validated by a
  rebuilt lsst_y1 reproducing the frozen reference chi2 to every
  printed digit.
- **C_gk moved onto the _work batch API** (C_gk_tomo_limber_work +
  _nointerp_ells/_batch in the gg design with one leg W_k, the
  64-node ladder of the retired scalar kept, RSD gate and one-loop
  FPTbias tables as in gg): table builder, w_gk low-ell loop and
  both wrapper overloads migrated. Validated on the desy1xplanck
  6x2pt fiducial: ss/ggl/gg/ks/kk bitwise unchanged, the 37 changed
  w_gk entries within 4.0e-15 relative, chi2 unchanged at ten
  digits. Closes the gk/ks _work ticket.

## Non-Limber galaxy-galaxy lensing and the gg batch API (2026-09-27)

- **Non-Limber C_gs shipped** (cosmolike_core): `C_gs_tomo`, the
  FKEM split (arXiv:1911.11947) in the house FFTLog design (hoisted
  forward FFT, per-pair early exit, Limber continuation), with lens
  rows on the Limber lens range (magnification foreground kept),
  one combined lensing + NLA source kernel per source bin, and the
  subtracted Limber term in separable growth. Both Limber terms come
  from the batched `C_gs_tomo_limber_linpsopt_nointerp_ells`
  (`use_linear_ps` switch in `C_gs_tomo_limber_work`, bitwise neutral
  at 0). `C_gs_tomo_ells` adds the correction to Fourier band centers
  (interpolated between integer l). `like.adopt_limber_gs` (default
  1) with `init_adopt_limber_gs`, the yaml key in every ggl
  likelihood of the six projects, `w_gammat_tomo` keyed on the flag,
  and one `tests/test_nonlimber_ggl.py` per project. The reference
  code (cluster_chto `cosmo2D_exact.c`) was not ported line by line:
  its gamma_t Legendre kernel has a typo (Pmin[l+1]-Pmax[l] for
  Pmax[l+1]; wrong by orders of magnitude at l = 2), its l = 1 terms
  are uninitialized, its early exit is dead code, and its RSD uses the
  gamma approximation f = Omega_m(z)^0.55.
- **Validation (lsst_y1 3x2pt fiducial).** FFTLog term vs a
  brute-force double integral (scipy spherical_jn, 20000-point chi
  grid, same kernels): 1e-6 to 1e-4 relative for l >= 3 in all 25
  pairs (~1% at l = 2 for the highest lens bin). FFTLog -> Limber at
  l = 149: ~1e-4 for lens-in-front pairs. Early exit vs none within
  the 1% tolerance. Default data vectors bitwise equal to HEAD (full
  precision). Debug build (UBSan, scalar fallbacks) and aggressive
  build agree with the default to 8e-13 and 6e-12 in lens-bin units;
  OMP 1 vs 8 bitwise; repeated calls bitwise.
- **gg batch API.** `C_gg_tomo_limber_work` + `_linpsopt_nointerp_ells`
  / `_nointerp_ells` / `_nointerp_batch` in the ss/gs design, same
  128-point rule as the scalar path; the table, the w_gg low-l loop,
  the C_cl_tomo Limber pair, the Fourier gg data vector and the
  notebook wrapper moved onto it. Batch vs scalar: 2.2e-15 relative;
  w(theta) moves by 3.3e-14. Cost: 33 ms vs 45 ms (1750 l x 5 bins,
  one thread; W_RSD and P_delta dominate). The measurement of the gs
  batch Limber pair: 3.3 ms vs 51 ms scalar (25 pairs x 150 l).
- **Aggressive-mode n(z) fix.** Under COSMOLIKE_AGGRESSIVE_MODE the
  `arma::find(nofz > c*nofz.max())` of set_lens/source_sample
  returned an empty list for a valid column once this work changed the
  code generation of generic_interface.cpp (HEAD happened to escape).
  The bin-support search is two plain loops, with identical results
  in the default build.
- **Non-Limber C_gg growth fix (kept 2026-09-28, references not
  refrozen by the maintainer's decision).** `C_cl_tomo` subtracted
  C_limber(P_lin) with CAMB's p_lin(k, a) while its FFTLog term uses
  the separable D(z1) D(z2) P_lin(k, 0); D(a)^2 differs from
  P_lin(k,a)/P_lin(k,0) by 0.7% (z = 0.3) to 1.6% (z = 1), so the pair
  never cancelled at high l (-0.85% to -1.6% at l = 149; the 1% early
  exit fired near l = 50 on the crossing of the decaying non-Limber
  excess with the offset). The subtracted term uses D(a)^2
  P_lin(k, 0) (batch and scalar integrands); mismatch at l = 149:
  0.02% to 0.17%. w(theta) delta^T C^-1 delta: lsst_y1 1.52, des_y3
  0.168 (Y3) / 0.030 (Y1), desy1xplanck 0.0092, roman_real 0.0083,
  Fourier projects 0. The lsst_y1 3x2pt/2x2pt reference checks fail
  by 1.43 to 1.52 until a refreeze; the other projects stay within
  the 0.2 limit. Each real-space project's tests/README.md explains
  it in an appendix FAQ.
- **gg Limber switch as a yaml key (2026-09-28).** `adopt_limber_gg`
  (`init_adopt_limber_gg`; 0 = non-Limber in the real-space projects,
  1 = Limber in roman_fourier and roman_kl, so no default changed),
  w_gg_tomo keyed on the flag, and `C_gg_tomo_ells` for Fourier band
  centers. `tests/test_nonlimber_gg.py` in every project measures
  non-Limber minus Limber clustering, delta^T C^-1 delta: lsst_y1 148,
  roman_kl 57.4, des_y3 9.26, roman_real 8.58, desy1xplanck 6.52,
  roman_fourier 3.34 (against 0.0037-1.86 for ggl).
- **Two pre-existing bugs found by the full test suites.** (1) The
  python FAST-PT setters `set_IA_PS`/`set_bias_PS` replaced
  `FPTIA/FPTbias.tab` but left `tab_int` aliasing the freed table;
  the next cfastpt rebuild freed it again (malloc abort in
  `get_FPT_IA`, lsst_y1 suite, also in crash reports of 2026-09-26).
  The setters re-alias `tab_int`, and `get_FPT_IA`/`get_FPT_bias`
  rebuild whenever `tab` is not the table they allocated
  (cfastpt -> FAST-PT -> cfastpt reproduces the first chi2 exactly).
  (2) The static ggl pair maps (`test_zoverlap`, `ZL`, `ZS`, `N_ggl`)
  were filled once per process, so a cosmic-shear model built after a
  3x2pt model with another `ggl_exclude` list miscounted the pairs
  (roman_kl: "IP::set_mask: inconsistent mask"). They rebuild on
  `tomo.random_ggl`, refreshed by `init_ntomo_powerspectra` and
  `init_ggl_exclude`, which also warms them single-threaded.
- **Suites (2026-09-28, one project at a time):** roman_real 47
  passed, roman_fourier 42, roman_kl 46, lsst_y1 48 passed and 6
  failed (the frozen 3x2pt/2x2pt references, off by the gg growth
  fix's delta chi2 of 1.43-1.52); des_y3 60 and desy1xplanck 42 on
  the build before the two bug fixes.

## Scale-cut diagnostics for C_ks and w_ks (2026-09-27)

- **The ks family shipped** (cosmolike_core 7ded4a7; desy1xplanck
  694bd8d): `dC_ks_dlnk_tomo_limber_work` (single-node grid
  derivative, per-bin source-support gating, fused normalize mode),
  cached dC/dlnC tables, `RF_C_ks`, the real-space `dlnw_ks_dlnk`
  pipeline (limber_fill_interp gather, CMB beam/pixel filter,
  gamma_t-type Legendre kernel, normalized by w_ks) and `RF_w_ks`,
  wrapper overloads at the doc standard, desy1xplanck bindings (plus
  plain C_ks_tomo_limber and a fixed live w_ks_tomo binding), six
  notebook wrappers, and a 15-cell EXAMPLE_EVALUATE1 section.
- **Validation.** Truth check: the dC_ks/dlnk integral reconstructs
  C_ks to 4.7e-5 relative (integration_accuracy 3; the 1.9e-3 at the
  default is the 64-point C_ks rule itself). Scalar-vs-array
  overloads and repeated calls bit-identical; RF bounded and
  saturating at 1; 6x2pt chi2 unchanged to the last digit; full
  41-test suite green; the notebook executes end to end (98 cells,
  33 figures). The truth check also exposed the inherited ss
  amplitude bug (see the 2026-09-27 bullet under the scuts
  refactor).

## Runtime n(z) photo-z conventions (2026-09)

- **Two runtime flags shipped (2026-09-24/25).** `Ntable.photoz_interpolation_type`
  (0 = cspline default, 1 = linear, 2+ = Steffen monotone; the
  documented-but-unimplemented switch in basics.c became real, inside
  `malloc_gsl_interp`/`malloc_gsl_spline`, whose only callers are the
  photo-z readers) and `Ntable.photoz_zmid_convention` (0 = z column
  read as Z_LOW left bin edges, values at centers z + dz/2, the
  historical behavior; 1 = Z_MID sample points). One shared
  `init_photoz_conventions` in generic_interface.cpp; the n(z) caches
  watch both values through a packed slot, so a runtime flip rebuilds
  the tables (both directions covered by a bit-identical round-trip
  assertion). No preprocessor flag: a compile-time `#ifdef` was
  rejected because the unit test would need two builds. Defaults
  unchanged everywhere; every default chi2 reproduces its frozen
  reference exactly.
- **Wired end to end in all six projects.** pybind binding, the
  likelihood call, yaml keys in every likelihood variant (31 yamls),
  the notebook wrappers of lsst_y1/roman_real (_CONFIG +
  configure()), and the inline des_y3 notebooks.
- **Unit test + figures + README section in all six projects.**
  `test_photoz_conventions.py` evaluates five settings in one process
  and measures each alternative as delta^T C^-1 delta against the
  default (masked inverse covariance; dead-flag floors);
  `generate_photoz_convention_figure.py` makes the per-pair
  delta-xi/delta-Cl figures the tests README records.
- **Measured (2026-09-24/25, frozen cosmic-shear fiducials).**
  Steffen: 4.1e-5 (lsst_y1), 1.3e-6 (roman_real), 2.9e-6
  (roman_fourier), 1.6e-5 (des_y3), 5.7e-5 (desy1xplanck), 1.5e-6
  (roman_kl); linear: 6.3e-4, 1.6e-4, 9.4e-4, 3.1e-4, 1.3e-3,
  2.0e-5; Z_MID: 1.63, 0.94, 3.60, 0.30, 0.42, 2.35. The interpolant
  is far below statistical precision; the half-bin z-column reading
  is the one photo-z convention that matters, as the 2026-09 DES-Y6
  three-code comparison predicted. Full suites green in all six
  projects (2026-09-25): lsst_y1 (49), roman_real (42), roman_fourier
  (41), des_y3 (59), desy1xplanck (41), roman_kl (45).
- **Deferred decisions, deliberately.** Flipping the default to
  Steffen (the measurements support it whenever desired; a deliberate
  documented accuracy change under the full validation protocol when
  taken). The correct Z_LOW-vs-Z_MID setting per survey is a data-
  product fact (which column the tables were exported from), declared
  per analysis in its likelihood yamls. Motivating measurements: the
  DESY6 source tables carry an overflow-like last row against which
  cspline rings at -0.3% to -0.6% of peak; a single-cell spike makes
  cspline undershoot -13.7% of peak while Steffen stays non-negative;
  detector-plus-rebuild designs were rejected because sampled-n(z)
  analyses rebuild the tables per likelihood call.

## FAST-PT two-grid upgrade (2026-09)

- **Two-grid theory block.** The wrapper now computes its FFTLog
  convolutions on a coarse internal grid and upsamples with a cubic
  spline in log k onto the dense output table the likelihood reads
  linearly. `accuracyboost` scales the output table,
  `internal_accuracyboost` the internal grid, and both are rebased so
  1.0 is the converged default; values above 8 are refused with the
  reason. Shipped as PyFAST-PT v1.0; README added in v1.01.
- **Divergence located.** The historical CFASTPT vs FASTPT
  disagreement (up to Δχ² = 21 at LSST-Y1 precision and Δχ² = 87184
  at Roman precision on the shared single 1,100-point grid) lived
  entirely in the density of the interpolated output table and none
  of it in the convolutions.
- **Six projects converged.** The comparison test passes at the
  defaults on lsst_y1, roman_real, desy1xplanck, des_y3, and roman_kl
  (which keeps a density-independent floor ≈ 0.175); roman_fourier
  needs `accuracyboost: 2.0`. Each `tests/README.md` carries the
  contract, the measurement table, and the corner plot; the example
  yamls carry the rebased defaults.

## Batched shear wrappers and the cosmo2D_scuts refactor (2026-09-26)

- **cosmo2D_wrapper on the batch APIs (2026-09-25).** The C_ss and
  C_gs array overloads make one `_nointerp_ells` call and scatter;
  the scalar overloads are one-element calls into the same engines,
  documented as point diagnostics. Measured on lsst_y1 (100
  multipoles, 4 threads): C_ss 13.2 -> 0.5 ms, C_gs 10.8 -> 0.9 ms
  per call. C_ss matches the retired loop at reassociation level
  (<= 4e-15); C_gs moved onto the likelihood's own 64-point rule
  (the legacy scalar used 96 points), each verified at its rule's
  error against a 2000-point reference.
- **cosmo2D_scuts on the _work design (2026-09-26).**
  `dC_ss_dlnk_tomo_limber_work` computes the scale-cut derivative on
  a (ln k, ell) grid (each output one core evaluation at the Limber
  node chi = (l+1/2)/k, amplitude dchida/fK); its normalize flag
  computes C_ss on the same thread team and divides cache-hot rows to
  dlnC. The hidden deriv argument of int_for_C_ss_tomo_limber is
  gone (the dC point value is the C_ell integrand times chi). The
  cached tables start at l = 1, killing the exact-scalar low-l
  branches; `RF_C_ss/RF_xi_tomo_limber_work` run both RF integrals on
  precomputed Gauss-Legendre node arrays with the kmax-independent
  denominators computed once. RF array call (26x26): 108 -> 25 ms.
- **dlnxi redesigned (2026-09-26).** dlnxi_dlnk_pm_tomo_nointerp now
  reads the dC table on its multipole log-grid, gathers to every
  integer multipole with the vectorized limber_fill_interp (exported
  through cosmo2D.h), and Legendre-sums with restrict + SIMD: first
  call 4.04 s -> 0.04 s, steady 15 -> 8 ms, and the 6.1 GB
  per-integer-multipole cache is gone (work arrays are
  Ntable/tomography-keyed statics).
- **Wrapper cleanup (2026-09-26).** Every int_for_* python wrapper
  and binding deleted from cosmo2D_wrapper and all six projects'
  interface.cpp (never used from notebooks, incompatible with the
  _work design); the unfinished Compton-y family parked in
  future_port_unfinished/cosmo2d_tmp.c; per-argument documentation
  across cosmo2D_scuts, cosmo2D_wrapper and cosmo2D_scuts_wrapper.
- **Validation.** Every step compared old-vs-new dumps on the lsst_y1
  frozen TATT fiducial: bit-identical wherever the arithmetic was
  unchanged (the single-work fusion, the statics, y-move and int_for
  removal were all bitwise), reassociation-level (<= 1e-13) for the
  reorganized sums, and lnl-respacing-level shifts only where the
  table grids deliberately changed. Full suites green through the
  arc; `test_scale_cut_diagnostics.py` added to lsst_y1 and
  roman_real. A cosmetic leftover: the notebook wrappers call the
  dlnC function `dlnC_dlss_tomo_limber` (scrambled name), a
  rename-commit candidate.
- **End-to-end rf_xi measured (2026-09-27).** roman_real, 76-value
  kmax grid, idle machine: the retired path (GSL RF integrals over
  the per-integer-multipole dlnxi table) took 22.4 s on the first
  call and 19.7 s on every repeat at the same cosmology — the GSL
  quadrature re-drove the scalar integrand on each call, cached
  tables or not, while the one-time table builds cost only the
  remaining 2.7 s (and 10.3 GB at roman lmax). The _work path takes
  4.2 s, first call and repeat alike (5.3x / 4.7x), on ~40 MB of
  statics.
- **dC/dlnk node amplitude fixed (2026-09-27).** The per-node
  amplitude multiplied the per-a integrand by |dchi/dlnk| = chi
  without converting the measure (|da/dlnk| = fK/dchida), leaving a
  spurious dchida — inherited verbatim from the retired GSL
  implementation and preserved by the old-vs-new migration, which
  never ran a truth-integral check on ss. Caught by the ks family's
  reconstruction test and fixed (cosmolike_core 81319fc): the
  integral of dlnC_ss/dlnk over ln k is now 0.9996-1.0001 (it was
  1.25-1.57, the kernel-weighted mean of dchida). Every ss
  diagnostic (dC, dlnC, RF_C_ss, dlnxi, RF_xi) carried the smooth
  k-dependent tilt; the likelihood never read this path, and chi2
  is bit-identical.

## Notebook derivative crashes (2026-09-26)

- **Root cause found: a deterministic exit.** The retired low-l RF
  branch underflowed k = exp(-(1-t)/t) to 0 at small quadrature t,
  and the dC point diagnostic's k > 0 guard was log_fatal -> exit(1):
  any rf_C_ss call at l <= 20 killed the process — and a jupyter
  kernel dies from exit(1) with no traceback, matching the reported
  symptom. Two aggravators: every log_fatal/critical in the
  diagnostics exits the kernel the same way (for example running
  cells out of order), and the old dlnxi build allocated 6.1 GB and
  took 4 s per cosmology.
- **Fixed by the scuts refactor** (the branch and the point function
  are gone; dlnxi's cache is gone), and **verified with the
  notebooks' own calls**: drivers running the exact derivative cells
  of EXAMPLE_EVALUATE1 (roman_real, and the section newly ported to
  lsst_y1) complete with finite outputs; the regression test
  `test_scale_cut_diagnostics.py` pins the old fatal multipoles
  (rf_C_ss at l = 3) in both suites.

## Two-grid C-FAST-PT internal grid (2026-09-25)

- **Runtime knob shipped.** `Ntable.FPT_internal_accuracy_boost`
  (yaml key `internal_accuracyboost`; setter `init_fpt_internal_boost`,
  which refuses values <= 0) runs the C-FAST-PT FFTLog convolutions
  of `get_FPT_IA` and `get_FPT_bias` on an internal grid of
  ceil(N * boost) points rounded up to even (the FFTLog engine
  requires an even count — discovered by the convergence scan) and
  moves the spectra onto the unchanged output table with
  `spline_coeffs_uniform` plus Horner evaluation on the uniform ln k
  grid (`fpt_regrid`, no binary search); 1.0 recovers the single-grid
  path exactly and is the reference arm of the accuracy tests. Work
  tables (`FPT.tab_int`), regrid scratch and the FFTLog
  configurations persist across cosmologies and rebuild only when
  Ntable changes; the FFTLog padding/extrapolation spans scale with
  the grid ratio (they are ln-k spans, not point counts).
- **Default 0.5 (Nint = 550), chosen with margin.** Measured
  2026-09-25 on lsst_y1 frozen TATT fiducials: delta^T C^-1 delta vs
  the single-grid path <= 1e-10 (shear) and <= 1e-9 (3x2pt) down to
  298 internal points, converged from above at 2200; the default
  keeps a ~100x chi2 margin over the 298-point arm. FPT table cost
  fits 1.55 us * N ln N on the M-series Mac: 11.9 -> 5.4 ms per
  evaluation (6.5 ms saved, CAMB excluded); the TATT premium over
  NLA drops from ~25 ms to ~7 ms.
- **Validated in all six projects (2026-09-25).**
  `internal_accuracyboost` is in every project's high-accuracy
  settings and one-at-a-time accuracy knob scan; full suites green:
  lsst_y1 (49), roman_real (42), roman_fourier (41), des_y3 (59),
  desy1xplanck (41), roman_kl (45). Parity at the default point is
  exact (lsst_y1 chi2 0.267263), and the convergence scan stayed
  bit-identical through every review refactor.
- **Deferred decisions, deliberately.** `perf stat -r 3` on the
  Linux roman benchmark (the citable numbers) and the
  DEBUG/AGGRESSIVE build-mode sweep are maintainer steps.

## Shared test harness (2026-09)

- **cocoa_testing.py.** About ten thousand duplicated lines of unit
  test python across five projects consolidated into
  `external_modules/code/cosmolike_core/cocoa_testing.py`
  (`CocoaTestHarness`: frozen-state integrity, chi2 pipeline, baryon
  checks, worker isolation, race checks, CFASTPT vs FASTPT
  comparison). The projects became data-only shims binding one
  harness instance; the full suites reproduced their digits exactly
  before and after. Shipped in cosmolike_core v4.11.6.

## CFASTPT vs FASTPT: 3x2pt, 2x2pt, and scale-cut masks (2026-09-23)

- **Comparison extended to every probe.** All six projects gained
  the 3x2pt (desy1xplanck: 6x2pt) and 2x2pt sweeps next to the
  cosmic-shear one, passing the 0.2 rule at their contracts; each
  `tests/README.md` carries the dated measurements. The frozen
  configurations fix the one-loop bias amplitudes at zero, so the
  sweeps score the IA tables; lsst_y1's exploratory b2-activated
  variant measured the bias tables separately (max 0.044,
  density-independent floor 0.013).
- **--mask option.** The sweeps rerun under a chosen scale-cut mask
  (frozen contract, lsst_y1's M2-M6, or the all-ones no-cuts mask)
  via frozen TATT dataset variants; under a non-frozen mask the
  chi2 baseline is regenerated from the cfastpt fiducial (zero by
  construction). conftest.py content was deduplicated into
  cocoa_testing.py (the file stays per project for pytest
  discovery; a shim binds the shared hooks).
- **Findings.** The ones-mask growth at default camb/cosmolike
  settings collapses under the pushed settings (cosmolike
  integration accuracy, not the FAST-PT grids); three shipped
  covariances (desy1xplanck 6x2pt, roman_real 3x2pt, roman_fourier
  3x2pt) are not positive definite when fully unmasked; roman_kl's
  frozen 3x2pt mask is already the all-ones mask.
- **Stray-file repairs.** roman_fourier's ones.mask was a
  wrong-length lsst_y1 byte-copy, replaced by the correct
  1,485-row mask (one guarded frozen replacement); roman_fourier's
  and roman_kl's real-space calculate_mask.py strays were replaced
  by Fourier generators that reproduce every shipped mask
  byte-identically.

## Nonlinear P(k): Halofit vs EE2, and the EE2 modifications (2026-09-23)

- **Halofit vs EE2 (advisory checks NL1/NL2, all six projects).**
  Ten shared seeded cosmologies in omegam/ns/As, the EE2 vector as
  each cosmology's fiducial, the difference weighted under the
  --mask scale cuts, reported through the per-project corner
  figures. The two sources are not interchangeable at survey
  precision under the frozen cuts anywhere (medians from 1.4 at
  DES-Y3 shear to 912 at roman_kl 3x2pt, always worst at high
  omegam).
- **Cocoa's EE2 vs the original EE2.** The original (commit
  ff59f66) cannot run inside Cocoa as-is: no get_boost2, and a
  silent overflow beyond 101 redshifts (the likelihoods send ~110)
  - two of the defects the Cocoa modifications fixed. Bridged with
  a compatibility patch (a get_boost2 adapter plus 100-redshift
  chunking), the side-by-side ten-cosmology comparison passes on
  all six projects (max delta chi2 4.3e-4, at roman_fourier).
  Shipped as lsst_y1's test 18, which compiles the original at
  test time (offline, --ignore-installed) and gates at 0.2; the
  modifications, their measured 14x speed-up, and the validation
  table are documented in the euclidemu2 repository README.
- **EE2 OpenMP race tests.** Every project ships a race check with
  the nonlinear P(k) from EE2 (ten_in_a_row_chi2's ee2 flag), all
  passing with exact eight-decimal agreement.

## Installation scripts (2026-09)

- **SWITCH_TO_DEV_MODE for setup_pyfastpt.sh.** The wrapper clone now
  routes through the per-script `devurl()` helper like every other
  CosmoLike-org repository; `set_installation_options.sh` keeps the
  https address.
- **Tag checkout refname fix.** The wrapper's tag checkout uses the
  `-b "${TAG}TMP"` form the other setup scripts use, removing the
  ambiguous-refname failure when a branch and a tag share a name.

## Release train (2026-09-23)

- **Nine repositories released** and pinned in
  `set_installation_options.sh`: cocoa v4.11.7, cosmolike_core
  v4.11.6, lsst_y1 v4.11.2, roman_real v4.11.2, desy1xplanck v4.11.1,
  des_y3 v4.11.1, roman_fourier v4.11.1, roman_kl v4.11.4, PyFAST-PT
  v1.01, BFMT v1.01. Every pin verified against an existing remote
  tag; every repository cycled onto a fresh `bugfix` from its updated
  `main`.

## New projects and the tests/ folder (2026-09-24)

- **Rename script teaches tests/.**
  `projects/copy_and_rename_project.sh` now renames the project
  inside `tests/*.py` and `tests/README.md` with the same sed
  families it applies to the other folders, and deletes the
  untransferable donor pins — `tests/frozen`,
  `tests/manifest_sha256.json`, the measured figures, and
  `tests/__pycache__` — with a comment pointing at
  `tests/generate_frozen_reference.py --overwrite` for regeneration.
  Validated on a copy of `lsst_y1/tests`: zero old-name references
  remain and every renamed test file compiles.
- **FAQ documents tests/.** `projects/README.md`: the folder-structure
  tree and a NOTE now describe the suite and its frozen pins; the
  easy way carries a NOTE on what the script does to `tests/` plus
  the regeneration command; the hard way gained a "Changes in the
  `tests` folder" section (rename seds, pin deletions, regeneration,
  and a tests-scoped leftover-name grep). Pruning survey-specific
  entries (for example the `M2`-`M6` scale-cut datasets in
  `tests/cocoa_test_utils.py`) and re-measuring the README's tables
  and figures stay documented manual steps.
- **The one script runs on Linux and macOS.** The bash-4
  `${var,,}`/`${var^^}` expansions became tr-precomputed case
  variants (bash 3.2, the macOS /bin/bash, suffices), the linux-only
  `rename` tool became `find -depth -print0` + `mv` with bash pattern
  substitution, and a guard aborts with a message when GNU sed (from
  the cocoa environment) is missing, before anything is copied or
  deleted. Validated by a full end-to-end run on macOS 13 /
  bash 3.2.57: the FAQ final-check greps return nothing, every
  renamed python file compiles, and the renamed `tests/` is
  byte-identical to the precomputed-expansion reference; the FAQ's
  hard-way data-file rename command was made portable the same way.
- **Exhaustive leftover scan (2026-09-24).** Scanning EVERY file of a
  freshly created project (all extensions, contents and filenames,
  case-insensitive) caught three survivors the code-extension greps
  missed: the `EXAMPLE_MCMC*.covmat` header line names the sampled
  parameters with the old survey prefix (a silent proposal-matrix
  mismatch), `.gitattributes` kept the LFS pattern of the old
  covariance name (the renamed large file would escape LFS), and the
  top-level `README.md` is donor documentation that renaming would
  only falsify. The script now seds the covmat headers (bodies
  verified byte-identical) and `.gitattributes`, and replaces the
  README with a stub; the FAQ hard way gained the matching step and
  its final check became the exhaustive pair `grep -rli lsst` +
  `find -iname "*lsst*"`, both returning nothing on the validated
  macOS run.
- **Compile-and-run validation (2026-09-24).** A created project was
  taken through the full easy-way cycle on macOS: re-sourcing
  `start_cocoa.sh` auto-created its data and cobaya-likelihood
  symlinks, `compile_xxx.sh` built `cosmolike_xxx_interface.so`, and
  `EXAMPLE_EVALUATE1.yaml` (cosmic shear) and `EXAMPLE_EVALUATE2.yaml`
  (3x2pt) both ran, with the full evaluate output identical to the
  lsst_y1 donor's after name normalization (chi2 0.267263 and
  0.443061, log-posteriors -1076.03 and -1064.55). A failed `cd` in
  the rename loops now aborts instead of letting `find` rename the
  wrong folder.
- **Easy and hard way re-synced (2026-09-24).** Auditing the FAQ hard
  way against the script found drift in both directions: the script
  kept `scripts/EXAMPLE_PLOT_*.py` and `scripts/*.sbatch` (they plot
  emulator chains; now deleted), and the hard-way Final cleanup
  lacked the chains junk and `interface/*.{so,o}` removals (now
  listed). After the sync a script-created project's `scripts/`
  carries exactly the three lifecycle scripts, and both exhaustive
  final checks stay empty.
- **Project symlinks ignored everywhere.** `start_all_projects.sh`
  deleted `cobaya/cobaya/likelihoods/.gitignore` but never recreated
  it (the generated project list was copied only to
  `external_modules/{data,code}`), so every project's likelihood
  symlink sat untracked in the cobaya repository. The copy now
  reaches `cobaya/cobaya/likelihoods/` too, the generated file
  ignores itself (the cobaya repository has no other rule for it),
  and `stop_all_projects.sh` removes it symmetrically. Verified: no
  project link and no generated `.gitignore` shows in any repo's
  `git status`, for existing projects and a new one alike.
