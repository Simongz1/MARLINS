# Elastic FV counterpart of sakano_T_Y_P_1um_lump.i (input only).
# UNITS: nm, ns, GPa, K; implied mass unit = 1e-18 kg.
# rho0=1.82e-6, cv=2355.592, k=0.361; Q is specific energy (nm/ns)^2.
# 5000 x 5000 nm; 250 x 250 cells; centered hotspot radius 500 nm, 1920/300 K.
# IMPORTANT: energy below means THERMAL energy density rho*cv*T, NOT total energy.
# Elastic isochoric dev(B), Y1 degradation, mixed JWL, FE compression heating.
# No J2 plasticity or plastic dissipation; no new C++ objects are introduced.
# Open mechanical/advection boundaries, insulated conduction; see companion doc.
# Momentum retains existing FVPlanarFlux acoustic stabilization; other transport
# uses base MOOSE FVMatAdvection, first-order upwind (not LWENO5).
# A 2 ns comparison horizon is selected; the FE input has no explicit end_time.
[GlobalParams]
  ghost_layers = 2
[]
[Mesh]
  [grid]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 250
    ny = 250
    xmax = 5000
    ymax = 5000
  []
[]
[Variables]
  [rho]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1.82e-6
  []
  [mx]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [my]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [energy]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rhoF00]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1.82e-6
  []
  [rhoF01]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rhoF10]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rhoF11]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1.82e-6
  []
  [rhoY1]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1.82e-6
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
[]
[ICs]
  [hotspot_energy]
    type = FunctionIC
    variable = energy
    function = '1.82e-6*2355.592*if((x-2500)^2+(y-2500)^2<=500^2,1920,300)'
  []
[]
[FunctorMaterials]
  [gradients]
    type = ADPlanarConservedGradients
    rho = rho
    mx = mx
    my = my
    # This helper assumes total energy in gradT; conduction below cancels
    # its kinetic-gradient subtraction because energy is thermal here.
    energy = energy
    cv = 2355.592
  []
  [u]
    type = ADParsedFunctorMaterial
    property_name = u
    functor_names = 'mx rho'
    expression = 'mx/rho'
  []
  [v]
    type = ADParsedFunctorMaterial
    property_name = v
    functor_names = 'my rho'
    expression = 'my/rho'
  []
  [temperature]
    type = ADParsedFunctorMaterial
    property_name = temperature
    functor_names = 'energy rho'
    expression = 'energy/(rho*2355.592)'
  []
  [B00]
    type = ADParsedFunctorMaterial
    property_name = B00
    functor_names = 'J F00 F01'
    expression = '(F00^2+F01^2)/J^(2/3)'
  []
  [B01]
    type = ADParsedFunctorMaterial
    property_name = B01
    functor_names = 'J F00 F01 F10 F11'
    expression = '(F00*F10+F01*F11)/J^(2/3)'
  []
  [B11]
    type = ADParsedFunctorMaterial
    property_name = B11
    functor_names = 'J F10 F11'
    expression = '(F10^2+F11^2)/J^(2/3)'
  []
  [Btrace]
    type = ADParsedFunctorMaterial
    property_name = Btrace
    functor_names = 'B00 B11 J'
    expression = 'B00+B11+J^(-2/3)'
  []
  [effective_mu]
    type = ADParsedFunctorMaterial
    property_name = effective_mu
    functor_names = 'Y1'
    expression = '12.80709677419355*max(0,min(1,Y1))'
  []
  [sxx]
    type = ADParsedFunctorMaterial
    property_name = sxx
    functor_names = 'effective_mu B00 Btrace'
    expression = 'effective_mu*(B00-Btrace/3)'
  []
  [syy]
    type = ADParsedFunctorMaterial
    property_name = syy
    functor_names = 'effective_mu B11 Btrace'
    expression = 'effective_mu*(B11-Btrace/3)'
  []
  [szz]
    type = ADParsedFunctorMaterial
    property_name = szz
    functor_names = 'effective_mu Btrace J'
    expression = 'effective_mu*(J^(-2/3)-Btrace/3)'
  []
  [sxy]
    type = ADParsedFunctorMaterial
    property_name = sxy
    functor_names = 'effective_mu B01'
    expression = 'effective_mu*B01'
  []
  [von_mises]
    type = ADParsedFunctorMaterial
    property_name = von_mises
    functor_names = 'sxx syy szz sxy'
    expression = 'sqrt(1.5*(sxx^2+syy^2+szz^2+2*sxy^2))'
  []
  [dilatation]
    type = ADParsedFunctorMaterial
    property_name = dilatation
    functor_names = 'L00 L11'
    expression = 'L00+L11'
  []
  [artificial_pressure]
    type = ADParsedFunctorMaterial
    property_name = artificial_pressure
    functor_names = 'sound_speed dilatation'
    expression = '1.82e-6*(0.1*20^2*max(-dilatation,0)^2+sound_speed*20*max(-dilatation,0))'
  []
  [sigma_xx]
    type = ADParsedFunctorMaterial
    property_name = sigma_xx
    functor_names = 'sxx pressure artificial_pressure'
    expression = 'sxx-pressure-artificial_pressure'
  []
  [sigma_yy]
    type = ADParsedFunctorMaterial
    property_name = sigma_yy
    functor_names = 'syy pressure artificial_pressure'
    expression = 'syy-pressure-artificial_pressure'
  []
  [wave_speed]
    type = ADParsedFunctorMaterial
    property_name = wave_speed
    functor_names = 'u v sound_speed'
    expression = 'abs(u)+abs(v)+sound_speed'
  []
  [flux_mx_x]
    type = ADParsedFunctorMaterial
    property_name = flux_mx_x
    functor_names = 'mx u sigma_xx'
    expression = 'mx*u-sigma_xx'
  []
  [flux_mx_y]
    type = ADParsedFunctorMaterial
    property_name = flux_mx_y
    functor_names = 'mx v sxy'
    expression = 'mx*v-sxy'
  []
  [flux_my_x]
    type = ADParsedFunctorMaterial
    property_name = flux_my_x
    functor_names = 'my u sxy'
    expression = 'my*u-sxy'
  []
  [flux_my_y]
    type = ADParsedFunctorMaterial
    property_name = flux_my_y
    functor_names = 'my v sigma_yy'
    expression = 'my*v-sigma_yy'
  []
  [flux_energy_x]
    type = ADParsedFunctorMaterial
    property_name = flux_energy_x
    functor_names = 'gradT0 u v L00 L10'
    expression = '-0.361*(gradT0+(u*L00+v*L10)/2355.592)'
  []
  [flux_energy_y]
    type = ADParsedFunctorMaterial
    property_name = flux_energy_y
    functor_names = 'gradT1 u v L01 L11'
    expression = '-0.361*(gradT1+(u*L01+v*L11)/2355.592)'
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
    expression = '-32002.15963286241+591.0987132187528*max(temperature-1736.3,0)'
  []
  [Q2]
    type = ADParsedFunctorMaterial
    property_name = Q2
    functor_names = 'temperature'
    expression = '7831116.710159273-722.1193197156482*max(temperature-1736.3,0)'
  []
  [heat]
    type = ADParsedFunctorMaterial
    property_name = heat
    functor_names = 'Q1 Q2 consume1 consume2'
    expression = 'Q1*consume1+Q2*consume2'
  []
  [J]
    type = ADParsedFunctorMaterial
    property_name = J
    functor_names = 'F00 F01 F10 F11'
    expression = 'F00*F11-F01*F10'
  []
  [Jrho_error]
    type = ADParsedFunctorMaterial
    property_name = Jrho_error
    functor_names = 'rho J'
    expression = 'rho*J/1.82e-6-1'
  []
  [species_error]
    type = ADParsedFunctorMaterial
    property_name = species_error
    functor_names = 'rhoY1 rhoY2 rhoY3 rho'
    expression = '(rhoY1+rhoY2+rhoY3)/rho-1'
  []
  [F00]
    type = ADParsedFunctorMaterial
    property_name = F00
    functor_names = 'rhoF00 rho'
    expression = 'rhoF00/rho'
  []
  [source_F00]
    type = ADParsedFunctorMaterial
    property_name = source_F00
    functor_names = 'L00 L01 rhoF00 rhoF10'
    expression = 'L00*rhoF00+L01*rhoF10'
  []
  [F01]
    type = ADParsedFunctorMaterial
    property_name = F01
    functor_names = 'rhoF01 rho'
    expression = 'rhoF01/rho'
  []
  [source_F01]
    type = ADParsedFunctorMaterial
    property_name = source_F01
    functor_names = 'L00 L01 rhoF01 rhoF11'
    expression = 'L00*rhoF01+L01*rhoF11'
  []
  [F10]
    type = ADParsedFunctorMaterial
    property_name = F10
    functor_names = 'rhoF10 rho'
    expression = 'rhoF10/rho'
  []
  [source_F10]
    type = ADParsedFunctorMaterial
    property_name = source_F10
    functor_names = 'L10 L11 rhoF00 rhoF10'
    expression = 'L10*rhoF00+L11*rhoF10'
  []
  [F11]
    type = ADParsedFunctorMaterial
    property_name = F11
    functor_names = 'rhoF11 rho'
    expression = 'rhoF11/rho'
  []
  [source_F11]
    type = ADParsedFunctorMaterial
    property_name = source_F11
    functor_names = 'L10 L11 rhoF01 rhoF11'
    expression = 'L10*rhoF01+L11*rhoF11'
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
  [velocity]
    type = ADComputeComponentVector
    x_component = u
    y_component = v
    z_component = 0
    vector_name = velocity
  []
  [Y_clamped]
    type = ADParsedFunctorMaterial
    property_name = Y_clamped
    functor_names = 'Y1'
    expression = 'max(0,min(1,Y1))'
  []
  [omega_mix]
    type = ADParsedFunctorMaterial
    property_name = omega_mix
    functor_names = 'Y_clamped'
    expression = 'Y_clamped*0.37+(1-Y_clamped)*0.77'
  []
  [sound_speed]
    type = ADParsedFunctorMaterial
    property_name = sound_speed
    functor_names = 'J'
    expression = 'sqrt((20.36+4/3*12.80709677419355)*J/1.82e-6)'
  []
  # Adapt the existing JWL object thermal term omega*energy/density/J.
  # This numerator is rho0^2*cv*(T-300), NOT physical energy density.
  [jwl_energy_numerator]
    type = ADParsedFunctorMaterial
    property_name = jwl_energy_numerator
    functor_names = 'temperature'
    expression = '(1.82e-6)^2*2355.592*(temperature-300)'
  []
  [jwl_unreacted]
    type = ADFVComputeJWLPressure
    A_name = 13398.42268091
    B_name = 3810.3712782
    R1_name = 68.1217746
    R2_name = 6.81217746
    omega_name = 0.37
    Jacobian_name = J
    energy_name = jwl_energy_numerator
    density_name = 1.82e-6
    pressure_name = pressure_unreacted_raw
  []
  [jwl_reacted]
    type = ADFVComputeJWLPressure
    A_name = 1000
    B_name = 2738.01645291
    R1_name = 59.99058313
    R2_name = 5.999058313
    omega_name = 0.77
    Jacobian_name = J
    energy_name = jwl_energy_numerator
    density_name = 1.82e-6
    pressure_name = pressure_reacted_raw
  []
  [pressure]
    type = ADParsedFunctorMaterial
    property_name = pressure
    functor_names = 'Y_clamped pressure_unreacted_raw pressure_reacted_raw'
    expression = 'Y_clamped*(pressure_unreacted_raw-13398.42268091*exp(-68.1217746)-3810.3712782*exp(-6.81217746))+(1-Y_clamped)*(pressure_reacted_raw-1000*exp(-59.99058313)-2738.01645291*exp(-5.999058313))'
  []
  [compression_heat]
    type = ADParsedFunctorMaterial
    property_name = compression_heat
    functor_names = 'omega_mix energy dilatation'
    expression = '-omega_mix*energy*dilatation'
  []
[]
[FVKernels]
  [rho_time]
    type = FVTimeKernel
    variable = rho
  []
  [rho_flux]
    type = FVMatAdvection
    variable = rho
    vel = velocity
    advected_interp_method = upwind
    force_boundary_execution = true
  []
  [mx_time]
    type = FVTimeKernel
    variable = mx
  []
  [mx_flux]
    type = FVPlanarFlux
    variable = mx
    flux_x = flux_mx_x
    flux_y = flux_mx_y
    wave_speed = wave_speed
  []
  [my_time]
    type = FVTimeKernel
    variable = my
  []
  [my_flux]
    type = FVPlanarFlux
    variable = my
    flux_x = flux_my_x
    flux_y = flux_my_y
    wave_speed = wave_speed
  []
  [energy_time]
    type = FVTimeKernel
    variable = energy
  []
  [energy_flux]
    type = FVMatAdvection
    variable = energy
    vel = velocity
    advected_interp_method = upwind
    force_boundary_execution = true
  []
  [rhoF00_time]
    type = FVTimeKernel
    variable = rhoF00
  []
  [rhoF00_flux]
    type = FVMatAdvection
    variable = rhoF00
    vel = velocity
    advected_interp_method = upwind
    force_boundary_execution = true
  []
  [rhoF01_time]
    type = FVTimeKernel
    variable = rhoF01
  []
  [rhoF01_flux]
    type = FVMatAdvection
    variable = rhoF01
    vel = velocity
    advected_interp_method = upwind
    force_boundary_execution = true
  []
  [rhoF10_time]
    type = FVTimeKernel
    variable = rhoF10
  []
  [rhoF10_flux]
    type = FVMatAdvection
    variable = rhoF10
    vel = velocity
    advected_interp_method = upwind
    force_boundary_execution = true
  []
  [rhoF11_time]
    type = FVTimeKernel
    variable = rhoF11
  []
  [rhoF11_flux]
    type = FVMatAdvection
    variable = rhoF11
    vel = velocity
    advected_interp_method = upwind
    force_boundary_execution = true
  []
  [rhoY1_time]
    type = FVTimeKernel
    variable = rhoY1
  []
  [rhoY1_flux]
    type = FVMatAdvection
    variable = rhoY1
    vel = velocity
    advected_interp_method = upwind
    force_boundary_execution = true
  []
  [rhoY2_time]
    type = FVTimeKernel
    variable = rhoY2
  []
  [rhoY2_flux]
    type = FVMatAdvection
    variable = rhoY2
    vel = velocity
    advected_interp_method = upwind
    force_boundary_execution = true
  []
  [rhoY3_time]
    type = FVTimeKernel
    variable = rhoY3
  []
  [rhoY3_flux]
    type = FVMatAdvection
    variable = rhoY3
    vel = velocity
    advected_interp_method = upwind
    force_boundary_execution = true
  []
  [energy_source]
    type = FVCoupledForce
    variable = energy
    v = heat
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
    v = source_Y2
    coef = 1
  []
  [rhoY3_source]
    type = FVCoupledForce
    variable = rhoY3
    v = consume2
    coef = 1
  []
  [rhoF00_source]
    type = FVCoupledForce
    variable = rhoF00
    v = source_F00
    coef = 1
  []
  [rhoF01_source]
    type = FVCoupledForce
    variable = rhoF01
    v = source_F01
    coef = 1
  []
  [rhoF10_source]
    type = FVCoupledForce
    variable = rhoF10
    v = source_F10
    coef = 1
  []
  [rhoF11_source]
    type = FVCoupledForce
    variable = rhoF11
    v = source_F11
    coef = 1
  []
  [conduction]
    type = FVPlanarFlux
    variable = energy
    flux_x = flux_energy_x
    flux_y = flux_energy_y
    wave_speed = 0
    dissipation = 0
    force_boundary_execution = false
    boundaries_to_avoid = 'left right bottom top'
  []
  [compression_heat]
    type = FVCoupledForce
    variable = energy
    v = compression_heat
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
  [v_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [F00_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [F01_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [F10_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [F11_out]
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
  [syy_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [sxy_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [von_mises_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [J_out]
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
  [artificial_pressure_out]
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
  [v]
    type = FunctorAux
    variable = v_out
    functor = v
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [F00]
    type = FunctorAux
    variable = F00_out
    functor = F00
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [F01]
    type = FunctorAux
    variable = F01_out
    functor = F01
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [F10]
    type = FunctorAux
    variable = F10_out
    functor = F10
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [F11]
    type = FunctorAux
    variable = F11_out
    functor = F11
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
  [syy]
    type = FunctorAux
    variable = syy_out
    functor = syy
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [sxy]
    type = FunctorAux
    variable = sxy_out
    functor = sxy
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [von_mises]
    type = FunctorAux
    variable = von_mises_out
    functor = von_mises
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [J]
    type = FunctorAux
    variable = J_out
    functor = J
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
  [artificial_pressure]
    type = FunctorAux
    variable = artificial_pressure_out
    functor = artificial_pressure
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[Postprocessors]
  [rho_mean]
    type = ElementAverageValue
    variable = rho
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [mx_mean]
    type = ElementAverageValue
    variable = mx
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [my_mean]
    type = ElementAverageValue
    variable = my
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
  [TimeStepper]
    type = FunctionDT
    function = timestep
    min_dt = 1e-8
  []
  end_time = 2
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-8
  automatic_scaling = true
  line_search = none
  petsc_options_iname = '-ksp_gmres_restart -pc_type -pc_hypre_type'
  petsc_options_value = '401 hypre boomeramg'
  l_max_its = 300
[]
[Functions]
  [timestep]
    type = ParsedFunction
    expression = '1e-3'
  []
[]
[Outputs]
  exodus = true
  csv = true
  time_step_interval = 5
[]
