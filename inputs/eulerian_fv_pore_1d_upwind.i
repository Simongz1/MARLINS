# Reduced-diffusion copy of eulerian_fv_pore_1d.i.
# Same physics/loading; material-speed upwind transport with minmod reconstruction.
# No acoustic-speed Lax-Friedrichs diffusion; pressure/AV use a common acoustic traction/velocity state.
# Planar gas-filled gap closure: fixed Eulerian grid; um, ns, GPa, K.
# Demonstration diffuse mixture, not a sharp-interface vacuum solver.
# Gas cv equals solid cv for compatibility with the current thermal-gradient helper.
# Geometry/loading are explicit FunctionIC expressions below.
[GlobalParams]
  ghost_layers = 2
  reconstruction = minmod
[]
[Mesh]
  [grid]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 800
    xmax = 20
  []
[]
[Variables]
  [rho]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rho_solid]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [momentum]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [energy]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [solid_volume]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rhoSolidF]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rhoY1]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rhoY2]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rhoY3]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
[]
[ICs]
  [rho]
    type = FunctionIC
    variable = rho
    function = 'if(x>=10 & x<=10.4,0.0182,1.82)'
  []
  [rho_solid]
    type = FunctionIC
    variable = rho_solid
    function = 'if(x>=10 & x<=10.4,0,1.82)'
  []
  [momentum]
    type = FunctionIC
    variable = momentum
    function = 'if(x<8,1.82,0)'
  []
  [energy]
    type = FunctionIC
    variable = energy
    function = 'if(x>=10 & x<=10.4,0.0182,1.82)*(0.002355592*300+0.5*if(x<8,1,0))'
  []
  [solid_volume]
    type = FunctionIC
    variable = solid_volume
    function = 'if(x>=10 & x<=10.4,0,1)'
  []
  [rhoSolidF]
    type = FunctionIC
    variable = rhoSolidF
    function = 'if(x>=10 & x<=10.4,0,1.82)'
  []
  [rhoY1]
    type = FunctionIC
    variable = rhoY1
    function = 'if(x>=10 & x<=10.4,0,1.82)'
  []
  [rhoY2]
    type = FunctionIC
    variable = rhoY2
    function = '0'
  []
  [rhoY3]
    type = FunctionIC
    variable = rhoY3
    function = '0'
  []
[]
[FunctorMaterials]
  [gradients]
    type = ADLongitudinalGradients
    rho = rho
    momentum = momentum
    energy = energy
    cv = 0.002355592
  []
  [u]
    type = ADParsedFunctorMaterial
    property_name = u
    functor_names = 'momentum rho'
    expression = 'momentum/rho'
  []
  [alpha]
    type = ADParsedFunctorMaterial
    property_name = alpha
    functor_names = 'solid_volume'
    expression = 'min(1,max(0,solid_volume))'
  []
  [rho_gas]
    type = ADParsedFunctorMaterial
    property_name = rho_gas
    functor_names = 'rho rho_solid'
    expression = 'rho-rho_solid'
  []
  [solid_density]
    type = ADParsedFunctorMaterial
    property_name = solid_density
    functor_names = 'rho_solid alpha'
    expression = 'if(alpha>1e-10,rho_solid/max(alpha,1e-10),1.82)'
  []
  [Fxx]
    type = ADParsedFunctorMaterial
    property_name = Fxx
    functor_names = 'rhoSolidF rho_solid'
    expression = 'if(rho_solid>1e-10,rhoSolidF/max(rho_solid,1e-10),1)'
  []
  [Y1]
    type = ADParsedFunctorMaterial
    property_name = Y1
    functor_names = 'rhoY1 rho_solid'
    expression = 'if(rho_solid>1e-10,rhoY1/max(rho_solid,1e-10),0)'
  []
  [Y2]
    type = ADParsedFunctorMaterial
    property_name = Y2
    functor_names = 'rhoY2 rho_solid'
    expression = 'if(rho_solid>1e-10,rhoY2/max(rho_solid,1e-10),0)'
  []
  [Y3]
    type = ADParsedFunctorMaterial
    property_name = Y3
    functor_names = 'rhoY3 rho_solid'
    expression = 'if(rho_solid>1e-10,rhoY3/max(rho_solid,1e-10),0)'
  []
  [internal_energy_density]
    type = ADParsedFunctorMaterial
    property_name = internal_energy_density
    functor_names = 'energy momentum rho'
    expression = 'energy-0.5*momentum^2/rho'
  []
  [temperature]
    type = ADParsedFunctorMaterial
    property_name = temperature
    functor_names = 'internal_energy_density rho'
    expression = 'internal_energy_density/(rho*0.002355592)'
  []
  [solid_internal_energy_density]
    type = ADParsedFunctorMaterial
    property_name = solid_internal_energy_density
    functor_names = 'solid_density temperature'
    expression = 'solid_density*0.002355592*temperature'
  []
  [solid_reference_energy_density]
    type = ADParsedFunctorMaterial
    property_name = solid_reference_energy_density
    functor_names = 'solid_density'
    expression = 'solid_density*0.002355592*300'
  []
  [pressure]
    type = ADParsedFunctorMaterial
    property_name = pressure
    functor_names = 'alpha solid_pressure rho_gas temperature'
    expression = 'alpha*(solid_pressure+0.005144612928)+0.4*rho_gas*0.002355592*temperature'
  []
  [sxx]
    type = ADParsedFunctorMaterial
    property_name = sxx
    functor_names = 'alpha Y1 Fxx'
    expression = 'alpha*max(0,min(1,Y1))*12.80709677419355*(2/3)*(Fxx^2-1)'
  []
  [artificial_pressure]
    type = ADParsedFunctorMaterial
    property_name = artificial_pressure
    functor_names = 'rho velocity_gradient'
    expression = 'rho*(0.1*4*0.025*max(-velocity_gradient,0)+0.025^2*max(-velocity_gradient,0)^2)'
  []
  [normal_stress]
    type = ADParsedFunctorMaterial
    property_name = normal_stress
    functor_names = 'sxx pressure artificial_pressure'
    expression = 'sxx-pressure-artificial_pressure'
  []
  [conductivity]
    type = ADParsedFunctorMaterial
    property_name = conductivity
    functor_names = 'alpha'
    expression = 'alpha*0.361e-6+(1-alpha)*0.026e-6'
  []
  [source_volume]
    type = ADParsedFunctorMaterial
    property_name = source_volume
    functor_names = 'solid_volume velocity_gradient'
    expression = 'solid_volume*velocity_gradient'
  []
  [source_F]
    type = ADParsedFunctorMaterial
    property_name = source_F
    functor_names = 'rhoSolidF velocity_gradient'
    expression = 'rhoSolidF*velocity_gradient'
  []
  [r1]
    type = ADParsedFunctorMaterial
    property_name = r1
    functor_names = 'temperature'
    expression = '32103.943853583012*exp(-24400/(1.987*temperature))'
  []
  [r2]
    type = ADParsedFunctorMaterial
    property_name = r2
    functor_names = 'temperature'
    expression = '11810.38092425548*exp(-23500/(1.987*temperature))'
  []
  [consume1]
    type = ADParsedFunctorMaterial
    property_name = consume1
    functor_names = 'r1 rhoY1'
    expression = 'r1*rhoY1'
  []
  [consume2]
    type = ADParsedFunctorMaterial
    property_name = consume2
    functor_names = 'r2 rhoY2'
    expression = 'r2*rhoY2'
  []
  [source_Y2]
    type = ADParsedFunctorMaterial
    property_name = source_Y2
    functor_names = 'consume1 consume2'
    expression = 'consume1-consume2'
  []
  [Q1]
    type = ADParsedFunctorMaterial
    property_name = Q1
    functor_names = 'temperature'
    expression = '-0.03200215963286241+0.0005910987132187528*max(temperature-1736.3,0)'
  []
  [Q2]
    type = ADParsedFunctorMaterial
    property_name = Q2
    functor_names = 'temperature'
    expression = '7.831116710159273-0.0007221193197156482*max(temperature-1736.3,0)'
  []
  [heat]
    type = ADParsedFunctorMaterial
    property_name = heat
    functor_names = 'Q1 Q2 consume1 consume2'
    expression = 'Q1*consume1+Q2*consume2'
  []
  [species_error]
    type = ADParsedFunctorMaterial
    property_name = species_error
    functor_names = 'rhoY1 rhoY2 rhoY3 rho_solid'
    expression = 'rhoY1+rhoY2+rhoY3-rho_solid'
  []
  [Jrho_error]
    type = ADParsedFunctorMaterial
    property_name = Jrho_error
    functor_names = 'alpha solid_density Fxx'
    expression = 'if(alpha>0.1,solid_density*Fxx/1.82-1,0)'
  []
  [gap_fraction]
    type = ADParsedFunctorMaterial
    property_name = gap_fraction
    functor_names = 'alpha'
    expression = '1-alpha'
  []
  [impedance]
    type = ADParsedFunctorMaterial
    property_name = impedance
    functor_names = 'rho alpha pressure'
    # Reference longitudinal solid modulus and current gas bulk contribution.
    expression = 'sqrt(rho*(alpha*(20.36+4/3*12.80709677419355)+(1-alpha)*1.4*max(pressure,0.005144612928)))'
  []
  [conductive_flux]
    type = ADParsedFunctorMaterial
    property_name = conductive_flux
    functor_names = 'conductivity temperature_gradient'
    expression = '-conductivity*temperature_gradient'
  []
  [solid_eos]
    type = ADComputeMieGruneisenPressure
    K0 = 20.36
    s = 1.5
    gamma = 1.2
    density_name = solid_density
    reference_density_name = 1.82
    sie_name = solid_internal_energy_density
    sie0_name = solid_reference_energy_density
    pressure_name = solid_pressure
  []
[]
[FVKernels]
  [rho_time]
    type = FVTimeKernel
    variable = rho
  []
  [rho_flux]
    type = FVMaterialUpwindFlux
    variable = rho
    velocity = u
    normal_stress = normal_stress
    impedance = impedance
  []
  [rho_solid_time]
    type = FVTimeKernel
    variable = rho_solid
  []
  [rho_solid_flux]
    type = FVMaterialUpwindFlux
    variable = rho_solid
    velocity = u
    normal_stress = normal_stress
    impedance = impedance
    material_component = solid
    density = rho
    solid_density = rho_solid
    species = 'rhoY1 rhoY2 rhoY3'
  []
  [momentum_time]
    type = FVTimeKernel
    variable = momentum
  []
  [momentum_flux]
    type = FVMaterialUpwindFlux
    variable = momentum
    velocity = u
    normal_stress = normal_stress
    impedance = impedance
    equation = momentum
  []
  [energy_time]
    type = FVTimeKernel
    variable = energy
  []
  [energy_flux]
    type = FVMaterialUpwindFlux
    variable = energy
    velocity = u
    normal_stress = normal_stress
    impedance = impedance
    equation = energy
    heat_flux = conductive_flux
  []
  [solid_volume_time]
    type = FVTimeKernel
    variable = solid_volume
  []
  [solid_volume_flux]
    type = FVMaterialUpwindFlux
    variable = solid_volume
    velocity = u
    normal_stress = normal_stress
    impedance = impedance
  []
  [rhoSolidF_time]
    type = FVTimeKernel
    variable = rhoSolidF
  []
  [rhoSolidF_flux]
    type = FVMaterialUpwindFlux
    variable = rhoSolidF
    velocity = u
    normal_stress = normal_stress
    impedance = impedance
  []
  [rhoY1_time]
    type = FVTimeKernel
    variable = rhoY1
  []
  [rhoY1_flux]
    type = FVMaterialUpwindFlux
    variable = rhoY1
    velocity = u
    normal_stress = normal_stress
    impedance = impedance
    material_component = species1
    density = rho
    solid_density = rho_solid
    species = 'rhoY1 rhoY2 rhoY3'
  []
  [rhoY2_time]
    type = FVTimeKernel
    variable = rhoY2
  []
  [rhoY2_flux]
    type = FVMaterialUpwindFlux
    variable = rhoY2
    velocity = u
    normal_stress = normal_stress
    impedance = impedance
    material_component = species2
    density = rho
    solid_density = rho_solid
    species = 'rhoY1 rhoY2 rhoY3'
  []
  [rhoY3_time]
    type = FVTimeKernel
    variable = rhoY3
  []
  [rhoY3_flux]
    type = FVMaterialUpwindFlux
    variable = rhoY3
    velocity = u
    normal_stress = normal_stress
    impedance = impedance
    material_component = species3
    density = rho
    solid_density = rho_solid
    species = 'rhoY1 rhoY2 rhoY3'
  []
  [solid_volume_source]
    type = FVMaterialDilatationSource
    variable = solid_volume
    velocity = u
    normal_stress = normal_stress
    impedance = impedance
  []
  [rhoSolidF_source]
    type = FVMaterialDilatationSource
    variable = rhoSolidF
    velocity = u
    normal_stress = normal_stress
    impedance = impedance
  []
  [rhoY1_source]
    type = FVCoupledForce
    variable = rhoY1
    v = consume1
    coef = -1
  []
  [rhoY2_source]
    type = FVCoupledForce
    variable = rhoY2
    v = source_Y2
    coef = 1
  []
  [rhoY3_source]
    type = FVCoupledForce
    variable = rhoY3
    v = consume2
    coef = 1
  []
  [energy_source]
    type = FVCoupledForce
    variable = energy
    v = heat
    coef = 1
  []
[]
[AuxVariables]
  [alpha_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [gap_fraction_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rho_gas_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [solid_density_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [u_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [Fxx_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [temperature_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [pressure_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [sxx_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [artificial_pressure_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [Y1_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [Y2_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [Y3_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [species_error_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [Jrho_error_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
[]
[AuxKernels]
  [alpha]
    type = FunctorAux
    variable = alpha_out
    functor = alpha
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [gap_fraction]
    type = FunctorAux
    variable = gap_fraction_out
    functor = gap_fraction
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [rho_gas]
    type = FunctorAux
    variable = rho_gas_out
    functor = rho_gas
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [solid_density]
    type = FunctorAux
    variable = solid_density_out
    functor = solid_density
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [u]
    type = FunctorAux
    variable = u_out
    functor = u
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Fxx]
    type = FunctorAux
    variable = Fxx_out
    functor = Fxx
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [temperature]
    type = FunctorAux
    variable = temperature_out
    functor = temperature
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [pressure]
    type = FunctorAux
    variable = pressure_out
    functor = pressure
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [sxx]
    type = FunctorAux
    variable = sxx_out
    functor = sxx
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [artificial_pressure]
    type = FunctorAux
    variable = artificial_pressure_out
    functor = artificial_pressure
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Y1]
    type = FunctorAux
    variable = Y1_out
    functor = Y1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Y2]
    type = FunctorAux
    variable = Y2_out
    functor = Y2
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Y3]
    type = FunctorAux
    variable = Y3_out
    functor = Y3
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [species_error]
    type = FunctorAux
    variable = species_error_out
    functor = species_error
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Jrho_error]
    type = FunctorAux
    variable = Jrho_error_out
    functor = Jrho_error
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[Postprocessors]
  [rho_mean]
    type = ElementAverageValue
    variable = rho
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [rho_solid_mean]
    type = ElementAverageValue
    variable = rho_solid
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [energy_mean]
    type = ElementAverageValue
    variable = energy
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [momentum_mean]
    type = ElementAverageValue
    variable = momentum
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [temperature_out_mean]
    type = ElementAverageValue
    variable = temperature_out
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [species_error_out_mean]
    type = ElementAverageValue
    variable = species_error_out
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [gas_volume]
    type = ElementIntegralVariablePostprocessor
    variable = gap_fraction_out
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 0.001
  dtmin = 1e-7
  end_time = 2
  nl_rel_tol = 1e-9
  nl_abs_tol = 1e-11
  petsc_options_iname = '-pc_type'
  petsc_options_value = lu
[]
[Outputs]
  exodus = true
  csv = true
  time_step_interval = 10
[]
