# 1D Eulerian shock and gas-filled planar gap

Run using the same conda/MPICH environment as the working hotspot cases:

```bash
./scripts/run_eulerian_fv_pore_1d.sh
```

Input: `inputs/eulerian_fv_pore_1d.i`. This is a new input and launcher; existing cases and C++ objects are unchanged. It uses FVLongitudinalFlux with an explicit two-ghost-layer input setting, ADLongitudinalGradients, ADComputeMieGruneisenPressure, and base MOOSE objects.

## Initial state and loading

Units are um, ns, GPa, K. The domain is 0 to 20 um with 800 cells (h=0.025 um), dt=0.001 ns, and end_time=2 ns. The gap occupies x=10 to 10.4 um. Solid density is 1.82 and initial gas density is 0.0182, a density ratio of 100. Temperature starts at 300 K, Fxx=1 in solid, and solid composition is (1,0,0). Gas has no solid reactants or shear stiffness.

Material at x<8 um initially moves right at 1 um/ns. Material to its right is initially stationary. The velocity discontinuity launches compression waves, including the right-moving wave that reaches the gap. This is initial impact loading, not a continuously driven piston boundary. Both end boundaries extrapolate the interior physical flux, as in the earlier FV prototype. There is no initially imposed hotspot.

Initial pressure is balanced at 0.005144612928 GPa. The gas has gamma=1.4 and uses the same cv=0.002355592 as the solid, so p=(gamma-1)*rho_gas*cv*T. This gas cv/density is a demonstration choice, not calibrated air. An ambient pressure offset makes the initially undeformed solid match the gas pressure.

## Phase treatment

The fields are total density rho, solid partial density rho_solid, momentum, total energy, solid volume fraction alpha, rho_solid*Fxx, and three solid-species partial densities. Gas partial density is rho-rho_solid. Alpha evolves with alpha_t+(alpha*u)_x=alpha*u_x, so Dalpha/Dt=0 in the continuum. Both phases share velocity and temperature.

Solid intrinsic density is rho_solid/alpha where solid is present. Pressure is a volume-weighted solid Mie-Gruneisen pressure plus ideal-gas partial pressure. The gas pressure contribution is (gamma-1)*rho_gas_partial*cv*T; the solid contribution is alpha*(p_solid+p_ambient). The mixture is not a pressure-equilibrium two-fluid model. Mixed-cell pressure artifacts and numerical interface diffusion require assessment before quantitative use.

Deviatoric stress is alpha*mu*clamp(Y1,0,1)*dev(B), with Fyy=Fzz=1, Bxx=Fxx^2 and mu=12.80709677419355 GPa. There is no plasticity. Only solid species react. Reaction rates and heats match the Sakano FV case. The conductivity interpolates between 0.361e-6 in solid and 0.026e-6 in gas. Compression-only artificial viscosity and the existing Lax-Friedrichs face diffusion are active.

Specific heat is common and constant, so the existing temperature-gradient helper remains applicable. Temperature is recovered from internal energy/cv without separately removing elastic stored energy. The existing EOS's energy-density convention is handled as in the hotspot inputs. Small 1e-10 guards in phase recovery avoid division by absent solid; they do not allow zero TOTAL density.

## What this case represents

This is a diffuse-interface planar gas-gap closure demonstration, not a true-vacuum calculation or a validated sharp-interface pore-collapse solver. A 1D gap can close longitudinally but cannot produce lateral flow or pore jetting. Interface smearing may be substantial when the gap is underresolved. Do not interpret the width of an arbitrary alpha contour as a quantitative pore size without a refinement study.

Inspect rho, gap_fraction_out, pressure_out, u_out, temperature_out and solid_volume. The CSV gas_volume is the integral of (1-alpha); it is a better closure diagnostic than a single density threshold. Species_error_out measures rhoY1+rhoY2+rhoY3-rho_solid. Jrho_error_out monitors intrinsic solid density*Fxx/1.82-1 where alpha>0.1; this compatibility relation is not enforced exactly.

If changing the domain or gap/loading positions, update the FunctionIC expressions consistently. If changing resolution, update the explicit 0.025 um factors in artificial_pressure. The abs(u)+8 signal-speed estimate is inherited from the prototype and must be reassessed for stronger loading.

The full 800-cell input uses a serial LU preconditioner, as in the earlier 1D examples. For MPI, select an MPI-compatible preconditioner such as hypre; global ghost_layers=2 is already present.

## Verified results

The full 800-cell case completed 2000 steps to 2 ns with finite fields and positive total density and temperature. The integrated gas volume decreased from 0.400 to 0.343081 um: partial gap compression, not complete closure. A 200-cell comparison also completed to 2 ns and ended at 0.353127 um. These two results do not establish convergence. The 800-cell run took about 766 s on the single process used for this test; this is not a parallel performance benchmark.

A separate no-impact density-gap test remained in mechanical/thermal equilibrium through 0.1 ns, with gas volume 0.400 um and temperature 300 K. Saved-field ranges and species-conservation errors are in `logs/fv_pore_1d_validation.json`. The raw transported solid volume fraction can slightly overshoot one; constitutive evaluations clamp it to [0,1]. This is a numerical limitation of the current prototype.

Logs: `logs/fv_pore_1d.log`, `logs/fv_pore_1d_coarse.log`, and `logs/fv_pore_1d_equilibrium.log`.
