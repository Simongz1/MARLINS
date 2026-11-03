#include "FVReferenceHeatConduction.h"
#include "MooseException.h"
#include "RankTwoTensor.h"
registerMooseObject("mlApp",FVReferenceHeatConduction);
InputParameters
FVReferenceHeatConduction::validParams()
{
  auto p = FVFluxKernel::validParams();
  p.addClassDescription("Reference pullback of displaced FE normalized conduction, with insulated boundaries.");

  for (const auto name : {"rho0","F00","F01","F10","F11"}){
    p.addRequiredParam<MooseFunctorName>(name,"Cell field or functor");
  }

  p.addRequiredRangeCheckedParam<Real>("cv", "cv>0", "Specific heat");
  p.addRequiredRangeCheckedParam<Real>("conductivity", "conductivity>=0", "Current-space isotropic conductivity");
  p.set<unsigned short>("ghost_layers") = 2;
  return p;
}
FVReferenceHeatConduction::FVReferenceHeatConduction(const InputParameters & p)
  : FVFluxKernel(p), _rho0(getFunctor<ADReal>("rho0")),
    _F{{&getFunctor<ADReal>("F00"),&getFunctor<ADReal>("F01"),
        &getFunctor<ADReal>("F10"),&getFunctor<ADReal>("F11")}},
    _cv(getParam<Real>("cv")), _conductivity(getParam<Real>("conductivity"))
{

}

ADReal
FVReferenceHeatConduction::computeQpResidual()
{
  if(onBoundary(*_face_info)) return 0;

  const auto s = determineState();
  const auto left = elemArg(), right = neighborArg();

  auto tensor = [&](const Moose::ElemArg & r) -> ADRankTwoTensor {
    ADRankTwoTensor F = ADRankTwoTensor::Identity();

    //populate F
    for(unsigned int i = 0; i<2; ++i){
      for (unsigned int j = 0; j<2; ++j){
        F(i,j) = (*_F[2*i+j])(r,s);
      }
    }

    //compute Jacobian
    const ADReal J = F.det();

    const auto F_inv = F.inverse();
    return (J * _conductivity / (_rho0(r,s) * _cv)) * (F_inv * F_inv.transpose());
  };

  const auto K = 0.5 * (tensor(left) + tensor(right));
  auto grad = 0.5 * (_var.gradient(left,s) + _var.gradient(right,s));

  // Retain the two-point normal difference; reconstructed tangential gradients
  // supply the off-diagonal pullback terms on the Cartesian/AMR reference mesh.
  grad += (gradUDotNormal(s,false) - grad * _normal) * _normal;
  return - _normal * (K * grad);
}
