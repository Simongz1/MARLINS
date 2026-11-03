#pragma once
#include "FVFluxKernel.h"
#include <array>

/** Shared acoustic interface velocity/traction for reference momentum and F transport. */
class FVReferenceHydroFlux : public FVFluxKernel
{
public:
  static InputParameters validParams();
  FVReferenceHydroFlux(const InputParameters &);
protected:
  ADReal computeQpResidual() override;
  const Moose::Functor<ADReal> & _vx;
  const Moose::Functor<ADReal> & _vy;
  const Moose::Functor<ADReal> & _rho0;
  const Moose::Functor<ADReal> & _pressure;
  const Moose::Functor<ADReal> & _av;
  const Moose::Functor<ADReal> & _sound;
  std::array<const Moose::Functor<ADReal> *,4> _F;
  const MooseEnum _equation;
  const unsigned int _i, _j;
  const BoundaryID _driven_boundary;
  const Real _drive;
};
