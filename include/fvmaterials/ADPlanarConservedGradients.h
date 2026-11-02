#pragma once
#include "FunctorMaterial.h"

/** Reconstruct in-plane velocity and thermal gradients from conserved FV fields. */
class ADPlanarConservedGradients : public FunctorMaterial
{
public:
  static InputParameters validParams();
  ADPlanarConservedGradients(const InputParameters & parameters);
protected:
  const Moose::Functor<ADReal> & _rho;
  const Moose::Functor<ADReal> & _mx;
  const Moose::Functor<ADReal> & _my;
  const Moose::Functor<ADReal> & _energy;
  const Real _cv;
};
