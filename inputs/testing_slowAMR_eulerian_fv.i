# Eulerian FV counterpart of testing_slowAMR.i. Units: um, ns, GPa, K.
# FIXED SPATIAL mesh; all conservation equations and material histories advect.
# Spherical PBX/JWL stress, no J2 plasticity or plastic dissipation.
# The bottom is a prescribed inflow of bulk RDX, NOT an advancing piston.
# See doc/testing_slowAMR_eulerian_fv.md, especially mixed-history closure.
[GlobalParams]
  ghost_layers = 2
  csv_directory = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv'
[]
[Mesh]
  parallel_type = REPLICATED
  [generated]
    type = GeneratedMeshGenerator
    extra_element_integers = 'microstructure_id legacy_prediction_id'
    elem_type = QUAD4
    dim = 2
    nx = 80
    ny = 300
    xmax = 80
    ymax = 300
  []
[]
[Variables]
  [rho]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
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
  [thermal_energy]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rhoF00]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
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
  []
  [rhoY1]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
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
  [rho_species_total]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rho_inv_rho0]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rho_phi]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [rho_X]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    # IOSS groups rho_X/rho_Y into a vector named rho, colliding with density.
    # The derived X_material/Y_material fields remain available for plotting.
    outputs = none
  []
  [rho_Y]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    outputs = none
  []
  [rho_inlet]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_active]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_active_phi]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_Tshock]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_Treact]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_tau]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_up]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_tracking]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_shock_clock]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [rho_react_clock]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
[]
[ICs]
  [rho]
    type = FVEulerianMicrostructureIC
    variable = rho
    quantity = rho
  []
  [thermal_energy]
    type = FVEulerianMicrostructureIC
    variable = thermal_energy
    quantity = thermal
  []
  [rhoF00]
    type = FVEulerianMicrostructureIC
    variable = rhoF00
    quantity = diagonal_F
  []
  [rhoF11]
    type = FVEulerianMicrostructureIC
    variable = rhoF11
    quantity = diagonal_F
  []
  [rhoY1]
    type = FVEulerianMicrostructureIC
    variable = rhoY1
    quantity = Y1
  []
  [rho_species_total]
    type = FVEulerianMicrostructureIC
    variable = rho_species_total
    quantity = Y1
  []
  [rho_inv_rho0]
    type = FVEulerianMicrostructureIC
    variable = rho_inv_rho0
    quantity = reference_volume
  []
  [rho_phi]
    type = FVEulerianMicrostructureIC
    variable = rho_phi
    quantity = phi
  []
  [rho_X]
    type = FVEulerianMicrostructureIC
    variable = rho_X
    quantity = X
  []
  [rho_Y]
    type = FVEulerianMicrostructureIC
    variable = rho_Y
    quantity = Y
  []
[]
[UserObjects]
  [voronoi_density]
    type = PolycrystalDensityIntegerLegacyUO
    initial_reactant_variable = rhoY1
    microstructure_id_name = microstructure_id
    prediction_id_name = legacy_prediction_id
    num_grains = 800
    target_grains = '1'
    range_in = '1 90'
    range_out = '1 90'
    generate_matrix = true
    max_grain_size = 1000
    execute_on = 'INITIAL TIMESTEP_END'
    min_center_spacing = 30
    matrix_thickness = 5
    sizes = '30 100'
    sizes_fraction = '0.7 0.3'
    csv_fraction = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/fractions_new.csv'
    csv_fraction_pore = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/fraction_pore.csv'
    bulk_grains = true
    n_pores = 10000000
    pore_probability = 0.01
    bulk_MicroID = 99
    bulk_RDX_fraction = 1
    pore_RDX_fraction = 1
    range_pore = '101 103'
    use_loaded_microstructure = false
  []
  [mist_events]
    type = FVEulerianMISTnetEvents
    thr_v = 0.5
    tau_react_scaling = 1
  []
[]
[AuxVariables]
  [density_i]
    type = MooseVariableFVReal
    outputs = none
  []
  [grainID]
    type = MooseVariableFVReal
    outputs = none
  []
  [temperature_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [Y1]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [Y2]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [Y3]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [density_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [reference_density_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [fraction_csv]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [u_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [v_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [J_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [Jrho_error_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [pressure_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [artificial_pressure_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [s_pressure]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [X_material]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [Y_material]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [active_fraction_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [Tshock_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [Treact_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [time_react_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [called_up_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [dirac_switch_shock]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [dirac_switch_react]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [tracking]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [inlet_fraction_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [species_error_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [Y2_flag]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [von_mises]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
[]
[AuxKernels]
  [temperature_out]
    type = FunctorAux
    variable = temperature_out
    functor = temperature
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Y1]
    type = FunctorAux
    variable = Y1
    functor = Y1_fraction
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Y2]
    type = FunctorAux
    variable = Y2
    functor = Y2_fraction
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Y3]
    type = FunctorAux
    variable = Y3
    functor = Y3_fraction
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [density_out]
    type = FunctorAux
    variable = density_out
    functor = rho
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_density_out]
    type = FunctorAux
    variable = reference_density_out
    functor = reference_density
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [fraction_csv]
    type = FunctorAux
    variable = fraction_csv
    functor = fraction
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [u_out]
    type = FunctorAux
    variable = u_out
    functor = u
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [v_out]
    type = FunctorAux
    variable = v_out
    functor = v
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [J_out]
    type = FunctorAux
    variable = J_out
    functor = J
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Jrho_error_out]
    type = FunctorAux
    variable = Jrho_error_out
    functor = Jrho_error
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [pressure_out]
    type = FunctorAux
    variable = pressure_out
    functor = pressure
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [artificial_pressure_out]
    type = FunctorAux
    variable = artificial_pressure_out
    functor = artificial_pressure
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [s_pressure]
    type = FunctorAux
    variable = s_pressure
    functor = spherical_stress
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [X_material]
    type = FunctorAux
    variable = X_material
    functor = material_X
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Y_material]
    type = FunctorAux
    variable = Y_material
    functor = material_Y
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [active_fraction_out]
    type = FunctorAux
    variable = active_fraction_out
    functor = active_fraction
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Tshock_out]
    type = FunctorAux
    variable = Tshock_out
    functor = target_shock
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Treact_out]
    type = FunctorAux
    variable = Treact_out
    functor = target_react
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [time_react_out]
    type = FunctorAux
    variable = time_react_out
    functor = time_react
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [called_up_out]
    type = FunctorAux
    variable = called_up_out
    functor = called_up
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [dirac_switch_shock]
    type = FunctorAux
    variable = dirac_switch_shock
    functor = shock_clock
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [dirac_switch_react]
    type = FunctorAux
    variable = dirac_switch_react
    functor = react_clock
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [tracking]
    type = FunctorAux
    variable = tracking
    functor = tracking_fraction
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [inlet_fraction_out]
    type = FunctorAux
    variable = inlet_fraction_out
    functor = inlet_fraction
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [species_error_out]
    type = FunctorAux
    variable = species_error_out
    functor = species_error
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [interface]
    type = FVProductInterfaceAux
    variable = Y2_flag
    products = Y3_fraction
    reaction_clock = react_clock
    reaction_duration = time_react
    jump_threshold = 0.1
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[FunctorMaterials]
  [constitutive]
    type = ADFVEulerianPBX
    rho = rho
    mx = mx
    my = my
    thermal_energy = thermal_energy
    rho_inv_rho0 = rho_inv_rho0
    rho_phi = rho_phi
    rhoY1 = rhoY1
    rhoF00 = rhoF00
    rhoF01 = rhoF01
    rhoF10 = rhoF10
    rhoF11 = rhoF11
    cv = 0.002355592
    C0 = 0.1
    C1 = 1
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
  [fraction]
    type = ADParsedFunctorMaterial
    property_name = fraction
    functor_names = 'rho_phi rho'
    expression = 'rho_phi/rho'
  []
  [Y1_fraction]
    type = ADParsedFunctorMaterial
    property_name = Y1_fraction
    functor_names = 'rhoY1 rho'
    expression = 'rhoY1/rho'
  []
  [Y2_fraction]
    type = ADParsedFunctorMaterial
    property_name = Y2_fraction
    functor_names = 'rhoY2 rho'
    expression = 'rhoY2/rho'
  []
  [Y3_fraction]
    type = ADParsedFunctorMaterial
    property_name = Y3_fraction
    functor_names = 'rhoY3 rho'
    expression = 'rhoY3/rho'
  []
  [material_X]
    type = ADParsedFunctorMaterial
    property_name = material_X
    functor_names = 'rho_X rho'
    expression = 'rho_X/rho'
  []
  [material_Y]
    type = ADParsedFunctorMaterial
    property_name = material_Y
    functor_names = 'rho_Y rho'
    expression = 'rho_Y/rho'
  []
  [tracking_fraction]
    type = ADParsedFunctorMaterial
    property_name = tracking_fraction
    functor_names = 'rho_tracking rho'
    expression = 'rho_tracking/rho'
  []
  [inlet_fraction]
    type = ADParsedFunctorMaterial
    property_name = inlet_fraction
    functor_names = 'rho_inlet rho'
    expression = 'rho_inlet/rho'
  []
  [active_fraction]
    type = ADParsedFunctorMaterial
    property_name = active_fraction
    functor_names = 'rho_active rho'
    expression = 'max(0,min(1,rho_active/rho))'
  []
  [active_mass_safe]
    type = ADParsedFunctorMaterial
    property_name = active_mass_safe
    functor_names = 'rho_active rho'
    expression = 'max(rho_active,1e-20*rho)'
  []
  [target_shock]
    type = ADParsedFunctorMaterial
    property_name = target_shock
    functor_names = 'rho_Tshock active_mass_safe'
    expression = 'rho_Tshock/active_mass_safe'
  []
  [target_react]
    type = ADParsedFunctorMaterial
    property_name = target_react
    functor_names = 'rho_Treact active_mass_safe'
    expression = 'rho_Treact/active_mass_safe'
  []
  [time_react]
    type = ADParsedFunctorMaterial
    property_name = time_react
    functor_names = 'rho_tau active_mass_safe'
    expression = 'rho_tau/active_mass_safe'
  []
  [called_up]
    type = ADParsedFunctorMaterial
    property_name = called_up
    functor_names = 'rho_up active_mass_safe'
    expression = 'rho_up/active_mass_safe'
  []
  [shock_clock]
    type = ADParsedFunctorMaterial
    property_name = shock_clock
    functor_names = 'rho_shock_clock active_mass_safe'
    expression = 'rho_shock_clock/active_mass_safe'
  []
  [react_clock]
    type = ADParsedFunctorMaterial
    property_name = react_clock
    functor_names = 'rho_react_clock active_mass_safe'
    expression = 'rho_react_clock/active_mass_safe'
  []
  [reference_density]
    type = ADParsedFunctorMaterial
    property_name = reference_density
    functor_names = 'rho rho_inv_rho0'
    expression = 'rho/rho_inv_rho0'
  []
  [spherical_stress]
    type = ADParsedFunctorMaterial
    property_name = spherical_stress
    functor_names = 'pressure artificial_pressure'
    expression = '-pressure-artificial_pressure'
  []
  [species_error]
    type = ADParsedFunctorMaterial
    property_name = species_error
    functor_names = 'rhoY1 rhoY2 rhoY3 rho_species_total rho'
    expression = '(rhoY1+rhoY2+rhoY3-rho_species_total)/rho'
  []
  [mist_us]
    type = ADParsedFunctorMaterial
    property_name = mist_us
    functor_names = 'speed'
    expression = '((-0.286*speed+1.640)*speed+1.249391)*speed+5.575975'
  []
  [time_shock]
    type = ADParsedFunctorMaterial
    property_name = time_shock
    functor_names = 'mist_us'
    expression = '1/max(mist_us,1e-12)'
  []
  [tau_react]
    type = ADParsedFunctorMaterial
    property_name = tau_react
    functor_names = 'time_react dt'
    expression = 'max(max(time_react,dt),1e-12)'
  []
  [shock_window]
    type = ADParsedFunctorMaterial
    property_name = shock_window
    functor_names = 'active_fraction shock_clock time_shock'
    expression = 'if(active_fraction>0,if(shock_clock>0,if(shock_clock<=time_shock,1,0),0),0)'
  []
  [react_window]
    type = ADParsedFunctorMaterial
    property_name = react_window
    functor_names = 'active_fraction react_clock tau_react'
    expression = 'if(active_fraction>0,if(react_clock>0,if(react_clock<=tau_react,1,0),0),0)'
  []
  [shock_heat]
    type = ADParsedFunctorMaterial
    property_name = shock_heat
    functor_names = 'shock_window rho_Tshock rho_active time_shock'
    expression = 'shock_window*0.002355592*(rho_Tshock-300*rho_active)/time_shock'
  []
  [reaction_heat]
    type = ADParsedFunctorMaterial
    property_name = reaction_heat
    functor_names = 'react_window rho_Treact rho_Tshock tau_react'
    expression = 'react_window*0.002355592*(rho_Treact-rho_Tshock)/tau_react'
  []
  [tracking_source]
    type = ADParsedFunctorMaterial
    property_name = tracking_source
    functor_names = 'rho speed mist_us'
    expression = 'if(speed>0.5,rho*mist_us/3,0)'
  []
  [shock_clock_source]
    type = ADParsedFunctorMaterial
    property_name = shock_clock_source
    functor_names = 'rho_active'
    expression = 'max(rho_active,0)'
  []
  [react_clock_source]
    type = ADParsedFunctorMaterial
    property_name = react_clock_source
    functor_names = 'rho_active shock_clock time_shock'
    expression = 'if(shock_clock>=time_shock,max(rho_active,0),0)'
  []
  [surrogate_product_source]
    type = ADParsedFunctorMaterial
    property_name = surrogate_product_source
    functor_names = 'react_window target_react rho_active_phi tau_react'
    expression = 'if(target_react>1600,react_window*rho_active_phi/tau_react,0)'
  []
  [r1]
    type = ADParsedFunctorMaterial
    property_name = r1
    functor_names = 'temperature active_fraction react_clock time_react'
    expression = 'if(react_clock>time_react,active_fraction*1e-9*exp(31.1)*exp(-24400/(1.987*temperature)),0)'
  []
  [r2]
    type = ADParsedFunctorMaterial
    property_name = r2
    functor_names = 'temperature active_fraction react_clock time_react'
    expression = 'if(react_clock>time_react,active_fraction*1e-9*exp(30.1)*exp(-23500/(1.987*temperature)),0)'
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
  [chemical_heat]
    type = ADParsedFunctorMaterial
    property_name = chemical_heat
    functor_names = 'Q1 Q2 consume1 consume2'
    expression = 'Q1*consume1+Q2*consume2'
  []
  [gated_compression]
    type = ADParsedFunctorMaterial
    property_name = gated_compression
    functor_names = 'compression_heat react_clock time_react'
    expression = 'if(react_clock>time_react,compression_heat,0)'
  []
  [F_source_00]
    type = ADParsedFunctorMaterial
    property_name = F_source_00
    functor_names = 'L00 L01 rhoF00 rhoF10'
    expression = 'L00*rhoF00+L01*rhoF10'
  []
  [F_source_01]
    type = ADParsedFunctorMaterial
    property_name = F_source_01
    functor_names = 'L00 L01 rhoF01 rhoF11'
    expression = 'L00*rhoF01+L01*rhoF11'
  []
  [F_source_10]
    type = ADParsedFunctorMaterial
    property_name = F_source_10
    functor_names = 'L10 L11 rhoF00 rhoF10'
    expression = 'L10*rhoF00+L11*rhoF10'
  []
  [F_source_11]
    type = ADParsedFunctorMaterial
    property_name = F_source_11
    functor_names = 'L10 L11 rhoF01 rhoF11'
    expression = 'L10*rhoF01+L11*rhoF11'
  []
[]
[FVKernels]
  [rho_time]
    type = FVTimeKernel
    variable = rho
  []
  [rho_flux]
    type = FVEulerianHydroFlux
    variable = rho
    equation = mass
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
  []
  [mx_time]
    type = FVTimeKernel
    variable = mx
  []
  [mx_flux]
    type = FVEulerianHydroFlux
    variable = mx
    equation = momentum
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    component = 0
  []
  [my_time]
    type = FVTimeKernel
    variable = my
  []
  [my_flux]
    type = FVEulerianHydroFlux
    variable = my
    equation = momentum
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    component = 1
  []
  [thermal_energy_time]
    type = FVTimeKernel
    variable = thermal_energy
  []
  [thermal_energy_flux]
    type = FVEulerianHydroFlux
    variable = thermal_energy
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = .7066776
  []
  [rhoF00_time]
    type = FVTimeKernel
    variable = rhoF00
  []
  [rhoF00_flux]
    type = FVEulerianHydroFlux
    variable = rhoF00
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 1
  []
  [rhoF01_time]
    type = FVTimeKernel
    variable = rhoF01
  []
  [rhoF01_flux]
    type = FVEulerianHydroFlux
    variable = rhoF01
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 0
  []
  [rhoF10_time]
    type = FVTimeKernel
    variable = rhoF10
  []
  [rhoF10_flux]
    type = FVEulerianHydroFlux
    variable = rhoF10
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 0
  []
  [rhoF11_time]
    type = FVTimeKernel
    variable = rhoF11
  []
  [rhoF11_flux]
    type = FVEulerianHydroFlux
    variable = rhoF11
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 1
  []
  [rhoY1_time]
    type = FVTimeKernel
    variable = rhoY1
  []
  [rhoY1_flux]
    type = FVEulerianHydroFlux
    variable = rhoY1
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 1
    species_role = species1
  []
  [rhoY2_time]
    type = FVTimeKernel
    variable = rhoY2
  []
  [rhoY2_flux]
    type = FVEulerianHydroFlux
    variable = rhoY2
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 0
    species_role = species2
  []
  [rhoY3_time]
    type = FVTimeKernel
    variable = rhoY3
  []
  [rhoY3_flux]
    type = FVEulerianHydroFlux
    variable = rhoY3
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 0
    species_role = species3
  []
  [rho_species_total_time]
    type = FVTimeKernel
    variable = rho_species_total
  []
  [rho_species_total_flux]
    type = FVEulerianHydroFlux
    variable = rho_species_total
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 1
  []
  [rho_inv_rho0_time]
    type = FVTimeKernel
    variable = rho_inv_rho0
  []
  [rho_inv_rho0_flux]
    type = FVEulerianHydroFlux
    variable = rho_inv_rho0
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 0.5494505494505495 # 1/rho0 of the bulk inflow
  []
  [rho_phi_time]
    type = FVTimeKernel
    variable = rho_phi
  []
  [rho_phi_flux]
    type = FVEulerianHydroFlux
    variable = rho_phi
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 1
  []
  [rho_X_time]
    type = FVTimeKernel
    variable = rho_X
  []
  [rho_X_flux]
    type = FVEulerianHydroFlux
    variable = rho_X
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = inlet_X
  []
  [rho_Y_time]
    type = FVTimeKernel
    variable = rho_Y
  []
  [rho_Y_flux]
    type = FVEulerianHydroFlux
    variable = rho_Y
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = inlet_Y
  []
  [rho_inlet_time]
    type = FVTimeKernel
    variable = rho_inlet
  []
  [rho_inlet_flux]
    type = FVEulerianHydroFlux
    variable = rho_inlet
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 1
  []
  [rho_active_time]
    type = FVTimeKernel
    variable = rho_active
  []
  [rho_active_flux]
    type = FVEulerianHydroFlux
    variable = rho_active
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 0
  []
  [rho_active_phi_time]
    type = FVTimeKernel
    variable = rho_active_phi
  []
  [rho_active_phi_flux]
    type = FVEulerianHydroFlux
    variable = rho_active_phi
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 0
  []
  [rho_Tshock_time]
    type = FVTimeKernel
    variable = rho_Tshock
  []
  [rho_Tshock_flux]
    type = FVEulerianHydroFlux
    variable = rho_Tshock
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 0
  []
  [rho_Treact_time]
    type = FVTimeKernel
    variable = rho_Treact
  []
  [rho_Treact_flux]
    type = FVEulerianHydroFlux
    variable = rho_Treact
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 0
  []
  [rho_tau_time]
    type = FVTimeKernel
    variable = rho_tau
  []
  [rho_tau_flux]
    type = FVEulerianHydroFlux
    variable = rho_tau
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 0
  []
  [rho_up_time]
    type = FVTimeKernel
    variable = rho_up
  []
  [rho_up_flux]
    type = FVEulerianHydroFlux
    variable = rho_up
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 0
  []
  [rho_tracking_time]
    type = FVTimeKernel
    variable = rho_tracking
  []
  [rho_tracking_flux]
    type = FVEulerianHydroFlux
    variable = rho_tracking
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 0
  []
  [rho_shock_clock_time]
    type = FVTimeKernel
    variable = rho_shock_clock
  []
  [rho_shock_clock_flux]
    type = FVEulerianHydroFlux
    variable = rho_shock_clock
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 0
  []
  [rho_react_clock_time]
    type = FVTimeKernel
    variable = rho_react_clock
  []
  [rho_react_clock_flux]
    type = FVEulerianHydroFlux
    variable = rho_react_clock
    equation = passive
    rho = rho
    mx = mx
    my = my
    inlet_density = 1.82
    inlet_velocity = 1.2
    inlet_specific = 0
  []
  [conduction]
    type = FVEulerianHeatConduction
    variable = thermal_energy
    conductivity = 0.361e-6
  []
  [thermal_energy_shock_heat]
    type = FVCoupledForce
    variable = thermal_energy
    v = shock_heat
    coef = 1
  []
  [thermal_energy_reaction_heat]
    type = FVCoupledForce
    variable = thermal_energy
    v = reaction_heat
    coef = 1
  []
  [thermal_energy_chemical_heat]
    type = FVCoupledForce
    variable = thermal_energy
    v = chemical_heat
    coef = 1
  []
  [thermal_energy_gated_compression]
    type = FVCoupledForce
    variable = thermal_energy
    v = gated_compression
    coef = 1
  []
  [rho_tracking_tracking_source]
    type = FVCoupledForce
    variable = rho_tracking
    v = tracking_source
    coef = 1
  []
  [rho_shock_clock_shock_clock_source]
    type = FVCoupledForce
    variable = rho_shock_clock
    v = shock_clock_source
    coef = 1
  []
  [rho_react_clock_react_clock_source]
    type = FVCoupledForce
    variable = rho_react_clock
    v = react_clock_source
    coef = 1
  []
  [rhoY1_consume1]
    type = FVCoupledForce
    variable = rhoY1
    v = consume1
    coef = -1
  []
  [rhoY1_surrogate_product_source]
    type = FVCoupledForce
    variable = rhoY1
    v = surrogate_product_source
    coef = -1
  []
  [rhoY2_consume1]
    type = FVCoupledForce
    variable = rhoY2
    v = consume1
    coef = 1
  []
  [rhoY2_consume2]
    type = FVCoupledForce
    variable = rhoY2
    v = consume2
    coef = -1
  []
  [rhoY3_consume2]
    type = FVCoupledForce
    variable = rhoY3
    v = consume2
    coef = 1
  []
  [rhoY3_surrogate_product_source]
    type = FVCoupledForce
    variable = rhoY3
    v = surrogate_product_source
    coef = 1
  []
  [rhoF00_F_source_00]
    type = FVCoupledForce
    variable = rhoF00
    v = F_source_00
    coef = 1
  []
  [rhoF01_F_source_01]
    type = FVCoupledForce
    variable = rhoF01
    v = F_source_01
    coef = 1
  []
  [rhoF10_F_source_10]
    type = FVCoupledForce
    variable = rhoF10
    v = F_source_10
    coef = 1
  []
  [rhoF11_F_source_11]
    type = FVCoupledForce
    variable = rhoF11
    v = F_source_11
    coef = 1
  []
[]
[FVBCs]
  [mx_left_right]
    type = FVDirichletBC
    variable = mx
    boundary = 'left right'
    value = 0
  []
  [my_top]
    type = FVDirichletBC
    variable = my
    boundary = 'top'
    value = 0
  []
  [mx_bottom]
    type = FVDirichletBC
    variable = mx
    boundary = 'bottom'
    value = 0
  []
  [my_bottom]
    type = FVDirichletBC
    variable = my
    boundary = 'bottom'
    value = 2.184
  []
  [rho_bottom]
    type = FVDirichletBC
    variable = rho
    boundary = 'bottom'
    value = 1.82
  []
  [thermal_energy_bottom]
    type = FVDirichletBC
    variable = thermal_energy
    boundary = 'bottom'
    value = 1.286153232
  []
[]
[Adaptivity]
  marker = bulk_marker
  max_h_level = 3
  cycles_per_step = 1
  interval = 1
  [Markers]
    [bulk_marker]
      type = ValueThresholdMarker
      variable = Y2_flag
      refine = 0.9
      coarsen = 0.5
      third_state = DO_NOTHING
    []
  []
[]
[Postprocessors]
  [dt]
    type = TimestepSize
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [total_mass]
    type = ElementIntegralVariablePostprocessor
    variable = rho
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [temperature_max]
    type = ElementExtremeValue
    variable = temperature_out
    value_type = max
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [J_min]
    type = ElementExtremeValue
    variable = J_out
    value_type = min
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[Functions]
  [loaded_microstructure]
    type = ParsedFunction
    expression = '1'
  []
  [inlet_X]
    type = ParsedFunction
    expression = 'x'
  []
  [inlet_Y]
    type = ParsedFunction
    expression = '-1.2*t'
  []
  [timestep]
    type = ParsedFunction
    expression = '5e-3'
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
  end_time = 40
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-8
  automatic_scaling = true
  line_search = none
  petsc_options_iname = '-ksp_gmres_restart -pc_type -pc_hypre_type -pc_hypre_boomeramg_max_iter -snes_type'
  petsc_options_value = '401 hypre boomeramg 60 vinewtonrsls'
[]
[Outputs]
  exodus = true
  csv = true
  time_step_interval = 10
  [mycheckpoints]
    type = Checkpoint
    wall_time_interval = 2000
  []
[]
