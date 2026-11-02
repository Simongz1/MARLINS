# INPUT TEMPLATE ONLY -- NOT RUNNABLE WITH THE CURRENT EXECUTABLE.
# Closure/post-closure variant. No C++ changes, builds, input checks or simulations.
# This file specifies a candidate run; it does NOT establish stable pore closure.
# The two proposed 2D FV types listed below still need implementation.
#
# Operational closure candidate (not an independently verified topology test):
#   - gas chord integral along y=2.5 falls below 0.05 um (two reference cells);
#   - total gas area falls below 50% of pi*(0.2 um)^2;
#   - no gas has reached an outer boundary (prevents counting gas loss as closure).
# First candidate time is latched; continue for another 1 ns before stopping.
# If no candidate occurs, stop at the 5 ns time cap with an explicit warning.
# Inspect the interface/jet near the reported candidate time before calling it closure.
#
# A nonzero gas mass remains after contact; zero gas area is NOT required.
# An even ny is required so the pore axis is an element-side line.
# Existing 2D input and all existing code are retained unchanged.
# Required, not-yet-implemented objects:
#   FVMaterialUpwindFlux2D: face-normal acoustic velocity/traction, limited material
#     transport, consistent solid/species mass fluxes, both momentum components,
#     stress work and conduction. Parameters below specify the proposed interface.
#   FVMaterialDilatationSource2D: uses EXACTLY the same vector face velocity as
#     the flux. scalar mode returns Q*div(u_star); tensor mode returns
#     sum_k L_star(row,k)*rhoSolidF(k,column), with L_star reconstructed from faces.
# These are proposed object names, not available MOOSE or application objects.
# No C++ changes or simulation runs were performed to produce this template.
#
# 2D counterpart of eulerian_fv_pore_1d_upwind.i. Units: um, ns, GPa, K.
# Circular gas-filled pore: centre (10.2,2.5), radius 0.2 um (diameter 0.4 um).
# Domain 20 x 5 um; 800 x 200 cells gives h=0.025 um in both directions.
# Initially u=1 for x<8, u=0 otherwise; v=0, T=300 K.
# Same solid/gas densities, phase/EOS/caloric/chemical model as the 1D case.
# Plane strain Fzz=1; all four in-plane F components evolve.
# Open extrapolated boundaries are assumed in the proposed flux, as in 1D.
# Common velocity/temperature diffuse mixture; not a vacuum/free-surface model.
# WENO5 IS NOT IMPLEMENTED OR SELECTABLE IN THIS TEMPLATE.
[GlobalParams]
  ghost_layers = 2
  reconstruction = minmod
[]
[Mesh]
  parallel_type = REPLICATED
  [grid]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 800
    ny = 200
    xmax = 20
    ymax = 5
  []
  # Add only the upward-oriented trace of the INTERNAL pore-axis sides.
  # This does not prescribe a BC or split the physical mesh into two domains.
  [pore_axis]
    type = ParsedGenerateSideset
    input = grid
    new_sideset_name = pore_axis
    combinatorial_geometry = 'abs(y-2.5)<1e-10'
    include_only_external_sides = false
    normal = '0 1 0'
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
  [mx]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [my]
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
  [rhoSolidF00]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rhoSolidF01]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rhoSolidF10]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rhoSolidF11]
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
    function = 'if((x-10.2)^2+(y-2.5)^2<=0.2^2,0.0182,1.82)'
  []
  [rho_solid]
    type = FunctionIC
    variable = rho_solid
    function = 'if((x-10.2)^2+(y-2.5)^2<=0.2^2,0,1.82)'
  []
  [mx]
    type = FunctionIC
    variable = mx
    function = '(if((x-10.2)^2+(y-2.5)^2<=0.2^2,0.0182,1.82))*if(x<8,1,0)'
  []
  [my]
    type = FunctionIC
    variable = my
    function = '0'
  []
  [energy]
    type = FunctionIC
    variable = energy
    function = '(if((x-10.2)^2+(y-2.5)^2<=0.2^2,0.0182,1.82))*(0.002355592*300+0.5*if(x<8,1,0))'
  []
  [solid_volume]
    type = FunctionIC
    variable = solid_volume
    function = 'if((x-10.2)^2+(y-2.5)^2<=0.2^2,0,1)'
  []
  [rhoSolidF00]
    type = FunctionIC
    variable = rhoSolidF00
    function = 'if((x-10.2)^2+(y-2.5)^2<=0.2^2,0,1.82)'
  []
  [rhoSolidF01]
    type = FunctionIC
    variable = rhoSolidF01
    function = '0'
  []
  [rhoSolidF10]
    type = FunctionIC
    variable = rhoSolidF10
    function = '0'
  []
  [rhoSolidF11]
    type = FunctionIC
    variable = rhoSolidF11
    function = 'if((x-10.2)^2+(y-2.5)^2<=0.2^2,0,1.82)'
  []
  [rhoY1]
    type = FunctionIC
    variable = rhoY1
    function = 'if((x-10.2)^2+(y-2.5)^2<=0.2^2,0,1.82)'
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
  [internal_energy_density]
    type = ADParsedFunctorMaterial
    property_name = internal_energy_density
    functor_names = 'energy mx my rho'
    expression = 'energy-0.5*(mx^2+my^2)/rho'
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
    functor_names = 'alpha Y1'
    expression = 'alpha*max(0,min(1,Y1))*12.80709677419355'
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
    expression = 'rho*(0.1*4*0.025*max(-dilatation,0)+0.025^2*max(-dilatation,0)^2)'
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
  [conductivity]
    type = ADParsedFunctorMaterial
    property_name = conductivity
    functor_names = 'alpha'
    expression = 'alpha*0.361e-6+(1-alpha)*0.026e-6'
  []
  [heat_flux_x]
    type = ADParsedFunctorMaterial
    property_name = heat_flux_x
    functor_names = 'conductivity gradT0'
    expression = '-conductivity*gradT0'
  []
  [heat_flux_y]
    type = ADParsedFunctorMaterial
    property_name = heat_flux_y
    functor_names = 'conductivity gradT1'
    expression = '-conductivity*gradT1'
  []
  [impedance]
    type = ADParsedFunctorMaterial
    property_name = impedance
    functor_names = 'rho alpha pressure'
    expression = 'sqrt(rho*(alpha*(20.36+4/3*12.80709677419355)+(1-alpha)*1.4*max(pressure,0.005144612928)))'
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
  [J]
    type = ADParsedFunctorMaterial
    property_name = J
    functor_names = 'F00 F01 F10 F11'
    expression = 'F00*F11-F01*F10'
  []
  [Jrho_error]
    type = ADParsedFunctorMaterial
    property_name = Jrho_error
    functor_names = 'alpha solid_density J'
    expression = 'if(alpha>0.1,solid_density*J/1.82-1,0)'
  []
  [gas_fraction]
    type = ADParsedFunctorMaterial
    property_name = gas_fraction
    functor_names = 'alpha'
    expression = '1-alpha'
  []
  [F00]
    type = ADParsedFunctorMaterial
    property_name = F00
    functor_names = 'rhoSolidF00 rho_solid'
    expression = 'if(rho_solid>1e-10,rhoSolidF00/max(rho_solid,1e-10),1)'
  []
  [F01]
    type = ADParsedFunctorMaterial
    property_name = F01
    functor_names = 'rhoSolidF01 rho_solid'
    expression = 'if(rho_solid>1e-10,rhoSolidF01/max(rho_solid,1e-10),0)'
  []
  [F10]
    type = ADParsedFunctorMaterial
    property_name = F10
    functor_names = 'rhoSolidF10 rho_solid'
    expression = 'if(rho_solid>1e-10,rhoSolidF10/max(rho_solid,1e-10),0)'
  []
  [F11]
    type = ADParsedFunctorMaterial
    property_name = F11
    functor_names = 'rhoSolidF11 rho_solid'
    expression = 'if(rho_solid>1e-10,rhoSolidF11/max(rho_solid,1e-10),1)'
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
  [solid_eos]
    type = ADComputeMieGruneisenPressure
    K0 = 20.36
    s = 1.5
    gamma = 1.2
    density_name = solid_density
    reference_density_name = 1.82
    # Energy-density arguments retain the existing EOS object's convention.
    sie_name = solid_internal_energy_density
    sie0_name = solid_reference_energy_density
    pressure_name = solid_pressure
  []
[]
[FVKernels]
  # The 2D flux and source types below are REQUIRED EXTENSIONS, not registered objects.
  [rho_time]
    type = FVTimeKernel
    variable = rho
  []
  [rho_flux]
    type = FVMaterialUpwindFlux2D
    variable = rho
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
    equation = transport
  []
  [rho_solid_time]
    type = FVTimeKernel
    variable = rho_solid
  []
  [rho_solid_flux]
    type = FVMaterialUpwindFlux2D
    variable = rho_solid
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
    equation = transport
    material_component = solid
    density = rho
    solid_density = rho_solid
    species = 'rhoY1 rhoY2 rhoY3'
  []
  [mx_time]
    type = FVTimeKernel
    variable = mx
  []
  [mx_flux]
    type = FVMaterialUpwindFlux2D
    variable = mx
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
    equation = momentum_x
  []
  [my_time]
    type = FVTimeKernel
    variable = my
  []
  [my_flux]
    type = FVMaterialUpwindFlux2D
    variable = my
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
    equation = momentum_y
  []
  [energy_time]
    type = FVTimeKernel
    variable = energy
  []
  [energy_flux]
    type = FVMaterialUpwindFlux2D
    variable = energy
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
    equation = energy
    heat_flux_x = heat_flux_x
    heat_flux_y = heat_flux_y
  []
  [solid_volume_time]
    type = FVTimeKernel
    variable = solid_volume
  []
  [solid_volume_flux]
    type = FVMaterialUpwindFlux2D
    variable = solid_volume
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
    equation = transport
  []
  [rhoSolidF00_time]
    type = FVTimeKernel
    variable = rhoSolidF00
  []
  [rhoSolidF00_flux]
    type = FVMaterialUpwindFlux2D
    variable = rhoSolidF00
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
    equation = transport
  []
  [rhoSolidF01_time]
    type = FVTimeKernel
    variable = rhoSolidF01
  []
  [rhoSolidF01_flux]
    type = FVMaterialUpwindFlux2D
    variable = rhoSolidF01
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
    equation = transport
  []
  [rhoSolidF10_time]
    type = FVTimeKernel
    variable = rhoSolidF10
  []
  [rhoSolidF10_flux]
    type = FVMaterialUpwindFlux2D
    variable = rhoSolidF10
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
    equation = transport
  []
  [rhoSolidF11_time]
    type = FVTimeKernel
    variable = rhoSolidF11
  []
  [rhoSolidF11_flux]
    type = FVMaterialUpwindFlux2D
    variable = rhoSolidF11
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
    equation = transport
  []
  [rhoY1_time]
    type = FVTimeKernel
    variable = rhoY1
  []
  [rhoY1_flux]
    type = FVMaterialUpwindFlux2D
    variable = rhoY1
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
    equation = transport
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
    type = FVMaterialUpwindFlux2D
    variable = rhoY2
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
    equation = transport
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
    type = FVMaterialUpwindFlux2D
    variable = rhoY3
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
    equation = transport
    material_component = species3
    density = rho
    solid_density = rho_solid
    species = 'rhoY1 rhoY2 rhoY3'
  []
  [volume_source]
    type = FVMaterialDilatationSource2D
    variable = solid_volume
    mode = scalar
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
  []
  [F00_source]
    type = FVMaterialDilatationSource2D
    variable = rhoSolidF00
    mode = tensor
    tensor_row = 0
    tensor_column = 0
    deformation = 'rhoSolidF00 rhoSolidF01 rhoSolidF10 rhoSolidF11'
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
  []
  [F01_source]
    type = FVMaterialDilatationSource2D
    variable = rhoSolidF01
    mode = tensor
    tensor_row = 0
    tensor_column = 1
    deformation = 'rhoSolidF00 rhoSolidF01 rhoSolidF10 rhoSolidF11'
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
  []
  [F10_source]
    type = FVMaterialDilatationSource2D
    variable = rhoSolidF10
    mode = tensor
    tensor_row = 1
    tensor_column = 0
    deformation = 'rhoSolidF00 rhoSolidF01 rhoSolidF10 rhoSolidF11'
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
  []
  [F11_source]
    type = FVMaterialDilatationSource2D
    variable = rhoSolidF11
    mode = tensor
    tensor_row = 1
    tensor_column = 1
    deformation = 'rhoSolidF00 rhoSolidF01 rhoSolidF10 rhoSolidF11'
    velocity_x = u
    velocity_y = v
    stress_xx = sigma_xx
    stress_xy = sxy
    stress_yy = sigma_yy
    impedance = impedance
  []
  [rhoY1_reaction]
    type = FVCoupledForce
    variable = rhoY1
    v = consume1
    coef = -1
  []
  [rhoY2_reaction]
    type = FVCoupledForce
    variable = rhoY2
    v = source_Y2
    coef = 1
  []
  [rhoY3_reaction]
    type = FVCoupledForce
    variable = rhoY3
    v = consume2
    coef = 1
  []
  [energy_reaction]
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
  [gas_fraction_out]
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
  [J_out]
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
  [gas_fraction]
    type = FunctorAux
    variable = gas_fraction_out
    functor = gas_fraction
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
  [J]
    type = FunctorAux
    variable = J_out
    functor = J
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
  [species_error_out_mean]
    type = ElementAverageValue
    variable = species_error_out
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Jrho_error_out_mean]
    type = ElementAverageValue
    variable = Jrho_error_out
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [gas_area]
    type = ElementIntegralVariablePostprocessor
    variable = gas_fraction_out
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [clock]
    type = TimePostprocessor
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [centreline_gas_length]
    type = SideIntegralVariablePostprocessor
    variable = gas_fraction_out
    boundary = pore_axis
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [outer_gas_trace]
    type = SideIntegralVariablePostprocessor
    variable = gas_fraction_out
    boundary = 'left right top bottom'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [gas_area_ratio]
    type = ParsedPostprocessor
    pp_names = gas_area
    expression = 'gas_area/(0.12566370614359174)'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [closure_candidate_time]
    type = ParsedPostprocessor
    pp_names = 'clock centreline_gas_length gas_area outer_gas_trace'
    expression = 'if(clock>0.05 & centreline_gas_length<0.05 & gas_area<0.5*0.12566370614359174 & outer_gas_trace<1e-6,clock,1e20)'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [first_closure_candidate]
    type = TimeExtremeValue
    postprocessor = closure_candidate_time
    value_type = min
    output_type = extreme_value
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [closure_candidate_seen]
    type = ParsedPostprocessor
    pp_names = first_closure_candidate
    expression = 'if(first_closure_candidate<1e10,1,0)'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [post_closure_time]
    type = ParsedPostprocessor
    pp_names = 'clock first_closure_candidate'
    expression = 'if(first_closure_candidate<1e10,max(0,clock-first_closure_candidate),0)'
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 0.001
  dtmin = 1e-7
  end_time = 5
  nl_rel_tol = 1e-9
  nl_abs_tol = 1e-11
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart'
  petsc_options_value = 'hypre boomeramg 100'
  l_max_its = 300
[]
[UserObjects]
  [finish_post_closure]
    type = Terminator
    expression = 'closure_candidate_seen>0.5 & post_closure_time>=1.0'
    fail_mode = HARD
    error_level = INFO
    message = 'Completed 1 ns after the operational closure candidate. Inspect interface fields to confirm jet/wall contact.'
    execute_on = TIMESTEP_END
  []
  [closure_not_observed]
    type = Terminator
    expression = 'clock>=5 & closure_candidate_seen<0.5'
    fail_mode = NONE
    error_level = WARNING
    message = 'Reached 5 ns without meeting the operational pore-closure criterion. This is not a verified post-closure run.'
    execute_on = TIMESTEP_END
  []
[]
[Outputs]
  [fields]
    type = Exodus
    execute_on = 'INITIAL TIMESTEP_END FINAL'
    time_step_interval = 5
  []
  [history]
    type = CSV
    execute_on = 'INITIAL TIMESTEP_END FINAL'
  []
  [console]
    type = Console
    time_step_interval = 25
  []
  [checkpoints]
    type = Checkpoint
    wall_time_interval = 2000
    num_files = 2
  []
[]
