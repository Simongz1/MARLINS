#include "ADBarImpedanceBC.h"
#include "Function.h"
#include "MooseVariable.h"

registerMooseObject("mlApp", ADBarImpedanceBC);

InputParameters
ADBarImpedanceBC::validParams()
{
  InputParameters params = ADIntegratedBC::validParams();

  params.addClassDescription(
      "Axial bar impedance traction: t = driving_traction - impedance * v, "
      "with velocity reconstructed using Newmark integration.");

  params.addRequiredCoupledVar(
      "velocity", "Velocity auxiliary variable corresponding to this displacement");

  params.addRequiredCoupledVar(
      "acceleration", "Acceleration auxiliary variable corresponding to this displacement");

  params.addRequiredRangeCheckedParam<Real>(
      "impedance", "impedance > 0", "Bar impedance rho_bar * c_bar");

  params.addRequiredRangeCheckedParam<Real>(
      "beta", "beta > 0", "Newmark beta, matching the inertia kernel");

  params.addRequiredRangeCheckedParam<Real>(
      "gamma", "gamma > 0", "Newmark gamma, matching the inertia kernel");

  params.addParam<FunctionName>(
      "driving_traction", "0",
      "Signed axial driving traction: 2*p_incident on the left, zero on the right");

  params.set<bool>("use_displaced_mesh") = true;

  return params;
}

ADBarImpedanceBC::ADBarImpedanceBC(const InputParameters & parameters)
  : ADIntegratedBC(parameters),
    _displacement_old(_var.slnOld()),
    _velocity_old(coupledValueOld("velocity")),
    _acceleration_old(coupledValueOld("acceleration")),
    _impedance(getParam<Real>("impedance")),
    _beta(getParam<Real>("beta")),
    _gamma(getParam<Real>("gamma")),
    _driving_traction(getFunction("driving_traction"))
{
}

ADReal
ADBarImpedanceBC::computeQpResidual()
{
    //reconstruct acceleration and velocity
    const ADReal acceleration =
        (_u[_qp] - _displacement_old[_qp]
        - _dt * _velocity_old[_qp])
            / (_beta * _dt * _dt)
        - (1.0 / (2.0 * _beta) - 1.0) * _acceleration_old[_qp];

    const ADReal velocity =
        _velocity_old[_qp]
        + _dt * ((1.0 - _gamma) * _acceleration_old[_qp]
                + _gamma * acceleration);

    //get driving traction

    const Real driving =
        _driving_traction.value(_t, _q_point[_qp]);

    return _test[_i][_qp] * (_impedance * velocity - driving);
}