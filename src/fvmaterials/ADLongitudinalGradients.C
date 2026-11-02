#include "ADLongitudinalGradients.h"
registerMooseObject("mlApp", ADLongitudinalGradients);
InputParameters
ADLongitudinalGradients::validParams()
{
  auto params = FunctorMaterial::validParams();
  params.addRequiredParam<MooseFunctorName>("rho", "Mass density");
  params.addRequiredParam<MooseFunctorName>("momentum", "Longitudinal momentum density");
  params.addRequiredParam<MooseFunctorName>("energy", "Total energy density");
  params.addRequiredParam<Real>("cv", "Constant specific heat");
  return params;
}
ADLongitudinalGradients::ADLongitudinalGradients(const InputParameters & p)
  : FunctorMaterial(p), _rho(getFunctor<ADReal>("rho")),
    _momentum(getFunctor<ADReal>("momentum")), _energy(getFunctor<ADReal>("energy")),
    _cv(getParam<Real>("cv"))
{
  addFunctorProperty<ADReal>("velocity_gradient", [this](const auto & r, const auto & s) -> ADReal {
    const ADReal rho = _rho(r,s), u = _momentum(r,s)/rho;
    return (_momentum.gradient(r,s)(0)-u*_rho.gradient(r,s)(0))/rho;
  });
  addFunctorProperty<ADReal>("temperature_gradient", [this](const auto & r, const auto & s) -> ADReal {
    const ADReal rho = _rho(r,s), u = _momentum(r,s)/rho;
    const ADReal du = (_momentum.gradient(r,s)(0)-u*_rho.gradient(r,s)(0))/rho;
    return ((_energy.gradient(r,s)(0)-_energy(r,s)*_rho.gradient(r,s)(0)/rho)/rho-u*du)/_cv;
  });
}
