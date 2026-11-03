#include "FVReferenceHydroFlux.h"
#include "MooseMesh.h"
#include "MooseException.h"
#include "RankTwoTensor.h"
#include <cmath>

registerMooseObject("mlApp", FVReferenceHydroFlux);
InputParameters
FVReferenceHydroFlux::validParams()
{
  auto p=FVFluxKernel::validParams();
  p.addClassDescription("Reference-coordinate acoustic momentum/F flux with driven and slip walls.");
  for (const auto name : {"vx","vy","rho0","F00","F01","F10","F11"})
    p.addRequiredParam<MooseFunctorName>(name,"Cell field or functor");
  p.addParam<MooseFunctorName>("pressure","pressure","Thermodynamic pressure, positive in compression");
  p.addParam<MooseFunctorName>("artificial_pressure","artificial_pressure","Positive compressive viscosity");
  p.addParam<MooseFunctorName>("sound_speed","sound_speed","Acoustic speed");
  p.addRequiredParam<MooseEnum>("equation",MooseEnum("momentum deformation"),"Equation type");
  p.addRequiredRangeCheckedParam<unsigned int>("component","component<2","Velocity row");
  p.addRangeCheckedParam<unsigned int>("column",0,"column<2","F column for deformation equation");
  p.addParam<BoundaryName>("driven_boundary","bottom","Driven material surface");
  p.addParam<Real>("driven_velocity",1.2,"Y velocity on driven boundary in um/ns");
  p.set<unsigned short>("ghost_layers")=2;
  p.set<bool>("force_boundary_execution")=true;
  return p;
}
FVReferenceHydroFlux::FVReferenceHydroFlux(const InputParameters & p)
  : FVFluxKernel(p), _vx(getFunctor<ADReal>("vx")), _vy(getFunctor<ADReal>("vy")),
    _rho0(getFunctor<ADReal>("rho0")), _pressure(getFunctor<ADReal>("pressure")),
    _av(getFunctor<ADReal>("artificial_pressure")), _sound(getFunctor<ADReal>("sound_speed")),
    _F{{&getFunctor<ADReal>("F00"),&getFunctor<ADReal>("F01"),
        &getFunctor<ADReal>("F10"),&getFunctor<ADReal>("F11")}},
    _equation(getParam<MooseEnum>("equation")), _i(getParam<unsigned int>("component")),
    _j(getParam<unsigned int>("column")),
    _driven_boundary(_mesh.getBoundaryID(getParam<BoundaryName>("driven_boundary"))),
    _drive(getParam<Real>("driven_velocity"))
{}
ADReal
FVReferenceHydroFlux::computeQpResidual()
{
  const auto s=determineState();
  const auto left=elemArg();
  auto F_at = [&](const Moose::ElemArg & a) -> ADRankTwoTensor {
    ADRankTwoTensor F=ADRankTwoTensor::Identity();
    for (unsigned int i=0;i<2;++i)
      for (unsigned int j=0;j<2;++j) F(i,j)=(*_F[2*i+j])(a,s);
    return F;
  };
  const auto FL=F_at(left);
  const ADReal JL=FL.det();
  if (JL<=0) throw MooseException("Nonpositive J in reference FV flux.");
  ADRealVectorValue vL(_vx(left,s),_vy(left,s),0), vstar;
  const ADReal pL=_pressure(left,s)+_av(left,s);
  // Nanson's area vector is shared by all equations on this face.
  ADRealVectorValue area=JL*FL.inverse().transpose()*_normal;
  ADReal pstar;
  if (onBoundary(*_face_info))
  {
    ADRealVectorValue wall=vL;
    // Match FE normal constraints: vx=0 at left/right; vy=0 at top;
    // vy=drive at bottom. Tangential components have natural zero traction.
    if (std::abs(_normal(0))>.5) wall(0)=0;
    else wall(1)=_face_info->boundaryIDs().count(_driven_boundary) ? _drive : 0;
    const ADReal length=MetaPhysicL::sqrt(area*area);
    const auto n=area/length;
    const ADReal Z=_rho0(left,s)*_sound(left,s)/JL;
    vstar=wall;
    pstar=pL+Z*((vL-wall)*n);
  }
  else
  {
    const auto right=neighborArg();
    const auto FR=F_at(right);
    const ADReal JR=FR.det();
    if (JR<=0) throw MooseException("Nonpositive neighbor J in reference FV flux.");
    area=.5*(area+JR*FR.inverse().transpose()*_normal);
    const ADReal length=MetaPhysicL::sqrt(area*area);
    const auto n=area/length;
    const ADRealVectorValue vR(_vx(right,s),_vy(right,s),0);
    const ADReal pR=_pressure(right,s)+_av(right,s);
    const ADReal ZL=_rho0(left,s)*_sound(left,s)/JL;
    const ADReal ZR=_rho0(right,s)*_sound(right,s)/JR;
    const ADReal uL=vL*n, uR=vR*n;
    const ADReal un=(ZL*uL+ZR*uR+pL-pR)/(ZL+ZR);
    pstar=(ZR*pL+ZL*pR+ZL*ZR*(uL-uR))/(ZL+ZR);
    vstar=.5*(vL+vR);
    vstar+=(un-vstar*n)*n;
  }
  if (_equation=="momentum") return pstar*area(_i);
  return -vstar(_i)*_normal(_j);
}
