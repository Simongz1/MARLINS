# Installation smoke test derived from vp_T300.i: one QUAD4, ramp then hold.
# Retains illustrative reference properties; not a material validation benchmark.
[Mesh]
  [read_mesh]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 1
    ny = 1
    xmin = 0
    xmax = 1
    ymin = 0
    ymax = 1
    elem_type = QUAD4
  []
[]

[GlobalParams]
    displacements = 'disp_x disp_y'
    use_displaced_mesh = true
    exponential_stretch_approximation = true
    use_artificial_viscosity = false
[]

[AuxVariables]
  [h_min]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[AuxKernels]
  [compute_h_min]
    type = ElementLengthAux
    variable = h_min
    method = min
    execute_on = INITIAL
  []
[]

[Postprocessors]
  [global_hmin]
    type = ElementExtremeValue
    variable = h_min
    value_type = min
    execute_on = INITIAL
  []
[]

[Materials]
  [minimum_mesh_size]
    type = ParsedMaterial
    property_name = h_min
    postprocessor_names = 'global_hmin'
    expression = 'global_hmin'
  []
[]

[Variables]
    [disp_x]
    []

    [disp_y]
    []

    [c]
        initial_condition = 0.0
    []

    [temperature]
        initial_condition = 300.0
    []
[]

#materials
#we set materials for fracture first

[Materials]
    
    [constants_matrix]
        type = ADGenericConstantMaterial
        prop_names = 'density bulk poisson gc k_r sigma_r eta l'
        prop_values = '1.02e-3 3e3 0.45 400 1e-5 0.8 500 1.25'
    []

    #define degradation properties
    [De]
        type = ADDerivativeParsedMaterial
        material_property_names = 'k_r'
        coupled_variables = 'c'
        expression = '(1 - k_r) * (1 - c)^2 + k_r'
        derivative_order = 2
        outputs = exodus
        property_name = 'De'
    []
    [Dp]
        type = ADDerivativeParsedMaterial
        material_property_names = 'sigma_r'
        coupled_variables = 'c'
        expression = '(1 - sigma_r) * (1 - c)^2 + sigma_r'
        derivative_order = 2
        outputs = exodus
        property_name = 'Dp'
    []

    #compute incremental deformation gradient
    [incremental]
        type = ADComputeFiniteStrain
        displacements = 'disp_x disp_y'
        decomposition_method = EigenSolution
    []

    #stress calculation
    [elasto_plastic_update]
        type = ADElastoPlastic
        constitutive_model = NH
        viscoplastic_flow = true
        viscoplastic_flow_resistance_name = vp_flow_resistance
        viscoplastic_reference_rate_name = vp_reference_rate
        viscoplastic_rate_exponent_name = vp_rate_exponent
        viscoplastic_yield_function_name = vp_f
        xi_name = xi
        flow_stress_material = 'flow_stress'
        bulk_modulus_name = 'bulk'
        poisson_ratio_name = 'poisson'
        elastic_degradation_name = 'De'
        plastic_degradation_name = 'Dp'
        temperature = temperature
        outputs = exodus
    []

    # New VP properties: constant vp_f avoids a dependency on current ep.
    # Illustrative values only, assuming MPa and seconds; calibrate for your material.
    # Applied on both blocks because elasto_plastic_update is unrestricted.
    [viscoplastic_properties]
        type = ADGenericConstantMaterial
        prop_names = 'vp_reference_rate vp_rate_exponent vp_f xi'
        prop_values = '0.0015 3 1 0.19'
    []

    [temperature_dependent_flow_resistance]
        type = ADParsedMaterial
        coupled_variables = 'temperature'
        expression = '15 - 0.22 * (temperature - 300)'
        property_name = 'vp_flow_resistance'
    []


    #yield stress material
    [yield_properties]
        type = ADGenericConstantMaterial
        prop_names = 'A B n'
        prop_values = '80 30 3'
    []

    [flow_stress]
        type = ADDerivativeParsedMaterial
        material_property_names = 'ep A B n'
        expression = 'A + B * ep ^ n'
        additional_derivative_symbols = 'ep'
        derivative_order = 2
        property_name = 'flow_stress'
        compute = false
    []

    #materials for phase field: 
    #we need to define the total energy
    [plastic_energy]
        type = ADDerivativeParsedMaterial
        material_property_names = 'flow_stress ep A B n'
        expression = 'A*ep + B/(n+1)*ep^(n+1)'
        property_name = 'Wp'
    []
    
    [total_energy]
        type = ADDerivativeParsedMaterial
        coupled_variables = 'c'
        material_property_names = 'De:=De(c) Dp:=Dp(c) Hist Wp gc l'
        expression = 'De * Hist + Dp * Wp + (gc * c * c) / (2 * l)'
        property_name = 'bulk_energy'
        outputs = exodus
    []

    #mobility and kappa
    [L]
        type = ADParsedMaterial
        material_property_names = 'gc eta'
        expression = '1 / (gc * eta)'
        property_name = 'L'
    []
    [kappa]
        type = ADParsedMaterial
        material_property_names = 'gc l'
        expression = 'gc * l'
        property_name = 'kappa'
    []
[]

[Kernels]
    # Preserve c=0 using c_dot, isolate constitutive relaxation.
    inactive = 'bulk_variation interface_variation'
    #temperature
    [T_dot]
        type = ADTimeDerivative
        variable = temperature
    []

    #stress divergence: quasistatic case
    [div_x]
        type = ADDynamicStressDivergenceTensors
        component = 0
        displacements = 'disp_x disp_y'
        variable = 'disp_x'
    []
    [div_y]
        type = ADDynamicStressDivergenceTensors
        component = 1
        displacements = 'disp_x disp_y'
        variable = 'disp_y'
    []

    #fracture stuff
    [c_dot]
        type = ADTimeDerivative
        variable = c
    []
    #allen cahn bulk
    [bulk_variation]
        type = ADAllenCahn
        f_name = 'bulk_energy'
        variable = c
        mob_name = 'L'
    []
    [interface_variation]
        type = ADACInterface
        variable = c
        kappa_name = 'kappa'
        mob_name = 'L'
        variable_L = False
    []
[]

[Functions]
  [opening_right]
    type = PiecewiseLinear
    x = '0 20 200'
    y = '0 0.01 0.01'
  []
[]

[BCs]
    [left_x_fix]
        type = DirichletBC
        variable = disp_x
        boundary = left
        value = 0.0
    []

    [left_y_fix]
        type = DirichletBC
        variable = disp_y
        boundary = left
        value = 0.0
    []

    [right_opening]
        type = FunctionDirichletBC
        variable = disp_x
        boundary = right
        function = opening_right
    []
[]

#solver
[Executioner]
    end_time = 200
    type = Transient
    [./TimeStepper]
        type = FunctionDT
        function = timestep
        min_dt = 1e-7
        growth_factor = 1.25
        cutback_factor_at_failure = 0.25
    [../]
    nl_rel_tol = 1e-7
    nl_abs_tol = 1e-7
    l_tol = 1e-6
    l_max_its = 200
    solve_type = Newton
    petsc_options_iname = '-ksp_type -pc_type'
    petsc_options_value = 'preonly lu'
    automatic_scaling = true
    line_search = 'bt'
[]

[Preconditioning]
    [coup]
        type = SMP
        full = true
    []
[]

[Functions]
    [./timestep]
        type = ParsedFunction
        expression = '1'
    [../]
[]

[Outputs]
    exodus = true
    csv = true
    execute_on = TIMESTEP_END
    time_step_interval = 1
[]

# Diagnostics; sample only at accepted step ends.
[AuxVariables]
  [vp_ep]
    family = MONOMIAL
    order = CONSTANT
  []
  [vp_ep_dot]
    family = MONOMIAL
    order = CONSTANT
  []
  [vp_sigma_xx]
    family = MONOMIAL
    order = CONSTANT
  []
  [vp_fp_xx]
    family = MONOMIAL
    order = CONSTANT
  []
  [vp_fe_xx]
    family = MONOMIAL
    order = CONSTANT
  []
  [vp_q]
    family = MONOMIAL
    order = CONSTANT
  []
  [vp_Jp]
    family = MONOMIAL
    order = CONSTANT
  []
  [vp_Je]
    family = MONOMIAL
    order = CONSTANT
  []
[]
[AuxKernels]
  [copy_vp_ep]
    type = ADMaterialRealAux
    variable = vp_ep
    property = ep
    execute_on = TIMESTEP_END
  []
  [copy_vp_ep_dot]
    type = ADMaterialRealAux
    variable = vp_ep_dot
    property = ep_dot
    execute_on = TIMESTEP_END
  []
  [copy_vp_sigma_xx]
    type = ADRankTwoAux
    variable = vp_sigma_xx
    rank_two_tensor = cauchy
    index_i = 0
    index_j = 0
    execute_on = TIMESTEP_END
  []
  [copy_vp_fp_xx]
    type = ADRankTwoAux
    variable = vp_fp_xx
    rank_two_tensor = Fp
    index_i = 0
    index_j = 0
    execute_on = TIMESTEP_END
  []
  [copy_vp_fe_xx]
    type = ADRankTwoAux
    variable = vp_fe_xx
    rank_two_tensor = Fe
    index_i = 0
    index_j = 0
    execute_on = TIMESTEP_END
  []
  [copy_vp_q]
    type = ADRankTwoScalarAux
    variable = vp_q
    rank_two_tensor = cauchy
    scalar_type = VonMisesStress
    execute_on = TIMESTEP_END
  []
  [copy_vp_Jp]
    type = ADRankTwoScalarAux
    variable = vp_Jp
    rank_two_tensor = Fp
    scalar_type = ThirdInvariant
    execute_on = TIMESTEP_END
  []
  [copy_vp_Je]
    type = ADRankTwoScalarAux
    variable = vp_Je
    rank_two_tensor = Fe
    scalar_type = ThirdInvariant
    execute_on = TIMESTEP_END
  []
[]
[Postprocessors]
  [mean_vp_ep]
    type = ElementAverageValue
    variable = vp_ep
    execute_on = TIMESTEP_END
  []
  [mean_vp_ep_dot]
    type = ElementAverageValue
    variable = vp_ep_dot
    execute_on = TIMESTEP_END
  []
  [mean_vp_sigma_xx]
    type = ElementAverageValue
    variable = vp_sigma_xx
    execute_on = TIMESTEP_END
  []
  [mean_vp_fp_xx]
    type = ElementAverageValue
    variable = vp_fp_xx
    execute_on = TIMESTEP_END
  []
  [mean_vp_fe_xx]
    type = ElementAverageValue
    variable = vp_fe_xx
    execute_on = TIMESTEP_END
  []
  [mean_vp_q]
    type = ElementAverageValue
    variable = vp_q
    execute_on = TIMESTEP_END
  []
  [mean_vp_Jp]
    type = ElementAverageValue
    variable = vp_Jp
    execute_on = TIMESTEP_END
  []
  [mean_vp_Je]
    type = ElementAverageValue
    variable = vp_Je
    execute_on = TIMESTEP_END
  []
  [mean_c]
    type = ElementAverageValue
    variable = c
    execute_on = TIMESTEP_END
  []
  [mean_temperature]
    type = ElementAverageValue
    variable = temperature
    execute_on = TIMESTEP_END
  []
  [min_element_mean_vp_Jp]
    type = ElementExtremeValue
    variable = vp_Jp
    value_type = min
    execute_on = TIMESTEP_END
  []
  [min_element_mean_vp_Je]
    type = ElementExtremeValue
    variable = vp_Je
    value_type = min
    execute_on = TIMESTEP_END
  []
  [right_displacement]
    type = SideAverageValue
    variable = disp_x
    boundary = right
    execute_on = TIMESTEP_END
  []
[]
