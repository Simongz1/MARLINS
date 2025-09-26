# PS-LIPIT Impact Simulations Code Repository from Prof. [Marisol Koslowski](https://engineering.purdue.edu/ME/People/ptProfile?resource_id=29264) Group

Fork "cat" to create a new MOOSE-based application.

For more information see: [https://mooseframework.org/getting_started/new_users.html#create-an-app](https://mooseframework.org/getting_started/new_users.html#create-an-app)

-------
To contribute, follow these steps:

This is the branch of the repository for the research group of Prof. [Marisol Koslowski](https://engineering.purdue.edu/ME/People/ptProfile?resource_id=29264) at Purdue University. The branch contains the code developed in the finite element solver [MOOSE](https://mooseframework.inl.gov/) to simulate PS-LIPIT Impact simulations.

Follow the tutorial below to run an example case.

Code maintained by:

[Simon Gonzalez-Zapata](https://github.com/Simongz1) - PhD Student in Mechanical Engineering, Purdue University

## Dependecy versions:

+ MOOSE Version: git commit 72da5d58f0 on 2024-02-27
+ LibMesh Version: 31948b018e9bea83c138035e952d48065458ba4a
+ PETSc Version: 3.20.3
+ WASP Version: 4.2.0
+ LibTorch Version: 2.1.0 + cpu
+ SLEPc Version: 3.20.1
+ Gmsh Version: 4.13.1

## Build and run times

+ Build time: $\leq$ 4 hours on HPC - Linux system [Negishi](https://www.rcac.purdue.edu/compute/negishi).
+ Compilation time: $\leq$ 1 hour FIRST COMPILE on 4 Alta CPU cores. Check system specs and hardware [here](https://www.rcac.purdue.edu/compute/negishi). $\leq$ 3 minutes following compiles.
+ Simulation runtime: This aspect strongly depends on mesh size, resolution, hardware limitations and numerical precision. Simulations on 128 to 512 CPU cores typically take $\leq$ 3 days to run. The minimum runtime achievable with reliable results is $\approx$ 6 hours.

## Makefile configuration

MOOSE only compiles with modules marked for compilation in the MakeFile. The app is compiled with the flag ALL_MODULE := yes active

	################################## MODULES ####################################
	# To use certain physics included with MOOSE, set variables below to
	# yes as needed.  Or set ALL_MODULES to yes to turn on everything (overrides
	# other set variables).
	
	ALL_MODULES                 := yes
	
	CHEMICAL_REACTIONS          := no
	CONTACT                     := no
	ELECTROMAGNETICS            := no
	EXTERNAL_PETSC_SOLVER       := no
	FLUID_PROPERTIES            := no
	FSI                         := no
	FUNCTIONAL_EXPANSION_TOOLS  := no
	GEOCHEMISTRY                := no
	HEAT_TRANSFER               := no
	LEVEL_SET                   := no
	MISC                        := no
	NAVIER_STOKES               := no
	OPTIMIZATION                := no
	PERIDYNAMICS                := no
	PHASE_FIELD                 := no
	POROUS_FLOW                 := no
	RAY_TRACING                 := no
	REACTOR                     := no
	RDG                         := no
	RICHARDS                    := no
	STOCHASTIC_TOOLS            := no
	THERMAL_HYDRAULICS          := no
	TENSOR_MECHANICS            := no
	XFEM                        := no
	
	include $(MOOSE_DIR)/modules/modules.mk
	###############################################################################


## How to contribute?
+ Add your source files (.C) to the folder ./src/ and subfolder /kernel/ or /material/ depending on the object type
+ Add your header files (.h) to the folder ./include/ and subfolder /kernel/ or /material/ depending on the object type
+ Add example of MOOSE input (.i) file to the ./folder ExampleInputFiles/ with all required objects and variables for simulation setup

The material is publised under the GNU General Public License. You can reuse it if you also include the same license and cite this repository. Please send an e-mail to marisol@purdue.edu if you have any questions.

--------

## PS-Impact simulations tutorial for running test case
The following tutorial explains how to set up a PS-LIPIT impact simulation following the workflow for our $N1 \rightarrow v = 350\ m/s$ simulation case.

Note: MOOSE uses arbitrary units. The simulations we perform use the system:

+ Distance $\longrightarrow$ $nm$
+ Time $\longrightarrow$ $ns$
+ Pressure $\longrightarrow$ $GPa$

All other units for derived quanitites are consistent with these units.

### [NumericalValues]

You will be able to set any input-level variable here. You can call these values at different portions of the input file.

	E = 0.1 [GPa]
	nu = 0.33 [-]
	x = anyOtherNumericalValue [a.u]

### [GlobalParams] ([MOOSE - GlobalParams Syntax](https://mooseframework.inl.gov/syntax/GlobalParams/))

Here you will need to define any global parameters for all objects in the input file to retrieve. We use large_kinematics = true and we provide the displacements.
	
	[GlobalParams]
		large_kinematics = true
		displacements = 'disp_x disp_y'
	[]

### [Variables] ([MOOSE - Variables Syntax](https://mooseframework.inl.gov/syntax/Variables/))

Here you will set the nonlinear variables of the problem. 
	
	[Variables]
	  [disp_x] -> set up x component of displacements vector
	  []
	  [disp_y] -> set up y component of displacement vector
	  []
	  [temperature] -> set up temperature variable
	  []
	  [c] -> set up damage variable
	    initial_condition = 0. -> constant IC assignment
	  []
	[]

### [AuxVariables] ([MOOSE - AuxVariables Syntax](https://mooseframework.inl.gov/syntax/AuxVariables/))

Here you will set auxiliary variables to use with auxiliary kernels. We set the components of velocity and acceleration (v, a), gcprop to be the surface energy, and dummyc is used to constrain the values of c between 0 and 1. 

	[AuxVariables]
		[./vx] -> AuxVariables without ORDER and FAMILY declarations default to FIRST and LAGRANGE respectively
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

### [Bounds] ([MOOSE - Bounds Syntax](https://mooseframework.inl.gov/syntax/Bounds/))

Constrain the damage variable to be between 0 and 1. Any other bounds can be supplied following the syntax.

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

### [Mesh] ([MOOSE - Mesh Syntax](https://mooseframework.inl.gov/syntax/Mesh/))

Here you will be able to define your own mesh geometry, either by importing a mesh in a supported mesh format, or by generating a mesh with the built-in mesh capabilities of base MOOSE.

Different iterations of the PS-LIPIT Impact simulations can be generated using the .geo code at the [Mesh Folder](https://github.com/marisolkoslowski/Marisol/tree/LIPIT/Mesh), which also containts .msh files used to run the example. An imported mesh may be generated as

	[Mesh]
	  [someName]
	  	type = FileMeshGenerator
	  	file = 'someMesh.msh'
	  []
	[]

The names and ids of surfaces, boundaries, and blocks are arbitrary and depend solely on the setup of the .geo file and the .msh compiler used. These are consistent with the .geo file provided here.

### [Kernels] ([MOOSE - Kernels Syntax](https://mooseframework.inl.gov/syntax/Kernels/))

Each kernel sets up a contribution to the weak form residual of each nonlinear variable. Each kernel requires to indicate the variable to which it contributes (variable =). Each kernel can be assigned to a subset of the mesh (block =), and each subset can have independently assigned kernels.

Every kernel is passed on an input file with the general structure

	[arbitraryName]
		type = KernelType ---> May be a custom kernel or base MOOSE
		variable = someVariable ---> variable to which this kernel contributes
		block = someBlocks ---> list of all blocks where this kernel applies
		otherParameters ---> required or optional parameters (Materials, Variables, Constants)
	[]
	
Custom and base MOOSE kernels can be combined naturally as

	[Kernels]
		##--- [Thermal Evolution Kernels] ---##
		[dTdt]
			type = ADHeatConductionTimeDerivative ----> BASE MOOSE
			variable = temperature
			density_name = 'density'
			specific_heat = 'specific_heat'
			block = '7 14'
		[]
		[nabla2T]
			type = ADHeatConduction ----> BASE MOOSE
			variable = temperature
			thermal_conductivity = 'thermal_conductivity'
			block = '7 14'
		[]
		[./PlasticHS] ##computes plastic flow heat source
			type = ADVisHSLIPIT ----> CUSTOM KERNEL
			variable = temperature
			beta_p = 0.5
			block = plate
			beta_comp = 1
			reference_temperature = 300
		[../]
		##--- [Stress Divergence Kernels] ---##
		[sdx]
			type = TotalLagrangianStressDivergence ----> BASE MOOSE
			variable = disp_x
			component = 0
			displacements = 'disp_x disp_y'
			block = '7 14'
		[]
		[sdy]
			type = TotalLagrangianStressDivergence ----> BASE MOOSE
			variable = disp_y
			component = 1
			displacements = 'disp_x disp_y'
			block = '7 14'
		[]
		##--- [Inertia Kernels] ---##
		[./inertia_x]
			type = ADInertialForce ----> BASE MOOSE
			variable = disp_x
			velocity = vx
			acceleration = ax
			beta = 0.3025 ###from dandekar 2019 sec 2.1
			gamma = 0.6 ###from dandekar 2019 sec 2.1
			block = '7 14'
		[../]
		[./inertia_y]
			type = ADInertialForce ----> BASE MOOSE
			variable = disp_y
			velocity = vy
			acceleration = ay
			beta = 0.3025 ###from dandekar 2019 sec 2.1
			gamma = 0.6 ###from dandekar 2019 sec 2.1
			block = '7 14'
		[../]
	
		##--- [Phase Field Damage Kernels] ---##
		[c_dot]
			type = ADTimeDerivative ----> BASE MOOSE
			variable = c
			use_displaced_mesh = true
			block = plate
			[]
		[AC]
			type = AllenCahn ----> BASE MOOSE
			variable = c
			f_name = elastic_energy
			mob_name = L
			use_displaced_mesh = true
			block = plate
		[]
		[ACInterface]
			type = ACInterface ----> BASE MOOSE
			variable = c
			kappa_name = kappa
			mob_name = L
			use_displaced_mesh = true
			block = plate
		[]
	[]

### [AuxKernels] ([MOOSE - AuxKernels Syntax](https://mooseframework.inl.gov/syntax/AuxKernels/))

Here you’ll set up some AuxKernels required for inertia. Any other AuxKernels may be added here. The syntax for AuxKernels is fairly similar to that of Kernels.

+ Kernel $\longrightarrow$ Variable
+ AuxKernel $\longrightarrow$ AuxVariable

### [BCs] ([MOOSE - BCs Syntax](https://mooseframework.inl.gov/syntax/BCs/))

Here you will set up the boundary conditions of the problem. The boundary names are set on the .geo file provided. These are arbitrary, and can be modified or assigned manually if the mesh is generated using the MeshGenerator system.

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

### [ICs] ([MOOSE - ICs Syntax](https://mooseframework.inl.gov/syntax/ICs/))

Here you will define the initial conditions for the problem. Initial conditions are usually coupled to blocks or boundaries.

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

### [Materials] ([MOOSE - Materials Syntax](https://mooseframework.inl.gov/syntax/Materials/))

Here you will define material properties with specific models. These models are highly customizable, allowing for complex physics and tightly coupled systems.

Base MOOSE materials and Custom materials may be combined simply by listing them as

	[Materials]
	    
	  ##materials on block 7: plate
	  
	  [plate_const]
	  	type = ADGenericConstantMaterial ----> BASE MOOSE
	  	prop_names = 'density specific_heat thermal_conductivity alpha' 
	  	prop_values = '1100e-9 1250 0.13 3e-5' #kg/m3 J/kg-K W/m-K# 
	  []
	  [elastic_tensor_plate]
	    type = ComputeIsotropicElasticityTensor ----> BASE MOOSE
	    youngs_modulus = ${E}
	    poissons_ratio = ${nu}
	    block = '7'
	  []
	  [compute_strain_plate]
	    type = ComputeLagrangianStrain ----> BASE MOOSE
	    displacements = 'disp_x disp_y'
	    block = '7'
	    #stabilize_strain = true
	    #eigenstrain_names = thermal_expansion
	  []
	  
	  [flow_stress_plate]
	  	type = ComputeLagrangianJCYieldStressLIPIT ----> CUSTOM MATERIAL
	  	epsilon_ref = 1e3 ----> reference plastic strain rate
	  	transtemp = 400 ----> transition temperature
	  	temperature = temperature ----> temperature variable
	  	T0 = 300 ----> reference state temperature
	  	k = 1 ----> thermal softening coefficient
	  	compute = false ----> DO NOT MODIFY
	  	A = 0.2 ----> initial yield stress
	  	B = 0.33 ----> plastic modulus
	  	use_temp = 1.0 ----> whether or not to use temperature dependency on yield model
	  	a_melt = 1.53 ----> deprecated parameter
	  	n_h = 1.0 ----> hardening exponent
	  	use_rate = 1.0  ----> whether or not to use strain rate dependency on hardening
	  	block = plate ----> applied on plate
	  []
	  
	  [compute_stress_plate]
	    type = ADArtVisJ2StressLIPITFinite ----> CUSTOM MATERIAL
	    flow_stress_material = flow_stress_plate ----> where the yield stress is computed 
	    C0 = 0.1 ----> VonNeumann parameter
	    C1 = 1.0 ----> Landshoff parameter
	    element_size = 20
	    ##damage parameters
	    c = c ----> damage variabke
	    l = 5 ----> featyre width
	    kappa_name = kappa ----> kappa operator
	    visco = 0.1 ----> fracture speeed viscosity
	    gc = 1e-4 ----> surface energy
	    gcprop = gcprop ----> variable surface energy
	    kdamage = 1e-4 ----> residual stiffness
	    ep_ref = 2 ----> reference plastic strain for degradation function
	    ##declarations
	    elastic_energy_name = elastic_energy ----> DO NOT MODIFY
	    mobility_name = L ----> DO NOT MODIFY
	    h_min = h_min ----> variable storing the minimum element size
	    block = plate ----> apploed to plate
	  []
	
	  ##materials on block 14: ball
	  [elastic_tensor_ball]
	    type = ComputeIsotropicElasticityTensor ----> BASE MOOSE
	    youngs_modulus = 10000
	    poissons_ratio = 0.35
	    block = ball
	  []
	  [compute_strain_ball]
	    type = ComputeLagrangianStrain ----> BASE MOOSE
	    displacements = 'disp_x disp_y'
	    block = ball
	  []
	  [compute_stress_ball]
	    type = ComputeLagrangianLinearElasticStress ----> BASE MOOSE
	    block = ball
	  []
	[]

In particular, custom materials often require many input parameters.

### [AuxVariables] ($\textbf{outputs}$)

Note: MOOSE supports component-wise tensor outputs, as well as scalar outputs.

Structure for outputting scalars:


	[scalar]
		family = MONOMIAL -> can be modified
		order = CONSTANT -> can be modified
		block -> any
		[AuxKernel]
			type = (AD)MaterialRealAux -> generates output
			variable = scalar -> same as provided above
			block -> any
		[]
	[]
	

Structure for outputting tensors:

	[tensor_ij] -> outputs ij component
		family = MONOMIAL -> consistent for all components
		order = CONSTANT -> consistent for all components
		block -> any, consistent for all components
		[AuxKernel]
			type = RankTwoAux -> rank two tensor output
			rank_two_tensor = tensor -> same as above
			index_i = i -> same as above
			index_j = j -> same as above
		[]
	[]

### [Contact] ([MOOSE - Contact Syntax](https://mooseframework.inl.gov/syntax/Contact/))

Here you will define the type of contact between the flyer and the film. 

	[Contact]
	    [mechanical]
	      formulation = penalty ----> type of contact algorithm
	      model = frictionless ----> contact model
	      primary   = 'ball_bottom' ----> primary surface
	      secondary = 'top' ----> secondary surface
	      penalty = 1e3 ----> penalty for implicit return solve
	      tension_release = 100 ----> maximum debonding tension at iterface
	    []
	[]

### [Executioner] ([MOOSE - Executioner Syntax](https://mooseframework.inl.gov/syntax/Executioner/))

Here you will define the type of problem. Note: these parameters should be modified with caution.

	[Executioner]
	  type = Transient ----> type of MOOSE problem
	  line_search = none
	  petsc_options_iname = '-ksp_gmres_restart -pc_type -pc_hypre_type -pc_hypre_boomeramg_max_iter -snes_type' ----> PetSc options for PDE solver
	  petsc_options_value = '201 hypre boomeramg 20 vinewtonrsls'  ----> values
	  automatic_scaling = true ----> perform initial scaling calculation
	  solve_type = Newton ----> numerical integrator to use
	  l_max_its = 20 ----> maximum linear iterations per step
	  nl_max_its = 20 ----> maximum nonlinear iterations per step
	  nl_rel_tol = 1e-6 ----> nonlinear relative tolerance before failure and cut back of timestep
	  nl_abs_tol = 1e-6 ----> nonlinear absolute tolerance before failure and cut back of timestep
	  start_time = 0.0 ----> DO NOT MODIFY
	  dt = 1e-3 ----> timestep size
	  end_time = 10000 ----> final time
	[]

### [Preconditioning] ([MOOSE - Preconditioning Syntax](https://mooseframework.inl.gov/syntax/Preconditioning/)) 

Note: read MOOSE’s documentation.

### [Outputs] ([MOOSE - Outputs Syntax](https://mooseframework.inl.gov/syntax/Outputs/))

Here you will set up the outputs format, as well as outputs frequency.

	[Outputs]
	  exodus = true ----> type of output file for simulation results
	  interval = 20 ----> frequency of timeframe saving
	[]

----------------------

Any additional information on specific MOOSE usage, modification, or customization, may be found on the following link: (MOOSE - Application Development)

----------------------
# cat
