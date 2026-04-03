import getdist.plots as gplot
from getdist import MCSamples
from getdist import loadMCSamples
import os
import matplotlib
import subprocess
import matplotlib.pyplot as plt
import numpy as np

# GENERAL PLOT OPTIONS
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

# ADDING AS DERIVED PARAMETER
num_points_thin = 30000

parameter = [u'omegam', u'H0', u'w', u'wa', u'SS8']
chaindir=r'./'

analysissettings={'smooth_scale_1D':0.45,'smooth_scale_2D':0.45,'ignore_rows': u'0.3',
'range_confidence' : u'0.025'}

analysissettings2={'smooth_scale_1D':0.45,'smooth_scale_2D':0.45,'ignore_rows': u'0.0',
'range_confidence' : u'0.025'}


root_chains = (
  'EXAMPLE_MCMC702',
  'EXAMPLE_MCMC703',
  'EXAMPLE_MCMC705',
  'EXAMPLE_MCMC706',
  'EXAMPLE_MCMC707',
)

# --------------------------------------------------------------------------------
samples=loadMCSamples(chaindir + root_chains[0],settings=analysissettings)
samples.thin(factor = int(np.sum(samples.weights)/num_points_thin))
p = samples.getParams()
samples.addDerived(p.s8omegamp5/0.5477225575,name='SS8',label='{S_8}')
samples.saveAsText(chaindir + '/.VM_P99v3_TMP1')
# --------------------------------------------------------------------------------
samples=loadMCSamples(chaindir + root_chains[1],settings=analysissettings)
samples.thin(factor = int(np.sum(samples.weights)/num_points_thin))
p = samples.getParams()
samples.addDerived(p.s8omegamp5/0.5477225575,name='SS8',label='{S_8}')
samples.saveAsText(chaindir + '/.VM_P99v3_TMP2')
# --------------------------------------------------------------------------------
samples=loadMCSamples(chaindir + root_chains[2],settings=analysissettings)
samples.thin(factor = int(np.sum(samples.weights)/num_points_thin))
p = samples.getParams()
samples.addDerived(p.s8omegamp5/0.5477225575,name='SS8',label='{S_8}')
samples.saveAsText(chaindir + '/.VM_P99v3_TMP3')
# --------------------------------------------------------------------------------
samples=loadMCSamples(chaindir + root_chains[3],settings=analysissettings)
samples.thin(factor = int(np.sum(samples.weights)/num_points_thin))
p = samples.getParams()
samples.addDerived(p.s8omegamp5/0.5477225575,name='SS8',label='{S_8}')
samples.saveAsText(chaindir + '/.VM_P99v3_TMP4')
# --------------------------------------------------------------------------------
samples=loadMCSamples(chaindir + root_chains[4],settings=analysissettings)
samples.thin(factor = int(np.sum(samples.weights)/num_points_thin))
p = samples.getParams()
samples.addDerived(p.s8omegamp5/0.5477225575,name='SS8',label='{S_8}')
samples.saveAsText(chaindir + '/.VM_P99v3_TMP5')

#GET DIST PLOT SETUP
g=gplot.getSubplotPlotter(chain_dir=chaindir,
analysis_settings=analysissettings2,width_inch=6.0)
g.settings.lw_contour = 1.2
g.settings.legend_rect_border = False
g.settings.figure_legend_frame = False
g.settings.axes_fontsize = 13.5
g.settings.legend_fontsize = 13.0
g.settings.alpha_filled_add = 0.9
g.settings.lab_fontsize=15
g.legend_labels=False

param_3d = None
g.triangle_plot(['.VM_P99v3_TMP1',
                 '.VM_P99v3_TMP2',
                 '.VM_P99v3_TMP3',
                 '.VM_P99v3_TMP4',
                 '.VM_P99v3_TMP5'],parameter,
plot_3d_with_param=param_3d,
legend_labels=[
  'Planck $\\ell < 2500$ + DESI + Pantheon', 
  'Planck $\\ell < 2500$ + DESI (no $z=0.71$) + Pantheon',
  'Planck $\\ell < 2500$ + DESI (no $z=0.51$) + Pantheon',
  'Planck $\\ell < 2500$ + DESI (no $z=(0.51,0.71)$) + Pantheon',
  'Planck $\\ell < 2500$ + DESI (no $z=(0.51,0.71)$) + BOSS DR12 + DR6 + Pantheon'
],
legend_loc=(0.3,0.805),
imax_shaded=0,
contour_colors=['royalblue','lightcoral','grey','black','gold'],
filled=[True,True,False,False,False],
line_args=[
{'lw': 1.1,'ls': 'solid', 'color':'royalblue'},
{'lw': 1.4,'ls': 'solid', 'color':'lightcoral'},
{'lw': 1.7,'ls': '-.', 'color':'grey'},
{'lw': 1.0,'ls': 'dashed', 'color':'black'},
{'lw': 1.3,'ls': 'solid', 'color':'gold'}
],
contour_ls=['solid', 'solid', '-.', 'dashed','solid'],
contour_lws=[1.1, 1.4, 1.7, 1.0,1.3],
)
g.export()