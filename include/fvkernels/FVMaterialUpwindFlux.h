#pragma once
#include "FVFluxKernel.h"
#include "Limiter.h"

/** Material-speed upwinding with limited face reconstruction and an acoustic traction/velocity interface solve. */
class FVMaterialUpwindFlux : public FVFluxKernel
{
public:
  static InputParameters validParams();
  FVMaterialUpwindFlux(const InputParameters & parameters);
protected:
  ADReal computeQpResidual() override;
  const Moose::Functor<ADReal> & _velocity;
  const Moose::Functor<ADReal> & _stress;
  const Moose::Functor<ADReal> & _impedance;
  const Moose::Functor<ADReal> & _heat;
  const MooseEnum _equation;
  const MooseEnum _component;
  const Moose::Functor<ADReal> * _density;
  const Moose::Functor<ADReal> * _solid;
  std::vector<const Moose::Functor<ADReal> *> _species;
  const Moose::FV::LimiterType _limiter;
};
