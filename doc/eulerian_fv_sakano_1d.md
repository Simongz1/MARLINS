# Sakano-matched longitudinal FV analogue

Run `./scripts/run_eulerian_fv_sakano.sh` from the application directory. The separate input is `inputs/eulerian_fv_sakano_1d.i`. It retains the equations and fluxes of the existing 1D mechanics prototype. No existing input or C++ object is modified.

Reference: `/scratch/negishi/gonz1075/mist2/sakano_proof/sakano_T_Y_P_1um_lump.i`.

| Quantity | Reference | FV analogue |
|---|---|---|
| Domain | 5000 x 5000 nm | 0 to 5 um, longitudinal |
| Resolution | 250 x 250 cells, 20 nm | 250 cells, 0.02 um |
| Hotspot | radius 500 nm, centre (2500,2500) nm | halfwidth 0.5 um, centre 2.5 um |
| Temperature | 1920 K inside, 300 K outside | same sharp centreline profile |
| Initial velocity | zero | zero |
| Density | 1820 kg/m3 | 1.82 in um/ns/GPa units |
| Specific heat | 2355.592 J/(kg K) | 0.002355592 |
| Conductivity | 0.361 W/(m K) | 0.361e-6 |
| Arrhenius prefactors | 32103.943853583012, 11810.38092425548 ns^-1 | copied literally |
| Activation parameters | 24400,23500 cal/mol; R=1.987 | identical |
| Heat laws | explicit Q1/Q2 constants and slopes | copied literally, scaled by 1e-6 |
| Transition temperature | 1736.3 K | identical |
| Bulk modulus, Poisson ratio | 20.36 GPa, 0.24 | K0=20.36, mu=12.80709677419355 GPa |
| Timestep | 0.001 ns | 0.001 ns |

The reference SmoothCircleIC defaults to zero interface width, so the initial profile is sharp. FV samples the profile at cell centres. The new input uses a finite 2 ns end time; the original does not specify one.

This is not an exact 2D validation reproduction: curvature, transverse flow and heat loss are absent. The reference uses JWL and plasticity; this input retains the previous FV Mie-Gruneisen EOS, reaction-dependent elastic dev(B) stress, constant-cv caloric closure and open boundaries. Numerical Lax-Friedrichs diffusion remains active. Quantitative propagation speeds will not necessarily match the 2D reference, even with matching reaction data. See `doc/eulerian_fv_reaction_mechanics_1d.md` for constitutive limitations.

## Density gaps

Current fields require positive density: u=m/rho, Fxx=rhoF/rho and temperature divides by rho. A true vacuum cannot be inserted. A low-density filler with the same constant reference density, bulk modulus, shear law, chemistry and conductivity is not a physical void. A planar gap-closure calculation requires a phase-aware void/gas treatment, transport of material identity and constitutive history, and compatible initialization of density and deformation. A shock-driving boundary or left/right loading must also be specified; the present copy initializes a hotspot at rest.

A planar 1D gap can close under longitudinal motion but cannot represent radial collapse, jetting or multidimensional pore-hotspot formation.
