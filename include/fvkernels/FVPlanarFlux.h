#pragma once
#include "FVFluxKernel.h"

/** Central physical flux plus optional local Lax-Friedrichs stabilization in 2D. */
class FVPlanarFlux : public FVFluxKernel
{
public:
  static InputParameters validParams();
  FVPlanarFlux(const InputParameters & parameters);
protected:
  ADReal computeQpResidual() override;
  const Moose::Functor<ADReal> & _flux_x;
  const Moose::Functor<ADReal> & _flux_y;
  const Moose::Functor<ADReal> & _speed;
  const Real _dissipation;
};
