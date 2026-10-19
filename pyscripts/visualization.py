import argparse
import re
from pathlib import Path
import pyvista as pv
import numpy as np

VIDEO_FPS = 60
WINDOW_SIZE = (1920, 1080)
CAMERA_VIEWS = {
    "iso": ((1.0, 1.0, 1.0), (0.0, 0.0, 1.0)),
    "xy": ((0.0, 0.0, 1.0), (0.0, 1.0, 0.0)),
    "xz": ((0.0, -1.0, 0.0), (0.0, 0.0, 1.0)),
    "yz": ((1.0, 0.0, 0.0), (0.0, 0.0, 1.0)),
}

def leaf_blocks(dataset):
    """Yield all non-MultiBlock datasets recursively."""
    if isinstance(dataset, pv.MultiBlock):
        for block in dataset:
            if block is not None:
                yield from leaf_blocks(block)
    else:
        yield dataset


def blocks_with_array(data, array_name, association, time_index):
    """Return the leaf blocks containing the requested result array."""
    valid_blocks = []

    for block in leaf_blocks(data):
        arrays = block.point_data if association == "point" else block.cell_data

        if array_name in arrays:
            valid_blocks.append(block)

    if not valid_blocks:
        raise KeyError(
            f"{array_name!r} is listed by the reader but is absent from "
            f"all loaded blocks at timestep {time_index}."
        )

    return valid_blocks


def add_timestep(
    plotter,
    reader,
    times,
    time_index,
    array_name,
    association,
    color_limits=None,
):
    """Load and add one timestep to a plotter."""
    reader.set_active_time_point(time_index)
    data = reader.read()
    valid_blocks = blocks_with_array(
        data, array_name, association, time_index
    )

    #colorbar arguments
    sarg = dict(
        position_x = 0.9,
        position_y = 0.01,
        vertical = True
    )

    #turn off ambient light

    for block in valid_blocks:
        actor = plotter.add_mesh(
            block,
            scalars=array_name,
            preference=association,
            cmap=f"{colormap_name}{'_r' if invert == 'y' else ''}",
            clim=color_limits,
            scalar_bar_args=sarg
        )

        #turn off light
        actor.prop.ambient = 0.0

    plotter.add_text(
        f"{array_name}, time = {times[time_index]:g}",
        font_size=12,
    )


def set_camera_view(plotter, view):
    """Aim the camera at the requested coordinate plane and fit the data."""
    direction, view_up = CAMERA_VIEWS[view]
    plotter.view_vector(direction, viewup=view_up)

    # Plane views should not introduce perspective distortion.  Applying the
    # view after meshes are added also lets PyVista calculate a useful camera
    # distance instead of aiming at the default, empty-scene bounds.
    if view == "iso":
        plotter.disable_parallel_projection()
    else:
        plotter.enable_parallel_projection()

    plotter.reset_camera()


def capture_camera(plotter):
    """Capture camera framing, including projection-specific zoom."""
    return {
        "position": plotter.camera_position,
        "parallel_scale": plotter.camera.parallel_scale,
        "view_angle": plotter.camera.view_angle,
    }


def restore_camera(plotter, camera_state, view):
    """Restore fixed framing after actors have been replaced."""
    plotter.camera_position = camera_state["position"]

    if view == "iso":
        plotter.disable_parallel_projection()
        plotter.camera.view_angle = camera_state["view_angle"]
    else:
        plotter.enable_parallel_projection()
        plotter.camera.parallel_scale = camera_state["parallel_scale"]

    # Refresh only the near/far clipping planes, without refitting the view.
    plotter.reset_camera_clipping_range()


def camera_for_timestep(
    reader,
    times,
    time_index,
    array_name,
    association,
    view,
    color_limits=None,
):
    """Fit the camera once using a reference timestep."""
    plotter = pv.Plotter(off_screen=True, window_size=WINDOW_SIZE)
    try:
        add_timestep(
            plotter,
            reader,
            times,
            time_index,
            array_name,
            association,
            color_limits,
        )
        set_camera_view(plotter, view)
        return capture_camera(plotter)
    finally:
        plotter.close()


def save_figure(
    reader,
    times,
    time_index,
    array_name,
    association,
    output_path,
    view,
    camera_state,
    color_limits=None,
):
    """Render one timestep to a PNG file."""
    plotter = pv.Plotter(off_screen=True, window_size=WINDOW_SIZE)
    add_timestep(
        plotter,
        reader,
        times,
        time_index,
        array_name,
        association,
        color_limits,
    )
    restore_camera(plotter, camera_state, view)
    plotter.show(screenshot=str(output_path))


def save_video(
    reader,
    times,
    time_indices,
    array_name,
    association,
    output_path,
    view,
    color_limits=None,
):
    """Render selected timesteps to an MP4 video at 60 frames per second."""
    plotter = pv.Plotter(off_screen=True, window_size=WINDOW_SIZE)
    plotter.open_movie(str(output_path), framerate=VIDEO_FPS)
    camera_state = None
    frame_count = len(time_indices)

    try:
        for frame_number, time_index in enumerate(time_indices, start=1):
            plotter.clear()
            add_timestep(
                plotter,
                reader,
                times,
                time_index,
                array_name,
                association,
                color_limits,
            )

            if camera_state is None:
                set_camera_view(plotter, view)
                camera_state = capture_camera(plotter)
            else:
                restore_camera(plotter, camera_state, view)

            plotter.write_frame()
            print(
                f"Rendered frame {frame_number}/{frame_count} "
                f"(timestep {time_index})"
            )
    finally:
        plotter.close()


parser = argparse.ArgumentParser(description="Render an Exodus result variable.")
parser.add_argument("--input", type=Path, help="path to an *_out.e file")
parser.add_argument("--variable", help="point or cell variable to render")
parser.add_argument(
    "--view",
    choices=CAMERA_VIEWS,
    default=None,
    help="camera view: isometric or normal to a coordinate plane (default: iso)",
)
parser.add_argument(
    "--clim",
    nargs=2,
    type=float,
    metavar=("MIN", "MAX"),
    help="fixed colormap range (default: automatically determined)",
)
time_options = parser.add_mutually_exclusive_group()
time_options.add_argument(
    "--animate",
    action="store_true",
    help="render an animation without prompting",
)
time_options.add_argument(
    "--latest",
    action="store_true",
    help="save the latest timestep without prompting",
)
time_options.add_argument(
    "--timesteps",
    nargs="+",
    type=int,
    metavar="INDEX",
    help="save one image for each specified timestep index",
)
parser.add_argument(
    "--start-step",
    type=int,
    help="first timestep index to include in the animation (default: 0)",
)
parser.add_argument(
    "--end-step",
    type=int,
    help="last timestep index to include in the animation, inclusive",
)
parser.add_argument(
    "--stride",
    type=int,
    help="interval between animation timestep indices (default: 1)",
)
args = parser.parse_args()

if args.input is None:
    file_name = input("Enter the file name without extension: ").strip()
    base_dir = Path("/scratch/negishi/gonz1075/mist2/pbx_corrected")
    file_path = base_dir / f"DIR{file_name}" / f"{file_name}_out.e"
else:
    file_path = args.input.expanduser().resolve()
    file_name = file_path.name
    if file_name.endswith("_out.e"):
        file_name = file_name[:-6]
    else:
        file_name = file_path.stem

if args.view is not None:
    camera_view = args.view
elif args.input is None:
    camera_view = input(
        "Camera view [iso/xy/xz/yz] (default: iso): "
    ).strip().lower() or "iso"
    if camera_view not in CAMERA_VIEWS:
        raise ValueError(
            f"Unknown camera view {camera_view!r}; choose from "
            f"{', '.join(CAMERA_VIEWS)}."
        )
else:
    camera_view = "iso"

array_name = args.variable or input("Enter field to plot: ").strip()
color_limits = tuple(args.clim) if args.clim is not None else None
if args.input is None and color_limits is None:

    #get colormap name
    colormap_name = input("Enter colormap name (default: jet): ").strip() or "jet"
    clim_value = input(
        "Provide colormap MIN MAX, or press Enter for automatic limits: "
    ).strip()

    #ask if colorbar should be inverted
    invert = input("Invert colorbar? (y or n): ")
    if clim_value:
        try:
            color_limits = tuple(
                float(value)
                for value in clim_value.replace(",", " ").split()
            )
        except ValueError:
            raise ValueError("Colormap limits must be two numbers: MIN MAX.")
        if len(color_limits) != 2:
            raise ValueError("Colormap limits must contain exactly two numbers.")

if color_limits is not None and color_limits[0] >= color_limits[1]:
    raise ValueError("Colormap MIN must be less than MAX.")

animate = args.animate or (
    args.latest is False
    and args.timesteps is None
    and input("Animate? [y/N] ").strip().lower() in {"y", "yes"}
)

if not file_path.is_file():
    raise FileNotFoundError(file_path)

reader = pv.get_reader(file_path)

print("Point arrays:", reader.point_array_names)
print("Cell arrays:", reader.cell_array_names)

if array_name in reader.point_array_names:
    association = "point"
    reader.enable_point_array(array_name)
elif array_name in reader.cell_array_names:
    association = "cell"
    reader.enable_cell_array(array_name)
else:
    raise KeyError(
        f"{array_name!r} was not found.\n"
        f"Point arrays: {reader.point_array_names}\n"
        f"Cell arrays: {reader.cell_array_names}"
    )

times = list(reader.time_values)
if not times:
    raise ValueError("The input file does not contain any time values.")

print(f"There are {len(times)} available time values.")

output_dir = file_path.parent

if animate:
    print("Valid timestep indices:", 0, "through", len(times) - 1)

    if args.start_step is None:
        value = input("Animation start step (default: 0): ").strip()
        start_step = int(value) if value else 0
    else:
        start_step = args.start_step

    if args.end_step is None:
        value = input(
            f"Animation end step, inclusive (default: {len(times) - 1}): "
        ).strip()
        end_step = int(value) if value else len(times) - 1
    else:
        end_step = args.end_step

    if args.stride is None:
        value = input("Animation frame stride (default: 1): ").strip()
        stride = int(value) if value else 1
    else:
        stride = args.stride

    if not 0 <= start_step < len(times):
        raise IndexError(
            f"Start step {start_step} is outside 0 through {len(times) - 1}."
        )
    if not 0 <= end_step < len(times):
        raise IndexError(
            f"End step {end_step} is outside 0 through {len(times) - 1}."
        )
    if end_step < start_step:
        raise ValueError("Animation end step must be at least the start step.")
    if stride <= 0:
        raise ValueError("Animation frame stride must be greater than zero.")

    time_indices = list(range(start_step, end_step + 1, stride))
    output_path = output_dir / f"{file_name}_{array_name}.mp4"
    save_video(
        reader,
        times,
        time_indices,
        array_name,
        association,
        output_path,
        camera_view,
        color_limits,
    )
    print(f"Saved {VIDEO_FPS} fps video to: {output_path}")
else:
    print("Valid timestep indices:", 0, "through", len(times) - 1)
    if args.latest:
        time_indices = [len(times) - 1]
    elif args.timesteps is not None:
        time_indices = args.timesteps
    else:
        value = input(
            "Provide one or more timestep indices (space or comma separated): "
        ).strip()
        try:
            time_indices = [int(item) for item in re.split(r"[\s,]+", value) if item]
        except ValueError:
            raise ValueError("Timestep indices must be integers.")

    if not time_indices:
        raise ValueError("At least one timestep index is required.")

    invalid_indices = [
        time_index
        for time_index in time_indices
        if not 0 <= time_index < len(times)
    ]
    if invalid_indices:
        raise IndexError(
            f"Invalid timestep indices {invalid_indices}; expected each index "
            f"0 through {len(times) - 1}."
        )

    # Use the first requested timestep to establish one camera for every PNG.
    camera_state = camera_for_timestep(
        reader,
        times,
        time_indices[0],
        array_name,
        association,
        camera_view,
        color_limits,
    )

    for time_index in time_indices:
        output_path = output_dir / f"{file_name}_{array_name}_{time_index}.png"
        save_figure(
            reader,
            times,
            time_index,
            array_name,
            association,
            output_path,
            camera_view,
            camera_state,
            color_limits,
        )
        print(f"Saved figure to: {output_path}")

#directly crop the figures here

su.run(['python', 'crop.py'])
