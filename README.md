# MARLINS

**Microstructure-Aware Reactive Lagrangian INtegrated Shock Code**

MARLINS is a research application for **modeling arbitrary microstructures under shock compaction**, with a particular emphasis on the coupled mechanical, thermal, and chemical processes involved in **shock-to-detonation transition (SDT)** in heterogeneous energetic materials. Built on the [MOOSE finite-element framework](https://mooseframework.inl.gov/), it brings together microstructure representations, Lagrangian dynamics, equations of state, reaction models, and analysis utilities.

The application is intended to connect microstructural heterogeneity—particles, binder regions, porosity, and spatially varying material properties—to the evolving bulk response under shock loading. Generated structures and imported microstructure fields provide different routes to representing a material. “Arbitrary microstructures” describes this broader modeling scope; a particular geometry and material system still require a compatible representation, constitutive models, and supporting data.

The primary formulation is Lagrangian, combining mechanical deformation and compaction with thermal transport, mechanical work heating, and reactive response. Tabulated surrogate contributions provide an additional connection to microstructure-dependent heating. The accompanying tools support examination of wave propagation, pressure histories, Hugoniot-related relationships, and run-to-detonation/Pop-plot data.

The MOOSE application is named `ml`; its optimized executable is `ml-opt`. Additional constitutive and fracture-coupling objects support the broader mechanics effort, while Eulerian finite-volume components remain a development direction.

Developed and maintained by [Simon Gonzalez](mailto:gonz1075@purdue.edu), [Koslowski Group, Purdue University](https://koslowskigroup.org/).

## Contents

- [Capabilities](#capabilities)
- [Installation](#installation)
- [Verify the installation](#verify-the-installation)
- [Workflows](#workflows)
- [Repository layout](#repository-layout)
- [Current limitations and reproducibility](#current-limitations-and-reproducibility)
- [License](#license)

## Capabilities

| Area | Available components | Scope and status |
| --- | --- | --- |
| Microstructure representation | Generated particle/matrix and Voronoi-based assignments, pores/crack descriptors, imported fields, and CSV-backed density and phase fractions | Supports heterogeneous shock-compaction studies; geometry and material data must match the selected representation |
| Shock propagation and compaction | Lagrangian finite-strain dynamics, stress response, plasticity, polymer response, and artificial-viscosity terms | Custom materials combined with MOOSE solid-mechanics objects |
| Thermal response | Elastic/plastic work heating, thermal conduction coupling, and tabulated surrogate heating contributions | Couples mechanical response and microstructure-dependent heating to temperature evolution |
| Reactive response and SDT research | Reaction-rate kernels, reaction heating, and coupled mechanical/thermal/reactive formulations | Components for studying the evolution of shocked energetic materials; require compatible material data and validation |
| Equations of state | JWL-related and Mie–Grüneisen components for pressure/thermodynamic response | Model availability and required properties depend on the selected formulation |
| Shock-response analysis | Spatial profiles, time histories, EOS and shock/particle-velocity relationships, run-to-detonation and Pop-plot utilities | Research scripts with study-specific data and analysis assumptions |
| Workflow automation | YAML-driven input generation and optional Slurm submission | Supports preparation and execution of studies with external data and site-specific configuration |
| Supporting constitutive development | NH/SVK elasticity and plasticity, optional NH viscoplasticity, orientation comparisons, and fracture degradation coupling | Additional mechanics capabilities; a small mode-I integration test is bundled |
| Eulerian finite volumes | AD flux, stress, pressure, temperature, and mixture components; custom transport kernels | Development components; no complete FV example is included in the top-level `inputs/` directory |

Many custom objects use automatic differentiation (AD). Legacy non-AD implementations also remain in the source tree. Having a model implemented does not establish its validation range; the bundled tests do not validate all the physics listed above.

## Installation

### 1. Set up MOOSE

A working MOOSE development environment is required, including its compiler, MPI, PETSc, and libMesh dependencies. Follow the official [MOOSE Conda installation guide](https://mooseframework.inl.gov/getting_started/installation/conda.html) to install the supported dependency environment, obtain the MOOSE source, and build/test MOOSE. Use its current package/version instructions rather than assuming that an arbitrary MOOSE checkout and dependency environment are compatible.

The commands below assume Linux and this directory layout:

```text
~/projects/
├── moose/
└── ml/
```

The repository does not pin a supported MOOSE revision or provide a dependency lockfile. Record the MOOSE revision and environment used for a successful build.

### 2. Obtain and build MARLINS

For a new checkout:

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/Simongz1/MARLINS.git ml
```

For either a new or existing checkout, activate your MOOSE environment and build:

```bash
conda activate moose
export MOOSE_DIR="$HOME/projects/moose"
cd ~/projects/ml
make -j 4 METHOD=opt
```

If your environment has another name, replace `moose` accordingly. Choose the build parallelism to fit available memory. On an HPC system, load the site's compatible compiler/MPI/MOOSE environment instead of assuming Conda is required.

The [Makefile](Makefile) enables **all MOOSE modules** through `ALL_MODULES := yes`; this overrides the individual module switches below it. The build can therefore require substantial time and memory.

`MOOSE_DIR` can point to a different MOOSE installation. If it is unset, the Makefile first checks for `ml/moose/`, then uses the sibling `../moose/` directory. Setting it explicitly also makes the test runner's environment unambiguous.

### 3. Install optional Python tools

The C++ application does not require the plotting packages below. For input-generation and analysis utilities, use a Python environment containing:

```bash
python -m pip install numpy pandas scipy matplotlib pyyaml
```

- `generate_input.py` requires **Python 3.10 or newer** because it uses structural pattern matching, plus NumPy, pandas, and PyYAML.
- `generate_constitutive_cases.py` uses only the Python standard library.
- `px.py`, `pt.py`, and `plot_eos.py` additionally require ParaView's Python modules and VTK. Use a ParaView-enabled Python environment, such as its `pvpython` interpreter, with the needed scientific packages available there.
- Image digitization utilities use interactive Matplotlib windows and need a graphical backend.
- Automated batch submission requires Slurm and a site-specific execution environment.

## Verify the installation

After building `ml-opt`, activate its compatible MOOSE environment and run the
installation suite from the repository root:

```bash
./ml-opt --help
./run_tests --re installation -j 2
```

Expected result: **8 passed, 0 skipped, 0 failed**—four simulations and four
dependent output checks. Each simulation uses one MPI process and one thread.
The tests use generated meshes and bundled synthetic CSV fixtures, without
external research datasets.

| Test input | Expected outcome |
| --- | --- |
| [PBX initialization](test/tests/installation/pbx_initialization.i) | Particle/binder and orientation fields initialize; one CSV row at time zero, with **no timesteps**. |
| [AD thermal diffusion](test/tests/installation/ad_thermal_diffusion.i) | A random temperature field smooths over five steps to time 0.05; six CSV rows including initialization. **No decomposition kinetics or mechanics are included.** |
| [Mode-I fracture](test/tests/installation/mode1_fracture.i) | A notched 8×8 specimen undergoes opening over five steps to time 0.1; damage evolves within prescribed bounds and six CSV rows are written. |
| [Viscoplastic relaxation](test/tests/installation/viscoplastic_relaxation.i) | One element ramps to displacement 0.01 by time 20, then holds until time 200; plastic strain increases and axial stress relaxes during the hold. |

Every output check requires finite CSV values. These are installation and
integration checks, not validation of material predictions, crack paths, or
shock-to-detonation behavior.

See the [test instructions and expected outcomes](test/tests/installation/README.md)
for individual run commands, exact pass criteria, output fields, visualization
suggestions, and troubleshooting. To run just one case and its check:

```bash
./run_tests --re 'installation.*mode1_fracture' -j 1
```

Expected result for this filtered command: **2 passed, 0 skipped, 0 failed**.

On the reviewed Negishi installation, activate the MOOSE Conda environment and
unload the default OpenMPI module before running these commands:

```bash
module load conda
conda activate moose
module unload openmpi/4.1.4
export MOOSE_DIR="$HOME/projects/moose"
```

This setup is site-specific; use the compiler/MPI environment matching your own
build. Check `MOOSE_DIR` if MOOSE makefiles or the test harness cannot be found.

The existing [simple diffusion regression test](test/tests/kernels/simple_diffusion/simple_diffusion.i)
remains available, and `./run_tests -j 2` runs the full discovered suite. The
`unit/` directory contains sample GoogleTest tests.

## Workflows

### 1. Represent the microstructure

A study begins with a representation of the material's spatial heterogeneity. MARLINS supports generated assignments and imported microstructure fields, allowing particle, binder, and pore-related information to enter the material description. Depending on the formulation, heterogeneity may be represented through local density, phase fractions, material identifiers, or separately meshed regions.

The [input generator](pyscripts/generate_input.py) currently recognizes `PBX`, `RANDOM`, and `LOADED` modes and includes 2D/3D configuration paths. These offer different routes to model preparation; the application can also be configured directly through MOOSE input files for representations outside the generator's presets.

The generator prompts for a **YAML configuration filename**. Its working-directory assumptions include `csv/distributions.csv` and `distributions_template.i`, with further material data referenced by the generated input. The required CSV collection and a ready-to-use simulation YAML configuration are not included in this repository.

### 2. Study shock compaction and wave propagation

The Lagrangian formulation connects microstructure to deformation, stress, density changes, and thermal response under shock loading. Mechanical work heating and thermal transport provide the link between the evolving mechanical state and temperature. This supports research into how heterogeneous material response contributes to the spatial and temporal structure of a compression wave.

The files in [inputs/](inputs/) illustrate the coupled Lagrangian formulation. They require external model data and are not standalone installation tests. `distributions_template.i` contains substitution placeholders and must be processed before use. A study focused on mechanical or nonreactive response requires an input and material definitions consistent with that scope; the installation suite includes nonreactive thermal and mechanics cases, but no dedicated nonreactive shock-compaction example.

Custom objects are registered with `mlApp` and can be composed with the enabled MOOSE modules. Direct MOOSE inputs define the mesh, variables, equations, materials, initial/boundary conditions, solvers, and outputs.

### 3. Investigate coupled reactive response and shock-to-detonation transition

For energetic-material studies, MARLINS brings together shock-driven deformation, thermal evolution, reaction progress, and equations of state within a coupled model. The scientific focus is how heterogeneous compaction and heating relate to reaction development and the evolution of the propagating wave.

The source includes reaction-rate and heating objects, as well as tabulated surrogate contributions associated with local microstructure information. These provide complementary ingredients for representing the response at the scale of a study. Their presence does not imply that every relevant microscopic process is explicitly resolved; the interpretation depends on the chosen model and supporting data.

The analysis utilities include pressure profiles and histories, shock/particle-velocity relationships, and specialized run-to-detonation and Pop-plot analysis. These support comparison with reference observations and examination of SDT behavior. Quantitative interpretation requires model-specific verification and validation; the bundled diffusion test does not establish predictive accuracy for SDT.

### 4. Organize simulation studies

The Python generator provides a configuration-driven route to preparing inputs, while direct MOOSE inputs support more customized studies. Reproducibility depends on retaining the microstructure representation, external tables, model definitions, random seeds, and numerical settings together with the results.

The generator can prepare and submit a Slurm job when its `gen_and_run` option is enabled. This path performs submission, not just file generation. The [batch template](bash/sbatch_template) assumes a relative executable location and site-specific scheduler settings; review those assumptions before using it.

### 5. Analyze shock-response results

| Utility | Intended purpose | Main dependencies/assumptions |
| --- | --- | --- |
| [px.py](pyscripts/px.py) | Spatial field profiles at selected times | ParaView/VTK, NumPy, Matplotlib; expected Exodus fields and geometry |
| [pt.py](pyscripts/pt.py) | Field histories at selected spatial samples | ParaView/VTK, NumPy, Matplotlib; expected Exodus fields and geometry |
| [plot_eos.py](pyscripts/plot_eos.py) | Sample and plot EOS-related field relationships | ParaView/VTK, NumPy, pandas, SciPy, Matplotlib; optional fit CSVs |
| [fit_eos.py](pyscripts/fit_eos.py) | Digitize reference figures and fit EOS-related curves | NumPy, SciPy, interactive Matplotlib; source images |
| [usup.py](pyscripts/usup.py) | Digitize and fit shock/particle-velocity relationships | NumPy, interactive Matplotlib; source image |
| [r2d.py](pyscripts/r2d.py) | Specialized tracking-data and run-to-detonation/Pop-plot analysis | NumPy, pandas, SciPy, Matplotlib; study-specific filenames and assumptions |

These are research utilities, not a uniform command-line package. Several prompt interactively; others contain study-specific settings. Review the expected field names, point/cell association, paths, and units. `fit_eos.py` also contains an optional transfer path tied to a specific cluster account.

### 6. Extend the mechanics or numerical formulation

Supporting mechanics development includes [ADElastoPlastic](src/fracture_materials/ADElastoPlastic.C), with NH/SVK constitutive branches, optional NH viscoplasticity, and degradation/history properties for fracture coupling. The [constitutive comparison utility](pyscripts/generate_constitutive_cases.py) creates NH and unrotated/rotated SVK variants from a user-supplied mechanics template and named ASCII Gmsh mesh. The comparison utility's template and mesh are not bundled. A self-contained mode-I coupling example is available in the [installation tests](test/tests/installation/README.md).

The [finite-volume kernels](src/fvkernels/) and [functor materials](src/fvmaterials/) provide components for exploring Eulerian transport and mixture formulations. This remains a development workflow requiring a compatible input and independent verification; the current top-level examples do not include a complete FV cavity-compression case.

## Repository layout

| Path | Purpose |
| --- | --- |
| `src/`, `include/` | Active C++ implementations and headers |
| `src/fracture_materials/` | Constitutive mechanics with degradation/fracture coupling |
| `src/material/`, `src/material2/` | Heating, reaction, stress, and EOS-related materials |
| `src/kernel/` | Custom finite-element kernels, including a `deprecated/` subtree |
| `src/fvkernels/`, `src/fvmaterials/` | Finite-volume development components |
| `src/ics/`, `src/auxkernels/`, `src/userobjects/` | Microstructure initialization and field assignment |
| `inputs/` | Lagrangian input template and example input requiring external data |
| `pyscripts/`, `bash/` | Generation, analysis, and batch-job utilities |
| `test/`, `unit/` | Diffusion regression, installation integration tests, and sample unit tests |
| `doc/` | MooseDocs scaffolding; currently minimal project documentation |
| `fromBell/` | Separate legacy application snapshot, including older inputs |
| `original/`, if present | Local duplicate source tree; not tracked in the reviewed checkout |
| `build/`, `lib/`, `ml-opt` | Local build products |

The root Makefile builds the top-level application. Treat nested application snapshots as reference material, not as automatically interchangeable examples for the current executable.

## Current limitations and reproducibility

- External material/microstructure CSVs, a simulation YAML example, and the constitutive generator's mesh/template are not bundled.
- The repository does not specify a tested MOOSE revision, Python dependency versions, or a complete supported-platform matrix.
- Automated coverage includes basic diffusion, installation integration checks, and sample unit tests; custom physics still require dedicated verification and validation.
- Scheduler settings, transfer destinations, data filenames, and some analysis settings are specific to the original research environment.
- Model parameters and scripts use workflow-specific units. Check dimensional consistency across geometry, stiffness, density, time, temperature, and imported tables.

For a reproducible study, retain the MARLINS and MOOSE revisions, environment/package versions, complete input and external data, random seeds, and solver/output settings alongside the results.

## License

See [LICENSE](LICENSE) for the GNU Lesser General Public License, version 2.1. Consult individual source notices and dependency licenses where applicable.
