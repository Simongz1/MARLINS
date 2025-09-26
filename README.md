#PS-LIPIT Simulations Code Repository from Prof. [Marisol Koslowski](https://engineering.purdue.edu/ME/People/ptProfile?resource_id=29264) Group
=====
Fork "cat" to create a new MOOSE-based application.

For more information see: [https://mooseframework.org/getting_started/new_users.html#create-an-app](https://mooseframework.org/getting_started/new_users.html#create-an-app)

-------
To contribute, follow these steps:

This is the branch of the repository for the research group of Prof. [Marisol Koslowski](https://engineering.purdue.edu/ME/People/ptProfile?resource_id=29264) at Purdue University. The branch contains the code developed in the finite element solver [MOOSE](https://mooseframework.inl.gov/) to simulate PS-LIPIT Impact simulations.

Follow the tutorial below to run an example case.

Code maintained by:

[Simon Gonzalez-Zapata](https://github.com/Simongz1) - PhD Student in Mechanical Engineering, Purdue University

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

Here you will be able to define your own mesh geometry, either by importing a mesh in a supported mesh format, or by generating a mesh with the built-in mesh capabilities of base MOOSE. The .geo file used to generate the mesh files is available here.

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

fix_x -> constrain x displacements on the right and left ends of the film

fix_y -> constrain y displacements on the right and left ends of the film

[ICs] ([MOOSE - ICs Syntax](https://mooseframework.inl.gov/syntax/ICs/))

Here you will define the initial conditions for the problem. Initial conditions are usually coupled to blocks or boundaries.

ball_vel -> initial flyer velocity before impact

temp_IC -> temperature initial condition

ConstantIC -> set up gcprop initial condition 

[Materials] ([MOOSE - Materials Syntax](https://mooseframework.inl.gov/syntax/Materials/))

Here you will define material properties with specific models. These models are highly customizable, allowing for complex physics and tightly coupled systems.

plate_const -> define constant material properties for the film (Base MOOSE).

elastic_tensor_plate -> define the fourth order elasticity tensor for the film. Here we call the young modulus and poison’s ration defined as input variables using a parsed expression (Base MOOSE).

compute_strain_plate -> compute incremental deformation gradient from displacements (Base MOOSE).

flow_stress_plate -> define the Johnson-Cook yield parameters for the film. Note: do not modify compute = false (in-house coded).

compute_stress_plate -> compute the First Piola-Kirchhoff, Second Piola-Kirchhoff, consistent tangent modulus, radial return update of the intermediate configuration, elastic and plastic Lagrangian strains, strain energy, damage penalty to stress, plastic work, and stabilization by artificial viscosity. This material is the core of the model, and many of its parameters strongly modify the global behavior of the model (in-house coded).

elastic_tensor_ball -> compute fourth order elasticity tensor for the flyer (Base MOOSE). Note: we set the flyer to be many orders of magnitude stiffer than the film to simulate a “perfectly elastic” flyer. Modify accordingly.

compute_strain_ball -> compute incremental deformation gradient from displacements (Base MOOSE). 

compute_stress_ball -> compute linear elastic stress for the flyer using Hooke’s law (Base MOOSE).

[AuxVariables] ($\textbf{outputs}$)

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

[Contact] ([MOOSE - Contact Syntax](https://mooseframework.inl.gov/syntax/Contact/))

Here you will define the type of contact between the flyer and the film. 
primary = ball_bottom -> arbitrary name for the flywers surface
secondary = top -> arbitrary name for the films upper surface

[Executioner] ([MOOSE - Executioner Syntax](https://mooseframework.inl.gov/syntax/Executioner/))

Here you will define the type of problem. Note: these parameters should not be modified.

[Preconditioning] ([MOOSE - Preconditioning Syntax](https://mooseframework.inl.gov/syntax/Preconditioning/)) 

Note: read MOOSE’s documentation.

[Outputs] ([MOOSE - Outputs Syntax](https://mooseframework.inl.gov/syntax/Outputs/))

Here you will set up the outputs format, as well as outputs frequency.
exodus = true -> generates .e files. It is highly recommended to be read using Paraview.

interval = 20 -> this defines the frequency at which outputs are written into disk. Note: a high frequency makes simulation outputs very heavy, keep this value no lower than 20.

----------------------

Any additional information on specific MOOSE usage, modification, or customization, may be found on the following link: (MOOSE - Application Development)

----------------------

Code developed and maintained by:
Simon Gonzalez-Zapata

PhD Student – Purdue University

Contact: gonz1075@purdue.edu

GitHub: https://github.com/Simongz1/

# cat
