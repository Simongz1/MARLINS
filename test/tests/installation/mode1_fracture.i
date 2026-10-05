# Installation smoke test adapted from kuhn.i. Coarse diffuse notch; not a crack-growth benchmark.
[Mesh]
    type = GeneratedMesh
    dim = 2
    nx = 8
    ny = 8
    xmax = 1
    ymax = 1
[]

[GlobalParams]
        displacements = 'disp_x disp_y'
        use_displaced_mesh = true
[]

[Variables]
    [disp_x]
    []
    [disp_y]
    []

    #damage
    [c]
    []

    #temperature
    [temperature]
        initial_condition = 300.0
    []
[]

#materials
#we set materials for fracture first

[Materials]
    [mesh_length]
        type = GenericConstantMaterial
        prop_names = h_min
        prop_values = 0.125
    []
    [constants]
        type = ADGenericConstantMaterial
        prop_names = 'bulk poisson gc k_r sigma_r eta l density'
        prop_values = '36.67 0.25 0.01 1e-3 0.8 2.0 0.1 1'
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
        flow_stress_material = 'flow_stress'
        bulk_modulus_name = 'bulk'
        poisson_ratio_name = 'poisson'
        elastic_degradation_name = 'De'
        plastic_degradation_name = 'Dp'
        temperature = temperature
        outputs = exodus
    []

    #yield stress material
    [flow_stress]
        type = ADDerivativeParsedMaterial
        material_property_names = 'ep'
        constant_names = 'A B n'
        constant_expressions = '1e3 20e-3 2'
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
        material_property_names = 'flow_stress ep'
        expression = 'flow_stress * ep'
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
    [pull]
        type = ParsedFunction
        expression = '0.05*t'
    []
[]

# Opening normal to a horizontal diffuse notch: mode I.
[ICs]
    [notch]
        type = FunctionIC
        variable = c
        function = 'if(x < 0.35, exp(-abs(y-0.5)/0.05), 0)'
    []
[]
[BCs]
    [opening]
        type = FunctionDirichletBC
        variable = disp_y
        boundary = top
        function = pull
    []
    [bottom]
        type = DirichletBC
        variable = disp_y
        boundary = bottom
        value = 0
    []
    [horizontal_constraint]
        type = DirichletBC
        variable = disp_x
        boundary = left
        value = 0
    []
[]
[Postprocessors]
    [mean_damage]
        type = ElementAverageValue
        execute_on = 'INITIAL TIMESTEP_END'
        variable = c
    []
    [opening]
        type = SideAverageValue
        execute_on = 'INITIAL TIMESTEP_END'
        variable = disp_y
        boundary = top
    []
[]

#solver
[Executioner]
    type = Transient
    num_steps = 5
    end_time = 0.1
    [./TimeStepper]
        type = FunctionDT
        function = timestep
        min_dt = 1e-7
    [../]
    nl_rel_tol = 1e-6
    nl_abs_tol = 1e-6
    solve_type = Newton
    petsc_options_iname = '-pc_type -snes_type'
    petsc_options_value = 'lu vinewtonrsls' 
    automatic_scaling = true
    line_search = 'bt'
[]

[Functions]
    [./timestep]
        type = ParsedFunction
        expression = '0.02'
    [../]
[]

[Outputs]
    exodus = true
    csv = true
    execute_on = 'INITIAL TIMESTEP_END'
[]

# Prevent the seeded crack from healing during this short opening test.
[AuxVariables]
    [bounds_dummy]
    []
[]
[Bounds]
    [damage_upper]
        type = ConstantBounds
        variable = bounds_dummy
        bounded_variable = c
        bound_type = upper
        bound_value = 1
    []
    [damage_lower]
        type = VariableOldValueBounds
        variable = bounds_dummy
        bounded_variable = c
        bound_type = lower
    []
[]
