#pragma once
#include "FVElementalKernel.h"

/** Q*div(u_star) source using the same face velocities as material transport (1D). */
class FVMaterialDilatationSource : public FVElementalKernel
{
public:
  static InputParameters validParams();
  FVMaterialDilatationSource(const InputParameters & parameters);
protected:
  ADReal computeQpResidual() override;
  const Moose::Functor<ADReal> & _velocity;
  const Moose::Functor<ADReal> & _stress;
  const Moose::Functor<ADReal> & _impedance;
};
