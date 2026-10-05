#!/usr/bin/env python3
"""Check execution paths and output health, not calibrated material predictions."""
import csv
import math
from pathlib import Path
import sys


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def read(name):
    path = Path(__file__).parent / (name + '_out.csv')
    with path.open() as stream:
        rows = [{k: float(v) for k, v in row.items()} for row in csv.DictReader(stream)]
    require(bool(rows), f'{path.name}: no output rows')
    require(all(math.isfinite(v) for row in rows for v in row.values()),
            f'{path.name}: nonfinite output')
    require(all(b['time'] > a['time'] for a, b in zip(rows, rows[1:])),
            f'{path.name}: non-increasing output times')
    return rows


def check(case):
    rows = read(case)
    first, last = rows[0], rows[-1]
    if case == 'pbx_initialization':
        require(len(rows) == 1 and first['time'] == 0, 'Initialization must not advance time')
        require(first['max_grain'] > 0 and first['min_grain'] == 0,
                'Expected both particle and binder assignments')
        require(0 < first['mean_fraction'] < 1, 'Expected a heterogeneous fraction field')
    elif case == 'ad_thermal_diffusion':
        require(len(rows) == 6 and math.isclose(last['time'], 0.05), 'Missing thermal steps')
        require(first['max_temperature'] > first['min_temperature'], 'Initial field is not random')
        require(last['max_temperature'] - last['min_temperature'] <
                first['max_temperature'] - first['min_temperature'], 'Temperature field did not evolve')
    elif case == 'mode1_fracture':
        require(len(rows) == 6 and math.isclose(last['time'], 0.1), 'Missing fracture steps')
        require(last['opening'] > 0, 'Mode-I displacement was not applied')
        require(first['mean_damage'] > 0, 'Initial notch was not initialized')
        require(last['mean_damage'] > first['mean_damage'], 'Damage coupling did not activate')
        require(all(0 <= r['mean_damage'] <= 1 for r in rows), 'Damage outside bounds')
    elif case == 'viscoplastic_relaxation':
        require(math.isclose(last['time'], 200), 'Relaxation did not finish')
        ramp = next(r for r in rows if math.isclose(r['time'], 20))
        hold = [r for r in rows if r['time'] >= 20]
        require(all(math.isclose(r['right_displacement'], 0.01, abs_tol=1e-10)
                    for r in hold), 'Displacement did not remain fixed during hold')
        require(last['mean_vp_ep'] > ramp['mean_vp_ep'] > 0, 'Viscoplastic flow did not continue')
        require(last['mean_vp_sigma_xx'] < ramp['mean_vp_sigma_xx'], 'No axial stress relaxation')
        require(all(r['mean_vp_Je'] > 0 and r['mean_vp_Jp'] > 0 for r in rows),
                'Invalid deformation-gradient determinant')
    else:
        raise ValueError('Unknown case: ' + case)
    print(f'PASS: {case} ({len(rows)} output rows)')


if __name__ == '__main__':
    check(sys.argv[1])
