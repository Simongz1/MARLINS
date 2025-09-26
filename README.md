PS-LIPIT Simulations Code
=====

Fork "cat" to create a new MOOSE-based application.

For more information see: [https://mooseframework.org/getting_started/new_users.html#create-an-app](https://mooseframework.org/getting_started/new_users.html#create-an-app)

[NumericalValues]

You will be able to set any input-level variable here. You can call these values at different portions of the input file.
E=1 [GPa] -> elasticity modulus
nu = 0.33 [-] -> poisson’s ration

[GlobalParams] (MOOSE - GlobalParams Syntax)

Here you will need to define any global parameters for all objects in the input file to retrieve. We use large_kinematics = true and we provide the displacements.

[Variables] (MOOSE - Variables Syntax)

Here you will set the nonlinear variables of the problem. 

disp_x -> x component of displacements vector.
disp_y -> y component of displacements vector.
temperature -> temperature.
c -> damage variable.

[AuxVariables] (MOOSE - AuxVariables Syntax)

Here you will set auxiliary variables to use with auxiliary kernels. We set the components of velocity and acceleration (v, a), gcprop to be the surface energy, and dummyc is used to constrain the values of c between 0 and 1. 

order = CONSTANT -> no quadrature point interpolation.
order = FIRST -> linear interpolation between quadrature points.
family = LAGRANGE -> variable define in the lagrangian frame of reference.
family = MONOMIAL -> constant on the mesh.

[Bounds] (MOOSE - Bounds Syntax)

Constrain the damage variable to be between 0 and 1. Any other bounds can be supplied following the syntax, but caution is advised their use can over constraint the system of PDEs, causing unrealistic behavior.

[Mesh] (MOOSE - Mesh Syntax)

Here you will be able to define your own mesh geometry, either by importing a mesh in a supported mesh format, or by generating a mesh with the built-in mesh capabilities of base MOOSE. The .geo file used to generate the mesh files is available here.

block = 7 -> plate: block corresponding to the film.
block = 14 -> ball: block corresponding to the flyer.

These names and ids are arbitrary and depend solely on the setup of the .geo file and the .msh compiler used. These are consistent with the .geo file provided.

[Kernels] (MOOSE - Kernels Syntax)

Each kernel sets up a contribution to the weak form residual of each nonlinear variable. Each kernel requires to indicate the variable to which it contributes (variable =). Each kernel can be assigned to a subset of the mesh (block =), and each subset can have independently assigned kernels.

dTdt -> time derivative of temperature (Base MOOSE)

nabla2T -> heat conduction (Base MOOSE)

PlasticHS -> plastic deformation and compression heat sources (in-house coded)

sdx -> stress divergence for balance of linear momentum in x direction (Base MOOSE)

sdy -> stress divergence for balance of linear momentum in y direction (Base MOOSE)

intertia_x -> inertial force for balance of linear momentum in x direction (Base MOOSE)

inertia_y -> inertial force for balance of linear momentum in y direction (Base MOOSE)

c_dot -> time derivative of damage variable (Base MOOSE)

AC -> Allen-Cahn evolution equation for the damage phase (Base MOOSE)

ACInterface -> magnitude of the gradient of the damage field (Base MOOSE)

NOTE: For the present simulations damage was disabled, but the capability is built into the code and can be enabled.

[AuxKernels] (MOOSE - AuxKernels Syntax)

Here you’ll set up some kernels required for inertia.

[BCs] (MOOSE - BCs Syntax)

Here you will set up the boundary conditions of the problem. The boundary names are set on the .geo file provided. These are arbitrary, and can be modified or assigned manually if the mesh is generated using the MeshGenerator system.
fix_x -> constrain x displacements on the right and left ends of the film
fix_y -> constrain y displacements on the right and left ends of the film

[ICs] (MOOSE - ICs Syntax)

Here you will define the initial conditions for the problem. Initial conditions are usually coupled to blocks or boundaries.
ball_vel -> initial flyer velocity before impact
temp_IC -> temperature initial condition
ConstantIC -> set up gcprop initial condition 

[Materials] (MOOSE - Materials Syntax)

Here you will define material properties with specific models. These models are highly customizable, allowing for complex physics and tightly coupled systems.
plate_const -> define constant material properties for the film (Base MOOSE).
elastic_tensor_plate -> define the fourth order elasticity tensor for the film. Here we call the young modulus and poison’s ration defined as input variables using a parsed expression (Base MOOSE).
compute_strain_plate -> compute incremental deformation gradient from displacements (Base MOOSE).
flow_stress_plate -> define the Johnson-Cook yield parameters for the film. Note: do not modify compute = false (in-house coded).
compute_stress_plate -> compute the First Piola-Kirchhoff, Second Piola-Kirchhoff, consistent tangent modulus, radial return update of the intermediate configuration, elastic and plastic Lagrangian strains, strain energy, damage penalty to stress, plastic work, and stabilization by artificial viscosity. This material is the core of the model, and many of its parameters strongly modify the global behavior of the model (in-house coded).
elastic_tensor_ball -> compute fourth order elasticity tensor for the flyer (Base MOOSE). Note: we set the flyer to be many orders of magnitude stiffer than the film to simulate a “perfectly elastic” flyer. Modify accordingly.
compute_strain_ball -> compute incremental deformation gradient from displacements (Base MOOSE). 
compute_stress_ball -> compute linear elastic stress for the flyer using Hooke’s law (Base MOOSE).

[AuxVariables] (Outputs)

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

[Contact] (MOOSE - Contact Syntax)

Here you will define the type of contact between the flyer and the film. 
primary = ball_bottom -> arbitrary name for the flywers surface
secondary = top -> arbitrary name for the films upper surface

[Executioner] (MOOSE - Executioner Syntax)

Here you will define the type of problem. Note: these parameters should not be modified.

[Preconditioning] (MOOSE - Preconditioning Syntax) 

Note: read MOOSE’s documentation.

[Outputs] (MOOSE - Outputs Syntax)

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
