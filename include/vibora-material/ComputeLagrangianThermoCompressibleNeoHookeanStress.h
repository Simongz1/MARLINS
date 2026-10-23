#pragma once

#include "ComputeLagrangianStressPK1.h"

/**
 * Thermoelastic compressible neo-Hookean model for the Lagrangian kernel system.
 *
 * Multiplicative thermal split F = F^e F^theta with F^theta = theta I (full 3x3),
 *   theta = 1 + alpha (T - T0)       (linear, default)
 *   theta = exp(alpha (T - T0))      (exponential)
 *
 * Elastic energy (per intermediate volume) evaluated at F^e:
 *   W = K/2 (J^e - 1)^2 + W_dev
 *     literal  : W_dev = G/2 (tr b^e - 3)
 *     isochoric: W_dev = G/2 ((J^e)^{-2/3} tr b^e - 3)
 *
 * With reference energy theta^3 W(F/theta):
 *   P = theta^2 P^e(F^e),   dP/dF = theta A^e(F^e),
 *   sigma = (1/J^e) P^e (F^e)^T  (depends on F^e only).
 *
 * Also publishes the stateful total Jacobian J = det(F), its backward-Euler rate
 * J_dot = (J - J_old)/dt and the thermal stretch theta as Real material properties.
 * Without a coupled temperature the model reduces exactly to the isothermal one.
 */
class ComputeLagrangianThermoCompressibleNeoHookeanStress : public ComputeLagrangianStressPK1
{
public:
  static InputParameters validParams();

  ComputeLagrangianThermoCompressibleNeoHookeanStress(const InputParameters & parameters);

  virtual void initialSetup() override;

protected:
  virtual void initQpStatefulProperties() override;
  virtual void computeQpPK1Stress() override;

  /// Elastic PK1 stress P^e(F^e) and exact tangent A^e = dP^e/dF^e
  void computeElasticResponse(const RankTwoTensor & Fe,
                              const Real K,
                              const Real G,
                              RankTwoTensor & Pe,
                              RankFourTensor & Ae) const;

  /// Thermal stretch theta at the current quadrature point
  Real computeThermalStretch() const;

  /// Bulk modulus K
  const MaterialProperty<Real> & _bulk;
  /// Shear modulus G
  const MaterialProperty<Real> & _shear;
  /// true: G/2 (J^{-2/3} tr b - 3); false: G/2 (tr b - 3)
  const bool _isochoric;

  /// Whether a temperature is coupled
  const bool _has_temperature;
  /// Coupled temperature (nullptr when not coupled)
  const VariableValue * const _temperature;
  /// Thermal expansion coefficient (nullptr when no temperature)
  const MaterialProperty<Real> * const _alpha;
  /// Whether a stress free temperature was given
  const bool _has_T0;
  /// Stress free temperature
  const Real _T0;
  /// Exponential (true) or linear (false) thermal stretch
  const bool _exponential_stretch;

  /// Total Jacobian J = det(F) (stateful)
  MaterialProperty<Real> & _J;
  /// Old total Jacobian
  const MaterialProperty<Real> & _J_old;
  /// Rate of total Jacobian (J - J_old)/dt
  MaterialProperty<Real> & _J_dot;
  /// Thermal stretch theta
  MaterialProperty<Real> & _thermal_stretch;
};
