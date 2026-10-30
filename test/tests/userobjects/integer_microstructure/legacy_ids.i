[Mesh]
  parallel_type = REPLICATED
  [generated]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 3
    ny = 1
    xmax = 3
    ymax = 1
    extra_element_integers = 'microstructure_id legacy_prediction_id'
  []
[]

[GlobalParams]
  bulk_grains = true
  bulk_MicroID = 99
  bulk_RDX_fraction = 1
  pore_RDX_fraction = 1
  range_pore = '101 101'
  use_loaded_microstructure = true
  csv_fraction_pore = pore_fractions.csv
  csv_density_pore = pore_densities.csv
[]

[Variables]
  [Y1]
  []
[]
[Kernels]
  [storage]
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
  [density_csv]
    family = MONOMIAL
    order = CONSTANT
  []
  [fraction_csv]
    family = MONOMIAL
    order = CONSTANT
  []
  [adapt_flag]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [loaded_microstructure]
    # The initializer evaluates this during initialSetup, before ParsedFunction setup.
    type = PiecewiseConstant
    axis = x
    x = '0 1 2 3'
    y = '1 2 0 0'
  []
  [adapt_pattern]
    type = ParsedFunction
    expression = 'if(t<0.15,1,if(t<0.25,0,if(t<0.35,1,0)))'
  []
[]

[UserObjects]
  [microstructure]
    type = PolycrystalDensityIntegerLegacyUO
    num_grains = 2
    target_grains = 1
    range_in = '1 1'
    range_out = '1 1'
    generate_matrix = true
    max_grain_size = 1000
    min_center_spacing = 0.1
    matrix_thickness = 0.1
    sizes = '1 1'
    sizes_fraction = '1 0'
    n_pores = 1
    csv_fraction = fractions.csv
  []
[]

[AuxKernels]
  [id_display]
    type = MicrostructureIDAux
    variable = density_i
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [density]
    type = PolycrystalIntegerDensityAux
    variable = density_csv
    csv_density = densities.csv
    density_scaling = 1e-3
    bulk_RDX_density = 1820
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [fraction]
    type = PolycrystalIntegerFractionAux
    variable = fraction_csv
    csv_fraction = fractions.csv
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [adapt_flag]
    type = FunctionAux
    variable = adapt_flag
    function = adapt_pattern
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Adaptivity]
  marker = adapt
  max_h_level = 1
  [Markers]
    [adapt]
      type = ValueThresholdMarker
      variable = adapt_flag
      refine = 0.9
      coarsen = 0.1
    []
  []
[]

[Postprocessors]
  [mean_id]
    type = ElementAverageValue
    variable = density_i
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [mean_density]
    type = ElementAverageValue
    variable = density_csv
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [mean_fraction]
    type = ElementAverageValue
    variable = fraction_csv
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [elements]
    type = NumElements
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Executioner]
  type = Transient
  dt = 0.1
  num_steps = 4
  solve_type = NEWTON
[]
[Outputs]
  csv = true
  checkpoint = true
[]
