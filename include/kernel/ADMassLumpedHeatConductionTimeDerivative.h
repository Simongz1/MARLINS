#pragma once

#include "ADTimeKernel.h"
#include "MooseVariableFE.h"

/** Row-sum lumped thermal storage with quadrature-point density and specific heat.
 * Each residual row uses its own nodal temperature rate, while capacity is integrated
 * over the adjacent elements. Material and displaced-geometry derivatives remain AD.
 */
class ADMassLumpedHeatConductionTimeDerivative : public ADTimeKernel
{
public:
  static InputParameters validParams();
  ADMassLumpedHeatConductionTimeDerivative(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const ADMaterialProperty<Real> & _density;
  const ADMaterialProperty<Real> & _specific_heat;
  const MooseVariableFE<Real>::ADDofValues & _u_dot_nodal;
};
