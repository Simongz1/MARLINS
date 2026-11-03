#pragma once
#include "FunctorMaterial.h"
#include <array>

/** Spherical PBX constitutive closure reconstructed from Eulerian conserved fields. */
class ADFVEulerianPBX : public FunctorMaterial
{
public:
  static InputParameters validParams();
  ADFVEulerianPBX(const InputParameters &);
protected:
  std::array<ADReal, 12> values(const Moose::ElemArg &, const Moose::StateArg &) const;
  ADRealVectorValue temperatureGradient(const Moose::ElemArg &, const Moose::StateArg &) const;
  const Moose::Functor<ADReal> & _rho;
  const Moose::Functor<ADReal> & _mx;
  const Moose::Functor<ADReal> & _my;
  const Moose::Functor<ADReal> & _energy;
  const Moose::Functor<ADReal> & _reference_volume;
  const Moose::Functor<ADReal> & _phimass;
  const Moose::Functor<ADReal> & _Y1mass;
  std::array<const Moose::Functor<ADReal> *,4> _Fmass;
  const Real _cv, _c0, _c1;
};
