# Fixed-grid, constant-density Eulerian advection-reaction-conduction test.
# Units: um, ns, GPa, K. Prescribed velocity; no momentum/pore-collapse solve.
# rho=2.15; cv=0.563*4184e-6; k=0.361e-6.
# Q=a+b*max(T-1736.3,0), kcal/mol -> specific energy using MW=0.22226 kg/mol.
# a2=416 deliberately matches the current production input (paper discussion: 412).
# Fresh cold material enters at left; advective outflow at right.
[Mesh]
  [grid]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 200
    xmin = 0
    xmax = 20
  []
[]
[Variables]
  [Y1]
    type = MooseVariableFVReal
    initial_condition = 1
    two_term_boundary_expansion = false
  []
  [Y2]
    type = MooseVariableFVReal
    initial_condition = 0
    two_term_boundary_expansion = false
  []
  [Y3]
    type = MooseVariableFVReal
    initial_condition = 0
    two_term_boundary_expansion = false
  []
  [temperature]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
[]
[ICs]
  [hot_parcel]
    type = FunctionIC
    variable = temperature
    function = '300+1200*exp(-((x-5)/0.5)^8)'
  []
[]
[FVBCs]
  [Y1_inlet]
    type = FVDirichletBC
    variable = Y1
    boundary = left
    value = 1
  []
  [Y1_outlet]
    type = FVConstantScalarOutflowBC
    variable = Y1
    boundary = right
    velocity = '0.5 0 0'
  []
  [Y2_inlet]
    type = FVDirichletBC
    variable = Y2
    boundary = left
    value = 0
  []
  [Y2_outlet]
    type = FVConstantScalarOutflowBC
    variable = Y2
    boundary = right
    velocity = '0.5 0 0'
  []
  [Y3_inlet]
    type = FVDirichletBC
    variable = Y3
    boundary = left
    value = 0
  []
  [Y3_outlet]
    type = FVConstantScalarOutflowBC
    variable = Y3
    boundary = right
    velocity = '0.5 0 0'
  []
  [temperature_inlet]
    type = FVDirichletBC
    variable = temperature
    boundary = left
    value = 300
  []
  [temperature_outlet]
    type = FVConstantScalarOutflowBC
    variable = temperature
    boundary = right
    velocity = '0.5 0 0'
  []
[]
[FunctorMaterials]
  [r1]
    type = ADParsedFunctorMaterial
    property_name = r1
    functor_names = 'temperature'
    expression = '1e-9*exp(31.1-24400/(1.987*temperature))'
  []
  [r2]
    type = ADParsedFunctorMaterial
    property_name = r2
    functor_names = 'temperature'
    expression = '1e-9*exp(30.1-23500/(1.987*temperature))'
  []
  [consume1]
    type = ADParsedFunctorMaterial
    property_name = consume1
    functor_names = 'r1 Y1'
    expression = 'r1*Y1'
  []
  [consume2]
    type = ADParsedFunctorMaterial
    property_name = consume2
    functor_names = 'r2 Y2'
    expression = 'r2*Y2'
  []
  [source2]
    type = ADParsedFunctorMaterial
    property_name = source2
    functor_names = 'consume1 consume2'
    expression = 'consume1-consume2'
  []
  [Q1]
    type = ADParsedFunctorMaterial
    property_name = Q1
    functor_names = 'temperature'
    expression = '4184e-6/0.22226*(-1.7+0.0314*max(temperature-1736.3,0))'
  []
  [Q2]
    type = ADParsedFunctorMaterial
    property_name = Q2
    functor_names = 'temperature'
    expression = '4184e-6/0.22226*(416-0.03836*max(temperature-1736.3,0))'
  []
  [thermal_source]
    type = ADParsedFunctorMaterial
    property_name = thermal_source
    functor_names = 'Q1 Q2 consume1 consume2'
    expression = '(Q1*consume1+Q2*consume2)/(0.563*4184e-6)'
  []
  [species_sum]
    type = ADParsedFunctorMaterial
    property_name = species_sum
    functor_names = 'Y1 Y2 Y3'
    expression = 'Y1+Y2+Y3'
  []
[]
[FVKernels]
  [Y1_time]
    type = FVTimeKernel
    variable = Y1
  []
  [Y1_advection]
    type = FVAdvection
    variable = Y1
    velocity = '0.5 0 0'
    advected_interp_method = upwind
  []
  [Y2_time]
    type = FVTimeKernel
    variable = Y2
  []
  [Y2_advection]
    type = FVAdvection
    variable = Y2
    velocity = '0.5 0 0'
    advected_interp_method = upwind
  []
  [Y3_time]
    type = FVTimeKernel
    variable = Y3
  []
  [Y3_advection]
    type = FVAdvection
    variable = Y3
    velocity = '0.5 0 0'
    advected_interp_method = upwind
  []
  [temperature_time]
    type = FVTimeKernel
    variable = temperature
  []
  [temperature_advection]
    type = FVAdvection
    variable = temperature
    velocity = '0.5 0 0'
    advected_interp_method = upwind
  []
  [Y1_reaction]
    type = FVCoupledForce
    variable = Y1
    v = consume1
    coef = -1
  []
  [Y2_reaction]
    type = FVCoupledForce
    variable = Y2
    v = source2
    coef = 1
  []
  [Y3_reaction]
    type = FVCoupledForce
    variable = Y3
    v = consume2
    coef = 1
  []
  [temperature_reaction]
    type = FVCoupledForce
    variable = temperature
    v = thermal_source
    coef = 1
  []
  [conduction]
    type = FVDiffusion
    variable = temperature
    coeff = 7.128016088702376e-05 # k/(rho*cv), um^2/ns
  []
[]
[Postprocessors]
  [Y1_mean]
    type = ElementAverageValue
    variable = Y1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Y1_max]
    type = ElementExtremeValue
    variable = Y1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Y2_mean]
    type = ElementAverageValue
    variable = Y2
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Y2_max]
    type = ElementExtremeValue
    variable = Y2
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Y3_mean]
    type = ElementAverageValue
    variable = Y3
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Y3_max]
    type = ElementExtremeValue
    variable = Y3
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [temperature_mean]
    type = ElementAverageValue
    variable = temperature
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [temperature_max]
    type = ElementExtremeValue
    variable = temperature
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 0.002
  end_time = 2
  nl_rel_tol = 1e-9
  nl_abs_tol = 1e-11
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
[]
[Outputs]
  exodus = true
  csv = true
  [console]
    type = Console
    time_step_interval = 100
  []
[]
