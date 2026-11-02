#pragma once

#include "FunctorMaterial.h"

class ADFVMISTnet : public FunctorMaterial
{
public:
    static InputParameters validParams();
    ADFVMISTnet(const InputParameters & params);
protected:
    const Moose::Functor<ADReal> &_x;
    const Moose::Functor<ADReal> &_y;
    const Moose::Functor<ADReal> &_z;
};