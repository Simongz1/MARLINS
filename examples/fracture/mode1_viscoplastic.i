[Mesh]
    [read_mesh]
        type = FileMeshGenerator
        file = mode1_150.msh
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
        initial_condition = 350.0
    []
[]

#materials
#we set materials for fracture first

[Materials]
    
    [constants_matrix]
        type = ADGenericConstantMaterial
        prop_names = 'density specific_heat thermal_conductivity thermal_expansion bulk poisson gc k_r sigma_r eta l'
        prop_values = '1.02e-3 1200 1.2e-4 5e-5 0.85e3 0.35 0.100 1e-5 0.8 0.5 0.1'
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
      xi_name = xi
      flow_stress_material = 'flow_stress'
      bulk_modulus_name = 'bulk'
      poisson_ratio_name = 'poisson'
      elastic_degradation_name = 'De'
      plastic_degradation_name = 'Dp'

      #flow hardening function
      flow_hardening_material = 'strain_hardening'
      viscoplastic_yield_function_name = vp_f

      temperature = temperature
      outputs = exodus

      #properties for thermal expansion
      thermal_expansion = true
      thermal_expansion_coefficient_name = 'thermal_expansion'
  []

    [viscoplastic_properties]
        type = ADGenericConstantMaterial
        prop_names = 'vp_reference_rate vp_rate_exponent xi'
        prop_values = '0.0015 3 0.19'
    []

    [strain_hardening]
      type = ADParsedMaterial
      material_property_names = 'ep'
      expression = '0.9 + 0.1 * exp( - ep / 0.03)'
      property_name = 'vp_f'
      compute = false
      outputs = exodus
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
    
    [total_energy]
        type = ADDerivativeParsedMaterial
        coupled_variables = 'c'
        material_property_names = 'De:=De(c) Dp:=Dp(c) Hist gc l'
        expression = 'De * Hist + (gc * c * c) / (2 * l)'
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
    #viscoplastic heating
    [viscoplastic_heating_calculation]
        type = ADViscoplasticHeating
        beta_vp = 1
    []
    #compression heating
    [compute_compressive_heating]
        type = ADCompressionHeating
        temperature = temperature
        thermal_expansion_name = thermal_expansion
        bulk_modulus_name = bulk
        outputs = exodus
    []
[]

[Kernels]
    #temperature
    [T_dot]
        type = ADHeatConductionTimeDerivative
        variable = temperature
        density_name = density
        specific_heat = specific_heat
        displacements = 'disp_x disp_y'
    []
    [nabla2T]
        type = ADHeatConduction
        thermal_conductivity = thermal_conductivity
        variable = temperature
        displacements = 'disp_x disp_y'
    []
    [viscoplastic_heating_source]
        type = ADMatHeatSource
        variable = temperature
        material_property = vp_heating
        displacements = 'disp_x disp_y'
    []
    [compression_heating_source]
        type = ADMatHeatSource
        variable = temperature
        material_property = q_elastic
        displacements = 'disp_x disp_y'
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
        type = ParsedFunction
        expression = '5e-2*t'
    []
    [opening_left]
        type = ParsedFunction
        expression = '-5e-2*t'
    []
[]

[BCs]
  [right_opening]
    type = FunctionDirichletBC
    variable = disp_x
    boundary = right
    function = opening_right
  []

  [left_opening]
    type = FunctionDirichletBC
    variable = disp_x
    boundary = left
    function = opening_left
  []

  #keep shear displacement zero
  [right_vert_fix]
    type = DirichletBC
    variable = disp_y
    boundary = 'left right'
    value = 0.0
  []
[]

#solver
[Executioner]
    end_time = 200000
    type = Transient
    [./TimeStepper]
        type = FunctionDT
        function = timestep
        min_dt = 1e-7
        growth_factor = 1.25
        cutback_factor_at_failure = 0.25
    [../]
    nl_rel_tol = 1e-8
    nl_abs_tol = 1e-8
    l_tol = 1e-6
    l_max_its = 200
    solve_type = Newton
    petsc_options_iname = '-ksp_type -pc_type -pc_factor_mat_solver_type'
    petsc_options_value = 'preonly   lu       mumps'
    petsc_options = '-snes_converged_reason -ksp_converged_reason -snes_linesearch_monitor'
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
        expression = '0.1'
    [../]
[]

[Outputs]
    exodus = true
    csv = true
    execute_on = TIMESTEP_END
    time_step_interval = 1
[]

[Postprocessors]
#reaction in the right boundary
  [right_reaction]
    type = ADSidesetReaction
    direction = '1 0 0'
    boundary = right
    execute_on = TIMESTEP_END
    stress_tensor = 'stress'
  []

#reaction in left boundary
  [left_reaction]
    type = ADSidesetReaction
    direction = '-1 0 0'
    boundary = left
    execute_on = TIMESTEP_END
    stress_tensor = 'stress'
  []
[]