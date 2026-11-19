# Supplied BiHalofit implementation record

The copied implementation handoff describes the optional route recorded
here. The separate follow-up handoff records later work; it does not
authorize a default change or a push. The current unfinished work is tracked
in the [Cocoa backlog](../../cocoa_installation_libraries/notes/backlog.md#open-threepcf-integration-followups).
The user has confirmed that this team owns current edits. Earlier unrelated
DES 3PCF Makefile edits remain outside these commits.

## Implemented changes and validation

The core accepts an optional positive absolute bispectrum on uniform
`(z, logk, logu, v)` coordinates. It shares the feedback table's cubic
preparation and arithmetic-index linear reader, while keeping the absolute
baseline distinct from the hydro/DMO response ratio. The internal fit remains
the default. The supplied route skips its fit preparation and does not read
the unused `omega_de`, `w0`, `wa` and `ns` fields. Its halo calculation reads
the explicitly supplied matter-density fraction.

The project contains the Python equation producer, a Cobaya Theory adapter,
the optional YAML selector, immutable input ownership, and model-state cache
keys. The CLI records baseline input hashes and resolved controls for mean,
covariance and Fisher outputs. Fisher captures the central model's record
before displacements. Covariance construction checks its input identities
without attempting to read the matrix it is about to create.

The example `configs/des_y3_supplied_bihalofit.yaml` writes separate physical
tables and results. Its configuration check passes and reports the expected
missing prepared physical file. Its 49/193/97/33 bispectrum counts pass the
full 480-row mean comparison at the stated fiducial NLA point; this is not
a Fisher-derivative convergence result. The installed project binary is
unchanged; native checks use isolated builds.

## Evidence already obtained

- Initial equation probes agreed with the pinned C implementation to about
  `2e-14` relative error. This compares the same background and numerical
  prescription and is separate from four-dimensional table interpolation.
- The full strict and debug/UBSan checks covered the 767-test snapshot
  with no outstanding skips. Native checks include background ownership,
  cache replacement, independent covariance scaling under an imposed
  change in the absolute bispectrum, and retained-model lifetime.
- The recovered original stage-0 battery and nonzero-feedback comparison
  retain 32 output archives across strict and UBSan builds. All 344 array
  comparisons are byte-identical to the pre-edit binary. The battery
  includes three model points, both C++ adapters, repeated calls, and
  fresh one- and four-thread processes.
- A four-row joint example retains a complete positive covariance with
  all six implemented covariance contributions. Refining its supplied
  bispectrum table gives squared covariance-weighted differences of
  0.0797234, 0.00622678 and 0.0000162025. Its two-point rows are byte-identical.
  Frozen physical inputs, data, covariance and mask accompany the
  permanent test. These small-example results do not establish
  convergence of the full 480-row example.
- Strongly squeezed nonzero-gap probes distinguish power-rounding
  cancellation from equation disagreement using an independent 80-digit
  reconstruction. The incomplete-gamma audit covers 24 shapes and 12
  lower bounds against 80-digit values, including near-zero shape and
  large-argument recurrence cancellation. The largest relative difference
  is 1.0214e-12. Final producer and frozen-input checks pass 57/57 in strict
  and UBSan builds. The ordinary-equation tolerance is unchanged.
- The full 480-row Y3 comparison uses fixed saved power, distance, growth,
  sources and the public joint covariance. Coarse-to-refined data chi-squared
  differences are -0.5713294, -0.3131430, -0.1573676 and -0.08315490.
  The refined squared covariance-weighted model difference is 0.0007998647.
  All 400 two-point rows are byte-identical; every dependency hash is
  unchanged. Replacing only the refined supplied matter fraction by the
  radiation-free prescription changes data chi-squared by -2.946074e-6.
  Thus the table error dominates that particular background effect here.
- An actual Cobaya Model with installed CAMB resolves the Theory adapter's
  requirements and passes A/A/B/A cache checks. This complements the
  controlled array-provider unit tests; it is not a posterior-reproduction
  claim.
- All eight file-provenance tests passed, including refusal after input
  changes during a covariance calculation.
- Project README and configuration README rendering and local table-of-
  contents anchors pass. The producer guide has also passed rendering,
  relative-link and control-character checks.

Native evidence is under
`/private/tmp/supplied_baseline_3pcf_20261119/`; equation evidence is under
`/private/tmp/bihalofit_python_20261119/`. Both directories retain input
hashes and source/binary identities. Durable test commands and numerical
results are included in the core and project commits identified below.

## Commits and remaining work

Core commit `1fa68b0c71b3197fdbf31bfa27962ddfe531e925` contains the native
route, documentation, skill references and durable comparison records.
That commit excludes the independently owned `cocoa_testing_suites.py`
change present during validation. Project commit `1086ce5` on `main`
contains the Python producer,
Theory adapter, CLI route, tests, configuration and documentation. Its
unrelated `interface/MakefileCosmolike` edits remain outside this commit,
as requested by the handoff. Defaults remain internal and no changes are
pushed. The installed project extension still awaits the ordered rebuild;
the recorded supplied-route checks use the pinned private strict build.

The independent background-derivative follow-up is committed in DES 3PCF
`d9f2a1e`. All five cases pass with identical strict/UBSan measurements.
The toy IA error falls from 8.638e-5 to 1.345e-6 between 41 and 321
background nodes. The observer-endpoint Jacobian remains first order;
these controlled tests do not establish a survey-level Fisher error.
Its guide and results are under `tests/studies/bridge_background_analytic`.
Core `90a1b3a` also records the NFW table and angular-spline ownership.
Both follow-ups are closed in the root backlog (`2da36a9e`).

A subsequent source-only cross-review exchanged the two implementation
owners: the Python author reviewed native `1fa68b0`, and the native author
reviewed Python `1086ce5`. Neither found a new actionable defect. The
native review covered physical routing, ownership, cache state, dimension
checks and the unchanged default. The Python review covered provider
units/backgrounds, input/control cache keys, immutable owners, YAML
selection and CLI provenance. These reviews ran no numerical jobs and
do not extend the measured validation limits above.

All substantial numerical jobs share the refreeze queue's lock. The project
refreezes and notebooks remain active; the BiHalofit checks use agreed gaps
between those jobs. The worker limit is six OpenMP threads with BLAS fixed
to one, except explicit one/four-thread determinism comparisons.
