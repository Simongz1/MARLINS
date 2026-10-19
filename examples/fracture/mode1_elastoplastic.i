[Mesh]
    [read_mesh]
        type = FileMeshGenerator
        file = mode1.msh
    []
[]

[GlobalParams]
        displacements = 'disp_x disp_y'
        use_displaced_mesh = true
        exponential_stretch_approximation = true
[]

[Variables]
    [disp_x]
    []
    [disp_y]
    []

    #damage
    [c]
        initial_condition = 0.0
    []

    #temperature
    [temperature]
        initial_condition = 300.0
    []
[]

#materials
#we set materials for fracture first

[Materials]
    [constants]
        type = ADGenericConstantMaterial
        prop_names = 'bulk poisson gc k_r sigma_r eta l'
        prop_values = '36.67e3 0.25 0.5 1e-4 0.8 500 1.25'
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
    [yield_properties]
        type = ADGenericConstantMaterial
        prop_names = 'A B n'
        prop_values = '50 50 2'
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
        type = ParsedFunction
        expression = '5e-6*t'
    []
    [opening_left]
        type = ParsedFunction
        expression = '-5e-6*t'
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
    type = Transient
    [./TimeStepper]
        type = FunctionDT
        function = timestep
        min_dt = 1e-7
        growth_factor = 1.25
        cutback_factor_at_failure = 0.25
    [../]
    nl_rel_tol = 1e-6
    nl_abs_tol = 1e-6
    l_tol = 1e-4
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
        expression = '50'
    [../]
[]

[Outputs]
    exodus = true
    time_step_interval = 1
[]
