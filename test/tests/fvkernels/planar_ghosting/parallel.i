# Parallel regression: face fluxes evaluate gradients in off-processor neighbors.
# No GlobalParams ghost override: exercise FVPlanarFlux's default ghosting.
[Mesh]
  [grid]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 8
    ny = 8
  []
[]
[Variables]
  [rho]
    type = MooseVariableFVReal
    initial_condition = 1
  []
  [mx]
    type = MooseVariableFVReal
    initial_condition = 0
  []
  [my]
    type = MooseVariableFVReal
    initial_condition = 0
  []
  [energy]
    type = MooseVariableFVReal
  []
[]
[ICs]
  [energy]
    type = FunctionIC
    variable = energy
    function = '1+0.1*cos(2*pi*x)*cos(2*pi*y)'
  []
[]
[FunctorMaterials]
  [gradients]
    type = ADPlanarConservedGradients
    rho = rho
    mx = mx
    my = my
    energy = energy
    cv = 1
  []
  [qx]
    type = ADParsedFunctorMaterial
    property_name = qx
    functor_names = gradT0
    expression = '-gradT0'
  []
  [qy]
    type = ADParsedFunctorMaterial
    property_name = qy
    functor_names = gradT1
    expression = '-gradT1'
  []
[]
[FVKernels]
  [rho_time]
    type = FVTimeKernel
    variable = rho
  []
  [mx_time]
    type = FVTimeKernel
    variable = mx
  []
  [my_time]
    type = FVTimeKernel
    variable = my
  []
  [energy_time]
    type = FVTimeKernel
    variable = energy
  []
  [conduction]
    type = FVPlanarFlux
    variable = energy
    flux_x = qx
    flux_y = qy
    wave_speed = 1
  []
[]
[Executioner]
  type = Transient
  dt = 0.001
  num_steps = 2
  solve_type = NEWTON
  nl_abs_tol = 1e-10
  petsc_options_iname = '-pc_type'
  petsc_options_value = jacobi
[]
[Outputs]
  console = true
[]
