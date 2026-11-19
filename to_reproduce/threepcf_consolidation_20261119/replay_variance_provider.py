"""Replay frozen CAMB tables while varying only three-point smoothing.

This study adapter implements the normal provider protocol. It never replaces
an imported function. The ordinary two-point calculation receives the original
arrays; a diagnostic refined-local model retains the old three-point power
normalization explicitly. It is not a new production prescription.
"""

import hashlib
import json
from pathlib import Path

import numpy as np

from des3pcf.accuracy import accuracy_settings
from des3pcf.bihalofit import BiHalofit, _Curve, fit_redshifts
from des3pcf.mean import physics_model
from des3pcf.inputs import load_tables, save_tables
from des3pcf.pipeline import COSMOLOGY_NAMES, parameter_key
from des3pcf.variance import SharedVariance


class ReplayVarianceProvider:
    """Keep prepared geometry reusable while loading exactly recorded inputs."""

    def __init__(self, compiled, driver, config, path, replay, variant,
                 legacy_normalization=None):
        self.compiled = compiled
        self.driver = driver
        self.config = config
        self.path = path
        self.variant = variant
        self.reference = dict(config['parameters'])
        self.reference.setdefault('mnu', 0.0)
        self.reference.setdefault('num_massive_neutrinos', 1)
        self.reference.setdefault('nnu', 3.046)
        self.mode = 'frozen_camb_replay'
        self.halofit_version = config['physics'].get('halofit_version','takahashi')
        self.feedback = None
        self.nbin = config['source']['nbin']
        source_path = driver.resolve_path(path, config['physics']['tables'])
        self._source_tables, unused = load_tables(path=source_path)
        self._replay_directory = Path(replay).with_suffix('.replay_tables')
        self._replay_directory.mkdir(exist_ok=True)
        self._files = {}
        saved = json.loads(Path(replay).read_text())
        self._normalizations = {}
        if variant == 'shared_normalized':
            if legacy_normalization is None:
                raise ValueError('Matched normalization requires its saved reference.')
            reference = json.loads(Path(legacy_normalization).read_text())
            for name in ('points', 'physical_table_hashes'):
                if reference[name] != saved[name]:
                    raise ValueError('Normalization reference has different inputs.')
            for point, record in zip(reference['points'], reference['variance_records']):
                key = self._key(point)
                value = record['power_normalization']
                if not np.isfinite(value) or value <= 0.0:
                    raise ValueError('Normalization must be positive and finite.')
                if key in self._normalizations and self._normalizations[key] != value:
                    raise ValueError('Normalization changed at a fixed cosmology.')
                self._normalizations[key] = value
        for point, name, expected in zip(saved['points'], saved['point_table_files'],
                                         saved['point_table_file_sha256']):
            key = self._key(point)
            entry = (name, expected)
            if key in self._files and self._files[key] != entry:
                raise ValueError('One cosmology has different frozen input files.')
            self._files[key] = entry
        self._point = None
        self._base = None
        self._source_model = None
        self._result = None
        self._shared = None
        self._fit_point = None
        self._fit = None
        self._normalization = 1.0
        self._select(parameters=self.reference)

    def _key(self, point):
        parameters = dict(self.reference)
        parameters.update(point)
        return parameter_key(parameters=parameters, names=COSMOLOGY_NAMES)

    def _select(self, parameters):
        key = self._key(parameters)
        if key == self._point:
            return
        filename, expected = self._files[key]
        if hashlib.sha256(Path(filename).read_bytes()).hexdigest() != expected:
            raise ValueError('Frozen input file changed before replay.')
        # CAMB returns cosmological arrays, while the original provider keeps
        # native source edges in its fiducial owner. Restore that independent
        # source information for this fresh fixed-table provider. Remove these
        # added fields from returned arrays so the archived inputs remain
        # directly comparable to the original run.
        self._original_tables, metadata = load_tables(path=filename)
        merged = dict(self._original_tables)
        self._added_source_keys = []
        for name in self._source_tables:
            if name.startswith('source_native') and name not in merged:
                merged[name] = self._source_tables[name]
                self._added_source_keys.append(name)
        prepared = self._replay_directory / Path(filename).name
        save_tables(path=prepared, tables=merged, metadata=metadata,
                    overwrite=True)
        config = json.loads(json.dumps(self.config))
        config['physics']['tables'] = str(prepared)
        config['physics']['cosmology_mode'] = 'fixed_tables'
        for name in COSMOLOGY_NAMES:
            config['parameters'][name] = parameters.get(name, self.reference[name])
        if self.variant != 'shared':
            config['physics']['variance_source'] = 'local'
            for name in ('variance_mass_boost','variance_a_boost',
                         'variance_radius_boost','variance_inverse_boost'):
                config['accuracy'][name] = 1.0
        self._base, unused = self.driver.provider_for_run(
            compiled=self.compiled, config=config, path=self.path)
        self._point = key
        self._source_model = None

    def numerical_key(self):
        return self._base.numerical_key() + (self.variant,)

    def get(self, parameters):
        self._select(parameters=parameters)
        model, tables, metadata = self._base.get(parameters=parameters)
        tables = dict(tables)
        for name in self._added_source_keys:
            tables.pop(name, None)
        self.cosmology_tables = self._original_tables
        self.cosmology_metadata = self._base.cosmology_metadata
        if self.variant == 'shared':
            return model, tables, metadata
        if model is self._source_model:
            return self._result
        if self._fit_point != self._point:
            original = self.cosmology_tables
            anchors = fit_redshifts(zmax=original['z'][-1],fit_nz=self._base.fit_nz,
                                    source_readers=self._base.source_readers)
            if self.variant == 'legacy_refined':
                matter = original['omega_m'] * (1.0+anchors)**3
                dark = original['omega_de'] * (1.0+anchors)**(3.0*(1.0+original['w0']+original['wa']))
                dark *= np.exp(-3.0*original['wa']*anchors/(1.0+anchors))
                arguments = {}
                for name in ('k','p_linear0','z','growth','ns','sigma8'):
                    arguments[name] = original[name]
                fit = BiHalofit(**arguments,omega_m_z=matter/(matter+dark),
                    omega_m_redshift=anchors,fit_nz=self._base.fit_nz,
                    table_boost=self._base.table_boost,
                    source_readers=self._base.source_readers,
                    variance_nodes=8000,slope_nodes=16000,radius_rtol=1e-10)
                self._fit = {'z':fit.fit_anchors,'rnl':fit.radius_anchors,
                             'neff':fit.neff_anchors,'sigma8':fit.sigma8_anchors}
                self._normalization = fit.power_normalization
                self._record = {'engine':'refined legacy Simpson and bisection',
                    'growth_mode':'factorized','sampling':{'variance_nodes':8000,
                    'slope_nodes':16000,'radius_rtol':1e-10},
                    'input_sha256':{},'power_normalization':self._normalization}
            else:
                if self._shared is None:
                    self._shared = SharedVariance(compiled=self.compiled)
                source = dict(original)
                linear = _Curve(x=np.log(original['k']),y=np.log(original['p_linear0']),natural=True)
                growth = _Curve(x=original['z'],y=original['growth'],natural=True)
                linear.prepare_uniform(boost=8)
                growth.prepare_uniform(boost=8)
                source['k'] = np.exp(linear.x)
                source['p_linear0'] = np.exp(linear.y)
                source['z'] = growth.x
                source['growth'] = growth.y
                self._normalization = 1.0
                if self.variant == 'shared_normalized':
                    # Match the old three-point amplitude convention only.
                    # The ordinary two-point model still receives raw CAMB
                    # power, exactly as it did in the legacy reference.
                    self._normalization = self._normalizations[self._point]
                    source['p_linear0'] *= self._normalization
                snapshot, self._record = self._shared.prepare(tables=source,
                    parameters=parameters,metadata=self.cosmology_metadata,
                    z=anchors,accuracy=accuracy_settings(value=self.config['accuracy']))
                self._fit = {}
                for name in ('z','rnl','neff','sigma8'):
                    self._fit[name] = snapshot[name]
                self._record['diagnostic_power_multiplier'] = self._normalization
            self._fit_point = self._point
        model_tables = dict(tables)
        model_tables['p_linear0'] = tables['p_linear0'] * self._normalization
        replacement = physics_model(compiled=self.compiled,tables=model_tables,
            kernel_nz=self._base.kernel_nz,source_readers=self._base.source_readers,
            table_boost=self._base.table_boost,fit_nz=self._base.fit_nz,
            accuracy=self._base.accuracy,pixel_window=self._base.pixel_window,
            variance=self._fit)
        record = dict(metadata)
        record['variance'] = self._record
        self._source_model = model
        self._result = (replacement, tables, record)
        return self._result
