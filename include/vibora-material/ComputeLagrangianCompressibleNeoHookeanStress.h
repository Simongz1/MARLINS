#pragma once

#include "ComputeLagrangianStressPK1.h"

/**
 * Compressible neo-Hookean hyperelastic model for the Lagrangian kernel system.
 *
 *   W = K/2 (J - 1)^2 + W_dev
 *     literal  : W_dev = G/2 (tr b - 3)
 *     isochoric: W_dev = G/2 (J^{-2/3} tr b - 3)
 *
 * The first Piola-Kirchhoff stress P = dW/dF and the consistent tangent dP/dF are
 * provided; the ComputeLagrangianStressPK1 base converts them to the Cauchy stress
 * and Cauchy Jacobian consumed by the total/updated Lagrangian stress divergence kernels.
 */
class ComputeLagrangianCompressibleNeoHookeanStress : public ComputeLagrangianStressPK1
{
public:
  static InputParameters validParams();

  ComputeLagrangianCompressibleNeoHookeanStress(const InputParameters & parameters);

  virtual void initialSetup() override;

protected:
  virtual void computeQpPK1Stress() override;

  /// Bulk modulus K
  const MaterialProperty<Real> & _bulk;
  /// Shear modulus G
  const MaterialProperty<Real> & _shear;
  /// true: G/2 (J^{-2/3} tr b - 3); false: G/2 (tr b - 3)
  const bool _isochoric;
};
