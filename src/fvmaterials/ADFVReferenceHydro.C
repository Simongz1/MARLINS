#include "ADFVReferenceHydro.h"
#include "MooseException.h"
#include "RankTwoTensor.h"
#include <cmath>
#include <type_traits>

registerMooseObject("mlApp", ADFVReferenceHydro);
InputParameters
ADFVReferenceHydro::validParams()
{
  auto p = FunctorMaterial::validParams();
  p.addClassDescription("Reference-coordinate FV spherical PBX stress; no J2 update or plastic heat.");
  for (const auto name : {"vx", "vy", "temperature", "Y1", "fraction", "rho0", "F00", "F01", "F10", "F11"})
    p.addRequiredParam<MooseFunctorName>(name, "Cell field or functor");
  p.addParam<Real>("cv", 2355.592e-6, "Specific heat in um/ns/GPa units");
  p.addParam<Real>("RDX_bulk", 20, "RDX bulk modulus in GPa");
  p.addParam<Real>("RDX_poisson", .24, "RDX Poisson ratio used for the FE viscosity sound speed");
  p.addParam<Real>("binder_bulk", 3, "Binder bulk modulus in GPa");
  p.addParam<Real>("binder_poisson", .45, "Binder Poisson ratio for the FE viscosity sound speed");
  p.addParam<Real>("C0", .1, "Quadratic artificial viscosity coefficient");
  p.addParam<Real>("C1", 1, "Linear artificial viscosity coefficient");
  p.addParam<std::vector<Real>>("unreacted_jwl", {13398.42268091,3810.3712782,68.1217746,6.81217746,.37}, "A B R1 R2 omega");
  p.addParam<std::vector<Real>>("reacted_jwl", {1000,2738.01645291,59.99058313,5.999058313,.77}, "A B R1 R2 omega");
  return p;
}
ADFVReferenceHydro::ADFVReferenceHydro(const InputParameters & p)
  : FunctorMaterial(p), _vx(getFunctor<ADReal>("vx")), _vy(getFunctor<ADReal>("vy")),
    _temperature(getFunctor<ADReal>("temperature")), _reactant(getFunctor<ADReal>("Y1")),
    _fraction(getFunctor<ADReal>("fraction")), _rho0(getFunctor<ADReal>("rho0")),
    _F{{&getFunctor<ADReal>("F00"), &getFunctor<ADReal>("F01"),
        &getFunctor<ADReal>("F10"), &getFunctor<ADReal>("F11")}},
    _cv(getParam<Real>("cv")), _k_rdx(getParam<Real>("RDX_bulk")),
    _nu_rdx(getParam<Real>("RDX_poisson")), _k_binder(getParam<Real>("binder_bulk")),
    _nu_binder(getParam<Real>("binder_poisson")), _c0(getParam<Real>("C0")), _c1(getParam<Real>("C1")),
    _unreacted(getParam<std::vector<Real>>("unreacted_jwl")), _reacted(getParam<std::vector<Real>>("reacted_jwl"))
{
  if (_unreacted.size() != 5 || _reacted.size() != 5)
    mooseError("JWL vectors need A B R1 R2 omega.");
  const std::array<std::string, 6> names = {{"J", "pressure", "artificial_pressure", "sound_speed", "dilatation", "HS_elastic"}};
  for (unsigned int i=0; i<names.size(); ++i)
    addFunctorProperty<ADReal>(names[i], [this,i](const auto & r, const auto & s) -> ADReal {
      if constexpr (std::is_same_v<std::decay_t<decltype(r)>,Moose::ElemArg>)
        return response(r,s)[i];
      else
        mooseError("ADFVReferenceHydro properties require cell-centered ElemArg.");
    });
}
std::array<ADReal, 6>
ADFVReferenceHydro::response(const Moose::ElemArg & r, const Moose::StateArg & s) const
{
  ADRankTwoTensor F=ADRankTwoTensor::Identity();
  for (unsigned int i=0; i<2; ++i)
    for (unsigned int j=0; j<2; ++j) F(i,j)=(*_F[2*i+j])(r,s);
  const ADReal J=F.det(), rho0=_rho0(r,s);
  if (J <= 0 || rho0 <= 0)
    throw MooseException("Reference FV hydro requires positive J and reference density.");
  ADRankTwoTensor gradV; gradV.zero();
  const auto gx=_vx.gradient(r,s), gy=_vy.gradient(r,s);
  for (unsigned int j=0; j<2; ++j) { gradV(0,j)=gx(j); gradV(1,j)=gy(j); }
  const ADReal theta=(gradV*F.inverse()).trace();
  const ADReal phi=_fraction(r,s);
  const ADReal y=std::max(ADReal(0),std::min(phi,_reactant(r,s)));
  const auto eos = [&](const std::vector<Real> & a) -> ADReal {
    return a[0]*MetaPhysicL::exp(-a[2]*J)+a[1]*MetaPhysicL::exp(-a[3]*J)
           +a[4]*rho0*_cv*(_temperature(r,s)-300)/J
           -a[0]*std::exp(-a[2])-a[1]*std::exp(-a[3]);
  };
  const ADReal pressure=y*eos(_unreacted)+(phi-y)*eos(_reacted)
                        -(1-phi)*_k_binder*(J-1);
  const Real mu_r=3*_k_rdx*(1-2*_nu_rdx)/(2+2*_nu_rdx);
  const Real mu_b=3*_k_binder*(1-2*_nu_binder)/(2+2*_nu_binder);
  const ADReal bulk=phi*_k_rdx+(1-phi)*_k_binder;
  const ADReal mu=phi*mu_r+(1-phi)*mu_b;
  const ADReal c=MetaPhysicL::sqrt((bulk+4*mu/3)*J/rho0);
  // Current edge length corresponding to local reference hmin: follows AMR and
  // deformation, unlike the original constant element_size viscosity length.
  ADReal stretch=MetaPhysicL::sqrt(F(0,0)*F(0,0)+F(1,0)*F(1,0));
  stretch=std::min(stretch,MetaPhysicL::sqrt(F(0,1)*F(0,1)+F(1,1)*F(1,1)));
  const ADReal h=r.elem->hmin()*stretch;
  const ADReal compression=theta < 0 ? -theta : ADReal(0);
  const ADReal av=rho0*(_c0*h*h*compression*compression+_c1*c*h*compression);
  const ADReal omega=y*_unreacted[4]+(phi-y)*_reacted[4];
  const ADReal heat=-_temperature(r,s)*omega*(rho0/J)*_cv*theta;
  return {{J,pressure,av,c,theta,heat}};
}
