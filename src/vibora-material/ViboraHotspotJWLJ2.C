#include "ViboraHotspotJWLJ2.h"
#include "MooseException.h"
#include <algorithm>
#include <cmath>

registerMooseObject("mlApp", ViboraHotspotJWLJ2);

InputParameters
ViboraHotspotJWLJ2::validParams()
{
  auto p = ComputeLagrangianStressPK1::validParams();
  p.addClassDescription("Stateful isochoric neo-Hookean J2 radial return with mixed JWL pressure.");
  p.addRequiredCoupledVar("temperature", "Temperature in K");
  p.addRequiredCoupledVar("reactant", "Reactant mass fraction Y1");
  p.addParam<MaterialPropertyName>("reference_density", "rho0", "Reference density");
  p.addParam<MaterialPropertyName>("specific_heat", "specific_heat", "Specific heat");
  p.addParam<MaterialPropertyName>("shear_modulus", "shear", "Shear modulus");
  p.addParam<std::vector<Real>>("unreacted_jwl", {13398.42268091, 3810.3712782, 68.1217746, 6.81217746, 0.37}, "A B R1 R2 omega");
  p.addParam<std::vector<Real>>("reacted_jwl", {1000, 2738.01645291, 59.99058313, 5.999058313, 0.77}, "A B R1 R2 omega");
  p.addParam<Real>("yield_A", 0.3, "Yield intercept in GPa");
  p.addParam<Real>("yield_B", 0.3, "Hardening coefficient in GPa");
  p.addParam<Real>("melting_temperature", 550, "Temperature denominator endpoint, K");
  p.addParam<Real>("temperature_exponent", 3, "Literal temperature-factor exponent");
  p.addParam<Real>("hardening_exponent", 2, "Plastic-strain exponent");
  p.addRangeCheckedParam<Real>("reference_rate", 1000, "reference_rate>0", "Reference plastic rate in ns^-1");
  p.addRangeCheckedParam<Real>("difference_step", 1e-6, "difference_step>0", "Relative centered-difference tangent step");
  return p;
}

ViboraHotspotJWLJ2::ViboraHotspotJWLJ2(const InputParameters & p)
  : ComputeLagrangianStressPK1(p),
    _temperature(coupledValue("temperature")),
    _reactant(coupledValue("reactant")),
    _rho0(getMaterialProperty<Real>("reference_density")),
    _cv(getMaterialProperty<Real>("specific_heat")),
    _G(getMaterialProperty<Real>("shear_modulus")),
    _unreacted(getParam<std::vector<Real>>("unreacted_jwl")),
    _reacted(getParam<std::vector<Real>>("reacted_jwl")),
    _A(getParam<Real>("yield_A")), _B(getParam<Real>("yield_B")),
    _Tm(getParam<Real>("melting_temperature")),
    _m(getParam<Real>("temperature_exponent")),
    _n(getParam<Real>("hardening_exponent")),
    _reference_rate(getParam<Real>("reference_rate")),
    _difference_step(getParam<Real>("difference_step")),
    _history_F(declareProperty<RankTwoTensor>("hotspot_history_F")),
    _history_F_old(getMaterialPropertyOld<RankTwoTensor>("hotspot_history_F")),
    _be(declareProperty<RankTwoTensor>("hotspot_elastic_b")),
    _be_old(getMaterialPropertyOld<RankTwoTensor>("hotspot_elastic_b")),
    _ep(declareProperty<Real>("equivalent_plastic_strain")),
    _ep_old(getMaterialPropertyOld<Real>("equivalent_plastic_strain")),
    _J(declareProperty<Real>("J")), _J_old(getMaterialPropertyOld<Real>("J")),
    _J_dot(declareProperty<Real>("J_dot")),
    _density(declareProperty<Real>("current_density")),
    _pressure(declareProperty<Real>("pressure"))
{
  if (_unreacted.size() != 5 || _reacted.size() != 5)
    mooseError("JWL parameter vectors must contain A B R1 R2 omega.");
  if (_Tm <= 300 || _A < 0 || _B < 0 || _n <= 0)
    mooseError("Invalid yield parameters.");
}

void
ViboraHotspotJWLJ2::initialSetup()
{
  ComputeLagrangianStressPK1::initialSetup();
  if (!_large_kinematics)
    mooseError("ViboraHotspotJWLJ2 requires large kinematics.");
}

void
ViboraHotspotJWLJ2::initQpStatefulProperties()
{
  ComputeLagrangianStressPK1::initQpStatefulProperties();
  _history_F[_qp] = RankTwoTensor::Identity();
  _be[_qp] = RankTwoTensor::Identity();
  _ep[_qp] = 0;
  _J[_qp] = 1;
  _J_dot[_qp] = 0;
  _density[_qp] = _rho0[_qp];
  _pressure[_qp] = 0;
}

Real
ViboraHotspotJWLJ2::yield(Real d) const
{
  const Real thermal = std::pow((_temperature[_qp]-300)/(_Tm-300), _m);
  const Real rate = _dt > 0 ? d/_dt : 0;
  const Real value = (_A + _B*std::pow(_ep_old[_qp]+d, _n)) *
                     (1+std::log1p(rate/_reference_rate))*thermal;
  // A negative literal yield stress has no admissible J2 stress state.
  // Fail explicitly instead of changing the supplied constitutive law.
  if (!std::isfinite(value) || value < 0)
    throw MooseException("Literal yield law produced a negative or nonfinite yield stress.");
  return value;
}

ViboraHotspotJWLJ2::Response
ViboraHotspotJWLJ2::response(const RankTwoTensor & F) const
{
  const Real J = F.det();
  if (!(J > 0) || !(_G[_qp] > 0))
    throw MooseException("Nonpositive deformation determinant or shear modulus.");
  const auto I = RankTwoTensor::Identity();
  auto f = F * _history_F_old[_qp].inverse();
  const Real jf = f.det();
  if (!(jf > 0))
    throw MooseException("Nonpositive incremental determinant.");
  f *= std::pow(jf, -1.0/3.0);
  const RankTwoTensor trial = f * _be_old[_qp] * f.transpose();
  const RankTwoTensor deviator = trial - I*(trial.trace()/3);
  const Real G = _G[_qp];
  const RankTwoTensor strial = G*deviator;
  const Real qtrial = std::sqrt(1.5*strial.doubleContraction(strial));
  Real d = 0;
  const Real y0 = yield(0);
  const Real modulus = G*trial.trace();
  if (_dt > 0 && qtrial > y0 && qtrial > 0)
  {
    Real lo = 0, hi = qtrial/modulus;
    // Monotone local consistency equation:
    // q_trial - G tr(be_trial) d - yield(ep_old+d,d/dt,T) = 0.
    for (unsigned int it=0; it<80; ++it)
    {
      const Real mid = (lo+hi)/2;
      const Real residual = qtrial-modulus*mid-yield(mid);
      if (residual > 0) lo=mid; else hi=mid;
    }
    d=(lo+hi)/2;
  }
  const Real factor = qtrial > 0 ? std::max(0.0, 1-modulus*d/qtrial) : 1;
  const RankTwoTensor devnew = factor*deviator;
  // Recover the spherical elastic part from det(be)=1. The lower
  // bound exceeds minus every eigenvalue by the Frobenius bound.
  // Locate the SPD branch by shifting a Gershgorin lower bound.
  Real lower = 0;
  for (unsigned int i=0; i<3; ++i)
  {
    Real bound = -devnew(i,i);
    for (unsigned int j=0; j<3; ++j)
      if (i != j) bound += std::abs(devnew(i,j));
    lower = std::max(lower, bound);
  }
  // The determinant-one root can lie below this conservative bound.
  // Obtain the exact SPD boundary through symmetric eigenvalues.
  std::vector<Real> eigenvalues;
  devnew.symmetricEigenvalues(eigenvalues);
  lower = -eigenvalues.front();
  Real upper = std::max(1.0, lower+1.0);
  while ((devnew+I*upper).det() < 1) upper *= 2;
  for (unsigned int it=0; it<80; ++it)
  {
    const Real mid=(lower+upper)/2;
    if ((devnew+I*mid).det() < 1) lower=mid; else upper=mid;
  }
  Response r;
  r.be = devnew + I*((lower+upper)/2);
  r.ep = _ep_old[_qp]+d;
  const auto eos = [&](const std::vector<Real> & a)
  {
    return a[0]*std::exp(-a[2]*J)+a[1]*std::exp(-a[3]*J)+
           a[4]*_rho0[_qp]*_cv[_qp]*(_temperature[_qp]-300)/J;
  };
  r.pressure = _reactant[_qp]*eos(_unreacted)+(1-_reactant[_qp])*eos(_reacted);
  const RankTwoTensor sigma = G*(r.be-I*(r.be.trace()/3))-I*r.pressure;
  r.P = J*sigma*F.inverse().transpose();
  return r;
}

void
ViboraHotspotJWLJ2::computeQpPK1Stress()
{
  const RankTwoTensor F = _F[_qp];
  const auto result = response(F);
  _history_F[_qp] = F;
  _be[_qp] = result.be;
  _ep[_qp] = result.ep;
  _J[_qp] = F.det();
  _J_dot[_qp] = _dt > 0 ? (_J[_qp]-_J_old[_qp])/_dt : 0;
  _density[_qp] = _rho0[_qp]/_J[_qp];
  _pressure[_qp] = result.pressure;
  _pk1_stress[_qp] = result.P;
  RankFourTensor tangent;
  tangent.zero();
  for (unsigned int k=0; k<3; ++k)
    for (unsigned int l=0; l<3; ++l)
    {
      const Real h=_difference_step*std::max(1.0,std::abs(F(k,l)));
      auto plus=F, minus=F;
      plus(k,l)+=h;
      minus(k,l)-=h;
      const RankTwoTensor derivative=(response(plus).P-response(minus).P)/(2*h);
      for (unsigned int i=0; i<3; ++i)
        for (unsigned int j=0; j<3; ++j)
          tangent(i,j,k,l)=derivative(i,j);
    }
  _pk1_jacobian[_qp] = tangent*_d_F_stab_d_F_ust[_qp];
  _pk1_jacobian_bypass_fbar[_qp] = tangent;
}
