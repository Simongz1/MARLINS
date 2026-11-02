# Longitudinal Eulerian FV reaction/mechanics prototype

Run from the application directory after building:

```bash
./ml-opt -i inputs/eulerian_fv_reaction_mechanics_1d.i
```

This is a separate input. The original chemistry demonstration and all existing C++ objects are unchanged. Two new objects provide a shared numerical flux (`FVLongitudinalFlux`) and reconstructed velocity/temperature gradients (`ADLongitudinalGradients`).

## Equations and constitutive assumptions

All unknowns are cell-centered on a fixed 1D mesh. The conserved unknowns are density rho, momentum m=rho*u, total energy density H=rho*E, A=rho*Fxx, and Zi=rho*Yi. Transverse stretches remain one; off-diagonal deformation components remain zero.

- Mass: rho_t + (rho*u)_x = 0.
- Momentum: m_t + (m*u - sigma_xx)_x = 0.
- Total energy: H_t + [(H-sigma_xx)*u - k*T_x]_x = Q1*r1*Z1 + Q2*r2*Z2.
- Deformation: A_t + (A*u)_x = A*u_x.
- Species: Zi_t + (Zi*u)_x = (-r1*Z1, r1*Z1-r2*Z2, r2*Z2).

Fxx=A/rho, u=m/rho, and T=(H/rho-u*u/2)/cv. In exact longitudinal kinematics rho*Fxx=rho0. The output Jrho_error measures A/rho0-1; it is a diagnostic, not a constraint.

Stress is sigma_xx = sxx - p - q. With B=diag(Fxx^2,1,1), sxx=mu*clamp(Y1,0,1)*(2/3)*(Fxx^2-1). Thus this prototype follows the requested linear dependence on dev(B), with loss of deviatoric stiffness after full reaction. It uses mu=5.8 GPa as a demonstration coefficient, not a calibrated fit. There is no plastic return mapping.

The existing ADComputeMieGruneisenPressure supplies pressure, with illustrative K0=20 GPa, s=1.5, gamma=1.2, rho0=2.15. Its thermal implementation multiplies the supplied energy difference by gamma without density; the input therefore passes internal ENERGY DENSITY and rho*cv*300 despite the object's `sie` parameter names. The existing cold curve and its positive-only thermal-energy increment are preserved exactly; this is not an independent validation of that EOS implementation.

Compression-only artificial pressure is rho*[0.1*4*h*max(-u_x,0)+h^2*max(-u_x,0)^2], with h=0.1 um for the default uniform grid. The 4 um/ns scale is illustrative. Update h if nx or the domain changes. Its stress work enters the same total energy flux, so no additional q*u_x source is added.

The caloric closure is deliberately simple: internal energy is cv*T, without a separately subtracted elastic stored-energy contribution. Mechanical work, including reversible deviatoric work, consequently contributes to the recovered thermal energy. Reaction-driven stiffness loss has no separate stored-energy release model. This limitation matters before interpreting quantitative temperatures.

## Discretization and boundaries

Every conserved field uses the same central physical flux plus local Lax-Friedrichs diffusion. This is not HLLC. The signal-speed estimate is abs(u)+8 um/ns; 8 is a conservative demonstration scale near the initial state, not a guaranteed bound for arbitrary EOS states. It must be checked when changing loading or material parameters. Artificial pressure and numerical flux diffusion are both active. Velocity and temperature gradients use MOOSE's FV gradient reconstruction and the chain rule applied to conserved fields.

Both boundaries extrapolate the physical flux from the interior. They are open, approximate outflow boundaries, not reflecting walls, a piston, or nonreflecting characteristic boundaries. The hot parcel is placed away from the ends for this short run. There is no resolved pore interface or AMR.

The initial state has rho=2.15, u=0.5 um/ns, Fxx=1, Yi=(1,0,0), and the same hot parcel as the chemistry demonstration. Reaction rates, heats (including a2=416 kcal/mol), cv and conductivity match that demonstration. Units are um, ns, GPa, K. Backward Euler/Newton with a direct preconditioner is used; this input is not an explicit-solver performance benchmark.

## Checks

A homogeneous cold, translating equilibrium should retain density, momentum, Fxx and temperature. The hot-parcel run should produce nonzero pressure, velocity gradients, deformation and reaction, while maintaining finite positive density/temperature and species mass conservation. Check Jrho_error under refinement; transporting F independently of density does not enforce compatibility exactly.

## Verified runs

The 200-cell reacting case completed 200 steps to 0.2 ns using the conda moose environment. All saved fields were finite. Density ranged from 1.7145 to 2.4504, temperature from 300 to 4143 K, and Fxx from 0.87765 to 1.25560. Species-sum errors remained below 1.1e-14; the maximum absolute rho*Fxx compatibility error was about 0.00140 (0.14%). This compatibility drift requires a refinement study before quantitative use. A cold homogeneous translating equilibrium preserved density, momentum, Fxx and temperature through 0.01 ns.

The executable links against conda MPICH. Do not launch it using the system OpenMPI mpiexec. A serial launcher that activates the tested environment is available:

```bash
./scripts/run_eulerian_fv_mechanics.sh
```

Solver logs: logs/fv_mechanics_hot.log and logs/fv_mechanics_equilibrium.log. These tests establish serial execution and basic invariants, not validation of the constitutive model or parallel performance.
