#include "ComputeLagrangianCompressibleNeoHookeanStress.h"
#include "MooseException.h"

#include <cmath>

registerMooseObject("mlApp", ComputeLagrangianCompressibleNeoHookeanStress);

InputParameters
ComputeLagrangianCompressibleNeoHookeanStress::validParams()
{
  InputParameters params = ComputeLagrangianStressPK1::validParams();
  params.addClassDescription(
      "Compressible neo-Hookean material W = K/2 (J-1)^2 + G/2 (tr b - 3) (or the isochoric "
      "deviatoric form G/2 (J^{-2/3} tr b - 3)) providing the first Piola-Kirchhoff stress and "
      "its consistent tangent for the Lagrangian kernel system.");
  params.addParam<MaterialPropertyName>("bulk_modulus", "bulk", "Bulk modulus material property K");
  params.addParam<MaterialPropertyName>(
      "shear_modulus", "shear", "Shear modulus material property G");
  MooseEnum form("literal isochoric", "literal");
  params.addParam<MooseEnum>("deviatoric_form",
                             form,
                             "literal: G/2 (tr b - 3); isochoric: G/2 (J^{-2/3} tr b - 3)");
  return params;
}

ComputeLagrangianCompressibleNeoHookeanStress::ComputeLagrangianCompressibleNeoHookeanStress(
    const InputParameters & parameters)
  : ComputeLagrangianStressPK1(parameters),
    _bulk(getMaterialProperty<Real>("bulk_modulus")),
    _shear(getMaterialProperty<Real>("shear_modulus")),
    _isochoric(getParam<MooseEnum>("deviatoric_form") == "isochoric")
{
}

void
ComputeLagrangianCompressibleNeoHookeanStress::initialSetup()
{
  // Derives _large_kinematics from the strain calculator guarantee.
  ComputeLagrangianStressPK1::initialSetup();

  if (!_large_kinematics)
    mooseError("ComputeLagrangianCompressibleNeoHookeanStress is a finite-deformation "
               "hyperelastic model and requires large kinematics (use strain = FINITE or "
               "large_kinematics = true on the ComputeLagrangianStrain calculator).");
}

void
ComputeLagrangianCompressibleNeoHookeanStress::computeQpPK1Stress()
{
  const RankTwoTensor & F = _F[_qp];
  const Real J = F.det();
  if (!(J > 0.0))
    throw MooseException("ComputeLagrangianCompressibleNeoHookeanStress: non-positive "
                         "Jacobian determinant J = ",
                         J);

  const RankTwoTensor FinvT = F.inverse().transpose();
  const Real K = _bulk[_qp];
  const Real G = _shear[_qp];

  // Volumetric part: P_vol = K J (J-1) F^{-T}
  const Real pvol = K * J * (J - 1.0);
  // d(K J (J-1))/dF = K (2J-1) J F^{-T}
  const Real dpvol = K * (2.0 * J - 1.0) * J;

  RankTwoTensor P = pvol * FinvT;

  // Deviatoric part
  Real a = 1.0;  // J^{-2/3} for isochoric form
  Real I1 = 0.0; // tr C = F:F
  if (_isochoric)
  {
    a = std::pow(J, -2.0 / 3.0);
    I1 = F.doubleContraction(F);
    P += G * a * (F - (I1 / 3.0) * FinvT);
  }
  else
    P += G * F;

  // Consistent tangent dP_iJ / dF_kL
  RankFourTensor dPdF;
  dPdF.zero();
  for (unsigned int i = 0; i < LIBMESH_DIM; ++i)
    for (unsigned int j = 0; j < LIBMESH_DIM; ++j)
      for (unsigned int k = 0; k < LIBMESH_DIM; ++k)
        for (unsigned int l = 0; l < LIBMESH_DIM; ++l)
        {
          const Real dd = (i == k && j == l) ? 1.0 : 0.0;

          // volumetric: K(2J-1)J F^-T_iJ F^-T_kL - K J(J-1) F^-T_iL F^-T_kJ
          Real v = dpvol * FinvT(i, j) * FinvT(k, l) - pvol * FinvT(i, l) * FinvT(k, j);

          if (_isochoric)
            v += G * a *
                 (dd - 2.0 / 3.0 * F(i, j) * FinvT(k, l) - 2.0 / 3.0 * FinvT(i, j) * F(k, l) +
                  2.0 / 9.0 * I1 * FinvT(i, j) * FinvT(k, l) +
                  1.0 / 3.0 * I1 * FinvT(i, l) * FinvT(k, j));
          else
            v += G * dd;

          dPdF(i, j, k, l) = v;
        }

  _pk1_stress[_qp] = P;
  // Chain through the (optional) F-bar stabilization; identity when F-bar is off.
  _pk1_jacobian[_qp] = dPdF * _d_F_stab_d_F_ust[_qp];
  _pk1_jacobian_bypass_fbar[_qp] = dPdF;
}
