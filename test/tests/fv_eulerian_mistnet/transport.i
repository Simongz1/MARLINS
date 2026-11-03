[Mesh]
  parallel_type = REPLICATED
  [grid]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 1
    ny = 32
    xmax = 1
    ymax = 8
  []
[]
[Variables]
  [rho]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [my]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rho_tracer]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rho_target]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rho_Y]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [mx]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_clock]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
[]
[Functions]
  [ic_rho]
    type = ParsedFunction
    expression = 'if(y>1,if(y<2,1.6,1.82),1.82)'
  []
  [ic_my]
    type = ParsedFunction
    expression = '0.1*if(y>1,if(y<2,1.6,1.82),1.82)'
  []
  [ic_rho_tracer]
    type = ParsedFunction
    expression = 'if(y>1,if(y<2,1.6,0),0)'
  []
  [ic_rho_target]
    type = ParsedFunction
    expression = '2000*if(y>1,if(y<2,1.6,0),0)'
  []
  [ic_rho_Y]
    type = ParsedFunction
    expression = 'y*if(y>1,if(y<2,1.6,1.82),1.82)'
  []
  [coordinate_y]
    type = ParsedFunction
    expression = 'y'
  []
  [inlet_Y]
    type = ParsedFunction
    expression = '-0.1*t'
  []
[]
[ICs]
  [rho]
    type = FunctionIC
    variable = rho
    function = ic_rho
  []
  [my]
    type = FunctionIC
    variable = my
    function = ic_my
  []
  [rho_tracer]
    type = FunctionIC
    variable = rho_tracer
    function = ic_rho_tracer
  []
  [rho_target]
    type = FunctionIC
    variable = rho_target
    function = ic_rho_target
  []
  [rho_Y]
    type = FunctionIC
    variable = rho_Y
    function = ic_rho_Y
  []
[]
[FVKernels]
  [rho_time]
    type = FVTimeKernel
    variable = rho
  []
  [rho_flux]
    type = FVEulerianHydroFlux
    variable = rho
    equation = mass
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 0.1
  []
  [my_time]
    type = FVTimeKernel
    variable = my
  []
  [my_flux]
    type = FVEulerianHydroFlux
    variable = my
    equation = momentum
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 0.1
    component = 1
  []
  [rho_tracer_time]
    type = FVTimeKernel
    variable = rho_tracer
  []
  [rho_tracer_flux]
    type = FVEulerianHydroFlux
    variable = rho_tracer
    equation = passive
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 0.1
  []
  [rho_target_time]
    type = FVTimeKernel
    variable = rho_target
  []
  [rho_target_flux]
    type = FVEulerianHydroFlux
    variable = rho_target
    equation = passive
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 0.1
  []
  [rho_Y_time]
    type = FVTimeKernel
    variable = rho_Y
  []
  [rho_Y_flux]
    type = FVEulerianHydroFlux
    variable = rho_Y
    equation = passive
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 0.1
    inlet_specific = inlet_Y
  []
  [mx_time]
    type = FVTimeKernel
    variable = mx
  []
  [mx_flux]
    type = FVEulerianHydroFlux
    variable = mx
    equation = momentum
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 0.1
    component = 0
  []
  [rho_clock_time]
    type = FVTimeKernel
    variable = rho_clock
  []
  [rho_clock_flux]
    type = FVEulerianHydroFlux
    variable = rho_clock
    equation = passive
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 0.1
  []
  [clock_source]
    type = FVCoupledForce
    variable = rho_clock
    v = rho_tracer
  []
[]
[FunctorMaterials]
  [target_error_sq]
    type = ADParsedFunctorMaterial
    property_name = target_error_sq
    functor_names = 'rho_target rho_tracer'
    expression = '(rho_target-2000*rho_tracer)^2'
  []
[]
[Postprocessors]
  [mass]
    type = ElementIntegralVariablePostprocessor
    variable = rho
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [tracer_mass]
    type = ElementIntegralVariablePostprocessor
    variable = rho_tracer
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [clock_mass]
    type = ElementIntegralVariablePostprocessor
    variable = rho_clock
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [tracer_moment]
    type = ADElementIntegralFunctorPostprocessor
    functor = rho_tracer
    prefactor = coordinate_y
    evaluation_type = CELL_AVERAGE
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [target_error]
    type = ADElementIntegralFunctorPostprocessor
    functor = target_error_sq
    evaluation_type = CELL_AVERAGE
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[Executioner]
  type = Transient
  solve_type = NEWTON
  num_steps = 2
  dt = .01
  nl_abs_tol = 1e-11
  nl_rel_tol = 1e-11
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
[]
[Outputs]
  csv = true
[]
