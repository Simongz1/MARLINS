#pragma once

#include "FunctorMaterial.h"
#include <array>
#include <utility>
#include <vector>

/**
 * Draft FV translation of ADComputeIntPValRDXMISTERnetInteger.
 *
 * Pure cell-center prediction from current velocity/tracking and previous accepted
 * auxiliary state. Five FunctorAux objects commit the snapshot at TIMESTEP_END.
 * Deliberately has no mutable per-element map or side effects in functor callbacks.
 * This draft's snapshots/IDs are mesh attached, not material-advected histories.
 */
class ADFVMISTnetPredictor : public FunctorMaterial
{
public:
  static InputParameters validParams();
  ADFVMISTnetPredictor(const InputParameters & parameters);

protected:
  enum SnapshotField : unsigned int { FLAG, SHOCK_T, REACT_T, REACT_TIME, CALLED_UP, N_FIELDS };
  using Snapshot = std::array<Real, N_FIELDS>;
  using Table = std::vector<std::vector<Real>>;

  Snapshot prediction(const Moose::ElemArg & cell, const Moose::StateArg & state) const;
  ADReal speed(const Moose::ElemArg & cell, const Moose::StateArg & state) const;
  ADReal shockSpeed(const Moose::ElemArg & cell, const Moose::StateArg & state) const;
  void loadTables(const std::string & phase, const std::string & shock,
                  const std::string & react, const std::string & time,
                  std::vector<Real> & velocities, Table & shock_values,
                  Table & react_values, Table & time_values);

  const Moose::Functor<ADRealVectorValue> & _velocity;
  const Moose::Functor<ADReal> & _tracking;
  const Moose::Functor<ADReal> & _reference_density;
  const std::array<const Moose::Functor<ADReal> *, N_FIELDS> _snapshot;
  const unsigned int _micro_id_index;
  const unsigned int _bulk_id;
  const unsigned int _bulk_sensitivity;
  const std::vector<unsigned int> _pore_ids;
  const std::pair<Real, Real> _pore_range;
  const Real _threshold;
  const Real _tracking_threshold;
  const Real _element_size;
  const Real _velocity_to_table;
  const Real _time_from_table;
  const Real _tau_scale;
  const Real _minimum_up;
  const Real _maximum_up;
  const bool _tabular_time;
  const std::vector<Real> _coefficients;
  const std::string _prefix;

  std::vector<Real> _velocities;
  std::vector<Real> _pore_velocities;
  Table _shock, _react, _times;
  Table _pore_shock, _pore_react, _pore_times;
};
