"""Plot transverse means in reference position versus time for a structured Exodus mesh.

Accepts case names, case directories, or Exodus paths. Use --all for DIR*/*_out.e.
Requires Python 3.9+, NumPy, SciPy and Matplotlib. Reads classic NetCDF Exodus
files with one block of axis-aligned quadrilateral or hexahedral cells.
Coordinates, times and stresses are assumed to use microns, ns and GPa.
"""
import argparse
import sys
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
from scipy.io import netcdf_file


plt.rcParams.update({
        "font.family": "serif",
        "font.serif": ["Times New Roman", "Times", "Nimbus Roman", "DejaVu Serif"],
})

#make font size larger 

plt.rcParams.update({'font.size': 18})

def resolve_input(value):
    path = Path(value).expanduser()
    if path.is_file():
        return path.resolve()
    if not path.is_dir():
        path = Path('DIR' + str(value))
    if path.is_dir():
        name = path.name[3:] if path.name.startswith('DIR') else path.name
        candidate = path / (name + '_out.e')
        if candidate.is_file():
            return candidate.resolve()
    raise FileNotFoundError(f'Cannot find Exodus output for {value}')


def plot_case(input_path, args):
    """Write PNG, PDF and averaged NPZ data for one case."""
    axis = 'xyz'.index(args.axis)
    with netcdf_file(input_path, 'r', mmap=True) as source:
        def read(name):
            return source.variables[name][:].copy()

        def names(name):
            return [row.tobytes().split(b'\0')[0].decode().strip() for row in read(name)]

        if source.dimensions['num_el_blk'] != 1:
            raise ValueError('This script expects one structured element block.')
        connectivity = read('connect1').astype(int) - 1
        coordinates = np.column_stack([
            read('coord' + direction) for direction in 'xyz'[:source.dimensions['num_dim']]
        ])
        if axis >= coordinates.shape[1]:
            raise ValueError(f'The mesh has no {args.axis} coordinate.')
        corners = coordinates[connectivity]
        centers = corners.mean(axis=1)
        # Reference-volume weighting is equivalent to area weighting for constant thickness.
        extents = np.ptp(corners, axis=1)
        active = np.ptp(coordinates, axis=0) > 0
        if not active[axis]:
            raise ValueError('The selected shock direction has zero extent.')
        if connectivity.shape[1] != 2 ** int(active.sum()) or not np.all(
            np.isclose(corners, corners.min(axis=1)[:, None, :]) |
            np.isclose(corners, corners.max(axis=1)[:, None, :])
        ):
            raise ValueError('Expected axis-aligned linear quadrilateral or hexahedral cells.')
        volumes = np.prod(extents[:, active], axis=1)
        positions, rows = np.unique(np.round(centers[:, axis], 9), return_inverse=True)
        if not np.all(volumes > 0) or len(positions) < 2:
            raise ValueError('Expected a structured mesh with positive cell volumes.')
        weights = np.bincount(rows, weights=volumes)
        all_times = read('time_whole')
        indices = np.flatnonzero((all_times >= args.start_time) & (all_times <= args.end_time))[::args.stride]
        times = all_times[indices]
        if len(times) < 2 or not np.isfinite(times).all() or not np.all(np.diff(times) > 0):
            raise ValueError('Select at least two finite, strictly increasing output times.')
        temperature_index = names('name_nod_var').index('temperature') + 1
        pressure_index = names('name_elem_var').index('s_pressure') + 1
        temperature = np.empty((len(times), len(positions)))
        pressure = np.empty_like(temperature)
        for i, time_index in enumerate(indices):
            nodal = source.variables[f'vals_nod_var{temperature_index}'][time_index].copy()
            cell_temperature = nodal[connectivity].mean(axis=1)
            # s_pressure is mean normal stress: compression is negative.
            cell_pressure = -source.variables[f'vals_elem_var{pressure_index}eb1'][time_index].copy()
            temperature[i] = np.bincount(rows, weights=cell_temperature * volumes) / weights
            pressure[i] = np.bincount(rows, weights=cell_pressure * volumes) / weights
            if i % 100 == 0:
                print(f'Processed {i + 1}/{len(times)} times', flush=True)
        lower = np.array([corners[rows == j, :, axis].min() for j in range(len(positions))])
        upper = np.array([corners[rows == j, :, axis].max() for j in range(len(positions))])
        if not np.allclose(upper[:-1], lower[1:]):
            raise ValueError(f'Mesh rows must be contiguous along {args.axis}.')
        position_edges = np.r_[lower, upper[-1]]

    if not (np.isfinite(temperature).all() and np.isfinite(pressure).all()):
        raise ValueError('Temperature or pressure contains nonfinite values.')
    directory = args.output_dir if args.output_dir else input_path.parent
    directory.mkdir(parents=True, exist_ok=True)
    prefix = directory / (input_path.stem.removesuffix('_out') + '_xt')
    np.savez_compressed(str(prefix) + '.npz', position_um=positions, time_ns=times,
                        temperature_K=temperature, pressure_GPa=pressure,
                        position_edges_um=position_edges, shock_axis=args.axis,
                        source_file=str(input_path))
    time_edges = np.r_[times[0], (times[:-1] + times[1:]) / 2, times[-1]]
    fig, axes = plt.subplots(1, 2, figsize=(12, 5), sharex=True, sharey=True,
                             constrained_layout=True)
    for ax, values, title, unit, cmap in zip(
        axes, [temperature, pressure], ['Temperature', 'Pressure'], ['K', 'GPa'],
        ['inferno', 'viridis'],
    ):
        mesh = ax.pcolormesh(position_edges, time_edges, values, shading='flat',
                             cmap=cmap, rasterized=True)
        fig.colorbar(mesh, ax=ax, label=f'{title} ({unit})')
        ax.set_xlabel(r'Reference shock-direction position ($\mu$m)')
        ax.set_xlim(position_edges[0], position_edges[-1])
        ax.set_ylim(times[0], times[-1])
    axes[0].set_ylabel('Time (ns)')
    #fig.suptitle(input_path.stem.removesuffix('_out') + '\nTransverse reference-volume means; compression-positive pressure')
    fig.savefig(str(prefix) + '.png', dpi=300)
    fig.savefig(str(prefix) + '.pdf')
    plt.close(fig)
    print(f'Saved {prefix}.png, .pdf and .npz')
    print(f'{len(times)} times, {len(positions)} positions; T: {temperature.min():g}–{temperature.max():g} K; P: {pressure.min():g}–{pressure.max():g} GPa')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('inputs', nargs='*', help='Case names, case directories, or Exodus files')
    parser.add_argument('--all', action='store_true', help='Process all DIR*/*_out.e files under --root')
    parser.add_argument('--root', type=Path, default=Path('.'), help='Directory searched by --all')
    parser.add_argument('--axis', choices=list('xyz'), default='y', help='Shock direction (default: y)')
    parser.add_argument('--stride', type=int, default=1, help='Process every Nth saved time (default: 1)')
    parser.add_argument('--start-time', type=float, default=-np.inf, help='First physical time in ns, inclusive')
    parser.add_argument('--end-time', type=float, default=np.inf, help='Last physical time in ns, inclusive')
    parser.add_argument('--output-dir', type=Path, help='Save all results here instead of beside each input')
    args = parser.parse_args()
    if not args.inputs and not args.all:
        parser.error('Provide at least one input or --all.')
    if args.stride < 1 or args.start_time > args.end_time or np.isnan([args.start_time, args.end_time]).any():
        parser.error('Use a positive stride and an ordered time range.')
    inputs = list(args.inputs)
    if args.all:
        inputs.extend(sorted(args.root.glob('DIR*/*_out.e')))
    if not inputs:
        parser.error('No matching Exodus files found.')
    failures = 0
    seen = set()
    for value in inputs:
        try:
            path = resolve_input(value)
            if path in seen:
                continue
            seen.add(path)
            print(f'Processing {path}', flush=True)
            plot_case(path, args)
        except (OSError, ValueError, KeyError, TypeError) as error:
            failures += 1
            print(f'Failed {value}: {error}', file=sys.stderr, flush=True)
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
