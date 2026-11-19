# Sharing the NFW profile evaluator between halo.c and the 3PCF covariance

**Handoff to the implementation team — 18 November 2026.**

The investigation supports sharing one implementation of the truncated NFW
Fourier transform. The recommended change is to share its dimensionless
numerical evaluator, including its uniform table and SIMD readers. Keep mass
definitions, radii, concentration prescriptions and covariance weights in
their present callers. Do not replace the three-point helper by a direct call
to the existing mass-based `u_nfw_c` wrapper.

This is an implementation plan backed by numerical experiments, not an
implemented production change. The experiments used core commit `eb37de1`,
strict floating-point flags, at most four OpenMP threads and one BLAS thread.
Production C files, READMEs and `projects/des_3pcf` were not changed. Subsequent
bridge changes must be accounted for when the team rebases this work.

## 1. What is shared physically

An NFW halo has density proportional to
`1 / [y (1+y)^2]`, where `y = r/r_s`. Truncating it at `r200 = c r_s`
and dividing by its enclosed mass gives the dimensionless transform

\[
u(c,q)=\frac{1}{m(c)}\int_0^c
\frac{y\,dy}{(1+y)^2}\,\mathrm{sinc}\!\left(\frac{q y}{c}\right),
\qquad m(c)=\ln(1+c)-\frac{c}{1+c},\qquad q=k r_{200}.
\]

Here `sinc(t) = sin(t)/t`, so `u(c,0) = 1`: the zero-wavenumber
profile contains the full halo mass. Equivalently, the evaluator can take
`x = k r_s = q/c`. Once `c` and `x` are supplied, it needs no cosmology,
mass unit, redshift or overdensity prescription. That is the boundary at
which the implementations should be shared.

Both present callers use an M200m radius, meaning an enclosed mean density
of 200 times the cosmic mean matter density. Their differences are not an
M200m-versus-M200c choice. They use different units and slightly different
critical-density constants:

| Quantity | Ordinary halo code | Three-point covariance |
|---|---|---|
| Input to current wrapper | Mass and core-unit wavenumber | Radius and wavenumber in h/Mpc |
| Critical density in `(Msun/h)/(Mpc/h)^3` | `7.4775e21 / 2997.92458^3 = 2.77520016669e11` | `2.77536627e11` |
| Profile evaluation | Uniform table of smooth Si/Ci combinations, then linear reads | Direct GSL Si/Ci, plus small-q expansion |

At fixed mass and matter density parameter, those constants change the
radius by approximately `1.9951e-5` fractionally. A wrapper that invents a
mass to call `u_nfw_c` would mix a numerical replacement with a convention
change. Preserve the caller's existing radius instead. Changing the density
constant is a separate scientific decision and must not enter this port.

## 2. What the current code already does well

`halo.c` does not interpolate the rapidly oscillating raw Si and Ci functions.
It stores smooth combinations

\[
f(t)=\mathrm{Ci}(t)\sin t+
       [\pi/2-\mathrm{Si}(t)]\cos t,
\]
\[
g(t)=-\mathrm{Ci}(t)\cos t+
       [\pi/2-\mathrm{Si}(t)]\sin t,\qquad G(t)=g(t)+\ln t.
\]

The grid is uniform in `ln(t)` over `1e-10 <= t <= 50`. Positions are
computed arithmetically, without binary search. Above the table, short
asymptotic series supply the values. The scalar and SIMD readers use the
same mathematical organization. Preserve this design.

The default `Ntable.halo_nfw_n = 131072` takes approximately 2 MiB for the
two double-precision rows. Four times that count takes approximately 8 MiB.
This universal table depends on numerical settings, not on cosmological
parameters or halo masses.

The three-point covariance already prepares halo-profile arrays and reuses
them across filters, source combinations and covariance elements. Therefore
the opportunity is to make **profile construction** cheaper. It is not the
removal of a special-function call from every covariance matrix element.

## 3. Measurements that motivate the change

The isolated C comparison used the actual kernel bodies, linked against the
actual core allocation and state utilities. It covered 25,576 `(c,q)` pairs,
including both sides of the small-q and table/asymptotic boundaries. A
selected set of 871 points was checked with 70-digit arithmetic. Selection
included a regular subsample and the largest observed disagreements;
these measured maxima are not rigorous bounds over a continuous domain.

For `1 <= c <= 30`, the largest relative errors among the reference points
were:

| Maximum q in the sample | Direct GSL expression | Default table | Fourfold table |
|---|---:|---:|---:|
| 100 | `6.79e-14` | `2.03e-8` | `1.34e-9` |
| 10,000 | `1.24e-9` | `2.03e-8` | `1.16e-8` |
| 1,000,000 | `1.86e-4` | `6.17e-4` | `6.17e-4` |

The final row describes cancellation when the transform itself is tiny.
It is not evidence for a covariance bias of that size. It does show that
neither double-precision expression is an unlimited-accuracy oracle and
that increasing the table density cannot remove every error.

For the wider concentration sample `0.05 <= c <= 100`, the default table's
largest relative error below `q=100` was `1.14e-6`. Thus the existing comment
about a `6e-7` relative error should not be promoted to a general guarantee.
The required concentration and phase domain should come from actual
covariance inputs and allowed nuisance parameters.

Three additional checks were completed:

1. Scalar and SIMD evaluations were bitwise identical at all 25,576 points.
2. One- and four-thread evaluations, and a table resize followed by a return
   to the default resolution, were bitwise identical.
3. The existing radial-mass-integral test was reproduced using independent
   256- and 512-node Gauss-Legendre integrals. Their maximum absolute
   difference was `9.44e-15`. The direct expression passed the existing
   `rtol=3e-10, atol=2e-13` criterion. The default table failed, with maximum
   relative error `3.45e-9`; the fourfold table passed, at `1.95e-10`.

The zero-wavenumber test returned exactly one for the existing three-point
helper. The raw core table expression returned NaN there because it takes a
logarithm. That is outside the documented positive-k core wrapper domain,
but inside the public three-point profile domain. The shared API must
explicitly preserve `u(c,0)=1`.

## 4. Propagation into a small joint covariance

An isolated experimental build replaced only the non-small-q profile
expression. It retained the original small-q branch, physical prescriptions,
integration grids and contraction order. The comparison exercised Map3,
xi+, xi- and Map2, two source bins, all six covariance families, and both
the large-area and finite-window calculations.

For each covariance, define

\[
\epsilon_C=\max_{ij}\frac{|C^{\rm table}_{ij}-C^{\rm direct}_{ij}|}
 {\sqrt{C^{\rm direct}_{ii}C^{\rm direct}_{jj}}}.
\]

This measures the change in units set by each observable's variance,
without dividing by a cross-covariance that might happen to be near zero.

| Grid | Finite-window epsilon_C | Large-area epsilon_C |
|---|---:|---:|
| Default table | `9.41e-9` | `3.87e-11` |
| Fourfold table | `5.53e-10` | `2.16e-12` |

The mean vectors were bitwise unchanged. The Gaussian, BB and PB families
were bitwise unchanged; the families using halo profiles changed at the
expected small level. Refining the table need not reduce every individual
matrix-element difference monotonically because contractions can cancel.

These are small numerical checks, not DES covariance convergence tests.
They justify proceeding with a controlled replacement, but do not establish
a survey-level accuracy target, Fisher stability or a runtime improvement.

## 5. Recommended ownership and file organization

Create one small shared NFW implementation, provisionally named
`cosmolike/halo_profile.c` with `halo_profile.h`. Confirm the house naming
with the team before choosing the final names. Do not link all of `halo.c`
into the standalone three-point library merely to obtain one function.
The standalone target currently links the small core utilities but not the
entire halo-model implementation.

The shared implementation should own the table builder and all numerical
readers. Keep `u_nfw_c(c,k,m,a)` as the existing public adapter in `halo.c`:
it computes its radius with its current conventions and passes the resulting
dimensionless argument to the shared evaluator. The three-point caller
passes its already-computed `k*r200/c` and its concentration.

**Prefer a caller-owned numerical-table descriptor, with one implementation
of its operations.** The ordinary halo code and the three-point covariance
can then own separate instances when they need different resolutions. This
duplicates a few MiB of universal table data, not the numerical algorithm.
It also avoids a covariance accuracy setting resizing a table while the
ordinary halo code retains auxiliary data derived from its old size.

An initial descriptor needs only the existing state: node count, axis
endpoints and spacing, inverse spacing, and the two table rows. Preparation
and destruction take a mutable descriptor; all readers take a const
descriptor. Keep this ordinary C. No global registry, hidden thread-local
state or new cache framework is needed.

If the team chooses one process-wide instance instead, it must first prove
that every consumer, including IA, sees the same resolution and lifetime.
Do not expose independent setters that silently resize that instance.

## 6. An IA dependency that must move with the table

The table is not used only by `u_nfw_c`. The halo IA calculation reads the
same f/G arrays and constructs its own derivative rows for cubic Hermite
reads. It uses

\[
\frac{df}{d\ln t}=-t g(t),\qquad
\frac{dG}{d\ln t}=t f(t).
\]

Consequently, relocating just the scalar NFW reader leaves a second owner
or a hidden dependency behind. Inventory `nfw_`, `nfw_table`, `nfw_pos`,
`nfw_um`, their SIMD variants, `ia_fg_read`, `ia_tables` and the IA slope
storage before editing. Keep the IA interpolation order unchanged: its
cubic treatment addresses a different cancellation problem and must not
be replaced by the NFW linear reader as part of this change.

For the caller-owned design, the ordinary halo/IA routines share their
existing instance. Their IA slopes must be rebuilt after that instance's
resolution or table generation changes. The covariance instance has no
authority to resize the ordinary halo/IA instance.

## 7. Suggested API contract

The public numerical contract should be expressible in the following
operations; names below describe roles, not mandated spellings:

| Operation | Inputs and behavior |
|---|---|
| Prepare a table | Descriptor and node count; allocate/refill only when its numerical definition changes |
| Read one normalized profile | Const descriptor, positive finite concentration, nonnegative finite x; returns u with exact zero limit |
| Read several profiles | Same normalization and branches; const inputs and disjoint output rows |
| Release a table | Free owned storage, clear its metadata, make later preparation safe |
| Read f/G for existing IA consumers | A narrow internal interface preserving their present interpolation and derivative conventions |

Internally, retain a fast entry accepting precomputed `ln(x)`, `ln(1+c)`
and normalization when a caller already has them. This avoids repeating
logs for every wavenumber. The zero branch must occur before taking
`ln(x)`. Do not rely on `0 * infinity` to reconstruct the limit.

Preserve the present three-point small-q expansion initially:

\[
u=1-\frac{x^2}{6m(c)}\int_0^c\frac{y^3\,dy}{(1+y)^2}+O(q^4).
\]

Its threshold is on `q=c*x`, not on x alone. Its moment and normalization
can be prepared once per halo. Use one shared implementation of this
branch in the finished code; do not leave copies in both callers.

## 8. Cache invalidation and OpenMP rules

The current `nfw_table()` checks a pointer and `Ntable.random`, and publishes
file-scope state. Two workers must not enter its first build concurrently.
Its internal parallel fill does not make concurrent entry safe.

The implementation sequence must be:

1. On the calling thread, validate the requested table definition and
   prepare all required storage.
2. Complete the fill and publish the fully constructed descriptor.
3. Enter the halo-profile OpenMP loop. Workers only read the descriptor
   and write separate output elements.
4. Resize, reset or release only after all those workers have completed.

Compare the requested node count explicitly. Do not make the numerical
table's correctness depend solely on a global random key being changed
elsewhere. If a caller retains the house nonce for surrounding caches,
compare the relevant integer sizes as well. A cosmology or concentration
change requires new profile values but does not require rebuilding the
universal f/G table.

Notebook tests must include resolution A→B→A, cosmology A→B→A, changes of
mass/radius/concentration arrays, repeated equal requests, and a complete
reset followed by reconstruction. Test independent ordinary-halo and
covariance resolution settings in the same process. Changing one must not
leave the other's IA derivatives or profile values stale.

## 9. Accuracy control and initial default

The default core table is already accurate enough for the small covariance
comparison, but it does not satisfy the existing direct-profile test.
**Use 524288 nodes as the first conservative three-point candidate** if the
present test tolerance is retained. This is a starting point supported by
the tested concentrations and arguments, not a proof for every allowed
input.

Expose a dedicated NFW table-resolution setting. Map it clearly to the
project's accuracy controls, but keep it separate from mass, redshift,
Fourier and offset quadrature settings. Increasing integration accuracy
must not silently change the physical halo prescription. Numerical
interpolation accuracy is not the same control as integration accuracy.

Before settling on a lower default, measure the largest relevant q values
and the covariance-weighted effects over the intended Y3/Y6 configurations.
Do not loosen the radial-profile test just because a replacement failed it.
If the accuracy contract is deliberately changed, document the observable
error budget and retain a high-resolution version of the stringent test.

## 10. Separate commits and their acceptance tests

### Commit 1 — shared ownership, unchanged core arithmetic

Move the existing table and its scalar/SIMD numerical code into the shared
owner. Adapt the ordinary halo and IA consumers. Preserve operation order,
table nodes, asymptotic expressions and interpolation choices. Update every
build target that compiles a consumer, including standalone three-point,
ordinary data-vector and covariance targets.

Acceptance: ordinary halo/IA outputs match before and after bit-for-bit;
scalar/SIMD checks pass; one/four-thread outputs agree; resize/reset tests
pass; the relevant project data vectors and covariance tests pass. This
commit should not yet change the three-point profile algorithm.

### Commit 2 — dimensionless entry and three-point adoption

Introduce the exact-zero and small-q contract, then switch the three-point
profile construction to the shared table. Keep the direct formula in a
test reference only. Preserve all mass, density, concentration, abundance,
bias and projection factors in the callers.

Acceptance: the independent radial integral passes at the chosen table
resolution; values on both sides of each numerical boundary agree within
the declared tolerance; all six covariance families pass the small
large-area and finite-window comparisons; zero returns exactly one.
This commit is numerically equivalent within tolerance, not bitwise
equivalent to direct GSL.

### Commit 3 — larger physical-domain and cache checks

Exercise the actual Y3/Y6 halo mass and redshift ranges, allowed
concentration variations, Fourier nodes and low-multipole window nodes.
Include high-k/low-chi combinations. Check against higher-precision
expressions or resolved radial integration where appropriate. Record
absolute error as well as relative error when u is tiny.

Refine mass, Fourier and redshift quadrature separately from the NFW table
so cancellation or integration error cannot be mistaken for profile-table
convergence. Run the existing cache suites and the IA consumers after
changing the shared table size. Use UBSan and targeted memory checks.

### Commit 4 — SIMD batches and measured performance

Only after the previous checks pass, use the existing vector readers for
profile batches. The natural inner batch holds one halo's concentration
and radius fixed while varying k. Reuse normalization, logarithms and
radius factors outside that inner loop. Retain a scalar tail for counts
not divisible by the vector width.

Prepare first, then distribute independent profile rows with the same
OpenMP conventions as the covariance code. Do not add nested OpenMP
regions or multiple-thread BLAS/FFT work inside an already parallel loop.

On a quiet machine, measure first-use table preparation separately from a
reused-table covariance construction. For each scientific timing, vary
physical parameters or inputs enough to force real profile recomputation.
Report total covariance time as well as profile construction time. Keep
BLAS at one thread; use at most four OpenMP threads unless the user grants
a new timing exception. No speedup has been measured in this study.

## 11. High-q stability is a separate possible improvement

The table stores `G=g+ln(t)`. At very large arguments, reconstructing
`g(x)-g(y)` by subtracting two G values and adding `ln(1+c)` loses digits
because the logarithms are much larger than the desired difference.
Likewise, `f(y)-1/y` subtracts nearly equal quantities. More table nodes do
not repair that cancellation.

If actual covariance weights make this tail relevant, a later change can
evaluate the asymptotic g values directly and express `f(y)-1/y` as the
remainder of its asymptotic polynomial. Review it against high precision
and the defining integral. Do not combine that numerical change with the
initial relocation: otherwise an agreement failure would have two causes
to disentangle.

## 12. Scope that must stay unchanged

The shared evaluator must not select Sheth–Tormen parameters, Duffy
parameters, collapse thresholds, neutrino prescriptions, halo mass limits,
feedback responses or covariance response terms. Those remain caller
inputs. Sharing the NFW mathematics does not validate the present
total-matter halo approximation for massive neutrinos, nor does it complete
the covariance's super-sample response model.

Keep the core branch `lowrank_fftlog`. Coordinate with the team editing
allocators, FFT parity and comment formatting. No general reformatting,
division-to-reciprocal conversion or IA interpolation rewrite belongs in
the numerical-sharing commits.

## 13. Evidence and reproduction record

This folder contains `kernel_results.json`, `kernel_values.npz`,
`covariance_results.json`, the direct/table covariance arrays, and the
radial-test logs. `metadata.json` records the source hashes. `nfw_probe.c`
is an investigation-only copy of the tested kernel bodies; it is not a
proposed second production implementation.

The original isolated build is at
`/private/tmp/nfw_sharing_review_20261118`. The copied `build.sh` records
the local compiler/linker setup. `setup_covariance_experiment.py` and
`run_covariance_case.py` record the covariance experiment. These scripts
use explicit local paths; recreate the `eb37de1` source archive and adjust
those paths before running on another machine. They are an audit record,
not an installed project test target. Promote the relevant cases into the
project tests during implementation, once edits there are authorized.

The remaining scientific acceptance work is the physical-domain survey
and full covariance convergence comparison. The remaining performance
work is measurement of preparation and total covariance time. The
completed tests support the shared design; they do not replace those
acceptance steps.

### First-use cost can reverse the performance comparison

Each table node needs two special-function evaluations during preparation;
each ordinary direct profile needs four outside its small-q branch. For a
nominal `65 redshifts x 48 masses x 64 Fourier nodes`, direct preparation
therefore uses up to 798720 Si/Ci evaluations. A 524288-node shared table
uses 1048576 on its first construction. These counts omit skipped redshifts,
small-q cases and finite-window extras, and are not timings, but they show
why a first covariance may not become faster at the conservative resolution.
The universal table's reuse across subsequent cosmologies is part of the
proposed benefit. Report first-use and reused-table performance separately.
