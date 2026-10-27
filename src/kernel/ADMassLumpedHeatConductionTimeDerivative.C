#include "ADMassLumpedHeatConductionTimeDerivative.h"

registerMooseObject("mlApp", ADMassLumpedHeatConductionTimeDerivative);

InputParameters
ADMassLumpedHeatConductionTimeDerivative::validParams()
{
  InputParameters params = ADTimeKernel::validParams();
  params.addClassDescription("mass lumped time derivative, scaled by rho * cv");
  params.addParam<MaterialPropertyName>("density_name", "density", "name of material property storing density");
  params.addParam<MaterialPropertyName>("specific_heat", "specific_heat", "name of material property storing specific heat");
  params.set<bool>("use_displaced_mesh") = true;
  return params;
}

ADMassLumpedHeatConductionTimeDerivative::ADMassLumpedHeatConductionTimeDerivative(
    const InputParameters & parameters)
  : ADTimeKernel(parameters),
    _density(getADMaterialProperty<Real>("density_name")),
    _specific_heat(getADMaterialProperty<Real>("specific_heat")),
    _u_dot_nodal(_var.adDofValuesDot())
{}

ADReal
ADMassLumpedHeatConductionTimeDerivative::computeQpResidual()
{
  return _test[_i][_qp] * _density[_qp] * _specific_heat[_qp] * _u_dot_nodal[_i];
}
