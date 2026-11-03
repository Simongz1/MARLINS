# Reference-coordinate FV counterpart of testing_slowAMR.i.
# Units: um, ns, GPa, K. All nonlinear fields are cell-centered FV.
# Spherical RDX/JWL + binder stress; no deviatoric stress or plastic heating.
# Material mesh: microstructure IDs and event histories follow material cells;
# there is no Eulerian advection on this fixed REFERENCE-coordinate mesh.
# See doc/testing_slowAMR_fv.md for equations, differences, and checks.
[GlobalParams]
  ghost_layers = 2
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
    xmin = 0
    ymin = 0
    xmax = 80
    ymax = 300
  []
[]
[Variables]
  [vx]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [vy]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [F00]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1
  []
  [F01]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [F10]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [F11]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1
  []
  [temperature]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 300
  []
  [tracking]
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
  [Y1]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    # Initialized by PolycrystalDensityIntegerLegacyUO, exactly as in FE.
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
  [disp_x]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [disp_y]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
[]
[AuxVariables]
  [density_i]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [density_csv]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1.82
  []
  [fraction_csv]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1
  []
  [grainID]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [Y2_flag]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [mist_flag_state]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [mist_shock_T_state]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 300
  []
  [mist_react_T_state]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 300
  []
  [mist_tau_state]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [mist_up_state]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [pressure_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [s_pressure]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
  []
  [von_mises]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [artificial_pressure_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [J_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1
  []
  [current_density_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 1.82
  []
  [dilatation_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [time_shock_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [time_react_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [heatrate_shock_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [heatrate_react_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [HS_elastic_out]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
[]
[UserObjects]
  [voronoi_density]
    type = PolycrystalDensityIntegerLegacyUO
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
[]
[AuxKernels]
  [display_id]
    type = MicrostructureIDAux
    variable = density_i
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_density]
    type = PolycrystalIntegerDensityAux
    variable = density_csv
    execute_on = INITIAL
    csv_density = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/densities_new.csv'
    csv_density_pore = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/density_pore.csv'
    microstructure_id_name = microstructure_id
    density_scaling = 1e-3
    bulk_MicroID = 99
    bulk_RDX_density = 1820
    range_pore = '101 103'
  []
  [reference_fraction]
    type = PolycrystalIntegerFractionAux
    variable = fraction_csv
    execute_on = 'INITIAL TIMESTEP_END'
    csv_fraction = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/fractions_new.csv'
    csv_fraction_pore = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/fraction_pore.csv'
    microstructure_id_name = microstructure_id
    bulk_MicroID = 99
    bulk_RDX_fraction = 1
    range_pore = '101 103'
  []
  [commit_flag]
    type = FunctorAux
    variable = mist_flag_state
    functor = mist_v_flag
    execute_on = TIMESTEP_END
  []
  [commit_shock_T]
    type = FunctorAux
    variable = mist_shock_T_state
    functor = mist_temperature_mister_shock
    execute_on = TIMESTEP_END
  []
  [commit_react_T]
    type = FunctorAux
    variable = mist_react_T_state
    functor = mist_temperature_mister_react
    execute_on = TIMESTEP_END
  []
  [commit_tau]
    type = FunctorAux
    variable = mist_tau_state
    functor = mist_time_react
    execute_on = TIMESTEP_END
  []
  [commit_up]
    type = FunctorAux
    variable = mist_up_state
    functor = mist_called_up
    execute_on = TIMESTEP_END
  []
  [output_Y2_flag]
    type = FunctorAux
    variable = Y2_flag
    functor = Y2_flag_value
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [output_pressure_out]
    type = FunctorAux
    variable = pressure_out
    functor = pressure
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [output_s_pressure]
    type = FunctorAux
    variable = s_pressure
    functor = hydrostatic_stress
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [output_artificial_pressure_out]
    type = FunctorAux
    variable = artificial_pressure_out
    functor = artificial_pressure
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [output_J_out]
    type = FunctorAux
    variable = J_out
    functor = J
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [output_current_density_out]
    type = FunctorAux
    variable = current_density_out
    functor = current_density
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [output_dilatation_out]
    type = FunctorAux
    variable = dilatation_out
    functor = dilatation
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [output_time_shock_out]
    type = FunctorAux
    variable = time_shock_out
    functor = time_shock
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [output_time_react_out]
    type = FunctorAux
    variable = time_react_out
    functor = mist_time_react
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [output_heatrate_shock_out]
    type = FunctorAux
    variable = heatrate_shock_out
    functor = scaled_shock
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [output_heatrate_react_out]
    type = FunctorAux
    variable = heatrate_react_out
    functor = scaled_react
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [output_HS_elastic_out]
    type = FunctorAux
    variable = HS_elastic_out
    functor = HS_elastic
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
[FunctorMaterials]
  [velocity]
    type = ADComputeComponentVector
    x_component = vx
    y_component = vy
    z_component = 0
    vector_name = velocity
  []
  [predictor]
    type = ADFVMISTnetPredictor
    velocity = velocity
    tracking = tracking
    reference_density = density_csv
    flag_state = mist_flag_state
    shock_temperature_state = mist_shock_T_state
    reaction_temperature_state = mist_react_T_state
    reaction_time_state = mist_tau_state
    called_up_state = mist_up_state
    microstructure_id_name = legacy_prediction_id
    bulk_MicroID = 99
    bulk_sensitivity = 20
    range_pore = '101 103'
    thr_v = 0.5
    tracking_threshold = 0.99
    element_size = 1
    velocity_to_table = 1
    time_from_table = 1
    maximum_up = 4.89
    use_tabular_time = false
    tau_react_scaling = 1
    csv_shock = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/shock_new.csv'
    csv_react = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/react_new.csv'
    csv_times = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/time_new.csv'
    csv_shock_pore = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/shock_pore.csv'
    csv_react_pore = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/react_pore.csv'
    csv_times_pore = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/time_pore.csv'
  []
  [spherical_hydro]
    type = ADFVReferenceHydro
    vx = vx
    vy = vy
    temperature = temperature
    Y1 = Y1
    fraction = fraction_csv
    rho0 = density_csv
    F00 = F00
    F01 = F01
    F10 = F10
    F11 = F11
    cv = 2355.592e-6
    RDX_bulk = 20
    RDX_poisson = 0.24
    binder_bulk = 3
    binder_poisson = 0.45
    C0 = 0.1
    C1 = 1
  []
  [current_density]
    type = ADParsedFunctorMaterial
    property_name = current_density
    functor_names = 'density_csv J'
    expression = 'density_csv/J'
  []
  [hydrostatic_stress]
    type = ADParsedFunctorMaterial
    property_name = hydrostatic_stress
    functor_names = 'pressure artificial_pressure'
    expression = '-pressure-artificial_pressure'
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
    functor_names = 'mist_time_react dt'
    # Initialization can evaluate diagnostics before the first nonzero dt.
    expression = 'max(max(mist_time_react,dt),1e-12)'
  []
  [rate_dirac_shock]
    type = ADParsedFunctorMaterial
    property_name = rate_dirac_shock
    functor_names = 'mist_v_flag'
    expression = 'if(mist_v_flag>0,1,0)'
  []
  [rate_dirac_react]
    type = ADParsedFunctorMaterial
    property_name = rate_dirac_react
    functor_names = 'dirac_switch_shock time_shock'
    expression = 'if(dirac_switch_shock>=time_shock,1,0)'
  []
  [shock_window]
    type = ADParsedFunctorMaterial
    property_name = shock_window
    functor_names = 'mist_v_flag dirac_switch_shock time_shock'
    expression = 'if(mist_v_flag=1,if(dirac_switch_shock>0,if(dirac_switch_shock<=time_shock,1,0),0),0)'
  []
  [react_window]
    type = ADParsedFunctorMaterial
    property_name = react_window
    functor_names = 'mist_v_flag dirac_switch_react tau_react'
    expression = 'if(mist_v_flag=1,if(dirac_switch_react>0,if(dirac_switch_react<=tau_react,1,0),0),0)'
  []
  [scaled_shock]
    type = ADParsedFunctorMaterial
    property_name = scaled_shock
    functor_names = 'shock_window mist_temperature_mister_shock time_shock'
    expression = 'shock_window*(mist_temperature_mister_shock-300)/time_shock'
  []
  [scaled_react]
    type = ADParsedFunctorMaterial
    property_name = scaled_react
    functor_names = 'react_window mist_temperature_mister_react mist_temperature_mister_shock tau_react'
    expression = 'react_window*(mist_temperature_mister_react-mist_temperature_mister_shock)/tau_react'
  []
  [Y3_dot_surrogate]
    type = ADParsedFunctorMaterial
    property_name = Y3_dot_surrogate
    functor_names = 'react_window mist_temperature_mister_react fraction_csv tau_react'
    expression = 'if(mist_temperature_mister_react>1600,react_window*fraction_csv/tau_react,0)'
  []
  [Y1_dot_surrogate]
    type = ADParsedFunctorMaterial
    property_name = Y1_dot_surrogate
    functor_names = 'Y3_dot_surrogate'
    expression = '-Y3_dot_surrogate'
  []
  [r1]
    type = ADParsedFunctorMaterial
    property_name = r1
    functor_names = 'temperature dirac_switch_react mist_time_react'
    expression = 'if(dirac_switch_react>mist_time_react,1e-9*exp(31.1)*exp(-24400/(1.987*temperature)),0)'
  []
  [r2]
    type = ADParsedFunctorMaterial
    property_name = r2
    functor_names = 'temperature dirac_switch_react mist_time_react'
    expression = 'if(dirac_switch_react>mist_time_react,1e-9*exp(30.1)*exp(-23500/(1.987*temperature)),0)'
  []
  [r1Y1]
    type = ADParsedFunctorMaterial
    property_name = r1Y1
    functor_names = 'r1 Y1'
    expression = 'r1*Y1'
  []
  [r2Y2]
    type = ADParsedFunctorMaterial
    property_name = r2Y2
    functor_names = 'r2 Y2'
    expression = 'r2*Y2'
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
  [scaled_chem]
    type = ADParsedFunctorMaterial
    property_name = scaled_chem
    functor_names = 'Q1 Q2 r1Y1 r2Y2'
    expression = '(Q1*r1Y1+Q2*r2Y2)/2355.592e-6'
  []
  [scaled_elastic]
    type = ADParsedFunctorMaterial
    property_name = scaled_elastic
    functor_names = 'HS_elastic current_density dirac_switch_react mist_time_react'
    expression = 'if(dirac_switch_react>mist_time_react,HS_elastic/(current_density*2355.592e-6),0)'
  []
  [Y2_flag_value]
    type = ADParsedFunctorMaterial
    property_name = Y2_flag_value
    functor_names = 'Y1 Y2 Y3 dirac_switch_react mist_time_react'
    expression = 'if(Y3>0.95*max(Y1+Y2+Y3,1e-12),0,if(Y3>0.01,1,0)*if(Y2<0.75,1,0)*if(dirac_switch_react>mist_time_react,1,0))'
  []
[]
[FVKernels]
  [vx_time]
    type = FVScalarTimeKernel
    variable = vx
    scalar = density_csv
  []
  [vy_time]
    type = FVScalarTimeKernel
    variable = vy
    scalar = density_csv
  []
  [F00_time]
    type = FVTimeKernel
    variable = F00
  []
  [F01_time]
    type = FVTimeKernel
    variable = F01
  []
  [F10_time]
    type = FVTimeKernel
    variable = F10
  []
  [F11_time]
    type = FVTimeKernel
    variable = F11
  []
  [temperature_time]
    type = FVTimeKernel
    variable = temperature
  []
  [tracking_time]
    type = FVTimeKernel
    variable = tracking
  []
  [dirac_switch_shock_time]
    type = FVTimeKernel
    variable = dirac_switch_shock
  []
  [dirac_switch_react_time]
    type = FVTimeKernel
    variable = dirac_switch_react
  []
  [Y1_time]
    type = FVTimeKernel
    variable = Y1
  []
  [Y2_time]
    type = FVTimeKernel
    variable = Y2
  []
  [Y3_time]
    type = FVTimeKernel
    variable = Y3
  []
  [disp_x_time]
    type = FVTimeKernel
    variable = disp_x
  []
  [disp_y_time]
    type = FVTimeKernel
    variable = disp_y
  []
  [vx_flux]
    type = FVReferenceHydroFlux
    variable = vx
    equation = momentum
    component = 0
    column = 0
    vx = vx
    vy = vy
    rho0 = density_csv
    F00 = F00
    F01 = F01
    F10 = F10
    F11 = F11
    driven_boundary = bottom
    driven_velocity = 1.2
  []
  [vy_flux]
    type = FVReferenceHydroFlux
    variable = vy
    equation = momentum
    component = 1
    column = 0
    vx = vx
    vy = vy
    rho0 = density_csv
    F00 = F00
    F01 = F01
    F10 = F10
    F11 = F11
    driven_boundary = bottom
    driven_velocity = 1.2
  []
  [F00_flux]
    type = FVReferenceHydroFlux
    variable = F00
    equation = deformation
    component = 0
    column = 0
    vx = vx
    vy = vy
    rho0 = density_csv
    F00 = F00
    F01 = F01
    F10 = F10
    F11 = F11
    driven_boundary = bottom
    driven_velocity = 1.2
  []
  [F01_flux]
    type = FVReferenceHydroFlux
    variable = F01
    equation = deformation
    component = 0
    column = 1
    vx = vx
    vy = vy
    rho0 = density_csv
    F00 = F00
    F01 = F01
    F10 = F10
    F11 = F11
    driven_boundary = bottom
    driven_velocity = 1.2
  []
  [F10_flux]
    type = FVReferenceHydroFlux
    variable = F10
    equation = deformation
    component = 1
    column = 0
    vx = vx
    vy = vy
    rho0 = density_csv
    F00 = F00
    F01 = F01
    F10 = F10
    F11 = F11
    driven_boundary = bottom
    driven_velocity = 1.2
  []
  [F11_flux]
    type = FVReferenceHydroFlux
    variable = F11
    equation = deformation
    component = 1
    column = 1
    vx = vx
    vy = vy
    rho0 = density_csv
    F00 = F00
    F01 = F01
    F10 = F10
    F11 = F11
    driven_boundary = bottom
    driven_velocity = 1.2
  []
  [conduction]
    type = FVReferenceHeatConduction
    variable = temperature
    rho0 = density_csv
    F00 = F00
    F01 = F01
    F10 = F10
    F11 = F11
    cv = 2355.592e-6
    conductivity = 0.361e-6
  []
  [tracking_mist_rate_tracking]
    type = FVCoupledForce
    variable = tracking
    v = mist_rate_tracking
    coef = 1
  []
  [dirac_switch_shock_rate_dirac_shock]
    type = FVCoupledForce
    variable = dirac_switch_shock
    v = rate_dirac_shock
    coef = 1
  []
  [dirac_switch_react_rate_dirac_react]
    type = FVCoupledForce
    variable = dirac_switch_react
    v = rate_dirac_react
    coef = 1
  []
  [temperature_scaled_shock]
    type = FVCoupledForce
    variable = temperature
    v = scaled_shock
    coef = 1
  []
  [temperature_scaled_react]
    type = FVCoupledForce
    variable = temperature
    v = scaled_react
    coef = 1
  []
  [temperature_scaled_chem]
    type = FVCoupledForce
    variable = temperature
    v = scaled_chem
    coef = 1
  []
  [temperature_scaled_elastic]
    type = FVCoupledForce
    variable = temperature
    v = scaled_elastic
    coef = 1
  []
  [Y1_r1Y1]
    type = FVCoupledForce
    variable = Y1
    v = r1Y1
    coef = -1
  []
  [Y1_Y1_dot_surrogate]
    type = FVCoupledForce
    variable = Y1
    v = Y1_dot_surrogate
    coef = 1
  []
  [Y2_r1Y1]
    type = FVCoupledForce
    variable = Y2
    v = r1Y1
    coef = 1
  []
  [Y2_r2Y2]
    type = FVCoupledForce
    variable = Y2
    v = r2Y2
    coef = -1
  []
  [Y3_r2Y2]
    type = FVCoupledForce
    variable = Y3
    v = r2Y2
    coef = 1
  []
  [Y3_Y3_dot_surrogate]
    type = FVCoupledForce
    variable = Y3
    v = Y3_dot_surrogate
    coef = 1
  []
  [disp_x_vx]
    type = FVCoupledForce
    variable = disp_x
    v = vx
    coef = 1
  []
  [disp_y_vy]
    type = FVCoupledForce
    variable = disp_y
    v = vy
    coef = 1
  []
[]
[FVBCs]
  [vx_left_right]
    type = FVDirichletBC
    variable = vx
    boundary = 'left right'
    value = 0
  []
  [vy_bottom]
    type = FVDirichletBC
    variable = vy
    boundary = 'bottom'
    value = 1.2
  []
  [vy_top]
    type = FVDirichletBC
    variable = vy
    boundary = 'top'
    value = 0
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
      coarsen = 0.5
      variable = Y2_flag
      refine = 0.9
      third_state = DO_NOTHING
    []
  []
[]
[Postprocessors]
  [dt]
    type = TimestepSize
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [temperature_max]
    type = ElementExtremeValue
    variable = temperature
    value_type = max
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [J_min]
    type = ElementExtremeValue
    variable = J_out
    value_type = min
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [artificial_pressure_max]
    type = ElementExtremeValue
    variable = artificial_pressure_out
    value_type = max
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
  # Explicit comparison horizon; the FE input leaves end_time unspecified.
  end_time = 40
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-8
  automatic_scaling = true
  line_search = none
  petsc_options_iname = '-ksp_gmres_restart -pc_type -pc_hypre_type -pc_hypre_boomeramg_max_iter -snes_type'
  petsc_options_value = '401 hypre boomeramg 60 vinewtonrsls'
[]
[Functions]
  [loaded_microstructure]
    type = ParsedFunction
    expression = '1'
  []
  [timestep]
    type = ParsedFunction
    expression = '5e-3'
  []
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
