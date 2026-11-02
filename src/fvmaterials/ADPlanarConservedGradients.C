#include "ADPlanarConservedGradients.h"
registerMooseObject("mlApp", ADPlanarConservedGradients);

InputParameters
ADPlanarConservedGradients::validParams()
{
  auto params = FunctorMaterial::validParams();
  params.addRequiredParam<MooseFunctorName>("rho", "Mass density");
  params.addRequiredParam<MooseFunctorName>("mx", "X momentum density");
  params.addRequiredParam<MooseFunctorName>("my", "Y momentum density");
  params.addRequiredParam<MooseFunctorName>("energy", "Total energy density");
  params.addRequiredParam<Real>("cv", "Constant specific heat");
  return params;
}

ADPlanarConservedGradients::ADPlanarConservedGradients(const InputParameters & p)
  : FunctorMaterial(p), _rho(getFunctor<ADReal>("rho")), _mx(getFunctor<ADReal>("mx")),
    _my(getFunctor<ADReal>("my")), _energy(getFunctor<ADReal>("energy")),
    _cv(getParam<Real>("cv"))
{
  for (unsigned int i = 0; i < 2; ++i)
    for (unsigned int j = 0; j < 2; ++j)
      addFunctorProperty<ADReal>("L" + std::to_string(i) + std::to_string(j),
        [this, i, j](const auto & r, const auto & s) -> ADReal {
          const auto & momentum = i == 0 ? _mx : _my;
          const ADReal rho = _rho(r,s), u = momentum(r,s)/rho;
          return (momentum.gradient(r,s)(j)-u*_rho.gradient(r,s)(j))/rho;
        });
  for (unsigned int j = 0; j < 2; ++j)
    addFunctorProperty<ADReal>("gradT" + std::to_string(j),
      [this, j](const auto & r, const auto & s) -> ADReal {
        const ADReal rho = _rho(r,s), u = _mx(r,s)/rho, v = _my(r,s)/rho;
        const ADReal drho = _rho.gradient(r,s)(j);
        const ADReal du = (_mx.gradient(r,s)(j)-u*drho)/rho;
        const ADReal dv = (_my.gradient(r,s)(j)-v*drho)/rho;
        return ((_energy.gradient(r,s)(j)-_energy(r,s)*drho/rho)/rho-u*du-v*dv)/_cv;
      });
}
