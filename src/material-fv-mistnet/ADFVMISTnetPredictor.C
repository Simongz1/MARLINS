#include "ADFVMISTnetPredictor.h"
#include "MISTnetXUtils.h"
#include "MicrostructureID.h"
#include "AuxiliarySystem.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <type_traits>

registerMooseObject("mlApp", ADFVMISTnetPredictor);

InputParameters
ADFVMISTnetPredictor::validParams()
{
  auto p = FunctorMaterial::validParams();
  p.addClassDescription("Cell-centered MISTnetX table predictor with accepted FV snapshot state.");
  p.addRequiredParam<MooseFunctorName>("velocity", "Physical material velocity vector");
  p.addRequiredParam<MooseFunctorName>("tracking", "Shock tracking scalar, usually a solved FV field");
  p.addRequiredParam<MooseFunctorName>("reference_density", "Reference density, not current rho");
  for (const auto & name : {"flag_state", "shock_temperature_state", "reaction_temperature_state",
                           "reaction_time_state", "called_up_state"})
    p.addRequiredParam<MooseFunctorName>(name, "FV auxiliary snapshot variable (read at old time state)");
  p.addParam<std::string>("microstructure_id_name", "microstructure_id", "Extra element integer label");
  p.addRequiredParam<unsigned int>("bulk_MicroID", "Bulk integer ID");
  p.addParam<unsigned int>("bulk_sensitivity", 20, "Bulk column in stripped binder tables");
  p.addRequiredParam<std::vector<unsigned int>>("range_pore", "Inclusive lower and upper pore IDs");
  p.addRequiredParam<Real>("thr_v", "Velocity threshold in simulation velocity units");
  p.addParam<Real>("tracking_threshold", 0.99, "Tracking threshold");
  p.addRequiredRangeCheckedParam<Real>("element_size", "element_size>0", "Tracking length in simulation units");
  p.addRangeCheckedParam<Real>("velocity_to_table", 1, "velocity_to_table>0",
                              "Multiply simulation velocity by this to get table velocity (um/ns)");
  p.addRangeCheckedParam<Real>("time_from_table", 1, "time_from_table>0",
                              "Multiply table time in ns by this to get simulation time");
  p.addRangeCheckedParam<Real>("tau_react_scaling", 1, "tau_react_scaling>0", "Reaction-window multiplier");
  p.addParam<Real>("minimum_up", 0, "Minimum lookup velocity in table units");
  p.addParam<Real>("maximum_up", 4.89, "Maximum lookup velocity in table units");
  p.addParam<bool>("use_tabular_time", false, "Use CSV times; otherwise use the FE deterministic time fit");
  p.addParam<std::vector<Real>>("us_up_coeffs", {-0.286, 1.640, 1.249391, 5.575975},
                               "Polynomial in table velocity units, descending degree; Us also um/ns");
  p.addParam<std::string>("output_prefix", "mist_", "Prefix on supplied functors");
  for (const auto & name : {"csv_shock", "csv_react", "csv_shock_pore", "csv_react_pore"})
    p.addRequiredParam<std::string>(name, "Numeric CSV with velocity in column zero");
  p.addParam<std::string>("csv_times", "", "Binder/bulk times CSV, required for tabular times");
  p.addParam<std::string>("csv_times_pore", "", "Pore times CSV, required for tabular times");
  return p;
}

ADFVMISTnetPredictor::ADFVMISTnetPredictor(const InputParameters & p)
  : FunctorMaterial(p),
    _velocity(getFunctor<ADRealVectorValue>("velocity")),
    _tracking(getFunctor<ADReal>("tracking")),
    _reference_density(getFunctor<ADReal>("reference_density")),
    _snapshot{{&getFunctor<ADReal>("flag_state"),
               &getFunctor<ADReal>("shock_temperature_state"),
               &getFunctor<ADReal>("reaction_temperature_state"),
               &getFunctor<ADReal>("reaction_time_state"),
               &getFunctor<ADReal>("called_up_state")}},
    _micro_id_index(_mesh.getMesh().get_elem_integer_index(getParam<std::string>("microstructure_id_name"))),
    _bulk_id(getParam<unsigned int>("bulk_MicroID")),
    _bulk_sensitivity(getParam<unsigned int>("bulk_sensitivity")),
    _pore_ids(getParam<std::vector<unsigned int>>("range_pore")),
    _pore_range(_pore_ids.empty() ? 0 : _pore_ids.front(), _pore_ids.empty() ? 0 : _pore_ids.back()),
    _threshold(getParam<Real>("thr_v")),
    _tracking_threshold(getParam<Real>("tracking_threshold")),
    _element_size(getParam<Real>("element_size")),
    _velocity_to_table(getParam<Real>("velocity_to_table")),
    _time_from_table(getParam<Real>("time_from_table")),
    _tau_scale(getParam<Real>("tau_react_scaling")),
    _minimum_up(getParam<Real>("minimum_up")),
    _maximum_up(getParam<Real>("maximum_up")),
    _tabular_time(getParam<bool>("use_tabular_time")),
    _coefficients(getParam<std::vector<Real>>("us_up_coeffs")),
    _prefix(getParam<std::string>("output_prefix"))
{

  // Functor old-state evaluation does not itself request solution storage.
  // Allocate the accepted auxiliary snapshot before threaded assembly begins.
  _fe_problem.getAuxiliarySystem().needSolutionState(1);
  //error checking 
  if (_pore_ids.size() != 2 || _pore_ids.front() > _pore_ids.back())
    paramError("range_pore", "Supply exactly two ordered inclusive bounds.");
  if (!(_minimum_up < _maximum_up))
    paramError("maximum_up", "Must exceed minimum_up.");
  if (_coefficients.empty())
    paramError("us_up_coeffs", "At least one coefficient is required.");
  loadTables("binder", getParam<std::string>("csv_shock"), getParam<std::string>("csv_react"),
             getParam<std::string>("csv_times"), _velocities, _shock, _react, _times);
  loadTables("pore", getParam<std::string>("csv_shock_pore"), getParam<std::string>("csv_react_pore"),
             getParam<std::string>("csv_times_pore"), _pore_velocities, _pore_shock, _pore_react, _pore_times);

  const std::array<std::string, N_FIELDS> names = {{"v_flag", "temperature_mister_shock",
      "temperature_mister_react", "time_react", "called_up"}};
  for (unsigned int i = 0; i < N_FIELDS; ++i)
    addFunctorProperty<ADReal>(_prefix + names[i],
      [this, i](const auto & arg, const auto & state) -> ADReal
      {
        if constexpr (std::is_same_v<std::decay_t<decltype(arg)>, Moose::ElemArg>)
          return prediction(arg, state)[i];
        else
          mooseError("MISTnetX predictions are cell-centered. Evaluate with ElemArg; ",
                     "transport/reconstruct snapshot fields separately for face fluxes.");
      });

  addFunctorProperty<ADReal>(_prefix + "us",
    [this](const auto & arg, const auto & state) -> ADReal
    {
      if constexpr (std::is_same_v<std::decay_t<decltype(arg)>, Moose::ElemArg>)
        return shockSpeed(arg, state);
      else
        mooseError("MISTnetX us requires a cell-centered ElemArg.");
    });
  addFunctorProperty<ADReal>(_prefix + "rate_tracking",
    [this](const auto & arg, const auto & state) -> ADReal
    {
      if constexpr (std::is_same_v<std::decay_t<decltype(arg)>, Moose::ElemArg>)
        return speed(arg, state) > _threshold ? shockSpeed(arg, state) / (3 * _element_size) : ADReal(0);
      else
        mooseError("MISTnetX tracking rate requires a cell-centered ElemArg.");
    });
  addFunctorProperty<ADReal>(_prefix + "density",
    [this](const auto & arg, const auto & state) -> ADReal
    {
      if constexpr (std::is_same_v<std::decay_t<decltype(arg)>, Moose::ElemArg>)
        return _reference_density(arg, state);
      else
        mooseError("MISTnetX reference density requires a cell-centered ElemArg.");
    });
}

void
ADFVMISTnetPredictor::loadTables(const std::string & phase, const std::string & shock,
                                 const std::string & react, const std::string & time,
                                 std::vector<Real> & velocities, Table & shock_values,
                                 Table & react_values, Table & time_values)
{
  const auto load = [&](const std::string & path, const bool first) -> Table
  {
    if (path.empty())
      mooseError("Missing MISTnetX ", phase, " CSV filename.");
    const auto raw = MISTnetXUtils::readCSV(path);
    if (raw.size() < 2)
      mooseError("MISTnetX CSV needs at least two velocity rows: ", path);
    std::vector<Real> axis;
    for (const auto & row : raw)
    {
      if (row.size() < 2 || row.size() != raw.front().size())
        mooseError("MISTnetX CSV must be rectangular and include velocity and data columns: ", path);
      for (const auto value : row)
        if (!std::isfinite(value))
          mooseError("Nonfinite value in MISTnetX CSV: ", path);
      if (!axis.empty() && row[0] <= axis.back())
        mooseError("MISTnetX velocities must be strictly increasing: ", path);
      axis.push_back(row[0]);
    }
    if (first)
      velocities = axis;
    else if (axis != velocities)
      mooseError("MISTnetX shock/reaction/time velocity axes must match within each phase: ", path);
    // computeInterval currently wraps to zero at the last row. Require the
    // configured lookup range to stop strictly before that endpoint.
    // The FE inputs deliberately extrapolate below the first binder row
    // (1.5 um/ns). Preserve that first-interval extrapolation here.
    if (_maximum_up >= axis.back())
      mooseError("MISTnetX maximum_up must be below the last table velocity: ", path);
    return MISTnetXUtils::formData(raw);
  };
  shock_values = load(shock, true);
  react_values = load(react, false);
  if (_tabular_time)
    time_values = load(time, false);
}

ADReal
ADFVMISTnetPredictor::speed(const Moose::ElemArg & cell, const Moose::StateArg & state) const
{
  const auto v = _velocity(cell, state);
  const ADReal squared = v * v;
  // Avoid a singular AD derivative of sqrt at exactly zero speed.
  return squared > 0 ? MetaPhysicL::sqrt(squared) : ADReal(0);
}

ADReal
ADFVMISTnetPredictor::shockSpeed(const Moose::ElemArg & cell, const Moose::StateArg & state) const
{
  const ADReal up = speed(cell, state) * _velocity_to_table;
  ADReal us = 0;
  for (const auto coefficient : _coefficients)
    us = us * up + coefficient;
  // Keep the FE behavior: Us uses instantaneous, unclamped velocity. Only
  // table lookup is clamped. Convert the table's Us back to simulation units.
  return us / _velocity_to_table;
}

ADFVMISTnetPredictor::Snapshot
ADFVMISTnetPredictor::prediction(const Moose::ElemArg & cell, const Moose::StateArg & state) const
{
  if (state.state != 0)
    mooseError("Use the snapshot FV variables directly for old-state MISTnetX queries.");
  // At INITIAL read IC values and do not activate. Thereafter read only the
  // previous accepted state, so FunctorAux commit order cannot change results.
  const auto history = _t_step == 0 ? Moose::currentState() : Moose::oldState();
  Snapshot out;
  for (unsigned int i = 0; i < N_FIELDS; ++i)
    out[i] = MetaPhysicL::raw_value((*_snapshot[i])(cell, history));
  if (_t_step == 0 || out[FLAG] != 0)
    return out;

  const Real velocity = MetaPhysicL::raw_value(speed(cell, state));
  if (velocity < _threshold || MetaPhysicL::raw_value(_tracking(cell, state)) < _tracking_threshold)
    return out;

  const auto micro_id = MicrostructureID::get(*cell.elem, _micro_id_index);
  if (micro_id > static_cast<dof_id_type>(std::numeric_limits<int>::max()))
    mooseError("Microstructure ID exceeds predictor index range on element ", cell.elem->id());
  const int id = static_cast<int>(micro_id);
  const std::string phase = micro_id >= _pore_ids.front() && micro_id <= _pore_ids.back()
                               ? "pore" : (micro_id == _bulk_id ? "bulk" : "binder");
  const Real up = std::clamp(velocity * _velocity_to_table, _minimum_up, _maximum_up);
  const auto temperatures = MISTnetXUtils::getTemperatures(
      up, id, phase, _velocities, _pore_velocities, _shock, _react, _pore_shock,
      _pore_react, _pore_range, cell.elem, _micro_id_index, _bulk_sensitivity);

  Real tau;
  if (_tabular_time)
    tau = _time_from_table * MISTnetXUtils::getTimes(
        up, id, phase, _velocities, _pore_velocities, _times, _pore_times,
        _pore_range, cell.elem, _micro_id_index, _bulk_sensitivity);
  else
  {
    tau = _time_from_table * (temperatures.second > 1000
                ? 8.046150413374 * std::exp(-0.963962928923 * up)
                : 0.000082188048 * std::exp(3.430175735695 * up));
    // Preserve FE ordering: bound the unscaled time, then multiply tau_scale.
    tau = std::max(_dt, std::min(2 * _time_from_table, tau));
  }
  tau *= _tau_scale;
  if (!(tau > 0) || !std::isfinite(tau))
    mooseError("Invalid MISTnetX reaction duration on element ", cell.elem->id());

  return {{1, temperatures.first, temperatures.second, tau, velocity}};
}
