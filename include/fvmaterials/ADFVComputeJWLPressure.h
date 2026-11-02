#pragma once

#include "FunctorMaterial.h"

class ADFVComputeJWLPressure : public FunctorMaterial
{
public:
    static InputParameters validParams();
    ADFVComputeJWLPressure(const InputParameters & params);
protected:
    const MooseFunctorName _A_name;
    const Moose::Functor<ADReal> &_A;
    const MooseFunctorName _B_name;
    const Moose::Functor<ADReal> &_B;
    const MooseFunctorName _R1_name;
    const Moose::Functor<ADReal> &_R1;
    const MooseFunctorName _R2_name;
    const Moose::Functor<ADReal> &_R2;
    const MooseFunctorName _omega_name;
    const Moose::Functor<ADReal> &_omega;
    const MooseFunctorName _Jacobian_name;
    const Moose::Functor<ADReal> &_Jacobian;
    const MooseFunctorName _pressure_name;
    const MooseFunctorName _energy_name;
    const Moose::Functor<ADReal> &_energy;
    const MooseFunctorName _density_name;
    const Moose::Functor<ADReal> &_density;
};