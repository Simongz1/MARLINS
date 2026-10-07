#pragma once

#include "Material.h"

class ADViscoplasticHeating;

class ADViscoplasticHeating : public Material
{
public:
    static InputParameters validParams();
    ADViscoplasticHeating(const InputParameters & parameters);

protected:
    virtual void computeQpProperties() override;

private:
    const Real _beta_vp;
    const ADMaterialProperty<Real> & _ep_dot;
    const ADMaterialProperty<RankTwoTensor> & _stress;
    const ADMaterialProperty<RankTwoTensor> & _flow_direction;
    ADMaterialProperty<Real> & _vp_heating;
};