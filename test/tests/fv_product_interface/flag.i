# No timesteps: exercise face flags and initial refinement/coarsening only.
[Mesh]
  uniform_refine = 0
  [grid]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 6
    ny = 2
    xmax = 6
    ymax = 2
  []
[]
[Variables]
  [Y3]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [clock]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
[]
[AuxVariables]
  [flag]
    type = MooseVariableFVReal
  []
[]
[Functions]
  [interface_band]
    type = ParsedFunction
    expression = 'if(x>2,if(x<4,1,0),0)'
  []
  [products]
    type = ParsedFunction
    expression = 'if(x<3,1,0)'
  []
  [clock_ic]
    type = ParsedFunction
    expression = 'if(x<3,2,0)'
  []
[]
[ICs]
  # Initial adaptivity precedes INITIAL AuxKernels. Only the AMR-face test
  # overrides this IC with interface_band to seed a nonuniform refined mesh.
  [flag]
    type = FunctionIC
    variable = flag
    function = 0
  []
  [products]
    type = FunctionIC
    variable = Y3
    function = products
  []
  [clock]
    type = FunctionIC
    variable = clock
    function = clock_ic
  []
[]
[AuxKernels]
  [interface]
    type = FVProductInterfaceAux
    variable = flag
    products = Y3
    reaction_clock = clock
    reaction_duration = 1
    jump_threshold = 0.1
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[FVKernels]
  [products]
    type = FVTimeKernel
    variable = Y3
  []
  [clock]
    type = FVTimeKernel
    variable = clock
  []
[]
[Adaptivity]
  marker = interface
  max_h_level = 3
  initial_steps = 0
  [Markers]
    [interface]
      type = ValueThresholdMarker
      variable = flag
      refine = 0.9
      coarsen = 0.5
      third_state = DO_NOTHING
    []
  []
[]
[Postprocessors]
  [flag_volume]
    type = ElementIntegralVariablePostprocessor
    variable = flag
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [num_elements]
    type = NumElements
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[Executioner]
  type = Transient
  num_steps = 0
  dt = 0.01
[]
[Outputs]
  csv = true
[]
