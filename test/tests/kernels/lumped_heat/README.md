Use ADMassLumpedHeatConductionTimeDerivative with FIRST LAGRANGE temperature.
It integrates rho*cv at quadrature points and multiplies each row by its nodal
AD temperature rate. With fixed capacity and geometry the temperature storage
Jacobian is diagonal; nonlinear capacity and geometry retain their AD couplings.

For current configuration: set use_displaced_mesh=true, density_name=current_density,
and specific_heat=specific_heat. Use physical conductivity in ADHeatConduction and
volumetric sources without division by rho*cv, on the displaced mesh. Convert the
reference-volume surrogate sources to current volume by dividing them by J.
Do not change the mechanics material to displaced geometry when it reconstructs
F = I + Grad_X(u). This kernel does not remove shared-node temperature averaging.

The heterogeneous test distinguishes row-sum lumping from a consistent mass
matrix and checks deposited energy. Run through the MOOSE test harness.
