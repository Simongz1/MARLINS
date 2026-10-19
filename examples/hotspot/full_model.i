#parameter definition
# UNITS:
# length -> 10^9
# time -> 10^9
# pressure -> 10^18

# setup:
# updated lagrangian - current configuration

# CONSTANTS
# k = 0.361 # W / m - K thermal conductivity
# cv = 0.563 # cal / g - K heat capacity
# rho0 = 1820 # kg / m3 reference density
# Q1 = -1.7 # kcal / mol heat of reaction 1
# Q2 = 416 # kcal / mol heat of reaction 2
# E1 = 24.4 # kcal / mol activation energy 1
# E2 = 23.5 # kcal / mol activation energy 2
# logZ1 = 31.1 # log(1/s) log of rate factor 1
# logZ2 = 30.1 # log(1/s) log of rate factor 2
# R = 1.987 # cal / mol - K


[Mesh]
        type = GeneratedMesh
        dim = 2
        xmin = 0
        xmax = 100
        ymin = 0
        ymax = 100
        nx = 250
        ny = 250
[]

[Variables]
        [T]
        []
        
        #reaction
        [Y1]
                initial_condition = 1
        []

        [Y2]
                initial_condition = 0
        []

        [Y3]
                initial_condition = 0
        []
[]

[ICs]
        [hotspot]
                type = SmoothCircleIC
                variable = T
                invalue = 1920 # K
                outvalue = 300
                radius = 5
                x1 = 50
                y1 = 50
        []
[]

[Materials]
        [activation_energies]
                type = ADGenericConstantMaterial
                prop_names = 'E1 E2'
                prop_values = '24400 23500'
        []
        [pre_exponential_factors]
                type = ADGenericConstantMaterial
                prop_names = 'Z1 Z2'
                prop_values = '32103.943853583012 11810.38092425548'
        []
        [gas_constant]
                type = ADGenericConstantMaterial
                prop_names = 'R'
                prop_values = '1.987'
        []
        [thermal_constants]
                type = ADGenericConstantMaterial
                prop_names = 'rho cv k'
                prop_values = '1820e-9 2355.592 0.361'
        []

        #molecular weight
        [molecular_weight_RDX]
                type = ADGenericConstantMaterial
                prop_names = 'MW'
                prop_values = '0.22226' # kg / mol
        []

        #for scaling        
        [k_scaled]
                type = ADParsedMaterial
                material_property_names = 'rho cv k'
                expression = 'k/(rho*cv)'
                property_name = 'k_scaled'
        []
        
        #reaction heat materials
        [Q1]
                type = ADDerivativeParsedMaterial
                derivative_order = 2
                coupled_variables = 'T'
                expression = '-32002.15963286241 + if(T >= 1736.3, 591.0987132187528 * (T-1736.3), 0.0)'
                property_name = 'Q1'
        []
        [Q2]
                type = ADDerivativeParsedMaterial
                derivative_order = 2
                coupled_variables = 'T'
                expression = '7831116.710159273 + if(T >= 1736.3, -722.1193197156482 * (T-1736.3), 0.0)'
                property_name = 'Q2'
        []
        
        #compute reaction rates
        [r1]
                type = ADDerivativeParsedMaterial
                derivative_order = 2
                coupled_variables = 'T'
                material_property_names = 'E1 R Z1'
                expression = 'Z1 * exp(-E1/(R*T))'
                property_name = 'r1'
        []
        [r2]
                type = ADDerivativeParsedMaterial
                derivative_order = 2
                coupled_variables = 'T'
                material_property_names = 'E2 R Z2'
                expression = 'Z2 * exp(-E2/(R*T))'
                property_name = 'r2'
        []
        
        #second Y2 term
        [r2Y2]
                type = ADDerivativeParsedMaterial
                derivative_order = 2
                coupled_variables = 'T Y2'
                material_property_names = 'r2:=r2(T)'
                expression = 'r2 * Y2'
                property_name = 'r2Y2'
        []
        [r1Y1]
                type = ADDerivativeParsedMaterial
                derivative_order = 2
                coupled_variables = 'T Y1'
                material_property_names = 'r1:=r1(T)'
                expression = 'r1 * Y1'
                property_name = 'r1Y1'
        []

        #decomposition heat
        [QR]
                type = ADDerivativeParsedMaterial
                derivative_order = 2
                coupled_variables = 'T Y1 Y2'
                material_property_names = 'rho cv r1:=r1(T) r2:=r2(T) Q1:=Q1(T) Q2:=Q2(T)'
                expression = 'rho * (Q1 * r1 * Y1 + Q2 * r2 * Y2)'
                property_name = 'QR'
        []
[]

#define residuals

[Kernels]
        #reactions
        [Y1_dot]
                type = ADTimeDerivative
                variable = Y1
        []
        [Y1_source]
                type = ADMatBodyForce
                variable = Y1
                material_property = r1Y1
                value = -1
        []

        #second reaction
        [Y2_dot]
                type = ADTimeDerivative
                variable = Y2
        []
        [Y2_term1]
                type = ADMatBodyForce
                variable = Y2
                material_property = r2Y2
                value = -1
        []
        [Y2_term2]
                type = ADMatBodyForce
                variable = Y2
                material_property = r1Y1
                value = 1
        []
        
        #third reaction
        [Y3_dot]
                type = ADTimeDerivative
                variable = Y3
        []
        [Y3_term1]
                type = ADMatBodyForce
                variable = Y3
                material_property = r2Y2
                value = 1
        []

        #temperature kernels
        [T_dot]
                type = ADHeatConductionTimeDerivative
                variable = T
                density_name = rho
                specific_heat = cv
        []
        [conduction]
                type = ADHeatConduction
                variable = T
                thermal_conductivity = k
        []
        [decomposition]
                type = ADMatHeatSource
                variable = T
                material_property = 'QR'
        []
[]
[Executioner]
        type = Transient
        [./TimeStepper]
                type = FunctionDT
                function = timestep
                min_dt = 1e-8
        [../]
        nl_rel_tol = 1E-8
        nl_abs_tol = 1E-8
        solve_type = Newton
        petsc_options_iname = '-ksp_gmres_restart -pc_type -pc_hypre_type'
        petsc_options_value = '401 hypre boomeramg'
        automatic_scaling = true
        line_search = 'none'
[]

[Functions]
        [./timestep]
        type = ParsedFunction
        expression = '1e-3'
        [../]
[]

[Outputs]
        exodus = true
        time_step_interval = 5
[]      
