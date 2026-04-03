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
parameter = [u'omegam2', u'H0', u'SS8',u'm_ncdm',u'n_s',u'As_1e9',
u'omegabh2',u'sigma8',u'Omega0_scf_ke',u'chi2_sn2',u'chi2_cmb2']
chaindir=r'./'

analysissettings={'smooth_scale_1D':0.45,'smooth_scale_2D':0.45,
'ignore_rows': u'0.35','range_confidence' : u'0.025'}

analysissettings2={'smooth_scale_1D':0.45,'smooth_scale_2D':0.45,
'ignore_rows': u'0.0','range_confidence' : u'0.025'}


root_chains = (
  'EXAMPLE_MCMC8000',
  'EXAMPLE_MCMC801',
  'EXAMPLE_MCMC8002',
  'EXAMPLE_MCMC803',
)

# --------------------------------------------------------------------------------
samples=loadMCSamples(chaindir + root_chains[0],settings=analysissettings)
p = samples.getParams()
samples.addDerived(p.omegan+(p.omegach2+p.omegabh2)/(p.H0/100.)/(p.H0/100.),name='omegam2',label='{\\Omega_m}')
samples.addDerived(p.sigma8*np.sqrt(p.omegan+(p.omegach2+p.omegabh2)/(p.H0/100.)/(p.H0/100.))/0.5477225575,name='SS8',label='{S_8}')
samples.addDerived(p.chi2__planck_2018_lowl.TT+p.chi2__planck_2018_lowl.EE+p.chi2__planck_2018_highl_plik.TTTEEE,name='chi2_cmb2',label='{\\chi^2_{\\rm CMB}}')
samples.addDerived(p.chi2__sn.pantheon,name='chi2_sn2',label='{\\chi^2_{\\rm SN}}')
samples.saveAsText(chaindir + '/.VM_PKIM_TMP1')
# --------------------------------------------------------------------------------
samples=loadMCSamples(chaindir + root_chains[1],settings=analysissettings)
p = samples.getParams()
samples.addDerived(p.omegan+(p.omegach2+p.omegabh2)/(p.H0/100.)/(p.H0/100.),name='omegam2',label='{\\Omega_m}')#sigma8
samples.addDerived(p.sigma8*np.sqrt(p.omegan+(p.omegach2+p.omegabh2)/(p.H0/100.)/(p.H0/100.))/0.5477225575,name='SS8',label='{S_8}')
samples.addDerived(p.chi2__planck_2018_lowl.TT+p.chi2__planck_2018_lowl.EE+p.chi2__planck_2018_highl_plik.TTTEEE,name='chi2_cmb2',label='{\\chi^2_{\\rm CMB}}')
samples.addDerived(p.chi2__sn.pantheon,name='chi2_sn2',label='{\\chi^2_{\\rm SN}}')
samples.saveAsText(chaindir + '/.VM_PKIM_TMP2')
# --------------------------------------------------------------------------------
samples=loadMCSamples(chaindir + root_chains[2],settings=analysissettings)
p = samples.getParams()
samples.addDerived(p.omegan+(p.omegach2+p.omegabh2)/(p.H0/100.)/(p.H0/100.),name='omegam2',label='{\\Omega_m}')
samples.addDerived(p.sigma8*np.sqrt(p.omegan+(p.omegach2+p.omegabh2)/(p.H0/100.)/(p.H0/100.))/0.5477225575,name='SS8',label='{S_8}')
samples.addDerived(p.chi2__planck_2018_lowl.TT+p.chi2__planck_2018_lowl.EE+p.chi2__planck_2018_highl_plik.TTTEEE,name='chi2_cmb2',label='{\\chi^2_{\\rm CMB}}')
samples.addDerived(p.chi2__sn.pantheon,name='chi2_sn2',label='{\\chi^2_{\\rm SN}}')
samples.saveAsText(chaindir + '/.VM_PKIM_TMP3')
# --------------------------------------------------------------------------------
samples=loadMCSamples(chaindir + root_chains[3],settings=analysissettings)
p = samples.getParams()
samples.addDerived(p.omegan+(p.omegach2+p.omegabh2)/(p.H0/100.)/(p.H0/100.),name='omegam2',label='{\\Omega_m}')
samples.addDerived(p.sigma8*np.sqrt(p.omegan+(p.omegach2+p.omegabh2)/(p.H0/100.)/(p.H0/100.))/0.5477225575,name='SS8',label='{S_8}')
samples.addDerived(p.chi2__planck_2018_lowl.TT+p.chi2__planck_2018_lowl.EE+p.chi2__planck_2018_highl_plik.TTTEEE,name='chi2_cmb2',label='{\\chi^2_{\\rm CMB}}')
samples.addDerived(p.chi2__sn.pantheon,name='chi2_sn2',label='{\\chi^2_{\\rm SN}}')
samples.saveAsText(chaindir + '/.VM_PKIM_TMP4')
# --------------------------------------------------------------------------------


#GET DIST PLOT SETUP
g=gplot.getSubplotPlotter(chain_dir=chaindir,
analysis_settings=analysissettings2,width_inch=8.0)
g.settings.lw_contour = 1.2
g.settings.legend_rect_border = False
g.settings.figure_legend_frame = False
g.settings.axes_fontsize = 13.5
g.settings.legend_fontsize = 15.5
g.settings.alpha_filled_add = 0.7
g.settings.lab_fontsize=15
g.legend_labels=False

param_3d = None
g.triangle_plot(['.VM_PKIM_TMP1','.VM_PKIM_TMP2','.VM_PKIM_TMP3','.VM_PKIM_TMP4'],parameter,
plot_3d_with_param=param_3d,line_args=[
{'lw': 1.1,'ls': 'solid', 'color':'royalblue'},
{'lw': 1.4,'ls': 'solid', 'color':'lightcoral'},
{'lw': 1.7,'ls': '-.', 'color':'grey'},
{'lw': 1.0,'ls': 'dashed', 'color':'black'},
],
contour_colors=['royalblue','lightcoral','grey','black'],
filled=[True,True,False,False,False],
legend_labels=[
  'Planck $\\ell < 1296$ + Pantheon, QUAD SCF', 
  'Planck $\\ell < 1296$ + Pantheon, LINEAR SCF',
  'Planck $\\ell < 1296$ + Pantheon, QUAD SCF',
  'Planck $\\ell < 1296$ + Pantheon, LINEAR SCF',
],
contour_ls=['solid', 'solid', '-.', 'dashed'],
contour_lws=[1.1, 1.4, 1.7, 1.0],
legend_loc=(0.4,0.815),
imax_shaded=0)
g.export()