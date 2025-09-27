E = 3
nu = 0.33

####"LIPIT_finalV_fracture_coarse_better_gc1_nostick_close_posneg_h250_le20_gc1000_stick.i"

[GlobalParams]
  large_kinematics = true
  displacements = 'disp_x disp_y'
  
[]

[Variables]
  [disp_x]
  []
  [disp_y]
  []
  [temperature]
  []
  [c]
    initial_condition = 0.
  []
[]

[AuxVariables]
	##dynamics variables

	[./vx]
	[../]
	[./ax]
	[../]
	[./vy]
	[../]
	[./ay]
	[../]
  [./gcprop]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./dummyc]
    order = FIRST
    family = LAGRANGE
  [../]
[]

[Bounds]
  [c_up]
    type = VariableOldValueBounds
    variable = dummyc
    bounded_variable = c
    bound_type = lower
  []
  [c_down]
    type = ConstantBounds
    variable = dummyc
    bounded_variable = c
    bound_type = upper
    bound_value = 1.
  []
[]

[Mesh]
  [complete]
  	type = FileMeshGenerator
  	file = 'LIPIT_MSH_simple.msh'
  []
[]

[Kernels]
  ##temperature kernels
  [dTdt]
  	type = ADHeatConductionTimeDerivative
        variable = temperature
        density_name = 'density'
        specific_heat = 'specific_heat'
        block = '7 14'
  []
  [nabla2T]
  	type = ADHeatConduction
        variable = temperature
        thermal_conductivity = 'thermal_conductivity'
        block = '7 14'
  []
  [./PlasticHS] ##computes plastic flow heat source
    type = ADVisHSLIPIT
    variable = temperature
    beta_p = 0.15
    block = plate
  [../]
  [sdx]
    type = TotalLagrangianStressDivergence
    variable = disp_x
    component = 0
    displacements = 'disp_x disp_y'
    block = '7 14'
  []
  [sdy]
    type = TotalLagrangianStressDivergence
    variable = disp_y
    component = 1
    displacements = 'disp_x disp_y'
    block = '7 14'
  []
	[./inertia_x]
		type = ADInertialForce
		variable = disp_x
		velocity = vx
		acceleration = ax
		beta = 0.3025 ###from dandekar 2019 sec 2.1
		gamma = 0.6 ###from dandekar 2019 sec 2.1
		block = '7 14'
	[../]
	[./inertia_y]
		type = ADInertialForce
		variable = disp_y
		velocity = vy
		acceleration = ay
		beta = 0.3025 ###from dandekar 2019 sec 2.1
		gamma = 0.6 ###from dandekar 2019 sec 2.1
		block = '7 14'
	[../]

  ##fracture stuff
  [c_dot]
    type = ADTimeDerivative
    variable = c
    use_displaced_mesh = true
    block = plate
  []
  [AC]
    type = AllenCahn
    variable = c
    f_name = elastic_energy
    mob_name = L
    use_displaced_mesh = true
    block = plate
  []
  [ACInterface]
    type = ACInterface
    variable = c
    kappa_name = kappa
    mob_name = L
    use_displaced_mesh = true
    block = plate
  []
[]

[AuxKernels]
	[./vx]
	    	type = NewmarkVelAux
	    	variable = vx
	    	acceleration = ax
	    	gamma = 0.6
	    	block = '7 14'
	[../]
	[./vy]
	    	type = NewmarkVelAux
	    	variable = vy
	    	acceleration = ay
	    	gamma = 0.6
	    	block = '7 14'
	[../]
	[./ax]
	    	type = NewmarkAccelAux
	    	variable = ax
	    	displacement = disp_x
	    	velocity = vx
	    	beta = 0.3025
	    	block = '7 14'
	[../]
	[./ay]
	    	type = NewmarkAccelAux
	    	variable = ay
	    	displacement = disp_y
	    	velocity = vy
	    	beta = 0.3025
	    	block = '7 14'
	[../]
	
[]

[BCs]
  [fix_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'right left'
    value = 0.0
  []
  [fix_y]
  	type = DirichletBC
  	variable = disp_y
  	boundary = 'right left'
  	value = 0.0
  []
[]

[ICs]
	[ball_vel]
		type = ConstantIC
		variable = vy
		value = -350
		block = ball
	[]
	[temp_IC]
		type = ConstantIC
		variable = temperature
		value = 300
		block = '7 14'
	[]
  [ConstantIC]
    type = ConstantIC
    variable = gcprop
    value = 100e3
  []
[]

[Materials]
    
  ##materials on block 1: plate
  
  [plate_const]
  	type = ADGenericConstantMaterial
  	prop_names = 'density specific_heat thermal_conductivity alpha'
  	prop_values = '1100e-9 1250 0.13 3e-5' #kg/m3 J/kg-K W/m-K#
  []
  [elastic_tensor_plate]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = ${E}
    poissons_ratio = ${nu}
    block = '7'
  []
  [compute_strain_plate]
    type = ComputeLagrangianStrain
    displacements = 'disp_x disp_y'
    block = '7'
    #stabilize_strain = true
    #eigenstrain_names = thermal_expansion
  []
  
  [flow_stress_plate]
  	type = ComputeLagrangianJCYieldStressLIPIT
  	epsilon_ref = 1e3
  	transtemp = 400
  	temperature = temperature
  	T0 = 300
  	k = 3
  	compute = false
  	A = 1
  	B = 0.33
  	use_temp = 1.0
  	a_melt = 1.53
  	n_h = 1.0
  	use_rate = 1.0
  	block = plate
  []
  
  [compute_stress_plate]
    type = ADArtVisJ2StressLIPIT
    flow_stress_material = flow_stress_plate
    C0 = 0.1
    C1 = 1.0
    element_size = 60
    block = 7
    ##fracture parameters
    c = c
    l = 120
    kappa_name = kappa
    visco = 0.1
    gc = 5
    gcprop = gcprop
    kdamage = 1e-6
    ep_ref = 10
  []

  ##materials on block 2: ball
  [elastic_tensor_ball]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 10000
    poissons_ratio = 0.35
    block = ball
  []
  [compute_strain_ball]
    type = ComputeLagrangianStrain
    displacements = 'disp_x disp_y'
    block = ball
  []
  [compute_stress_ball]
    type = ComputeLagrangianLinearElasticStress
    block = ball
  []
[]

[AuxVariables]

  [Hist]
    family = MONOMIAL
    order = CONSTANT
    block = plate
    [AuxKernel]
      type = MaterialRealAux
      variable = Hist
      property = Hist
      block = plate
    []
  []
	
#######################
  [sxx]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = cauchy_stress
      index_i = 0
      index_j = 0
    []
  []
  [sxy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = cauchy_stress
      index_i = 0
      index_j = 1
    []
  []
  [sxz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = cauchy_stress
      index_i = 0
      index_j = 2
    []
  []
  [syy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = cauchy_stress
      index_i = 1
      index_j = 1
    []
  []
  [syz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = cauchy_stress
      index_i = 1
      index_j = 2
    []
  []
  [szz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = cauchy_stress
      index_i = 2
      index_j = 2
    []
  []



  #############

  [Fexx]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Fe
      block = plate
      index_i = 0
      index_j = 0
    []
  []
  [Fexy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Fe
      block = plate
      index_i = 0
      index_j = 1
    []
  []
  [Fexz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Fe
      block = plate
      index_i = 0
      index_j = 2
    []
  []
  [Feyy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Fe
      block = plate
      index_i = 1
      index_j = 1
    []
  []
  [Feyz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Fe
      block = plate
      index_i = 1
      index_j = 2
    []
  []
  [Fezz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Fe
      block = plate
      index_i = 2
      index_j = 2
    []
  []
  
  ##plastic deformation gradient

  [Fpxx]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Fp
      block = plate
      index_i = 0
      index_j = 0
    []
  []
  [Fpxy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Fp
      block = plate
      index_i = 0
      index_j = 1
    []
  []
  [Fpxz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Fp
      block = plate
      index_i = 0
      index_j = 2
    []
  []
  [Fpyy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Fp
      block = plate
      index_i = 1
      index_j = 1
    []
  []
  [Fpyz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Fp
      block = plate
      index_i = 1
      index_j = 2
    []
  []
  [Fpzz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Fp
      block = plate
      index_i = 2
      index_j = 2
    []
  []

  ##

  [Epxx]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ep
      block = plate
      index_i = 0
      index_j = 0
    []
  []
  [Epxy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ep
      block = plate
      index_i = 0
      index_j = 1
    []
  []
  [Epxz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ep
      block = plate
      index_i = 0
      index_j = 2
    []
  []
  [Epyy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ep
      block = plate
      index_i = 1
      index_j = 1
    []
  []
  [Epyz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ep
      block = plate
      index_i = 1
      index_j = 2
    []
  []
  [Epzz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ep
      block = plate
      index_i = 2
      index_j = 2
    []
  []

  [Ep_dotxx]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ep
      block = plate
      index_i = 0
      index_j = 0
    []
  []
  [Ep_dotxy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ep
      block = plate
      index_i = 0
      index_j = 1
    []
  []
  [Ep_dotxz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ep
      block = plate
      index_i = 0
      index_j = 2
    []
  []
  [Ep_dotyy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ep
      block = plate
      index_i = 1
      index_j = 1
    []
  []
  [Ep_dotyz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ep
      block = plate
      index_i = 1
      index_j = 2
    []
  []
  [Ep_dotzz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ep
      block = plate
      index_i = 2
      index_j = 2
    []
  []

  [Eexx]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ee
      block = plate
      index_i = 0
      index_j = 0
    []
  []
  [Eexy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ee
      block = plate
      index_i = 0
      index_j = 1
    []
  []
  [Eexz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ee
      block = plate
      index_i = 0
      index_j = 2
    []
  []
  [Eeyy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ee
      block = plate
      index_i = 1
      index_j = 1
    []
  []
  [Eeyz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ee
      block = plate
      index_i = 1
      index_j = 2
    []
  []
  [Eezz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ee
      block = plate
      index_i = 2
      index_j = 2
    []
  []

  [Ee_dotxx]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ee_dot
      block = plate
      index_i = 0
      index_j = 0
    []
  []
  [Ee_dotxy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ee_dot
      block = plate
      index_i = 0
      index_j = 1
    []
  []
  [Ee_dotxz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ee_dot
      block = plate
      index_i = 0
      index_j = 2
    []
  []
  [Ee_dotyy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ee_dot
      block = plate
      index_i = 1
      index_j = 1
    []
  []
  [Ee_dotyz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ee_dot
      block = plate
      index_i = 1
      index_j = 2
    []
  []
  [Ee_dotzz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = Ee_dot
      block = plate
      index_i = 2
      index_j = 2
    []
  []

  ###jacobians

  [Je]
  	family = MONOMIAL
  	order = CONSTANT
  	[AuxKernel]
  		type = RankTwoScalarAux
  		variable = Je
  		scalar_type = ThirdInvariant
      rank_two_tensor = Fe
      block = plate
      execute_on = timestep_end
  	[]
  []

  [detEe_dot]
  	family = MONOMIAL
  	order = CONSTANT
  	[AuxKernel]
  		type = RankTwoScalarAux
  		variable = detEe_dot
  		scalar_type = FirstInvariant
      rank_two_tensor = Ee_dot
      block = plate
      execute_on = timestep_end
  	[]
  []

  [Jp]
  	family = MONOMIAL
  	order = CONSTANT
  	[AuxKernel]
  		type = RankTwoScalarAux
  		variable = Jp
  		scalar_type = ThirdInvariant
      rank_two_tensor = Fp
      block = plate
      execute_on = timestep_end
  	[]
  []

  #############



  [pk1xx]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = pk1_stress
      index_i = 0
      index_j = 0
    []
  []
  [pk1xy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = pk1_stress
      index_i = 0
      index_j = 1
    []
  []
  [pk1xz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = pk1_stress
      index_i = 0
      index_j = 2
    []
  []
  [pk1yy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = pk1_stress
      index_i = 1
      index_j = 1
    []
  []
  [pk1yz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = pk1_stress
      index_i = 1
      index_j = 2
    []
  []
  [pk1zz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = pk1_stress
      index_i = 2
      index_j = 2
    []
  []

  [sigmaxx]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma
      index_i = 0
      index_j = 0
      block = 7
    []
  []
  [sigmaxy]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma
      index_i = 0
      index_j = 1
      block = 7
    []
  []
  [sigmaxz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma
      index_i = 0
      index_j = 2
      block = 7
    []
  []
  [sigmayy]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma
      index_i = 1
      index_j = 1
      block = 7
    []
  []
  [sigmayz]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma
      index_i = 1
      index_j = 2
      block = 7
    []
  []
  [sigmazz]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma
      index_i = 2
      index_j = 2
      block = 7
    []
  []

  [sigma_posxx]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_pos
      index_i = 0
      index_j = 0
      block = 7
    []
  []
  [sigma_posxy]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_pos
      index_i = 0
      index_j = 1
      block = 7
    []
  []
  [sigma_posxz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_pos
      index_i = 0
      index_j = 2
      block = 7
    []
  []
  [sigma_posyy]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_pos
      index_i = 1
      index_j = 1
      block = 7
    []
  []
  [sigma_posyz]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_pos
      index_i = 1
      index_j = 2
      block = 7
    []
  []
  [sigma_poszz]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_pos
      index_i = 2
      index_j = 2
      block = 7
    []
  []

  [sigma_negxx]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_neg
      index_i = 0
      index_j = 0
      block = 7
    []
  []
  [sigma_negxy]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_neg
      index_i = 0
      index_j = 1
      block = 7
    []
  []
  [sigma_negxz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_neg
      index_i = 0
      index_j = 2
      block = 7
    []
  []
  [sigma_negyy]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_neg
      index_i = 1
      index_j = 1
      block = 7
    []
  []
  [sigma_negyz]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_neg
      index_i = 1
      index_j = 2
      block = 7
    []
  []
  [sigma_negzz]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_neg
      index_i = 2
      index_j = 2
      block = 7
    []
  []

  [sigma_devxx]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_dev
      index_i = 0
      index_j = 0
      block = 7
    []
  []
  [sigma_devxy]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_dev
      index_i = 0
      index_j = 1
      block = 7
    []
  []
  [sigma_devxz]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_dev
      index_i = 0
      index_j = 2
      block = 7
    []
  []
  [sigma_devyy]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_dev
      index_i = 1
      index_j = 1
      block = 7
    []
  []
  [sigma_devyz]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_dev
      index_i = 1
      index_j = 2
      block = 7
    []
  []
  [sigma_devzz]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = sigma_dev
      index_i = 2
      index_j = 2
      block = 7
    []
  []

  [sigma_pressure]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = MaterialRealAux
      variable = sigma_pressure
      property = sigma_pressure
      block = 7
    []
  []
  
  ##TEST CAUCHY FROM BLATZ-KO STRAIN ENERGY DENSITY FUNCTIONAL
  
  [exx]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = total_strain
      index_i = 0
      index_j = 0
    []
  []
  [exy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = total_strain
      index_i = 0
      index_j = 1
    []
  []
  [exz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = total_strain
      index_i = 0
      index_j = 2
    []
  []
  [eyy]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = total_strain
      index_i = 1
      index_j = 1
    []
  []
  [eyz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = total_strain
      index_i = 1
      index_j = 2
    []
  []
  [ezz]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = RankTwoAux
      rank_two_tensor = total_strain
      index_i = 2
      index_j = 2
    []
  []

  [W]
    family = MONOMIAL
    order = CONSTANT
    block = plate
    [AuxKernel]
      type = MaterialRealAux
      variable = W
      property = W
      block = plate
    []
  []

  [Wpos]
    family = MONOMIAL
    order = CONSTANT
    block = plate
    [AuxKernel]
      type = MaterialRealAux
      variable = Wpos
      property = Wpos
      block = plate
    []
  []

  [Wneg]
    family = MONOMIAL
    order = CONSTANT
    block = plate
    [AuxKernel]
      type = MaterialRealAux
      variable = Wneg
      property = Wneg
      block = plate
    []
  []

  ##TEST: JC variables output
  
  [theta]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = MaterialRealAux
      variable = theta
      property = theta
      block = 7
    []
  []


  [./vonmisesstress]
    order = CONSTANT
    family = MONOMIAL
    block = 7
    [AuxKernel]
      type = RankTwoScalarAux
      variable = vonmisesstress
      rank_two_tensor = cauchy_stress
      scalar_type = VonMisesStress
      block = 7
    []
  [../]

  [ep_rate]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = MaterialRealAux
      variable = ep_rate
      property = ep_rate
      block = 7
    []
  []
  [ep]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = MaterialRealAux
      variable = ep
      property = effective_plastic_strain
      block = 7
    []
  []
  [flow_stress]
    family = MONOMIAL
    order = CONSTANT
    block = 7
    [AuxKernel]
      type = MaterialRealAux
      variable = flow_stress
      property = flow_stress
      block = 7
    []
  []
[]

[Contact]
    [mechanical]
      formulation = penalty #ranfs, kinematic, penalty, augmented_lagrange, tangential_penalty, mortar, mortar_penalty
      model = frictionless
      primary   = 'ball_bottom' 
      secondary = 'top'
      penalty = 1e3
      tension_release = 100 #this value can be modified if that improves convergence rate at each time step
    []
[]


[Executioner]
  type = Transient
  line_search = none
  petsc_options_iname = '-ksp_gmres_restart -pc_type -pc_hypre_type -pc_hypre_boomeramg_max_iter -snes_type'
  petsc_options_value = '201 hypre boomeramg 20 vinewtonrsls' 
  automatic_scaling = true
  solve_type = Newton
  l_max_its = 20
  nl_max_its = 20
  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-6
  start_time = 0.0
  dt = 1e-3
  end_time = 11.5
[]

[Preconditioning]
	[full]
		type = SMP
		full = true
	[]
[]

[Outputs]
  exodus = true
  interval = 20
[]
