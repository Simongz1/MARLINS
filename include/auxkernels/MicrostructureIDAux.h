#pragma once

#include "AuxKernel.h"

/** Visualization of the authoritative original-element integer label. */
class MicrostructureIDAux : public AuxKernel
{
public:
  static InputParameters validParams();
  MicrostructureIDAux(const InputParameters & parameters);

protected:
  Real computeValue() override;
  const unsigned int _micro_id_index;
};
