# Three-point consolidation follow-up

The duplicate Legendre-root solver has been removed, the internal fit no longer
reconstructs a CPL expansion history, and upstream not-a-knot interpolation is
separate from production preparation. Radial reuse has been reviewed without
changing the radial algorithm. Notebooks and refreezes remain paused.

## Changes and commits

| Scope | Core commit | Project commit |
|---|---|---|
| Shared fixed Gauss-Legendre quadrature | `28505f3` | `2c9475f` |
| Expansion-derived or exact provider matter fraction | `113b091` | `78da388` |
| Separate upstream spline implementation | `dc6057c` | `09493eb` |
| Radial reuse review and documentation | `ef64fb1` | — |

For pressureless matter, Omega_m(z)=Omega_m0*(1+z)^3/E(z)^2. The direct model
uses its supplied dz/dchi in h/Mpc to obtain E=2997.92458*dz/dchi. The bridge's
Jacobian follows the same installed distance interpolation as core hoverh0.
An explicit fraction table overrides the pressureless relation. CAMB preparation
records its exact CDM+baryon+massive-neutrino fractions, and both bispectrum
routes receive that background. The internal core bridge refuses a nonzero
massive-neutrino model without an exact supplied fraction.

BiHalofit's d_n coefficient and the optional halo collapse-threshold correction
read the same copied fraction table. Lensing and IA prefactors still use
Omega_m0. Exact overrides are copied, identical resends reuse the bridge model,
and changed cosmology/power state requires resupply or clearing. Retained old
model owners survive replacements and reset. Independent fraction coordinates
are supported for direct internal-fit comparisons so the upstream fit anchors
can be retained without altering the power or background grids.

The source-comparison solver and binary interval search live in
`physics_reference_3pcf.c/.h`. Production keeps shared uniform natural-cubic
preparation and arithmetic indexing. The model continues to own its arrays.
The project Makefile links the new object; its previously held unrelated edits
remain unstaged.

## Validation

- Shared quadrature: 31 strict and 31 UBSan tests passed, including independent
  NumPy Legendre rules at 8, 33 and 128 nodes for NLA and TATT.
- Background preparation: an initial focused set passed 156 tests in each build.
  The final guard and CAMB-background follow-up passed 57 in each build. These
  are overlapping checks at successive revisions, not additive test totals.
- Final full project suite: **896 strict tests passed** and **896 UBSan tests
  passed**, with halt-on-error enabled. See `spline_split.json` for source,
  binary and log identities. No numerical tolerance was relaxed.
- Spline separation: **68 arrays were bitwise unchanged**. These cover matter
  components, all IA entries, NLA/TATT projections and multipoles, radial
  arrays, means and all six covariance families in production and comparison
  modes. All **34 one/six-worker pairs** were bitwise equal. Per-array hashes
  are in `spline_bitwise.json`.
- The one post-test C-source edit changed a comment in the reference module;
  non-comment source text was checked identical. A Python test signature was
  wrapped without changing its code. Markdown render checks passed: eight
  tables in the core README and two in project ACCURACY.md.

Numerical jobs ran sequentially with BLAS fixed to one and an OpenMP limit of
six. Installed extensions were not replaced. Tests used private libraries, so
normal project compilation is required before running the updated project code
against an installed extension.

The committed `validate.py` and `snapshot.py` record this private-harness
procedure. The build driver reuses the prior consolidation's prepared private
checkout and build recipe; it is an investigation record rather than a project
installation script.

## Radial reuse conclusion

`cosmolike/3pcf/RADIAL_REUSE.md` derives the unit conversions and identifies
finite-grid normalization, source shifts, endpoint handling and ownership
requirements. It also records the upstream speed-of-light convention:
299792 km/s versus the core's 299792.458 km/s. A direct substitution would mix
this deterministic difference with integration and interpolation differences.

The first promising shared operation is a lensing-efficiency helper over
explicit arrays, using suffix sums of weighted n and n/chi. It can retain the
current nodal trapezoid rule, but still needs cancellation, normalization,
shift, covariance and survey-weighted derivative checks. No radial replacement
or speedup is claimed by this change.

The prior variance/Fisher comparisons retain their original background
conventions. The explicit Python reference adapter still supplies those values,
so frozen variance checks remain independent. Their FoM numbers do not establish
survey convergence of the new expansion-derived background route. No new full
paired Fisher forecast or eight-times TATT forecast was run.
