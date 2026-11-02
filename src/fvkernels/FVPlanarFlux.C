#include "FVPlanarFlux.h"
registerMooseObject("mlApp", FVPlanarFlux);
InputParameters
FVPlanarFlux::validParams()
{
  auto params = FVFluxKernel::validParams();
  params.addRequiredParam<MooseFunctorName>("flux_x", "Physical flux in the x direction");
  params.addRequiredParam<MooseFunctorName>("flux_y", "Physical flux in the y direction");
  params.addRequiredParam<MooseFunctorName>("wave_speed", "Positive signal speed bound in every face-normal direction");
  params.addParam<Real>("dissipation", 1, "Multiplier for local Lax-Friedrichs diffusion");
  // Face fluxes evaluate cell gradients on both sides: the neighbor gradient
  // needs its own face neighbors, including across MPI partition boundaries.
  params.set<unsigned short>("ghost_layers") = 2;
  params.set<bool>("force_boundary_execution") = true;
  return params;
}
FVPlanarFlux::FVPlanarFlux(const InputParameters & p)
  : FVFluxKernel(p), _flux_x(getFunctor<ADReal>("flux_x")), _flux_y(getFunctor<ADReal>("flux_y")),
    _speed(getFunctor<ADReal>("wave_speed")), _dissipation(getParam<Real>("dissipation")) {}
ADReal
FVPlanarFlux::computeQpResidual()
{
  const auto state = determineState();
  const auto left = elemArg();
  // Zero-gradient open boundaries: use the interior physical flux.
  if (onBoundary(*_face_info))
    return (_normal(0) * _flux_x(left, state) + _normal(1) * _flux_y(left, state));
  const auto right = neighborArg();
  const ADReal speed = std::max(_speed(left, state), _speed(right, state));
  return 0.5 * (_normal(0) * (_flux_x(left, state) + _flux_x(right, state))
              + _normal(1) * (_flux_y(left, state) + _flux_y(right, state)))
       - 0.5 * _dissipation * speed * (_var(right, state) - _var(left, state));
}
