# Synthetic particle/binder initialization only; no chemistry or mechanics solve.
# Run from this directory: CSV readers resolve filenames against the working directory.
[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 12
  ny = 12
  xmax = 10
  ymax = 10
[]
[Variables]
  [Y1]
    family = MONOMIAL
    order = CONSTANT
  []
[]
[Kernels]
  [placeholder]
    type = TimeDerivative
    variable = Y1
  []
[]
[AuxVariables]
  [density_i]
    family = MONOMIAL
    order = CONSTANT
  []
  [grainID]
    family = MONOMIAL
    order = CONSTANT
  []
  [euler1]
    family = MONOMIAL
    order = CONSTANT
  []
  [euler2]
    family = MONOMIAL
    order = CONSTANT
  []
  [euler3]
    family = MONOMIAL
    order = CONSTANT
  []
[]
[Functions]
  [loaded_microstructure]
    type = ConstantFunction
    value = 0
  []
[]
[UserObjects]
  [microstructure]
    type = PolycrystalDensityUO
    num_grains = 4
    target_grains = '1 2 3 4'
    range_in = '0 2'
    range_out = '0 2'
    generate_matrix = true
    max_grain_size = 3
    min_center_spacing = 2
    matrix_thickness = 0.3
    sizes = '2 3'
    sizes_fraction = '0.5 0.5'
    csv_fraction = fractions.csv
    csv_fraction_pore = pore_fractions.csv
    bulk_grains = true
    n_cracks = 0
    l_cracks = 0
    n_pores = 0
    bulk_MicroID = 10
    bulk_RDX_fraction = 1
    range_pore = '100 101'
    pore_RDX_fraction = 1
    euler_angles = true
    execute_on = INITIAL
  []
[]
[Postprocessors]
  [max_grain]
    type = ElementExtremeValue
    variable = grainID
    value_type = max
    execute_on = INITIAL
  []
  [min_grain]
    type = ElementExtremeValue
    variable = grainID
    value_type = min
    execute_on = INITIAL
  []
  [mean_fraction]
    type = ElementAverageValue
    variable = Y1
    execute_on = INITIAL
  []
[]
[Executioner]
  type = Transient
  dt = 1
  num_steps = 0
[]
[Outputs]
  exodus = true
  csv = true
  execute_on = INITIAL
[]
