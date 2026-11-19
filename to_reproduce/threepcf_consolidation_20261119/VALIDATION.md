# Three-point consolidation: numerical acceptance

The interpolation consolidation passes the full NLA and TATT comparisons.
Adoption of shared smoothing variances has not passed. These are distinct
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
