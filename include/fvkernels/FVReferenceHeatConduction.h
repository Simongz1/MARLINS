#pragma once
#include "FVFluxKernel.h"
#include <array>

/** Pull back current-space isotropic conduction onto a fixed material-coordinate FV mesh. */
class FVReferenceHeatConduction : public FVFluxKernel
{
public:
  static InputParameters validParams();
  FVReferenceHeatConduction(const InputParameters &);
protected:
  ADReal computeQpResidual() override;
  const Moose::Functor<ADReal> & _rho0;
  std::array<const Moose::Functor<ADReal> *,4> _F;
  const Real _cv, _conductivity;
};
