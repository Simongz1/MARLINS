# Two unit-length cells: rho=1 and 3, cv=2, volumetric source=2.
# Lumped capacities at x=0,1,2 are 1,4,3; source loads are 1,2,1.
# After dt=0.1, T must be 0.1,0.05,1/30. A consistent mass matrix differs.
[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
  xmax = 2
[]
[Variables]
  [T]
    family = LAGRANGE
    order = FIRST
  []
[]
[Kernels]
  [storage]
    type = ADMassLumpedHeatConductionTimeDerivative
    variable = T
    use_displaced_mesh = false
  []
  [heat]
    type = BodyForce
    variable = T
    value = 2
  []
[]
[Materials]
  [density]
    type = ADParsedMaterial
    property_name = density
    extra_symbols = x
    expression = 'if(x < 1, 1, 3)'
  []
  [cv]
    type = ADGenericConstantMaterial
    prop_names = specific_heat
    prop_values = 2
  []
[]
[Postprocessors]
  [left]
    type = PointValue
    variable = T
    point = '0 0 0'
  []
  [middle]
    type = PointValue
    variable = T
    point = '1 0 0'
  []
  [right]
    type = PointValue
    variable = T
    point = '2 0 0'
  []
[]
[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 0.1
  num_steps = 1
  nl_abs_tol = 1e-12
  petsc_options_iname = '-pc_type'
  petsc_options_value = lu
[]
[Outputs]
  csv = true
[]
