#pragma once
#include "FVFluxKernel.h"

/** Shared acoustic mass flux for 2D Eulerian mass, momentum, and all rho-weighted fields. */
class FVEulerianHydroFlux : public FVFluxKernel
{
public:
  static InputParameters validParams();
  FVEulerianHydroFlux(const InputParameters &);
protected:
  ADReal computeQpResidual() override;
  const Moose::Functor<ADReal> & _rho;
  const Moose::Functor<ADReal> & _mx;
  const Moose::Functor<ADReal> & _my;
  const Moose::Functor<ADReal> & _pressure;
  const Moose::Functor<ADReal> & _av;
  const Moose::Functor<ADReal> & _sound;
  const Moose::Functor<ADReal> & _inlet_specific;
  const MooseEnum _equation;
  const unsigned int _component;
  const BoundaryID _inlet;
  const Real _inlet_density,_inlet_velocity;
  const Moose::FV::LimiterType _limiter;
  const MooseEnum _species_role;
  std::vector<const Moose::Functor<ADReal> *> _species;
  const Moose::Functor<ADReal> * _species_total;
};
