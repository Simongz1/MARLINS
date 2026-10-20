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
    params.addParam<std::string>("constitutive_model", "NH", "the constitutive equation for stress-temperature dependence");

    //add branch for log model
    params.addParam<bool>("log_model", false, "whether to use the log model for pressure");
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
    _thermal_expansion(getADMaterialPropertyByName<Real>(_thermal_expansion_name)),
    _bulk_modulus(getADMaterialPropertyByName<Real>(_bulk_modulus_name)),
    //
    _constitutive_model(getParam<std::string>("constitutive_model")),
    _elasticity_tensor(_constitutive_model != "NH" ? &getADMaterialProperty<RankFourTensor>("elasticity_tensor") : nullptr),
    _log_model(getParam<bool>("log_model")),

    //get elastic deformation gradient only if needed
    _Fe(_log_model ? &getADMaterialProperty<RankTwoTensor>("Fe") : nullptr)
{}

void
ADCompressionHeating::computeQpProperties()
{
    //NH branch
    if (_constitutive_model == "NH"){
        //compute material time derivative of deformation gradient
        const ADRankTwoTensor F_dot = (_F[_qp] - _F_old[_qp]) / _dt;

        //compute velocity gradient
        const ADRankTwoTensor L = F_dot * _F[_qp].inverse();

        //compute rate of deformation tensor
        const ADRankTwoTensor d = 0.5 * (L + L.transpose());

        //compute volumetric deformation rate
        const ADReal trd = d.trace();

        //branch for log model
        if (_log_model){
            const ADReal Je = (*_Fe)[_qp].det();
            _q_elastic[_qp] = -1.5 * _thermal_expansion[_qp] * _bulk_modulus[_qp] * _temperature[_qp] * (Je * Je + 1.0) / Je * trd;
        }else{
            //form elastic heating
            //classic branch
            _q_elastic[_qp] = - 3.0 * _thermal_expansion[_qp] * _bulk_modulus[_qp] * _temperature[_qp] * _Je[_qp] * trd;
        }
    }

    //SVK branch
    //keep same for now
    else{
        //keep same for now
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
}
