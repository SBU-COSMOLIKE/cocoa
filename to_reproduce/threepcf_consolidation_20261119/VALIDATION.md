# Three-point consolidation: numerical acceptance

The interpolation consolidation passes the full NLA and TATT comparisons.
Shared smoothing passes the NLA comparison and sampling refinement with
the higher-accuracy inputs described below; TATT checks are in progress.
These are distinct
changes: replacing interpolation machinery can preserve a physical model,
whereas removing the old power normalization also changes which spectrum
the three-point model uses.

## Interpolation

The comparison retains 400 two-point rows, 80 aperture rows and the complete
joint covariance. It evaluates 17 parameters for NLA and 20 for TATT, with
fourth-order finite differences at two step sizes. Every two-point row at
every evaluated parameter point remains bitwise unchanged. Input hashes
are recorded separately from output hashes in `provenance/`.

| Comparison | Mean delta chi-squared | Largest derivative change | Largest pair-FoM change |
| --- | ---: | ---: | ---: |
| NLA interpolation | 8.53e-9 | 0.000989% | 0.00625% |
| TATT interpolation | 8.53e-9 | 0.000997% | 0.0148% |

The last two columns take the maximum over both derivative spacings.
The complete per-parameter and per-pair results are in
`nla_forecast_comparison.json` and `tatt_forecast_comparison.json`.

## Shared smoothing

Shared smoothing supplies the Gaussian nonlinear radius, effective
spectral index and top-hat amplitude from the existing CosmoLike tables.
The adapter can also supply mass variances for the analytic covariance.
Copied results retain their values after another model changes global
core state. The local calculation remains the default.

The adopted acceptance criteria are a mean delta chi-squared at most
0.01, each covariance-weighted derivative change at most 0.1%, and every
marginalized-error and pair-FoM change at most 0.5%. Both derivative
spacings and further numerical refinement must pass. A small difference
in the mean does not establish stable parameter constraints: nearly
parallel derivative columns can make the Fisher inverse sensitive to
much smaller numerical differences.

| Shared sampling versus local reference | Mean delta chi-squared | Largest derivative change | Largest pair-FoM change |
| --- | ---: | ---: | ---: |
| Baseline counts | 2.41e-4 | 0.270% | 4.78% |
| Twice the baseline intervals | 2.16e-4 | 0.282% | 5.28% |

All two-point rows remain bitwise unchanged. Doubling shared sampling
changes a pair FoM by up to 0.595%, so shared refinement itself also needs
further checking. Failed comparisons are retained in the `nla_shared*`
JSON files; they are not new frozen references.

The old model renormalizes the input linear spectrum to a separate scalar
sigma8. Its fiducial multiplier is approximately 0.999686. Shared smoothing
preserves the supplied power amplitude. A separate diagnostic tightens
the old Gaussian-radius solve and quadrature while retaining this old
normalization. Replaying archived CAMB arrays isolates these differences
without repeating the Boltzmann calculation. Exact replay is checked
before drawing conclusions from that diagnostic.

The frozen-input replay reproduced every saved array exactly, including
all 103 complete joint vectors and both Fisher matrices. The refined local
reference uses 8000 variance nodes, 16000 slope nodes and a relative radius
stopping tolerance of 1e-10. Relative to the old settings, its mean changes
by only 6.64e-9 in delta chi-squared, but a pair FoM changes by up to 2.21%.
Shared sampling at twice baseline still differs from this refined local
reference by up to 5.04% in a pair FoM. The local calculation is sensitive
to numerical refinement, but this refinement does not resolve the failed
acceptance comparison.

The unchanged two-point h derivative changes by 1.60% when the finite-
difference step halves, measured with the two-point covariance block.
The corresponding aperture h derivative changes by 0.587% for the refined
local calculation and 2.54% for shared sampling at twice baseline. These
blockwise norms diagnose step sensitivity; they do not replace the full
joint covariance in the acceptance calculation. The complete column
values are in `derivative_step_diagnosis.json`.

## Identifying the normalization effect

Cold cubic upsampling of the power and growth inputs changes shared results
by less than 0.045% in any pair FoM. It does not resolve the discrepancy.
Applying the old normalization explicitly to shared smoothing, as a
diagnostic only, gives agreement with the refined local result within
0.014% per derivative and 0.172% per pair FoM. All fixed-step criteria pass
in that matched-normalization comparison. The production shared adapter
continues to preserve the input amplitude.

A second input preparation uses CAMB AccuracyBoost 2, k_per_logint 50 and
1025 uniform log-k output samples, while keeping the solved cutoff at
5/Mpc. Across its entire NLA stencil, the old normalization multiplier
ranges from 0.9999998589 to 1.0000000558. Shared smoothing at four-times
sampling, without any amplitude correction, then agrees with the refined
local calculation as follows:

| Quantity | Larger derivative step | Smaller derivative step |
| --- | ---: | ---: |
| Largest weighted derivative change | 0.00598% | 0.00797% |
| Largest marginalized-error change | 0.0523% | 0.0295% |
| Largest pair-FoM change | 0.0541% | 0.0299% |

The mean delta chi-squared is 1.55e-8, and all two-point rows are bitwise
identical. This comparison passes the original fixed-step criteria. The
older, less accurate input calculations remain recorded above; their
failure was not erased by regenerating their reference arrays.

Increasing shared sampling from four to eight times the baseline intervals
also passes. Against the same refined reference, the eight-times calculation
changes each weighted derivative by at most 0.00981%, each marginalized
error by at most 0.0649%, and each pair FoM by at most 0.0651%. The mean
delta chi-squared is 6.74e-9. Comparing four-times directly with eight-times
sampling gives maximum changes of 0.00516%, 0.0354%, and 0.0356% in those
three quantities, respectively. These maxima include both derivative steps;
all two-point stencil rows remain bitwise identical.

This agreement does not establish that every forecasted error is itself
step-converged. On these inputs the largest marginalized-error change
under step halving is about 2.8% in both calculations. The dark-energy
pair FoM changes by about 0.15--0.17%. The shared-versus-local comparison
must remain distinct from a claim of final forecast accuracy.

## Component and ordinary-interface checks

The pre-correction combined suite passed 875 strict checks; its UBSan
counterpart passed 833 project and 42 variance checks. Later FFT endpoint
checks passed 54 tests in each build, and sampling/state checks passed 63
in each build. The Python shared-variance integration passed 123 targeted
checks in each build. These stages test different revisions and must not
be added together as if they were one final regression run.

The ordinary LSST Y1 data-vector interface was built privately in strict
and UBSan modes. The public setup, cosmology setter and variance query
restore amplitude A/B/A exactly and reproduce the result after reset.
This verifies linkage and reset ownership. It does not refreeze a project
or validate a full survey prediction.

All numerical work is serial across jobs, with at most six OpenMP workers
and one BLAS worker. Installed extensions, notebooks and survey refreezes
remain untouched. Private numerical outputs reside under
`/private/tmp/threepcf_consolidation_20261119`; committed provenance keeps
the configuration, parameter points and input/output identities.

## Explicit reference inputs

Core commit `3abb5a6` preserves the selected interpolation convention when
fit arrays are supplied. Project commit `35d6aad` prepares the independent
reference arrays in Python and passes their recorded power normalization
only to the three-point model. Direct comparisons against the independent
native legacy calculation pass in both production and source-comparison
interpolation modes. The full suite passes 876 tests in strict mode and
876 under UBSan. A final metadata/documentation/validation-order follow-up
passes 22 focused UBSan tests. The first strict run's two failures were
error-message matching failures; no numerical assertions failed.

The native no-array compatibility path remains present. This is a checked
integration step, not a claim that all local C smoothing has been removed.
The user subsequently narrowed the validation queue: run the necessary
TATT shared4 comparison, omit the automatic full shared8 forecast, and
defer the broader covariance study. Notebooks and refreezes remain paused.
