# Integration fragment, NOT a standalone simulation.
# Copy draft sources into include/ and src/ only after reviewing README.md.
# Requires existing velocity vector functor, tracking FV field, integer mesh
# labels, and real CSV paths. Temperatures in K; example units nm, ns, GPa.

[AuxVariables]
  [mist_flag_state]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [mist_shock_T_state]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 300
  []
  [mist_react_T_state]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 300
  []
  [mist_tau_state]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
  [mist_up_state]
    type = MooseVariableFVReal
    two_term_boundary_expansion = false
    initial_condition = 0
  []
[]

[FunctorMaterials]
  [mist_predictor]
    type = ADFVMISTnetPredictor
    velocity = velocity
    tracking = tracking
    reference_density = 1.82e-6

    flag_state = mist_flag_state
    shock_temperature_state = mist_shock_T_state
    reaction_temperature_state = mist_react_T_state
    reaction_time_state = mist_tau_state
    called_up_state = mist_up_state

    # Use legacy_prediction_id with PolycrystalDensityIntegerLegacyUO
    # to reproduce the FE predictor's legacy rounded lookup.
    microstructure_id_name = legacy_prediction_id
    bulk_MicroID = 99
    bulk_sensitivity = 20
    range_pore = '101 103'

    # EXAMPLE threshold: replace with the FE case's thr_v, converted to nm/ns.
    thr_v = 50
    tracking_threshold = 0.99
    element_size = 20
    velocity_to_table = 0.001
    time_from_table = 1
    minimum_up = 0
    maximum_up = 4.89
    us_up_coeffs = '-0.286 1.640 1.249391 5.575975'
    tau_react_scaling = 1
    use_tabular_time = true

    # Replace all six paths with the exact files from your FE input.
    csv_shock = REPLACE_binder_shock.csv
    csv_react = REPLACE_binder_react.csv
    csv_times = REPLACE_binder_times.csv
    csv_shock_pore = REPLACE_pore_shock.csv
    csv_react_pore = REPLACE_pore_react.csv
    csv_times_pore = REPLACE_pore_times.csv
  []
[]

[AuxKernels]
  [commit_mist_flag]
    type = FunctorAux
    variable = mist_flag_state
    functor = mist_v_flag
    execute_on = TIMESTEP_END
  []
  [commit_mist_shock_T]
    type = FunctorAux
    variable = mist_shock_T_state
    functor = mist_temperature_mister_shock
    execute_on = TIMESTEP_END
  []
  [commit_mist_react_T]
    type = FunctorAux
    variable = mist_react_T_state
    functor = mist_temperature_mister_react
    execute_on = TIMESTEP_END
  []
  [commit_mist_tau]
    type = FunctorAux
    variable = mist_tau_state
    functor = mist_time_react
    execute_on = TIMESTEP_END
  []
  [commit_mist_up]
    type = FunctorAux
    variable = mist_up_state
    functor = mist_called_up
    execute_on = TIMESTEP_END
  []
[]

# Source consumers may read the CURRENT cell functors during assembly:
#   mist_v_flag, mist_temperature_mister_shock, mist_temperature_mister_react,
#   mist_time_react, mist_called_up, mist_us, mist_rate_tracking, mist_density.
# Do not use snapshot aux variables as current source values: before commit
# they contain the last accepted state and would delay activation by a step.
# This fragment does not add heat sources, species surrogates, timers,
# a tracking equation, transport of histories/IDs, or J2 mechanics.
