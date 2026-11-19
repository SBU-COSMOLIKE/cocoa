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

## Required theory bispectrum — 19 November 2026

The user specified that the theory block always supplies the full matter
bispectrum. Core commit `016adc0` therefore removes the internal C BiHalofit
fit, its coefficient structure, fitted variance splines and per-LOS fit
storage. The C reader accepts a required absolute B table. It retains the
linear-power/F2 tree diagnostic, the 19 TATT components, radial kernels,
projection and covariance calculations. Covariance halo integrals are
separate physical terms; removing the BiHalofit decomposition does not
remove those integrals.

The bridge no longer creates mean-model variance snapshots implicitly.
Its standalone fit and fraction overrides are removed. Shared
`variance_snapshot` and sampling controls remain available to the Python
theory producer and halo covariance. B and its provider Omega_m(z) now
arrive together. Missing, cleared or stale B is refused before model reuse;
a changed cosmology/power or legacy cosmological scalar requires resupply.
Identical resends and previously returned immutable owners retain their
existing behavior. A pressureless fraction may be derived from the
provider's H(z), but exact massive-neutrino fractions must reflect the
provider's actual density evolution.

Project callers now select the Python producer by default. The explicit
`internal` selector is refused. The ordinary constructor spelling retains
legacy scalar/variance keywords for migration, but they cannot activate
any C fit. Production uses the explicit supplied-bispectrum constructor.
CLI configurations with a physical-table file resolve the default B
endpoint from that loaded background. Timing scripts prepare a new theory
B for every changed physical point; the next timing study must include
that work. No timing claim is made here.

The default axes match the existing supplied example: 49, 193, 97 and 33
nodes in z, log k, log u and v, respectively, with dense boost one. This is
30,271,857 doubles, about 242 MB per array. These are starting settings,
not a forecast-convergence result. Global/bispectrum refinement multiplies
all four axis counts, and its memory cost must be considered explicitly.
Small regression fixtures use declared smaller grids instead.

### Independent equation and projection checks

Before removing the live equation comparison, a private oracle was built
from core `ef64fb1`. `capture_retired_bihalofit.py` records six ordinary
sampling cases, two shared-variance cases, two squeezed cases and a
piecewise-background case. The committed project fixture records the core
commit, binary hash, input hashes and all four matter components. The
Python equation tests retain their original numerical tolerances against
those saved results. The older fastnc fixtures remain independent checks.
The four-row joint-mean test retains its original frozen full covariance,
including the cross block, and its 5e-5 fine-grid delta-chi-squared limit.

Native projection tests consume explicit theory B tables. Their one-/three-
halo diagnostic calls were migrated to the Python equation rather than
redefined as arbitrary pieces of the supplied full B. The projected-grid
refinement test now uses 33/65 rather than 17/33 coarse nodes to resolve
the additional table interpolation; its error limits are unchanged. The
background-Jacobian test uses the Python physical B with shared variance,
rather than a constant B that would change the radial weighting and give
a different endpoint-accuracy experiment.

Validation records are `required_b_final.json`, `required_b_remaining.json`
and the before/after supplied-B snapshots. Both complete suites passed: 900 optimized tests and 900 UBSan tests.
The optimized suite took 209.87 seconds; UBSan took 325.51 seconds.
The supplied-B comparison preserved all 60 arrays bitwise, including
NLA/TATT projections and all six supported covariance families. All 30
one-versus-six-worker pairs were also bitwise identical. Builds and numerical jobs
are serial, with at most six OpenMP workers and all BLAS libraries limited
to one. The installed 3PCF extension was not replaced. Notebook files and survey
refreeze jobs remain paused; only their small wrapper unit tests ran. The pre-existing project Makefile
changes remain unstaged.


Implementation commits are core `016adc0`, adapter-comment follow-up
`d9dbf7e`, and project `131ff00`. The final supplied-B comparison is
recorded in `required_b_bitwise.json`. The current sources require a normal
project rebuild to install the new native missing/stale-input guards.
README rendering and Python parsing checks also passed. The optional
oracle-regeneration helpers were adapted to load the historical producer
under its own module name; that adaptation was syntax-checked, not rerun.
