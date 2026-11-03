#pragma once
#include "FVFluxKernel.h"
/** Isotropic current-space heat flux in the conserved thermal-energy equation. */
class FVEulerianHeatConduction : public FVFluxKernel
{
public:
  static InputParameters validParams();
  FVEulerianHeatConduction(const InputParameters &);
protected:
  ADReal computeQpResidual() override;
  const Moose::Functor<ADReal> & _temperature;
  const Moose::Functor<ADRealVectorValue> & _gradient;
  const Real _k;
};
