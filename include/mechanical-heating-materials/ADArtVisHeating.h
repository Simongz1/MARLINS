#pragma once
#include "ADMaterial.h"

class ADArtVisHeating : public ADMaterial
{
public:
    ADArtVisHeating(const InputParameters & parameters);
    static InputParameters validParams();

protected:
    virtual void computeQpProperties() override;

private:
    const ADMaterialProperty<Real> &_p_av;
    const Real _beta_av;
    ADMaterialProperty<Real> &_q_av;
    const ADMaterialProperty<Real> &_J;
    const MaterialProperty<Real> &_J_old;
};