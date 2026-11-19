# Refreeze and notebook queue status

The refreeze uses six OpenMP workers and one BLAS worker. Only one numerical
job runs at a time, under `heavy.lock`. The current owner of A/C execution is
the notebook/refreeze agent. No push is requested.

## Completed

- LSST Y1 refreeze: commit `57b50d5`; 114 tests passed in the full run and
  its single offline-build failure passed after restoring the Cocoa build
  environment. The original failed log/XML remains preserved. Notebook
  outputs are still pending.
- Shared Fisher tolerance guard: core commit `87195ee`.
- DES Y3 cumulative reference update: commit `f429b69`; 108 tests passed.
  The project record `tests/refreeze_record_20261119.json` preserves the
  historical comparison and its remaining attribution limit.
  Follow-up commit `df047e8` adds the controlled Halofit/growth comparison.
- DES Y1 × Planck reference update: commit `ec63a45`; 91 tests passed.
  Seven endpoint comparisons cover all six observable blocks and restore
  the original vector exactly. The project also carries its durable
  `tests/refreeze_record_20261119.json`.
- DES cluster reference update: commit `eb6fc9d`; 73 tests passed.
  Nine endpoint comparisons passed. The shipped 2,812-row cluster vector
  is byte-identical to its saved original; the two regenerated galaxy-only
  vectors have their cumulative differences recorded separately.
  Follow-up commit `d6f9353` adds the controlled Halofit/growth comparison.
- Roman Fourier reference update: commit `42428b3`; 88 tests passed and
  one real-space-only stencil test was intentionally skipped. Seven
  endpoint comparisons passed. The untracked notebook remains excluded.
- Roman KL reference update: `14281fd`, with reproduction record `d1730d3`.
  The original 91-pass/1-fail/1-skip run is preserved; its corrected
  comparison passes, yielding 92 applicable passes and one intentional skip.
- Roman real reference update: `064cb94`; 127 tests passed and 24 slow
  halo-model cases were intentionally skipped. Seven endpoint comparisons
  passed with bitwise restoration; `halo_reference.json` is unchanged.
- Matched galaxy-shear caps in shared SVD comparison: core `2bc4500`;
  six targeted tests passed across KL, LSST and Roman Fourier. Project
  supplements `f682191` (LSST) and `eb51b99` (Roman Fourier) retain evidence.
- DESI ModelFisher guard and real-space cache policy: project commit
  `8b6ee16bad079d3bb57b75918d064c252fb0d967`, separate from its refreeze.
  Both Fourier and legacy real-space native checks passed in
  `notebooks/native_smoke/attempt_20261119_001429/`.

## In progress

Seven A projects are complete. DESI A is deferred until tonight at the
user's explicit request. Its quick suite stopped safely at 07:21:47 EST:
eight completed cases passed and four completed archive checks had the
permitted threshold failures. All 200 high-accuracy and 200 default vectors
were completed; all 91 frozen manifest files remain intact. The remaining
98 quick cases and final A commit are pending. The exact resume boundary is
[recorded here](projects/lssty1xdesi/RESUME.md). No restart was scheduled.

The analytic bridge checks passed five cases in each of strict and
UBSan modes and released the slot. The bounded CAMB study also finished:
all twelve private patched controls match installed model-vector files byte
for byte.
Stock tolerance with the appropriate growth convention recovers the tested
DES/cluster shear values exactly. DES Y3 retains a Limber galaxy-shear
residual, and galaxy-clustering residuals remain. No installed runtime or
physical/reference input changed in those diagnostics.

DES Y1 × Planck queue session `71874` completed at 01:37:57 EST. The
configuration driver explicitly disables the later `fixed_params` defaults
while retaining the old resolved physical parameters and priors. The first
audit failure and its log remain in `attempt_history/`. Its cumulative
September-reference drift is recorded separately from the exact 4→4
endpoint comparison.

DES Y3 queue session `72439` completed at 00:50:52 EST on 19 November 2026:
108 quick tests passed, as did configuration expansion, thirteen endpoint
comparisons, reference generation and constant measurements. The changes are
committed with the old-reference Limber/shear drift recorded separately
from the unchanged DES endpoint.

Project commit `9cdf0ae` changed growth sampling from 0.0005/Mpc to 0.05/Mpc
on October 3, after the September 30 freeze; its message explicitly retained
the older reference values. A same-binary, statically defined subclass check
ran in `scripts/check_des_growth_drift.py` for all four NLA/TATT synthetic
vectors. Explicit 0.05/Mpc reproduces every regenerated column exactly;
returning to 0.0005/Mpc alone does not recover the September vectors. The
later private Halofit control recovers the shear values when both historical
settings are restored. The remaining Limber galaxy-shear and clustering
residuals retain their attribution limits. Production growth remains
0.05/Mpc and its Halofit tolerance remains 1e-7.
The full column comparisons are in
`projects/des_y3/serialized_vector_changes.json`; LSST's analogous file
finds only 59 FLAMINGO shear entries changed, at most 1e-14, relative to the
already partly refrozen snapshot saved at this queue's start.

The two newly explicit low-rank fields were verified against committed
likelihood defaults: flag 0 and rank 5. Flag zero leaves SVD inactive. Only
missing-to-identical-default additions were accepted. Frozen physical
parameters, priors and evaluation points remain unchanged.

Retries preserve old logs/XML in `attempt_history/`; each new queue record
also hashes its log. Saved null build-environment entries are unset before
workers start. `scripts/summarize_project.py` collects each completed project's
configuration audit, block comparisons, constants, original full-run counts,
any separate retry evidence and before/after reference records.

## Next numerical jobs

The DESI CAMB background diagnostic is also deferred until tonight.
The numerical slot was released directly to the reactivated bridge agent
for its reserved adapter/allocator/bridge checks. All owned DESI processes
have stopped and `heavy.lock` was removed normally. When the bridge agent
releases the slot explicitly, begin C notebooks despite the authorized
DESI deferral; those eleven notebooks do not include DESI.

The supplied-baseline validation, full-vector study and actual CAMB/provider
check have released the numerical slot. The completed private diagnostics remain recorded. Continue C after the
reserved bridge interval; finish the deferred DESI A checks tonight.

The C outputs use the current wrapper boost convention; some Fisher wrappers
square the requested boost. The native checks measured requested boost 2 as
core boost 4, with production tolerance bases divided by seven. Follow-up D
owns any change to that convention and the subsequent reruns. LSST EV1's
unsupported claim that DerivativeKit makes boost 3 the safest choice was
removed before execution; its prose now requires step-size and parameter
checks as well as a FoM plateau.
