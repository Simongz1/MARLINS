#include "ADCompressionHeating.h"

registerMooseObject("mlApp", ADCompressionHeating);

InputParameters
ADCompressionHeating::validParams()
{
    InputParameters params = ADMaterial::validParams();
    params.addClassDescription("compute thermodynamic compression heating");
    params.addCoupledVar("temperature", "temperature");
    params.addParam<MaterialPropertyName>("thermal_expansion_name", "alpha", "name of the thermal expansion coefficient");
    params.addParam<MaterialPropertyName>("bulk_modulus_name", "bulk_modulus", "name of the bulk modulus");
    return params;
}

ADCompressionHeating::ADCompressionHeating(const InputParameters & parameters)
  : ADMaterial(parameters),
    _temperature(adCoupledValue("temperature")),
    _F(getADMaterialProperty<RankTwoTensor>("F")),
    _F_old(getMaterialPropertyOld<RankTwoTensor>("F")),
    _Je(getADMaterialProperty<Real>("Je")),
    _q_elastic(declareADProperty<Real>("q_elastic")),
    //
    _thermal_expansion_name(getParam<MaterialPropertyName>("thermal_expansion_name")),
    _bulk_modulus_name(getParam<MaterialPropertyName>("bulk_modulus_name")),
    _thermal_expansion(declareADProperty<Real>(_thermal_expansion_name)),
    _bulk_modulus(declareADProperty<Real>(_bulk_modulus_name))
{}

void
ADCompressionHeating::computeQpProperties()
{
    //compute material time derivative of deformation gradient
    const ADRankTwoTensor F_dot = (_F[_qp] - _F_old[_qp]) / _dt;

    //compute velocity gradient
    const ADRankTwoTensor L = F_dot * _F[_qp].inverse();

    //compute rate of deformation tensor
    const ADRankTwoTensor d = 0.5 * (L + L.transpose());

    //compute volumetric deformation rate
    const ADReal trd = d.trace();

    //form elastic heating
    _q_elastic[_qp] = - 3.0 * _thermal_expansion[_qp] * _bulk_modulus[_qp] * _temperature[_qp] * _Je[_qp] * trd;
}
