# Eulerian FV reaction demonstration

Run from the application directory:

```bash
./ml-opt -i inputs/eulerian_fv_reaction_1d.i
```

This standalone input uses only base MOOSE objects. All four unknowns are cell-centered FV variables on a fixed 200-cell, 20 micrometer domain. Constant prescribed velocity is 0.5 micrometers/ns, density is 2.15 in um/ns/GPa units, and specific heat is 0.563*4184e-6. Fresh material enters at 300 K; a localized initially hot parcel reacts while moving right. Boundary inflow composition is (1,0,0).

The equations are dYi/dt + u*dYi/dx = omega_i, with omega=(-r1*Y1,r1*Y1-r2*Y2,r2*Y2). Constant density makes these equivalent to conservative species-density equations divided by density. Temperature satisfies dT/dt + u*dT/dx = alpha*d2T/dx2 + (Q1*r1*Y1+Q2*r2*Y2)/cv. Density cancels between volumetric heat generation and heat capacity; it is retained in alpha=k/(rho*cv).

Arrhenius parameters and temperature-dependent heats follow the current production input, including a2=416 kcal/mol (rather than the 412 discussed from the paper). Heat conversion uses MW=0.22226 kg/mol. Chemistry is active immediately, without surrogate gating. Units are um, ns, GPa, K. Backward Euler and first-order upwind advection are used; no species diffusion is added.

This is a constant-density thermal/chemistry demonstration, not a compressible reactive Euler or elastoplastic solver. It has no mass/momentum solve, HLLC flux, compression heating, pore interface, surrogate events, or AMR. Consequently its runtime is not a benchmark for resolved pore-collapse mechanics. No existing C++ objects or production inputs were modified.

CSV output contains species and temperature means/maxima. Exodus contains cell-resolved fields. The species sum should remain one to solver tolerance; initial chemistry and transport preserve this invariant with the shared prescribed velocity.
