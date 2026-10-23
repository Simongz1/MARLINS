#include "ComputeLagrangianThermoCompressibleNeoHookeanStress.h"
#include "MooseException.h"

#include <cmath>

registerMooseObject("mlApp", ComputeLagrangianThermoCompressibleNeoHookeanStress);

InputParameters
ComputeLagrangianThermoCompressibleNeoHookeanStress::validParams()
{
  InputParameters params = ComputeLagrangianStressPK1::validParams();
  params.addClassDescription(
      "Thermoelastic compressible neo-Hookean material with multiplicative thermal split "
      "F = F^e (theta I): W = K/2 (J^e-1)^2 + G/2 (tr b^e - 3) or the isochoric deviatoric form "
      "G/2 ((J^e)^{-2/3} tr b^e - 3). Provides the PK1 stress, its tangent dP/dF and the "
      "stateful total Jacobian J and its rate J_dot.");
  params.addParam<MaterialPropertyName>("bulk_modulus", "bulk", "Bulk modulus material property K");
  params.addParam<MaterialPropertyName>(
      "shear_modulus", "shear", "Shear modulus material property G");
  MooseEnum form("literal isochoric", "literal");
  params.addParam<MooseEnum>("deviatoric_form",
                             form,
                             "literal: G/2 (tr b^e - 3); isochoric: G/2 ((J^e)^{-2/3} tr b^e - 3)");
  params.addCoupledVar("temperature",
                       "Coupled temperature. If omitted the model is isothermal (theta = 1).");
  params.addParam<MaterialPropertyName>(
      "thermal_expansion_coefficient",
      "Material property for the (linear) thermal expansion coefficient alpha");
  params.addParam<Real>("stress_free_temperature",
                        "Temperature T0 at which the thermal stretch is unity");
  MooseEnum stretch("linear exponential", "linear");
  params.addParam<MooseEnum>("thermal_stretch_form",
                             stretch,
                             "linear: theta = 1 + alpha (T - T0); exponential: theta = exp(alpha "
                             "(T - T0))");
  params.addParam<MaterialPropertyName>(
      "jacobian_name", "J", "Name of the declared total Jacobian det(F) property");
  params.addParam<MaterialPropertyName>(
      "jacobian_rate_name", "J_dot", "Name of the declared (J - J_old)/dt property");
  params.addParam<MaterialPropertyName>(
      "thermal_stretch_name", "thermal_stretch", "Name of the declared thermal stretch property");
  return params;
}

ComputeLagrangianThermoCompressibleNeoHookeanStress::
    ComputeLagrangianThermoCompressibleNeoHookeanStress(const InputParameters & parameters)
  : ComputeLagrangianStressPK1(parameters),
    _bulk(getMaterialProperty<Real>("bulk_modulus")),
    _shear(getMaterialProperty<Real>("shear_modulus")),
    _isochoric(getParam<MooseEnum>("deviatoric_form") == "isochoric"),
    _has_temperature(isCoupled("temperature")),
    _temperature(_has_temperature ? &coupledValue("temperature") : nullptr),
    _alpha((_has_temperature && isParamValid("thermal_expansion_coefficient"))
               ? &getMaterialProperty<Real>("thermal_expansion_coefficient")
               : nullptr),
    _has_T0(isParamValid("stress_free_temperature")),
    _T0(_has_T0 ? getParam<Real>("stress_free_temperature") : 0.0),
    _exponential_stretch(getParam<MooseEnum>("thermal_stretch_form") == "exponential"),
    _J(declareProperty<Real>(getParam<MaterialPropertyName>("jacobian_name"))),
    _J_old(getMaterialPropertyOldByName<Real>(getParam<MaterialPropertyName>("jacobian_name"))),
    _J_dot(declareProperty<Real>(getParam<MaterialPropertyName>("jacobian_rate_name"))),
    _thermal_stretch(declareProperty<Real>(getParam<MaterialPropertyName>("thermal_stretch_name")))
{
  if (_has_temperature)
  {
    if (!_alpha)
      paramError("thermal_expansion_coefficient",
                 "A thermal expansion coefficient is required when 'temperature' is coupled.");
    if (!_has_T0)
      paramError("stress_free_temperature",
                 "A stress free temperature is required when 'temperature' is coupled.");
  }
  else
  {
    if (isParamValid("thermal_expansion_coefficient"))
      paramError("thermal_expansion_coefficient",
                 "Only meaningful when 'temperature' is coupled.");
    if (_has_T0)
      paramError("stress_free_temperature", "Only meaningful when 'temperature' is coupled.");
  }
}

void
ComputeLagrangianThermoCompressibleNeoHookeanStress::initialSetup()
{
  // Derives _large_kinematics from the strain calculator guarantee.
  ComputeLagrangianStressPK1::initialSetup();

  if (!_large_kinematics)
    mooseError("ComputeLagrangianThermoCompressibleNeoHookeanStress is a finite-deformation "
               "hyperelastic model and requires large kinematics (use strain = FINITE or "
               "large_kinematics = true on the ComputeLagrangianStrain calculator).");
}

void
ComputeLagrangianThermoCompressibleNeoHookeanStress::initQpStatefulProperties()
{
  ComputeLagrangianStressPK1::initQpStatefulProperties();
  _J[_qp] = 1.0;
  _J_dot[_qp] = 0.0;
  _thermal_stretch[_qp] = 1.0;
}

Real
ComputeLagrangianThermoCompressibleNeoHookeanStress::computeThermalStretch() const
{
  if (!_has_temperature)
    return 1.0;

  const Real dT = (*_temperature)[_qp] - _T0;
  const Real a = (*_alpha)[_qp];
  const Real theta = _exponential_stretch ? std::exp(a * dT) : 1.0 + a * dT;
  if (!(theta > 0.0))
    throw MooseException("ComputeLagrangianThermoCompressibleNeoHookeanStress: non-positive "
                         "thermal stretch theta = ",
                         theta);
  return theta;
}

void
ComputeLagrangianThermoCompressibleNeoHookeanStress::computeElasticResponse(
    const RankTwoTensor & Fe, const Real K, const Real G, RankTwoTensor & Pe, RankFourTensor & Ae)
    const
{
  const Real Je = Fe.det();
  if (!(Je > 0.0))
    throw MooseException("ComputeLagrangianThermoCompressibleNeoHookeanStress: non-positive "
                         "elastic Jacobian J^e = ",
                         Je);

  const RankTwoTensor FinvT = Fe.inverse().transpose();

  // Volumetric part: P_vol = K J (J-1) F^{-T}
  const Real pvol = K * Je * (Je - 1.0);
  // d(K J (J-1))/dF = K (2J-1) J F^{-T}
  const Real dpvol = K * (2.0 * Je - 1.0) * Je;

  Pe = pvol * FinvT;

  Real a = 1.0;  // J^{-2/3} for the isochoric form
  Real I1 = 0.0; // tr C = F:F
  if (_isochoric)
  {
    a = std::pow(Je, -2.0 / 3.0);
    I1 = Fe.doubleContraction(Fe);
    Pe += G * a * (Fe - (I1 / 3.0) * FinvT);
  }
  else
    Pe += G * Fe;

  // Exact tangent dP_iJ / dF_kL
  Ae.zero();
  for (unsigned int i = 0; i < LIBMESH_DIM; ++i)
    for (unsigned int j = 0; j < LIBMESH_DIM; ++j)
      for (unsigned int k = 0; k < LIBMESH_DIM; ++k)
        for (unsigned int l = 0; l < LIBMESH_DIM; ++l)
        {
          const Real dd = (i == k && j == l) ? 1.0 : 0.0;

          // volumetric: K(2J-1)J F^-T_ij F^-T_kl - K J(J-1) F^-T_il F^-T_kj
          Real v = dpvol * FinvT(i, j) * FinvT(k, l) - pvol * FinvT(i, l) * FinvT(k, j);

          if (_isochoric)
            v += G * a *
                 (dd - 2.0 / 3.0 * Fe(i, j) * FinvT(k, l) - 2.0 / 3.0 * FinvT(i, j) * Fe(k, l) +
                  2.0 / 9.0 * I1 * FinvT(i, j) * FinvT(k, l) +
                  1.0 / 3.0 * I1 * FinvT(i, l) * FinvT(k, j));
          else
            v += G * dd;

          Ae(i, j, k, l) = v;
        }
}

void
ComputeLagrangianThermoCompressibleNeoHookeanStress::computeQpPK1Stress()
{
  const RankTwoTensor & F = _F[_qp];
  const Real J = F.det();
  if (!(J > 0.0))
    throw MooseException("ComputeLagrangianThermoCompressibleNeoHookeanStress: non-positive "
                         "Jacobian determinant J = ",
                         J);

  // Kinematic outputs used by the thermomechanical coupling
  _J[_qp] = J;
  _J_dot[_qp] = (_dt > 0.0) ? (J - _J_old[_qp]) / _dt : 0.0;

  // Thermal split F = F^e (theta I)
  const Real theta = computeThermalStretch();
  _thermal_stretch[_qp] = theta;
  const RankTwoTensor Fe = F * (1.0 / theta);

  RankTwoTensor Pe;
  RankFourTensor Ae;
  computeElasticResponse(Fe, _bulk[_qp], _shear[_qp], Pe, Ae);

  // Reference energy theta^3 W(F/theta): P = theta^2 P^e, dP/dF = theta A^e
  const RankTwoTensor P = Pe * (theta * theta);
  const RankFourTensor dPdF = Ae * theta;

  _pk1_stress[_qp] = P;
  // Chain through the (optional) F-bar stabilization; identity when F-bar is off.
  _pk1_jacobian[_qp] = dPdF * _d_F_stab_d_F_ust[_qp];
  _pk1_jacobian_bypass_fbar[_qp] = dPdF;
}
