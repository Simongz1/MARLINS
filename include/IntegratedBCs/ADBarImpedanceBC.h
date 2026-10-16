#pragma once

#include "ADIntegratedBC.h"

class Function;

class ADBarImpedanceBC : public ADIntegratedBC
{
public:
  static InputParameters validParams();

  ADBarImpedanceBC(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const VariableValue & _displacement_old;
  const VariableValue & _velocity_old;
  const VariableValue & _acceleration_old;

  const Real _impedance;
  const Real _beta;
  const Real _gamma;

  const Function & _driving_traction;
};