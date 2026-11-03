#pragma once
#include "FunctorMaterial.h"
#include <array>

/** Plane-strain spherical JWL/binder response on a fixed material-coordinate FV mesh. */
class ADFVReferenceHydro : public FunctorMaterial
{
public:
  static InputParameters validParams();
  ADFVReferenceHydro(const InputParameters &);
protected:
  std::array<ADReal, 6> response(const Moose::ElemArg &, const Moose::StateArg &) const;
  const Moose::Functor<ADReal> & _vx;
  const Moose::Functor<ADReal> & _vy;
  const Moose::Functor<ADReal> & _temperature;
  const Moose::Functor<ADReal> & _reactant;
  const Moose::Functor<ADReal> & _fraction;
  const Moose::Functor<ADReal> & _rho0;
  std::array<const Moose::Functor<ADReal> *, 4> _F;
  const Real _cv, _k_rdx, _nu_rdx, _k_binder, _nu_binder, _c0, _c1;
  const std::vector<Real> _unreacted, _reacted;
};
