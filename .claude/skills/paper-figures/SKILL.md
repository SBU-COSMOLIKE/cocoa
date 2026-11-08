---
name: paper-figures
description: The maintainer's figure style for papers and paper notes in every Cocoa project (projects/*/notes, paper drafts, forecast figures). Use it whenever a paper or note figure, its plot script (notes/*/plots/*/plot_*.py), a notebook cell that draws a paper figure, or a figure caption is written or changed. It fixes the house rcParams block, the one-column layout, the colorblind-safe palette with redundant encodings, legend and label placement enforced in code, caption wording, the plot-folder contract and the rules that replace tables by figures. README and study figures follow cocoa-maintenance Section 8.8 instead; a project may add its own specifics in its own paper-figures skill.
---

# Paper figures

Every figure is made for a two-column article and must carry its main
message at a glance. The rules below come from repeated corrections
and are fixed choices, not suggestions. Apply them when a figure is
first written, not as a later cleanup.

Scope: figures of papers and of the LaTeX notes that feed them. README
and study figures (larger fonts, data-vector plotters) follow
cocoa-maintenance Section 8.8. A project's own
`.claude/skills/paper-figures/SKILL.md`, where it exists, adds that
project's assignments (which color and width each of its categories
takes, its scale-cut conventions, its reference results) on top of
these rules.

## The plot-folder contract

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

## The house rcParams block

Every `plot_*.py`, and every notebook cell that draws a paper figure,
carries this block verbatim:

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

## Layout

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

## Color and redundant encoding

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

## Legends, labels and references

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

## Scale cuts on figures

When a scale cut grows with redshift (a cut at k_max/D(z) per bin), the
plotted k_max is only its z = 0 value: axis labels say "at z = 0" and
captions carry a one-clause reminder of the per-bin rule. A sample with
its own cut is named. A project fixes the largest k_max its figures
show in its own paper-figures skill.

## Captions

- Short statements, never questions. Say what is drawn, what is
  omitted and the k_max clause.
- No value the reader takes from the plot; no FoM to two digits.
- Symbols defined once in the text; the caption only points to them.
- A diagnostic statistic gets no invented name: write its symbol and
  explain it once in a statement, e.g. "How well each fit's quoted
  error bar covers where the fit actually lands, measured by
  eta = sqrt(<chi^2>/n_dof)".

## Tables and narrative order

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

## Names on figures

The primordial amplitude is written A_s, never a bare "As". Labels use
the names the text uses; internal code keys and jargon stay out of
figures.
