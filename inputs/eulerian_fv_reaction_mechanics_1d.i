# Eulerian longitudinal thermo-reactive mechanics prototype; um, ns, GPa, K.
# Conserved fields: rho, rho*u, rho*E, rho*Fxx, rho*Yi.
# Fyy=Fzz=1; no shear motion, plasticity, pore interface, or surrogate sources.
# Open extrapolated boundaries. Initial hot parcel drives pressure waves.
# Constant-cv caloric closure: elastic stored energy is not separated from thermal energy.
[Mesh]
  [grid]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 200
    xmax = 20
  []
[]
[Variables]
  [rho]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 2.15
  []
  [momentum]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1.075
  []
  [rhoF]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 2.15
  []
  [rhoY1]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 2.15
  []
  [rhoY2]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rhoY3]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [energy]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
[]
[ICs]
  [energy]
    type = FunctionIC
    variable = energy
    function = '2.15*(0.002355592*(300+1200*exp(-((x-5)/0.5)^8))+0.5*0.5^2)'
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
  [Fxx]
    type = ADParsedFunctorMaterial
    property_name = Fxx
    functor_names = 'rhoF rho'
    expression = 'rhoF/rho'
  []
  [Y1]
    type = ADParsedFunctorMaterial
    property_name = Y1
    functor_names = 'rhoY1 rho'
    expression = 'rhoY1/rho'
  []
  [Y2]
    type = ADParsedFunctorMaterial
    property_name = Y2
    functor_names = 'rhoY2 rho'
    expression = 'rhoY2/rho'
  []
  [Y3]
    type = ADParsedFunctorMaterial
    property_name = Y3
    functor_names = 'rhoY3 rho'
    expression = 'rhoY3/rho'
  []
  [internal_energy_density]
    type = ADParsedFunctorMaterial
    property_name = internal_energy_density
    functor_names = 'energy momentum rho'
    expression = 'energy-0.5*momentum^2/rho'
  []
  [reference_energy_density]
    type = ADParsedFunctorMaterial
    property_name = reference_energy_density
    functor_names = 'rho'
    expression = 'rho*0.002355592*300'
  []
  [temperature]
    type = ADParsedFunctorMaterial
    property_name = temperature
    functor_names = 'internal_energy_density rho'
    expression = 'internal_energy_density/(rho*0.002355592)'
  []
  [sxx]
    type = ADParsedFunctorMaterial
    property_name = sxx
    functor_names = 'Y1 Fxx'
    expression = 'max(0,min(1,Y1))*5.8*(2/3)*(Fxx^2-1)'
  []
  [artificial_pressure]
    type = ADParsedFunctorMaterial
    property_name = artificial_pressure
    functor_names = 'rho velocity_gradient'
    expression = 'rho*(0.1*4*0.1*max(-velocity_gradient,0)+1*0.1^2*max(-velocity_gradient,0)^2)'
  []
  [normal_stress]
    type = ADParsedFunctorMaterial
    property_name = normal_stress
    functor_names = 'pressure artificial_pressure sxx'
    expression = 'sxx-pressure-artificial_pressure'
  []
  [wave_speed]
    type = ADParsedFunctorMaterial
    property_name = wave_speed
    functor_names = 'u'
    expression = 'abs(u)+8'
  []
  [flux_mass]
    type = ADParsedFunctorMaterial
    property_name = flux_mass
    functor_names = 'momentum'
    expression = 'momentum'
  []
  [flux_momentum]
    type = ADParsedFunctorMaterial
    property_name = flux_momentum
    functor_names = 'momentum u normal_stress'
    expression = 'momentum*u-normal_stress'
  []
  [flux_energy]
    type = ADParsedFunctorMaterial
    property_name = flux_energy
    functor_names = 'energy u normal_stress temperature_gradient'
    expression = '(energy-normal_stress)*u-0.361e-6*temperature_gradient'
  []
  [flux_F]
    type = ADParsedFunctorMaterial
    property_name = flux_F
    functor_names = 'rhoF u'
    expression = 'rhoF*u'
  []
  [source_F]
    type = ADParsedFunctorMaterial
    property_name = source_F
    functor_names = 'rhoF velocity_gradient'
    expression = 'rhoF*velocity_gradient'
  []
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
    functor_names = 'r1 rhoY1'
    expression = 'r1*rhoY1'
  []
  [consume2]
    type = ADParsedFunctorMaterial
    property_name = consume2
    functor_names = 'r2 rhoY2'
    expression = 'r2*rhoY2'
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
  [heat]
    type = ADParsedFunctorMaterial
    property_name = heat
    functor_names = 'Q1 Q2 consume1 consume2'
    expression = 'Q1*consume1+Q2*consume2'
  []
  [Jrho_error]
    type = ADParsedFunctorMaterial
    property_name = Jrho_error
    functor_names = 'rhoF'
    expression = 'rhoF/2.15-1'
  []
  [species_error]
    type = ADParsedFunctorMaterial
    property_name = species_error
    functor_names = 'rhoY1 rhoY2 rhoY3 rho'
    expression = '(rhoY1+rhoY2+rhoY3)/rho-1'
  []
  [flux_Y1]
    type = ADParsedFunctorMaterial
    property_name = flux_Y1
    functor_names = 'rhoY1 u'
    expression = 'rhoY1*u'
  []
  [flux_Y2]
    type = ADParsedFunctorMaterial
    property_name = flux_Y2
    functor_names = 'rhoY2 u'
    expression = 'rhoY2*u'
  []
  [flux_Y3]
    type = ADParsedFunctorMaterial
    property_name = flux_Y3
    functor_names = 'rhoY3 u'
    expression = 'rhoY3*u'
  []
  [eos]
    type = ADComputeMieGruneisenPressure
    K0 = 20
    s = 1.5
    gamma = 1.2
    density_name = rho
    reference_density_name = 2.15
    # This object's thermal term needs ENERGY DENSITY, despite the 'sie' names.
    sie_name = internal_energy_density
    sie0_name = reference_energy_density
    pressure_name = pressure
  []
[]
[FVKernels]
  [rho_time]
    type = FVTimeKernel
    variable = rho
  []
  [rho_flux]
    type = FVLongitudinalFlux
    variable = rho
    flux = flux_mass
    wave_speed = wave_speed
  []
  [momentum_time]
    type = FVTimeKernel
    variable = momentum
  []
  [momentum_flux]
    type = FVLongitudinalFlux
    variable = momentum
    flux = flux_momentum
    wave_speed = wave_speed
  []
  [energy_time]
    type = FVTimeKernel
    variable = energy
  []
  [energy_flux]
    type = FVLongitudinalFlux
    variable = energy
    flux = flux_energy
    wave_speed = wave_speed
  []
  [rhoF_time]
    type = FVTimeKernel
    variable = rhoF
  []
  [rhoF_flux]
    type = FVLongitudinalFlux
    variable = rhoF
    flux = flux_F
    wave_speed = wave_speed
  []
  [rhoY1_time]
    type = FVTimeKernel
    variable = rhoY1
  []
  [rhoY1_flux]
    type = FVLongitudinalFlux
    variable = rhoY1
    flux = flux_Y1
    wave_speed = wave_speed
  []
  [rhoY2_time]
    type = FVTimeKernel
    variable = rhoY2
  []
  [rhoY2_flux]
    type = FVLongitudinalFlux
    variable = rhoY2
    flux = flux_Y2
    wave_speed = wave_speed
  []
  [rhoY3_time]
    type = FVTimeKernel
    variable = rhoY3
  []
  [rhoY3_flux]
    type = FVLongitudinalFlux
    variable = rhoY3
    flux = flux_Y3
    wave_speed = wave_speed
  []
  [rhoF_source]
    type = FVCoupledForce
    variable = rhoF
    v = source_F
    coef = 1
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
    v = source2
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
  [temperature_out]
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
  [Jrho_error_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [species_error_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
[]
[AuxKernels]
  [temperature]
    type = FunctorAux
    variable = temperature_out
    functor = temperature
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
  [Jrho_error]
    type = FunctorAux
    variable = Jrho_error_out
    functor = Jrho_error
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [species_error]
    type = FunctorAux
    variable = species_error_out
    functor = species_error
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[Postprocessors]
  [rho_mean]
    type = ElementAverageValue
    variable = rho
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [momentum_mean]
    type = ElementAverageValue
    variable = momentum
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [energy_mean]
    type = ElementAverageValue
    variable = energy
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [temperature_out_mean]
    type = ElementAverageValue
    variable = temperature_out
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Fxx_out_mean]
    type = ElementAverageValue
    variable = Fxx_out
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Jrho_error_out_mean]
    type = ElementAverageValue
    variable = Jrho_error_out
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [species_error_out_mean]
    type = ElementAverageValue
    variable = species_error_out
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 0.001
  end_time = 0.2
  nl_rel_tol = 1e-9
  nl_abs_tol = 1e-11
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
[]
[Outputs]
  exodus = true
  csv = true
[]
