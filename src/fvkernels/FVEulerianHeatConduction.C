#include "FVEulerianHeatConduction.h"
registerMooseObject("mlApp",FVEulerianHeatConduction);
InputParameters
FVEulerianHeatConduction::validParams()
{
  auto p=FVFluxKernel::validParams();
  p.addClassDescription("Current-space isotropic conduction of cell thermal energy, insulated external faces.");
  p.addParam<MooseFunctorName>("temperature","temperature","Temperature from thermal energy");
  p.addParam<MooseFunctorName>("temperature_gradient","temperature_gradient","Cell temperature gradient");
  p.addRangeCheckedParam<Real>("conductivity",.361e-6,"conductivity>=0","Conductivity in um/ns/GPa/K units");
  p.set<unsigned short>("ghost_layers")=2;return p;
}
FVEulerianHeatConduction::FVEulerianHeatConduction(const InputParameters & p)
 : FVFluxKernel(p),_temperature(getFunctor<ADReal>("temperature")),
 _gradient(getFunctor<ADRealVectorValue>("temperature_gradient")),_k(getParam<Real>("conductivity")) {}
ADReal
FVEulerianHeatConduction::computeQpResidual()
{
  if(onBoundary(*_face_info)) return 0;
  const auto s=determineState();const auto l=elemArg(),r=neighborArg();
  const auto d=_face_info->neighborCentroid()-_face_info->elemCentroid();
  const Real dn=d*_normal;
  const auto g=.5*(_gradient(l,s)+_gradient(r,s));
  return -_k*((_temperature(r,s)-_temperature(l,s))/dn+g*(_normal-d/dn));
}
