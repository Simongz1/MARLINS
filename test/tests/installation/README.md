# Installation integration tests

These small, self-contained cases check application setup, object registration,
material/property coupling, CSV access, solver execution, and output generation.
They are not calibrated material benchmarks or physical-validation tests.

| Input | Coverage | Execution |
| --- | --- | --- |
| `pbx_initialization.i` | Particle/binder generation with `PolycrystalDensityUO`, orientations, and synthetic CSV fraction data | Initialization only; `num_steps = 0`, one output at time zero |
| `ad_thermal_diffusion.i` | Random temperature field, AD heat conduction and heat capacity, insulated boundaries | Five thermal steps; **nonreactive alternative, no decomposition kinetics** |
| `mode1_fracture.i` | Structure adapted from `kuhn.i`: finite strain, `ADElastoPlastic`, degradation/history energy, AD Allen–Cahn evolution | Five opening steps on a 8×8 mesh with a horizontal diffuse notch |
| `viscoplastic_relaxation.i` | Structure adapted from `vp_T300.i`: NH viscoplastic flow at fixed temperature | One QUAD4; ramp to displacement 0.01 over 20 time units, hold to 200 |

The reference inputs were read from `/scratch/negishi/gonz1075/fracture/` during
creation. They and their external meshes are not runtime dependencies.

## Run

Activate the same MOOSE environment used to build `ml-opt`, then from the
application root:

```bash
./run_tests --re installation -j 2
```

The four simulation tests each have a dependent output check (eight harness
entries total). They are restricted to one MPI process and one thread. Run from
the application root so unrelated local duplicate application trees are not the
starting directory.

To run one input manually:

```bash
cd test/tests/installation
../../../ml-opt -i pbx_initialization.i --error --error-unused
python3 check_outputs.py pbx_initialization
```

Replace `pbx_initialization` with the other input's basename as needed. Run from
this directory: the custom CSV reader resolves relative filenames against the
working directory. No Python generator or external research data are required;
the input itself generates the microstructure during application initialization.
The synthetic CSV fixtures are single numeric rows without headers.

On the reviewed Negishi installation, the executable requires the MOOSE Conda
environment and the default OpenMPI module must be unloaded:

```bash
module load conda
conda activate moose
module unload openmpi/4.1.4
```

These commands are site-specific. Do not mix the site's OpenMPI launcher/libraries
with this MPICH-based MOOSE environment.

## What is checked

- Microstructure: successful initialization, both binder and particle assignments,
  a heterogeneous fraction field, and no advancement beyond time zero.
- Thermal: finite output, completion of five steps, a nonuniform initial field,
  and a decreasing temperature range.
- Fracture: initialization of the notch, completion of opening steps, finite
  output, and activation of the damage field within its bounds.
- Viscoplasticity: completion of the hold, fixed displacement during the hold,
  continuing accumulated flow, decreasing axial stress, and positive elastic
  and plastic deformation-gradient determinants.

`check_outputs.py` checks these execution signatures without comparing calibrated
stress–strain curves, crack paths, or experimental measurements. Exodus files
provide visual inspection; CSV files provide the automatic checks.

The fracture case uses top/bottom opening normal to a horizontal notch, with a
left-edge horizontal constraint. Unlike the reference input, it includes
old-value lower bounds on damage and an upper bound of one using PETSc's VI
solver, preventing notch healing. Its mesh, loading, and illustrative fracture
properties are chosen for a short integration test, not resolved crack-growth
predictions. The viscoplasticity case retains the reference's inactive damage
kernels to isolate relaxation, uses a one-unit timestep, and uses serial LU
without requiring MUMPS.

The thermal input deliberately covers diffusion only. It does not implement the
requested energetic-material thermal-decomposition case.
