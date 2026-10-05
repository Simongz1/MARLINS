# Nonreactive alternative: AD heat diffusion only. No decomposition kinetics.
# Synthetic properties; random initial field in an insulated square.
[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 8
  ny = 8
[]
[Variables]
  [temperature]
  []
[]
[ICs]
  [random_temperature]
    type = RandomIC
    variable = temperature
    min = 290
    max = 310
    seed = 1234
  []
[]
[Kernels]
  [capacity]
    type = ADHeatConductionTimeDerivative
    variable = temperature
  []
  [conduction]
    type = ADHeatConduction
    variable = temperature
  []
[]
[Materials]
  [thermal_properties]
    type = ADGenericConstantMaterial
    prop_names = 'density specific_heat thermal_conductivity'
    prop_values = '1 1 1'
  []
[]
[Postprocessors]
  [mean_temperature]
    type = ElementAverageValue
    variable = temperature
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [min_temperature]
    type = NodalExtremeValue
    variable = temperature
    value_type = min
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [max_temperature]
    type = NodalExtremeValue
    variable = temperature
    value_type = max
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 0.01
  num_steps = 5
  nl_abs_tol = 1e-9
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
[]
[Outputs]
  exodus = true
  csv = true
  execute_on = 'INITIAL TIMESTEP_END'
[]
