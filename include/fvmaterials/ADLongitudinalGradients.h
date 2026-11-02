#pragma once
#include "FunctorMaterial.h"
/** Reconstruct velocity and temperature gradients from conserved FV fields. */
class ADLongitudinalGradients : public FunctorMaterial
{
public:
  static InputParameters validParams();
  ADLongitudinalGradients(const InputParameters & parameters);
protected:
  const Moose::Functor<ADReal> & _rho;
  const Moose::Functor<ADReal> & _momentum;
  const Moose::Functor<ADReal> & _energy;
  const Real _cv;
};
