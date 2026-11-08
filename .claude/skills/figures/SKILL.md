---
name: figures
description: The maintainer's figure style for every figure in Cocoa and its projects - papers and paper notes (projects/*/notes/*/plots), notebook cells (EXAMPLE_EVALUATE*.ipynb), README and study figures, test and validation plots, and the plotting functions of cosmolike_notebook_utils. Use it whenever a figure, a plot script, a notebook plotting cell, a figure caption or a plotting function is written or changed. It fixes the house rcParams block, the colorblind-safe palette (never red with green) with redundant encodings (color + line width + marker), legends and labels kept off the data by a check in code, layouts per medium (one-column paper panels, README sizes), captions as short statements, the plot-folder contract, and figures in place of big tables. A project may add its own assignments in .claude/skills/paper-figures/SKILL.md (lssty1xdesi has one).
---

# Figures

Every figure must carry its main message at a glance. The rules below
come from repeated corrections by the maintainer and are fixed choices,
not suggestions. Apply them when a figure is first written, not as a
later cleanup. Section 1 holds the rules for every figure; Sections 2-4
add the rules of each medium; Section 5 covers plotting code.

A project with its own `.claude/skills/paper-figures/SKILL.md` (for
example lssty1xdesi) adds that project's assignments on top: which
color, width and marker each of its categories takes, its scale-cut
limits, its reference results.

## 1. Every figure

### The house rcParams block

Every plotting script (`plot_*.py`, study and test scripts) and every
notebook's setup cell carries this block verbatim:

```python
# Figure style of the whole notebook: the shared plotting functions never change
# rcParams, so these lines set every font, tick and grid default.
matplotlib.rcParams['mathtext.fontset'] = 'stix'
matplotlib.rcParams['font.family'] = 'STIXGeneral'
matplotlib.rcParams['mathtext.rm'] = 'Bitstream Vera Sans'
matplotlib.rcParams['mathtext.it'] = 'Bitstream Vera Sans:italic'
matplotlib.rcParams['mathtext.bf'] = 'Bitstream Vera Sans:bold'
matplotlib.rcParams['xtick.bottom'] = True
matplotlib.rcParams['xtick.top'] = False
matplotlib.rcParams['ytick.right'] = False
matplotlib.rcParams['axes.edgecolor'] = 'black'
matplotlib.rcParams['axes.linewidth'] = '1.0'
matplotlib.rcParams['axes.labelsize'] = 'medium'
matplotlib.rcParams['axes.grid'] = True
matplotlib.rcParams['grid.linewidth'] = '0.0'
matplotlib.rcParams['grid.alpha'] = '0.18'
matplotlib.rcParams['grid.color'] = 'lightgray'
matplotlib.rcParams['legend.labelspacing'] = 0.77
matplotlib.rcParams['savefig.bbox'] = 'tight'
matplotlib.rcParams['savefig.format'] = 'pdf'
```

For notebooks, the setup cell also sets `%matplotlib inline` and
`%config InlineBackend.figure_format = 'retina'` (Section 3).

### Color and redundant encoding

- **Palette.** Okabe-Ito, colorblind safe, and never red together with
  green. In order of use: `#0072B2` (blue), `#E69F00` (orange),
  `#CC79A7` (reddish purple), `#56B4E9` (sky blue), `#D55E00`
  (vermillion), `#F0E442` (yellow, only for thick lines or fills),
  black. Its bluish green `#009E73` is not used next to a red or
  vermillion. External references are gray.
- **Never color alone.** Every category is encoded redundantly, so the
  eye separates it from several cues at once: color + line width +
  marker for the main categories (for four: widths 2.4, 1.8, 1.3, 0.9
  with markers `o`, `s`, `D`, `^`), line style for models or variants
  (solid, dashed, with a dash pattern visible at the thinnest width).
  This is the maintainer's house style for papers: several cues let
  the reader catch the main message faster, whatever the medium.
  Check: the PNG converted to grayscale still lets every line be
  identified.

### Legends, labels and references

- Legends `frameon=False`; no `bbox` on text; no `\%` in labels
  without usetex (it prints the backslash).
- A legend, label or text must never touch a data line, a marker or a
  reference line. Enforce it in code: sample every drawn line in
  display coordinates (a `line_points` helper; the lssty1xdesi scripts
  under `projects/lssty1xdesi/notes/*/plots/` are working examples),
  try candidate corners or grow the y headroom by the least amount,
  and raise an error when nothing clears. Never rely on a visual check
  alone.
- Legend entries show the markers and line widths that are actually
  drawn; for filled-versus-open pairs, use a tuple handle with the
  drawn pair, never a neutral stand-in.
- Stacked legends (line styles above, layouts below) sit close
  together, with no large vertical gap.
- Reference lines carry no legend entry; the caption names them. A
  reference far above the data (more than 1.5 times the highest
  point) is not drawn on a stretched axis: an in-panel text such as
  "<reference survey>: <value>" quotes it instead, included in the bounding-box
  check.
- Legend labels name a model plainly; a variant is stated once in the
  caption when the figure draws only one, so variant names do not
  clash with other labels in the panels.

### Look at it

Render every figure and look at it before showing it or committing it,
in every mode a plotting function offers. A figure that has not been
looked at is not done.

### Names on figures

The primordial amplitude is written A_s, never a bare "As". Labels use
the names the text uses; internal code keys and jargon stay out of
figures.

## 2. Papers and paper notes

Figures for a two-column article and for the LaTeX notes that feed a
paper.

### The plot-folder contract

Each figure lives in `notes/<note>/plots/<name>/`:

- `data.json`: everything the figure draws, plus an `about` string
  naming its producer (a notebook export cell, a generator script in
  the note's `plots/` folder, or a hand transcription from a paper);
- `plot_<name>.py`: redraws the figure from `data.json` alone;
- `<name>.pdf` (included by the note) and `<name>.png` (dpi 300).

Test: copy the folder to an empty directory and run
`.local/bin/python -I -W error::RuntimeWarning plot_<name>.py` with the
cocoa environment's Python. It must redraw without the notebook,
CosmoLike or the repository. Look at every PNG after redrawing.

### Layout

- **Width.** One column (about 3.5 in) by default. A full-width strip
  (about 6.4 in) only for a grid that must sit side by side, and then
  short: a strip of the page, never a full page.
- **Stacked panels.** Panels are stacked vertically, wide and short
  (about 1.1 to 1.3 in each), with a thin gap (`hspace` about 0.06,
  never 0). They share the x axis, with tick labels on the bottom
  panel only. Every panel of a stack uses the exact same y range, and
  there is one shared y label (`fig.supylabel`).
- **Panel names.** Inside the panel (a corner free of data) or rotated
  90 degrees as a right-hand y label (used for parameter names and
  prior names). A title only when the caption cannot carry it.
- **Different natural ranges.** When the panels of a grid have
  different natural y ranges (a column per sample group), divide each
  column by one round constant, written inside its panel (e.g.
  delta_g = 20%), so that every panel shares one y axis, only the first
  column needs tick labels and the panels nearly touch
  (`wspace` about 0.06). Separate per-panel ranges give a poor aspect
  ratio and are not used.
- **Sibling figures.** Two figures with the same axes (two priors, two
  scenarios) become rows of one grid.
- **Crowding.** Draw only the variants the text discusses; values that
  are 1 or 0 by construction go into the caption, not onto the plot.
  When curves stay apart, one panel with redundant encodings beats
  several panels. Use a linear axis unless the values span decades.
- **Narrow x spacing.** Categorical x axes keep cases close; no wide
  figures with large gaps between cases.

### Scale cuts on figures

When a scale cut grows with redshift (a cut at k_max/D(z) per bin), the
plotted k_max is only its z = 0 value: axis labels say "at z = 0" and
captions carry a one-clause reminder of the per-bin rule. A sample with
its own cut is named. A project fixes the largest k_max its figures
show in its own paper-figures skill.

### Captions

- Short statements, never questions. Say what is drawn, what is
  omitted and the k_max clause.
- No value the reader takes from the plot; no FoM to two digits.
- Symbols defined once in the text; the caption only points to them.
- A diagnostic statistic gets no invented name: write its symbol and
  explain it once in a statement, e.g. "How well each fit's quoted
  error bar covers where the fit actually lands, measured by
  eta = sqrt(<chi^2>/n_dof)".

### Tables and narrative order

- No big numeric tables in any note: a table of many numbers becomes a
  compact figure (stacked panels, one line per entry against the
  natural variable). Only short didactic tables remain. A table that a
  figure duplicates is removed.
- Logic before FoM: a prior or model that fails the accuracy test gets
  no FoM in any figure (its FoM means nothing). The FoM figures show
  only what survives.
- Two scenarios that the author has not ranked (e.g. baseline and
  pessimistic variants) are shown side by side with equal weight; no
  caption calls one the headline.

## 3. Notebooks

The setup cell of every `EXAMPLE_EVALUATE*.ipynb` runs
`%matplotlib inline` and `%config InlineBackend.figure_format = 'retina'`,
then the house rcParams block of Section 1, verbatim.

Plotter call defaults in notebooks (`cosmolike_notebook_utils`
`plot_datavectors`, ratio mode against a reference):

```python
cnu.plot_gammat_tomo_limber(theta_gammat=curves, gammat_ref=reference,
    param=param, colorbarlabel="Accuracy Boost",
    ylim=(0.981, 1.019),                 # tight: fitted to the curves
    bintextpos=[0.85, 0.2], bintextsize=20,
    legendloc=(0.9, 0.55),
    linewidth=[1.0, 1.3, 1.6, 1.9],
    linestyle=['solid', 'dashed', 'dashdot', 'dotted'],
    figsize=(20, 13),                    # grids; (18, 13./5) for one row (w)
    yaxislabelsize=17, yaxisticklabelsize=14, xaxisticklabelsize=20)
```

## 4. READMEs and studies

Rules the maintainer applies when reading a figure:

- **No white space.** The y-range is fitted to the data: not symmetric
  when the curves sit on one side of 0, 0 included, about 10% padding.
  A ±1 axis for percent-level curves is rejected.
- **One range per row when rows differ.** Pass the plotters' per-row
  `ylim` (one `[lo, hi]` per row, ratio mode of `plot_xi` and
  `plot_gammat_tomo_limber`). If every panel of a row needs a rescale
  factor, the range is wrong.
- **Outlier panels get a factor, printed as 1/alpha.** The panel shows
  alpha times the curve and prints `1/α = f` with f in 2, 3, 5, 10, 20,
  30, 50, 100, ... (`1/α = 3` reads: the difference is three times what
  the axis shows). Reserve it for a few panels.
- **The quantity a reader needs.** For a code or setting comparison,
  plot the difference in units of the data error,
  $(d_a - d_b)/\sigma$ with $\sigma = \sqrt{C_{ii}}$ (1 = one sigma), or
  in percent, `100 (a/b - 1)`; never a raw fraction such as 0.0017.
  Label the axis with the quantity (`$\Delta\gamma_t/\sigma$`,
  `$\gamma_t$ diff. [%]`).
- **Few curves.** Show only the comparison asked for (for example one
  curve per cosmology); variants and diagnostics go in tables.
- **One shared legend, without a frame** (`frameon=False`). Prefer one
  row above the panels; a free corner of one panel is suitable for a
  compact illustration. Do not repeat the same legend in every panel.
  Bin labels and the 1/alpha note sit where the curves leave free space.
- **Give the panels the space.** Use shared axis labels when their
  meanings match. Omit an obvious overall title, repeated close-up
  titles and explanatory footers. Keep equations, normalization details,
  node-position explanations and limits in the study README instead.
- For the per-project n(z) study, use at most two panels; the common
  original/3/5/7 reconstruction illustration may use the requested four
  columns. Explain how a displayed bin edge and redshift range were
  selected in both the plotting script's comments and the study README.
- **Readable at README size.** Figures for a README or a study use larger
  fonts than the notebook defaults: y label 24, y ticks 19, x ticks 22,
  x label 24, bin labels 22, legend 22, and 180 dpi.
- **Every curve visible.** No pale colors (colormaps such as
  `twilight_shifted` lose their middle); a light color gets a long dash
  and a wide line, a dark color may take the dots; never a light, thin,
  dotted line.
- **Look at the rendered image** before showing it (Cosmolike skill,
  `references/python.md` Section 10).

## 5. Plotting code

The data-vector plotting functions and the notebook helpers live in
the Cosmolike core (`cosmolike_notebook_utils/`), and their
conventions are written in the Cosmolike skill:
`external_modules/code/cosmolike_core/.claude/skills/cosmolike-dev/references/python.md`,
Section 10. Read it before writing or changing a plotting function, a
notebook wrapper or a notebook. The points that matter from this side:

- `cosmolike_notebook_utils` never imports a project's compiled
  interface; a function that needs cosmolike receives the notebook's
  callable as an argument. Its plotting modules are pure numpy and
  matplotlib.
- A new plotting function copies the signature order and the behavior
  of the existing ones: the list of curves, an optional `*_ref` that
  switches the panels to `value/reference - 1`, `param` with
  `colorbarlabel` for a sweep, `show = None` returning `(fig, axes)`,
  and malformed input printing one message and returning 0.
- A notebook cell calls the project's wrappers and the shared plotting
  functions; it does not reimplement them inline. The wrapper
  initializes cosmolike exactly as the project's likelihood does.
- A figure is checked by rendering it and looking at it, in every mode
  the function offers.
