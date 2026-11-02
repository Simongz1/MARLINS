# Reduced-diffusion pore transport

Run `./scripts/run_eulerian_fv_pore_1d_upwind.sh`. Input: `inputs/eulerian_fv_pore_1d_upwind.i`. All previous cases and flux classes are retained.

The old flux used local Lax-Friedrichs diffusion with a=abs(u)+8 for every conserved field, including density and solid volume fraction. At zero velocity a remained 8 um/ns. Its first-order diffusion scale a*h/2 was approximately 0.1 um^2/ns on the 800-cell grid, which smeared a density jump even in mechanical equilibrium. A higher-order reconstruction alone would not remove this diffusion at an initially sharp stationary discontinuity.

FVMaterialUpwindFlux instead computes a common acoustic interface velocity and traction from the two cell states, then upwinds material transport at that velocity. With impedances ZL, ZR and face orientation n, u_star=(ZL*uL+ZR*uR+n*(sigmaR-sigmaL))/(ZL+ZR), and sigma_star=(ZR*sigmaL+ZL*sigmaR+n*ZL*ZR*(uR-uL))/(ZL+ZR). For equal velocity and traction, density changes alone do not create an interface velocity or a diffusive mass flux. Mass, solid mass, volume fraction, deformation and species all advect at u_star. Momentum carries -sigma_star and energy carries -sigma_star*u_star plus averaged conductive flux. The impedance estimate uses the reference solid longitudinal modulus and gas bulk modulus contribution. This is a linearized acoustic interface solve, not a general nonlinear Riemann solution. The transported conserved field is reconstructed through MOOSE's limiter infrastructure. The acoustic interface states themselves use cell-centre values; this is not a uniformly second-order discretization of the entire coupled system. Default reconstruction is minmod; GlobalParams/reconstruction may be set to upwind or vanleer. Ghosting remains two layers, including gradients in neighbor-cell stress/heat fluxes.

The phase EOS, common velocity/temperature closure, chemistry, loading, viscosity coefficients and geometry are unchanged. The volume-fraction and rho_solid*F source terms use FVMaterialDilatationSource: the divergence is computed from the same acoustic face velocities as transport, so an initially pure solid does not acquire void fraction just because pressure changes the face velocity. The common interface solve is shared through MaterialAcousticState.h. This source currently targets the uniform Cartesian 1D mesh; it is not an AMR hanging-face implementation. Acoustic-speed numerical diffusion has been removed; compression-only artificial viscosity remains. At a stationary pressure-balanced contact the advective flux vanishes and the density/volume-fraction jump is preserved.

This flux is not HLLC. Partial-density fluxes use the same reconstructed total mass flux: solid face mass is bounded by total face mass, and the three reconstructed species are normalized to sum to that solid mass. This enforces the species/solid transport identity rather than limiting each conserved partial density independently. It does not constitute a general positivity proof for arbitrary nonlinear loadings. Strong-shock robustness and resolution dependence must be assessed separately. The common-phase and constant-cv limitations documented for the original pore case still apply.

Backward Euler remains first order in time. Limited spatial reconstruction reduces to first order at discontinuities and does not eliminate diffusion of moving contacts. Do not interpret this input as a WENO implementation.

The default input remains 800 cells and dt=0.001 ns. If changing resolution, update the explicit cell size in artificial_pressure. The original LLF input is available for comparison.

## Verification

The final implementation was rebuilt and tested:

- Stationary 200-cell gas/solid gap through 0.1 ns: saved rho and solid_volume are exactly unchanged; velocity remains zero. The original LLF equilibrium test changed rho by up to 0.955 and solid_volume by 0.530 over the same time.
- Coupled 200-cell shock/gap run through 0.8 ns (dt=0.005 ns, AV spacing adjusted to 0.1 um): all saved fields finite, total density/temperature positive, gas partial density nonnegative. Species/solid mass error stays below 3.9e-13. Volume fraction stays within [0,1] to approximately 3.2e-11, and solid density/deformation compatibility error stays below 1.6e-10. Maximum temperature is about 5077 K; this is an implementation result for the existing mixture/caloric model, not a validated pore temperature.
- Two-rank coupled test through 0.003 ns and a separate two-rank stationary-contact regression passed.
- Moving-contact scalar test at the same resolution/time discretization: L2 error decreased from 0.882383 with first-order upwind to 0.682824 with MinMod (approximately 23%). This demonstrates reduced transport error, not formal convergence order of the coupled system.
- The default 800-cell grid was advanced through 0.002 ns. The final full-resolution 2 ns run has not been performed.

Field ranges and invariants are recorded in `logs/fv_pore_upwind_validation.json`. Final shock log: `logs/fv_pore_upwind_shared_shock.log`. Stationary log: `logs/fv_pore_upwind_shared_stationary.log`. MPI log: `logs/fv_pore_upwind_shared_mpi.log`. Regression inputs and checks are under `test/tests/fvkernels/material_upwind/`.
