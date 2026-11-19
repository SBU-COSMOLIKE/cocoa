# Source review for the follow-ups after notebook execution

This record was prepared on 19 November 2026 while the first LSST Y1
notebook was running. It records source findings and the checks needed in
follow-up D. It changes no notebook, installed module, compiled library or
scientific input. The C execution records retain their original settings;
corrected D outputs must identify their new settings separately.

## AccuracyBoost reaches the core through two arguments

The general wrapper takes an overall `AccuracyBoost` and a separate
`CLAccuracyBoost`. Its `_set_state` multiplies them before calling the core.
This permits a global refinement together with a refinement of CosmoLike
alone. A Fisher caller that passes the same number in both arguments
therefore squares it. For example, requesting 3 sends 9 to the core, whereas
the already corrected Roman Fourier route sends 3.

An AST inspection of the current wrapper call sites gives:

| Project and Fisher vector | Overall argument | CosmoLike argument | Effective factor |
| --- | --- | --- | --- |
| LSST Y1 `get_dv` | requested value | requested value | requested value squared |
| Roman real `get_dv`, `get_dv_w0wa`, `get_dv_3x2pt` | requested value | requested value | requested value squared |
| DES Y3 `get_dv`, `get_dv_3x2pt` | requested value | requested value | requested value squared |
| DES Y1 x Planck `get_dv` | requested value | requested value | requested value squared |
| Roman Fourier `get_dv` | requested value | 1 | requested value |
| Roman KL `get_dv` | requested value | 1 | requested value |
| DES cluster `get_fisher_datavector` | forwarded to `get_datavector` | configured default through the general preparation route | inspect the resolved configuration |

The LSST notebook also defines its own 3x2pt Fisher vector. Inspect every
notebook-local vector before making the change; the table above covers the
module call sites, not arbitrary functions defined in notebook cells.

For D, retain the multiplication in the general wrapper and make each
ordinary Fisher caller supply a CosmoLike-only factor of one. This preserves
the purpose of the two independent public controls. Before accepting it,
check the requested factor against the native table sizes, integration
setting and early-exit getter at factors 1, 2 and 3. Check 1 -> 2 -> 1 within
one process. A factor-one vector must remain unchanged. An old request of
sqrt(2) is not a complete substitute for a corrected request of 2: the
overall argument also changes CAMB and other settings.

The numerical work must separately compare old and new calls with *all*
effective settings matched, then recompute the displayed accuracy scans
under the new convention. Record the CAMB factor, CosmoLike factor,
integration setting, ell limit, radial boost, non-Limber caps and tolerance
bases. A plateau against an incorrectly labelled axis is not an accuracy
measurement at the label's advertised factor.

## Derivkit samples a zero fiducial on a very different scale

The installed `derivkit/adaptive_fit.py` uses a line for a first derivative.
At a zero fiducial its default positive offsets are
`1e-6 * 1.5**i`, for i from 0 to 9: the largest is approximately
3.8443e-5. Including the center and the negative partners gives 21 points.
For an ordinary nonzero fiducial it instead starts at one percent and caps
the offsets at five percent of the fiducial magnitude. The public
`compute` method does not forward an explicit offset scale.

Consequently a wa fiducial of zero is differentiated on offsets hundreds
to thousands of times smaller than the notebook's five-point rule with
absolute steps of 0.02 or 0.03. This difference is a hypothesis to test for
the reported discrepancy. It does not by itself establish which result is
accurate. Both smooth truncation error and small-scale numerical variation
can affect the comparison.

The package accepts a fit according to residuals in the *data-vector
values*: `abs(y_fit-y)/max(abs(y),1e-8)`, with a default tolerance of 0.05.
It does not check a five-percent error in the derivative. A line with an
incorrect small slope can fit a large nearly constant signal to that
tolerance. The current shared wrapper's description that noise averages
away therefore needs a qualification; correlated or deterministic errors
are not guaranteed to decrease.

The weights supplied to `numpy.polyfit` are
`1/(abs(x-x0)+epsilon)`, where epsilon is the larger of 0.001 times the
sample span and 1e-9. NumPy squares these weights in the least-squares
objective. For symmetric points and a first-degree polynomial, the fitted
slope is a weighted average of pairwise centered slopes with weights
proportional to `delta**2/(delta+epsilon)**2`. It is not exactly their
unweighted mean. The central point fixes the intercept strongly; symmetry
decouples that intercept from the slope. Pruning can change the set of
points for each data-vector component, so inspect the returned diagnostics.

The D calculation should proceed as follows:

1. Preserve the current DES Y3 parameter ordering, source inputs, mask,
   covariance, priors and zero non-Limber derivative tolerances. Verify the
   wa direction varies `w0pwa = w0 + wa` while holding w0 fixed. Check the
   same mapping in the other project wrappers.
2. Compute only the wa column first. Save every evaluated parameter and
   vector. Compare five-point steps 0.01, 0.02, 0.03 and 0.06, then refine
   only where these fail to agree. Repeat at selected higher effective
   accuracy, with the corrected boost convention explicitly recorded.
3. Capture the actual derivkit sampling points, component-wise fit status
   and derivatives. Compare the default near-zero offsets with explicitly
   controlled offsets on the stable five-point scale. A declared subclass
   or an explicit coordinate transformation can supply this comparison;
   replacing methods at runtime is prohibited. Any transformed coordinate
   requires the chain-rule factor in the returned derivative.
4. Compare derivatives using the same data covariance and also inspect
   their effect in the weakly constrained dark-energy directions. A small
   relative column norm does not bound a change in a nearly degenerate
   marginalized FoM. Replace one column at a time only in a saved common
   derivative matrix; never reconstruct columns from a Fisher matrix.
5. Retain the limited meaning of the fourth-difference noise estimate:
   smooth curvature and correlated numerical errors can evade its noise
   model. Agreement between that estimate and a step-size plateau is
   evidence to report, not a proof over the entire prior.

Do not rescale wa or choose a larger step merely to reproduce the old FoM.
The accepted step must be supported by convergence of the calculated
response and the marginalized forecast. If the two methods disagree after
controlled refinement, retain both results and the unresolved discrepancy.

## Derivkit changes plotting defaults during import

The installed package's `__init__.py` imports `plotutils.plot_kit`, which
calls `apply_plot_style()` at module level. That function changes
Matplotlib's `rcParams`. The lazy import inside the shared `get_ddv_dkit`
therefore changes the notebook's later plots on its first use.

The D repair should contain both the first import and the derivative
calculation within a Matplotlib `rc_context`. Validate in a fresh process,
since a repeated import alone cannot exercise the original side effect.
Compare all relevant style settings before and after normal completion and
after a deliberately raised data-vector exception. Confirm that derivative
arrays are unchanged. No installed third-party package needs modification.
Some notebooks already wrap their derivkit calls; the shared helper still
needs to honor the caller's style when used directly.

## Cumulative response plots use an internal finite k range

The `RF_C_ss_tomo_limber_work` and `RF_xi_tomo_limber_work` implementations
in `cosmo2D_scuts.c` normalize their integrals over
`Ntable.dCX_dlnk_k[RANGE_MIN:RANGE_MAX]`. The initialized values are
1e-5 and 1e2 h/Mpc. This range is distinct from the array of cutoff values
passed by a notebook for plotting.

LSST EV1 sections 16 and 17 currently write infinite integration bounds.
Those bounds can describe the mathematical idealization, or a formal
zero-extension of the computed table, but they should not suggest that the
code measures all physical tails. Explain the finite range explicitly.
Reaching one at its upper boundary follows from normalization and does not
show that increasing the boundary is unnecessary.

The numerator integrates the *absolute* response. It therefore measures the
fraction of that absolute integral below a cutoff. Real-space projection
kernels have oscillating signs: different wavenumber ranges can add or
subtract from xi. The absolute cumulative fraction neither reconstructs a
signed fractional signal nor measures a fraction of Fisher information.
The latter additionally depends on parameter derivatives, covariance and
marginalization. A shape plot divided by its peak removes still another
piece of information, its amplitude, and needs that explanation as well.

The harmonic worker explicitly handles a zero denominator; the xi worker
currently divides by it directly. Do not promise identical behavior for
zero-response rows. This source observation does not establish a failure
for the nonzero rows plotted in the current notebook.

## Preserve the remaining D and E order

After C, also repair the adjacent seagreen/firebrick Fisher colors and the
figure labels listed in `LSST_EV1_FIGURE_FOLLOWUP.md`. The separate cluster
early exit is hard-coded to 0.002 in `cluster_nonlimber_overwrite`; the
galaxy tolerance setter cannot disable it. Its future control must check
cache invalidation, reset and restoration, including an exception, and
must preserve existing production defaults. Cluster counts themselves do
not acquire a non-Limber projection from this change.

Roman real's slow halo reference requires a separate accuracy and lineage
decision. Do not update it simply to eliminate a test failure. The DESI
one-loop RSD follow-up and the remaining DESI refreeze are separate tasks;
the latter is deferred until tonight at the user's request.

Only after D and its affected notebook reruns should E rebuild DES 3PCF,
repeat the CLI timing with actual changed parameter points and CAMB
excluded, and rerun the DES 3PCF notebooks. A quiet-machine check is needed
for a new timing claim. Six OpenMP workers remain the current upper limit;
BLAS stays at one.

## Details to retain for the later cluster and DESI checks

The cluster engine already accepts a tolerance argument, and its stopping
condition explicitly requires `tol > 0`. Passing zero therefore keeps every
multipole below the cap. The missing piece is the public setting and the
cache connection: `cluster_nonlimber_overwrite` currently supplies 0.002,
while the real-space `w_cc_tomo` and `w_cg_tomo` blocks reuse values according
to their explicit key arrays. A setter that changes only a scalar without
adding that scalar's effective value to those keys can silently reuse the
old vector. Include the tolerance in those real-space refill keys; do not
invalidate unrelated cluster counts or Limber tables merely to make a test
pass. The existing `double_bits_key` gives this file a house mechanism for
keying a double. Reset must restore the default too.

Roman real's last halo reference update is project commit `8451623`, dated
6 October. Its record says the update followed independent FFTLog checks
and moved probes by at most 6.8e-10. That is historical evidence, not the
size or cause of today's reported slow-tier drift. The current quick suite
skipped the slow `p_gm` and `p_gg` comparisons. The JSON reference records
the HOD, example and TATT choice, but does not pin an old native binary or
CAMB build. D must first measure the present discrepancy, retain the
original reference, check the independent large-scale limits and refine
the relevant tables before deciding whether to update the reference.
Describe frozen values as a regression reference, not physical ground truth.

The DESI study `tests/studies/test_nonlinear_kaiser.py` already implements
flag toggles, a fresh-process comparison, A_s-squared scaling and an E3
comparison. Two test-design issues must be handled before interpreting a
new run:

- `test_default_off` currently identifies the default-off behavior through
  chi-squared below 1e-6 against the live example's data. The preserved
  legacy data and current model need not coincide. The flag's default
  behavior should instead be checked against an explicitly selected zero
  flag at identical model settings. Keep the observed chi-squared as a
  separate reference-data diagnostic; do not loosen its threshold to hide
  a changed reference.
- `test_e3_record` skips unmatched spectrum keys and requires only that at
  least one spectrum was compared. The installed Delta-z=0.2 record has
  23 spectra and 667 retained bands. A complete comparison must account for
  every expected key and retained band, verify the band ordering and
  relevant physical inputs, and reject missing or nonfinite entries.

The external E3 record's `swap` is A minus B: the exact loop contribution
minus the older Limber halofit contribution to the velocity sector. The
production flag preserves that halofit hand-off and adds A minus Lloop,
where Lloop is the Limber projection of the loop terms themselves. The
existing six-percent comparison allowance includes this different physical
construction; passing it is not a six-percent integration-accuracy test.
The core skill records a separate matched-convention comparison with much
smaller residuals. Preserve that distinction, including the different
growth inputs, when running the new consistency check. Do not change the
production high-ell convention to force agreement with the older `swap`.

These are read-only findings. No DESI test was launched and no DESI file
was edited for this review; its deferred refreeze remains paused.
