# Two-dimensional Sakano hotspot with Eulerian FV mechanics

Run with the tested conda/MPICH environment:

```bash
./scripts/run_eulerian_fv_sakano_2d.sh
```

Input: `inputs/eulerian_fv_sakano_2d.i`. This is a genuinely 2D plane-strain calculation, not an extrusion or independent collection of 1D lines. All earlier inputs and objects are retained.

## Geometry and reference data

The reference is `/scratch/negishi/gonz1075/mist2/sakano_proof/sakano_T_Y_P_1um_lump.i`. The domain is 5 x 5 um with 250 x 250 QUAD4 cells (20 nm spacing). The initially sharp circular hotspot has radius 0.5 um and centre (2.5,2.5) um. Temperature is 1920 K inside and 300 K outside. Initial velocity is zero, density is 1.82, F is identity, and composition is (1,0,0).

The reference's Arrhenius prefactors, activation parameters, heat-law intercepts/slopes, transition temperature, density, specific heat and conductivity are copied with nm-to-um/energy unit conversions. The explicit heat constants from the reference are used rather than recalculating rounded kcal/mol values. K0=20.36 GPa and mu=12.80709677419355 GPa derive from its K=20.36 GPa and nu=0.24. Timestep is 0.001 ns; this copy specifies a 2 ns end time. FV samples the circular initial profile at cell centres.

## Two-dimensional equations

The 11 conserved unknowns are rho, mx, my, energy, rhoF00, rhoF01, rhoF10, rhoF11, rhoY1, rhoY2 and rhoY3. Plane strain fixes Fzz=1 and all out-of-plane off-diagonal components to zero. Both velocity components and both spatial derivatives are active.

- Mass: rho_t + div(rho*u) = 0.
- Momentum: (rho*u)_t + div(rho*u tensor u - sigma) = 0.
- Total energy: H_t + div(H*u - sigma*u - k*grad(T)) = chemical heat.
- Deformation: (rho*Fij)_t + div(rho*Fij*u) = sum_k Lik*rho*Fkj, with L=grad(u).
- Species: (rho*Yi)_t + div(rho*Yi*u) = rho*omega_i.

B=F*F^T is assembled with the in-plane off-diagonal terms and Bzz=1. The same model used in the 1D FV prototype is extended to 2D: s=mu*clamp(Y1,0,1)*dev(B), sigma=s-(p+q)I. The deviator uses the three-dimensional trace divided by three, including Bzz. Momentum fluxes include shear traction; the energy flux includes both normal and shear stress work. Outputs include all in-plane F components, both velocities, pressure, shear/normal deviatoric stress and von Mises stress.

Existing ADComputeMieGruneisenPressure supplies p. As in the 1D version, energy-density inputs compensate its thermal-energy convention. Compression-only artificial pressure uses -div(u), with h=0.02 um; change the explicit h factors if changing resolution. The signal-speed estimate abs(u)+abs(v)+8 is a demonstration bound, not a guaranteed EOS bound for arbitrary loadings.

FVPlanarFlux projects both physical flux components onto the face normal and applies the same local Lax-Friedrichs diffusion to each conserved field. ADPlanarConservedGradients reconstructs all four velocity-gradient components and both thermal gradients from conserved fields. Existing 1D classes are not modified.

## Preserved model limitations

This matches the reference's 2D geometry and thermal/chemical data while preserving the requested FV mechanics model. It does not replace Mie-Gruneisen/elasticity with the reference's JWL/plasticity. Internal energy is cv*T without a separately removed elastic stored-energy term. Fixed-grid boundaries use the previous FV model's open extrapolated fluxes, not an exact moving free surface. Consequently it is not an identical constitutive/boundary model to the FE reference.

The default solver uses Newton with hypre BoomerAMG rather than a serial direct factorization of the full 687,500-unknown system. No claim of FE-equivalent runtime or front-speed convergence is made. Refinement and solver performance still need measurement.

Monitor species_error=(rhoY1+rhoY2+rhoY3)/rho-1 and Jrho_error=rho*det(F)/1.82-1. The latter is not enforced as a discrete constraint and may drift.

## Verification performed

- Application rebuilt successfully with the matching conda environment.
- Full 250 x 250 input: `--check-input` passed.
- Reacting 24 x 24 test: ten steps to 0.01 ns passed, with all saved fields finite, positive density/temperature, and nonnegative species. X/y exchange symmetry error was below 1.2e-13 for temperature. Off-diagonal F reached approximately +/-0.001 and transverse velocity approximately +/-0.095 um/ns, confirming active 2D coupling. Species-sum errors were below 5e-16; absolute rho*det(F) compatibility errors were below 4.7e-7 over this short coarse test.
- Cold uniform 12 x 12 equilibrium: preserved through 0.003 ns.
- Default hypre solver: two steps on a 16 x 16 mesh passed.

These are implementation checks, not full-resolution front-speed validation. The full 250 x 250, 2 ns evolution has not been run. Coarse verification runs retained the reference AV spacing; they do not establish spatial convergence.

Logs: `logs/fv_sakano_2d_input_check.log`, `logs/fv_sakano_2d_hot.log`, `logs/fv_sakano_2d_equilibrium.log`, and `logs/fv_sakano_2d_hypre.log`. Field-check results: `logs/fv_sakano_2d_validation.json`.

## MPI ghosting correction

The first implementation requested only one ghost layer. Its face flux evaluates velocity/temperature gradients in the neighboring cell, which requires that neighbor's own neighbors. A two-rank run reproduced a first-timestep signal-11 crash. Changing only ghost_layers to 2 made that same run pass. FVPlanarFlux now defaults to two layers, and the production input also explicitly sets GlobalParams/ghost_layers=2. The executable was rebuilt.

A two-rank regression without the global override and a four-rank coupled hotspot test passed. Serial/four-rank final fields agree within 1e-7 (actual differences are recorded in logs/fv_sakano_2d_parallel_validation.json). A full 64-rank production evolution has not been run here. Older copies of the input can use the rebuilt executable or append GlobalParams/ghost_layers=2 to the launch command.
