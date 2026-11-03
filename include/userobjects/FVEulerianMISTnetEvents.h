#pragma once
#include "GeneralUserObject.h"
#include <vector>

/** Accepted-step activation impulse for transported MISTnetX conditional histories. */
class FVEulerianMISTnetEvents : public GeneralUserObject
{
public:
  static InputParameters validParams();
  FVEulerianMISTnetEvents(const InputParameters &);
  void initialize() override {}
  void execute() override;
  void finalize() override {}
protected:
  using Table=std::vector<std::vector<Real>>;
  const unsigned int _id_index;
  const Real _threshold,_tau_scale;
  std::vector<Real> _velocities,_pore_velocities;
  Table _shock,_react,_pore_shock,_pore_react;
};
