# A stationary contact must not diffuse at an acoustic speed.
[Mesh]
  [grid]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 40
    xmax = 20
  []
[]
[Variables]
  [density]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
[]
[Functions]
  [exact]
    type = ParsedFunction
    expression = 'if(x-t>=10 & x-t<=11,0.0182,1.82)'
  []
[]
[ICs]
  [density]
    type = FunctionIC
    variable = density
    function = exact
  []
[]
[FVKernels]
  [time]
    type = FVTimeKernel
    variable = density
  []
  [transport]
    type = FVMaterialUpwindFlux
    variable = density
    velocity = 1
    normal_stress = 0
    impedance = 1
    reconstruction = minmod
  []
[]
[Postprocessors]
  [contact_error]
    type = ElementL2Error
    variable = density
    function = exact
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[Executioner]
  type = Transient
  dt = 0.01
  num_steps = 50
[]
[Outputs]
  csv = true
[]
