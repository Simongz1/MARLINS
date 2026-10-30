# Units: micrometers (um), nanoseconds (ns), gigapascals (GPa), kelvin (K).
# Velocity: um/ns (= km/s); density: SI kg/m^3 * 1e-3.
# Specific energy and specific heat: SI values * 1e-6.
# Thermal conductivity: SI W/(m K) * 1e-6; reaction rates: ns^-1.
#try to keep these fixed
E = 20.76
nu = 0.24

[Distributions]
  
    [15_unreacted] type = Normal mean = 0.0234902173913043 standard_deviation = 0.0345482496170293 []
  
    [16_unreacted] type = Normal mean = 0.029853488372093 standard_deviation = 0.0549629451597098 []
  
    [17_unreacted] type = Normal mean = 0.0291649999999999 standard_deviation = 0.0328303506537873 []
  
    [18_unreacted] type = Normal mean = 0.0371776315789473 standard_deviation = 0.0224607366972335 []
  
    [19_unreacted] type = Normal mean = 0.0761246376811593 standard_deviation = 0.0698079158788749 []
  
    [20_unreacted] type = Normal mean = 0.0993134615384615 standard_deviation = 0.1021213292787807 []
  
    [21_unreacted] type = Normal mean = 0.1272085714285714 standard_deviation = 0.1008719583590666 []
  
    [22_unreacted] type = Normal mean = 0.1170555555555555 standard_deviation = 0.0558112388241379 []
  
    [23_unreacted] type = Normal mean = 0.1816888888888888 standard_deviation = 0.0786017723153306 []
  
    [24_unreacted] type = Normal mean = 0.3394 standard_deviation = 0.0813172798364529 []
  
    [25_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [26_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [27_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [28_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [29_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [30_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [31_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [32_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [33_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [34_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [35_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [36_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [37_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [38_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [39_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [40_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [41_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [42_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [43_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [44_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [45_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [46_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [47_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [48_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [49_unreacted] type = Normal mean = 0 standard_deviation = 1e-08 []
[]


[Distributions]
  
    [15_reacted] type = Normal mean = 0 standard_deviation = 1e-08 []
  
    [16_reacted] type = Normal mean = 1.6232666666666666 standard_deviation = 0.0763251116387436 []
  
    [17_reacted] type = Normal mean = 1.582749999999999 standard_deviation = 0.1906695308642685 []
  
    [18_reacted] type = Normal mean = 1.5146125 standard_deviation = 0.1800305413904355 []
  
    [19_reacted] type = Normal mean = 1.4573869565217388 standard_deviation = 0.1956506401828334 []
  
    [20_reacted] type = Normal mean = 1.3586025 standard_deviation = 0.2935895569367338 []
  
    [21_reacted] type = Normal mean = 1.2337561403508768 standard_deviation = 0.2906706156321618 []
  
    [22_reacted] type = Normal mean = 0.9880162162162156 standard_deviation = 0.2877276156876888 []
  
    [23_reacted] type = Normal mean = 0.6679999999999999 standard_deviation = 0.2194670957058505 []
  
    [24_reacted] type = Normal mean = 0.5641844444444444 standard_deviation = 0.2379034696655376 []
  
    [25_reacted] type = Normal mean = 0.4996184782608696 standard_deviation = 0.1818138994972774 []
  
    [26_reacted] type = Normal mean = 0.4761065217391304 standard_deviation = 0.1758941513651663 []
  
    [27_reacted] type = Normal mean = 0.4531184782608696 standard_deviation = 0.1639719320187651 []
  
    [28_reacted] type = Normal mean = 0.4265445652173912 standard_deviation = 0.1361950083512934 []
  
    [29_reacted] type = Normal mean = 0.4156043478260868 standard_deviation = 0.1319398730133495 []
  
    [30_reacted] type = Normal mean = 0.4054434782608695 standard_deviation = 0.1279499363842584 []
  
    [31_reacted] type = Normal mean = 0.3892869565217391 standard_deviation = 0.1067670641248706 []
  
    [32_reacted] type = Normal mean = 0.3765369565217391 standard_deviation = 0.0928672320844713 []
  
    [33_reacted] type = Normal mean = 0.3650717391304347 standard_deviation = 0.0785921176123174 []
  
    [34_reacted] type = Normal mean = 0.3534673913043477 standard_deviation = 0.0706490461096032 []
  
    [35_reacted] type = Normal mean = 0.3422923913043478 standard_deviation = 0.0668177860668712 []
  
    [36_reacted] type = Normal mean = 0.3272554347826086 standard_deviation = 0.0638916723393149 []
  
    [37_reacted] type = Normal mean = 0.3098880434782607 standard_deviation = 0.057496531844555 []
  
    [38_reacted] type = Normal mean = 0.2959423913043478 standard_deviation = 0.0546205617478197 []
  
    [39_reacted] type = Normal mean = 0.2787173913043477 standard_deviation = 0.0513902599244053 []
  
    [40_reacted] type = Normal mean = 0.2637923913043478 standard_deviation = 0.0486330219150779 []
  
    [41_reacted] type = Normal mean = 0.2468510869565216 standard_deviation = 0.0427979369292369 []
  
    [42_reacted] type = Normal mean = 0.2293260869565216 standard_deviation = 0.0377348175409594 []
  
    [43_reacted] type = Normal mean = 0.2146967391304347 standard_deviation = 0.0343960624218674 []
  
    [44_reacted] type = Normal mean = 0.2000249999999999 standard_deviation = 0.0312769747314481 []
  
    [45_reacted] type = Normal mean = 0.1853826086956521 standard_deviation = 0.0284547978097657 []
  
    [46_reacted] type = Normal mean = 0.171491304347826 standard_deviation = 0.0250943435339691 []
  
    [47_reacted] type = Normal mean = 0.1582054347826086 standard_deviation = 0.0224882453501771 []
  
    [48_reacted] type = Normal mean = 0.1449804347826086 standard_deviation = 0.019920237868358 []
  
    [49_reacted] type = Normal mean = 0.1331423913043478 standard_deviation = 0.0174619286581002 []
[]


[GlobalParams]
  # Materials and normalized thermal/species equations use reference geometry.
  use_displaced_mesh = false
  #general
  displacements = 'disp_x disp_y'

  #this should never change
  bulk_MicroID = 99

  #for microstructure
  bulk_grains = true

  dirac_tolerance = 0
  use_mixture = true
  
  #define binder mechanical properties
  #binder_bulk = 3.0
  #binder_yield = 0.07
  #binder_shear = 0.75

  fraction_csv = fraction_csv
  use_tabular_time = false
  use_distributions = false

  use_loaded_microstructure = false
  use_complete_burn = false

  #testing bulk grains
  n_pores = 10000000
  pore_probability = 0.01 # default is 0.01

  bulk_RDX_fraction = 1. ##saturated RDX
  pore_RDX_fraction = 1. ##this should be deprecated
  range_pore = '101 103' #keep constant

  ##csv data assignment
  csv_shock_pore = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/shock_pore.csv'
  csv_react_pore = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/react_pore.csv'
  csv_times_pore = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/time_pore.csv'
  csv_density_pore = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/density_pore.csv'
  csv_fraction_pore = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/fraction_pore.csv'

  #use old time formulation
  use_gating = false 

  #scale reaction time
  tau_react_scaling = 1.0

  #coefficients for the us_up relation
  #defaultusup
[]


[Functions]
    [loaded_microstructure]
        type = ParsedFunction
        expression = a
        symbol_names = 'a'
        symbol_values = '1'
    []
[]

[AuxVariables]
    [loaded_microstructure]
        order = CONSTANT
        family = MONOMIAL
    []
[]

[Variables]
  [dirac_switch_shock]
    order = CONSTANT
    family = MONOMIAL
  []
  [dirac_switch_react]
    order = CONSTANT
    family = MONOMIAL
  []
  [disp_x]
  []
  [disp_y]
  []
  

  [temperature]
  []
  [tracking]
    order = CONSTANT
    family = MONOMIAL
  []

	[Y1]
	[]
	[Y2]
	[]
	[Y3]
	[]
[]

[AuxVariables]
	##dynamics variables
	[vx]
    order = FIRST
    family = LAGRANGE
	[]
	[ax]
    order = FIRST
    family = LAGRANGE
	[]
	[vy]
    order = FIRST
    family = LAGRANGE
	[]
	[ay]
    order = FIRST
    family = LAGRANGE
	[]
  
[]

[Mesh]
  parallel_type = REPLICATED
  displacements = 'disp_x disp_y'
  [generated]
    type = GeneratedMeshGenerator
    extra_element_integers = 'microstructure_id legacy_prediction_id'
    elem_type = QUAD4
    dim = 2
    nx = 80
    ny = 300
    xmin = 0
    ymin = 0
    xmax = 80.0
    ymax = 300.0
  []
[]

#mesh refinement

[Materials]
    [Y2_flag]
      type = ADParsedMaterial
      coupled_variables = 'Y1 Y2 Y3 dirac_switch_react'
      material_property_names = 'time_react'
      expression = 'if(Y3 > 0.95 * max(Y1 + Y2 + Y3, 1e-12), 0, if(Y3 > 0.05, 1, 0) * if(Y2 < 0.5, 1, 0) * if(dirac_switch_react > time_react, 1, 0))'
      property_name = Y2_flag
    []
  []

[AuxVariables]
    [Y2_flag]
        order = CONSTANT
        family = MONOMIAL
    []
[]

[AuxKernels]
    [assign]
        type = ADMaterialRealAux
        property = Y2_flag
        variable = Y2_flag
        execute_on = 'timestep_end'
    []
[]

[Adaptivity]
    marker = bulk_marker
    max_h_level = 3

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

[AuxKernels]
  # Visualization only: no integer reader consumes this real-valued variable.
  [display_microstructure_id]
    type = MicrostructureIDAux
    variable = density_i
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

###global parameters for configuration consistency###

[Kernels]

  ###tracking shock location###
  [tracking_t]
    type = ADTimeDerivative
    variable = tracking
  []

  ###takeover windows###
  [dirac_switch_shock_time_derivative]
    type = ADTimeDerivative
    variable = dirac_switch_shock
  []
  [dirac_switch_react_time_derivative]
    type = ADTimeDerivative
    variable = dirac_switch_react
  []

  [rate_shock]
    type = ADMatBodyForce
    variable = dirac_switch_shock
    material_property = rate_dirac_shock
  []
  [rate_react]
    type = ADMatBodyForce
    variable = dirac_switch_react
    material_property = rate_dirac_react
  []
  [rate_tracking]
    type = ADMatBodyForce
    variable = tracking
    material_property = rate_tracking
  []
	
  ##temperature kernels
  [dTdt]
  	type = MassLumpedTimeDerivative
    variable = temperature
    # density_name = 'current_density'
    # specific_heat = 'specific_heat'
  []
  [nabla2T]
  	type = ADHeatConduction
    variable = temperature
    thermal_conductivity = 'k_corrected'
    use_displaced_mesh = true
  []

  ###mistnetx heats###
  [heat_shock]
    type = ADMatBodyForce
    variable = temperature
    material_property = scaled_shock
  []
  [heat_react]
    type = ADMatBodyForce
    variable = temperature
    material_property = scaled_react
  []

  ###linear momentum###
  [sdx]
    type = ADDynamicStressDivergenceTensors
    variable = disp_x
    component = 0
    use_displaced_mesh = true
    displacements = 'disp_x disp_y'
  []
  [inertia_x]
		type = ADInertialForce
    use_displaced_mesh = true
    density = current_density
		variable = disp_x
		velocity = vx
		acceleration = ax
		beta = 0.3025 
		gamma = 0.6 
	[]

  [sdy]
    type = ADDynamicStressDivergenceTensors
    variable = disp_y
    component = 1
    use_displaced_mesh = true
    displacements = 'disp_x disp_y'
  []
  [inertia_y]
		type = ADInertialForce
    use_displaced_mesh = true
    density = current_density
		variable = disp_y
		velocity = vy
		acceleration = ay
		beta = 0.3025 
		gamma = 0.6 
	[]

  

  [chem_from_prop]
    type = ADMatHeatSource
    variable = temperature
    material_property = scaled_chem
    scalar = 1 #can switch sign
    use_displaced_mesh = false
  []
  [PlasticHeat]
    type = ADMatHeatSource
    variable = temperature
    material_property = scaled_plastic
    scalar = 1 #to assign sign
    use_displaced_mesh = false
  []
  [ElasticHeat]
    type = ADMatHeatSource
    variable = temperature
    material_property = scaled_elastic
    scalar = 1
    use_displaced_mesh = false
  []

	[dY1_dt]
		type = MassLumpedTimeDerivative
		variable = Y1
	[]
  [Y1_source]
    type = ADMatBodyForce
    variable = Y1
    material_property = r1Y1
    value = -1
    use_displaced_mesh = false
  []

	[dY2_dt]
		type = MassLumpedTimeDerivative
		variable = Y2
	[]
  [Y2_term1]
  type = ADMatBodyForce
    variable = Y2
    material_property = r2Y2
    value = -1
    use_displaced_mesh = false
  []
  [Y2_term2]
    type = ADMatBodyForce
    variable = Y2
    material_property = r1Y1
    value = 1
    use_displaced_mesh = false
  []

	[dY3_dt]
    type = MassLumpedTimeDerivative
    variable = Y3
  []
  [Y3_term1]
    type = ADMatBodyForce
    variable = Y3
    material_property = r2Y2
    value = 1
    use_displaced_mesh = false
  []

	# [Y1dot]
	# 	type = ADY1_dot_RDX
	# 	variable = Y1
	# []
	# [Y2dot]
	# 	type = ADY2_dot_RDX
	# 	variable = Y2
	# 	Y1 = Y1
	# []
	# [Y3dot]
	# 	type = ADY3_dot_RDX
	# 	variable = Y3
	# 	Y2 = Y2
	# []

  [Y1_surr]
    type = ADMatBodyForce
    variable = Y1
    material_property = Y1_dot_surrogate
  []
  [Y2_surr]
    type = ADMatBodyForce
    variable = Y2
    material_property = Y2_dot_surrogate
  []
  [Y3_surr]
    type = ADMatBodyForce
    variable = Y3
    material_property = Y3_dot_surrogate
  []
  
[]

[AuxKernels]
	[vx]
    type = NewmarkVelAux
    variable = vx
    acceleration = ax
    gamma = 0.6
	[]
  [ax]
    type = NewmarkAccelAux
    variable = ax
    displacement = disp_x
    velocity = vx
    beta = 0.3025
	[]

	[vy]
    type = NewmarkVelAux
    variable = vy
    acceleration = ay
    gamma = 0.6
	[]
  [ay]
    type = NewmarkAccelAux
    variable = ay
    displacement = disp_y
    velocity = vy
    beta = 0.3025
	[]	

  
[]

[BCs]
  [x_fix]
    type = DirichletBC
    variable = disp_x
    boundary = 'left right'
    value = 0.0
  []
  
  [velocity]
    type = PresetVelocity
    boundary = bottom
    velocity = 1.2
    variable = disp_y
  []
  [top]
    type = DirichletBC
    boundary = top
    value = 0
    variable = disp_y
  []
[]

[ICs]
  [dirac_switch_shock_ic]
    type = ConstantIC
    variable = dirac_switch_shock
    value = 0.0
  []
  [dirac_switch_react_ic]
    type = ConstantIC
    variable = dirac_switch_react
    value = 0.0
  []
	[temp_IC]
		type = ConstantIC
		variable = temperature
		value = 300
	[]
	[chemY2_IC]
		type = ConstantIC
		variable = Y2
		value = 0.0
	[]
	[chemY3_IC]
		type = ConstantIC
		variable = Y3
		value = 0.0
	[]
[]

[Materials]
  ##define properties for binder
  [binder_properties]
    type = ADGenericConstantMaterial
    prop_names = 'binder_bulk binder_poisson binder_yield RDX_bulk RDX_poisson'
    prop_values = '3 0.45 0.07 20 0.24'
  []

  [reaction_properties]
    type = ADGenericConstantMaterial
    prop_names = 'E1 E2 logZ1 logZ2 R MW'
    prop_values = '24400 23500 31.1 30.1 1.987 0.22226'
  []

  [heat_source_properties]
    type = ADGenericConstantMaterial
    prop_names = 'a1 b1 a2 b2'
    prop_values = '-1.7 0.0314 416 -0.03836'
  []

  ###compute reaction rates###
  [r1]
    type = ADDerivativeParsedMaterial
    derivative_order = 2
    coupled_variables = 'temperature dirac_switch_react'
    material_property_names = 'E1 R logZ1 time_react'
    expression = 'if(dirac_switch_react > time_react, 1e-9 * exp(logZ1) * exp(- E1 / (R * temperature)), 0.0)'
    property_name = 'r1'
  []

  [r2]
    type = ADDerivativeParsedMaterial
    derivative_order = 2
    coupled_variables = 'temperature dirac_switch_react'
    material_property_names = 'E2 R logZ2 time_react'
    expression = 'if(dirac_switch_react > time_react, 1e-9 * exp(logZ2) * exp(- E2 / (R * temperature)), 0.0)'
    property_name = 'r2'
  []

  [r2Y2]
    type = ADDerivativeParsedMaterial
    derivative_order = 2
    coupled_variables = 'temperature Y2'
    material_property_names = 'r2:=r2(temperature)'
    expression = 'r2 * Y2'
    property_name = 'r2Y2'
  []

  [r1Y1]
    type = ADDerivativeParsedMaterial
    derivative_order = 2
    coupled_variables = 'temperature Y1'
    material_property_names = 'r1:=r1(temperature)'
    expression = 'r1 * Y1'
    property_name = 'r1Y1'
  []

  ###compute heats of reaction###

  [Q1]
    type = ADDerivativeParsedMaterial
    derivative_order = 2
    material_property_names = 'a1 b1 MW current_density'
    constant_names = 'kcal2specific_energy'
    constant_expressions = '4184e-6'
    coupled_variables = 'temperature'
    expression = 'kcal2specific_energy / MW * (a1 + if(temperature >= 1736.3, b1 * (temperature - 1736.3), 0.0))'
    property_name = 'Q1'
  []

  [Q2]
    type = ADDerivativeParsedMaterial
    derivative_order = 2
    material_property_names = 'a2 b2 MW current_density'
    constant_names = 'kcal2specific_energy'
    constant_expressions = '4184e-6'
    coupled_variables = 'temperature'
    expression = 'kcal2specific_energy / MW * (a2 + if(temperature >= 1736.3, b2 * (temperature - 1736.3), 0.0))'
    property_name = 'Q2'
  []
  
  ###current density###
  [current_density]
    type = ADDerivativeParsedMaterial
    material_property_names = 'density J'
    expression = 'density / J'
    property_name = 'current_density'
    derivative_order = 2
    coupled_variables = 'temperature'
  []

  [QR]
    type = ADDerivativeParsedMaterial
    derivative_order = 2
    coupled_variables = 'temperature Y1 Y2'
    material_property_names = 'current_density r1:=r1(temperature) r2:=r2(temperature) Q1:=Q1(temperature) Q2:=Q2(temperature)'
    expression = 'current_density * (Q1 * r1 * Y1 + Q2 * r2 * Y2)'
    property_name = 'QR'
  []

  [scaled_shock]
    type = ADParsedMaterial
    material_property_names = 'heatrate_mister_shock J current_density specific_heat'
    expression = '(heatrate_mister_shock / J) / (current_density * specific_heat)'
    property_name = scaled_shock
  []

  [scaled_react]
    type = ADParsedMaterial
    material_property_names = 'heatrate_mister_react J current_density specific_heat'
    expression = '(heatrate_mister_react / J) / (current_density * specific_heat)'
    property_name = scaled_react
  []

  [scaled_elastic]
    type = ADDerivativeParsedMaterial
    material_property_names = 'HS_elastic current_density specific_heat time_react'
    coupled_variables = 'temperature dirac_switch_react'
    expression = 'if(dirac_switch_react > time_react, HS_elastic / (current_density * specific_heat), 0.0)'
    property_name = scaled_elastic
  []

  [scaled_plastic]
    type = ADDerivativeParsedMaterial
    material_property_names = 'HS_plastic current_density specific_heat time_react'
    coupled_variables = 'temperature dirac_switch_react'
    expression = 'if(dirac_switch_react > time_react, HS_plastic / (current_density * specific_heat), 0.0)'
    property_name = scaled_plastic
  []

  [scaled_chem]
    type = ADParsedMaterial
    material_property_names = 'QR J current_density specific_heat'
    expression = '(QR) / (current_density * specific_heat)'
    property_name = scaled_chem
  []

  #materials for switches
  [rate_dirac_switch_shock]
    type = ADDerivativeParsedMaterial
    property_name = rate_dirac_shock
    material_property_names = 'v_flag time_shock'
    function = 'if(v_flag > 0, 1., 0.)'
  []

  [rate_dirac_switch_react]
    type = ADDerivativeParsedMaterial
    property_name = rate_dirac_react
    coupled_variables = 'dirac_switch_shock'
    material_property_names = 'time_react time_shock'
    function = 'if(dirac_switch_shock >= time_shock, 1., 0.)'
  []

  [ADplate_const]
  	type = ADGenericConstantMaterial
  	prop_names = 'specific_heat thermal_conductivity'
  	prop_values = '2355.592e-6 0.361e-6' 
  []

  [k_corrected]
    type = ADDerivativeParsedMaterial
    property_name = k_corrected
    material_property_names = 'density specific_heat thermal_conductivity'
    expression = 'thermal_conductivity / (density * specific_heat)' 
  []

  [elastic_tensor_plate]
    type = ADComputeVariableIsotropicElasticityTensor
    youngs_modulus = ${E}
    poissons_ratio = ${nu}
  []

  [compute_strain_plate]
    type = ADComputeFiniteStrain
    displacements = 'disp_x disp_y'
  []

  [yield_mixture]
    type = ADDerivativeParsedMaterial
    derivative_order = 2
    expression = 'fraction_csv * (A + B * ep ^ (1+n)) + (1 - fraction_csv) * yield_binder'
    material_property_names = 'ep'
    constant_names = 'A B n m yield_binder'
    constant_expressions = '0.3 0.1 0.1 3 0.07'
    property_name = yield_mixture
    coupled_variables = 'temperature fraction_csv'
    compute = false
  []
  
  ##replace by actual calculation of the chemistry rates here


  [compute_stress_plate]
    type = ADPBXStress
    stress_measure = cauchy
    deformation_gradient_reconstruction = total
    flow_stress_material = yield_mixture
    #poisson_binder = 0.35
    C0 = 0.1
    C1 = 1.0
    element_size = 1.0
    Yinitial = Y1
    #displacements = 'disp_x disp_y'

    A_unreacted = 13398.42268091
    R1_unreacted = 68.1217746
    R2_unreacted = 6.81217746
    B_unreacted = 3810.3712782
    omega_unreacted = 0.37

    #reacted
    A_reacted = 1000
    R1_reacted = 59.99058313
    R2_reacted = 5.999058313
    B_reacted = 2738.01645291
    omega_reacted = 0.77

    temperature = temperature
    outputs = exodus
  []

  [compute_misternet_heat]
    type = ADComputeMISTERnetHeat
    dirac_switch_shock = dirac_switch_shock
    dirac_switch_react = dirac_switch_react
    temperature = temperature
    density = density
    specific_heat = specific_heat
    T_ref = 300
    element_size = 1.0
    fraction_csv = fraction_csv

    ##for velocity and acceleration thresholds
    v_components = 'vx vy'
    a_components = 'ax ay'
    outputs = exodus
  []

  [pressureval]
    type = ADComputeIntPValRDXMISTERnetInteger
    element_size = 1.0
    tracking = tracking    
    ##call parameters
    thr_a = 1.5 ##acceleration smaller than this value CURRENTLY WORKING VALUE OF 2.5e-2
    thr_v = 0.5 ##velocity grater than this value
    v_components = 'vx vy'
    a_components = 'ax ay'

    microstructure_id_name = legacy_prediction_id	

	  ###########CSV data
    csv_shock = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/shock_new.csv'
    csv_react = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/react_new.csv'
    csv_times = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/time_new.csv'

    ##variable that stores density from csv
    density_csv = density_csv

    #############
    csv_unreacted = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/unreacted.csv'
    csv_reacted = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/reacted.csv'
    outputs = exodus
  []

[]

[AuxKernels]
  #######to assign density as a function of the voronoi tessellation
  [readVoronoiStructure]
    type = PolycrystalIntegerDensityAux
    variable = density_csv
    execute_on = INITIAL
      csv_density = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/densities_new.csv'
    microstructure_id_name = microstructure_id
    density_scaling = 1e-3 # kg/m^3 to um-ns-GPa density

    ##testing bulk grains
  
    bulk_RDX_density = 1820.0 # supplied in kg/m^3; density_scaling applied by AuxKernel
  []
  [readVoronoiRDXFraction]
    type = PolycrystalIntegerFractionAux
    variable = fraction_csv
    execute_on = 'INITIAL TIMESTEP_END'
      csv_fraction = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/fractions_new.csv'
    microstructure_id_name = microstructure_id  
    bulk_RDX_fraction = 1.
  []
[]

[UserObjects]
  [voronoi_density]
    type = PolycrystalDensityIntegerLegacyUO
    num_grains = 800
    target_grains = '1'
    range_in = '1 90' #this is for particles
    range_out = '1 90' #this is for binder
    generate_matrix = true #keep true
    max_grain_size = 1000
    execute_on = 'INITIAL TIMESTEP_END'
    min_center_spacing = 30.0
    matrix_thickness = 5
    sizes = '30.0 100.0'
    sizes_fraction = '0.7 0.3'

    ##for fraction assignment
    csv_fraction = '/scratch/negishi/gonz1075/mist2/pbx_corrected/csv/fractions_new.csv'
  []
[]

[AuxVariables]
  [./density_i]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [density_csv]
    order = CONSTANT
    family = MONOMIAL
  []
  [fraction_csv]
    order = CONSTANT
    family = MONOMIAL
  []
  [grainID]
    order = CONSTANT
    family = MONOMIAL
  []

  [von_mises]
  	family = MONOMIAL
  	order = CONSTANT
  	[AuxKernel]
  		type = ADRankTwoScalarAux
  		variable = von_mises
  		scalar_type = VonMisesStress
      rank_two_tensor = sigma_total
      execute_on = timestep_end
  	[]
  []
  [s_pressure]
  	family = MONOMIAL
  	order = CONSTANT
  	[AuxKernel]
  		type = ADRankTwoScalarAux
  		variable = s_pressure
  		scalar_type = Hydrostatic
      rank_two_tensor = sigma_total
      execute_on = timestep_end
  	[]
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
	petsc_options_iname = '-ksp_gmres_restart -pc_type -pc_hypre_type -pc_hypre_boomeramg_max_iter -snes_type'
	petsc_options_value = '401 hypre boomeramg 60 vinewtonrsls' 
	automatic_scaling = true
	line_search = 'none'
[]

[Functions]
  [./timestep]
    type = ParsedFunction
    expression = 'if(t<1, 5e-3, 5e-3)'
  [../]
[]

[Outputs]
  exodus = true
  time_step_interval = 10
  [./mycheckpoints]
    type = Checkpoint
    wall_time_interval = 2000
  []
[]
