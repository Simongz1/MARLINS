#include "ADArtVisHeating.h"

registerMooseObject("mlApp", ADArtVisHeating);

InputParameters
ADArtVisHeating::validParams()
{
    InputParameters params = ADMaterial::validParams();
    params.addClassDescription("compute shock heating due to artificial viscosity");
    params.addParam<Real>("beta_av", 0.5, "fraction of viscous dissipation converted into heat");
    return params;
}

ADArtVisHeating::ADArtVisHeating(const InputParameters & parameters)
  : ADMaterial(parameters),
    _p_av(getADMaterialProperty<Real>("p_av")),
    _beta_av(getParam<Real>("beta_av")),
    _q_av(declareADProperty<Real>("q_av")),
    _J(getADMaterialProperty<Real>("J")),
    _J_old(getMaterialPropertyOld<Real>("J"))
{}

void
ADArtVisHeating::computeQpProperties()
{   
    //compute material time derivative of J
    const ADReal J_dot = (1.0 / _dt) * (_J[_qp] - _J_old[_qp]);

    //compute artificial viscosity heating
    _q_av[_qp] = _beta_av * _p_av[_qp] * J_dot / _J[_qp];
}
