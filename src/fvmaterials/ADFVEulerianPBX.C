#include "ADFVEulerianPBX.h"
#include "MooseException.h"
#include "RankTwoTensor.h"
#include <cmath>
#include <type_traits>

registerMooseObject("mlApp", ADFVEulerianPBX);
InputParameters
ADFVEulerianPBX::validParams()
{
  auto p = FunctorMaterial::validParams();
  p.addClassDescription("Spherical PBX/JWL response from advected mass, F and composition in um/ns/GPa.");
  for(const auto n:{"rho","mx","my","thermal_energy","rho_inv_rho0","rho_phi","rhoY1","rhoF00","rhoF01","rhoF10","rhoF11"})
    p.addRequiredParam<MooseFunctorName>(n,"Eulerian conserved field");
  p.addRangeCheckedParam<Real>("cv",2355.592e-6,"cv>0","Specific heat");
  p.addParam<Real>("C0",.1,"Quadratic viscosity coefficient");
  p.addParam<Real>("C1",1,"Linear viscosity coefficient");
  return p;
}

ADFVEulerianPBX::ADFVEulerianPBX(const InputParameters & p)
 : FunctorMaterial(p),_rho(getFunctor<ADReal>("rho")),_mx(getFunctor<ADReal>("mx")),
 _my(getFunctor<ADReal>("my")),_energy(getFunctor<ADReal>("thermal_energy")),
 _reference_volume(getFunctor<ADReal>("rho_inv_rho0")),_phimass(getFunctor<ADReal>("rho_phi")),
 _Y1mass(getFunctor<ADReal>("rhoY1")),
 _Fmass{{&getFunctor<ADReal>("rhoF00"),&getFunctor<ADReal>("rhoF01"),&getFunctor<ADReal>("rhoF10"),&getFunctor<ADReal>("rhoF11")}},
 _cv(getParam<Real>("cv")),_c0(getParam<Real>("C0")),_c1(getParam<Real>("C1"))
{
  const std::array<std::string,12> names={{"temperature","J","pressure","artificial_pressure","sound_speed","L00","L01","L10","L11","dilatation","compression_heat","Jrho_error"}};
  for(unsigned int i=0;i<names.size();++i)
    addFunctorProperty<ADReal>(names[i],[this,i](const auto & r,const auto & s)->ADReal {
      if constexpr(std::is_same_v<std::decay_t<decltype(r)>,Moose::ElemArg>) return values(r,s)[i];
      else mooseError("ADFVEulerianPBX requires cell-centered arguments.");
    });
  addFunctorProperty<ADRealVectorValue>("temperature_gradient",[this](const auto & r,const auto & s)->ADRealVectorValue {
    if constexpr(std::is_same_v<std::decay_t<decltype(r)>,Moose::ElemArg>) return temperatureGradient(r,s);
    else mooseError("ADFVEulerianPBX gradient requires a cell-centered argument.");
  });
  addFunctorProperty<ADReal>("speed",[this](const auto & r,const auto & s)->ADReal {
    if constexpr(std::is_same_v<std::decay_t<decltype(r)>,Moose::ElemArg>) {
      const ADReal rho=_rho(r,s),mx=_mx(r,s),my=_my(r,s);
      if(!(rho>0)) throw MooseException("Nonpositive density in Eulerian speed.");
      const ADReal square=(mx*mx+my*my)/(rho*rho);
      return square>0?MetaPhysicL::sqrt(square):ADReal(0);
    } else mooseError("Eulerian speed requires a cell-centered argument.");
  });
}
std::array<ADReal,12>
ADFVEulerianPBX::values(const Moose::ElemArg & r,const Moose::StateArg & s) const
{
  const ADReal rho=_rho(r,s);
  if(!(rho>0)) throw MooseException("Nonpositive Eulerian mass density.");
  const ADReal reference_volume=_reference_volume(r,s);
  if(!(reference_volume>0)) throw MooseException("Nonpositive transported reference specific volume.");
  const ADReal rho0=rho/reference_volume;
  ADRankTwoTensor F=ADRankTwoTensor::Identity();
  for(unsigned int i=0;i<2;++i) for(unsigned int j=0;j<2;++j) F(i,j)=(*_Fmass[2*i+j])(r,s)/rho;
  const ADReal J=F.det();
  if(!(J>0)) throw MooseException("Nonpositive Eulerian deformation determinant.");
  const ADReal T=_energy(r,s)/(rho*_cv);
  if(!(T>0)) throw MooseException("Nonpositive Eulerian temperature.");
  const ADReal phi=std::max(ADReal(0),std::min(ADReal(1),_phimass(r,s)/rho));
  const ADReal y=std::max(ADReal(0),std::min(phi,_Y1mass(r,s)/rho));
  const auto eos=[&](Real A,Real B,Real R1,Real R2,Real w)->ADReal {
    return A*MetaPhysicL::exp(-R1*J)+B*MetaPhysicL::exp(-R2*J)
      +w*rho0*_cv*(T-300)/J-A*std::exp(-R1)-B*std::exp(-R2);
  };
  const ADReal pressure=y*eos(13398.42268091,3810.3712782,68.1217746,6.81217746,.37)
    +(phi-y)*eos(1000,2738.01645291,59.99058313,5.999058313,.77)-(1-phi)*3*(J-1);
  const ADReal u=_mx(r,s)/rho,v=_my(r,s)/rho;
  const auto dr=_rho.gradient(r,s),dmx=_mx.gradient(r,s),dmy=_my.gradient(r,s);
  const ADReal L00=(dmx(0)-u*dr(0))/rho,L01=(dmx(1)-u*dr(1))/rho;
  const ADReal L10=(dmy(0)-v*dr(0))/rho,L11=(dmy(1)-v*dr(1))/rho;
  const ADReal theta=L00+L11;
  const Real mu_r=3*20*(1-2*.24)/(2+2*.24),mu_b=3*3*(1-2*.45)/(2+2*.45);
  const ADReal bulk=phi*20+(1-phi)*3,mu=phi*mu_r+(1-phi)*mu_b;
  // Use the FE elastic signal bound and the isothermal JWL tangent, whichever
  // is larger. The latter can exceed the nominal elastic modulus when hot.
  const ADReal K=y*(13398.42268091*68.1217746*J*MetaPhysicL::exp(-68.1217746*J)
      +3810.3712782*6.81217746*J*MetaPhysicL::exp(-6.81217746*J)+.37*rho0*_cv*(T-300)/J)
    +(phi-y)*(1000*59.99058313*J*MetaPhysicL::exp(-59.99058313*J)
      +2738.01645291*5.999058313*J*MetaPhysicL::exp(-5.999058313*J)+.77*rho0*_cv*(T-300)/J)
    +(1-phi)*3*J;
  const ADReal c=MetaPhysicL::sqrt((std::max(bulk,K)+4*mu/3)/rho);
  const ADReal compression=theta<0 ? -theta:ADReal(0);
  const Real h=r.elem->hmin(); // This mesh is spatial: h is already a current length.
  const ADReal av=rho*(_c0*h*h*compression*compression+_c1*c*h*compression);
  const ADReal omega=.37*y+.77*(phi-y);
  return {{T,J,pressure,av,c,L00,L01,L10,L11,theta,-omega*_energy(r,s)*theta,rho*J/rho0-1}};
}
ADRealVectorValue
ADFVEulerianPBX::temperatureGradient(const Moose::ElemArg & r,const Moose::StateArg & s) const
{
  const ADReal rho=_rho(r,s);
  if(!(rho>0)) throw MooseException("Nonpositive density in thermal gradient.");
  return (_energy.gradient(r,s)-(_energy(r,s)/rho)*_rho.gradient(r,s))/(rho*_cv);
}
