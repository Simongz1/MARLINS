#pragma once

#include "FunctorMaterial.h"
#include <cmath>

class ADComputeStressTensor : public FunctorMaterial
{
public:
    static InputParameters validParams();
    ADComputeStressTensor(const InputParameters & params);
protected:
    //velocity components
    const Moose::Functor<ADReal> &_vx;
    const Moose::Functor<ADReal> &_vy;
    const Moose::Functor<ADReal> &_vz;
    const std::string _velocity_gradient_name;

    //deformation gradient components
    const Moose::Functor<ADReal> &_F_00;
    const Moose::Functor<ADReal> &_F_01;
    const Moose::Functor<ADReal> &_F_02;
    const Moose::Functor<ADReal> &_F_10;
    const Moose::Functor<ADReal> &_F_11;
    const Moose::Functor<ADReal> &_F_12;
    const Moose::Functor<ADReal> &_F_20;
    const Moose::Functor<ADReal> &_F_21;
    const Moose::Functor<ADReal> &_F_22;

    //names of the functors
    const std::string _lambda_name;
    const std::string _mu_name;
    const std::string _momentum_vector_name;
    const std::string _density_name;
    const Moose::Functor<ADReal> &_lambda;
    const Moose::Functor<ADReal> &_mu;
    const Moose::Functor<ADRealVectorValue> &_m;
    const Moose::Functor<ADReal> &_rho;

    const std::string _strain_type;
};
