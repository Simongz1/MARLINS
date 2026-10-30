# Integer microstructure ID workflow

This opt-in workflow adds new objects; it does not replace or modify the original classes.

| Existing object | New independent copy |
|---|---|
| `PolycrystalDensityUOV2` | `PolycrystalDensityIntegerUO` |
| `PolycrystalDensityUO` | `PolycrystalDensityIntegerLegacyUO` |
| `PolycrystalDensityAux` | `PolycrystalIntegerDensityAux` |
| `PolycrystalFractionAux` | `PolycrystalIntegerFractionAux` |
| `ADComputeIntPValRDXMISTERnetNSFull` | `ADComputeIntPValRDXMISTERnetInteger` |

`MicrostructureIDAux` is a new visualization reader. `MicrostructureID.h` provides shared original-region lookup and bounds diagnostics.

## Storage and AMR

Use an initially unrefined, replicated mesh constructed with:

```text
[Mesh]
  parallel_type = REPLICATED
  [generated]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 80
    ny = 300
    xmax = 80
    ymax = 300
    extra_element_integers = microstructure_id
  []
[]
```

The integer initializer assigns `microstructure_id` to each original coarse element. It otherwise retains V2's center search, random sampling, pore selection and shared-node initialization approach.

Readers always look up the reference-mesh element, ascend its parent chain, and read the original element's integer label. This is deliberate: adaptive children represent the same physical surrogate region as their original coarse ancestor. A child's projected `density_i` value is never used for any table lookup. The same reference metadata is used even when a reader evaluates on the displaced mesh.

The mesh generator registers the label before material and AuxKernel construction. Only transient refinement is supported; the initializer rejects an initially refined mesh rather than assigning conflicting IDs to a common original ancestor. Both the original mesh ancestry and extra integer metadata must be retained on restart.

As in V2, initialization occurs before normal Function initial setup. If `use_loaded_microstructure = true`, provide a function already evaluable at that stage (the regression uses `PiecewiseConstant`). A `ParsedFunction` evaluated here before its setup is not supported by this initializer. The prepared production input uses the existing generated microstructure path (`use_loaded_microstructure = false`).

## Integer selection and numerical differences

The legacy initializer produces fractional binder IDs. The legacy density/fraction AuxKernels truncate them, while the initializer's species lookup and the prediction material round them. There is no single integer conversion that preserves both inconsistent interpretations.

The new initializer **truncates generated binder IDs once**, preserving the legacy density/fraction selection. All new consumers, including species initialization and temperature prediction, then use that same integer. This can change species initialization and surrogate predictions relative to the legacy rounding paths. Bulk and pore IDs are already integers and remain unchanged. Do not interpret a different trajectory as an otherwise bit-identical solver comparison.

For comparison to the failing input that uses the original `PolycrystalDensityUO`, the prepared production copy instead selects `PolycrystalDensityIntegerLegacyUO`. That separate legacy copy retains the original random draws, pore selection and shared-node Y1 assignment. It stores two integer labels: `microstructure_id` is the truncated index for density/fraction readers, and `legacy_prediction_id` is the rounded index for the prediction material. This deliberately preserves the old code's inconsistent rounding conventions while removing floating-point projection from both lookup paths. Both names must be registered in `extra_element_integers`. Neither original initializer is modified.

Raw density/fraction CSV rows retain the existing layout: column zero is a velocity/header value, ordinary IDs index their columns directly, and pore IDs use `id - first_pore_id + 1`. The predictor strips the velocity column and uses the corresponding zero-based pore index. Its copied pore-time lookup now uses the pore velocity interval and ratio; its local pore ID is always initialized. Invalid columns produce contextual errors instead of clamping to a different microstructure.

## Input wiring

`inputs/testing_current_up1.2_integer_ids.i` is a separate copy of the failing interface-AMR input using the legacy-compatible integer initializer described above. Its physics, solver settings, AMR marker and table paths are retained. Changes are the mesh generator/label registration, new object types, replacement of reader `density_i` couplings with `microstructure_id_name`, and an integer-ID visualization AuxKernel. The generated mesh's default bottom/right/top/left boundaries replace the equivalent explicit boundary-name list.

Keep `density_i` as `CONSTANT MONOMIAL` for viewing only:

```text
[AuxKernels]
  [display_microstructure_id]
    type = MicrostructureIDAux
    variable = density_i
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
```

The density and fraction copies must be elemental AuxKernels. Their table files and scaling retain their original parameters. The predictor retains the original temperature, time, distribution and takeover interfaces, except that it takes `microstructure_id_name` instead of a `density_i` coupling. There is no neural-network integration in this change.

## Restart and migration

Start a **fresh run** with the integer-ID input. A checkpoint from the old real-valued-ID workflow has no authoritative integer metadata and is not a supported migration source. Recover subsequent runs from checkpoints produced with the new workflow, keeping its mesh label and original-region interpretation.

## Validation

Validated using the `moose` conda environment and the rebuilt application:

- Serial binder/bulk/pore lookup during 3 -> 12 -> 3 -> 12 element adaptation.
- Checkpoint recovery from step 4 and continuation through step 6, including return to the coarse mesh.
- Displaced-mesh lookup of the authoritative reference-region IDs during the same adaptation sequence.
- The same regression with two MPI ranks.
- An invalid ID (`93`) rejected with a contextual message.
- `--check-input` on `inputs/testing_current_up1.2_integer_ids.i`.

In each value regression, mean ID stayed 67, mean scaled density stayed 1.44, and mean reactive fraction stayed 5/6. The production shock simulation was not run, and its predictor's full table-response behavior has not been numerically regression-tested against a complete legacy run.

Test inputs and the CSV checker are under `test/tests/userobjects/integer_microstructure/`. Validation terminal output is saved in `logs/integer_ids_*.log`.

The build initially picked up system OpenMPI headers through `CPATH`, conflicting with conda MPICH. Activating the `moose` environment and unsetting external `CPATH` and `LIBRARY_PATH` resolved compilation. For test execution, conda's `lib` directory was placed first in `LD_LIBRARY_PATH`. MPI endpoint creation required running outside the filesystem/network sandbox.
