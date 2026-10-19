#!/usr/bin/env pvpython
"""Compute reacted volume as a fraction of shocked volume in Exodus output.

Run this script with ParaView's Python interpreter (``pvpython``). Point-data
variables, such as Y1 in the MOOSE inputs in this repository, are averaged to
cell centers before the threshold is applied. The reported geometric measure
is volume for a 3-D mesh and area for a 2-D mesh.
"""

import argparse
import csv
import math
import sys
from pathlib import Path

from paraview import servermanager
from paraview.simple import (
    Delete,
    ExodusIIReader,
    IntegrateVariables,
    PointDatatoCellData,
    Threshold,
)

import matplotlib.pyplot as plt

plt.rcParams.update({
        "font.family": "serif",
        "font.serif": ["Times New Roman", "Times", "Nimbus Roman", "DejaVu Serif"],
})

def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Compute reacted_volume / shocked_volume at selected Exodus "
            "output times."
        )
    )
    parser.add_argument(
        "input",
        nargs="?",
        help=(
            "Exodus file, or the case name used by DIR<case>/<case>_out.e "
            "(prompted for when omitted)"
        ),
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="output CSV path (default: <input stem>_lambda.csv)",
    )
    parser.add_argument(
        "--pressure-variable",
        default="s_pressure",
        help="pressure/stress variable (default: s_pressure)",
    )
    parser.add_argument(
        "--pressure-threshold",
        type=float,
        default=-0.5,
        help="cells below this value are shocked (default: -0.5)",
    )
    parser.add_argument(
        "--reactant-variable",
        default="Y1",
        help="unreacted mass-fraction variable (default: Y1)",
    )
    parser.add_argument(
        "--reacted-threshold",
        type=float,
        default=0.025,
        help="cells below this value are reacted (default: 0.025)",
    )
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument(
        "--time-indices",
        nargs="+",
        type=int,
        metavar="INDEX",
        help="zero-based output timestep indices to process",
    )
    selection.add_argument(
        "--times",
        nargs="+",
        type=float,
        metavar="TIME",
        help="physical times to process (the nearest saved times are used)",
    )
    parser.add_argument(
        "--start",
        "--initial-time",
        "--initial-timestamp",
        "--start-time",
        dest="start",
        type=int,
        default=0,
        help=(
            "first saved timestep index, inclusive, when processing a "
            "range (default: 0)"
        ),
    )
    parser.add_argument(
        "--stop",
        "--final-time",
        "--final-timestamp",
        "--end-time",
        dest="stop",
        type=int,
        help=(
            "last saved timestep index, inclusive, when processing a "
            "range (default: final timestep)"
        ),
    )
    parser.add_argument(
        "--stride",
        "--frame-stride",
        "--every",
        dest="frame_stride",
        type=int,
        default=1,
        help=(
            "process every Nth saved frame when using a timestep range "
            "(default: 1; --every is an alias)"
        ),
    )
    parser.add_argument(
        "--plot",
        "--generate-plot",
        action="store_true",
        help=(
            "save a PNG of reacted fraction versus time next to the "
            "source Exodus file"
        ),
    )
    return parser.parse_args()


def resolve_input(value):
    """Accept either a direct Exodus path or the repository's case-name form."""
    if value is None:
        value = input("Provide Exodus file or case name: ").strip()

    direct = Path(value).expanduser()
    if direct.is_file():
        return direct.resolve()

    legacy = Path("DIR{}".format(value)) / "{}_out.e".format(value)
    if legacy.is_file():
        return legacy.resolve()

    raise FileNotFoundError(
        "Could not find {!r} or {!s}".format(value, legacy)
    )


def selected_time_indices(args, times):
    if not times:
        raise RuntimeError("The Exodus reader reported no output times.")
    if args.frame_stride <= 0:
        raise ValueError("--stride must be a positive integer")

    if (args.time_indices is not None or args.times is not None) and (
        args.start != 0 or args.stop is not None
    ):
        raise ValueError(
            "range bounds cannot be combined with --time-indices or --times"
        )

    if args.time_indices is not None:
        indices = args.time_indices
    elif args.times is not None:
        indices = [
            min(range(len(times)), key=lambda i: abs(times[i] - requested))
            for requested in args.times
        ]
        # Do not process the same saved timestep twice.
        indices = list(dict.fromkeys(indices))
    else:
        stop = len(times) - 1 if args.stop is None else args.stop
        indices = list(range(args.start, stop + 1, args.frame_stride))

    if not indices:
        raise ValueError("The requested timestep selection is empty")

    invalid = [i for i in indices if i < 0 or i >= len(times)]
    if invalid:
        raise IndexError(
            "Timestep indices out of range [0, {}]: {}".format(
                len(times) - 1, invalid
            )
        )
    return indices


def array_association(source, name):
    """Return POINTS or CELLS for an array visible on a pipeline source."""
    point_info = source.GetPointDataInformation()
    cell_info = source.GetCellDataInformation()
    if point_info.GetArray(name) is not None:
        return "POINTS"
    if cell_info.GetArray(name) is not None:
        return "CELLS"
    return None


def set_below_threshold(threshold, value):
    """Configure a Threshold proxy across ParaView 5.9+ API variants."""
    try:
        threshold.ThresholdMethod = "Below Lower Threshold"
        threshold.LowerThreshold = value
    except Exception:
        # ParaView 5.9 uses ThresholdRange rather than ThresholdMethod.
        threshold.ThresholdRange = [-sys.float_info.max, value]


def make_threshold(source, variable, value):
    threshold = Threshold(Input=source)
    threshold.Scalars = ["CELLS", variable]
    set_below_threshold(threshold, value)
    return threshold


def integrated_measure(integrator, time_value):
    """Return Volume, Area, or Length from an IntegrateVariables result."""
    integrator.UpdatePipeline(time=time_value)
    result = servermanager.Fetch(integrator)
    if result is None or result.GetNumberOfCells() == 0:
        return 0.0, "measure"

    cell_data = result.GetCellData()
    for name in ("Volume", "Area", "Length"):
        array = cell_data.GetArray(name)
        if array is not None and array.GetNumberOfTuples():
            return float(array.GetTuple1(0)), name.lower()

    # An empty threshold selection can produce a single result cell without a
    # geometric-measure array in some ParaView releases.
    return 0.0, "measure"


def save_fraction_plot(
    rows,
    plot_path,
    pressure_threshold,
    reactant_variable,
    reacted_threshold,
):
    """Plot reacted/shocked volume fraction against physical time."""
    try:
        import matplotlib
    except ImportError as error:
        raise RuntimeError(
            "--plot requires matplotlib in the pvpython environment"
        ) from error

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    figure, axis = plt.subplots()
    axis.plot(
        [row["time"] for row in rows],
        [row["reacted_fraction"] for row in rows],
        'k-',
        linewidth=2,
    )
    axis.set_xlabel("Time (ns)", fontsize=20)
    axis.set_ylabel("$v/v_r$", fontsize=20)
    plt.xticks(fontsize=20)
    plt.yticks(fontsize=20)
    axis.grid(False)
    figure.tight_layout()
    figure.savefig(str(plot_path), dpi=300)
    plt.close(figure)


def main():
    args = parse_args()
    input_path = resolve_input(args.input)
    output_path = (
        args.output
        if args.output is not None
        else input_path.with_name("{}_lambda.csv".format(input_path.stem))
    )
    # Figures always stay with their source Exodus output, even when the CSV
    # destination is overridden with --output.
    plot_path = input_path.with_name("{}_lambda.png".format(input_path.stem))

    reader = ExodusIIReader(FileName=[str(input_path)])
    reader.UpdatePipelineInformation()
    times = list(reader.TimestepValues)
    indices = selected_time_indices(args, times)

    # Update once before querying associations. Exodus output from this project
    # stores Y1 as point data and s_pressure as cell data.
    reader.UpdatePipeline(time=times[indices[0]])
    associations = {
        args.pressure_variable: array_association(reader, args.pressure_variable),
        args.reactant_variable: array_association(reader, args.reactant_variable),
    }
    missing = [
        name for name, association in associations.items() if association is None
    ]
    if missing:
        raise KeyError(
            "Variables not found in the loaded Exodus output: {}".format(
                ", ".join(missing)
            )
        )

    # Convert nodal fields to per-cell averages. Existing elemental fields pass
    # through unchanged, giving both threshold variables a common association.
    cell_data = PointDatatoCellData(Input=reader)
    cell_data.ProcessAllArrays = 1
    try:
        cell_data.PassPointData = 0
    except Exception:
        pass

    shocked = make_threshold(
        cell_data, args.pressure_variable, args.pressure_threshold
    )
    reacted = make_threshold(
        cell_data, args.reactant_variable, args.reacted_threshold
    )
    shocked_integral = IntegrateVariables(Input=shocked)
    reacted_integral = IntegrateVariables(Input=reacted)

    rows = []
    measure_name = None
    for count, index in enumerate(indices, start=1):
        time_value = times[index]
        shocked_measure, shocked_name = integrated_measure(
            shocked_integral, time_value
        )
        reacted_measure, reacted_name = integrated_measure(
            reacted_integral, time_value
        )
        measure_name = (
            shocked_name if shocked_name != "measure" else reacted_name
        )
        fraction = (
            reacted_measure / shocked_measure
            if shocked_measure > 0.0
            else math.nan
        )
        rows.append(
            {
                "time_index": index,
                "time": time_value,
                "shocked_volume": shocked_measure,
                "reacted_volume": reacted_measure,
                "reacted_fraction": fraction,
            }
        )
        print(
            "[{}/{}] index={} time={:.9g} shocked={:.9g} "
            "reacted={:.9g} reacted/shocked={:.9g}".format(
                count,
                len(indices),
                index,
                time_value,
                shocked_measure,
                reacted_measure,
                fraction,
            )
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="") as stream:
        writer = csv.DictWriter(
            stream,
            fieldnames=(
                "time_index",
                "time",
                "shocked_volume",
                "reacted_volume",
                "reacted_fraction",
            ),
        )
        writer.writeheader()
        writer.writerows(rows)

    if args.plot:
        save_fraction_plot(
            rows,
            plot_path,
            args.pressure_threshold,
            args.reactant_variable,
            args.reacted_threshold,
        )

    print(
        "Wrote {} rows to {} (geometric measure: {}).".format(
            len(rows), output_path, measure_name or "unknown"
        )
    )
    if args.plot:
        print("Saved reacted-fraction plot to {}.".format(plot_path))

    for proxy in (
        reacted_integral,
        shocked_integral,
        reacted,
        shocked,
        cell_data,
        reader,
    ):
        Delete(proxy)


if __name__ == "__main__":
    main()
