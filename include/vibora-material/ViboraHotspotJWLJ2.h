#pragma once
#include "ComputeLagrangianStressPK1.h"

/** Plane-strain-compatible, three-dimensional spatial JWL/J2 update.
 * History is committed by MOOSE only after timestep convergence.
 * F-bar is unsupported; the input disables it.
 */
class ViboraHotspotJWLJ2 : public ComputeLagrangianStressPK1
{
public:
  static InputParameters validParams();
  ViboraHotspotJWLJ2(const InputParameters &);
  void initialSetup() override;
protected:
  void initQpStatefulProperties() override;
  void computeQpPK1Stress() override;
  struct Response
  {
    RankTwoTensor P, be;
    Real ep, pressure;
  };
  Response response(const RankTwoTensor &) const;
  Real yield(Real increment) const;
  const VariableValue & _temperature;
  const VariableValue & _reactant;
  const MaterialProperty<Real> & _rho0;
  const MaterialProperty<Real> & _cv;
  const MaterialProperty<Real> & _G;
  const std::vector<Real> _unreacted;
  const std::vector<Real> _reacted;
  const Real _A, _B, _Tm, _m, _n, _reference_rate, _difference_step;
  MaterialProperty<RankTwoTensor> & _history_F;
  const MaterialProperty<RankTwoTensor> & _history_F_old;
  MaterialProperty<RankTwoTensor> & _be;
  const MaterialProperty<RankTwoTensor> & _be_old;
  MaterialProperty<Real> & _ep;
  const MaterialProperty<Real> & _ep_old;
  MaterialProperty<Real> & _J;
  const MaterialProperty<Real> & _J_old;
  MaterialProperty<Real> & _J_dot;
  MaterialProperty<Real> & _density;
  MaterialProperty<Real> & _pressure;
};
