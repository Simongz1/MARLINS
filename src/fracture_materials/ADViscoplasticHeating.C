#include "ADViscoplasticHeating.h"

registerMooseObject("mlApp", ADViscoplasticHeating);

InputParameters
ADViscoplasticHeating::validParams()
{
    InputParameters params = Material::validParams();
    params.addClassDescription("computes viscoplastic heating due to plastic velocity gradient flow");
    params.addParam<Real>("beta_vp", 0.5, "value of the beta parameter controlling viscoplastic heating");
    return params;
}

ADViscoplasticHeating::ADViscoplasticHeating(const InputParameters & parameters)
    : Material(parameters),
    _beta_vp(getParam<Real>("beta_vp")),
    _ep_dot(getADMaterialProperty<Real>("ep_dot")),
    _stress(getADMaterialProperty<RankTwoTensor>("stress")),
    _flow_direction(getADMaterialProperty<RankTwoTensor>("flow_direction")),
    _vp_heating(declareADProperty<Real>("vp_heating"))
{}

void
ADViscoplasticHeating::computeQpProperties()
{
    //compute viscoplastic flow
    const ADReal flow = _beta_vp * _ep_dot[_qp] * _stress[_qp].doubleContraction(_flow_direction[_qp]);
    _vp_heating[_qp] = flow;
}