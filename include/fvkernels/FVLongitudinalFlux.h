#pragma once
#include "FVFluxKernel.h"

/** Central physical flux plus optional local Lax-Friedrichs stabilization in 1D. */
class FVLongitudinalFlux : public FVFluxKernel
{
public:
  static InputParameters validParams();
  FVLongitudinalFlux(const InputParameters & parameters);
protected:
  ADReal computeQpResidual() override;
  const Moose::Functor<ADReal> & _flux;
  const Moose::Functor<ADReal> & _speed;
  const Real _dissipation;
};
