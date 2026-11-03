#pragma once

#include "AuxKernel.h"

/** Flag both sides of a cell-product jump once either adjacent reaction window has finished. */
class FVProductInterfaceAux : public AuxKernel
{
public:
  static InputParameters validParams();
  FVProductInterfaceAux(const InputParameters & parameters);

protected:
  Real computeValue() override;
  const Moose::Functor<Real> & _products;
  const Moose::Functor<Real> & _clock;
  const Moose::Functor<Real> & _duration;
  const Real _jump_threshold;
};
