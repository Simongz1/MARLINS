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
  [ids]
    type = ParsedExtraElementIDGenerator
    input = grid
    extra_elem_integer_name = legacy_prediction_id
    expression = 99
  []
[]
[Variables]
  [rho]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1.82
  []
  [mx]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [my]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 3.276
  []
  [rho_phi]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1.82
  []
  [rho_tracking]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 3.64
  []
  [rho_active]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_active_phi]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_Tshock]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_Treact]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_tau]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_up]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_X]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rho_Y]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rho_inlet]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
[]
[Functions]
  [coordinate_x]
    type = ParsedFunction
    expression = 'x'
  []
  [ic_rho_X]
    type = ParsedFunction
    expression = '1.82*x'
  []
  [ic_rho_Y]
    type = ParsedFunction
    expression = '1.82*y'
  []
  [coordinate_y]
    type = ParsedFunction
    expression = 'y'
  []
  [inlet_Y]
    type = ParsedFunction
    expression = '-1.8*t'
  []
[]
[ICs]
  [rho_X]
    type = FunctionIC
    variable = rho_X
    function = ic_rho_X
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
    inlet_velocity = 1.8
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
    inlet_velocity = 1.8
    component = 0
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
    inlet_velocity = 1.8
    component = 1
  []
  [rho_phi_time]
    type = FVTimeKernel
    variable = rho_phi
  []
  [rho_phi_flux]
    type = FVEulerianHydroFlux
    variable = rho_phi
    equation = passive
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 1.8
    inlet_specific = 1
  []
  [rho_tracking_time]
    type = FVTimeKernel
    variable = rho_tracking
  []
  [rho_tracking_flux]
    type = FVEulerianHydroFlux
    variable = rho_tracking
    equation = passive
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 1.8
    inlet_specific = 2
  []
  [rho_active_time]
    type = FVTimeKernel
    variable = rho_active
  []
  [rho_active_flux]
    type = FVEulerianHydroFlux
    variable = rho_active
    equation = passive
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 1.8
  []
  [rho_active_phi_time]
    type = FVTimeKernel
    variable = rho_active_phi
  []
  [rho_active_phi_flux]
    type = FVEulerianHydroFlux
    variable = rho_active_phi
    equation = passive
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 1.8
  []
  [rho_Tshock_time]
    type = FVTimeKernel
    variable = rho_Tshock
  []
  [rho_Tshock_flux]
    type = FVEulerianHydroFlux
    variable = rho_Tshock
    equation = passive
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 1.8
  []
  [rho_Treact_time]
    type = FVTimeKernel
    variable = rho_Treact
  []
  [rho_Treact_flux]
    type = FVEulerianHydroFlux
    variable = rho_Treact
    equation = passive
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 1.8
  []
  [rho_tau_time]
    type = FVTimeKernel
    variable = rho_tau
  []
  [rho_tau_flux]
    type = FVEulerianHydroFlux
    variable = rho_tau
    equation = passive
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 1.8
  []
  [rho_up_time]
    type = FVTimeKernel
    variable = rho_up
  []
  [rho_up_flux]
    type = FVEulerianHydroFlux
    variable = rho_up
    equation = passive
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 1.8
  []
  [rho_X_time]
    type = FVTimeKernel
    variable = rho_X
  []
  [rho_X_flux]
    type = FVEulerianHydroFlux
    variable = rho_X
    equation = passive
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 1.8
    inlet_specific = coordinate_x
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
    inlet_velocity = 1.8
    inlet_specific = inlet_Y
  []
  [rho_inlet_time]
    type = FVTimeKernel
    variable = rho_inlet
  []
  [rho_inlet_flux]
    type = FVEulerianHydroFlux
    variable = rho_inlet
    equation = passive
    rho = rho
    mx = mx
    my = my
    pressure = 0
    artificial_pressure = 0
    sound_speed = 1
    inlet_velocity = 1.8
  []
[]
[FunctorMaterials]
  [active_fraction]
    type = ADParsedFunctorMaterial
    property_name = active_fraction
    functor_names = 'rho_active rho'
    expression = 'rho_active/rho'
  []
  [targets_valid]
    type = ADParsedFunctorMaterial
    property_name = targets_valid
    functor_names = 'rho_active rho_Tshock rho_tau'
    expression = 'if(rho_active>0,if(rho_Tshock>0,if(rho_tau>0,1,0),0),0)'
  []
[]
[Postprocessors]
  [active_integral]
    type = ADElementIntegralFunctorPostprocessor
    functor = active_fraction
    evaluation_type = CELL_AVERAGE
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [valid_targets_integral]
    type = ADElementIntegralFunctorPostprocessor
    functor = targets_valid
    evaluation_type = CELL_AVERAGE
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[UserObjects]
  [events]
    type = FVEulerianMISTnetEvents
    csv_directory = /scratch/negishi/gonz1075/mist2/pbx_corrected/csv
  []
[]
[Executioner]
  type = Transient
  solve_type = NEWTON
  num_steps = 2
  dt = 0.001
  # Match the production absolute tolerance for density-weighted targets.
  nl_abs_tol = 1e-8
  nl_rel_tol = 1e-9
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
[]
[Outputs]
  csv = true
[]
