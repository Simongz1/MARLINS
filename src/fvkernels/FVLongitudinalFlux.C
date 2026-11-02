#include "FVLongitudinalFlux.h"
registerMooseObject("mlApp", FVLongitudinalFlux);
InputParameters
FVLongitudinalFlux::validParams()
{
  auto params = FVFluxKernel::validParams();
  params.addRequiredParam<MooseFunctorName>("flux", "Physical flux in the x direction");
  params.addRequiredParam<MooseFunctorName>("wave_speed", "Positive longitudinal signal speed bound");
  params.addParam<Real>("dissipation", 1, "Multiplier for local Lax-Friedrichs diffusion");
  params.set<bool>("force_boundary_execution") = true;
  return params;
}
FVLongitudinalFlux::FVLongitudinalFlux(const InputParameters & p)
  : FVFluxKernel(p), _flux(getFunctor<ADReal>("flux")),
    _speed(getFunctor<ADReal>("wave_speed")), _dissipation(getParam<Real>("dissipation")) {}
ADReal
FVLongitudinalFlux::computeQpResidual()
{
  const auto state = determineState();
  const auto left = elemArg();
  // Zero-gradient open boundaries: use the interior physical flux.
  if (onBoundary(*_face_info))
    return _normal(0) * _flux(left, state);
  const auto right = neighborArg();
  const ADReal speed = std::max(_speed(left, state), _speed(right, state));
  return 0.5 * _normal(0) * (_flux(left, state) + _flux(right, state))
       - 0.5 * _dissipation * speed * (_var(right, state) - _var(left, state));
}
