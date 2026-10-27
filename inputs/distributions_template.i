# Units: micrometers (um), nanoseconds (ns), gigapascals (GPa), kelvin (K).
# Velocity: um/ns (= km/s); density: SI kg/m^3 * 1e-3.
# Specific energy and specific heat: SI values * 1e-6.
# Thermal conductivity: SI W/(m K) * 1e-6; reaction rates: ns^-1.
#try to keep these fixed
E = 20.76
nu = 0.24

{UNREACTED_DISTRIBUTIONS}

{REACTED_DISTRIBUTIONS}

[GlobalParams]
  # Materials and normalized thermal/species equations use reference geometry.
  use_displaced_mesh = false
  #general
  displacements = '{DISPLACEMENTS}'

  #this should never change
  bulk_MicroID = 99

  #for microstructure
  bulk_grains = {BULK_GRAINS}

  dirac_tolerance = 0
  use_mixture = {USE_MIXTURE}
  
  #define binder mechanical properties
  #binder_bulk = {BINDER_BULK}
  #binder_yield = {BINDER_YIELD}
  #binder_shear = {BINDER_SHEAR}

  fraction_csv = fraction_csv
  use_tabular_time = {TABULAR_TIME}
  use_distributions = {DISTRIBUTIONS}

  use_loaded_microstructure = {LOADED_MICROSTRUCTURE}
  use_complete_burn = {COMPLETE_BURN}

  #testing bulk grains
  n_pores = {N_PORES}
  pore_probability = {POROSITY} # default is 0.01

  bulk_RDX_fraction = 1. ##saturated RDX
  pore_RDX_fraction = 1. ##this should be deprecated
  range_pore = '101 103' #keep constant

  ##csv data assignment
  csv_shock_pore = '{CSV_DIR}/shock_pore.csv'
  csv_react_pore = '{CSV_DIR}/react_pore.csv'
  csv_times_pore = '{CSV_DIR}/time_pore.csv'
  csv_density_pore = '{CSV_DIR}/density_pore.csv'
  csv_fraction_pore = '{CSV_DIR}/fraction_pore.csv'

  #use old time formulation
  use_gating = {USE_GATING} 

  #scale reaction time
  tau_react_scaling = {SCALING_TAU}

  #coefficients for the us_up relation
  {USUP_COEFFS}
[]

{MICROSTRUCTURE_FUNCTION}

{MICROSTRUCTURE_VARIABLE}

{MICROSTRUCTURE_IC}

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
  {Z_DISPLACEMENT}

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
  {Z_AUX_VARIABLES}
[]

{MESH}


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
    use_displaced_mesh = {MECHANICS_DISPLACED}
    displacements = '{DISPLACEMENTS}'
  []
  [inertia_x]
		type = ADInertialForce
    use_displaced_mesh = {MECHANICS_DISPLACED}
    density = {INERTIA_DENSITY}
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
    use_displaced_mesh = {MECHANICS_DISPLACED}
    displacements = '{DISPLACEMENTS}'
  []
  [inertia_y]
		type = ADInertialForce
    use_displaced_mesh = {MECHANICS_DISPLACED}
    density = {INERTIA_DENSITY}
		variable = disp_y
		velocity = vy
		acceleration = ay
		beta = 0.3025 
		gamma = 0.6 
	[]

  {Z_KERNELS}

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

  {Z_AUX_KERNELS}
[]

[BCs]
  [x_fix]
    type = DirichletBC
    variable = disp_x
    boundary = 'left right'
    value = 0.0
  []
  {Z_BC}
  [velocity]
    type = PresetVelocity
    boundary = bottom
    velocity = {IMPACT_VELOCITY}
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
    expression = 'current_density * kcal2specific_energy / MW * (a1 + if(temperature >= 1736.3, b1 * (temperature - 1736.3), 0.0))'
    property_name = 'Q1'
  []
  [Q2]
    type = ADDerivativeParsedMaterial
    derivative_order = 2
    material_property_names = 'a2 b2 MW current_density'
    constant_names = 'kcal2specific_energy'
    constant_expressions = '4184e-6'
    coupled_variables = 'temperature'
    expression = 'current_density * kcal2specific_energy / MW * (a2 + if(temperature >= 1736.3, b2 * (temperature - 1736.3), 0.0))'
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
    material_property_names = 'r1:=r1(temperature) r2:=r2(temperature) Q1:=Q1(temperature) Q2:=Q2(temperature)'
    expression = '(Q1 * r1 * Y1) + (Q2 * r2 * Y2)'
    property_name = 'QR'
  []

  [scaled_shock]
    type = ADParsedMaterial
    material_property_names = 'heatrate_mister_shock J {HEAT_DENSITY} specific_heat'
    expression = '({SHOCK_HEAT}) / ({HEAT_DENSITY} * specific_heat)'
    property_name = scaled_shock
  []

  [scaled_react]
    type = ADParsedMaterial
    material_property_names = 'heatrate_mister_react J {HEAT_DENSITY} specific_heat'
    expression = '({REACT_HEAT}) / ({HEAT_DENSITY} * specific_heat)'
    property_name = scaled_react
  []

  [scaled_elastic]
    type = ADDerivativeParsedMaterial
    material_property_names = 'HS_elastic {HEAT_DENSITY} specific_heat time_react'
    coupled_variables = 'temperature dirac_switch_react'
    expression = 'if(dirac_switch_react > time_react, HS_elastic / ({HEAT_DENSITY} * specific_heat), 0.0)'
    property_name = scaled_elastic
  []

  [scaled_plastic]
    type = ADDerivativeParsedMaterial
    material_property_names = 'HS_plastic {HEAT_DENSITY} specific_heat time_react'
    coupled_variables = 'temperature dirac_switch_react'
    expression = 'if(dirac_switch_react > time_react, HS_plastic / ({HEAT_DENSITY} * specific_heat), 0.0)'
    property_name = scaled_plastic
  []

  [scaled_chem]
    type = ADParsedMaterial
    material_property_names = 'QR J {HEAT_DENSITY} specific_heat'
    expression = '({CHEM_HEAT}) / ({HEAT_DENSITY} * specific_heat)'
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
    displacements = '{DISPLACEMENTS}'
  []

  [yield_mixture]
    type = ADDerivativeParsedMaterial
    derivative_order = 2
    expression = 'fraction_csv * (A + B * ep ^ (1+n)) + (1 - fraction_csv) * yield_binder'
    material_property_names = 'ep'
    constant_names = 'A B n m yield_binder'
    constant_expressions = '0.3 0.1 0.1 3 {BINDER_YIELD}'
    property_name = yield_mixture
    coupled_variables = 'temperature fraction_csv'
    compute = false
  []
  
  ##replace by actual calculation of the chemistry rates here


  [compute_stress_plate]
    type = ADPBXStress
    stress_measure = {STRESS_MEASURE}
    deformation_gradient_reconstruction = {RECONSTRUCTION}
    flow_stress_material = yield_mixture
    #poisson_binder = {BINDER_POISSON}
    C0 = 0.1
    C1 = 1.0
    element_size = {SHOCKDIR}
    Yinitial = Y1
    #displacements = '{DISPLACEMENTS}'

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
    {OUTPUTS}
  []

  [compute_misternet_heat]
    type = ADComputeMISTERnetHeat
    dirac_switch_shock = dirac_switch_shock
    dirac_switch_react = dirac_switch_react
    temperature = temperature
    density = density
    specific_heat = specific_heat
    T_ref = 300
    element_size = {SHOCKDIR}
    fraction_csv = fraction_csv

    ##for velocity and acceleration thresholds
    v_components = '{VELOCITIES}'
    a_components = '{ACCELERATIONS}'
    {OUTPUTS}
  []

  [pressureval]
    type = ADComputeIntPValRDXMISTERnetNSFull
    element_size = {SHOCKDIR}
    tracking = tracking    
    ##call parameters
    thr_a = 1.5 ##acceleration smaller than this value CURRENTLY WORKING VALUE OF 2.5e-2
    thr_v = 0.5 ##velocity grater than this value
    v_components = '{VELOCITIES}'
    a_components = '{ACCELERATIONS}'

    density_i = density_i	

	  ###########CSV data
    csv_shock = '{CSV_DIR}/shock_new.csv'
    csv_react = '{CSV_DIR}/react_new.csv'
    csv_times = '{CSV_DIR}/time_new.csv'

    ##variable that stores density from csv
    density_csv = density_csv

    #############
      csv_unreacted = '{CSV_DIR}/unreacted.csv'
      csv_reacted = '{CSV_DIR}/reacted.csv'
    {OUTPUTS}
  []

[]

[AuxKernels]
  #######to assign density as a function of the voronoi tessellation
  [readVoronoiStructure]
    type = PolycrystalDensityAux
    variable = density_csv
    execute_on = INITIAL
      csv_density = '{CSV_DIR}/densities_new.csv'
    density_i = density_i
    density_scaling = 1e-3 # kg/m^3 to um-ns-GPa density

    ##testing bulk grains
  
    bulk_RDX_density = {BULK_DENSITY} # supplied in kg/m^3; density_scaling applied by AuxKernel
  []
  [readVoronoiRDXFraction]
    type = PolycrystalFractionAux
    variable = fraction_csv
    execute_on = 'INITIAL TIMESTEP_END'
      csv_fraction = '{CSV_DIR}/fractions_new.csv'
    density_i = density_i  
    bulk_RDX_fraction = 1.
  []
[]

[UserObjects]
  [voronoi_density]
    type = PolycrystalDensityUOV2
    num_grains = {NUM_GRAINS}
    target_grains = '1'
    range_in = '{PARTICLE_RANGE_SMALL} {PARTICLE_RANGE_LARGE}' #this is for particles
    range_out = '{BINDER_RANGE_SMALL} {BINDER_RANGE_LARGE}' #this is for binder
    generate_matrix = true #keep true
    max_grain_size = 1000
    execute_on = 'INITIAL TIMESTEP_END'
    min_center_spacing = {SMALL_SIZE}
    matrix_thickness = {BINDER_WIDTH}
    sizes = '{SMALL_SIZE} {BIG_SIZE}'
    sizes_fraction = '{SMALL_PROPORTION} {BIG_PROPORTION}'

    ##for fraction assignment
      csv_fraction = '{CSV_DIR}/fractions_new.csv'
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
  time_step_interval = 20
  [./mycheckpoints]
    type = Checkpoint
    wall_time_interval = {{FREC}}
  []
[]
