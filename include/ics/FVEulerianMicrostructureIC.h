#pragma once
#include "InitialCondition.h"
#include <vector>

/** Initialize rho-weighted fields from the existing immutable integer microstructure labels. */
class FVEulerianMicrostructureIC : public InitialCondition
{
public:
  static InputParameters validParams();
  FVEulerianMicrostructureIC(const InputParameters &);
protected:
  Real value(const Point &) override;
  const MooseEnum _quantity;
  const unsigned int _density_index,_prediction_index;
  std::vector<Real> _density,_pore_density,_fraction,_pore_fraction;
};
