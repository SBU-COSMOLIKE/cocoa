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

# ADDING NEFF AS DERIVED PARAMETER
parameter = [u'H0',u'omegabh2',u'omegach2',u'Omega_m',u'Omega0_scf_ke',u'chi2bao']
chaindir=r'.'

root_chains = ('EXAMPLE_MCMC13','EXAMPLE_MCMC18')


analysissettings={'smooth_scale_1D':0.15,'smooth_scale_2D':0.15,
'ignore_rows': u'0.5', 'range_confidence' : u'0.015'}

analysissettings2={'smooth_scale_1D':0.25,'smooth_scale_2D':0.25,
'ignore_rows': u'0.0', 'range_confidence' : u'0.015'}

samples=loadMCSamples('./' + root_chains[0], settings=analysissettings)
samples.deleteZeros()
samples.thin(factor = int(len(samples.weights)/20000))
p = samples.getParams()
samples.saveAsText('.VM_P2V4_TMP1')
samples=loadMCSamples('./' + '.VM_P2V4_TMP1',settings=analysissettings2)
samples.addDerived(p.chi2__planck_2018_lowl.TT + 
  p.chi2__planck_2018_lowl.EE + p.chi2__planck_2018_highl_plik.TTTEEE, 
  name='chi2CMB',label='{\\chi^2_{\\mathrm{CMB}}}')
samples.addDerived(p.chi2__sn.pantheon, 
  name='chi2sn',label='{\\chi^2_{\\mathrm{SN}}}')
samples.addDerived(p.chi2__bao.sdss_dr12_consensus_bao + p.chi2__bao.sdss_dr7_mgs, 
  name='chi2bao',label='{\\chi^2_{\\mathrm{BAO}}}')
samples.saveAsText('.VM_P2V4_TMP1')

# ------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------

samples=loadMCSamples('./' + root_chains[1], settings=analysissettings)
samples.deleteZeros()
samples.thin(factor = int(len(samples.weights)/20000))
p = samples.getParams()
samples.saveAsText('.VM_P2V4_TMP2')
samples=loadMCSamples('./' + '.VM_P2V4_TMP2',settings=analysissettings2)
#samples.addDerived(p.chi2__planck_2018_lowl.TT + 
#  p.chi2__planck_2018_lowl.EE + p.chi2__planck_2018_highl_plik.TTTEEE, 
#  name='chi2CMB',label='{\\chi^2_{\\mathrm{CMB}}}')
#samples.addDerived(p.chi2__sn.pantheon, 
#  name='chi2sn',label='{\\chi^2_{\\mathrm{SN}}}')
samples.addDerived(p.chi2__bao.sdss_dr12_consensus_bao + p.chi2__bao.sdss_dr7_mgs, 
  name='chi2bao',label='{\\chi^2_{\\mathrm{BAO}}}')
samples.saveAsText('.VM_P2V4_TMP2')


#GET DIST PLOT SETUP
g=gplot.getSubplotPlotter(chain_dir=chaindir,
analysis_settings=analysissettings2,width_inch=14.0)
g.settings.lw_contour = 1.2
g.settings.legend_rect_border = False
g.settings.figure_legend_frame = False
g.settings.axes_fontsize = 13.5
g.settings.legend_fontsize = 15.5
g.settings.alpha_filled_add = 0.7
g.settings.lab_fontsize=15
g.legend_labels=False

param_3d = None
g.triangle_plot(['.VM_P2V4_TMP1', '.VM_P2V4_TMP2'],parameter,
plot_3d_with_param=param_3d,line_args=[
{'lw': 1.0,'ls': 'solid', 'color':'royalblue'},
{'lw': 1.6,'ls': 'solid', 'color':'firebrick'}],
contour_colors=['royalblue','firebrick'],
filled=True,shaded=False,
legend_labels=['Model 3 PL+PT','Model 3 SO+WF'],legend_loc=(0.5,0.825),
imax_shaded=0)
g.export()