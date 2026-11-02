# 2D Eulerian FV circular-hotspot case matching sakano_T_Y_P_1um_lump.i.
# Units: um, ns, GPa, K. Same FV EOS, elastic dev(B), energy and reaction model.
# Plane strain: Fzz=1, Fxz=Fyz=Fzx=Fzy=0; both in-plane momenta evolve.
# No plasticity or JWL replacement. Existing 1D cases remain unchanged.
# 250 x 250 cells: h=0.02 um. Update AV spacing if changing the mesh.
# Required for neighbor-cell gradients across MPI partitions, including older builds.
[GlobalParams]
  ghost_layers = 2
[]
[Mesh]
  [grid]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 250
    ny = 250
    xmax = 5
    ymax = 5
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
    initial_condition = 0
  []
  [energy]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rhoF00]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1.82
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
    initial_condition = 1.82
  []
  [rhoY1]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1.82
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
    function = '1.82*0.002355592*if((x-2.5)^2+(y-2.5)^2<=0.5^2,1920,300)'
  []
[]
[FunctorMaterials]
  [gradients]
    type = ADPlanarConservedGradients
    rho = rho
    mx = mx
    my = my
    energy = energy
    cv = 0.002355592
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
  [internal_energy_density]
    type = ADParsedFunctorMaterial
    property_name = internal_energy_density
    functor_names = 'energy mx my rho'
    expression = 'energy-0.5*(mx^2+my^2)/rho'
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
  [B00]
    type = ADParsedFunctorMaterial
    property_name = B00
    functor_names = 'F00 F01'
    expression = 'F00^2+F01^2'
  []
  [B01]
    type = ADParsedFunctorMaterial
    property_name = B01
    functor_names = 'F00 F01 F10 F11'
    expression = 'F00*F10+F01*F11'
  []
  [B11]
    type = ADParsedFunctorMaterial
    property_name = B11
    functor_names = 'F10 F11'
    expression = 'F10^2+F11^2'
  []
  [Btrace]
    type = ADParsedFunctorMaterial
    property_name = Btrace
    functor_names = 'B00 B11'
    expression = 'B00+B11+1'
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
    functor_names = 'effective_mu Btrace'
    expression = 'effective_mu*(1-Btrace/3)'
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
    functor_names = 'rho dilatation'
    expression = 'rho*(0.1*4*0.02*max(-dilatation,0)+0.02^2*max(-dilatation,0)^2)'
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
    functor_names = 'u v'
    expression = 'abs(u)+abs(v)+8'
  []
  [flux_rho_x]
    type = ADParsedFunctorMaterial
    property_name = flux_rho_x
    functor_names = 'mx'
    expression = 'mx'
  []
  [flux_rho_y]
    type = ADParsedFunctorMaterial
    property_name = flux_rho_y
    functor_names = 'my'
    expression = 'my'
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
    functor_names = 'energy u v sigma_xx sxy gradT0'
    expression = 'energy*u-sigma_xx*u-sxy*v-0.361e-6*gradT0'
  []
  [flux_energy_y]
    type = ADParsedFunctorMaterial
    property_name = flux_energy_y
    functor_names = 'energy u v sigma_yy sxy gradT1'
    expression = 'energy*v-sxy*u-sigma_yy*v-0.361e-6*gradT1'
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
    expression = 'rho*J/1.82-1'
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
  [flux_rhoF00_x]
    type = ADParsedFunctorMaterial
    property_name = flux_rhoF00_x
    functor_names = 'rhoF00 u'
    expression = 'rhoF00*u'
  []
  [flux_rhoF00_y]
    type = ADParsedFunctorMaterial
    property_name = flux_rhoF00_y
    functor_names = 'rhoF00 v'
    expression = 'rhoF00*v'
  []
  [flux_rhoF01_x]
    type = ADParsedFunctorMaterial
    property_name = flux_rhoF01_x
    functor_names = 'rhoF01 u'
    expression = 'rhoF01*u'
  []
  [flux_rhoF01_y]
    type = ADParsedFunctorMaterial
    property_name = flux_rhoF01_y
    functor_names = 'rhoF01 v'
    expression = 'rhoF01*v'
  []
  [flux_rhoF10_x]
    type = ADParsedFunctorMaterial
    property_name = flux_rhoF10_x
    functor_names = 'rhoF10 u'
    expression = 'rhoF10*u'
  []
  [flux_rhoF10_y]
    type = ADParsedFunctorMaterial
    property_name = flux_rhoF10_y
    functor_names = 'rhoF10 v'
    expression = 'rhoF10*v'
  []
  [flux_rhoF11_x]
    type = ADParsedFunctorMaterial
    property_name = flux_rhoF11_x
    functor_names = 'rhoF11 u'
    expression = 'rhoF11*u'
  []
  [flux_rhoF11_y]
    type = ADParsedFunctorMaterial
    property_name = flux_rhoF11_y
    functor_names = 'rhoF11 v'
    expression = 'rhoF11*v'
  []
  [flux_rhoY1_x]
    type = ADParsedFunctorMaterial
    property_name = flux_rhoY1_x
    functor_names = 'rhoY1 u'
    expression = 'rhoY1*u'
  []
  [flux_rhoY1_y]
    type = ADParsedFunctorMaterial
    property_name = flux_rhoY1_y
    functor_names = 'rhoY1 v'
    expression = 'rhoY1*v'
  []
  [flux_rhoY2_x]
    type = ADParsedFunctorMaterial
    property_name = flux_rhoY2_x
    functor_names = 'rhoY2 u'
    expression = 'rhoY2*u'
  []
  [flux_rhoY2_y]
    type = ADParsedFunctorMaterial
    property_name = flux_rhoY2_y
    functor_names = 'rhoY2 v'
    expression = 'rhoY2*v'
  []
  [flux_rhoY3_x]
    type = ADParsedFunctorMaterial
    property_name = flux_rhoY3_x
    functor_names = 'rhoY3 u'
    expression = 'rhoY3*u'
  []
  [flux_rhoY3_y]
    type = ADParsedFunctorMaterial
    property_name = flux_rhoY3_y
    functor_names = 'rhoY3 v'
    expression = 'rhoY3*v'
  []
  [eos]
    type = ADComputeMieGruneisenPressure
    K0 = 20.36
    s = 1.5
    gamma = 1.2
    density_name = rho
    reference_density_name = 1.82
    # Energy densities compensate the existing EOS thermal-term convention.
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
    type = FVPlanarFlux
    variable = rho
    flux_x = flux_rho_x
    flux_y = flux_rho_y
    wave_speed = wave_speed
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
    type = FVPlanarFlux
    variable = energy
    flux_x = flux_energy_x
    flux_y = flux_energy_y
    wave_speed = wave_speed
  []
  [rhoF00_time]
    type = FVTimeKernel
    variable = rhoF00
  []
  [rhoF00_flux]
    type = FVPlanarFlux
    variable = rhoF00
    flux_x = flux_rhoF00_x
    flux_y = flux_rhoF00_y
    wave_speed = wave_speed
  []
  [rhoF01_time]
    type = FVTimeKernel
    variable = rhoF01
  []
  [rhoF01_flux]
    type = FVPlanarFlux
    variable = rhoF01
    flux_x = flux_rhoF01_x
    flux_y = flux_rhoF01_y
    wave_speed = wave_speed
  []
  [rhoF10_time]
    type = FVTimeKernel
    variable = rhoF10
  []
  [rhoF10_flux]
    type = FVPlanarFlux
    variable = rhoF10
    flux_x = flux_rhoF10_x
    flux_y = flux_rhoF10_y
    wave_speed = wave_speed
  []
  [rhoF11_time]
    type = FVTimeKernel
    variable = rhoF11
  []
  [rhoF11_flux]
    type = FVPlanarFlux
    variable = rhoF11
    flux_x = flux_rhoF11_x
    flux_y = flux_rhoF11_y
    wave_speed = wave_speed
  []
  [rhoY1_time]
    type = FVTimeKernel
    variable = rhoY1
  []
  [rhoY1_flux]
    type = FVPlanarFlux
    variable = rhoY1
    flux_x = flux_rhoY1_x
    flux_y = flux_rhoY1_y
    wave_speed = wave_speed
  []
  [rhoY2_time]
    type = FVTimeKernel
    variable = rhoY2
  []
  [rhoY2_flux]
    type = FVPlanarFlux
    variable = rhoY2
    flux_x = flux_rhoY2_x
    flux_y = flux_rhoY2_y
    wave_speed = wave_speed
  []
  [rhoY3_time]
    type = FVTimeKernel
    variable = rhoY3
  []
  [rhoY3_flux]
    type = FVPlanarFlux
    variable = rhoY3
    flux_x = flux_rhoY3_x
    flux_y = flux_rhoY3_y
    wave_speed = wave_speed
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
  dt = 0.001
  end_time = 2
  nl_rel_tol = 1e-9
  nl_abs_tol = 1e-11
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart'
  petsc_options_value = 'hypre boomeramg 100'
  l_max_its = 300
[]
[Outputs]
  exodus = true
  csv = true
  time_step_interval = 5
[]
